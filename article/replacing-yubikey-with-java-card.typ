#import "/typ/templates/blog.typ": *
#import "/typ/utils.typ": gh-repo

#show: main.with(
  title: "用 Java Card 平替 YubiKey",
  desc: [
    使用 J3R180 卡片和一些 Java Card Applet 在低预算下实现 YubiKey 的主要功能.
  ],
  date: "2026-11-19",
  tags: (
    blog-tags.diy,
  ),
  license: licenses.cc-by-nc-sa,
)

#set heading(numbering: "1.")

常见的 YubiKey 5 系列产品很贵. 其中的 "标准款" YubiKey 5C NFC 在#link("https://www.yubico.com/product/yubikey-5-series/yubikey-5c-nfc/")[官网]上的价格为 58 USD, 也即约 390 CNY. 在国内电商平台的价格往往大于 600 CNY.

YubiKey 5C NFC 有诸多功能, 然而其中的很多都可以通过在特定智能卡上运行的 Java Card Applet 实现, 如下表.

#figure(
  table(
    columns: 4,
    align: horizon,
    table.header([YubiKey 5C NFC 功能], [是否可使用 Java Card Applet 实现], [已有的实现], [备注]),

    [FIDO2, CTAP2.1],
    sym.checkmark,
    gh-repo("https://github.com/BryanJacobs/FIDO2Applet"),
    [没有 FIDO2 L2 认证, 可以存储的 resident key 取决于卡片内存],

    [OpenPGP], sym.checkmark, gh-repo("https://github.com/github-af/SmartPGP"), [支持的加密算法类型有差异],

    [Smart card (PIV)],
    sym.checkmark,
    gh-repo("https://github.com/makinako/OpenFIPS201"),
    [可以存储的证书数量取决于卡片内存, 本文未涉及],

    [OATH],
    sym.checkmark,
    gh-repo("https://github.com/Yubico/ykneo-oath"),
    [可以存储的 OATH 数量取决于卡片内存, 本文未涉及],

    [Static password], sym.crossmark, [], table.cell(rowspan: 3)[依赖 HID 键盘模拟. Java Card 不具备此功能 ],
    [Challenge-response], sym.crossmark, [],
    [Yubico OTP], sym.crossmark, [],
  ),
  caption: [YubiKey 5C NFC 的功能与该功能是否可使用 Java Card Applet 实现的情况],
)

而实现这些功能所需的 Java Card 和读卡器(可选), 以本文使用的 NXP J3R180 和 ACR38U-N1 PocketMate 为例, 分别只需要约 30 CNY 和约 70 CNY.

本文记录我使用 NXP J3R180 DIY 一个用于平替 YubiKey 的硬件安全密钥的过程. 由于我只需要 FIDO2 和 OpenPGP 的功能, 因此下面的教程不涉及 PIV 和 OATH 这些 YubiKey 特性的实现.

= 使用体验

- Android 手机
  - Passkey: 可以正常使用 Authnkey 或 Android 的 NFC Passkey 功能.
  - SSH: 没有找到可以使用 FIDO2 Resident Key 的 SSH 应用.
  - 安全邮件: 无需额外配置即可使用 #link("https://f-droid.org/en/packages/com.pgpony.android/")[PGPony] 和 #link("https://f-droid.org/packages/net.thunderbird.android/")[Tunderbird] 对邮件进行签名和加密.
- Linux / Windows PC
  - Passkey: 取决于你所选择的连接卡片的方式
    - 若使用接触式读卡器, 则需要额外安装一个对应的中间件, 此后可以正常使用
    - 若使用 Android 手机作为 NFC 读卡器, 则需要安装 vpcd 服务端, 此后将手机作为无线 NFC 读卡器使用
    之后正常使用 WebAuthn 功能.
  - SSH: SSH 客户端无需中间件即可使用卡片上的 resident key.
  - Git 提交签名: 可以良好地使用 GPG 签名. 在 Windows 上, 需要安装对应的中间件以使用 SSH 签名.
  - 安全邮件: 可以正常使用调用 gpg 命令行的客户端.

= 成本

