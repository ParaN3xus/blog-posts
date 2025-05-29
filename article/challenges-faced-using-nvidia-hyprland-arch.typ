#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "NVIDIA + Hyprland + Arch 踩坑",
  desc: [使用 NVIDIA 显卡和 Hyprland 在 Arch Linux 上的经验分享],
  date: "2024-08-01",
  tags: (
    blog-tags.linux,
  ),
  license: licenses.cc-by-nc-sa,
)

继 Debian + Gnome 用了没几天就换回 Windows 吃灰后, 又下定了一次决心日用纯 Linux 系统. 这一次我装了 Arch + Hyprland, 在 Arch 强大的生态和自定义能力的加持下终于也算用了一个月. 虽然系统还是有各种小问题无法解决, 但是稍微忍忍已经完全能用了. 所以这篇 Blog 就是记录我是怎么调教 NVIDIA + Hyprland + Arch 打到一个相对良好的状态的.

不过还有很多问题我没有解决, 也一同记录在下面, 就当作是一个 TODO List 了, 没事的时候我会来看看的.

= NVIDIA 驱动开机崩溃

我因为有使用 CUDA 的需要, 所以安装了 NVIDIA 的闭源驱动, 然后就出现了这个问题.

主要表现为开机概率性的崩溃, 这个原因就是 NVIDIA 驱动和内核的兼容性不太好, 最终我在 `linux-lts + nvidia-dkms` 上实现了稳定.

本文写作时, 上述软件包的版本为:
- `linux-lts: 6.6.42-1`
- `nvidia-dkms: 555.58.02-1`

= 双屏幕双显卡的配置

本来我想核显一个屏幕, 独显一个屏幕, 但是无论怎么配置都没法正常用, 主要表现为要么两个屏幕都黑屏, 要么一个黑屏, 反正就是没法正常用.

最后终于在 Hyprland Wiki 上找到了明确的说明, 在 Windows 上如此自然的想法是不可能的, 我们必须关掉核显. #footnote(link("https://wiki.hyprland.org/Nvidia/=multi-monitor-with-hybrid-graphics")[Hyprland Wiki - Multi-Monitor with Hybrid Graphics])

= 双屏幕不同 DPI 下 XWayland 应用的缩放

这个要求主线目前做不了, 不过 Hyprland 社区已经有相关 PR #footnote(link("https://github.com/hyprwm/Hyprland/pull/6446")[hyprwm/Hyprland - xwayland: support HiDPI scale]). 经过本人测试工作良好, 可按照 PR 内指引尝试.

= QQNT 不能复制

这个问题是给 Electron 指定平台参数:
```shell
--enable-features=UseOzonePlatform --ozone-platform=wayland
```
引起的.

我曾经在各种社区或者 issue 里找到了一些用于修复复制粘贴问题的脚本, 但是这些脚本似乎都会破坏其他功能, 因此我没有最终使用.

我的建议是仍然使用 XWayland 模式, 虽然不能缩放, 但是至少能复制粘贴.

= Emoji Picker

我始终觉得输入 "haha" 来调用 Emoji 表情非常蠢而且尴尬, 所以还是选择找一个好用的 Emoji Picker.

经过一番寻找, 我发现这个还不错: [im-emoji-picker](https://github.com/GaZaTu/im-emoji-picker).

不过要让他在 Hyprland 下良好的工作, 还需要设置一些简单的 WindowRules, 这里是我的配置:
```ini
windowrulev2 = nofocus,initialTitle:^(im-emoji-picker)$
```

= RIME 配置

虽然输入法本身和 Wayland 之类的关系不大, 但是作为我调整系统过程的一个重要部分, 我还是选择写在这里.

RIME 的配置用的是 "预构建配置 + 用户自定义 Patch" 的形式, 但是他们的文档讲的不是很清楚, 我花了很长时间才搞明白要怎么用.

我使用的预构建配置是: [rime-ice](https://github.com/iDvel/rime-ice).

我主要是取消了中英文切换的 Shift 快捷键, 然后修改了默认标点为半角, 并设置页面选项数为 9, 并且默认不显示那些我用不到的配置. 具体需要进行如下修改:

`~/.local/share/fcitx5/rime/default.custom.yaml`
```yaml
patch:
  "menu/page_size": 9
  schema_list:
    - schema: luna_pinyin_simp

  "ascii_composer/switch_key/Shift_L": none
```

`~/.local/share/fcitx5/rime/luna_pinyin_simp.custom.yaml`
```yaml
patch:
  "menu/page_size": 9
  "switches/@3/reset": 1

  "ascii_composer/switch_key/Shift_L": none
```

= 小键盘有时失灵

具体表现为小键盘灯亮着但是实际上不能用, 需要按一下关闭再按一下打开, 或者(有时)切换输入法再切回来.

因为后面这个解决方式, 我猜测这个和输入法有关, 但是目前还没得到验证, 也没找到靠谱的解决方式.

= 截图不显示鼠标失效 + 选择光标会被截上

我目前用 `grimblast` + `screenshot.sh`#footnote(link("https://github.com/prasanthrangan/hyprdots/blob/main/Configs/.local/share/bin/screenshot.sh")[screenshot.sh]) 进行截图.

前一个问题我没什么头绪, 这似乎和 `screenshot.sh` 冻结屏幕的方式有关, 也有可能和 `hyprpicker` 有关. 我不太确定.

后一个问题似乎与用于 freeze 屏幕的 `hyprpicker` 有关#footnote(link("https://github.com/hyprwm/hyprpicker/issues/65")[hyprwm/hyprpicker - Add a flag to hide the cursor in hyprpicker]), 但是还没有修复. Github 的相关 issue #footnote(link("https://github.com/hyprwm/contrib/issues/60")[hyprwm/contrib - Area selection cursor is shown in final screenshot])
有一些 workround, 但是对我没用.

= 截图后有时 `hyprpicker` 不能正常退出导致屏幕无法操作

这个比较容易修复, 但是我还没有实践, 主要是因为出现概率比较小 + 修复简单.

遇到这种情况切到其他 tty 然后手动 `kill` 掉 `hyprpicker` 进程即可.

= Special Workspace 中 XWayland 应用遮挡输入法

这个是一个尚未修复 Bug, 在 Hyprland 仓库有相关 #link("https://github.com/hyprwm/Hyprland/issues/3503")[issue].

不过就作者态度来看, 他大概不太会想修这个 Bug 了.

= float 窗口关闭时 focus 不会自动转移到鼠标所在的位置

#strike[我觉得这是个很典型的 Bug, 但是似乎 Hyprland 到现在也没有修复? 我也没有找到相关 issue.]

我创建了一个 #link("https://github.com/hyprwm/Hyprland/pull/7368")[PR] 用于添加一个选项指定窗口关闭时, focus 转移的行为. 现在只需要指定 `input::focus_on_close = 1` 就能实现想要的效果.


= Chromium 首屏有概率渲染错乱

在 `~/.config/chromium-flags.conf` 文件中指定
```shell
--enable-wayland-ime
--ozone-platform=wayland
--use-angle=vulkan
```

但是这样做会导致 B 站不能播放视频, 目前还没有找到解决方案.
