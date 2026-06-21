# UIKit Update Properties Demo

一个聚焦的 UIKit demo，用来观察 iOS 26 `updateProperties()` 和 layout / constraints callbacks 的关系。

## Blog Topic

解释 `updateProperties()`、Observation tracking、`layoutSubviews()`、`updateConstraints()`、`setNeedsLayout()`、`setNeedsUpdateConstraints()` 之间的边界。

## What It Shows

- UIView 页 override `updateProperties()`、`updateConstraints()`、`layoutSubviews()` 并显示调用次数。
- UIViewController 页 override `updateProperties()`、`viewWillLayoutSubviews()`、`viewDidLayoutSubviews()` 并显示调用次数。
- `Toggle hidden` 展示 state-driven property update 不等于自动 constraint update。
- `Constraint update` 展示修改约束相关 state 后显式调用 `setNeedsUpdateConstraints()`。
- `Layout only` 展示只调用 `setNeedsLayout()` 时，layout callback 可以发生，但不应把 `updateConstraints()` 当成必然结果。

## Core Conclusion

`@Observable` 或 observation tracking 可以让 UIKit 为受影响的 view 或 view controller 重新运行 `updateProperties()`。这并不意味着 `updateConstraints()` 会自动运行。layout 和 constraint update 仍然取决于属性变化本身、UIKit 控件行为，或显式调用 `setNeedsLayout()`、`setNeedsUpdateConstraints()` 是否让 layout / constraints 失效。

## Requirements

- Xcode with iOS 26 SDK
- XcodeGen
- XcodeBuildMCP when available for simulator workflows

## Generate

```bash
xcodegen generate
```

## Run

```bash
open UIKitUpdatePropertiesDemo.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=UIKitUpdatePropertiesDemo iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `UIKitUpdatePropertiesDemo/DemoState.swift` contains observable demo state.
- `UIKitUpdatePropertiesDemo/DemoAction.swift` defines stable action copy and invalidation expectations.
- `UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift` records callback counts and event order.
- `UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift` demonstrates UIView property, constraint, and layout callbacks.
- `UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift` demonstrates UIViewController property and layout callbacks.
