#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "DIY Smol Slime 追踪器",
  desc: [
    我 DIY Smol Slime 经历的记录.
  ],
  date: "2025-11-08",
  tags: (
    blog-tags.vrchat,
    blog-tags.diy,
  ),
  license: licenses.cc-by-nc-sa,
)

*本教程尚未完成, 但本人的 Tracker 已经 DIY 完成. 本教程的成本部分是准确的.*

一直很羡慕能在游戏里随便摆 Pose 的好友们, 但是我没钱, 买不起成品 tracker, 又不会焊接, 所以没法 DIY 史莱姆.

今年早些看了一个 #link("https://www.bilibili.com/video/BV19BaYz7EPV")[Bilibili 视频]介绍的#link("https://docs.slimevr.dev/smol-slimes/")[小史莱姆(Smol Slime)], 狠狠心动了. 正好这学期学校有一整周的实训课程教我们怎么焊接电路板(是的, 本项目开始一周前我还对焊接一无所知. 当然, 我现在也只是焊接新手), 那就趁这个机会试试吧.

= 成果

- 数量: 十点
- 电池: 120 mAh, 提供约 24h 续航
- 尺寸: 3.8 #sym.times 3.7 #sym.times 1.0
-

: tbd

= 成本

#let costs = (
  工具: (
    ([电烙铁], 1, 115, [趁手即可]),
    ([恒温加热台], 1, 73.01, [趁手即可]),
    ([水口钳], 1, 13.5, [剪去多余的排针用, 趁手即可]),
    ([镊子套装], 1, 18, [主要是 SMT 贴片时夹取和放置元件用, 趁手即可]),
    ([定制 SMT 激光钢网 10cm\*10cm], 1, 15, []),
    ([万用表], 1, 82.78, [最低要求是能测电阻]),
    ([迷你锡膏印刷台], 1, 25.8, [闲鱼]),
    ([针线], 1, 0, [家中常备]),
    ([打火机], 1, 0, [家中常备]),
  ),
  材料: (
    ([锡浆], 1, 25.5, []),
    ([焊锡丝], 0, 0, [买电烙铁送的]),
    ([两米长三厘米宽松紧带], 3, 13.12, [剩了不少]),
    ([1007电子线5卷共100米], 1, 36.45, [明显买多了]),
    ([子母扣], 9, 2.97, []),
    ([标签纸], 1, 5, [买多了]),
  ),
  电子元件: (
    ([KEY SMD小乌龟轻触开关], 10, 0.48, []),
    ([401230 锂电池 3.7V 120mAh], 10, 7.23, []),
    ([贴片电容\ CL10B104KC8NNNC 100nF], 50, 0.0372, []),
    ([贴片电容\ CL10A225KO8NNNC 2.2uF], 50, 0.0381, []),
    ([贴片电阻\ 0603WAF1002T5E 2.2uF], 100, 0.0059, []),
    ([有源晶振\ YF4032K76833T8188081], 10, 2.37, []),
    ([姿态传感器 ICM-45686], 10, 19.83, []),
    ([3D磁传感器 QMC6309], 10, 2.2065, [可选, 现阶段小史莱姆固件还不支持磁传感器]),
  ),
  模块: (
    ([Holyiot-21017-nRF52840 接收器], 1, 99, []),
    ([Promicro NRF52840 开发板], 10, 11.89, []),
    ([ICM-45686 模块 PCB], 10, 0, [嘉立创免费打样]),
    ([十口 USB 分线器], 1, 26, []),
    ([USB-C 公口对 USB-A 公口转换器], 10, 5.95, []),
    ([GoPro 用双肩胸带], 1, 15.3, [挂接胸部tracker用]),
    ([3D 打印外壳], 10, 1.84 + 2.41, []),
    ([3D 打印托盘], 9, 2.17, []),
    ([3D 打印 GoPro 胸带挂载托盘], 1, 6.03, []),
  ),
)

