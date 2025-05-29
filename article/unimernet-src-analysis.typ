#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "UniMERNet 源码阅读",
  desc: [
    本文记录了对 UniMERNet 源码的阅读和理解, 包括类层次结构和四点主要改进.
  ],
  date: "2024-12-31",
  tags: (
    blog-tags.ai,
    blog-tags.programming,
    blog-tags.pytorch,
  ),
  license: licenses.cc-by-nc-sa,
)

#link("https://github.com/opendatalab/UniMERNet")[UniMerNet] 是一个针对数学公式的 TrOCR 模型. 基本上, 他是一个 #link("https://github.com/clovaai/donut")[Donut] 的变体, 包含一个修改过的 Swin Encoder 和一个修改过的 BART Decoder.

由于他们的官方代码大量从 transformers 库中复制, 所以非常混乱, 嵌套了数不清层的类, 所以专门写一下 Blog 记录我一中午的阅读成果.

= 类层次
```yml
model: unimernet.UniMERModel
    tokenizer: encoder_decoder.DonutTokenizer
    model: encoder_decoder.DonutEncoderDecoder
        model: encoder_decoder.CustomVisionEncoderDecoderModel
            encoder: encoder_decoder.VariableUnimerNetModel (SwinModel - layernorm + *embeddings)
                num_layers: int
                num_features: int
                embeddings: encoder_decoder.VariableUnimerNetEmbeddings (SwinEmbeddings + *patch_embeddings - interpolate_pos_encoding)
                    patch_embeddings: encoder_decoder.VariableUnimerNetPatchEmbeddings (SwinPatchEmbeddings + StemLayer)
                        projection: encoder_decoder.StemLayer (FGE)

                encoder: UnimerNetEncoder (SwinEncoder + *UnimerNetStage)
                    layers: [UnimerNetStage (SwinStage + ConvEnhance)]
                        blocks: [UnimerNetLayer (SwinLayer + ConvEnhance + shift_size=0)]
                            shift_size: 0 (RSW)
                            layernorm_before: LayerNorm
                            ce: [ConvEnhance] (CE)
                            attention: SwinAttention
                            drop_path: SwinDropPath
                            layernorm_after: LayerNorm
                            intermediate: SwinIntermediate
                            output: SwinOutput

                pooler: AdaptiveAvgPool1d

            decoder: encoder_decoder.CustomMBartForCausalLM
                model.decoder: modeling_unimernet_decoder.MBartDecoder (or CustomMBartDecoder) (BardDecoder - spda + squeeze_attn + layernorm + count(todo, currently none))
                    embed_tokens: BartScaledWordEmbedding
                    embed_positions: BartLearnedPositionalEmbedding
                    layers: [MBartDecoderLayer]
                        *_attn: MBartSqueezeAttention / MBartFlashAttention2 (SA)
                    layernorm_embedding: LayerNorm
                    layer_norm: LayerNorm

processor: unimernet.processors.formula_processor.FormulaImageEvalProcessor
```
上述层次图基本展示了重要功能模块的组成, 并标注了论文中宣称的 FGE, RSW, CE, SA 对应在源码中的具体位置.

= 四点改进
== Fine-Grained Embedding(FGE)
UniMerNet 把 Swin Encoder 中 "把图片分为不重叠的 Patch + 线性映射"(`PatchEmbeddings` 中的 `projection`)的操作更换为两次卷积:
```python
class StemLayer(nn.Module):
    """
    Stem layer of InternImage
    Args:
        in_chans (int): number of input channels
        out_chans (int): number of output channels
        act_layer (str): activation layer
        norm_layer (str): normalization layer
    """

    def __init__(self,
                 in_chans=3,
                 out_chans=96,
                 act_layer=nn.GELU,
                 norm_layer='BN'):
        super().__init__()
        self.conv1 = nn.Conv2d(in_chans,
                               out_chans // 2,
                               kernel_size=3,
                               stride=2,
                               padding=1)
        self.norm1 = build_norm_layer(out_chans // 2, norm_layer)

        self.act = act_layer()
        self.conv2 = nn.Conv2d(out_chans // 2,
                               out_chans,
                               kernel_size=3,
                               stride=2,
                               padding=1)

    def forward(self, x):
        x = self.conv1(x)
        x = self.norm1(x)
        x = self.act(x)
        x = self.conv2(x)
        return x
```
把 patch 换成卷积已经是一个很常见的魔改了, 据说好处很多, 能加快收敛, 提高表现等等, 一个讨论见 #link("https://arxiv.org/abs/2106.14881")[Early Convolutions Help Transformers See Better].

