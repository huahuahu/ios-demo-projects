---
title: 用 UIKit 实现 Telegram 风格的页面最小化 Dock
description: 从根容器、页面快照、CATransform3D 卡片栈到 iOS 26 Liquid Glass，拆解一个可复现的 UIKit Demo。
summary: 用 UIKit 重新实现 Telegram 风格的文件最小化、底部停靠、多卡片透视展开与页面恢复机制。
category: Investigation
tag: UIKit
date: 2026-08-16
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/telegram-mini-dock-demo
---

## 想复现的到底是什么

Telegram iOS 中有一种很特别的页面最小化交互：正在浏览的文件可以缩到底部，停靠在标签栏下方；继续最小化其他文件后，点击 Dock 又会展开成一组带透视感的卡片。选中某张卡片，页面再从卡片恢复为全屏。

一开始很容易把它理解成一种特别的 Tab，或者把它塞进当前页面的 `UINavigationController`。但观察完整交互后会发现，App 仍然按标签组织，Dock 只是覆盖在主导航之上的临时工作区：切换到其他 Tab，已经最小化的文件仍然存在；恢复文件时，恢复的也是原来的页面，而不是重新打开一个同名页面。

因此，这个 Demo 最重要的学习目标并不是做一个好看的底栏，而是回答三个问题：

- 谁拥有标签栏、全屏文件页和最小化文件？
- 动画中的卡片与真实页面分别负责什么？
- 多张卡片怎样产生类似 Telegram 的纵深与堆叠感？

Demo 使用标准 UIKit 独立实现这套机制，并使用 iOS 26 的原生 Liquid Glass API。它参考 Telegram 的公开交互与源码思路，但没有复制 Telegram 的自有导航、AsyncDisplayKit 或 ComponentFlow 基础设施，因此更适合单独学习容器与动画。

## 最终效果

没有最小化页面时，底部只有正常的 `UITabBarController`。一旦文件被最小化，主 Tab 内容会向上让出空间，底部出现一个新的停靠区域。

![三个文件收起在标签栏下方]({{ '/telegram-mini-dock-demo/assets/collapsed-dock.jpg' | relative_url }})

一个文件时，点击 Dock 直接恢复；两个或更多文件时，点击 Dock 会先展开卡片栈。每张卡片仍然保留自己的标题、图标和内容快照。

![三个文件展开为 3D 透视卡片栈]({{ '/telegram-mini-dock-demo/assets/expanded-card-stack.jpg' | relative_url }})

展开后可以纵向浏览，点击卡片恢复页面，点击背景收起。代码也实现了左滑关闭单张卡片，不过本文的自动化验证范围只覆盖了最小化、展开和恢复，没有把横滑关闭列为已验证结果。

## 关键判断：Dock 属于 App Shell

根控制器 `DemoRootViewController` 同时拥有三个展示节点：

1. `DemoTabBarController`：App 原本的顶层导航。
2. `DocumentViewController`：当前全屏显示的文件页，一次最多一个。
3. `MinimizedContainerViewController`：跨 Tab 存活的最小化文件集合。

```swift
final class DemoRootViewController: UIViewController {
    private let mainTabController = DemoTabBarController()
    private let minimizedContainer = MinimizedContainerViewController()
    private var activeDocumentController: DocumentViewController?
}
```

这个所有权关系决定了整个实现。如果把 Dock 放在某个 Tab 内，它会随着 Tab 的切换一起消失；如果把最小化状态放进 Router，Router 就同时承担了“要去哪个页面”和“某个页面现在以什么形态展示”两种职责。

在这个 Demo 中，Router 或 Tab 仍只回答导航问题。最小化属于 App Shell 的 presentation state，由根容器统一协调。这也是 Dock 能跨 Tab 保留的原因。

当 Dock 出现时，根容器不会覆盖系统 Tab Bar，而是缩短 `UITabBarController` 的 frame，在其下方留出一个独立区域：

```swift
let dockHeight = minimizedContainer.items.isEmpty
    ? 0
    : MiniDockLayout.collapsedHeight(
        safeAreaBottom: view.safeAreaInsets.bottom
      )

mainTabController.view.frame.size.height =
    view.bounds.height - dockHeight - gap
```

收起高度由标题条、安全区和上下间距共同组成：

```swift
static func collapsedHeight(safeAreaBottom: CGFloat) -> CGFloat {
    navigationHeight + topMargin + safeAreaBottom + 3
}
```

这里 `navigationHeight` 是 56 pt。把底部安全区算进去后，Dock 在不同 Home Indicator 环境下仍能贴住屏幕底部。

## 动画使用 snapshot，恢复使用真实 ViewController

