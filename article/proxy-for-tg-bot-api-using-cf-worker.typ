#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "利用 Cloudflare Worker 实现的 Telegram Bot API 代理",
  desc: [
    如何使用 Cloudflare Worker 搭建 Telegram Bot API 代理, 解决国内无法直接访问的问题
  ],
  date: "2023-11-28",
  tags: (
    blog-tags.programming,
    blog-tags.network,
  ),
  license: licenses.cc-by-nc-sa,
)

*本代码已修复 "Bad Request: message text is empty" 异常. *

= 缘由

想用服务器搭一个青龙面板薅羊毛, 但是服务器在国内, Telegram 消息通知没法走官方API, 所以只能自建代理.

但是从网上的很多教程里面抄的代码在发送消息的时候都出现的上述异常, 似乎是因为 Post 请求的 data 没有一并转发(?), 最奇怪的是这些教程还都很新, 距今都不到一年.

最后也没找到不存在这个异常的代码, 所以决定自己写一个, 顺便理一下整个过程写一篇教程.

= 准备工作

- Cloudflare 账号
- 自己的域名

= 教程

== 创建和配置 Cloudflare Worker

登录 Cloudflare 后, 面板左侧的侧边栏中可以找到 "Workers & Pages".

进入后, 点击右侧的 "Create application", 然后点击 "Create Worker".

Worker 的名字可以随便填写, 然后点击 "Deploy".

点击 "Edit code" 进入编辑器, 全选粘贴以下代码

``` javascript
var URL_PATH_REGEX = /^\/bot(?<bot_token>[^/]+)\/(?<api_method>[a-z]+)/i;

var src_default = {
  async fetch(request) {
    const { pathname: path, search } = new URL(request.url);

    let matchResult;
    let apiUrl;

    try {
      matchResult = path.match(URL_PATH_REGEX);
    } catch (e) {
      return new Response("Invalid URL", {
        status: 400,
        headers: { "content-type": "text/plain" }
      });
    }

    if (matchResult && matchResult.groups) {
      const { bot_token, api_method } = matchResult.groups;
      apiUrl = "https://api.telegram.org/bot" + bot_token + "/" + api_method + search;
    } else {
      return new Response("Invalid URL", {
        status: 400,
        headers: { "content-type": "text/plain" }
      });
    }

    if (request.method === "GET") {
      const response = await fetch(apiUrl, {
        method: "GET",
        headers: request.headers
      });
      const responseBody = await response.text();

      return new Response(responseBody, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers
      });
    } else if (request.method === "POST") {
      const response = await fetch(apiUrl, {
        method: request.method,
        headers: request.headers,
        body: request.body
      });
      const responseBody = await response.text();

      return new Response(responseBody, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers
      });
    } else {
      return new Response("Unsupported Request Method", {
        status: 400,
        headers: { "content-type": "text/plain" }
      });
    }
  }
};
export {
  src_default as default
};
```

保存后点击右上角 "Save and deploy" 并确认.

== 添加DNS记录

由于 Cloudflare Workers 的默认域名已经被墙, 所以我们需要使用自己的域名, 并通过 Workers Route 调用刚刚创建的 Worker.

回到面板首页, 点击左侧侧边栏的 "Websites".

如果你的域名已经在使用Cloudflare, 那么直接点击你的域名, 否则先使用"Add a site"把域名添加到Cloudflare再进入.

点击左侧侧边栏 "DNS", 点击 "Add record", Type 选择 "A",Name 可填写 "tgproxy", IPv4 地址可以随意填写, 但是必须合法, Proxy status 要开启.

点击"Save"保存记录.

== 创建Workers Route

点击左侧侧边栏的 "Worker Routes".

点击右侧的 "Add route", 其中"Route"填写 `DNS记录中的Name.你的域名/*` ,"Worker" 选择你刚刚创建的Worker.

== 测试

可以使用以下的代码简单测试

```python
import requests
import json

TG_BOT_TOKEN = ''
TG_USER_ID = ''
TG_API_HOST = 'DNS记录中的Name.你的域名'

try:
    headers = {'Content-Type': 'application/json'}
    data = {'chat_id': TG_USER_ID, 'text': 'test'}
    json_data = json.dumps(data)

    response = requests.post(
        'https://' + TG_API_HOST + '/bot' + TG_BOT_TOKEN + '/sendMessage',
        headers=headers,
        data=json_data
    )
    print(response.text)
except Exception as e:
    print(e)
```

= 故障排除

如果运行测试中的代码后没有收到消息, 可以执行以下流程：

== 检查参数填写有无错误

将原代码 `TG_API_HOST` 行及其以下内容替换为：

```python
TG_API_HOST = 'api.telegram.org'

proxies = {
    "http": "http://127.0.0.1:7890",
    "https": "http://127.0.0.1:7890"
}

try:
    headers = {'Content-Type': 'application/json'}
    data = {'chat_id': TG_USER_ID, 'text': 'test'}
    json_data = json.dumps(data)

    response = requests.post(
        'http://' + TG_API_HOST + '/bot' + TG_BOT_TOKEN + '/sendMessage',
        headers=headers,
        data=json_data
    , proxies=proxies)
    print(response.text)
except Exception as e:
    print(e)
```

其中 `proxies` 的内容要更改为本机可用的代理.

若本测试不通过, 则参数出错.

== 检查Worker Route有无错误

将上一步故障排除中的代码的 `TG_API_HOST` 更改为使用的Worker的页面的Preview后的网址

若本测试仍不通过, 则 DNS 记录或 Worker Route 配置出错.

== 检查Cloudflare Worker有无错误

若上述两项检查都通过, 则为 Cloudflare Worker 配置出错.

= 总结

`index.js` 代码已经开源在 #link("https://github.com/paran3xus/telegram-bot-api-proxy-cf-worker")[Github].

虽然但是, 我不是很懂 JavaScript, 所以这个代码写得比较简陋(比起网上我之前找到的其他实现), 不过总算是能正常运行了.

我还是很疑惑为什么这么蠢的问题找不到现存的解决方案, 这篇 Blog 也算是做了一点小小的贡献吧.
