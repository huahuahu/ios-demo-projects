---
title: iOS 26 UIKit 的 updateProperties 和 Observation Tracking
description: 通过一个 UIKit demo 理清 updateProperties、updateConstraints、layoutSubviews 与 Swift Observation 状态依赖之间的关系。
summary: 用 UIView 和 UIViewController 两组实验验证 iOS 26 UIKit update methods 如何通过 Observation tracking 自动响应状态变化。
category: Investigation
tag: UIKit
date: 2026-06-21
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/uikit-update-properties-demo
---

## 起点：状态驱动的 UIKit 到底驱动了什么？

iOS 26 里 UIKit 开始更明确地拥抱 Swift Observation。最容易注意到的新入口是 `updateProperties()`：在 `UIView` 或 `UIViewController` 里读取 observable state，state 改变后 UIKit 会自动重新运行对应的 update method。

一开始我以为这只影响 property update，比如改 label text、hidden、alpha。后来继续查文档和做 demo 才发现，这个结论不够完整：`UIView.updateConstraints()` 也支持 automatic observation tracking。真正的边界不是“property 会自动、constraints 不会自动”，而是：

> 哪个 UIKit update method 读取了哪个 observable property，那个 property 改变时，UIKit 就会重新调度对应的 method。

这篇文章记录这个理解是怎么通过 demo 被拆开的。

## 最小背景：UIKit 的几个 update 入口

这个 demo 关注四类 callback：

- `updateProperties()`：更新 view 或 view controller 的普通 UI properties。
- `updateConstraints()`：更新 view 内部约束。
- `layoutSubviews()`：布局 pass 中对子视图 frame/layout 的处理。
- `viewWillLayoutSubviews()` / `viewDidLayoutSubviews()`：controller 观察 root view layout 前后的入口。

在 iOS 26 的 Observation tracking 语境下，关键不是“它们谁先谁后”，而是“它们各自读了什么 state”。每个 method 会建立自己的 observation dependency。

## Demo 结构

Demo 在 `uikit-update-properties-demo/`，用 XcodeGen 生成 UIKit app。核心文件是：

- `UIKitUpdatePropertiesDemo/DemoState.swift`：`@Observable` 状态源。
- `UIKitUpdatePropertiesDemo/DemoAction.swift`：按钮行为和预期 invalidation 类型。
- `UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift`：UIView 版本实验。
- `UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift`：UIViewController 版本实验。
- `UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift`：把 callback 写到屏幕日志、`Logger` 和 stdout。

状态对象很小：

```swift
@Observable
final class DemoState {
    var isDetailHidden = false
    var detailHeight: CGFloat = 140
    var layoutMarker: Int = 0
    var controllerMessage = "Controller title is normal"
    var statusText = "Tap an action to observe which UIKit callbacks run."
}
```

几个按钮故意改变不同 state：

- `Controller text only`：只改 `controllerMessage`。
- `Toggle hidden`：只改 `isDetailHidden`。
- `Constraint update`：改 `detailHeight`。
- `Layout only`：只改 `layoutMarker`，并显式调用 `setNeedsLayout()`。

## UIView：同一个 state 可以驱动不同 update method

UIView 页最直接。`InstrumentedPanelView.updateProperties()` 读取 `statusText` 和 `isDetailHidden`：

```swift
override func updateProperties() {
    super.updateProperties()
    recorder.record(.updateProperties, note: "UIView read observable state")
    statusLabel.text = state.statusText
    detailView.isHidden = state.isDetailHidden
    detailLabel.text = state.isDetailHidden ? "Hidden by state" : "Visible detail area"
    refreshLog()
}
```

`updateConstraints()` 读取的是 `detailHeight`：

```swift
override func updateConstraints() {
    recorder.record(.updateConstraints, note: "UIView applied height constraint = \(Int(state.detailHeight))")
    detailHeightConstraint.constant = state.detailHeight
    refreshLog()
    super.updateConstraints()
}
```

所以点击 `Constraint update` 时，`detailHeight` 改变，会自动重跑 `updateConstraints()`。这不是因为按钮手动调用了 `setNeedsUpdateConstraints()`；demo 的 action 文案测试还特意保证 `constraintUpdate` 的说明里不包含 `setNeedsUpdateConstraints`。

这也是最容易误解的地方：`updateConstraints()` 自己读了 observable state，所以它自己建立了 tracking。

## 为什么更新约束后会看到 layoutSubviews？

`updateConstraints()` 里改了 `detailHeightConstraint.constant`。约束常量变化后，Auto Layout 需要重新计算布局，所以后面出现 `layoutSubviews()` 很正常。

但这和 Observation tracking 是两层机制：

1. `detailHeight` 改变，让 UIKit 知道要重新运行读取过它的 `updateConstraints()`。
2. `updateConstraints()` 改了约束常量，让 Auto Layout 后续进入 layout pass。

也就是说，`layoutSubviews()` 不是因为它自动 tracking 了 `detailHeight` 才出现，而是因为约束系统真的需要重新 layout。

## Toggle hidden：为什么也可能看到 layout？

`Toggle hidden` 改的是 `isDetailHidden`。在 demo 里，`updateProperties()` 会把它映射到：

```swift
detailView.isHidden = state.isDetailHidden
```

如果这个 view 是 `UIStackView` 的 arranged subview，`isHidden` 会影响 stack view 的排列结果。于是你可能看到 layout callback。这仍然不是 constraints tracking；它只是 UI 属性变化带来的布局副作用。

