# Interruptible Animation Demo Design

## Goal

Create a focused iOS demo project that explains interruptible and resumable animations through direct interaction. The demo should let readers drag a card, stop midway, reverse direction, and release it so the animation continues from the current progress instead of restarting.

The demo is intended for a blog topic about UIKit `UIViewPropertyAnimator`, interactive animation progress, and how SwiftUI state-driven animation compares conceptually.

## Project Shape

The new standalone demo directory will be:

```text
interruptible-animation-demo/
  README.md
  project.yml
  .xcodebuildmcp/
    config.yaml
  InterruptibleAnimationDemo/
  InterruptibleAnimationDemoTests/
```

The app and scheme name will be `InterruptibleAnimationDemo`. The bundle identifier will be `com.huahuahu.demo.InterruptibleAnimationDemo`. The project will use XcodeGen, Swift 6.0, iOS 26.0, and an empty development team for local simulator use.

## Architecture

The app will use a SwiftUI shell with two tabs:

1. `UIKit` as the primary explanation.
2. `SwiftUI` as a conceptual comparison.

The UIKit tab will host a `UIViewControllerRepresentable` wrapper around a UIKit view controller. That view controller owns a draggable card and a `UIViewPropertyAnimator`. A pan gesture pauses the animator, maps drag distance into `fractionComplete`, and then calls `continueAnimation(...)` on release so the card completes or returns from the current position.

The SwiftUI tab will use the same visual metaphor, but it will explain the concept through state: gesture updates temporarily override the card offset, and release changes the target state with animation. This keeps the comparison honest: UIKit exposes explicit animator control, while SwiftUI usually expresses interruptibility by changing animated state.

## Components

### `AnimationSnapState`

`AnimationSnapState` will describe the two resting positions: collapsed and expanded. It will expose display labels and target offsets used by both tabs.

### `AnimationProgressModel`

`AnimationProgressModel` will contain deterministic math for:

- clamping progress to `0...1`
- converting a drag translation into progress
- choosing the final snap state from progress and drag velocity

This model keeps the demo behavior testable without relying on animation timing or UIKit gesture recognizers.

### `InterruptibleUIKitViewController`

`InterruptibleUIKitViewController` will render the primary demo. It will include:

- a card view with short instructional text
- a status label showing the current animator state and progress
- a pan gesture recognizer
- a `UIViewPropertyAnimator` that moves the card between collapsed and expanded positions

During a pan gesture, the controller will call `pauseAnimation()`, update `fractionComplete`, and reverse or continue the animator depending on the selected snap state.

### `UIKitInterruptibleDemoView`

`UIKitInterruptibleDemoView` will bridge the UIKit controller into SwiftUI so the app can keep a simple tab-based shell.

### `SwiftUIInterruptibleDemoView`

`SwiftUIInterruptibleDemoView` will mirror the card interaction using SwiftUI gestures and state. It will include explanatory text that points out the API difference from UIKit: SwiftUI does not expose the same `UIViewPropertyAnimator` control surface, but changing animated state while an animation is in flight produces a similar user-facing interruption.

### `ContentView`

`ContentView` will present the two tabs and a concise title for the overall demo.

## Data Flow

Static state flows from each tab into the shared progress model. Gesture updates produce a normalized progress value. The UIKit tab writes that progress into `UIViewPropertyAnimator.fractionComplete`; the SwiftUI tab converts the same concept into a temporary offset and final snap state.

There is no network, persistence, or user-generated data. The app remains deterministic except for UIKit and SwiftUI runtime animation interpolation.

## Error Handling and Edge Cases

The demo has no recoverable external errors. Internal edge cases will be handled by clamping progress and guarding against invalid travel distances before computing snap decisions. Very small layout sizes should still keep the card visible and avoid negative travel distance.

Gesture cancellation will be treated like release: the card chooses the nearest snap state and animates there from the current progress.

## Testing

Tests will focus on stable logic rather than visual timing:

- progress clamping keeps values inside `0...1`
- drag translation maps to expected progress
- snap decisions prefer expanded or collapsed based on progress threshold
- high velocity can choose the velocity direction even when progress is near the threshold

The project will not include pixel snapshot tests because the goal is to teach interruptible animation concepts, not to freeze exact rendering details.

## README Scope

The demo README will explain:

- what interruptible and resumable animations mean
- why `UIViewPropertyAnimator` is the central UIKit API
- how the SwiftUI comparison differs from UIKit
- expected Xcode/iOS versions
- how to run `xcodegen generate`
- how to open, run, and test the project
- which files contain the main concept

## Validation Plan

After implementation, generate the Xcode project with `xcodegen generate`, create a dedicated `InterruptibleAnimationDemo iPhone 17 Pro Max` simulator, write `.xcodebuildmcp/config.yaml`, and use XcodeBuildMCP `test_sim` to verify the simulator test target.
