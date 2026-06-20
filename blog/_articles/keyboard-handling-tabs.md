---
title: 用 UIKit 做一个像微信一样露出的附件面板
description: 记录 keyboard-handling-tabs demo 中从输入框键盘切到附件面板时，如何用 app-owned panel、UIKeyboardLayoutGuide 和约束状态机做出自然的覆盖与露出动画。
summary: 一次 UIKit 键盘交互实验：不用 custom inputView，而是让系统键盘覆盖 app-owned attachmentPanel，再用约束状态机处理 keyboard、attachment 和 idle 之间的过渡。
category: Investigation
tag: UIKit Keyboard
date: 2026-06-20
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/keyboard-handling-tabs
---

## 想解决的问题

聊天输入框里常见一个交互：光标在输入框里时，底部是系统键盘；点击附件按钮后，输入框失焦，键盘向下收起，底下的附件面板慢慢露出来。微信、豆包这类 app 里的切换很自然，不像是两个 view 突然互换。

`keyboard-handling-tabs` 这个 demo 一开始尝试过把附件面板当成类似 keyboard 的输入面板来处理。但在 UIKit 里，这条路很容易变成“切换 input surface”：系统键盘消失、附件 view 出现，视觉上就会生硬。这个实验最后采用了另一种模型：附件面板是 app 自己拥有的 view，系统键盘只是覆盖在它上面。

这篇记录的是这次实现中真正有用的理解：不要把 attachment panel 想成键盘的替代品，而要把它想成一个在底部等待被键盘遮住或露出的 surface。

## 效果对比

下面两个视频分别是 SwiftUI tab 和 UIKit tab 的当前效果。SwiftUI 版本保留为对照；UIKit 版本是这篇文章主要讨论的实现，它把附件面板作为 app-owned view 放在底部，让系统键盘负责覆盖和露出它。

<figure>
  <video controls playsinline muted preload="metadata" style="width: 100%; border-radius: 12px;">
    <source src="{{ '/keyboard-handling-tabs/assets/swiftui.mp4' | relative_url }}" type="video/mp4">
  </video>
  <figcaption>SwiftUI tab：作为对照的键盘/附件切换效果。</figcaption>
</figure>

<figure>
  <video controls playsinline muted preload="metadata" style="width: 100%; border-radius: 12px;">
    <source src="{{ '/keyboard-handling-tabs/assets/uikit.mp4' | relative_url }}" type="video/mp4">
  </video>
  <figcaption>UIKit tab：键盘下滑露出 attachmentPanel，键盘上滑覆盖 attachmentPanel。</figcaption>
</figure>

## 最小背景：三个 surface

demo 里的 UIKit 页面主要有三个相关对象：

- `composerContainer`：聊天输入区，包含工具栏、输入框和发送按钮。
- `attachmentPanel`：点击附件按钮后出现的面板。
- `view.keyboardLayoutGuide`：系统键盘顶部的 Auto Layout 参考。

核心约束不是“键盘和附件面板互相替代”，而是：

```text
keyboard active:
composerContainer.bottom == view.keyboardLayoutGuide.top

attachment active:
composerContainer.bottom == attachmentPanel.top

idle:
composerContainer.bottom == view.safeAreaLayoutGuide.bottom
```

对应代码在 `keyboard-handling-tabs/KeyboardHandlingTabs/UIKitKeyboardViewController.swift`。`attachmentPanel` 被抽成了独立的 `AttachmentPanelView`，这样动画时可以把整个 panel 当成一个固定高度的整体移动，而不是拉伸内部内容。

## 为什么 attachmentPanel 要贴 `view.bottomAnchor`

这个 demo 后来迁到了完整 UIKit 架构：root 是 `UITabBarController`，UIKit demo 是其中一个 tab。这里有一个容易踩坑的点：如果把 `attachmentPanel.bottom` 贴到 child view controller 的 `safeAreaLayoutGuide.bottom`，在 tab bar 场景下它会停在 tab bar 顶部。

但我们想要的是：附件面板位于 tab bar 和系统键盘后方，键盘下滑时它从底部被露出。所以实现里让 panel 贴住根 view 的底部：

```swift
let panelBottomConstraint = attachmentPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
let panelHeightConstraint = attachmentPanel.heightAnchor.constraint(equalToConstant: lastVisibleKeyboardHeight)
```

这样 attachment panel 的模型更接近系统键盘：它占据屏幕底部区域，可以被键盘覆盖，也可以在键盘离开时露出来。

## 状态机比布尔值更重要

最初只看 `attachmentPanel.isHidden` 很容易写错，因为“panel 可见”不等于“当前 active surface 是 panel”。

例如从 attachment 切回 keyboard 时，用户点击输入框，系统键盘开始上滑。在键盘完全覆盖 panel 之前，`attachmentPanel` 仍然应该可见；但 active surface 已经应该切到 keyboard 了。否则 composer 会贴错位置，或者在 pending 状态下被错误地拉到底部。

最终实现里用了一个显式状态：

