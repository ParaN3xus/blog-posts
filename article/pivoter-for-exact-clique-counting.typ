#import "/typ/templates/blog.typ": *
//#import "@preview/theorion:0.3.3": *
//#import cosmos.rainbow: *

#show: main.with(
  title: "团精确计数的 Pivoter 算法",
  desc: [
    对 Pivoter 算法的介绍, 包括关键数据结构 SCT 的构建和性质, 以及如何使用 SCT 来计数团.
  ],
  date: "2025-05-25",
  tags: (
    blog-tags.programming,
    blog-tags.math,
  ),
)



这是我"数据结构"课程大作业的一部分内容, 由于中文网络上似乎没有 Pivoter 算法的相关资料, 所以我整理成一篇文章来介绍这个算法.


= 任务
我所面临的任务是: 在给定的无向图中, 计算所有团(clique, 也即完全子图)的个数. 除此之外, 常见的任务还可以是计算某些点或者某些边参与的团的个数, 或者把这些团列出来.

方便起见, 下面默认任务是计算所有团的个数.

= 记号
为了防止混淆, 本文中递归树结构的边称为"连接", 而图中的边称为"边", 递归树结构的点称为"节点", 而图中的点称为"顶点".

#let tree = $bold(T)$.body
#let hold = $frak(h)$.body
#let pivot = $frak(p)$.body
#let SCT = $limits("SCT")$.body

#figure(
  table(
    columns: (6em, 30em),
    align: center + horizon,
    [记号], [含义],
    $G(V, E)$, [无向图, 其中 $V$ 是顶点集, $E$ 是边集],
    $n$, [顶点数, 即 $abs(V)$],
    $m$, [边数, 即 $abs(E)$],
    $alpha$, [退化度, 也即图中最大团的大小],
    $C$, [团, 也即完全子图],
    $C_k$, [$k$ 阶团, 也即包含 $k$ 个顶点的团],
    $N(v)$, [顶点 $v$ 的邻居集],
    $N^+(v)$, [顶点 $v$ 的出邻居集, 对有向图或无向图的一个定向适用],
    $N(S, v)$, [顶点集 $S$ 中顶点 $v$ 的邻居集, 即 $N(v) inter S$],
    $SCT(G)$, [图 $G$ 的简化团树, 即 Pivoter 算法的递归树],
    $tree$, [SCT, 也即简化团树],
    $hold$, [SCT 中连接标签的 hold 类型],
    $pivot$, [SCT 中连接标签的 pivot 类型],
    $T$, [递归树中的一条路径, 也即从根到某个叶子节点的路径],
    $H(T)$, [$T$ 中标签类型为 $hold$ 的所有边的标签中的节点的集合],
    $P(T)$, [$T$ 中标签类型为 $pivot$ 的所有边的标签中的节点的集合],
  ),
  caption: [符号表],
)

#let origin = link("https://dl.acm.org/doi/10.1145/3336191.3371839")[原论文]

= Pivoter 算法
== Pivoter 算法简介
Pivoter 算法是 Shweta Jain 等人于 2020 年提出的一种精确计数团的算法, #origin;发表在 WSDM 2020 上.

Pivoter 算法借鉴了 BK 算法的 Pivot 思想, 通过选择一个顶点作为 Pivot 构建一种具有良好性质的新的递归树结构 SCT(Succinct Clique Tree, 简化团树) 大大减少了朴素递归算法的时空代价. Pivoter 算法的时间复杂度是 $O(alpha^2 abs(SCT(G)) + m + n)$, 空间复杂度是 $O(m + n)$.

== Pivoter 算法的思想
=== 朴素递归算法
我们可以先从朴素递归算法开始, 它的思路是: 所有包含 $v$ 的团都可以通过把 $v$ 添加到另一个团中得到, 后者所提到的团必定在 $N(v)$ 中.

所以我们可以通过下面的这个递归过程找到所有团:


#auto-div-pseudocode-list[
  #let GetCliques = $limits(bold("GetCliques"))$.body
  + $GetCliques(V)$
    + *If* $abs(V) <= 1$:
      + *Return* $[[v]]$
    + $R <-[]$
    + *For* $v$ *in* $V$:
      + $CC <- GetCliques(N(v))$
      + $CC <- CC union {C union {v} mid(|) C in CC}$
      + $R <- R union CC$
    + *Return* $R$
]


