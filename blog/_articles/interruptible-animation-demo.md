---
title: 用 UIViewPropertyAnimator 理解 iOS 可打断动画
description: 通过一个 UIKit 和 SwiftUI 对照 demo，理解可打断动画、fractionComplete、isReversed 和从当前进度继续动画的核心概念。
summary: 用拖拽卡片 demo 解释 UIViewPropertyAnimator 如何让动画暂停、跟随手势、反向并从当前进度继续。
category: Investigation
tag: iOS Animation
date: 2026-06-21
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/interruptible-animation-demo
---

## 问题：动画为什么需要“可打断”

普通 `UIView.animate` 很适合做一次性动画：

```swift
UIView.animate(withDuration: 0.3) {
    view.alpha = 0
}
```

它表达的是：“从当前状态动画到目标状态”。但如果动画过程中用户参与了交互，比如拖拽卡片、抽屉或播放器面板，问题就变复杂了：

- 用户拖到一半松手，动画应该从当前位置继续。
- 用户反向拖动，动画应该能掉头。
- 动画还没完成时，用户再次操作，视图不应该突然跳到起点或终点。
- 动画进度最好能和手势进度绑定。

这类动画通常被称为 interruptible animation，中文可以理解成“可打断动画”或“可恢复动画”。

这次 demo 的目标就是用一张可拖拽卡片解释这件事：UIKit 里用 `UIViewPropertyAnimator` 明确控制动画进度；SwiftUI 里则用状态和 displayed progress 做概念对照。

## Demo 结构

demo 目录是：

```text
interruptible-animation-demo/
  README.md
  project.yml
  InterruptibleAnimationDemo/
  InterruptibleAnimationDemoTests/
```

主入口在 `ContentView.swift`：

```swift
TabView {
    UIKitInterruptibleDemoView()
        .tabItem {
            Label("UIKit", systemImage: "hand.draw")
        }

    SwiftUIInterruptibleDemoView()
        .tabItem {
            Label("SwiftUI", systemImage: "swift")
        }
}
```

它分成两个 tab：

1. UIKit：主讲 `UIViewPropertyAnimator`。
2. SwiftUI：对照状态驱动动画如何 retarget。

下面这段录屏展示了 demo 的核心交互：卡片可以跟随拖拽改变进度，松手后从当前位置继续到目标状态。

<video controls muted playsinline preload="metadata" style="max-width: 100%; border-radius: 12px;">
  <source src="{{ '/interruptible-animation-demo/assets/ani.mp4' | relative_url }}" type="video/mp4">
  你的浏览器不支持直接播放这个视频，可以查看 demo 目录中的录屏文件。
</video>

## UIViewPropertyAnimator 像一个“可控制的电梯”

可以把 `UIViewPropertyAnimator` 想成一部电梯：

- 起点：collapsed
- 终点：expanded
- 当前楼层：`fractionComplete`
- 暂停：`pauseAnimation()`
- 继续：`continueAnimation(...)`
- 掉头：`isReversed = true`

普通 `UIView.animate` 更像“按下按钮后自动跑完”。`UIViewPropertyAnimator` 则把动画变成了一个对象，你可以随时问它当前状态、暂停它、修改它的进度、让它反向，再继续跑。

Apple 文档里对 `UIViewPropertyAnimator` 的定位也是这个方向：它允许动态修改动画，并可以通过 `fractionComplete` scrub 一个 paused animation。

## 核心模型：把拖拽转换成 progress

demo 没有直接把手势 translation 写进 view 的位置，而是先转换成一个统一的 progress。

`AnimationProgressModel.swift` 里约定：

- `0` 表示 collapsed
- `1` 表示 expanded
- 向上拖动 progress 增加
- 向下拖动 progress 减少

核心方法是：

```swift
static func progress(
    startProgress: CGFloat,
    translation: CGFloat,
    travelDistance: CGFloat
) -> CGFloat {
    guard travelDistance > 0 else {
        return clampedProgress(startProgress)
    }

    let delta = -translation / travelDistance
    return clampedProgress(startProgress + delta)
}
```

UIKit 里 y 轴向下为正，所以用户向上拖时 `translation` 是负数。为了让“向上 = progress 增加”，代码用了：