最小化时，如果直接缩放真实 `DocumentViewController.view`，动画、容器关系和触摸处理会纠缠在一起。这个 Demo 把职责分成两层：

- snapshot 只负责运动和展示；
- 真实 `ViewController` 负责保存页面状态，并在恢复后继续交互。

流程如下：

1. 文件页生成当前内容的 snapshot。
2. Dock 用 snapshot 创建一个全屏大小的 `MiniDockCardView`。
3. 真实文件控制器从父控制器移除，但继续被 `MiniDockItem` 强引用。
4. snapshot 用 0.4 秒 spring 动画移到屏幕底部，只露出标题条。

```swift
func addMinimizedController(
    _ controller: MinimizableViewController
) -> Bool {
    guard let snapshot = controller.makeMinimizedSnapshotView()
    else { return false }

    let item = MiniDockItem(
        controller: controller,
        snapshotView: snapshot
    )
    // 创建卡片并加入 Dock……
    return true
}
```

这里有一个实际踩过的坑：如果 snapshot 包含整个页面，卡片自己的玻璃标题条上方还会再出现一份原页面标题，形成重复 header。最终实现只截取 `textView` 内容区域，让 `MiniDockCardView` 统一绘制标题条：

```swift
func makeMinimizedSnapshotView() -> UIView? {
    textView.snapshotView(afterScreenUpdates: true)
}
```

恢复时顺序刚好反过来。根容器先把保留的真实控制器插回 Dock 下方，再把 snapshot 动画到全屏。动画结束后移除 snapshot，并恢复真实页面的交互。因为真实页面已经提前铺在卡片后面，所以切换瞬间不会闪出白屏。

## 收起状态其实也是一个栈

收起时，最上面的卡片显示组合标题，例如“三个文件中的最新文件及其他 2 个”。下面的卡片略微缩小，并通过 `zPosition` 排在后方，让用户在未展开前就能感知这里不止一个页面。

```swift
if isTop {
    transform = CATransform3DIdentity
    card.layer.zPosition = 10_000
} else {
    let scale = (size.width - 20) / size.width
    transform = CATransform3DMakeScale(scale, scale, 1)
    card.layer.zPosition = CGFloat(index)
}
```

收起状态还需要特殊的事件穿透。`MinimizedContainerViewController` 的 view 始终覆盖全屏，以便展开时承载背景和滚动视图；但收起时如果它继续拦截所有触摸，下面的 Tab 就无法操作。

Demo 使用一个自定义 `DockPassthroughView`：收起时只有 Dock 的矩形区域参与 hit testing，其他位置返回 `nil`，事件自然落到下面的 Tab 页面；展开时再切换为捕获全屏触摸。

## 展开不是简单的缩放，而是围绕隐形圆柱旋转

多卡片展开的质感主要来自 `CATransform3D`。如果只做 `scale` 加 Y 轴错位，得到的是平面卡片列表；Telegram 风格的卡片更像沿着一个看不见的圆柱排布，越靠下，倾斜角度越大。

第一步是设置透视项：

```swift
var transform = CATransform3DIdentity
transform.m34 = -1 / 1_000
```

然后根据卡片在屏幕中的 Y 坐标计算 X 轴旋转角度，再同时沿 Y、Z 轴平移：

```swift
let radius = cardHeight / 2 + abs(zOffset / sin(angle))
let zTranslation = radius * sin(angle)
let yTranslation = radius * (1 - cos(angle))

transform = CATransform3DTranslate(
    transform,
    0,
    -yTranslation,
    zTranslation
)
transform = CATransform3DRotate(transform, angle, 1, 0, 0)
```

这组公式的直觉是：先选择一个虚拟旋转半径，再根据角度计算圆周上的 Y/Z 位移。卡片因此不是原地翻转，而是旋转的同时向屏幕深处移动。

卡片之间的纵向间距按最多五张计算：

```swift
let fitted = availableHeight / CGFloat(min(itemCount, 5))
return min(maximumInteritemSpacing, fitted)
```

少量卡片不会散得太开，卡片很多时也不会因为间距持续缩小而完全挤在一起。滚动过程中，布局会用卡片当前的屏幕 Y 坐标重新计算角度，所以卡片经过视口时会连续改变透视，而不是带着固定角度上下平移。

还有一个测试层面的细节：旋转和位移经过矩阵乘法后，最终矩阵里的 `m34` 不一定仍精确等于最初写入的 `-1 / 1000`。测试应该验证透视方向、数量级以及矩阵不是 identity，而不是把整个 `CATransform3D` 当成可直接 `Equatable` 比较的值。

## 把交互看成状态机

