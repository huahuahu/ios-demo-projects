# 可打断动画 Demo 设计

## 目标

创建一个聚焦的 iOS demo project，用直接可操作的交互解释可打断、可恢复动画。读者可以拖拽一张卡片，在中途停下、反向拖动，然后松手，让动画从当前进度继续完成或回弹，而不是从头开始。

这个 demo 服务于一篇关于 UIKit `UIViewPropertyAnimator`、交互式动画进度，以及 SwiftUI 状态驱动动画对比的博客主题。

## 项目形态

新的独立 demo 目录为：

```text
interruptible-animation-demo/
  README.md
  project.yml
  .xcodebuildmcp/
    config.yaml
  InterruptibleAnimationDemo/
  InterruptibleAnimationDemoTests/
```

app 和 scheme 名称为 `InterruptibleAnimationDemo`。bundle identifier 为 `com.huahuahu.demo.InterruptibleAnimationDemo`。项目使用 XcodeGen、Swift 6.0、iOS 26.0，并把 development team 留空，方便本地 simulator 运行。

## 架构

app 使用 SwiftUI 外壳，并提供两个 tab：

1. `UIKit`：作为主要讲解入口。
2. `SwiftUI`：作为概念对照。

UIKit tab 会通过 `UIViewControllerRepresentable` 承载一个 UIKit view controller。这个 view controller 拥有一张可拖拽卡片和一个 `UIViewPropertyAnimator`。pan gesture 开始时暂停 animator，把拖拽距离映射到 `fractionComplete`，松手时再调用 `continueAnimation(...)`，让卡片从当前进度继续完成或回到原位。

SwiftUI tab 使用同样的视觉隐喻，但通过 state 来解释这个概念：手势更新临时覆盖卡片 offset，松手时改变目标状态并触发动画。这样对比会更准确：UIKit 暴露显式 animator 控制面，而 SwiftUI 通常通过改变 animated state 来表现“被新目标打断后继续过渡”的用户体验。

## 组件

### `AnimationSnapState`

`AnimationSnapState` 描述两个静止位置：collapsed 和 expanded。它提供展示文案和目标 progress，供两个 tab 共用。

### `AnimationProgressModel`

`AnimationProgressModel` 存放可测试的确定性计算：

- 把 progress clamp 到 `0...1`
- 把拖拽 translation 转换成 progress
- 根据 progress 和拖拽 velocity 选择最终 snap state

这个 model 让 demo 行为可以通过单元测试验证，而不依赖动画时序或 UIKit gesture recognizer。

### `InterruptibleUIKitViewController`

`InterruptibleUIKitViewController` 渲染主要 demo。它包含：

- 一张带简短说明文字的卡片
- 一个显示当前 animator 阶段和 progress 的状态 label
- 一个 pan gesture recognizer
- 一个在 collapsed 和 expanded 位置之间移动卡片的 `UIViewPropertyAnimator`

pan 过程中，controller 会调用 `pauseAnimation()`，更新 `fractionComplete`，并根据最终 snap state 反向或继续 animator。

### `UIKitInterruptibleDemoView`

`UIKitInterruptibleDemoView` 把 UIKit controller bridge 到 SwiftUI，让 app 可以保持简单的 tab-based shell。

### `SwiftUIInterruptibleDemoView`

`SwiftUIInterruptibleDemoView` 使用 SwiftUI gesture 和 state 镜像同样的卡片交互。它会包含解释文案，说明 SwiftUI 与 UIKit 的 API 差异：SwiftUI 不暴露同样的 `UIViewPropertyAnimator` 控制面，但在动画过程中改变 animated state，可以得到类似的“可被打断并过渡到新目标”的用户体验。

### `ContentView`

`ContentView` 展示两个 demo tab，并提供简洁的整体标题或入口结构。

## 数据流

静态状态从各 tab 流入共享的 progress model。手势更新生成 normalized progress。UIKit tab 把这个 progress 写入 `UIViewPropertyAnimator.fractionComplete`；SwiftUI tab 把同一个概念转换成临时 offset 和最终 snap state。

demo 不包含网络、持久化或用户生成数据。除了 UIKit 和 SwiftUI runtime 的动画插值之外，app 行为保持确定且易于测试。

## 错误处理和边界情况

demo 没有需要恢复的外部错误。内部边界情况通过 clamp progress、并在计算 snap decision 前防御无效 travel distance 来处理。极小布局尺寸下，卡片仍应保持可见，并避免产生负 travel distance。

gesture cancellation 会按 release 处理：卡片根据当前 progress 选择最近或最符合速度方向的 snap state，并从当前进度动画到该位置。

## 测试

测试聚焦稳定逻辑，而不是视觉时序：

- progress clamp 始终保持在 `0...1`
- 拖拽 translation 能映射到预期 progress
- snap decision 能根据 progress threshold 选择 expanded 或 collapsed
- 当 velocity 方向足够明确时，即使 progress 接近 threshold，也可以按 velocity 方向选择目标状态

项目不包含 pixel snapshot tests，因为目标是解释可打断动画概念，而不是锁定具体渲染细节。

## README 范围

demo README 会说明：

- interruptible 和 resumable animations 是什么
- 为什么 `UIViewPropertyAnimator` 是 UIKit 里的核心 API
- SwiftUI 对照与 UIKit 的差异
- 预期 Xcode/iOS 版本
- 如何运行 `xcodegen generate`
- 如何打开、运行和测试项目
- 哪些文件承载主要概念

## 验证计划

实现完成后，使用 `xcodegen generate` 生成 Xcode project，创建专用的 `InterruptibleAnimationDemo iPhone 17 Pro Max` simulator，写入 `.xcodebuildmcp/config.yaml`，并使用 XcodeBuildMCP `test_sim` 验证 simulator test target。
