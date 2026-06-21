# UIKit updateProperties Demo 设计

## 目标

创建一个聚焦的 UIKit demo，用来说明 iOS 26 `updateProperties()` 和 view controller 更新、view layout、Auto Layout 约束更新之间的关系。这个 demo 要清楚表达：由 Observation 驱动的属性更新和 layout / constraint invalidation 是相互独立的；但当 layout pass 发生时，`updateProperties()` 会在 layout 之前运行。

## 工程结构

新增一个独立的 XcodeGen 工程：

```text
uikit-update-properties-demo/
  README.md
  project.yml
  .xcodebuildmcp/config.yaml
  UIKitUpdatePropertiesDemo/
  UIKitUpdatePropertiesDemoTests/
```

App target 名为 `UIKitUpdatePropertiesDemo`，使用 UIKit、Swift 6.0，最低部署目标为 iOS 26.0。

## Demo 结构

App 使用 tab bar 或 segmented navigation 展示两个实验页：

1. **UIView 实验页**：`InstrumentedPanelView` 拥有 detail 区域、高度约束、操作按钮和 lifecycle 日志。它 override `updateProperties()`、`updateConstraints()`、`layoutSubviews()`，并记录每次回调。
2. **UIViewController 实验页**：`InstrumentedViewController` override `updateProperties()`、`viewWillLayoutSubviews()`、`viewDidLayoutSubviews()`。它更新 controller 层 UI，例如 title 和 status 文案，同时展示 controller 的 property update 与 view layout callback 的边界。

## 状态和事件流

每个实验页使用一个小型 state object 和一个 `LifecycleEventRecorder`。

- 只影响外观的 state 变化通过 `updateProperties()` 更新 label、alpha、text 或 hidden state。
- 修改 constraint constant 的操作需要显式调用 `setNeedsUpdateConstraints()` 或 `setNeedsLayout()` 来请求对应更新。
- 日志展示 callback 顺序、callback 计数，以及当前操作预期会 invalidate 哪一类更新。

UI 需要包含这些操作：

- 切换 detail view 的 hidden state；
- 修改高度约束，并显式请求 constraint update；
- 修改高度约束，但只请求 layout update；
- 清空 lifecycle 日志。

## Demo 要传达的结论

界面文案和 README 必须写清楚核心结论：

`@Observable` 或 observation tracking 可以让 UIKit 为受影响的 view 或 view controller 重新运行 `updateProperties()`。这并不意味着 `updateConstraints()` 会自动运行。layout 和 constraint update 仍然取决于属性变化本身、UIKit 控件行为，或显式调用 `setNeedsLayout()`、`setNeedsUpdateConstraints()` 是否让 layout / constraints 失效。

## 测试

为非 UI 逻辑添加聚焦的单元测试：

- `LifecycleEventRecorder` 能记录有序事件和每种 callback 的调用次数。
- State transition helper 能描述某个操作预期会触发 property、layout 还是 constraint invalidation。
- Demo 操作文案保持稳定，README 和 UI 可以共享同一组解释文本。

完整 lifecycle callback 顺序作为 simulator 运行时观察结果展示，不写成脆弱的单元测试断言。

## 验证

使用 XcodeGen 生成工程。使用 XcodeBuildMCP 设置项目默认值、运行 simulator tests，并在专用的 iPhone 17 Pro Max simulator 上 build/run 这个 demo。