```swift
let delta = -translation / travelDistance
```

松手时再根据 progress 和 velocity 决定最终目标：

```swift
static func snapState(progress: CGFloat, velocity: CGFloat) -> AnimationSnapState
```

如果速度很明确，就按速度方向吸附；否则用 `0.5` 作为 threshold。

## UIKit：真正的可打断动画

UIKit 主 demo 在 `InterruptibleUIKitViewController.swift`。

它的手势流程是：

```swift
@objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    switch gesture.state {
    case .began:
        beginInteractiveAnimation()

    case .changed:
        // translation -> progress -> fractionComplete

    case .ended, .cancelled, .failed:
        // progress + velocity -> target
        // continueAnimation

    default:
        break
    }
}
```

### began：创建或暂停 animator

用户开始拖拽时，代码会进入 `beginInteractiveAnimation()`。

如果当前已经有 active animator，说明动画可能正在进行中。这时不要重新创建动画，而是暂停当前 animator：

```swift
if animator.isRunning {
    animator.pauseAnimation()
}
```

如果没有 active animator，就创建一个 paused animator：

```swift
_ = makePausedAnimator(to: forwardTarget, from: displayedProgress)
```

这个点很重要：可恢复动画的关键不是不断创建新动画，而是尽量保留当前 active animator 的上下文。

### changed：用手势 scrub 动画进度

拖拽变化时，demo 先算出绝对 progress：

```swift
let progress = AnimationProgressModel.progress(
    startProgress: interactionStartProgress,
    translation: translation,
    travelDistance: travelDistance
)
```

然后把这个 progress 转换成 animator 自己的局部 `fractionComplete`：

```swift
animator?.fractionComplete = AnimationProgressModel.animatorFraction(
    absoluteProgress: progress,
    startProgress: activeAnimatorStartProgress,
    targetProgress: activeAnimatorForwardTarget.targetProgress
)
```

这里为什么要转换？

因为 demo 里的 progress 是“卡片在 collapsed-expanded 之间的全局位置”，但 `UIViewPropertyAnimator.fractionComplete` 是“当前 animator 从自己的起点到终点的局部进度”。

如果 animator 是从 `0.4` 开始跑到 `1.0`，那么：

- absolute progress `0.4` 对 animator 来说是 `fractionComplete = 0`
- absolute progress `0.7` 对 animator 来说才是 `fractionComplete = 0.5`

这就是 `animatorFraction(...)` 存在的原因。

### ended：从当前进度继续或反向

松手后，demo 根据当前 progress 和 velocity 算出目标：

```swift
let targetState = AnimationProgressModel.snapState(
    progress: progress,
    velocity: velocity
)
```

然后继续动画：

```swift
continueAnimation(to: targetState, from: progress)
```

继续时会生成一个 `AnimatorContinuationPlan`：

```swift
let plan = AnimatorContinuationPlan.plan(
    activeForwardTarget: forwardTarget,
    releaseTarget: targetState
)
```

它决定两件事：

- 是否需要 `isReversed`
- `durationFactor` 不能是 `0`

如果用户拖到一半又决定回去，代码会：

```swift
activeAnimator.isReversed = true
activeAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
```

这就是 UIKit tab 里最核心的教学点：同一个 paused animator，可以通过 `fractionComplete` 被手势控制，也可以通过 `isReversed` 改变方向，再通过 `continueAnimation` 从当前进度继续。

## 一个容易踩的坑：不要松手后重建 animator

最初实现里有一个典型问题：松手时重新创建了 animator，然后把旧的 progress 写进新 animator 的 `fractionComplete`。

这会导致两个风险：

1. 新 animator 的起点已经是当前位置，再写旧 progress 等于二次套用进度。
2. `durationFactor: 0` 会让继续动画接近瞬间完成。

Apple 文档说明 `durationFactor` 是原始 duration 的乘数，所以传 `0` 并不适合表达“从当前位置自然继续”。

最终 demo 修正为：复用 paused active animator，必要时设置 `isReversed`，并使用非零 `durationFactor`。

## SwiftUI 对照：没有 UIViewPropertyAnimator，但可以 retarget state

SwiftUI tab 不试图复刻 `UIViewPropertyAnimator`。因为 SwiftUI 的动画模型不同，它通常是：