虽然代码里的持久展示状态只有 `collapsed` 和 `expanded`，动画期间还存在四类短暂过程：

- minimizing：真实页面退出，snapshot 向 Dock 收起；
- expanding / collapsing：Dock 与卡片栈之间切换；
- maximizing：snapshot 恢复全屏，真实页面回到容器；
- dismissing：某张卡片横向离场并从集合移除。

`transitionInProgress` 用来阻止这些动画重入。否则用户在 spring 尚未结束时再次点击、滚动或拖动，容器集合和卡片 frame 很容易进入不一致状态。

手势之间也要明确分工：

- 收起状态的向上纵向 pan 用于展开；
- 展开状态的 Scroll View 处理纵向浏览；
- 卡片自己的横向 pan 用于关闭；
- 点击卡片用于展开或恢复；
- 点击背景用于收起。

横向关闭还会对向右拖动增加阻尼，只让向左滑动保持一比一跟手。结束时根据位移是否超过屏宽三分之一，或速度是否小于 `-300 pt/s`，决定关闭还是 spring 回原位。

## UIKit 中的 Liquid Glass

Demo 的最低系统版本是 iOS 26，因此直接使用原生 `UIGlassEffect`：

```swift
let effect = UIGlassEffect(style: .regular)
effect.isInteractive = true

let effectView = UIVisualEffectView(effect: effect)
effectView.layer.cornerCurve = .continuous
```

实现时有两条重要规则：

1. 标题、按钮等子视图必须加入 `UIVisualEffectView.contentView`，而不是直接加到 effect view。
2. 不通过修改 `UIVisualEffectView.alpha` 来淡出玻璃。展开背景的 dim 使用独立 UIView，blur 则通过设置或清空 `effect` 来动画。

文件页的关闭与最小化按钮使用 `UIButton.Configuration.glass()`。系统 `UITabBarController` 则保留系统外观，让 iOS 26 自己提供匹配的 Tab Bar 玻璃效果。

这里的“像 Telegram”主要来自正确的层级、运动和状态切换。Liquid Glass 负责材质，但材质本身不能替代容器设计，也不能把一个普通的平面卡片列表自动变成 Telegram 的交互。

## 实现过程中遇到的工程问题

除了重复 snapshot header，还遇到了几类 UIKit 与 Swift 6 细节：

- 自定义属性不能随意命名为 `tabBarController`，它会与 `UIViewController` 已有属性冲突，因此根容器中改用 `mainTabController`。
- `GlassFactory` 创建 UIKit 对象，需要明确运行在 `@MainActor` 上，避免 Swift 6 隔离检查报错。
- `CATransform3D` 不能直接依赖 `Equatable` 做整体断言，应测试可观察的矩阵性质。
- 动画期间的 snapshot 与真实控制器必须有清楚的所有权，否则恢复后容易丢失原页面滚动位置或重复创建页面。

这些问题都指向同一件事：这个效果的难点不是某一个动画参数，而是 presentation state、控制器生命周期、手势和图层变换必须保持一致。

## 验证结果与边界

本次 Demo 在专用 `iPhone 17 Pro Max`、iOS 26.5 Simulator 上完成验证：

- XcodeBuildMCP build and run 成功，零 warning、零 error；
- 8 个单元测试全部通过；
- 自动化操作验证了打开文件、连续最小化多个文件、展开 3D 卡片栈，以及点击卡片恢复真实 ViewController；
- 左滑关闭已有实现，但未纳入本次自动化验证结论。

单元测试集中在不依赖动画时序的纯逻辑上，包括收起高度、卡片间距、角度变化、透视矩阵特征和多文件标题格式。容器切换与 spring 动画则通过 Simulator 实际交互验证。

## 我学到的核心结论

第一，App 的主结构仍然是 Tab，Mini Dock 是根容器管理的全局展示状态。把它放进某个 Tab 或 Router，都会模糊所有权。

第二，snapshot 和真实页面不能混为一谈。snapshot 负责平滑地从全屏变成卡片，真实 ViewController 负责保存页面身份与交互状态。

第三，Telegram 风格的“堆叠感”不是简单缩放。`m34`、X 轴旋转、Y/Z 位移和基于屏幕位置的连续重算，共同建立了类似隐形圆柱的空间关系。

最后，Liquid Glass 是材质层，不是架构层。先建立正确的容器、状态机和动画，再使用 `UIGlassEffect`，效果才会自然地融入系统界面。

完整 Demo 位于 `telegram-mini-dock-demo`。可以依次最小化三个示例文件，再切换 Tab、展开卡片并恢复页面，观察根容器的三个展示节点如何协作。