#table(
  align: center + horizon,
  columns: 5,
  [类别], [物品], [数量], [价格], [备注],
  ..costs
    .pairs()
    .map(x => {
      let (class, items) = x
      (
        table.cell(rowspan: items.len() + 1, class),
        ..items.map(x => x.map(x => if type(x) != content { str(x) } else { x })),
        [*合计*],
        [],
        strong(str(
          calc.round(
            items
              .map(x => {
                let (_, c, p, _) = x
                c * p
              })
              .sum(),
            digits: 2,
          ),
        )),
        [],
      )
    })
    .flatten(),
  [*合计*],
  [],
  [],
  strong(str(
    calc.round(
      costs
        .values()
        .map(x => x.map(x => {
          let (_, c, p, _) = x
          c * p
        }))
        .flatten()
        .sum(),
      digits: 2,
    ),
  )),
)

前面提到的视频中的商品 Styria Mini tracker 十点的价格是 1888. 虽然没有触点充电, 一键唤醒等功能, 但价格便宜约 700 元(甚至还留下了价值 300 多元未来还可以继续用的工具)让我感到满意.

如果你决定要跟随本教程制作 tracker, 建议先通读一遍本教程, 明确自己需要准备什么工具或材料, 然后再进行准备和实操.

= 过程

我的 Smol Slime tracker 整体上参考官方文档的 DIY 方案, 但是替换了官方方案中使用的#link("https://shop.slimevr.dev/products/slimevr-mumo-breakout-module-v1-icm-45686-qmc6309")[成品 ICM-45686 模块], 因此步骤上要再多一条制作该模块.

整体过程如下
+ 焊接 ICM-45686 模块
+ 焊接 tracker
+ 刷写固件, 配对 tracker 和接收器
+ 组装 tracker 与外壳, 绑带
+ 调试, 测试

== 焊接 ICM-45686 模块

这个步骤是精细操作要求最高的部分. 不使用成品模块能省下约 100 人民币, 但是会额外消耗你约 5 小时时间(我在熟练后需要约30分钟来焊接一个该模块). 所以如果你不缺这 100 人民币, 你可以跳过, 并直接购买成品模块.

操作步骤如下
+ #box(width: 100%)[将钢网和 PCB 板安装在夹具上]
  #figure(
    image(
      "assets/diy-smol-slime-tracker/install_stencil_and_pcb_to_fixture.jpg",
      width: 50%,
    ),
    caption: [钢网和 PCB 板安装在夹具上],
  )
+ 盖上钢网, 对齐钢网和 PCB
  #figure(
    image(
      "assets/diy-smol-slime-tracker/align_stencil_and_pcb.jpg",
      width: 50%,
    ),
    caption: [对齐钢网和 PCB],
  )
+ 刷上锡浆. 在覆盖焊点的基础上, 用最少的次数刷上恰好足够的锡浆. 尤其是对于 ICM-45686 和 QMC6309 两个芯片的焊盘, 能刷一次绝不刷两次, 以防止锡浆过多导致焊接后连锡. 刷的时候要用力按平钢网, 防止锡浆渗出到钢网另一侧与 PCB 之间的空隙, 导致连锡.
  #figure(
    image(
      "assets/diy-smol-slime-tracker/apply_solder_paste.jpg",
      width: 50%,
    ),
    caption: [刷上锡浆],
  )
+ 揭开钢板. 揭开前保证没有大片锡膏在焊点上, 否则揭开后会出现拉尖. 揭开时, 注意从下往上慢慢揭开, 防止锡浆偏移.
  #figure(
    image(
      "assets/diy-smol-slime-tracker/solder_paste_applied.jpg",
      width: 50%,
    ),
    caption: [刷好锡浆的 PCB],
  )
  注意检查各个焊盘上是否有锡浆, 是否有连锡. 电阻电容和晶振焊盘较大, 轻微连锡无关紧要, 但是 ICM-45686 焊点比较密集, 需要重点关注. QMC6309 焊点较小, 经常出现钢网被堵塞, 锡浆刷不上的情况, 不过因为 QMC6309 是可选安装的芯片, 所以如果你不想在这上面花时间, 可以直接不予理睬.