```swift
withAnimation {
    state = newValue
}
```

状态变了，SwiftUI 负责从旧视觉状态过渡到新视觉状态。

但如果我们想解释“中途再拖不跳变”，就需要知道当前显示进度。demo 用了一个小模型 `ProgressRetargetingModel`：

```swift
struct ProgressRetargetingModel {
    struct Animation {
        let startProgress: CGFloat
        let targetState: AnimationSnapState
        let startTime: TimeInterval
        let duration: TimeInterval
    }
}
```

再通过 `TimelineView(.animation)` 每帧计算当前 displayed progress：

```swift
TimelineView(.animation) { timeline in
    let displayedProgress = displayedProgress(at: timeline.date)
    content(displayedProgress: displayedProgress, phaseText: phaseText(at: timeline.date))
}
```

这样，如果动画还没结束，用户再次开始拖拽，新的拖拽基线不是 endpoint，而是当前屏幕上看到的 progress：

```swift
interactionStartProgress = displayedProgress
activeAnimation = nil
isScrubbing = true
```

这解决了一个常见跳变问题：状态已经被设置到终点，但视觉动画还在半路。如果下一次手势用 endpoint 当起点，卡片就会突然跳。

## 测试覆盖了什么

这个 demo 没有做截图测试，而是测试稳定的行为逻辑。

`AnimationProgressModelTests.swift` 覆盖：

- progress clamp 到 `0...1`
- 向上拖让 collapsed progress 增加
- 向下拖让 expanded progress 减少
- 无效 travel distance 不产生错误进度
- snap threshold 和 velocity 规则

`AnimatorContinuationPlanTests.swift` 覆盖：

- 正向继续时复用 paused animator
- 反向继续时设置 `isReversed`
- `durationFactor` 必须大于 `0`

`ProgressRetargetingModelTests.swift` 覆盖：

- 中途重新拖拽可以从 displayed progress 开始
- expanded 到 collapsed 时局部 fraction 和绝对 progress 能互转
- retarget 动画中途 progress 不会直接跳到 endpoint
- duration 结束后 progress clamp 到目标

这些测试没有验证 UIKit 动画每一帧的视觉效果，但验证了 demo 最容易写错的策略和数学。

## 我对 UIViewPropertyAnimator 的理解变化

这次 demo 让我更清楚地区分了两种动画。

普通 `UIView.animate` 更像 fire-and-forget：

```swift
UIView.animate(withDuration: 0.3) {
    view.alpha = 0
}
```

它适合按钮点击后的简单过渡、列表 cell 出现、toast fade out 等场景。

`UIViewPropertyAnimator` 更适合用户参与的动画：

- bottom sheet
- card expansion
- interactive dismiss
- custom transition
- 手势驱动的面板展开/收起

它的价值不是“写法更高级”，而是动画有了可控制的生命周期和进度。

## 关键结论

1. `UIViewPropertyAnimator` 是 UIKit 里解释可打断动画最直接的 API。
2. `fractionComplete` 只有在 paused animator 上最有意义，适合绑定手势进度。
3. `isReversed` 可以让同一个 animator 掉头，而不是重新创建动画。
4. `continueAnimation(withTimingParameters:durationFactor:)` 应该用于 paused active animator；`durationFactor` 不是剩余比例，而是原始 duration 的乘数。
5. SwiftUI 没有同等的 animator 控制面，更多是通过改变 state 来 retarget 动画。
6. 如果要避免 SwiftUI 中途再拖跳变，需要明确当前 displayed progress，而不是只看最终 state。

## 如何运行 demo

```bash
cd interruptible-animation-demo
xcodegen generate
open InterruptibleAnimationDemo.xcodeproj
```

测试可以用 XcodeBuildMCP 或 Xcode 的 test action。当前 demo 的核心逻辑有单元测试覆盖，最终验证结果是 15 个测试通过。

## 可继续补充

后续可以加一张 simulator 截图或短视频，展示：

- UIKit tab 拖到一半松手继续。
- 拖到一半反向回弹。
- SwiftUI tab 在动画途中重新拖拽不会跳变。

这样博客读者会更直观地理解“可打断”到底发生在哪里。