所以更准确的判断方式是：看哪个 method 读了哪个 state，而不是只看最终日志里有没有 layout。

## Layout only：显式 layout request 和 constraints tracking 分开

`layoutOnly` 只增加 `layoutMarker`：

```swift
case .layoutOnly:
    layoutMarker += 1
```

这个 state 没有被 `updateConstraints()` 读取，所以它不会建立 constraints dependency。UIView 页为了演示 layout request，会在 action handler 中显式调用 `setNeedsLayout()`。

这个按钮的意义是把两件事分开：

- 改 observable state 并不必然等于更新 constraints。
- 调用 `setNeedsLayout()` 只是请求 layout，不会让 constraints tracking magically 发生。

## UIViewController：没有 updateConstraints，但可以在 updateProperties 里更新约束常量

UIViewController 没有 `updateConstraints()` 可以 override。那如果某个页面级约束由 VC 持有，并且它依赖 state，应该放哪里？

这个 demo 选择在 VC 的 `updateProperties()` 里读取 state 并更新约束常量：

```swift
override func updateProperties() {
    super.updateProperties()
    title = state.isDetailHidden ? "VC Hidden State" : "UIViewController"
    titlePreviewLabel.text = state.controllerMessage
    if let titlePreviewHeightConstraint {
        ControllerPropertyBinding.apply(detailHeight: state.detailHeight, to: titlePreviewHeightConstraint)
    }
    statusLabel.text = state.statusText
    recorder.record(.updateProperties, note: "UIViewController read observable state and applied height constraint = \(Int(state.detailHeight))")
    refreshLog()
}
```

其中 helper 很直接：

```swift
@MainActor
enum ControllerPropertyBinding {
    static func apply(detailHeight: CGFloat, to heightConstraint: NSLayoutConstraint) {
        heightConstraint.constant = detailHeight
    }
}
```

这里的重点是 `updateProperties()` 读取了 `state.detailHeight`。因此点击 `Constraint update` 后，VC 的 property update 会重新运行，然后把新高度写进 `titlePreviewHeightConstraint.constant`。

这适合“页面级约束由 VC 组装和持有”的情况。如果约束是某个可复用 view 的内部布局规则，更好的边界仍然是放回 custom `UIView`，由它自己的 `updateConstraints()` 或 `updateProperties()` 处理。

## Label text 一行变两行，需要 updateConstraints 吗？

通常不需要。

如果只是根据 state 改 `UILabel.text`，并且布局依赖 label 的 intrinsic content size，那么放在 `updateProperties()` 里即可：

```swift
titlePreviewLabel.text = state.controllerMessage
```

文本从一行变两行会影响 intrinsic content size，Auto Layout 后续会处理布局。只有当你要改的是约束本身，例如高度、间距、激活/禁用某条 constraint，才需要把 state 映射到 constraint property。

在 VC 里，这个映射可以是 `updateProperties()`。在 UIView 内部，则可以是 `updateConstraints()`。

## 没有 Observation tracking 能不能用 updateProperties？

可以用，但语义不同。

没有 automatic observation tracking 时，`updateProperties()` 仍然是一个更新 UI property 的入口；只是 state 改变后 UIKit 不会自动知道该重跑它。你需要自己调用对应的 invalidation API，例如手动请求 property update。

Observation tracking 解决的是“谁读了 state，state 改变后谁应该重新运行”的自动依赖收集问题。

## 日志怎么验证

`LifecycleEventRecorder` 每次记录三份输出：

```swift
Self.logger.info("\(message, privacy: .public)")
print("[LifecycleEventRecorder] \(message)")
```

所以 demo 既能在屏幕上看到 callback 顺序，也能通过 simulator runtime log grep `[LifecycleEventRecorder]`。这对 agentic coding 很有用：不用人工盯 Xcode console，也能判断点击按钮后哪些 UIKit lifecycle method 真的跑了。

测试层面，demo 覆盖了几条关键边界：

- `constraintUpdate` 会改变 `detailHeight`，并保持没有显式 `setNeedsUpdateConstraints` 的文案。
- `layoutOnly` 只改 `layoutMarker`，不能误改 `detailHeight`。
- `controllerTextOnly` 只改 controller message，不影响 layout marker、hidden、height。
- `ControllerPropertyBinding.apply(detailHeight:to:)` 会把 state height 写入约束常量。

最后一次验证中，XcodeBuildMCP 跑过 12 个 unit tests，随后 simulator build/run 成功。

## 最终理解

这次 demo 让我把几个概念分清了：

1. `updateProperties()` 不是“会自动 layout”的新魔法，它是一个可被 Observation tracking 自动调度的 property update 入口。
2. `updateConstraints()` 也支持 automatic observation tracking；只要它读取了 observable state，state 改变后就能自动重跑。
3. Observation dependency 是 per-method 的：哪个 method 读了哪个 state，就由哪个 method 响应该 state 的变化。
4. layout callback 出现不一定代表 layout method tracking 了某个 state，也可能只是 property 或 constraint 变化造成了正常 layout pass。
5. VC 没有 `updateConstraints()`，但页面级约束常量可以在 `UIViewController.updateProperties()` 中根据 state 更新。

一句话总结：**UIKit 的状态驱动不是把所有 update 混成一个大刷新，而是让每个 update method 根据自己读取过的 state 建立独立依赖。**

