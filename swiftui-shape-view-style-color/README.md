# SwiftUI Shape / View / Style / Color

A focused SwiftUI demo that explains how `Shape`, `View`, `ShapeStyle`, `Color`, modifier chains, and `InsettableShape` fit together.

## Blog Topic

Understanding the relationship between SwiftUI drawing concepts: geometry (`Shape`), renderable UI (`View`), painting (`ShapeStyle`), color values, modifiers, and `strokeBorder`.

## What It Shows

- `Shape` describes geometry before appearance is chosen.
- `Shape` becomes visible as a `View` when it participates in layout and rendering.
- `ShapeStyle` paints a shape without changing its geometry.
- `Color` is a concrete value that can also be used as a `ShapeStyle`.
- Modifiers such as `.fill()`, `.stroke()`, and `.foregroundStyle()` return new views.
- `InsettableShape` explains why `.strokeBorder()` can draw inside a shape boundary.

## Requirements

- Xcode with iOS Simulator support
- XcodeGen
- XcodeBuildMCP when available for simulator workflows
- iOS 26.0 SDK baseline
- Swift 6.0

## Generate

```bash
xcodegen generate
```

## Run

```bash
open SwiftUIShapeViewStyleColor.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project SwiftUIShapeViewStyleColor.xcodeproj -scheme SwiftUIShapeViewStyleColor -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `SwiftUIShapeViewStyleColor/DemoModel.swift` defines concept metadata, relationship edges, and experiment options.
- `SwiftUIShapeViewStyleColor/ContentView.swift` renders the relationship map and four experiments.
- `SwiftUIShapeViewStyleColorTests/DemoModelTests.swift` verifies the teaching order, experiment metadata, and concept relationships.
