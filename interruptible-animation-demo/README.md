# Interruptible Animation Demo

A focused iOS demo for explaining interruptible and resumable animations.

## Blog Topic

This demo supports a blog post about UIKit `UIViewPropertyAnimator`, interactive animation progress, and how SwiftUI state-driven animation compares.

## What It Shows

- A UIKit card that can be dragged, paused, reversed, and continued with `UIViewPropertyAnimator`.
- A SwiftUI comparison that shows how changing animated state can interrupt an in-flight animation.
- Shared progress math for deciding whether the card should finish expanded or collapse back.

## Requirements

- Xcode with iOS Simulator support
- iOS 26.0 SDK
- Swift 6.0
- XcodeGen
- XcodeBuildMCP for simulator validation

## Generate

```bash
xcodegen generate
```

## Run

```bash
open InterruptibleAnimationDemo.xcodeproj
```

Then run the `InterruptibleAnimationDemo` scheme on an iOS Simulator.

## Test

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults, or run the equivalent Xcode test action for the `InterruptibleAnimationDemo` scheme.

## Key Files

- `AnimationProgressModel.swift` contains the deterministic drag/progress/snap logic.
- `InterruptibleUIKitViewController.swift` demonstrates `UIViewPropertyAnimator.pauseAnimation()`, `fractionComplete`, and `continueAnimation(...)`.
- `UIKitInterruptibleDemoView.swift` bridges the UIKit controller into the SwiftUI shell.
- `SwiftUIInterruptibleDemoView.swift` shows the state-driven SwiftUI comparison.
- `ContentView.swift` presents the two demo tabs.