#figure(
  table(
    columns: 4,
    table.header([物品], [数量], [价格 (CNY)], [备注]),
    ..{
      let costs = (
        ([NXP J3R180 双界面白卡], 2, 25, [多一张作为备份]),
        ([ACR38U-N1 PocketMate 读卡器], 1, 66.2, [USB-A 接口, 可选]),
        ([ACR39U-NF PocketMate II 读卡器], 1, 110, [USB-C 接口, 可选]),
        ([NFC 屏蔽卡套], 2, 5, [可选]),
        ([卡贴], 1, 10, [可选, 因为白卡比较难看]),
      )

      costs.map(x => {
        let (a, b, c, d) = x
        (a, str(b), str(c), d)
      })
      (
        (
          [*合计*],
          [],
          str(
            costs
              .map(x => {
                let (_, n, m, _) = x
                n * m
              })
              .sum(),
          ),
          [含可选部分, 推荐配置为 136.2],
        ),
      )
    }.flatten(),
  ),
  caption: [成本],
)

= 卡片配置

配置过程在 Linux 环境中完成, 笔者使用的是 Windows 11 上的 WSL 2 Arch Linux.

== 卡片连接

需要安装 #link("https://pcsclite.apdu.fr/")[pcsclite], #link("https://ccid.apdu.fr/")[ccid], #link("https://pcsc-tools.apdu.fr/")[pcsc-tools] 这几个软件. 特别地, 对于 Arch Linux 用户来说, 这可以通过执行

```shell-unix-generic
sudo pacman -Syu pcsclite ccid pcsc-tools opensc
sudo systemctl enable --now pcscd.socket
```

完成.

接下来, 取决于你是否购买了接触式读卡器, 这里有两种方案.

=== 使用接触式读卡器 <sect-contact-reader>

- 对于 Windows 用户: 可以参考 #link("https://frankmorgner.github.io/vsmartcard/virtualsmartcard/README.html#installation")[vsmartcard 文档] 的指引在 PC 上安装 vpcd, 然后使用一个 #link("https://github.com/ParaN3xus/java-card-utils/blob/main/vpcd_bridge.py")[桥接脚本] 将接触式读卡器作为 vpcd 的客户端. 桥接脚本可以使用该仓库中的 #link("https://github.com/ParaN3xus/java-card-utils/blob/main/setup_vpcd_bridge.ps1")[setup_vpcd_bridge.ps1] 安装
- 对于 Linux 用户: 可以使用 #gh-repo("https://github.com/neroduality/pcsc-fido/") 将接触式读卡器转为 USB HID 设备
- 对于 WSL 用户: 可以参照 #link("https://learn.microsoft.com/en-us/windows/wsl/connect-usb")[教程] 使用 usbipd 将接触式读卡器转发至 WSL 内. 配置阶段不需要中间件, 实际上你也没有中间件可以安装. 使用时, 受此影响, 你无法使用 WebAuthn

=== 使用 #gh-repo("https://github.com/frankmorgner/vsmartcard") 转发 Android 手机的 NFC <sect-android-as-a-nfc-reader>

在 Android 手机上安装 #link("https://f-droid.org/packages/com.vsmartcard.remotesmartcardreader.app/")[Smart Card Reader]. 然后参考 #link("https://frankmorgner.github.io/vsmartcard/virtualsmartcard/README.html#installation")[vsmartcard 文档] 的指引在 PC 上安装 vpcd.

特别地, 在 Arch Linux 上, vpcd 可以通过 AUR 包 #link("https://aur.archlinux.org/packages/virtualsmartcard")[virtualsmartcard] 安装.

调整防火墙规则使得 Android 手机能访问 PC 的 35963 端口, 然后在 Smart Card Reader App 的设置中调整 VPCD Hostname 和 VPCD Port (默认为 35963) 为实际值.

使用时, 只需要打开 Smart Card Reader App 后将卡片贴在手机的 NFC 位置上, App 应该读取到卡片并自动连接服务器. 注意不要点击右上角的按钮, 即使状态异常也尽量用重新贴放卡片和重启 App 的方式解决, 因为使用右上角的按钮启动连接时, App 会使用一个内置卡片进行测试, 这有可能干扰我们的作业.

== 卡片密钥验证

连接卡片后, 执行 `pcsc_scan`, 可以看到如下信息.