+ 摆放元器件. 用镊子把元器件摆到 PCB 上. 其中
  - 左上方两个是 100nF 电容的焊盘, 没有正反
  - 下方中间一个是 2.2uF 电容的焊盘, 没有正反
  - 其余小长方形是 10k 电阻的焊盘, 字面朝上即可
  - 中间上方面积最大的是晶振的焊盘, 反光下可见芯片上有一个 "#sym.dot", 注意这个 "#sym.dot" 和焊盘右上角处的 "#sym.not" 在同一方向
  - 中间焊点最多的是 ICM-45686 芯片的焊盘, 反光下可见芯片上有一个 "#sym.dot", 注意这个 "#sym.dot" 和焊盘左下角处的 "#sym.not" 在同一方向
  - (可选安装, 不影响功能)右侧最小的正方形是 QMC6309 芯片的焊盘, 反光下可见芯片上有一个 "#sym.dot", 注意这个 "#sym.dot" 和焊盘右上角处的 "#sym.not" 在同一方向.
  #figure(
    image(
      "assets/diy-smol-slime-tracker/pcb_components_placed.jpg",
      width: 50%,
    ),
    caption: [放好元件的 PCB],
  )
+ 加热台打开, 温度设置为 160, 到达后将 PCB 板放上, 预热约 30 秒.
  #figure(
    image(
      "assets/diy-smol-slime-tracker/pcb_preheating.jpg",
      width: 50%,
    ),
    caption: [预热 PCB],
  )
  背景图是我室友的行李箱. 请不要担心, 因为加热台只有上面的表面是热的. 本教程中没有任何室友或室友的行李箱受到损害.
+ 预热完成后, 调节温度到比锡浆熔点略高. 对于我来说, 这个温度是 210. 然后等待升温后锡浆融化.
  #figure(
    image(
      "assets/diy-smol-slime-tracker/solder_paste_melted.jpg",
      width: 50%,
    ),
    caption: [锡浆融化了],
  )
+ 当所有焊点的锡浆已经充分融化(往往是你设置的温度已经到达时), 用镊子直接把 PCB 从加热台上移除, 然后放到一个合适的地方散热(比如钢网上). 关闭加热台(这个加热台没有主动制冷功能). 注意此后的相当长时间内, 加热台仍然是烫的, 请注意安全.
+ 使用万用表检测各焊点是否有连锡或虚焊. 由于写教程时, 我的每个模块都已经被做成了 tracker, 所以无法提供各个测量点的具体参考值, 只能给出检测步骤和大致结果.
  - ICM-45686 连锡检测
    - OSDO 和 SC0: 应为开路
    - CLK 和 SC0: 不应短路
    - CLK 和 +3V3: 不应短路
    - GND 和 +3V3: 不应短路
    - INT1 和 SCX: 不应短路
    - SDX 和 SCX: 不应短路
    - SDX 和 SD0: 不应短路
    - SDA 和 SCL: 不应短路
    - CS 和 SCL: 不应短路
  - ICM-45686 虚焊检测
    - 测不了, 只能祈祷正确
  - 其它
    - 如果不放心, 可自行参考 PCB 设计图进行检测
+ 大功告成

== 焊接 tracker

这一部分和官方教程基本一致, 但是如果你选择自制 ICM-45686 模块, 那么得益于该模块的尺寸设计, 这一步会相对简单.

+ #box(width: 100%)[给模块背面贴上胶带, 防止其与开发板密切接触导致的短路]
  #figure(
    image(
      "assets/diy-smol-slime-tracker/taped_module.jpg",
      width: 50%,
    ),
    caption: [贴好胶带的模块],
  )
+ 掰一段六个的排针, 用钳子处理一下, 把外壳移动到一端
  #figure(
    image(
      "assets/diy-smol-slime-tracker/processed_pin_headers.jpg",
      width: 50%,
    ),
    caption: [处理好的排针],
  )
  再取两个排针, 直接移除外壳, 取出金属排针部分
