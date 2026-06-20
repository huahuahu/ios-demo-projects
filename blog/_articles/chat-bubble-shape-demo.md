---
title: 用 SwiftUI Shape 画一个带圆润尾巴的聊天气泡
description: 记录如何从参考图拆解聊天气泡轮廓，先用 SVG 调出尾巴，再把路径参数迁移到 SwiftUI Shape。
summary: 通过 ChatBubbleShapeDemo 说明聊天气泡不是圆角矩形加三角形，而是一条连续外轮廓；尾巴用多段三次贝塞尔曲线从网页 SVG 映射到 SwiftUI Path。
category: Investigation
tag: SwiftUI Shape
date: 2026-06-20
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/chat-bubble-shape-demo
result_url: https://github.com/huahuahu/ios-demo-projects/blob/main/chat-bubble-shape-demo/samples/reference-vs-current-comparison.jpg
---

## 想解决的问题

这次 demo 想复刻一个看起来像贴纸的聊天气泡：淡紫色填充、粗紫色描边、柔和阴影、很大的圆角，以及左下角一个短短的圆润尾巴。

最容易想到的做法，是先画一个 `RoundedRectangle`，再在左下角叠一个三角形或水滴形 tail。实际试下来，这个方向很容易出问题：

- 尾巴会像“贴上去”的独立形状，而不是气泡外轮廓的一部分。
- 三角形尖端太锐，和参考图里的软边不一致。
- 尾巴和左下角、底边交界处容易出现硬折角。
- 改一个参数时，尾巴方向、长度、圆角都会一起跑偏。

最后比较稳定的理解是：**这个气泡应该被画成一条连续的外轮廓。** 尾巴不是额外 append 到圆角矩形上的小组件，而是从底边走到左下角时经过的一段曲线。

## Demo 里有什么

`chat-bubble-shape-demo` 是一个很小的 SwiftUI demo。页面入口在 `ChatBubbleShapeDemo/ContentView.swift`，主视图先展示 reference bubble，再列出几组参数变体。

核心文件是：

- `ChatBubbleShapeDemo/ChatBubbleShape.swift`：自定义 `Shape`，真正生成气泡路径。
- `ChatBubbleShapeDemo/ChatBubbleView.swift`：把 shape 用在文字背景上，并加上 fill、stroke、shadow 和文字 padding。
- `ChatBubbleShapeDemo/ChatBubbleStyle.swift`：保存不同 preset 的颜色、描边宽度、圆角和尾巴参数。
- `ChatBubbleShapeDemoTests/ChatBubbleShapeTests.swift`：验证路径不越界、尾巴在左下角、尾巴不是长底线，也不是尖角。

当前 reference 样式的关键参数是：

```swift
static let reference = ChatBubbleStyle(
    fill: Color(red: 0.82, green: 0.80, blue: 1.0),
    stroke: Color(red: 0.54, green: 0.43, blue: 0.96),
    strokeWidth: 8,
    cornerRadius: 38,
    tailWidth: 16,
    tailHeight: 14,
    tailInset: 6,
    shadowColor: Color.black.opacity(0.26),
    shadowRadius: 8,
    shadowX: 0,
    shadowY: 5,
    textColor: Color(red: 0.12, green: 0.11, blue: 0.18)
)
```

效果对照图保存在 demo 的 `samples/` 目录，也复制到了本文资产目录：

![Reference 与当前 iOS 实现的聊天气泡对照]({{ '/chat-bubble-shape-demo/assets/reference-vs-current-comparison.jpg' | relative_url }})

## 第一步：不要急着在 SwiftUI 里盲调

一开始直接在 SwiftUI `Path` 里调控制点，问题是反馈成本太高。每次改一点点，都要 build、run、screenshot，再和参考图对比。更麻烦的是，SwiftUI 代码里混着 body rect、corner radius、tail width、tail height，很难判断到底是哪段曲线出了问题。

所以中间换了一个方法：**先用网页 SVG 单独画气泡外轮廓。**

SVG prototype 里的核心路径是：

```svg
<path d="
  M 110 30
  L 546 30
  Q 598 30 598 82
  L 598 138
  Q 598 190 546 190
  L 128 190
  C 113 190 102 199 91 207
  C 80 215 68 209 74 198
  C 80 188 75 183 66 176
  C 61 171 58 154 58 138
  L 58 82
  Q 58 30 110 30
  Z
" />
```

这段 path 的 body 参考区域是：

```text
x = 58
y = 30
width = 540
height = 160
radius ≈ 52
```

这个阶段最重要的收获不是某一个具体数字，而是轮廓结构：

1. 从顶部左圆角开始，顺时针画完整气泡。
2. 右上、右下、左上这些角仍然可以理解成圆角矩形的圆角。
3. 走到底边左侧时，不直接进入左下圆角，而是先进入尾巴。
4. 尾巴由几段三次贝塞尔曲线组成，先向左下形成软肚子，再向上收回左边缘。
5. 最后再回到左边缘和左上圆角，闭合路径。

