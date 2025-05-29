#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "近乎完美的 GitLab + frp 搭建踩坑",
  desc: [使用 GitLab 和 frp 搭建私有服务器的经验分享],
  date: "2025-04-14",
  tags: (
    blog-tags.network,
    blog-tags.free-ride,
  ),
  license: licenses.cc-by-nc-sa,
)

很早之前就想自建一个 Git server, 终于在这个月早些动工了.

我的基本要求是
- 一个公网可以访问的, 全链路 HTTPS 保护的 GitLab 网站
- 可以正常使用 Git over SSH
- 有邮箱通知(尽管可能被标记为垃圾邮件)
- 服务器的 IP 不被泄露, 但是不支付额外费用购买如 Cloudflare 等平台的付费服务

为此, 我使用了
- 一台我有 root 权限的公网服务器, 用于运行 frp, wstunnel 等
- 一台我有 root 权限的内网服务器, 用于运行 GitLab 本体
- 一个二级域名
- 一个支持 SMTP 的邮箱(Gmail)

= 思路
基本结构如下:

#figure(
  image("assets/almost-perfect-gitlab-frp/structure.svg"),
  caption: [基本结构],
)


个人认为比较重要的部分就是通过 wstunnel 代理 Git over SSH 的流量, 于是可以走 Cloudflare 达到不泄露服务器 IP 的目的.

= 部署过程
在开始之前, 我们先假设一些值用作示例:
- 我们给 GitLab 服务预留的域名是 gitlab.example.com
- wstunnel 服务器的 path prefix 是 ssh-tunnel
- 公网服务器的 IP 是 1.2.3.4
- 公网服务器暴露了以下端口
  #table(
    columns: 2,
    [端口], [服务],
    [10001], [frp server],
    [80], [nginx http],
    [443], [nginx https],
  )
- 公网服务器上还预留了以下端口, 但是不需要暴露
  #table(
    columns: 2,
    [端口], [服务],
    [10002], [GitLab Web],
    [10003], [GitLab SSH],
    [10004], [wstunnel server],
  )
- 内网服务器上预留了以下端口
  #table(
    columns: 2,
    [端口], [服务],
    [801], [GitLab Web],
    [221], [GitLab SSH],
  )
== FRP Server 的安装和配置
在公网服务器上进行.

从 frp 的#link("https://github.com/fatedier/frp")[官方仓库]下载即可.

这里提供一个简单的配置.
```toml
bindPort = 10001
auth.token = "some-random-password"
```

启动 frps
```sh
frps -c config.toml
```

== wstunnel Server 的安装和配置
在公网服务器上进行.

从 wstunnel 的#link("https://github.com/erebe/wstunnel")[官方仓库]下载即可.

可以一行启动:
```sh
wstunnel server ws://0.0.0.0:10004 --restrict-http-upgrade-path-prefix ssh-tunnel --restrict-to localhost:10003
```

这里按前面所说的额外限制了 path perfix 和可以访问的端口以提高安全性.


== GitLab 安装和配置
在内网服务器上进行.

遵循#link("https://about.gitlab.com/install/?version=ce=debian")[官方教程]即可.

需要注意我们使用 SMTP 提供邮件服务, 所以不需要安装 postfix. 此外, 安装时首次 configurate 申请证书会失败, 这无关紧要, 我们之后使用自签名证书即可.

编辑 `/etc/gitlab/gitlab.rb` 中的这些配置项
- `external_url`: 如果你没有在安装时指定, 现在可以设置了, 我们提到过使用 `https://gitlab.example.com` 作为示例
- SMTP 相关配置: 我这里根据#link("https://docs.gitlab.com/omnibus/settings/smtp/=gmail")[官方文档]中的指引进行配置. 我还额外设置了 `gitlab_rails['gitlab_email_from']` 为真实的邮箱用户名.
- `letsencrypt['enable']`: 修改为 `false`. 我已经解释过.
- `nginx['listen_port']`: 如果你的服务器上还运行了其他占用 80 端口的服务, 可以把这个端口修改为其他端口, 这里使用 801 作为示例.

生成自签名证书
```sh
cd /etc/gitlab/ssl
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout gitlab.example.com.key -out gitlab.example.com.crt
sudo chmod 600 gitlab.example.com.*
sudo chown root:root gitlab.example.com.*
```

做完这些后, 可以重新配置和重启 GitLab:
```sh
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

== sshd 的安装和配置
在内网服务器上进行.

直接从系统软件源安装即可.

安全起见, 我们使用一个单独的端口暴露 Git over SSH 服务, 并且只允许 git 用户登录, 这里使用 221 端口作为示例.

在 `/etc/ssh/sshd_config` 添加
```conf
Port 221
Match LocalPort=221
  AllowUsers git