```shell-unix-generic
$ pcsc_scan
PC/SC device scanner
V 1.7.5 (c) 2001-2026, Ludovic Rousseau <ludovic.rousseau@free.fr>
Using reader plug'n play mechanism
Scanning present readers...
0: Virtual PCD 00 00
1: Virtual PCD 00 01

Sat Nov 14 03:46:45 2026
 Reader 0: Virtual PCD 00 00
  Event number: 0
  Card state: Card removed,
 Reader 1: Virtual PCD 00 01
  Event number: 1
  Card state: Card inserted,
  ATR: ** ** ** ** ** ** ** ** ** **
```

此处状态为 `Card inserted` 的 `Virtual PCD 00 01` 是我们接下来的工作对象.

```shell-unix-generic
export READER="Virtual PCD 00 01"
```

安装 #gh-repo("https://github.com/martinpaljak/GlobalPlatformPro"). Arch 用户可以安装 AUR 包 #link("https://aur.archlinux.org/packages/globalplatformpro")[globalplatformpro].

取决于商家是否已经为你初始化卡片, 你收到卡片时可能同时收到或没有收到 GP 密钥组 (也即 ENC, MAC, DEK (有时也叫 KEK 或 KIK)). 若没有, 这三者可能都是默认密钥 `404142434445464748494A4B4C4D4E4F`. GlobalPlatformPro (`gpp`) 会自动读取下面的变量.

```shell-unix-generic
export GP_KEY_ENC=********************************
export GP_KEY_MAC=********************************
export GP_KEY_DEK=********************************
```

然后执行

```shell-unix-generic
gpp -l -r "$READER"
```

若密钥错误, 你将得到如下输出

```shell-unix-generic
Failed to open secure channel: Card cryptogram invalid!
Received: ****************
Expected: xxxxxxxxxxxxxxxx
!!! DO NOT RE-TRY THE SAME COMMAND/KEYS OR YOU MAY BRICK YOUR CARD !!!
Read more from https://github.com/martinpaljak/GlobalPlatformPro/wiki/Keys
```

如其所声称的, 不要重复尝试这个命令, 取决于卡的操作系统和厂商配置, 卡片可能在 3-10 次错误尝试后被锁定. 因此当你遇到这个情况且你确认你提供的密钥无误, 你最好和商家取得联系并询问具体情况.

== 删除无用包

若密钥正确, 你将得到这张卡的卡面清单, 也即这张卡片已经加载的 Java Card 包. 例如

```shell-unix-generic
ISD: A000000151000000 (OP_READY)
     Parent:   A000000151000000
     From:     A0000001515350
     Privs:    SecurityDomain, CardLock, CardTerminate, CardReset, CVMManagement, TrustedPath, AuthorizedManagement, TokenVerification, GlobalDelete, GlobalLock, GlobalRegistry, FinalApplication, ReceiptGeneration

PKG: A0000001515350 (LOADED)
     Parent:   A000000151000000
     Version:  255.255
     Applet:   A000000151535041

PKG: A00000016443446F634C697465 (LOADED)
     Parent:   A000000151000000
     Version:  1.0
     Applet:   A00000016443446F634C69746501

PKG: A0000000620204 (LOADED)
     Parent:   A000000151000000
     Version:  1.0

PKG: A0000000620202 (LOADED)
     Parent:   A000000151000000
     Version:  1.3
```

其中 `ISD(Issuer Security Domain): A000000151000000` 为卡管理器, `PKG: A0000001515350` 为辅助安全域创建包. 其余三个应该是厂商预载的例程, 我们留着没用, 可以删掉. 判断一个包能不能删的一个简单方法是看他的 AID 是否以 `A000000151` 开头. `A000000151` 是 GlobalPlatform 保留的 AID 空间, 凡是以它开头的都是 GP 系统组件, 因此最好不要删除. 如果实在不确定, 也可以直接搜索 AID 来确定其是什么包, 进而决定是否删除.

```shell-unix-generic
gpp --delete A00000016443446F634C697465 -r "$READER"
gpp --delete A0000000620204 -r "$READER"
gpp --delete A0000000620202 -r "$READER"
```

验证删除.