+ 把开发板, 模块, 排针摆放到图示位置(开发板四角的四组三个排针是起支撑固定作用的, 并不需要焊接)
  #figure(
    image(
      "assets/diy-smol-slime-tracker/pin_headers_placed.jpg",
      width: 50%,
    ),
    caption: [等待焊接正面的 tracker],
  )
+ 焊接正面
  #figure(
    image(
      "assets/diy-smol-slime-tracker/front_soldered.jpg",
      width: 50%,
    ),
    caption: [正面焊接后的 tracker],
  )
+ 移除六个排针的外壳, 准备焊接反面
  #figure(
    image(
      "assets/diy-smol-slime-tracker/6x_pin_header_housing_removed.jpg",
      width: 50%,
    ),
    caption: [等待焊接反面的 tracker],
  )
+ 焊接反面
  #figure(
    image(
      "assets/diy-smol-slime-tracker/back_soldered.jpg",
      width: 50%,
    ),
    caption: [反面焊接后的 tracker],
  )
+ 用钳子剪去多余的排针
+ 焊接电池. 在进行这一步时, 你的 tracker 上就会有指示灯亮起了, 这是正常的, 请不要担心
  #figure(
    image(
      "assets/diy-smol-slime-tracker/battery_soldered.jpg",
      width: 50%,
    ),
    caption: [焊接电池后的 tracker],
  )
+ 焊接天线.
  + 剪取一段和 tracker 长度相当的导线, 剥去一端的一小段线皮(5毫米已经足够), 把铜线捻在一起(如果你的导线是多股的), 并使用烙铁镀锡.
  + 在 tracker 的图示位置预先上锡
    #figure(
      image(
        "assets/diy-smol-slime-tracker/preparing_solder_antenna.jpg",
        width: 50%,
      ),
      caption: [等待焊接天线的 tracker],
    )
  + 在图示位置焊接天线
    #figure(
      image(
        "assets/diy-smol-slime-tracker/antenna_soldered.jpg",
        width: 50%,
      ),
      caption: [天线焊接后的 tracker],
    )
+ 焊接按钮
  + #box(width: 100%)[在 tracker 的图示位置预先上锡]
    #figure(
      image(
        "assets/diy-smol-slime-tracker/preparing_solder_button.jpg",
        width: 50%,
      ),
      caption: [等待焊接按钮的 tracker],
    )
  + 在图示位置焊接按钮
    #figure(
      image(
        "assets/diy-smol-slime-tracker/button_soldered.jpg",
        width: 50%,
      ),
      caption: [按钮焊接后的 tracker],
    )
+ 大功告成

== 刷写固件, 配对 tracker 和接收器

在这一步, 你通常就能知道你的 tracker 是否正常工作了.

+ 刷入接收器固件
  + 下载#link("https://github.com/Shine-Bright-Meow/SlimeNRF-Firmware-CI/releases/download/latest/SlimeNRF_Holyiot_Dongle_Receiver.hex")[接收器固件]
  + 安装 #link("https://www.nordicsemi.com/Products/Development-tools/nRF-Connect-for-Desktop/Download")[nRF Connect for Desktop], 在里面安装 "Programmer" 并打开
  + 将 Holyiot-21017-nRF52840 接收器连接到电脑. 该接收器还附赠一块磁铁, 把这块此贴在指示灯附近以进入 DFU 模式
  + 在 Programmer 中选择接收器设备, 刷入接收器固件
+ 刷入 tracker 固件
  + 下载 #link("https://github.com/Shine-Bright-Meow/SlimeNRF-Firmware-CI/releases/download/latest/SlimeNRF_Tracker_NoSleep_SPI_StackedSmol.uf2")[tracker 固件]. 这里的链接是官方推荐的 ProMicro 设备 SPI 协议有时钟无 WOM 有按钮版本, 如果需要其他版本, 请参阅#link("https://docs.slimevr.dev/smol-slimes/firmware/smol-pre-compiled-firmware.html#-stacked")[官方文档]
  + 将 tracker (通过 USB 线)连接到电脑, 应当看到一个名称为 "NICENANO" 的存储设备.
  + 直接将固件复制到该设备, 稍等片刻后该设备消失, 刷写完成
    #figure(
      image(
        "assets/diy-smol-slime-tracker/flash_firmware.png",
        width: 100%,
      ),
      caption: [刷入 tracker 固件],
    )