```swift
private enum InputSurfaceState {
    case idle
    case keyboard
    case attachment
    case attachmentRevealingBehindKeyboard
    case keyboardPresentingOverAttachment
    case keyboardDismissing
}
```

它让每个过渡都有名字：

- `idle -> keyboard`：输入框从空闲状态获得焦点，composer 直接跟随 `keyboardLayoutGuide` 上移。
- `keyboard -> idle`：composer 跟随 keyboardLayoutGuide，键盘完全消失后再回到底部。
- `idle -> attachment`：没有系统键盘动画，要自己把 panel 从底部滑上来。
- `attachment -> idle`：panel 作为整体向下滑走。
- `keyboard -> attachment`：键盘下滑，露出下面的 panel。
- `attachment -> keyboard`：键盘上滑，覆盖下面的 panel。

这个拆分让后续修 bug 时更清晰：如果问题发生在 pending 阶段，就不要拿 stable state 的规则硬套。

## 关键过渡一：keyboard -> attachment

点击附件按钮时，如果输入框正在 focus，第一件事不是立刻隐藏键盘区域，而是先把 attachment panel 放到键盘后面：

```swift
private func showAttachmentPanelAtKeyboardHeight() {
    attachmentPanelHeightConstraint?.constant = targetAttachmentPanelHeight
    attachmentPanelBottomConstraint?.constant = 0
    attachmentPanel.isHidden = false
    attachmentPanel.alpha = 1
}
```

然后切换 composer 的布局，让它同时避开键盘和 panel：

```swift
inputSurfaceState = .attachmentRevealingBehindKeyboard
pinComposerAboveKeyboardAndAttachmentPanel()
view.layoutIfNeeded()
draftTextField.resignFirstResponder()
```

真正的动画来自系统键盘下滑。因为 `attachmentPanel` 已经在底部，键盘下降时就像揭开盖子一样把 panel 露出来。

## 关键过渡二：attachment -> keyboard

反方向也一样。点击输入框时，不要立刻隐藏 `attachmentPanel`。它应该继续留在底部，等键盘上滑覆盖它。

`UITextFieldDelegate` 里做的事情是先切状态，再让系统键盘接管动画：

```swift
func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if attachmentPanelIsVisible {
        inputSurfaceState = .keyboardPresentingOverAttachment
        pinComposerAboveKeyboardAndAttachmentPanel()
        return true
    } else {
        inputSurfaceState = .keyboard
    }
    pinComposerToKeyboard()
    return true
}
```

等 `keyboardDidShow` 到来后，说明键盘已经覆盖完成，这时才隐藏 attachment panel：

```swift
private func keyboardDidShow(_ notification: Notification) {
    guard inputSurfaceState == .keyboardPresentingOverAttachment else {
        return
    }
    inputSurfaceState = .keyboard
    hideAttachmentPanelWithoutMovingComposer()
}
```

这个时机很重要。如果提前隐藏，用户看到的是 panel 消失；如果等键盘覆盖完成后隐藏，用户看到的是键盘自然盖上来。

## 过渡时 composer 为什么要取“更高的 surface”

在 `keyboard -> attachment` 和 `attachment -> keyboard` 过程中，keyboard 和 attachment panel 会同时存在。composer 不能只贴 keyboard，也不能只贴 panel，而应该停在两者中更靠上的那个 surface 上方。

实现里没有手动算 frame，而是用三条约束表达：

```swift
let composerAboveKeyboardConstraint =
    composerContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor)

let composerAbovePanelConstraint =
    composerContainer.bottomAnchor.constraint(lessThanOrEqualTo: attachmentPanel.topAnchor)

let composerPullDownConstraint =
    composerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
composerPullDownConstraint.priority = .defaultLow
```

前两个是 required 上界：composer 不能低于 keyboard top，也不能低于 panel top。第三个是低优先级 pull-down：在不违反前两个硬约束的前提下，尽量把 composer 往下拉。

Auto Layout 会先满足 required 约束，再尽量满足低优先级等式，所以最后得到的效果就是：

```text
composer.bottom = min(keyboard.top, attachmentPanel.top)
```

如果换成底部 inset 来理解，就是 composer 避让高度取两者的最大值：

```text
bottomInset = max(keyboardHeight, attachmentPanelHeight)
```

这个约束组合是整个动画不“跳”的关键。它让 composer 在两个 surface 交叠时仍然有连续的位置。

## idle -> attachment：不要拉伸 panel，要整体上移

如果当前没有键盘，点击附件按钮就没有系统键盘动画可借。最自然的做法是让 app 自己把 panel 从底部滑上来。

一个容易犯的错是把 height 从 `0` 动画到目标高度。这样看起来像 panel 内容被压缩再拉开，内部按钮和文字会出现怪异截图。正确做法是固定高度，只动 bottom constraint：

```swift
private func slideAttachmentPanelUpFromBottom() {
    attachmentPanelHeightConstraint?.constant = targetAttachmentPanelHeight
    attachmentPanelBottomConstraint?.constant = targetAttachmentPanelHeight
    attachmentPanel.isHidden = false
    attachmentPanel.alpha = 1
    pinComposerToAttachmentPanel()
    view.layoutIfNeeded()

    attachmentPanelBottomConstraint?.constant = 0
    UIView.animate(
        withDuration: 0.25,
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState],
        animations: {
            self.view.layoutIfNeeded()
        }
    )
}
```