```shell-unix-generic
$ gpp -l -r "$READER"
ISD: A000000151000000 (OP_READY)
     Parent:   A000000151000000
     From:     A0000001515350
     Privs:    SecurityDomain, CardLock, CardTerminate, CardReset, CVMManagement, TrustedPath, AuthorizedManagement, TokenVerification, GlobalDelete, GlobalLock, GlobalRegistry, FinalApplication, ReceiptGeneration

PKG: A0000001515350 (LOADED)
     Parent:   A000000151000000
     Version:  255.255
     Applet:   A000000151535041
```

== 卡片功能验证

若使用 Android 手机转发 NFC 连接卡片, 在进行这一步前, 需要在 Smart Card Reader App 的设置中调整 "Delay for Card Response" 为 30 秒.

查看卡片信息.

```shell-unix-generic
$ gpp -i -r "$READER"
...
Tag 66: 1.3.6.1.4.1.42.2.110.1.3
-> JavaCard v3
...
```

这里 Tag 66 会给出卡片支持的 Java Card 大版本, 我们这里是 v3.

下面我们将使用 #gh-repo("https://github.com/crocs-muni/JCAlgTest") 进行卡片算法支持情况的测试. 从 #link("https://github.com/crocs-muni/JCAlgTest/releases/latest")[Release] 中下载, JCAlgTest, 解压后将得到数个不同 Java Card 版本的 `.cap` 包和 `AlgTestJClient.jar`.

从最高版本开始尝试为卡片刷入 JCAlgTest.

```shell-unix-generic
gpp --install AlgTest_v1.8.4_jc305.cap -r "$READER"
```

直到显示如

```shell-unix-generic
AlgTest_v1.8.4_jc305.cap loaded: algtest 4A43416C6754657374
```

的成功消息为止.

执行测试.

```shell-unix-generic
java -jar AlgTestJClient.jar -op ALG_SUPPORT_EXTENDED
```

这里需要选择读卡器和输入卡片型号, 型号可输入 `NXP J3R180`. 输入后, 该测试将持续运行 10 分钟左右. 测试结束后, 你将得到一个 csv 文件, 里面包含了该卡片的基本信息和一些算法的支持情况.

我编写了一个 #link("https://github.com/ParaN3xus/java-card-utils/blob/main/jcalgtest_compare.py")[脚本] 用于对比两个 csv. 使用时, 需要先从 #link("https://github.com/crocs-muni/jcalgtest_results/tree/main/javacard/Profiles/results")[jcalgtest_results] 下载一个同型号的 csv 作为参考, 我这里选择的是 #link("https://github.com/crocs-muni/jcalgtest_results/blob/main/javacard/Profiles/results/NXP_JCOP4_J3R180_8PIN_ALGSUPPORT__3b_d5_18_ff_81_91_fe_1f_c3_80_73_c8_21_10_0a_(provided_by_ameneko).csv")[ameneko 提供的同型号卡片的测试结果].

```shell-unix-generic
$ python jcalgtest_compare.py my.csv ref.csv
A: my.csv (4438 entries)
B: ref.csv (4436 entries)
common: 4436 | identical: 4371 | differing: 65
similarity: 98.53%
...
```

可以看到相似度达到了 $98.53%$, 人工审阅脚本输出的差异后, 我发现我在淘宝商家 #link("https://shop106589700.taobao.com/")[mango智能卡] 处购买的卡片和参考卡片没有明显差异.

测试完成后可以删除 JCAlgText.

```shell-unix-generic
$ gpp -l -r "$READER"
ISD: A000000151000000 (OP_READY)
     Parent:   A000000151000000
     From:     A0000001515350
     Privs:    SecurityDomain, CardLock, CardTerminate, CVMManagement, TrustedPath, AuthorizedManagement, TokenVerification, GlobalDelete, GlobalLock, GlobalRegistry, FinalApplication, ReceiptGeneration

APP: 4A43416C675465737431 (SELECTABLE)
     Parent:   A000000151000000
     From:     4A43416C6754657374

PKG: A0000001515350 (LOADED)
     Parent:   A000000151000000
     Version:  255.255
     Applet:   A000000151535041

PKG: 4A43416C6754657374 (LOADED)
     Parent:   A000000151000000
     Version:  0.0
     Applet:   4A43416C675465737431
```

