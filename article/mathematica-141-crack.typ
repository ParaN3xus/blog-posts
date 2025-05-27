#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "Wolfram Mathematica 14.1 Key Generator",
  desc: [
    使用 Wolfram Mathematica 14.1 的密钥生成器, 支持多种版本的 Mathematica 和 System Modeler.
  ],
  date: "2024-08-24",
  tags: (
    blog-tags.crack,
    blog-tags.free-ride,
    blog-tags.math,
  ),
)

最近 Wolfram 发布了新的 Mathematica 14.1 版本, 打破了之前不需要改注册机就能一直用的局面, 不过所幸毛子又发了新的[^1], 目测好像就是更新了以下 magic 值, 算法并无大的改动.

我费了一番力气才找到, 为了方便他人搬运到这里, #link("https://softoroom.org/ptopic79256.html")[原版链接].

使用方法和以前一样, 下方的激活码处保留了一个默认值, 如果手动删除留空则会随机生成.

#if is-web-target {
  html.elem(
    "script",
    attrs: (src: "/post_assets/mathematica-141-crack/mma_keygen.js"),
  )
  html.elem(
    "form",
    attrs: (id: "form"),
    html.elem(
      "fieldset",
      {
        [= 密钥生成器]
        html.elem(
          "div",
          attrs: ("class": "form-control w-full max-w-xs mb-4"),
          {
            html.elem(
              "label",
              attrs: ("class": "label", "for": "mathid"),
              {
                html.elem("span", attrs: ("class": "label-text"), "MathID:")
              },
            )
            html.elem(
              "input",
              attrs: (
                type: "text",
                id: "mathid",
                required: "required",
                pattern: "\\d{4}-\\d{5}-\\d{5}",
                class: "input input-bordered w-full max-w-xs",
                placeholder: "例如: 1234-12345-12345",
              ),
            )
          },
        )

        html.elem(
          "div",
          attrs: ("class": "form-control w-full max-w-xs mb-4"),
          {
            html.elem(
              "label",
              attrs: ("class": "label", "for": "activation-key"),
              {
                html.elem("span", attrs: ("class": "label-text"), "激活码:")
              },
            )
            html.elem(
              "input",
              attrs: (
                type: "text",
                id: "activation-key",
                value: "3893-9258-K6XJLE",
                class: "input input-bordered w-full max-w-xs",
              ),
            )
          },
        )

        html.elem(
          "button",
          attrs: (
            id: "button",
            onclick: "genPass(event)",
            class: "btn btn-primary",
          ),
          "生成密钥",
        )

        let ids = (
          "output141",
          "outputMath130",
          "outputMath120",
          "outputMath102",
          "outputMath100",
          "outputWPP130",
          "outputWPP120",
          "outputWPP102",
          "outputWPP100",
          "outputSM130",
          "outputSM050",
          "outputSM040",
        )
        for id in ids {
          html.elem("div", attrs: (id: id))
        }
      },
    ),
  )
}


