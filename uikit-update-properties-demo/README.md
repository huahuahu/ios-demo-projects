# UIKit Update Properties Demo

一个聚焦的 UIKit demo，用来观察 iOS 26 `updateProperties()` 和 layout / constraints callbacks 的关系。

## Blog Topic

解释 `updateProperties()`、Observation tracking、`layoutSubviews()`、`updateConstraints()`、`setNeedsLayout()`、`setNeedsUpdateConstraints()` 之间的边界。

## What It Shows

- UIView 页 override `updateProperties()`、`updateConstraints()`、`layoutSubviews()` 并显示调用次数。
- UIViewController 页 override `updateProperties()`、`viewWillLayoutSubviews()`、`viewDidLayoutSubviews()` 并显示调用次数。
- `Toggle hidden` 展示 state-driven property update：UIStackView 可能触发 layout，但不会建立 constraints 依赖（除非 `updateConstraints()` 读取该 state）。
- `Constraint update` 展示 `updateConstraints()` 读取 `detailHeight`，detailHeight 改变会通过 observation tracking 自动重跑 `updateConstraints()`，无需显式调用 `setNeedsUpdateConstraints()`。
- `Layout only` 展示只改变 `layoutMarker`（`updateConstraints()` 不读取它）并显式调用 `setNeedsLayout()`，证明手动 layout request 与 constraints tracking 彼此独立。

## Core Conclusion

`updateProperties()`、`updateConstraints()`、`layoutSubviews()` 等 UIKit update 方法各自独立建立 observation 依赖。某个 observable 属性在哪个方法中被读取，改变时就会自动重跑哪个方法。例如：`detailHeight` 在 `updateConstraints()` 中被读取，改变时会自动重跑 `updateConstraints()`；`isDetailHidden` 只在 `updateProperties()` 中被读取，改变时只重跑 `updateProperties()`。layout 和 property update 仍然是独立的 pass，显式调用 `setNeedsLayout()` 只请求 layout，不影响 constraints tracking。

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

> **Note:** `.xcodebuildmcp/config.yaml` contains a `simulatorId` that is specific to the original machine. On other machines, either create a simulator named `UIKitUpdatePropertiesDemo iPhone 17 Pro Max` and update the UUID, or use the generic xcodebuild destination below.

## Test

```bash
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `UIKitUpdatePropertiesDemo/DemoState.swift` contains observable demo state.
- `UIKitUpdatePropertiesDemo/DemoAction.swift` defines stable action copy and invalidation expectations.
- `UIKitUpdatePropertiesDemo/LifecycleEventRecorder.swift` records callback counts and event order.
- `UIKitUpdatePropertiesDemo/LogView.swift` reusable count and event log UI component.
- `UIKitUpdatePropertiesDemo/InstrumentedPanelView.swift` demonstrates UIView property, constraint, and layout callbacks.
- `UIKitUpdatePropertiesDemo/UIViewControllerExperimentViewController.swift` demonstrates UIViewController property and layout callbacks.