换句话说，参考图里的尾巴更像“底边在左下角自然弯出去的一段脚”，不是一个三角箭头。

## 为什么尾巴要用多段曲线

如果只用一条曲线连接底边和左边缘，尾巴通常会变成一个很薄的钩子。它能弯，但缺少厚度，也很难形成参考图里那种圆润的底部。

如果用两条曲线做一个尖端，尾巴又容易像消息气泡常见的尖嘴。参考图里的尾巴不是尖嘴，它的最低区域是圆的，并且描边很粗，所以尖角会被放大。

最后 SVG path 里尾巴用了四段三次贝塞尔：

```text
L 128 190
C 113 190 102 199 91 207
C 80 215 68 209 74 198
C 80 188 75 183 66 176
C 61 171 58 154 58 138
```

可以把它拆成四个动作：

1. `L 128 190`：底边先走到尾巴和主体的连接点。
2. 第一段 `C`：从底边向左下方过渡，形成尾巴上沿。
3. 第二段 `C`：绕过尾巴最低处，避免尖角。
4. 第三、第四段 `C`：往左边缘收回，并顺到左侧边线。

这里的关键是，**尾巴的最低点不是一个孤立 tip，而是曲线经过的一段圆润区域。**

## 把 SVG 坐标迁移到 SwiftUI Path

有了网页里的参数后，SwiftUI 里不需要重新发明形状，只要做坐标映射。

`ChatBubbleShape` 先根据传入的 `rect` 计算一个 `body`：

```swift
let body = CGRect(
    x: rect.minX,
    y: rect.minY,
    width: max(0, rect.width - 0.0001),
    height: rect.height - safeTailHeight * 1.1
)
```

这里 body 高度会给 tail 预留空间。否则 SVG 尾巴向下伸出时，`Path.boundingRect` 会超过 SwiftUI 给 shape 的 `rect`。

接着用 SVG 的 body 宽度 `540` 做等比缩放：

```swift
let svgScale = max(0.01, geometry.body.width / 540.0)
func svgPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(
        x: geometry.body.minX + (x - 58.0) * svgScale,
        y: geometry.body.maxY + (y - 190.0) * svgScale
    )
}
```

这段映射里有两个锚点：

- SVG body 的左边是 `x = 58`，所以 iOS 的 `x` 要减掉 `58` 后再加到 `body.minX`。
- SVG body 的底边是 `y = 190`，所以 iOS 的 `y` 要减掉 `190` 后再加到 `body.maxY`。

这样一来，SVG 里的 `L 128 190` 在 SwiftUI 中就表示“从 body 底边左侧某个位置开始进入尾巴”，而 `C ... 91 207` 这种 y 大于 `190` 的点，就会自然落到 body 底边下方。

迁移后的尾巴路径是：

```swift
path.addLine(to: svgPoint(128, 190))
path.addCurve(
    to: svgPoint(91, 207),
    control1: svgPoint(113, 190),
    control2: svgPoint(102, 199)
)
path.addCurve(
    to: svgPoint(74, 198),
    control1: svgPoint(80, 215),
    control2: svgPoint(68, 209)
)
path.addCurve(
    to: svgPoint(66, 176),
    control1: svgPoint(80, 188),
    control2: svgPoint(75, 183)
)
path.addCurve(
    to: svgPoint(58, 158),
    control1: svgPoint(61, 174),
    control2: svgPoint(58, 166)
)
```

这样做的好处是，网页 prototype 和 iOS 实现之间有一条明确的参数迁移路径。后续如果要继续调尾巴，不必在 SwiftUI 里凭感觉改，可以先在 SVG 里调出视觉结果，再把坐标同步过来。

## 主体圆角仍然用 SwiftUI 原生命令

虽然尾巴来自 SVG 坐标，主体并没有完全逐点照抄 SVG。SwiftUI 代码仍然用 `addLine` 和 `addQuadCurve` 画主体四周：

```swift
path.move(to: CGPoint(x: geometry.body.minX + geometry.safeRadius, y: geometry.body.minY))
path.addLine(to: CGPoint(x: geometry.body.maxX - geometry.safeRadius, y: geometry.body.minY))
path.addQuadCurve(
    to: CGPoint(x: geometry.body.maxX, y: geometry.body.minY + geometry.safeRadius),
    control: CGPoint(x: geometry.body.maxX, y: geometry.body.minY)
)
```

这里保留 SwiftUI 计算出来的 `safeRadius`，是为了让 shape 在不同尺寸下更稳。测试里也覆盖了小 rect 情况，确保 radius 不会超过 body 宽高的一半：

