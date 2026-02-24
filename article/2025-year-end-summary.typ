#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "2025 年终总结",
  desc: [
    回顾 2025 这一年我所做的事.
  ],
  date: "2025-12-30",
  tags: (
    blog-tags.summary,
    blog-tags.typst,
    blog-tags.programming,
    blog-tags.vrchat,
  ),
  license: licenses.cc-by-nc-sa,
)

虽然本文的日期被标为 "2025-12-30", 但是实际上本文是在 2026-02-24 写的, 也即春节结束后. 原因就是我的拖延症.

= Typress
本来计划写一个更好的数据集生成工具, 同时在一个稍微魔改的新模型结构上进行训练, 然而最终鸽子了.

= Tinymist Nightly
手动为 Tinymist 维护了一段时间 nightly 发版后, 向仓库贡献了大量 GitHub Actions 以让发版流程更规范和自动化.

原计划在官方的 Path 模型大重构后再出一版 nightly, 然而写完第一版发现爆了一堆测试后就没再动过. 不过考虑到 typst 的发版周期如此之长, 可能之后有空再捡起来还来得及.

= #link("https://github.com/ParaN3xus/litman")[Litman]
这是我的数据结构课程大作业. 基本上就是一个从 DBLP 加载数据集, 然后进行各种 R(没有CUD) 的系统.

听起来似乎很没意思, 不过其实还好, 因为
- 不允许使用数据库, 所以我抄了 B+ 树
- 里面有一个很有意思的需求: 计算科研人员合作关系的图中的各阶完全子图个数. 这是一个著名的 NP 完全问题, 最终我#link("https://github.com/ParaN3xus/litman/tree/main/backend/pivoter")[抄]了 #link("https://dl.acm.org/doi/10.1145/3336191.3371839")[Pivoter] 算法, 并且因此写了一篇 #link("https://blog.paran3x.us/article/pivoter-for-exact-clique-counting/")[Blog].

= #link("https://github.com/ParaN3xus/blog")[Blog]
#link("https://github.com/Myriad-Dreamin/")[Myriad-Dreamin] 用 #link("https://github.com/OverflowCat/astro-typst")[astro-typst] 做了一个 Blog, 看得我手痒痒, 然后就有了现在这个 Blog.

其实我本来有继续重构 Blog 的计划, 但是一直被推迟, 或许 2026 年会完成, 这里可以写一下 todo
- [ ] 完全分离模板和内容: 模板应当是公共的仓库, 内容仓库应该负责构建和部署 Blog
- [ ] 修复各种样式: 图片, 代码框, 公式等
- [ ] SEO 优化
- [ ] 搞懂怎么用新版 astro-typst, 因为新版本不再允许直接在网页中嵌入 JavaScript 了


= #link("https://github.com/ParaN3xus/tinymist/tree/tinymist-wasm")[Tinymist WASM]
最开始 #link("https://github.com/Myriad-Dreamin/")[Myriad-Dreamin] 问我要不要做的时候我还拒绝了( 然而后来还是做了一些.

基本上就是让 Tinymist 能运行在浏览器里, 目前除了 debugger 部分都能正常工作, 还做了一个 playground(原名), 后来和官方撞了于是改为 #link("https://github.com/ParaN3xus/tyraria")[tyraria]. 目前还有一些 Bug, 不过总体工作良好.

目前还有很多重要功能没有合入主线 Tinymist. 这可能是 2026 年的一项重要目标.

= #link("https://github.com/typstyle-rs/typstyle-tampermonkey")[Typstyle 油猴插件]

赞美 WASM.

可以让你在官方 Web App 上使用 #link("https://github.com/typstyle-rs/typstyle")[typstyle] 格式化代码. 这是巨大的幸福感提升.

我的工作只是写了一些 hook, WASM 构建工作是 typstyle 官方完成的.

= #link("https://github.com/ParaN3xus/vdshortcut")[vdshortcut]

我对 Hyprland 又爱又恨, 表现在我放弃 Hyprland 切换到 Windows 后还是念念不忘 Hyprland 快捷键, 前前后后做了很多工作来模拟它.

vdshortcut 是一个能用快捷键切换到指定序号的虚拟桌面的 Windows 小工具, 我没有做任何逆向工作, 直接引入了别人的 API 包.

= #link("https://github.com/ParaN3xus/koioj")[koioj]

我的数据库课程大作业. 这是一个功能完整的 OJ.

由于我预感到如果不写 SQL 会被老师喷, 所以我没有使用任何高级的 ORM 框架或者抽象, 几乎所有 API 端口都是直接执行 SQL 来实现. 这导致代码十分丑陋, 而且可能有各种没考虑到的 corner case.

而且由于我完全没有 OJ 的设计经验, API 服务器向评测服务器发布评测任务居然需要传输全部测试数据(每次), 当我意识到测试数据可能有数 G 时已经覆水难收.

总而言之这是一次非常不优雅的 CRUD 初体验.

= #link("https://github.com/ParaN3xus/paran3xus_smol_slime")[DIY 史莱姆追踪器]
详情见该 #link("https://blog.paran3x.us/article/diy-smol-slime-tracker/")[Blog].

直到本文撰写之时, 我的教程还没写完, 因为我还是没搞懂怎么让脚上的追踪器正确工作. 目前有一个非常诡异的 Bug: 我从站姿到坐姿(腿展平)时, 脚踝会莫名其妙内翻, 且腿会张开, 导致姿势非常诡异. 或许等我真正搞懂如何让它正确工作时会继续完成教程.

= #link("https://github.com/ParaN3xus/udon-decompiler")[Udon Decompiler]
详情见该 #link("https://blog.paran3x.us/article/udon-script-analysis/")[Blog] 和该 #link("https://udon-decompiler.paran3x.us/")[文档].

我在做自己的第一个编译器之前先做了自己的第一个反编译器, 不知道这是否是正常的情形.

这个项目花费了比预计多得多的时间, 以至于直到撰写本文之时都没有完成. 不过我确实学到了很多东西, 不知道这是否值得. 希望我正式发布这个项目时能得到比较好的反响.
