# UIKit updateProperties Demo Design

## Goal

Create a focused UIKit demo that explains how iOS 26 `updateProperties()` relates to view-controller updates, view layout, and Auto Layout constraint updates. The demo should make it clear that observation-driven property updates are independent from layout and constraint invalidation, while still running before layout when a layout pass occurs.

## Project shape

Add a standalone XcodeGen project:

```text
uikit-update-properties-demo/
  README.md
  project.yml
  .xcodebuildmcp/config.yaml
  UIKitUpdatePropertiesDemo/
  UIKitUpdatePropertiesDemoTests/
```

The app target is `UIKitUpdatePropertiesDemo`, uses UIKit, Swift 6.0, and an iOS 26.0 deployment target.

## Demo structure

The app presents two experiments with a tab bar or segmented navigation:

1. **UIView experiment**: `InstrumentedPanelView` owns a detail area, height constraint, action buttons, and a lifecycle log. It overrides `updateProperties()`, `updateConstraints()`, and `layoutSubviews()` and records each callback.
2. **UIViewController experiment**: `InstrumentedViewController` overrides `updateProperties()`, `viewWillLayoutSubviews()`, and `viewDidLayoutSubviews()`. It updates controller-level UI, such as title/status text, while showing how controller property updates are separate from view layout callbacks.

## State and event flow

Each experiment uses a small state object and a `LifecycleEventRecorder`.

- State changes that only affect appearance update labels, alpha, text, or hidden state through `updateProperties()`.
- Actions that mutate constraint constants explicitly request the relevant update with `setNeedsUpdateConstraints()` or `setNeedsLayout()`.
- The log shows callback order, callback counts, and a short explanation of what the selected action was expected to invalidate.

The UI should include controls for:

- toggling a detail view hidden state;
- changing a height constraint with an explicit constraint update request;
- changing a height constraint with only a layout request;
- clearing the lifecycle log.

## Message the demo should teach

The screen copy and README must state the core conclusion:

`@Observable` or observation tracking can cause UIKit to rerun `updateProperties()` for affected views or view controllers. That does not mean `updateConstraints()` automatically runs. Layout and constraint updates still depend on whether layout or constraints were invalidated by the changed properties, UIKit control behavior, or explicit calls such as `setNeedsLayout()` and `setNeedsUpdateConstraints()`.

## Tests

Add focused unit tests for non-UI logic:

- `LifecycleEventRecorder` records ordered events and per-callback counts.
- State transition helpers describe whether an action expects property, layout, or constraint invalidation.
- Explanation strings for the demo actions remain stable enough for the README and UI to match.

Full lifecycle callback ordering remains a runtime observation in the simulator rather than a brittle unit-test assertion.

## Validation

Generate the project with XcodeGen. Use XcodeBuildMCP to set project defaults, run simulator tests, and build/run the demo on its dedicated iPhone 17 Pro Max simulator.
