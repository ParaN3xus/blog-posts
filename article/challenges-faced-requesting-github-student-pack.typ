#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "GitHub 学生包申请踩坑",
  desc: [申请 GitHub 学生包的经验分享],
  date: "2023-09-10",
  tags: (
    blog-tags.free-ride,
  ),
  license: licenses.cc-by-nc-sa,
)

心血来潮(早有预谋)想要申请 GitHub 学生包, 跟随网上已有的教程走了一遭发现还是有一些没法解决的问题, 经过一些摸索后决定写这篇踩坑.

= 要求 completed your GitHub user profile

== 问题

拒绝原因表现为:

#quote[
  You are unlikely to be verified until you have completed your #link("https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-profile/customizing-your-profile/personalizing-your-profile")[GitHub user profile] with your full name exactly as it appears in your academic affiliation document plus a short bio. Please do not use a variation of your name or a nickname. Once you have updated your profile information log out and log back into GitHub before re-applying.

  Have you completed your #link("https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-profile/customizing-your-profile/personalizing-your-profile")[GitHub user profile] with all your relevant information, such as your full name as it appears in your image and a short bio?
]

即使你按照其要求, 将自己的用户名改为学生卡的信息也不能成功.

== 解决方案

在 community 中找到了相关的问题, 并找到了用户 snowball-rain 分享的解决方法, 原链接: #link("https://github.com/orgs/community/discussions/53463")['The GitHub Student Developer Pack' was not verified in spite of my student ID is valid · community · Discussion =53463]

具体的方法如下:

+ 修改Github user profile
  - Name (注意不是登录使用的 Username) 改为学生卡(其它证明材料)的名字, 使用英文(拼音).
  - Bio 改为 xxx of XXX University, 这里要填写自己和自己学校名字的英文.
+ 让需要的信息的英文出现在学生卡(其它证明材料)的照片上: 拍下来后自己在图片上加上翻译
  - 学校名
  - Name, 需要和 profile 填写的一致
  - Valid Date, 比如 vaild until 09/2023, 如果中文版没有这个信息, 那么需要把发卡日期和学制等信息一并翻译(一般都有吧).
+ 不要上传图片, 要拍. 电脑打开图片, 然后手机对着电脑上修改过的图片拍.
+ 等, 我等了好多天.

