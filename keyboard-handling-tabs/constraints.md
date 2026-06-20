composerContainer: 带有聊天框和聊天框上面的工具栏
attachmentPanel: 点击附件按钮之后的 view
keyboardLayoutGuide: 系统键盘顶部的布局参考

# 核心原则

attachmentPanel 是 app-owned view，固定在 view 底部，位于 tab bar/keyboard 后方。
系统键盘不是 attachmentPanel 的一部分，而是覆盖在 app 内容上方。

视觉效果来自两件事：

1. 键盘下滑时，露出底下已经存在的 attachmentPanel。
2. 键盘上滑时，覆盖底下仍然存在的 attachmentPanel。

composerContainer 只负责贴住当前 active surface 的顶部。

重要：`attachmentPanel visible` 不等于 `attachmentPanel 是 active surface`。
点击输入框之后，attachmentPanel 会短暂保持 visible，但 active surface 已经切换成 keyboard。

也就是说：

- attachment active 时：`attachmentPanel.top == composerContainer.bottom`
- keyboard active 时：`composerContainer.bottom == view.keyboardLayoutGuide.top`
- idle 时：`composerContainer.bottom == view.safeAreaLayoutGuide.bottom`

`attachmentPanel` 自己始终固定在底部：

- `attachmentPanel.bottom == view.bottomAnchor`
- `attachmentPanel.height == 最近一次键盘高度，至少 180`

# Stable states

## idle

没有键盘，也没有 attachmentPanel。

attachmentPanel:
- top = composerContainer.bottom
- height = 最近一次键盘高度，至少 180
- hidden = true
- alpha = 0

composerContainer:
- bottom = view.bottomAnchor

active surface:
- none / bottom safe area

## keyboard

输入框 focus，系统键盘显示。

attachmentPanel:
- bottom = view.bottomAnchor
- hidden = true
- alpha = 0

composerContainer:
- bottom = view.keyboardLayoutGuide.top

active surface:
- keyboard

## attachment

输入框失焦，attachmentPanel 显示。

attachmentPanel:
- bottom = view.bottomAnchor
- height = 最近一次键盘高度，至少 180
- hidden = false
- alpha = 1

composerContainer:
- bottom = attachmentPanel.top

等价写法：
- attachmentPanel.top = composerContainer.bottom

active surface:
- attachmentPanel

# Transition states

## idle -> keyboard：点击输入框

目标效果：没有 attachmentPanel 参与时，输入框获得焦点，composer 直接跟随系统键盘顶部上移。

开始:
- active surface = keyboard
- attachmentPanel.hidden = true
- attachmentPanel.alpha = 0
- composerContainer.bottom = view.keyboardLayoutGuide.top

动画期间:
- 系统键盘上滑
- composerContainer 跟随 view.keyboardLayoutGuide.top

完成后进入:
- keyboard

## idle -> attachment：点击附件按钮

目标效果：没有系统键盘动画时，attachmentPanel 作为一个固定高度的整体从底部上移，composer 跟随 attachmentPanel.top 上移。

开始前：
- attachmentPanel.height = 最近一次键盘高度，至少 180
- attachmentPanel.bottom = view.bottomAnchor + attachmentPanel.height
- attachmentPanel.hidden = false
- attachmentPanel.alpha = 1
- composerContainer.bottom = attachmentPanel.top

动画期间：
- attachmentPanel.height 保持不变
- attachmentPanel.bottom 从 `view.bottomAnchor + attachmentPanel.height` 渐变到 `view.bottomAnchor`
- attachmentPanel 内部内容不被拉伸，整块 view 向上移动
- composerContainer 因为贴着 attachmentPanel.top，会同步向上移动

完成后进入：
- attachment

## keyboard -> attachment：点击附件按钮

目标效果：键盘向下滑，露出底部的 attachmentPanel。

先准备 attachmentPanel:
- bottom = view.bottomAnchor
- height = 最近一次键盘高度，至少 180
- hidden = false
- alpha = 1

然后切换 composer 到过渡布局：
- composerContainer.bottom 取 attachmentPanel.top 和 view.keyboardLayoutGuide.top 中更靠上的那个 surface
- 用 bottom inset 理解就是：composer 底部占用高度 = max(attachmentPanel 高度, keyboard 高度)

最后让输入框失焦:
- draftTextField.resignFirstResponder()

动画期间:
- 系统键盘向下滑出
- attachmentPanel 因为固定在底部，被键盘逐渐露出
- composerContainer 不能低于 attachmentPanel.top，也不能低于 keyboardLayoutGuide.top；两者同时约束，再用低优先级 pull-down 让它停在允许范围内最低的位置

keyboardDidHide 之后：
- composerContainer.bottom = attachmentPanel.top

等价写法：
- attachmentPanel.top = composerContainer.bottom