== Convolutional Enhancement(CE)
UniMerNet 认为 Transformer 能较好地捕捉全局信息, 但是对于数学公式识别来说, 一些局部信息(小的上下标等)也很重要. 所以, 他们在每个 Swin Layer 的 Window Attention 和 MLP 层之前都加了一个 Kernel Size = 3*3, Stride = 1 的卷积, 也即 Convolutional Enhancement 模块:

```python
class ConvEnhance(nn.Module):
    """
    Depth-wise convolution to get the positional information.
    """
    def __init__(self, config, dim, k=3):
        super(ConvEnhance, self).__init__()
        self.proj = nn.Conv2d(dim,
                              dim,
                              (k,k),
                              (1,1),
                              (k // 2,k // 2),
                              groups=dim)
        self.act_fn = ACT2FN[config.hidden_act]

    def forward(self, x, size: Tuple[int, int]):
        B, N, C = x.shape
        H, W = size
        assert N == H * W

        feat = x.transpose(1, 2).view(B, C, H, W)
        feat = self.proj(feat)
        feat = self.act_fn(feat)
        feat = feat.flatten(2).transpose(1, 2)

        x = x + feat
        return x
```

这里的激活函数选用的是 GELU.

== Removal of Shift Window(RSW)
Swin 原版设计 Shift Window based Multi-Head Self-Attention(SW-MSA) 是想解决多个 Window 之间互相沟通的问题. 由于前面的魔改主要是加入了大量的卷积, 多个 Window 之间已经有了沟通, 或者说"模型的感受野已经很大了", 所以这个模块也就没必要存在了, 删掉还能加速. 此外根据他们的实验, 删掉之后模型表现也会提升.

官方的实现没有直接删掉相关代码, 而是把 `SwinLayer` 的 `shift_size` 参数设置为 `0` 来关掉这个步骤:
```python
class UnimerNetStage(nn.Module):
    def __init__(self, config, dim, input_resolution, depth, num_heads, drop_path, downsample):
        super().__init__()
        self.config = config
        self.dim = dim
        self.blocks = nn.ModuleList(
            [
                UnimerNetLayer(
                    config=config,
                    dim=dim,
                    input_resolution=input_resolution,
                    num_heads=num_heads,
                    shift_size=0,
                )
                for i in range(depth)
            ]
        )

        = patch merging layer
        if downsample is not None:
            self.downsample = downsample(input_resolution, dim=dim, norm_layer=nn.LayerNorm)
        else:
            self.downsample = None

        self.pointing = False
```

== Squeeze Attention(SA)
这是一个用于提速的改进. 原本的 BART Attention 的 `q` 和 `k` 是和 `embed_dim` 一样大的. 这可能有点多余了, 所以 UniMerNet 中直接把这个维度砍半, 实验发现性能损失很小, 但是推理速度快了不少. 代码大部分都是照搬 BART Attention, 只是在相关的地方修改了 shape 而已, 这里就不贴了.

= 干净实现
#link("https://github.com/ParaN3xus/my-unimernet")[Repo].

主要是删除了大量复制的代码, 能继承 transformers 的就继承. 此外, 还把原版自己造的接口换成了 transformers 类似的接口, 包括 `VisionEncoderDecoder` 和 `Processor` 等.
