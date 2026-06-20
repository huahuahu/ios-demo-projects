# Chat Bubble Shape Demo

A focused SwiftUI demo for building a parameterized chat bubble with a rounded body, left-bottom tail, purple stroke, lavender fill, soft shadow, and multiline text.

## Blog Topic

Using SwiftUI `Shape` and `Path` to implement a reusable chat bubble silhouette and compare visual parameters such as corner radius, tail size, stroke width, and shadow.

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
open ChatBubbleShapeDemo.xcodeproj
```

Then run the `ChatBubbleShapeDemo` scheme on an iOS Simulator.

## Test

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults, or run the equivalent Xcode test action for the `ChatBubbleShapeDemo` scheme.

## Key Files

- `ChatBubbleShapeDemo/ChatBubbleShape.swift` builds the custom bubble `Path`.
- `ChatBubbleShapeDemo/ChatBubbleStyle.swift` stores visual parameters and presets.
- `ChatBubbleShapeDemo/BubbleSample.swift` defines the hero and comparison samples.
- `ChatBubbleShapeDemo/ChatBubbleView.swift` applies fill, stroke, shadow, padding, and text.
- `ChatBubbleShapeDemo/ContentView.swift` presents the reference bubble and variants.
- `ChatBubbleShapeDemoTests/` verifies preset data and path behavior.
- `samples/` keeps the original reference image, the latest simulator screenshot, and a side-by-side comparison.