完成后进入:
- attachment

## attachment -> keyboard：点击输入框

目标效果：键盘向上滑，覆盖底部仍然存在的 attachmentPanel。

关键点：不要立刻隐藏 attachmentPanel。

先切换 active surface:
- active surface = keyboard
- composerContainer.bottom 取 attachmentPanel.top 和 view.keyboardLayoutGuide.top 中更靠上的那个 surface
- 用 bottom inset 理解就是：composer 底部占用高度 = max(attachmentPanel 高度, keyboard 高度)

然后让输入框 focus:
- draftTextField.becomeFirstResponder()

动画期间:
- attachmentPanel 仍然 visible
- attachmentPanel.bottom = view.bottomAnchor
- 系统键盘从下往上覆盖 attachmentPanel
- composerContainer 不能低于 attachmentPanel.top，也不能低于 keyboardLayoutGuide.top；两者同时约束，再用低优先级 pull-down 让它停在允许范围内最低的位置

keyboardDidShow 之后:
- attachmentPanel.hidden = true
- attachmentPanel.alpha = 0

完成后进入:
- keyboard

## keyboard -> idle：点击 Dismiss

目标效果：键盘向下滑，composer 跟随键盘顶部，键盘完全消失后 composer 回到底部。

开始:
- view.endEditing(true)
- active surface = keyboard dismissing

动画期间:
- composerContainer.bottom = view.keyboardLayoutGuide.top

keyboardDidHide 之后:
- composerContainer.bottom = view.bottomAnchor

完成后进入:
- idle

## attachment -> idle：点击 Dismiss

目标效果：attachmentPanel 作为一个整体慢慢下移，composer 跟随 attachmentPanel.top 下移。

开始前：
- attachmentPanel.height = 最近一次键盘高度，至少 180
- attachmentPanel.bottom = view.bottomAnchor
- composerContainer.bottom = attachmentPanel.top

动画期间：
- attachmentPanel.height 保持不变
- attachmentPanel.bottom 从 `view.bottomAnchor` 渐变到 `view.bottomAnchor + attachmentPanel.height`
- attachmentPanel 内部内容不被拉伸，整块 view 向下移动
- composerContainer 因为贴着 attachmentPanel.top，会同步向下移动

动画结束后：
- attachmentPanel.hidden = true
- attachmentPanel.alpha = 0
- attachmentPanel.bottom 重置为 view.bottomAnchor，方便下次进入
- composerContainer.bottom = view.safeAreaLayoutGuide.bottom

完成后进入:
- idle

# Pending 边界情况

这些情况发生在 `attachment -> keyboard` 的键盘上滑动画期间。
此时 attachmentPanel 仍然 visible，但 active surface 已经是 keyboard。

## pending 期间又点击附件按钮

含义：用户取消“键盘覆盖 panel”，重新回到 attachment。

应该做:
- 取消 keyboard presentation pending
- attachmentPanel 保持 hidden = false, alpha = 1
- composerContainer.bottom = attachmentPanel.top
- draftTextField.resignFirstResponder()

不应该做:
- 因为 attachmentPanel visible 就忽略附件按钮
- 让后续 stale keyboardDidShow 隐藏 attachmentPanel

完成后进入:
- attachment

## pending 期间点击 Dismiss

含义：用户不想要 keyboard，也不想要 attachmentPanel。

应该做:
- 取消 keyboard presentation pending
- 隐藏 attachmentPanel
- draftTextField.resignFirstResponder() 或 view.endEditing(true)
- composerContainer 先继续跟随 view.keyboardLayoutGuide.top
- keyboardDidHide 后再切到 view.safeAreaLayoutGuide.bottom

不应该做:
- 只隐藏 attachmentPanel，但让键盘继续显示
- 在键盘还可见时立刻把 composerContainer 切到底部

完成后进入:
- idle

## pending 期间点击 attachment source

含义：用户在键盘覆盖 panel 前选择了附件来源。

应该做:
- 插入 attachment token
- 隐藏 attachmentPanel
- 保持 active surface = keyboard
- composerContainer.bottom = view.keyboardLayoutGuide.top
- 后续 stale keyboardDidShow 不应该把 composerContainer 切到底部

不应该做:
- 因为隐藏 attachmentPanel 就把 composerContainer 切到 safe area bottom

完成后进入:
- keyboard

## attachment -> attachment：重复点击附件按钮

目标效果：已经在 attachment active 时，再点附件按钮不应该重新播放动画。

应该做：
- 保持 attachmentPanel.hidden = false
- 保持 attachmentPanel.bottom = view.bottomAnchor
- 保持 composerContainer.bottom = attachmentPanel.top
- 直接 return

不应该做：
- 重新从底部滑入
- 重置高度或 alpha
