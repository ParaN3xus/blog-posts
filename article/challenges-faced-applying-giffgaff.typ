#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "giffgaff 申请踩坑",
  desc: [申请 giffgaff SIM 卡的经验分享],
  date: "2023-10-24",
  tags: (
    blog-tags.free-ride,
  ),
  license: licenses.cc-by-nc-sa,
)

今年早些时候在群友那里了解到 giffgaff, 本着"反正不花钱, 不要白不要"的原则一口气申请了三张, 结果一张都没到.

后来本人因各种原因暂时到了南方某沿海省, 想着可能经济发达的地方可能平邮会更容易到, 再加上沿海可能辗转更少, 所以又申请了两张, 这次全到了.

但是过程并不是一帆风顺, 还是有一些网上其他教程没有提到的小坑, 给了我水这篇Blog的机会.

= giffgaff 是什么?

这里引用#link("https://jiami.dog/3576.html")[另一篇教程]的介绍, 因为我也不太懂.

#quote[
  Giffgaff 是一家总部位于英国的行动电话公司. 作为一家行动虚拟网路电信业者, Giffgaff 使用 O2 的网路, 是 O2 的全资公司, 成立于 2009 年 11 月 25 日.
  Giffgaff 与传统的行动电话电信业者不同, 区别在于其使用者也可以参与公司的部份运营, 如销售, 客服, 行销环节等. 作为参与运营的回报, 使用者从公司的"回赠"(Payback)系统中获得补偿.
]

从结果来看, 你得到的是可在中国激活, 零月租保号的一张实体英国电话卡.

= 成果展示

#figure(
  image("assets/challenges-faced-applying-giffgaff/final_result.jpg"),
  caption: [最终收到的 giffgaff SIM 卡],
)

= 申请过程

过程非常简单和人性化, 只要在 giffgaff 官网点击 Order your free SIM (也可以直接: #link("https://www.giffgaff.com/freesim-international")[传送门]), 然后跟着引导走就行了.

注意进官网不要挂英国梯子, 不然没有选择送货国家的位置.

既然是要零月租保号, 那当然是什么套餐都不选, 这个应该都能懂.

下面重点介绍最关键的填写地址, 这直接决定你能不能收到卡.

== 坑点 1: 地址填写

在我收到 giffgaff 后, 我发现信息栏只有 9 行字, 大体布局如下:

```
1 名 (First name) 姓 (Last name)
2
3 地址行1和2共用这四行
4
5
6 邮编 (Postcode/Zip) 市 (Town/City)
7 省 (County/Province/State (optional))
8 THE PEOPLES REPUBLIC OF CHINA(Country)
9 一传类似于某种ID的东西
```

名和姓没必要写真名. 省市邮编这些都好说, 地址行一二才是关键.

地址行一二只能填英文字母, 数字, 空格, 符号. 本人实测, 一行字最多 26 个字符, 而且你还要考虑为了保持单词不断行做的提前换行.

那如果我写太多了会怎么样呢? 答案是: 你的地址会只剩下首尾, 中间的连省略号都没有. 我猜测这就是我第一次申请没有成功送到的原因.

我建议的是, 地址行 2 只填你的电话号, 因为他是先把两行直接拼接再打印的, 所以第二行的内容一定会印上去. 这个电话号等于是一个保底的内容, 如果邮局的人有责任心的话肯定会注意到然后打给你, 到时候你就可以再完善信息了.

至于地址行1, 就不要填写已经存在的国家, 省, 市等等信息, 只需要填市再往下的内容即可. 因为这个信息只是对市级的邮局有用, 而他们一般对下一级的区划比较熟悉, 所以像是"区", "小区"这种就可以不要填了, 尽量保证信息能够完整显示.

此外, 本着"反正不花钱, 不要白不要"的原则, 结合目前国内平邮丢件率极高的现状, 我建议一次申请两张起步. 毕竟 giffgaff 给我的邮件里也说:

#quote[
  Can't find your SIM? No worries. Simply #link("https://t.info3.giffgaff.com/r/?id=h24c3d97b,60798c1,2d4cd7&e=dXRtX3NvdXJjZT1naWZmZ2FmZiZ1dG1fbWVkaXVtPWVtYWlsJnV0bV9jYW1wYWlnbj1lbWFpbC1Db252c19PQkMwOTRfVjcmZ2dDYW1wYWlnbj1lbWFpbC1Db252c19PQkMwOTRfVjc&s=05xiCWcvh-tu721XNT0yJO7HNVyNqo6PkAwSxCJjni0")[head to giffgaff.com] to order a new SIM today and we'll pop another one in the post.
]

= 寄送过程

从官网申请到拿到实物一共花了 38 天, 其中从市级到达我手里就花了一星期左右. 平邮是这样的, 慢一点很正常, 所以不要急, 反正你也没花钱.

= 激活过程

激活过程也比较人性化, 跟着引导来就可以了, 但是要注意我们的目标是零月费保号, 所以:

== 坑点 2: 选套餐

一定要用网页版激活! 选套餐的时候一定要划到最下面选 pay as you go (除非你很有钱, 能付得起一个月50CNY).

如果你不慎真选错了, 那也没关系, 只要关掉自动续费下一个月就会变成无套餐, 然后就等同于 pay as you go 了.

充钱的话需要用外币卡, 我这边实测 dupay 的预付卡可以用, 所以应该是没有太多限制的.

似乎 Paypal 也可以充值, 但是我没试过, 所以不清楚是否有限制.

= 实际使用

待更新, 因为我就是那个充了五十块钱的冤种, 现在没钱冲话费了, 不敢用怕给我停机了.

保号的话只需要 180 天余额变动一次就行了, 简直无门槛.