+ 配对 tracker 和接收器
  + 下载 #link("https://github.com/ICantMakeThings/SmolSlimeConfigurator/releases/tag/Release-V7")[SmolSlimeConfigurator], 并打开两个实例
  + 将接收器连接到电脑, 刷新一个 SmolSlimeConfigurator 实例的 COM 接口列表, 应该能看到接收器对应的 COM 接口. 选中该接口, 点击连接, 能看到类似如下输出
    ```sh
    Connected to COM5
    *** Booting SlimeVR-Tracker-nRF-Receiver v0.6.9-c0c2784b78b0 ***
    *** Using nRF Connect SDK v3.1.1-cb47ad580360 ***
    *** Using Zephyr OS v4.1.99-ff8f0c579eeb ***
    [00:00:00.000,305] <inf> hid_event: HID Device: dev 0x1854c
    [00:00:00.006,988] <inf> esb_event: 10/256 devices stored
    [00:00:00.007,019] <inf> esb_event: Initializing ESB, RX mode
    [00:00:00.109,283] <inf> hid_event: New protocol: report
    *** Holyiot SlimeNRF Receiver Holyiot-21017 ***
    SlimeVR-Tracker-nRF-Receiver 0.6.9+0 (Commit c0c2784b78b0, Build 2025-11-05 02:23:01)
    info                         Get device information
    uptime                       Get device uptime
    list                         Get paired devices
    reboot                       Soft reset the device
    add <address>                Manually add a device
    remove                       Remove last device
    pair                         Enter pairing mode
    exit                         Exit pairing mode
    clear                        Clear stored devices
    d
    ```
    由于我已经配对过, 所以这里会显示 `esb_event: 10/256 devices stored`.
  + 这个 SmolSlimeConfigurator 实例切换到 Receiver 选项卡. 在此选项卡下, 点击 "Pairing Mode" 即可进入配对模式, 点击 "🛇 Pairing Mode" 即可退出配对模式.
  + 配对一个 tracker
    + 连接一个 tracker 到电脑, 刷新另一个 SmolSlimeConfigurator 实例的 COM 接口列表, 应该能看到 tracker 对应的 COM 接口. 选中该接口, 点击连接, 能看到类似如下输出
      ```sh
      Connected to COM23
      [19:58:33.350,463] <inf> status: USB connected
      [19:58:33.350,494] <inf> status: Status: 8
      [19:58:33.406,372] <inf> status: Charger plugged
      [19:58:33.406,372] <inf> status: Status: 24
      [19:58:33.406,402] <inf> power: Change to battery SOC: 26.55% -> 100.00%
      [19:58:33.406,433] <inf> battery_tracker: Tracker reset
      *** SlimeVR SlimeNRF Tracker ProMicro ***
      SlimeVR-Tracker-nRF 0.6.9+0 (Commit 5d572a0056f3, Build 2025-11-05 02:26:37)
      info                         Get device information
      uptime                       Get device uptime
      reboot                       Soft reset the device
      battery                      Get battery information
      scan                         Restart sensor scan
      calibrate                    Calibrate sensor ZRO
      6-side                       Calibrate 6-side accelerometer
      set <address>                Manually set receiver
      pair                         Enter pairing mode
      clear                        Clear pairing data
      dfu
      ```
    + 点击 Info 按钮, 查看该 tracker 的地址
      ```sh
      >>> info
      info
      SlimeVR SlimeNRF Tracker ProMicro
      SlimeVR-Tracker-nRF 0.6.9+0 (Commit 5d572a0056f3, Build 2025-11-05 02:26:37)
      Board: promicro_uf2
      SOC: nrf52840
      Target: promicro_uf2/nrf52840/spi
      IMU: ICM-45686
      Interface: SPI
      Address: 0x00F2
      Accelerometer matrix:
      0.00000 1.00000 0.00000 0.00000
      0.00000 0.00000 1.00000 0.00000
      0.00000 0.00000 0.00000 1.00000
      Gyroscope bias: 0.00000 0.00000 0.00000
      Fusion: VQF
      Tracker ID: 1
      Device address: A3ABE2433796
      Receiver address: EAAF99CF4E82
      Battery: 27%
      Remaining runtime: 7h 20min
      Fully charged runtime: 27h 31min
      ```
      此处我已经配对过, 所以 `Receiver address` 有显示. 这里重点关注 `Device address`.
    + 使用接收器对应的 SmolSlimeConfigurator 实例使接收器进入配对模式, 然后长按 tracker 的按钮至少三秒, 在 tracker 对应的 SmolSlimeConfigurator 实例中应该看到类似如下的输出
      ```sh
      [20:02:28.176,422] <inf> status: Button pressed
      [20:02:28.176,452] <inf> status: Status: 90
      [20:02:29.144,592] <inf> system: User shutdown requested
      [20:02:32.333,129] <inf> status: Cleared status: 2
      [20:02:32.333,160] <inf> status: Status: 88
      [20:02:33.145,111] <inf> system: Pairing requested
      [20:02:33.155,303] <inf> esb_event: Pairing requested
      [20:02:33.155,334] <inf> status: Cleared status: 64
      [20:02:33.155,334] <inf> status: Status: 24
      [20:02:33.234,619] <inf> esb_event: Pairing
      [20:02:33.234,710] <inf> esb_event: Device address: A3ABE2433796
      [20:02:33.234,710] <inf> esb_event: Checksum: 72
      [20:02:34.235,565] <inf> esb_event: Paired
      ```
      这里看到 `Paired` 即可松手.
    + 在接收器对应的 SmolSlimeConfigurator 实例点击 "List", 应该能看到类似如下输出
      ```sh
      >>> list
      list
      Stored devices:
      90855A7370F9
      A3ABE2433796
      25B9BCBE4551
      E6A5C759DA8A
      0E6389D6236D
      0B4BF4FE7330
      50C39218E879
      D1F1D0DCFB8C
      A56ECB442ECD
      4E1DFDF79F16
      ```
      如果能在这里找到先前看到的 tracker 地址, 则配对完成. 由于我已经把十个 tracker 都配对完成, 所以这里全都显示了
    + 断开 tracker 与电脑的连接
  + 重复上述步骤, 配对所有 tracker
