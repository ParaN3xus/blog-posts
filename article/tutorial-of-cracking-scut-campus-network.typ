#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "基于特定端口或协议版本的校园网免流教程",
  desc: [
    如何在校园网中通过 IPv6, 53 端口等常见授权漏洞实现免流上网
  ],
  date: "2024-03-05",
  tags: (
    blog-tags.network,
    blog-tags.free-ride,
  ),
  license: licenses.cc-by-nc-sa,
)

本教程仅供研究学习使用, 请在部署后 24h 内撤销所有更改并恢复原状, 本教程作者对依据本教程行动带来的后果概不负责.

本文的首要假设是你的校园网有某种授权漏洞, 例如 IPv6 或者 53 端口(DNS 所用)不需要鉴权或者不限速等. 若果你的校园网环境没有这些漏洞, 那么请不要尝试本教程.

= 成本

虽然打了个 free-ride 的 tag, 但是实际操作并不是免费的, 你仍然需要为一些设备和服务付出代价, 包括:

- 代理服务器: 价格取决于你选择的服务商和具体线路, 配置等. 若可能, 在校内某些地点(如实验室)直接放一台服务器也是可以的.
- 路由器: 至少要允许设置网关.
- 网关: 本地的一台服务器, 如果性能足够, 也可以直接使用支持 OpenWRT 等的路由器.
- 可能被发现的风险(同时违反校规和国家法律)

= 最终效果

- 上下行速度达到本方案任意一环中的瓶颈, 对于本人, 这个瓶颈是墙上面板只有百兆.
- 无需付费(指校园网费用).
- 夜间不断网(取决于具体情况).
- 可访问代理服务器可访问的所有网络服务. (如果代理服务器不在校内, 那你可能无法访问校内服务)
- 无限台无线设备连接, 上网无需经过认证或其他任何配置.

= 原理解释

某些校园网的鉴权系统非常老旧, 存在诸多漏洞, 比如
- IPv6 不需要鉴权
- 由于需要在无权限时劫持 DNS 请求, 53 端口不需要鉴权

只需要通过这些特殊的端口或协议版本访问某个代理服务器, 然后通过该代理服务器访问互联网, 便可以实现免流上网.

下面的教程以 IPv6 无鉴权的情况为例.

= 准备工作

== 购买路由器

不给出建议.

== 购买本地网关服务器

理论上来说, 该网关需要满足以下要求:

1. 有线网口速度不成为瓶颈.
2. 能运行 linux, 此方案是完全基于 linux 的.
3. 配置足够高, 能正常运行 xray. 一般来说不会不符合.

如果你想白嫖 Cloudflare Zero Trust 作为代理, 那你的服务器需要是 AMD64 架构, 也即不能使用树莓拍等 ARM 架构的设备, 这是因为 Cloudflare 并不提供 ARM 架构的 WARP 客户端, 而使用第三方 WireGuard 客户端连接 Cloudflare Zero Trust 在如今的环境下几乎不可能成功.

完全可以使用老电脑, 或某些软路由.

== 购买代理服务器

服务器要满足以下要求:

- IPv6 和 IPv4 双栈公网. 否则要么不能达到解除限速的目标, 要么只能访问支持纯 IPv6 的网站, 而后者在国内几乎不可能满足日用.
  - 或许也可以选择只有 IPv4 的服务器, 然后用 Tunnel Broker 之类的服务获取 IPv6, 但是我觉得这对延迟不友好, 所以没有尝试.
  - 这条要求会缩小选择空间, 很多著名服务商都可能被排除在外.
- 网络配置和硬件配置够好, 价格够便宜. 我们的行为需要有利可图.

= 教程

步骤可以大体分为:

1. 配置路由器
2. 配置代理服务器
3. 配置网关

== 配置路由器
不提供相关指引. 只需要保证路由器能正确访问我们用于访问代理服务器的网络即可.

== 配置代理服务器

=== 自建代理
这一步骤已经被 x-ui 等图形化工具大大简化, 因此这里不再提供详细指引, 只提供一些建议:
- 如果使用了海外代理服务器, 请确保你使用了正确的加密协议
- 如果使用了国内代理服务器, 可以酌情使用 socks5 等更加轻量的协议


=== 白嫖 Cloudflare Zero Trust

==== 注册 Cloudflare 并加入 Zero Trust

可参考此教程的“注册 Cloudflare 帐号并进行设置”部分: #link("https://github.com/getsomecat/GetSomeCats/blob/Surge/%E6%B3%A8%E5%86%8CCloudflare%E5%B9%B6%E5%8A%A0%E5%85%A5ZeroTrust%E6%95%99%E7%A8%8B.md=%E6%B3%A8%E5%86%8Ccloudflare%E5%B8%90%E5%8F%B7%E5%B9%B6%E8%BF%9B%E8%A1%8C%E8%AE%BE%E7%BD%AE")[传送门]

