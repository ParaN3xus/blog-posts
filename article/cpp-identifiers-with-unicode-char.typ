#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "C++ 标识符中的 Unicode 字符",
  desc: [
    C++ 中标识符的命名规则, 以及 Unicode 字符在其中的应用.
  ],
  date: "2023-09-16",
  tags: (
    blog-tags.cpp,
    blog-tags.programming,
  ),
)

这其实是我的课程作业, 但是因为确实解决了我的一大疑惑和内容比较充实, 所以发到这里.

在 C++ References 的 Language 栏目下的 Identifiers 栏目中, 有关于 C++ 中标识符命名规则的说明#footnote(link("https://en.cppreference.com/w/cpp/language/identifiers")[Identifiers - cppreference.com]):

- 首字符应为:
  - 大小写字母
  - 下划线
  - 带有 `XID_Start` 属性的任意 Unicode 字符
- 其他字符应为:
  - 数字
  - 大小写字母
  - 下划线
  - 带有 `XID_Continue` 属性的任意 Unicode 字符

原网页在两个规则的最后一条末尾给出了一个链接, 指向 2023 年 9 月 1 日发布的 Unicode 15.1.0 标准的第 31 号附件: UNICODE IDENTIFIERS AND SYNTAX. 这个附件的表2#footnote(link("https://www.unicode.org/reports/tr31/=Table_Lexical_Classes_for_Identifiers")[UAX =31: Unicode Identifiers and Syntax])指出了上述规则中提到的 `XID_` 属性的说明和覆盖范围:

- `XID_Start`: 根据 NFKC 修改#footnote(link("https://www.unicode.org/reports/tr31/=NFKC_Modifications")[UAX =31: Unicode Identifiers and Syntax])从 `ID_Start` 派生
- `XID_Continue`: 根据 NFKC 修改从 `ID_Continue` 派生

这里 `XID_` 中的 `X` 大概表示 `Extended`, 实际意义就是其从 `ID_` 中经过 `NFKC`(Normalization Form Compatibility Composition)派生. 在表格中, 同样给出了 `ID_` 属性的说明和覆盖范围:

- `ID_Start`
  - 大小写字母
  - titlecase letters (似乎与希腊语有关, 这里因为和“大写字母”翻译重合不再翻译)
  - modifier letters (同上, 但似乎不是希腊语)
  - other letters (同上)
  - letter numbers (同上, 类似于各种语言的罗马数字)
  - 除 `Pattern_Syntax` 和 `Pattern_White_Space`x的 `Other_ID_Start`

- `ID_Continue`
  - 符合`ID_Start`属性的字符
  - 非间距标记
  - 间距组合标记
  - 数字
  - 连接符标点
  - 除`Pattern_Syntax`和`Pattern_White_Space`#footnote(link("https://www.unicode.org/reports/tr31/=R3")[UAX =31: Unicode Identifiers and Syntax])的`Other_ID_Continue`

其中仍然存在的一些不明属性因过于无聊和没有必要不再展开.

其中, 平常提到的希腊字母在小写字母的范畴内, 大部分中文汉字和其他国家的文字在 other letter 范畴内. 因此实际上你可以用中文、希腊字母做标识符名字的一部分.

但是, 在实际测试中, gcc 10.2.1 能够正确识别由 Emoji 表情符号组成的标识符, 而 Emoji 表情所属的 other symbol 并不在上述属性的范围内. 说明编译器开发者对待标准的态度也不是那么一板一眼.

需要注意的是, 以上所说的内容只适用于 C++11 及之后的标准. 实际上, C++ 的 Unicode 字符支持首次出现是在 N3337 草案#footnote(link("https://timsong-cpp.github.io/cppwp/n3337/")[14882: Contents (timsong-cpp.github.io)])中, 这是C++11发布后的第一个标准草案, 对 C++11 标准做了一些重要的修改, 应用于 C++11 标准.