```swift
XCTAssertLessThanOrEqual(geometry.safeRadius, geometry.body.width / 2.0)
XCTAssertLessThanOrEqual(geometry.safeRadius, geometry.body.height / 2.0)
```

所以最终实现不是“完整复制 SVG path”，而是一个混合方案：

- 主体：由 SwiftUI 根据当前 rect 和 corner radius 动态画。
- 尾巴：使用网页 SVG 里调好的相对坐标，按 body 宽度缩放。

这个折中让主体保持可参数化，也让最难调的尾巴拥有稳定视觉来源。

## 描边圆角也很重要

网页 SVG 里有两个容易忽略的属性：

```css
stroke-linejoin: round;
stroke-linecap: round;
```

如果 SwiftUI 只写：

```swift
bubbleShape.stroke(style.stroke, lineWidth: style.strokeWidth)
```

一些连接处会显得更硬，尤其是尾巴底部和尾巴收回左边缘的位置。Demo 在 `ChatBubbleView` 里改成了明确的 `StrokeStyle`：

```swift
bubbleShape
    .stroke(
        style.stroke,
        style: StrokeStyle(
            lineWidth: style.strokeWidth,
            lineCap: .round,
            lineJoin: .round
        )
    )
```

这个改动不改变填充区域的 path，但会明显影响粗描边的观感。对这种贴纸感气泡来说，stroke 不是装饰细节，而是整体轮廓的一部分。

## Text padding 为什么要知道 tailWidth

`ChatBubbleView` 里文字不是直接贴在 shape 中间，而是专门给左侧多留了一些空间：

```swift
Text(message)
    .padding(.leading, style.tailWidth + 14)
    .padding(.trailing, 18)
    .padding(.vertical, 16)
```

因为左下角有尾巴，文字如果只按普通圆角矩形 padding，很容易离尾巴和左侧描边太近。这里把 `tailWidth` 纳入 leading padding，是为了让文字布局和外轮廓保持解耦：shape 负责画轮廓，view 负责安排内容区域。

## 测试验证了什么

这个 demo 的测试不试图做像素级截图比对，而是验证几个几何事实：

1. `Shape.path(in:)` 生成的 bounds 不为空，并且不超过传入 rect。
2. 尾巴仍在左下角附近，没有跑到 rect 外。
3. 尾巴和底边的连接很短，不会变成一条长底线。
4. 尾巴有圆润底部：`tailBase.y` 比 `tailTip.y` 更低，说明它不是一个尖锐 tip。
5. 小尺寸 rect 下，radius 会被 clamp，避免路径自交或反向。

例如这个测试描述的是尾巴的“圆脚”：

```swift
XCTAssertLessThan(
    geometry.tailTip.x,
    geometry.tailBase.x,
    "The rounded foot should curve rightward from the left tail tip."
)
XCTAssertGreaterThan(
    geometry.tailBase.y,
    geometry.tailTip.y,
    "The tail should have a soft lower belly instead of a sharp point."
)
XCTAssertGreaterThan(
    geometry.tailJoin.x,
    geometry.tailBase.x,
    "The tail should blend into the bottom edge to the right of the rounded foot."
)
```

最终用 XcodeBuildMCP 在模拟器上跑过测试：

```text
12 tests passed, 0 failed, 0 skipped
```

并用 `build_run_sim` 启动 app，截图生成 `samples/reference-vs-current-comparison.jpg` 做人工对照。

## 这次学到的东西

第一，复杂一点的 `Shape` 不一定适合一开始就在 SwiftUI 里调。SVG 更适合快速观察曲线、控制点和连接关系。等形状稳定后，再把 SVG 坐标映射回 SwiftUI。

第二，聊天气泡尾巴的关键不是“画一个尾巴”，而是“决定外轮廓怎么经过左下角”。如果把 tail 当成独立 overlay，天然就容易有贴片感。

第三，粗描边会放大路径连接处的问题。`lineJoin` 和 `lineCap` 是否为 `.round`，会直接影响尾巴是不是圆润。

第四，参数化 shape 要同时考虑视觉和几何边界。尾巴向 body 下方伸出时，body 高度就必须给 tail 预留空间，否则 path 会超过 SwiftUI 分配的 rect。

## 可以继续尝试的方向

现在 demo 已经把 reference bubble 和几个样式变体跑起来了。后续如果继续打磨，可以尝试两件事：

1. 把 `svgPoint` 迁移成一个更明确的 `TailPathModel`，把 SVG 原始坐标、缩放策略、语义点名集中管理。
2. 增加一个只截取 hero bubble 的对照图，而不是整屏截图，这样更容易肉眼比较尾巴细节。

但这篇文章的核心结论已经够明确：**要画出这种圆润的聊天气泡，先把它当成一条连续轮廓，再用多段贝塞尔曲线处理左下角尾巴。**