这里 `4A43416C6754657374` 是测试包, `4A43416C675465737431` 是其实例, 用于存储数据. 我们一并删除.

```shell-unix-generic
gpp --delete 4A43416C675465737431 --delete 4A43416C6754657374 -r "$READER"
```

== 安装 FIDO2Applet

我们使用 #gh-repo("https://github.com/BryanJacobs/FIDO2Applet") 来实现 YubiKey 5C NFC 的 FIDO2 相关功能, 如 PassKey.

构建 FIDO2Applet. 这个步骤需要你使用 JDK 8.

```shell-unix-generic
git clone --recursive https://github.com/BryanJacobs/FIDO2Applet
cd FIDO2Applet
JC_HOME=sdks/jc303_kit ./gradlew buildJavaCard
```

输出应为

```shell-unix-generic
...
[ant:verify] Verification passed
[ant:cap] CAP saved to build/javacard/FIDO2.cap
...
```

获取安装参数

```shell-unix-generic
$ export PARAMS=$(python3 get_install_parameters.py --force-always-uv --protect-against-reset --high-security --high-security-rks)
$ echo $PARAMS
ab01f402f503f404f50505061820071904000818200918fe0a1904000b190400
```

此处
- `--force-always-uv`: 要求操作必须经过用户验证, 也即输入 PIN. 这里开启是因为我不希望我的硬件密钥被其他人拿到后能直接使用
- `--protect-against-reset`: 要求重置卡片需要发送 reset, 断电, 然后再次发送 reset. 防止恶意软件重置卡片.
- `--no-high-security`, `--no-high-security-rks`:  `--force-always-uv` 的执行, 防止一些情况下直接使用低安全密钥创建凭据.

安装.

```shell-unix-generic
$ gpp --install build/javacard/FIDO2.cap --params $PARAMS --privs CardReset -r "$READER"
build/javacard/FIDO2.cap loaded: us.q3q.fido2 A000000647
[WARN] GPSession - Installation parameters did not parse as valid TLV, assuming simple app parameters!
```

列出卡面.

```shell-unix-generic
$ gpp -l -r "$READER"
ISD: A000000151000000 (OP_READY)
     Parent:   A000000151000000
     From:     A0000001515350
     Privs:    SecurityDomain, CardLock, CardTerminate, CVMManagement, TrustedPath, AuthorizedManagement, TokenVerification, GlobalDelete, GlobalLock, GlobalRegistry, FinalApplication, ReceiptGeneration

APP: A0000006472F0001 (SELECTABLE)
     Parent:   A000000151000000
     From:     A000000647
     Privs:    CardReset

PKG: A0000001515350 (LOADED)
     Parent:   A000000151000000
     Version:  255.255
     Applet:   A000000151535041

PKG: A000000647 (LOADED)
     Parent:   A000000151000000
     Version:  0.4
     Applet:   A0000006472F0001
```

== 配置 FIDO2Applet

需要安装 Android App #link("https://f-droid.org/packages/pl.lebihan.authnkey/")[Authnkey].

=== 设置 PIN

打开 Authnkey, 将卡片贴住手机, Authnkey 应该能连接卡片, Change PIN 按钮应该亮起. 然后使用 Change PIN 为卡片设置 PIN.

=== 使用 PassKey

这里以测试网站 WebAuthn 为例.

==== Android 手机

在 Android 手机中打开 #link("https://webauthn.io/")[WebAuthn.io], 输入一个用户名, 点击 Register 后, 系统应该弹出创建 PassKey 的提示. 这里可以选择 Authnkey, 也可以选择 Another Device 中的 NFC security key, 然后安装提示操作即可. 这两者是等价的.

之后点击 Authenticate 即可使用刚刚创建的 PassKey 来认证. 创建的 PassKey 可以在 Authnkey 中使用 List Saved Credentials 删除.

注意若需要多次测试, 尽量在每次注册时使用一个新的用户名, 以防止一些机制的干扰.

==== PC

Windows 上的 WebAuthn 只认可 USB HID 和 NFC 传输, Linux 上的 WebAuthn 只认可 USB HID 传输, 而接触式读卡器在系统里是 CCID 智能卡设备, 并不能用于 WebAuthn. 对此, 我们可以
- 用 Android 手机作为 NFC 读卡器, 见 @sect-android-as-a-nfc-reader
- 使用接触式读卡器, 并如 @sect-contact-reader 所述的安装对应系统的中间件