==== 进行一些设置

在 Zero Trust 面板中, 进入 Settings, WARP Client, Device settings, Default, 点击最后的三个点, Configurate.

打开 Mode swtich, Auto connect, Service mode 选择 Proxy, 点击 Save Profile 保存.

==== 配置 WARP Client

===== 安装客户端

请参考官方教程: [传送门](https://pkg.cloudflareclient.com/)

===== 加入团队

```shell
warp-cli teams-enroll 你的团队域
```

然后终端中会出现一个地址, 本地访问这个地址, 并在其中按照指引登录.

```shell
warp-cli teams-enroll-token 你的token
```

其中 token 可在浏览器登陆后的页面里打开开发者工具查看, 直接复制 Open Cloudflare WARP 按钮指向的那个地址即可.

```shell
warp-cli status
```

应当输出

```text
Status update: Connected
Success
```

至此, WARP Client 配置完成.

== 配置网关
可参考教程: #link("https://xtls.github.io/document/level-2/tproxy_ipv4_and_ipv6.html")[传送门]

关于教程中的 Xray 配置部分, 你只需要进行客户端的配置, 本人的配置文件如下, 请将信息修改为你本人的信息后参考使用.

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "all-in",
      "port": 12345,
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "followRedirect": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "sockopt": {
          "tproxy": "tproxy"
        }
      }
    },
    {
      "port": 10808,
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "填写代理服务器IPv6地址",
            "port": 填写代理服务器入站节点端口,
            "users": [
              {
                "id": "按照节点配置页面填写",
                "alterId": 0,
                "email": "按照节点配置页面填写",
                "security": "auto",
                "encryption": "none",
                "flow": ""
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "sockopt": {
          "mark": 255
        },
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "serverName": "按照节点配置页面填写",
          "fingerprint": "chrome",
          "show": false,
          "publicKey": "按照节点配置页面填写",
          "shortId": "",
          "spiderX": ""
        }
      },
      "mux": {
        "enabled": false,
        "concurrency": -1
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIP"
      },
      "streamSettings": {
        "sockopt": {
          "mark": 255
        }
      }
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      }
    },
    {
      "tag": "dns-out",
      "protocol": "dns",
      "streamSettings": {
        "sockopt": {
          "mark": 255
        }
      }
    }
  ],
  "dns": {
    "hosts": {
      "domain:googleapis.cn": "googleapis.com",
      "dns.google": "8.8.8.8"
    },
    "servers": [
      "https://1.1.1.1/dns-query",
      {
        "address": "119.29.29.29",
        "domains": [
          "geosite:cn"
        ],
        "expectIPs": [
          "geoip:cn"
        ]
      },
      "https://dns.google/dns-query",
      "223.5.5.5",
      "localhost"
    ]
  },
  "routing": {
    "domainMatcher": "mph",
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "block"
      },
      {
        "type": "field",
        "inboundTag": [
          "all-in"
        ],
        "port": 123,
        "network": "udp",
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "inboundTag": [
          "all-in"
        ],
        "port": 53,
        "network": "udp",
        "outboundTag": "dns-out"
      },
      {
        "type": "field",
        "ip": [
          "119.29.29.29",
          "223.5.5.5"
        ],
        "outboundTag": "proxy"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "proxy"
      },
      // 我不好说
      {
        "type": "field",
        "ip": [
          "geoip:cn"
        ],
        "outboundTag": "proxy"
      },
      {
        "type": "field",
        "domain": [
          "geosite:cn"
        ],
        "outboundTag": "proxy"
      },
      // end of 我不好说,
      {
        "type": "field",
        "ip": [
          "geoip:private",
          "填写代理服务器IPv6地址",
          "填写代理服务器IPv4地址"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [
          "1.1.1.1",
          "8.8.8.8"
        ],
        "outboundTag": "proxy"
      },
      {
        "type": "field",
        "domain": [
          "geosite:geolocation-!cn",
          "domain:googleapis.cn",
          "dns.google"
        ],
        "outboundTag": "proxy"
      }
    ]
  }
}
```

该教程中有大量代表局域网网段或主路由、代理服务器的 IP 地址, 请在配置时注意进行替换.

注意在该教程中, 最后的局域网设备上网部分可以使用方案二, 直接在路由器配置页面中设置网关即可.

= 最终测试

国内测速站点: [传送门](https://test.ustc.edu.cn/)

国外测速站点: [传送门](https://www.speedtest.net/)

= 总结

祝每一位读者获得更好的校园网上网体验.