我们可以想到朴素递归算法的递归树:
- 每个节点都对应一个 $V$ 的子集 $S$, 大多数时候是某个顶点的邻居, 我们称之为节点的标签
- 标签为 $S$ 的节点的出连接对应了所有 $s in S$, 我们称之为连接的标签

于是我们可以看出, 从根路径出发向下的任何路径(可以不到叶子节点)都给出一个团, 也即这条路径途径的所有连接的标签, 而且我们能通过这种方式获得所有团. 这是因为

+ 一个标签为 $v$ 的节点的子树中的所有节点(包括子节点, 子节点的子节点, ...)显然都在 $N(v)$ 中, 也即他们都和 $v$ 有边. 对路径上的所有节点都应用这个观察即可得知这是一个团
+ 任取一个团 $v_1, v_2, v_3 ... v_n$, 显然 $v_1$ 标记的连接必定在递归树的根节点之下, 而 $v_2 ... v_n$ 都是 $v_1$ 的邻居, 他们必定在这一连接所连接的另一个节点的标签中, 然后便可以反复应用这一规则, 直到说明所有 $n$ 个节点都在树上, 而且呈一条向下的路径排列

但是显然这种方式会导致重复生成团, 一种避免的方式是对这个图生成一个有向无环图(DAG), 然后把 $N$ 修改为只给出出邻居节点.

但是即使如此, 在大型图上我们也不能完整地构建这个递归树. 所以 Pivoter 算法试图找出一种压缩这棵树, 而且获得所有团的唯一表示的方式.

=== Pivoter 和 SCT
对于上述递归树中的一个标签为 $S$ 的节点, 我们取出一个轴节点 $p in S$, 于是 $S$ 中的任一团 $C$ 可以被分为三类
+ $p in C$
+ $C subset N(p)$
+ $C$ 中有一个 $p$ 的非邻居
前两类之间有一一对应的关系: 把每个第一类团里面的 $p$ 拿掉就可以得到第二类团, 反之亦然, 于是我们这里可以只在树中继续处理第二类团.

对于这个节点, 我们递归调用以获取在 $N(p) inter S$ 和 $N(u) inter S$ 中的团, 其中 $u$ 是 $S$ 中 $p$ 的非邻居节点. 这两种团分别对应前面所说的第二类和第三类.

这里 $p$ 可以取度最高的节点, 这是因为节点的度越大, 他就更有可能在更多团中, 那我们省下的第一类节点的代价就越多.

按这种算法构造的递归树就是所谓 SCT. SCT 可以轻易在千万级的图上构建.

=== 使用 SCT 进行团计数
和一般递归算法的递归树相比, SCT 的每条路径 $T$ 的连接标签集仍然对应一个团, 但是不是所有团都有路径对应, 实际上, 这也是为什么一般递归算法的递归树如此巨大.

但是如果这样, 我们又如何使用 SCT 来计数所有团呢? 实际上这正是 Pivoter 算法的关键贡献所在: SCT 有一种良好的性质, 使得我们可以在图中找到所有团的唯一表示. 而我们正是通过这种方式来计数所有团的. 至于具体如何, 我们将在接下来的内容中介绍.

== Pivoter 算法的实现
=== SCT 的构建
在此之前, 我们要先具体定义 SCT 的结构:
- SCT 是一棵树.
- SCT 的每个节点都有一个标签, 这个标签是一个顶点集. 其中根节点的标签是 $V$.
- SCT 的每个连接都有一个标签, 这个标签是一个顶点-类型对, 也即 $(v, dot)$, 其中 $v$ 是该连接接近根节点一端的节点标签中的一个元素, 类型为 $pivot$ 或者 $hold$.

下面我们给出一个 SCT 的构建算法, 这是一个 BFS 算法.