之后的操作应该和 Android 手机类似.

=== SSH Key 作为 Resident Key

生成密钥

```shell-unix-generic
ssh-keygen -t ecdsa-sk -O resident -O verify-required -O application=ssh:机器名字 -C "注释"
```

之后私钥就会驻留在卡上, 和普通的 ssh key 几乎是一样的, 除了认证时需要插卡和输入卡片的 PIN.

除此之外, 使用

```shell-unix-generic
ssh-keygen -K
```

可以拉取卡片上的所有 ssh key 的句柄 (用来调用卡片上的私钥) 和公钥. 这个命令在 Windows 上由于 SK provider 的原因无法使用.


== 安装 SmartPGP

我们使用 #gh-repo("https://github.com/github-af/SmartPGP") 来实现 YubiKey 5C NFC 的 OpenPGP 相关功能.

从 #link("https://github.com/github-af/SmartPGP/releases/latest")[Release] 下载适合自己卡片的 cap 包, 这里需要选择的是 Java Card 的版本和 RSA 位数. 我们在安装 JCAlgTest 时已经探测过 Java Card 版本, 而卡片支持的 RSA 位数可以在 JCAlgTest 测试报告的 `TYPE_RSA_PUBLIC LENGTH_RSA_2048`, `TYPE_RSA_PUBLIC LENGTH_RSA_3072`, `TYPE_RSA_PUBLIC LENGTH_RSA_4096`, 等行找到.

这里我选择的是 `javacard-3.0.4-rsa_up_to_2048` 的构建.

```shell-unix-generic
$ gpp --install SmartPGPApplet-v1.23.2.0-javacard-3.0.4-rsa_up_to_2048.cap -r "$READER"
SmartPGPApplet-v1.23.2.0-javacard-3.0.4-rsa_up_to_2048.cap loaded: fr.anssi.smartpgp D27600012401
```

== 配置 SmartPGP

这部分包括生成一个全新的 PGP 身份, 如果你已经有了, 那可以按需跳过生成部分.

我们需要生成一个主钥和三个子钥, 三个子钥分别用于签名, 加密和认证. 子钥之后会被传输到卡片上, 主钥则生成一个纸质备份.

我们在一个隔离的环境中完成工作.

```shell-unix-generic
export GNUPGHOME=~/gnupg-master
mkdir -p $GNUPGHOME && chmod 700 $GNUPGHOME
```

=== 生成主钥
```shell-unix-generic
gpg --expert --full-generate-key
```

- 选择 key 类型 `(11) ECC (set your own capabilities)`
- 关闭 `Sign` 能力
- 选择椭圆曲线类型 `(1) Curve 25519`, 因为主钥不会进入卡片, 因此这里不需要考虑卡片的能力
- 按需填写有效期
- 填写名字, 邮箱, 注释, 口令等

生成成功时将得到

```shell-unix-generic
...
pub   ed25519 2026-11-14 [C]
      ****************************************
uid                      name <mail@domain>
```

这里 `****************************************` 是主钥 FPR.

```shell-unix-generic
export FPR=****************************************
```

=== 生成子钥

```shell-unix-generic
$ gpg --expert --edit-key $FPR

gpg> addkey
```

然后
- 选择 key 类型 `(10) ECC (sign only)`
- 选择曲线类型 `NIST P-256`
- 按需填写有效期
- 填写口令

完成后继续 `addkey` 两次, 不同点在于
- 第二次 `addkey` 需要选择 key 类型 `(12) ECC (encrypt only)`
- 第三次 `addkey` 需要选择 key 类型 `(11) ECC (set your own capabilities)`, 然后只保留 `Authenticate` 能力

最后

```shell-unix-generic
gpg> save
```

现在使用
```shell-unix-generic
gpg --list-keys --with-fingerprint
```

应该能看到一个能力为 `C` 的主钥和三个能力分别为 `S`, `E`, `A` 的子钥.

=== 备份主钥私钥