这里的 `attachmentPanel.bottom = view.bottom + panelHeight` 表示整个 panel 先在屏幕下方。动画把 bottom constant 改回 `0`，于是 panel 作为一个完整 view 向上移动，内部内容不变形。

## attachment -> idle：反向整体下移

点击 Dismiss 时也不能只 `alpha = 0`。如果 panel 瞬间隐藏，用户会感觉 surface 被抽走。现在的处理是反向移动：composer 继续贴着 panel top，panel 下移时 composer 跟着下移，动画结束后再切回 idle。

```swift
private func slideAttachmentPanelDownToIdle() {
    inputSurfaceState = .idle
    attachmentPanelHeightConstraint?.constant = targetAttachmentPanelHeight
    attachmentPanelBottomConstraint?.constant = 0
    pinComposerToAttachmentPanel()
    view.layoutIfNeeded()

    attachmentPanelBottomConstraint?.constant = targetAttachmentPanelHeight
    UIView.animate(
        withDuration: 0.25,
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState],
        animations: {
            self.view.layoutIfNeeded()
        },
        completion: { _ in
            self.attachmentPanel.alpha = 0
            self.attachmentPanel.isHidden = true
            self.attachmentPanelBottomConstraint?.constant = 0
            self.pinComposerToBottom()
            self.view.layoutIfNeeded()
        }
    )
}
```

这里还有一个小细节：如果已经在 attachment active，再点附件按钮，不应该重新播放滑入动画。代码里直接在 `.attachment` 状态 return：

```swift
if inputSurfaceState == .attachment {
    return
}
```

这类小边界如果不处理，用户连续点击按钮时就会看到 panel 抽动。

## 为什么把 AttachmentPanel 封成一个 view class

`AttachmentPanelView` 不是为了复用而抽象，而是为了让动画对象更清楚。

当 panel 的 title、divider、按钮 stack 都散落在 view controller 里时，很容易在调动画时误改内部约束，比如动高度、改 alpha、临时隐藏某个 stack。抽成独立 view 后，controller 只关心这三件事：

1. panel 是否 hidden。
2. panel 的 height。
3. panel 的 bottom constraint。

内部内容由 `AttachmentPanelView` 自己管理：

```swift
final class AttachmentPanelView: UIView {
    var selectSource: ((AttachmentSource) -> Void)?
    ...
}
```

这样 `idle -> attachment` 和 `attachment -> idle` 都可以把整个 panel 作为一个整体移动，减少“内容被拉伸”的视觉问题。

## 测试覆盖了哪些交互

这个 demo 不是只靠手动看动画。`UIKitKeyboardViewControllerAttachmentInputTests.swift` 里对几个容易回归的点做了约束级测试：

- 点击附件按钮时，输入框会失焦，panel 会显示。
- `keyboard -> attachment` 期间，composer 使用 “above keyboard + above panel + pull-down” 组合约束。
- `keyboardDidHide` 后，composer 稳定贴到 `attachmentPanel.top`。
- `attachment -> keyboard` 期间，panel 会保持可见直到 `keyboardDidShow`。
- `attachment -> idle` 时，panel bottom constant 会变成正数，表示整块 panel 正在下移。
- `attachment -> attachment` 不会重新触发滑入动画。

这些测试有一个经验：不要过度依赖真实 first responder 和系统键盘时序。对状态机和约束来说，直接触发 delegate 或通知，往往比等待真实键盘动画更稳定。

## 这次实验后的理解变化

这次最重要的收获不是某一条 API，而是对底部输入区的建模方式变了。

以前容易把问题理解成：“点击附件按钮时，把键盘换成 attachment view。”这种模型会让交互看起来像两个输入法切换。

更自然的模型是：“attachment panel 一直是 app 内容的一部分，系统键盘负责覆盖或露出它。”这样一来：

- 键盘下滑露出 panel，是系统键盘动画 + 已存在 panel 的组合。
- 键盘上滑覆盖 panel，是系统键盘动画 + 延迟隐藏 panel 的组合。
- 没有键盘参与时，app 自己移动整个 panel，而不是拉伸 panel 高度。
- composer 不是跟某个布尔值走，而是跟当前 active surface 走。

如果以后要继续做聊天输入区，我会优先从这个模型开始：先列 stable states，再列 transition states，最后再写约束指令。这样比一边响应按钮、一边临时改约束更不容易失控。

## 可以继续补充的实验

后续还可以加两类观察：

- 继续补充更细分的过渡视频，例如只录 `keyboard -> attachment` 或只录 `attachment -> keyboard`，让读者能逐段对照状态机。
- 继续验证 split keyboard、hardware keyboard、undocked keyboard 场景下 `UIKeyboardLayoutGuide` 的表现，看看 `followsUndockedKeyboard = true` 是否还符合这个 surface 模型。
