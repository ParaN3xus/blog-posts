#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "一行命令提升 WSL 使用体验",
  desc: [
    在 WSL 中创建一个 alias, 直接使用 Windows 文件资源管理器打开目录或文件.
  ],
  date: "2023-10-28",
  tags: (
    blog-tags.linux,
  ),
  license: licenses.cc-by-nc-sa,
)

简而言之, 运行：
```shell
echo "alias open=\"explorer.exe\"" >> ~/.bashrc && source ~/.bashrc
```
现在你可以：

- 运行 `open path` 使用 Windows 文件资源管理器直接打开某个目录(可使用 `.`, `~` 等)
- 运行 `open filename` 使用 Windows 默认打开方式(若未指定则要求你选择)打开某个文件. (比如我想用 Typora 编辑 WSL 里面的 markdown 文件)

我感觉很爽, 但是似乎没有看到太多人这么做, 所以分享出来(虽然没什么技术含量).