我编写了一个 #link("https://github.com/ParaN3xus/java-card-utils/blob/main/pgp-backup.typ")[Typst 模板] 用于生成纸质备份文档 PDF. 只需要在安装 #gh-repo("http://github.com/typst/") 后执行

```shell-unix-generic
typst c pgp-backup.typ --input KEY="$(gpg --armor --export-secret-keys $FPR)" --input FPR=$FPR
```

然后打印生成的 `pgp-backup.pdf` 并将 PDF 文件销毁即可.

在 Arch Linux 上, typst 可以通过

```shell-unix-generic
sudo pacman -Syu typst
```

=== 设置 PIN

如果你此时通过转发 Android 手机的 NFC 来连接卡片, 那么你需要手动关闭 CCID, 让 GPG 使用 pcscd.

```shell-unix-generic
sudo mkdir -p /etc/gnupg && echo "disable-ccid" | sudo tee /etc/gnupg/scdaemon.conf
gpgconf --kill scdaemon
```

查看卡片信息.

```shell-unix-generic
$ gpg --card-status
Reader ...........: Virtual PCD 00 01
Application ID ...: D276000124010304AFAF000000000000
Application type .: OpenPGP
Version ..........: 3.4
Manufacturer .....: unknown
Serial number ....: 00000000
Name of cardholder: [not set]
Language prefs ...: en
Salutation .......:
URL of public key : [not set]
Login data .......: [not set]
Signature PIN ....: forced
Key attributes ...: rsa2048 rsa2048 rsa2048
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 0 3
Signature counter : 0
KDF setting ......: off
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]
```

SmartPGP 的 PIN 和 FIDO2Applet 的 PIN 是两套 PIN.

```shell-unix-generic
gpg --card-edit

gpg/card> admin
gpg/card> passwd
```

然后分别设置用户 PIN (1) 和管理 PIN (3), 其中用户 PIN 要求至少 6 位, 管理员 PIN 要求至少 8 位. 默认的用户 PIN 和管理 PIN 分别是 `123456` 和 `12345678`.

最后退出.

```shell-unix-generic
gpg/card> quit
```


=== 将子钥导入卡片


导入子钥.

```shell-unix-generic
$ gpg --edit-key $FPR

gpg> key 1
gpg> keytocard
gpg> key 1
gpg> key 2
gpg> keytocard
gpg> key 2
gpg> key 3
gpg> keytocard
gpg> save
```

注意每次 `keytocard` 要选择对应的槽位, 也即三次分别选择 `Signature key`, `Encryption Key` 和 `Authentication key`.


=== 发布公钥

导出公钥.

```shell-unix-generic
gpg --export --armor $FPR > /tmp/pub.asc
```

现在可以删除磁盘上的私钥了.

```shell-unix-generic
rm -rf $GNUPGHOME
unset GNUPGHOME
```

导入公钥.

```shell-unix-generic
gpg --import /tmp/pub.asc
```

使用一次卡片以生成私钥存根.

```shell-unix-generic
gpg --card-status
```

现在可以在 #link("https://keys.openpgp.org/upload")[OpenPGP Keyserver] 上传你的公钥.

== 更换 GP 密钥

```shell-unix-generic
export NEW_ENC=$(head -c 16 /dev/urandom | xxd -p -c 32)
export NEW_MAC=$(head -c 16 /dev/urandom | xxd -p -c 32)
export NEW_DEK=$(head -c 16 /dev/urandom | xxd -p -c 32)
gpp -r "$READER" --lock-enc $NEW_ENC --lock-mac $NEW_MAC --lock-dek $NEW_DEK
export GP_KEY_ENC=$NEW_ENC GP_KEY_MAC=$NEW_MAC GP_KEY_DEK=$NEW_DEK
unset NEW_ENC NEW_MAC NEW_DEK
```

我编写了一个 #link("https://github.com/ParaN3xus/java-card-utils/blob/main/gp-key-backup.typ")[Typst 模板] 用于生成纸质备份文档 PDF.

```shell-unix-generic
typst c gp-key-backup.typ --input ENC=$GP_KEY_ENC --input MAC=$GP_KEY_MAC --input DEK=$GP_KEY_DEK
```


= 总结

使用较低的价格完成了对 YubiKey 5C NFC 中重要功能的平替.
