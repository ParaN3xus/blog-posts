#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "C++ 学习笔记: 输入输出",
  desc: [C++ 的输入输出方法和重定向到文件的技巧],
  date: "2023-09-03",
  tags: (
    blog-tags.cpp,
    blog-tags.programming,
  ),
)


= 输入

== `scanf()`

可读取固定格式的输入.

用法:

```cpp
scanf(format, contents...)
```

其中, `format` 可填写的占位符有:

- `%d`: `int` (十进制)
- `%u`: `uint` (十进制)
- `%o`: `int` (八进制)
- `%x`/`%X`: `int` (十六进制)
- `%i`: `int` (十六、十、八进制)
- `%f`: `float`/`double`
- `%e`: `float`/`double` (以科学计数法形式表示)
- `%g`: `float`/`double` (科学计数法和正常形式表示皆可)
- `%s`: `string`
- `%c`: `char`
- `%p`: `void*`

== `getchar()`

可以读取一个字符, 返回值即为读取的一个字符, 当输入结束时, 会返回一个特殊的常量 `EOF`(End of File).

== `fgets()`

可读取一行.

用法:

```cpp
fgets(chararr, sizeof(chararr), stream)
```

当使用控制台输入时, `stream` 可填写 `stdin`.

== `getline()`

可读取一行.

用法：

```cpp
getline(cin, str)
```

== `cin`

`cin` 为标准输入流, 可使用以下方法读入空格、回车、占位符分割的数据:

```cpp
cin >> var1 >> var2 ...;
```

= 输出

== `printf()`

与 `scanf()` 类似.

== `putchar()`

输出一个字符.

== `cout`

`cout` 为标准输出流, 可使用以下方法输出无分割的数据:

```cpp
cout << val1 << val2 ...;
```

= 重定向到文件

== `freopen()`

用法:

```cpp
freopen(filename, mode, stream);
```

其中 `mode` 可以填写下列选项, 或它们的组合:

- `"r"`: 读
- `"w"`: 写
- `"a"`: 追加

此外, `stream` 可以填写类型为 `FILE *` 的任意变量, 如果要将控制台的输入输出重定向到文件, 只需要对输入输出文件分别填写 `stdin` 和 `stdout`.