```

重启 SSHD 服务
```sh
sudo systemctl restart sshd
```

== FRP Client 的安装和配置
在内网服务器上进行.

从 frp 的#link("https://github.com/fatedier/frp")[官方仓库]下载即可.

然后对我们用到的 nginx 和 SSH 端口做转发:
```toml
serverAddr = "1.2.3.4"
serverPort = 10001
auth.token = "some-random-password"

[[proxies]]
name = "gitlab-web"
type = "tcp"
localPort = 801
remotePort = 10002

[[proxies]]
name = "gitlab-ssh"
type = "tcp"
localPort = 221
remotePort = 10003
```

启动 frpc
```sh
frpc -c gitlab.toml
```

== Cloudflare 的配置
在 Cloudflare 中解析 gitlab.example.com 到你的公网服务器即可.

== nginx 的安装和配置
在公网服务器上进行.

直接从系统的软件源安装即可.

我们需要获取内网服务器上 GitLab 服务使用的自签名证书
```sh
sudo bash -c 'echo | openssl s_client -connect localhost:10002 -servername gitlab.example.com 2>/dev/null | openssl x509 > /etc/nginx/ssl/gitlab_cert.pem'
```

此外, 我们还需要使用 #link("https://github.com/acmesh-official/acme.sh")[acme.sh] 申请证书, 遵从其官方指引即可, 这里不再赘述.

这里给出一个 `/etc/nginx/conf.d/gitlab.conf` 的参考配置, 具体可以根据实际情况再修改:
```conf
server {
    listen 443 ssl;
    server_name gitlab.example.com;

    ssl_certificate /root/.acme.sh/gitlab.example.com_ecc/gitlab.example.com.cer;
    ssl_certificate_key /root/.acme.sh/gitlab.example.com_ecc/gitlab.example.com.key;

    location / {
        proxy_pass https://localhost:10002;

        proxy_ssl_verify off;
        proxy_ssl_trusted_certificate /etc/nginx/ssl/gitlab_cert.pem;
        proxy_ssl_verify_depth 2;

        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    location /ssh-tunnel {
        if ($http_upgrade = "") {
            return 404;
        }
        proxy_redirect off;
        keepalive_timeout 12000s;
        proxy_pass http://127.0.0.1:10004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Host $host;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_intercept_errors on;
        proxy_pass_request_headers on;
    }
}

server {
    listen 80;
    server_name gitlab.example.com;

    location / {
        proxy_pass http://localhost:10002;
        proxy_ssl_verify off;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
}
```
== 客户端需要的额外配置
需要安装 wstunnel, 并且在 `~/.ssh/config` 中额外添加
```conf
Host gitlab.example.com
    ProxyCommand=wstunnel client wss://gitlab.example.com/ssh-tunnel --http-upgrade-path-prefix ssh-tunnel -L stdio://127.0.0.1:10003
```

= Troubleshooting
一些问题的诊断方法, 和我遇到的一些问题的解决方案.

== 我不知道 root 用户的密码
如果你忘记了在安装时指定 root 用户密码, 可以遵照 #link("https://docs.gitlab.com/security/reset_user_password/=reset-the-root-password")[官方文档] 中的方法修改密码.


== 无法访问服务
由内而外地诊断哪里出了问题. 比如先在内网服务器上 `curl http://localhost:801`, 测试通过再在公网服务器上测试 `localhost:10002`, `localhost:80`.

Git over SSH 的问题也可以以同样的方式诊断.

== GitLab 无法保存配置, 错误代码500
看上去是一些 token 错误引起的问题, 总体的解决方案就是删掉这些 token. 我尝试了若干方法, 已经不太清楚哪一步起了作用, 这里是我当时查阅过的内容:
- https://gitlab.com/gitlab-org/gitlab/-/issues/419923
- https://gitlab.com/gitlab-org/gitlab/-/issues/334862
- https://gitlab.com/gitlab-org/gitlab/-/issues/301170
- https://forum.gitlab.com/t/500-error-access-admin-runners-not-a-migration/100875

== 注册邮件无法正常发送
可以按照 GitLab #link("https://docs.gitlab.com/omnibus/settings/smtp/=email-not-sent")[官方文档] 中的步骤进行诊断.

如果最后发现 `Notify.test_email` 无法正常发信, 可以使用第三方工具比如 swaks 按相同的配置发信看看有无更详细的错误信息.
