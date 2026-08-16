# UIKit Mini Dock Architecture

## 所有权

`DemoRootViewController` 是唯一的 App Shell。它拥有三个互相独立的展示节点：

1. `DemoTabBarController`：App 的常规顶层导航。
2. `DocumentViewController`：当前全屏文件，一次最多一个。
3. `MinimizedContainerViewController`：跨 Tab 存活的最小化文件集合。

文件页不会把 `isMinimized` 放进 Router。最小化是 App Shell 的 presentation state，而不是“要导航到哪个页面”。

## 最小化

1. 文件页创建当前 UIWindow 中可见内容的 snapshot。
2. Dock 创建一个全屏大小的 `MiniDockCardView` 并安装 snapshot。
3. 真实 `DocumentViewController` 从父控制器移除，但由 `MiniDockItem` 强引用保留。
4. 根容器为 Dock 预留 `56 + safeAreaBottom + 6` 的高度。
5. snapshot 卡片通过 0.4 秒 spring 移动到窗口底部，只露出标题条。

## 多卡片展开

展开后的卡片位置由 `MiniDockLayout` 计算：

- 最多按五张卡片分配纵向间距。
- `m34 = -1 / 1000` 提供透视。
- 卡片围绕 X 轴旋转，并同时沿 Y/Z 方向平移。
- 滚动时使用当前屏幕 Y 坐标重新计算角度。

这比单纯的 `scaleEffect` 或上下错位更接近 Telegram 中“围绕隐形圆柱”的感觉。

## 恢复

1. 根容器先把保留的真实 ViewController 放回 Dock 下方。
2. snapshot 卡片恢复到全屏尺寸、零圆角和单位变换。
3. 动画结束后移除 snapshot 卡片。
4. 真实文件页恢复交互并被提升到最前方。

真实页面在动画结束前已经位于 snapshot 下方，可以避免切换瞬间出现白屏。

## Liquid Glass

- 单个标题面使用 `UIVisualEffectView(effect: UIGlassEffect(style: .regular))`。
- 交互面设置 `isInteractive = true`。
- 子视图只添加到 `UIVisualEffectView.contentView`。
- 不通过降低 `UIVisualEffectView.alpha` 淡出玻璃；背景 dim 是独立 UIView，blur 通过切换 `effect` 动画。

## 与 Telegram 的差异

Telegram 的生产实现基于自有 NavigationController、AsyncDisplayKit 和 ComponentFlow。这个 Demo 使用标准 UIKit，以便单独学习交互机制。透视公式、收起高度、spring 时长和手势阈值按公开源码的行为重新实现，但没有引入 Telegram 的基础设施。
