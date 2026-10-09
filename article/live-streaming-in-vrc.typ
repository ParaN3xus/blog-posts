#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "在 VRChat 中直播",
  desc: [
    通过 MediaMTX 和 cloudflare tunnel 推流, 使得观众在 VRChat 的 AVPro 播放器上可以观看你的直播.
  ],
  date: "2026-10-10",
  tags: (
    blog-tags.vrchat,
    blog-tags.network,
    blog-tags.free-ride,
  ),
  license: licenses.cc-by-nc-sa,
)

= 需求

我的一个好友想在 VRChat 放电影, 但是
- 这个电影在 YouTube / Bilibili 上没有免费观看途径
- 他找不到这个电影的媒体文件资源, 因此不能简单地 host 一个文件

所以他必须通过直播的方式, 然而
- 因为电影是有版权的, 他不能直接在 YouTube / Bilibili 上直播, 因为直播间会被封禁
- 在尝试 #link("https://github.com/TopazChat/TopazChat")[TopazChat] 这个方案时, 他失败了. 可能原因是与服务器的连接不稳定, 或者特定世界不支持这种方式 (TopazChat 要求世界进行针对性适配才能播放直播)
  - 我个人也不喜欢这个方案

所以我尝试找出了一种新的方法来私域直播, 且
- 你只需要有一个域名
- 可以在任何有 AVPro (其它播放器未测试) 播放器的世界中观看直播, 不需要其它任何针对性适配
- 没有码率限制

= 概览

基本上, 你需要在本地开一个 MediaMTX 用于推流和分发, 然后通过 cloudflare tunnel 把服务反代出去. 这里的 trick 是通过一些参数调整使得 VRChat 的 AVPro 播放器能正常播放视频流.

= 教程

== 必要的准备

你需要购买一个域名, 并将其添加到 cloudflare 中. 具体操作步骤可以咨询 LLM.

== 安装软件

也即 MediaMTX 和 cloudflared, 这里给出 Windows 上的安装命令.

```powershell
winget install --id Cloudflare.cloudflared --accept-source-agreements --accept-package-agreements
winget install --id bluenviron.mediamtx --accept-source-agreements --accept-package-agreements
```

推流软件请自己准备, 可以使用 OBS.

== 配置 Cloudflare Tunnel

这里假设域名是 `example.com`

+ 登录 cloudflared

  ```powershell
  cloudflared tunnel login
  ```

  然后在弹出的网页中选择 `example.com`.

+ 设置 tunnel

  ```powershell
  cloudflared tunnel create live
  cloudflared tunnel route dns live live.example.com
  cloudflared tunnel list
  ```

  最后一条命令将会输出如下结果
  ```
  You can obtain more detailed information for each tunnel with `cloudflared tunnel info <name/uuid>`
  ID                                   NAME              CREATED              CONNECTIONS
  aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee live              ...                  ...
  ```
  记录这里的 ID `aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee`.

+ 创建配置文件 `cloudflared.yml`

  ```yaml
  tunnel: aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
  credentials-file: C:\Users\用户名\.cloudflared\aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.json
  ingress:
    - hostname: live.example.com
      service: http://127.0.0.1:8888
      originRequest:
        connectTimeout: 10s
    - service: http_status:404
  ```


== 配置 MediaMTX

创建配置文件 `mediamtx.yml`

```yaml
logLevel: info
rtsp: true
rtspTransports: [tcp]
rtspAddress: 127.0.0.1:8554
rtmp: true
rtmpAddress: 127.0.0.1:1935
hls: true
hlsAddress: 127.0.0.1:8888
hlsVariant: mpegts              # 否则 VRChat 不能播放
hlsSegmentDuration: 1s          # 关键帧间隔
hlsAlwaysRemux: true
hlsSegmentCount: 4              # 缓冲
hlsAllowOrigins: ["*"]
webrtc: false
srt: false
moq: false
api: true
apiAddress: 127.0.0.1:9997
paths:
  live:
    source: publisher
```

== 启动 MediaMTX 和 cloudflared

分别执行

```powershell
mediamtx mediamtx.yml
```
和

```powershell
cloudflared --config cloudflared.yml tunnel run
```

== 推流

这里以 OBS 为例, 配置
- 服务器: `rtmp://127.0.0.1:1935`
- 密钥: `live`
- 鉴权: 关

开启推流即可.

== 播放

- 本地测试: http://127.0.0.1:8888
- VRChat 外播放测试: https://live.example.com/live/index.m3u8
- VRChat 内播放: https://live.example.com/live/index.m3u8?cookieCheck=1