+ 检查 tracker 是否正常工作
  + 安装 #link("https://slimevr.dev/")[SlimeVR Server]
  + 打开 SlimeVR Server, 按步骤完成设置, 有些与佩戴相关的步骤可以直接跳过
  + 在 SlimeVR Server 的 Home 界面能看到所有 tracker. 当 tracker 剧烈移动的时候, 这个 tracker 对应的图标会亮起. 点进每个 tracker 可以看到该 tracker 的 3D 预览画面, 在现实中移动 tracker, 检查预览画面的移动是否匹配.

== 组装 tracker 与外壳, 绑带

我的外壳参考的是 #link("https://github.com/brisfknibis")[Bris Ibis] 设计的 #link("https://github.com/brisfknibis/ibis-trackers/tree/main/3D%20Print%20Models/Tracker%20V1")[Ibis Trackers V1], 在#link("https://space.bilibili.com/670121708")[凌橙]的帮助下进行了修改.

=== 组装 tracker 和外壳
+ 下载外壳的 #link("https://github.com/ParaN3xus/paran3xus_smol_slime/tree/main/mechanical")[3D 模型文件]并打印, 这里我们需要打印 10 个 `Body.stl`, 10 个 `Lid.stl`, 9 个 `Tray.stl`, 1 个 `GoPro Chest Mount.stl`.
+ 按图示方式组装追踪器和外壳. 建议先安装 PCB 部分再安装电池部分. 安装时注意方向(可以通过外壳上为 USB-C 接口预留的空缺确定).
  #figure(
    image(
      "assets/diy-smol-slime-tracker/shell_installed.jpg",
      width: 50%,
    ),
    caption: [tracker 在外壳中],
  )