#auto-div-pseudocode-list[
  #let BuildSCT = $limits(bold("BuildSCT"))$.body

  + $BuildSCT(G)$:
    + $N^+ <- bold("BuildDAG")(G)$
    + $"Init" tree "with root node" R "labeled by" V$
    + $Q <- "empty queue"$
    + *For* $v$ *in* $V$:
      + $cal(N) <- "new node labeled by "N^+ (v)$
      + $tree <- tree "with link labeled by" (v, hold) "from" R "to" v$
      + $"Push" cal(N) "into" Q$
    + *While* $Q "is not empty"$:
      + $cal(P) <- "pop node from" Q$
      + $S <- "label of" cal(P)$
      + *If* $S "is" diameter$:
        + *Continue*
      + $p <- arg max_p abs(N(S, p))$
      + $cal(N) <- "new node labeled by" N(S, p)$
      + $tree <- tree "with link labeled by" (p, pivot) "from" cal(P) "to" cal(N)$
      + $"Push" cal(N) "into" Q$
      + ${v_1, v_2, ..., v_l} <- S \\ (p union N(p))$
      + *For* $i < l$:
        + $cal(N)_2 <- "new node labeled by" N(S, v_i) \\ {v_1, v_2, ..., v_(i - 1)}$
        + $tree <- tree "with link labeled by" (v_i, hold) "from" cal(N) "to" cal(N)_2$
        + $"Push" cal(N)_2 "into" Q$
    + *Return* $bold(T)$
]
这其中新建到 $cal(N)$ 的连接和新建到 $cal(N)_2$ 的连接分别对应了上面所说的第二类和第三类团.

=== SCT 的性质及证明 <sect-sct-prop>
/ SCT 的唯一编码性: 对于图和在图上构建的 SCT $tree$, 图中的每个团都能被唯一表示为 $H(T) union Q$. 其中 $Q subset.eq P(T)$, $T$ 是 SCT 上一条从根到叶的路径.


我们可以看出, 每个从根到叶的路径都表示一个团, 也即 $H(T) union P(T)$. 其他的团可能就是这样的集合的子集. 这样的子集可能会多次出现, 但是如果我们考虑 $H(T)$ 和 $P(T)$ 的不同, 也即考虑连接的类型, 那么这种表示就是唯一的, 这也正是这个定理想要描述的内容.

证明:

考虑标签是 $S$ 的节点 $gamma$. 接下来我们将通过归纳 $abs(S)$ 证明, 每个团 $C subset.eq S$ 都可以表示为 $H(T) union Q$. 其中 $T$ 是一条从 $gamma$ 到叶子的路径, $Q subset.eq P(T)$.

这里对 SCT 的归纳是从下向上的(对应 $abs(S)$ 从小变大), 每次添加一个父亲节点到顶上, 下面归纳情况中我们添加的其实就是前面提到的节点 $gamma$.

+ 基本情况: $S$ 是空的, 其他所有相关内容都是空的, 自然成立.

