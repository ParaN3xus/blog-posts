#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "florr.io 中的合成与概率",
  desc: [
    在 WSL 中创建一个 alias, 直接使用 Windows 文件资源管理器打开目录或文件.
  ],
  date: "2025-02-05",
  tags: (
    blog-tags.math,
    blog-tags.probablities,
  ),
  license: licenses.cc-by-nc-sa,
)

#let levels = (
  "普通",
  "罕见",
  "稀有",
  "史诗",
  "传奇",
  "神话",
  "究极",
  "超级",
)
#let colors = (
  rgb("#7EEF6D"),
  rgb("#FFE65D"),
  rgb("#4D52E3"),
  rgb("#861FDE"),
  rgb("#DE1F1F"),
  rgb("#1FDBDE"),
  rgb("#E02365"),
  rgb("#2BFFA3"),
)

#show: body => (
  levels
    .zip(colors)
    .fold(body, (it, data) => {
      show regex(data.first()): set text(data.last())
      it
    })
)


#link("https://florr.io/")[florr.io] 是一款#strike[开放世界冒险游戏], 玩家可以在自己控制的花朵(flower)上装备各种花瓣(petal)来与地图中昆虫或者其他物体战斗.

花瓣有不同种类, 相同的种类也有等级高低之分, 高等级的花瓣可以通过击败高等级的昆虫, 并拾取其掉落物获得, 也可以通过五个次一级的同种花瓣合成获得.

= 花瓣合成的机制

花瓣合成的具体机制如下:
+ 一次合成是否成功服从伯努利分布, 对于大多数花瓣来说, 各等级合成的成功概率为
  #block(width: 100%, figure(
    table(
      columns: 2,
      [合成等级], [成功率],
      [普通合成罕见], [64%],
      [罕见合成稀有], [32%],
      [稀有合成史诗], [16%],
      [史诗合成传奇], [8%],
      [传奇合成神话], [4%],
      [神话合成究极], [2%],
      [究极合成超级], [1%],
    ),
    caption: [花瓣合成成功率表],
  ))
+ 如果合成失败, 将会随机销毁一个或数个花瓣, 销毁的花瓣数服从 $U(1, 4)$.

为了后续讨论的方便, 这里我们假设每次合成都是独立的, 也即不存在"保底"等规则.

= 我需要多少次级花瓣

有些时候, 我们想要知道需要多少次级的花瓣才能有较大概率(比如 $95%$)获得至少一个高级花瓣.

这里我们设一次合成成功率为 $p$, 为了有 $k$ 的概率获得至少一个高级花瓣, 我们有
$
  1 - k = (1-p)^(m_k) \
  => m_k = (ln(1-k)) / (ln(1-p))
$

其中 $m_k$ 是预期的合成次数.

这 $m_k$ 次中包含了 $m_k-1$ 次合成失败和 $1$ 次合成成功, 对于每次合成失败, 预期的损耗为 $5 / 2$, 所以
$
  n_k = & 5 / 2 (m_k - 1) + 5               \
      = & 5 / 2 ((ln(1-k)) / (ln(1-p)) + 1)
$

其中 $n_k$ 是需要的次级花瓣数.

根据此公式, 我们得到如下表格

#figure(
  table(
    columns: 4,
    [合成等级], [成功率], [$n_0.95$], [$n_0.99$],
    ..{
      let levels = (
        [普通合成罕见],
        [罕见合成稀有],
        [稀有合成史诗],
        [史诗合成传奇],
        [传奇合成神话],
        [神话合成究极],
        [究极合成超级],
      )
      let ps = (
        0.64,
        0.32,
        0.16,
        0.08,
        0.04,
        0.02,
        0.01,
      )
      let fn(p, k) = 5 / 2 * (calc.ln(1 - k) / calc.ln(1 - p) + 1)
      let ks = (0.95, 0.99)
      levels
        .zip(ps.map(p => p * 100).map(p => $#p%$))
        .zip(ps.map(p => {
          ks
            .map(k => {
              fn(p, k)
            })
            .map(calc.round.with(digits: 2))
            .map(str)
        }))
    }.flatten(),
  ),
  caption: [花瓣合成所需次级花瓣数表],
)