+ 安装外壳的盖子
  #figure(
    image(
      "assets/diy-smol-slime-tracker/shell_enclosed.jpg",
      width: 50%,
    ),
    caption: [tracker(已封顶)],
  )
+ 将 tracker 安装到挂载托盘上
  #figure(
    table(
      stroke: none,
      columns: 2,
      column-gutter: 2em,
      image(
        "assets/diy-smol-slime-tracker/shell_mounted_to_gopro_mounter.jpg",
        height: 20em,
      ),
      image(
        "assets/diy-smol-slime-tracker/shell_mounted.jpg",
        height: 20em,
      ),
    ),
    caption: [已挂载的 tracker],
  )
+ 为 tracker 贴上标签
  #figure(
    image(
      "assets/diy-smol-slime-tracker/tracker_labeled.jpg",
      width: 50%,
    ),
    caption: [贴好标签的 tracker],
  )
=== 制作和组装绑带

我使用的绑带设计是 Depact 设计的 #link("https://docs.slimevr.dev/smol-slimes/hardware/smol-slimes-community-straps.html#depact-v2-smol-strap")[Depact V2 Smol 绑带]. 由于本人完全不懂缝纫, 且撰写该教程时本人已忘记一些缝纫操作的细节, 所以本节教程可能不够详细.

+ 学习基础缝纫步骤. 此处有一个#link("https://docs.slimevr.dev/smol-slimes/hardware/smol-slimes-community-straps.html")[官方文档相关章节]给出的#link("https://www.wikihow.com/Sew")[基础缝纫教程], 能让你学会将两块布缝纫在一起. 这是完成本节所有步骤所需要掌握的唯一缝纫步骤.
+ *对于接下来的步骤, 建议先对一个 tracker 完整完成, 再进行批量制作, 以获取经验和调整后续操作细节*.
+ 制作固定环
  + 剪下一段长度略短于三倍松紧带宽度的松紧带, 并用打火机快速烤一下两端防止今后开线. 在不影响环绕绑带的基础上, 环越短, 固定时越紧, 绑带的固定效果越好. 一个可供参考的长度是短 1cm, 也即使用 8cm 长的松紧带制作环.
  + 令带有防滑条纹的一面朝内, 将松紧带卷起至重叠三次, 此时松紧带卷的长度应与松紧带本身的宽度相当(或略短).
  + 缝合松紧带卷外面裸露的头部和最外层下的一层(也即次外层), 制作成固定环. 由于涉及固定和尺寸问题, 这一步可能略难. 可以多次尝试.
+ 对于身体每个要使用绑带安装的部位(足部, 脚踝, 大腿, 腰部, 大臂), 使用你所购买的松紧带量出环绕该部位一周需要的长度, 剪下比该长度长 10cm 的松紧带作为绑带, 并用打火机快速烤一下两端防止今后开线. 此处的 10cm 是作者本人认为合适的经验长度, 可根据你的个人需要进行调整. 如果不放心, 可以继续加长, 毕竟后续可以进行修剪.
+ 按图示方式组装追踪器, 绑带, 子母扣和固定环. 图中蓝色标注了绑带带有防滑条纹的一面. 注意图中只有右侧的绑带和子母扣连接处需要缝纫固定, 左侧是完全依靠固定环的弹力和防滑条纹的摩擦固定的. 注意在左侧穿入子母扣之前就应该套上固定环.
  #figure(
    image(
      "assets/diy-smol-slime-tracker/tracker_on_strap.jpg",
      width: 50%,
    ),
    caption: [tracker 在绑带上],
  )
+ 在追踪器的标签上写上对应身体部位的名字. 建议留一些位置用于记录其他信息, 如 tracker 的硬件地址.

== 调试, 测试
tbd

= 总结
tbd