+ 归纳情况: 令 $p$ 为构建 SCT 时运行到 $gamma$ 节点时选择的轴. 对于所有的团, 我们有三种情况, 分别对应了 SCT 构建时选取轴之后的三种情况.
  + $p in C$. 也即 $gamma$ 之下有一个标签为 $(p, pivot)$ 的连接, 连接到 $gamma$ 的一个子节点 $beta$. $beta$ 有标签 $N(S, p)$.

    - 存在性: 观察到 $C \\ p$ 是 $N(S, p)$ 中的一个团. 由归纳假设, $C \\ p$ 有一个唯一表示 $H(T) union Q$, 其中 $T$ 是从 $beta$ 到叶子的路径且 $Q subset.eq P(T)$. 而且 $C$ 没有一种这样的表示(利用从 $beta$ 到叶子的路径的), 因为 $N(S, p) in.rev.not p$.

      令 $T'$ 为包含路径 $T$ 而且从 $gamma$ 开始的路径, 则有 $H(T') = H(T)$, $P(T') = P(T) union p$. 于是可以把 $C$ 表达为 $H(T') union (Q union p)$, 其中 $Q union p subset.eq P(T')$.

    - 唯一性: 也即我们需要说明没有其他路径可以表示 $C$. 我们可以讨论上述表示中使用的路径 $T$
      + $T$ 没有经过 $beta$: 考虑任意从 $gamma$ 开始, 但是不经过 $beta$ 的路径, 它一定经由标签为 $(v_i, hold)$ 的路径经过了其他子节点, 其中 $v_i$ 是 $p$ 的非邻居. 那么由于 $p in C$, $p$ 的非邻居显然不在 $C$ 中, 所以利用这样的路径无法表示 $C$.

      + $T$ 经过 $beta$: 如果是经过了 $beta$ 的路径, 根据归纳假设即可知其唯一.

  + $C subset.eq N(S, p)$. 这种其实就是第一种情况的 $C$ 去除 $p$, 区别就是新增节点不在 $C$ 中. 所以表示也和第一种情况类似, 也即复用之前的表示的节点选取(从而没有加入 $p$), 但是使用包含 $gamma$ 的路径.

  + $C$ 包含一个 $p$ 的非邻居节点.

    我们先重复代码的步骤把各种符号都恢复出来: 还是令 ${v_1, v_2, ..., v_l} = S \\ (N(p) union p)$, 令 $i = arg min_(j; v_j in C) j$, 也即 $v_i$ 是这些 $v$ 中首个包含在 $C$ 中的节点. 对于任意的 $1 <= j <= l$, 令 $N_j := N(S, v_j) \\ {v_1, v_2, ..., v_(j-1)}$. 根据我们生成 SCT 的步骤, $gamma$ 下面有 $l$ 个标签为 $N_j$ 的孩子节点, 而且这些节点到 $gamma$ 的连接都是 $hold$ 类型的, 所以对于经过 $N_j$ 的路径 $T$, 有 $H(T) in.rev v_j$.($hold$ 型连接的标签的节点必定选取)

    - 存在性: 我们可以讨论将要在表示中使用的路径 $T$

      + $T$ 经过 $N_j, j < i$: 如果能利用 $T$ 表示 $C$, 它就不能经过 $j < i$ 的 $N_j$, 因为 $v_i$ 才是首个包含在 $C$ 中的节点, $v_i$ 之前的均不在 $C$ 中却被选取.

      + $T$ 经过 $N_j, j > i$: 如果 $j > i$, 那 $N_j in.not.rev v_i$ 更是没有路径能表示 $C$, 这是因为前面包含在 $C$ 中的 $v_i$ 被去掉了.

      + $T$ 经过 $N_j, j = i$: 由上述两种情况, 我们知道如果能利用一条路径表示 $C$, 那它一定经过 $N_i$. 注意到 $C \\ v_i$ 是在 $N_i$ 中的团, 由归纳假设, 有 $C \\ v_i$ 的唯一表示 $H(T) union Q$, 其中 $Q subset.eq P(T)$, $T$ 是从 $N_i$ 开始到叶子的路径. 令 $T'$ 为包含路径 $T$ 而且从 $gamma$ 开始的路径, 有 $H(T') = H(T) union v_i$, 所以 $C = H(T') union Q$.

    - 唯一性: 显然.

证毕.

另一方面, 每一个合法的表示显然都对应了一个团. 这其实与简单递归算法的递归树的情形类似: 因为父节点到子节点的连接标签的节点是父节点标签中的一个节点, 而子节点的标签都是他的邻居, 而且还是还是父节点标签的子集, 所以完整的路径都能表示一个团, 从里面去除一部分 $p$ 也是如此.

=== 利用 SCT 的唯一编码性进行团计数

根据上述关键定理, 一条从根到叶的路径 $T$ 表示了 $2^(P(T))$ 个不同的团. 其中大小为 $abs(H(T)) + i$ 的有 $binom(P(T), i)$ 个, 所以我们可以轻易得出如下算法.
#auto-div-pseudocode-list[
  #let Pivoter = $limits(bold("Pivoter"))$.body
  + $Pivoter(G)$:
    + $bold(T) <- bold("BuildSCT")(G)$
    + $R <- [0, 0, ...]$
    + *For* $T$ *in* $bold(T)$:
      + *For* $i<= abs(P(T))$:
        + $R[abs(H(T)) + i] <- R[abs(H(T)) + i] + binom(P(T), i)$
    + *Return* $R$
]
当然, 这只是针对我的任务, 也即全局团精确计数的 Pivoter 算法. 对于边或者顶点参与的团计数, 或者列出所有团, 只需要在上述算法中稍作修改即可.

== Pivoter 算法的复杂度分析
参见#origin.

== Pivoter 算法的代码实现
我在网络上找到了两个 Pivoter 算法的实现:
- 论文作者给出的 C 语言实现: #link("https://bitbucket.org/sjain12/pivoter/")[Bitbucket 仓库]
- charunupara 给出的 Julia 实现: #link("https://github.com/charunupara/Pivoter")[GitHub 仓库]

另外, 我基于论文作者的 C 语言实现, 修改了一个只有全局团计数的 C++ 实现: #link("https://github.com/ParaN3xus/litman/tree/main/backend/pivoter")[GitHub 仓库].

不过这些实现都没有提供并行化的版本. 一些更新的算法的论文中提到了他们的算法和并行 Pivoter 算法的比较, 但是并没有提供代码.


