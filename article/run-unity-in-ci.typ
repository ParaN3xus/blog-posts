#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "在 CI 中运行 Unity",
  desc: [使用个人授权证书在 CI 环境中运行 Unity],
  date: "2026-02-03",
  tags: (
    blog-tags.unity,
    blog-tags.programming,
  ),
  license: licenses.cc-by-nc-sa,
)

方法来自 #link("https://github.com/game-ci/documentation/issues/408#issuecomment-3211109962")[game-ci/documentation/issue/408] 中 #link("https://github.com/GabLeRoux")[\@GabLeRoux] 的评论.

= 获取个人证书
+ Unity Hub → Preferences → Licenses → Add
+ 即使你已经有证书了, 也要 Add 一个新的证书
+ 找到 `.ulf` 文件
  - Windows: `C:\ProgramData\Unity\Unity_lic.ulf`
  - MacOS: `/Library/Application Support/Unity/Unity_lic.ulf`
  - Linux: `~/.local/share/unity3d/Unity/Unity_lic.ulf`

= 获取序列号
Shell:
```sh
cat Unity_lic.ulf | grep DeveloperData | sed -E 's/.*Value="([^"]+)".*/\1/' | base64 --decode
```

PowerShell:
```powershell
Get-Content Unity_lic.ulf | Select-String -Pattern 'DeveloperData' | ForEach-Object { $_ -replace '.*Value="([^"]+)".*', '$1' } | [System.Convert]::FromBase64String($_)
```

= 在 CI 中运行 Unity
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: unityci/editor:ubuntu-2022.3.22f1-base-3.2.1

      - name: Run Unity
        env:
          UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
          UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}
          UNITY_SERIAL: ${{ secrets.UNITY_SERIAL }}
        run: |
          /opt/unity/Editor/Unity \
            -username "$UNITY_EMAIL" \
            -password "$UNITY_PASSWORD" \
            -serial "$UNITY_SERIAL" \
            -batchmode \
            -nographics \
            ...
```
