# UIKit updateProperties Demo

This demo explores lifecycle callbacks in UIKit, specifically demonstrating the distinction between **observation-driven property updates** (`updateProperties()`) and **automatic constraint updates** (`updateConstraints()`).

## Key Insight

**`updateProperties()` does NOT automatically trigger `updateConstraints()`.**

When you use observation properties or key-value observation (KVO) to update view properties, `updateProperties()` is called to notify the view of the changes. However, this does not automatically invoke `updateConstraints()`. You must explicitly call `setNeedsUpdateConstraints()` if constraint adjustments are needed in response to property changes.

## Features

- **LifecycleEventRecorder**: A utility that tracks and records lifecycle callback invocations with detailed sequence information
- **Callback types tracked**: `updateProperties`, `updateConstraints`, `layoutSubviews`, `viewWillLayoutSubviews`, `viewDidLayoutSubviews`
- **Summary and event reporting**: Methods to generate human-readable summaries and event logs for debugging

## Testing

Run the test suite:

```bash
cd uikit-update-properties-demo
xcodegen generate
xcodebuild test -project UIKitUpdatePropertiesDemo.xcodeproj -scheme UIKitUpdatePropertiesDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```
