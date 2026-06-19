# Keyboard Handling Tabs

A focused iOS demo for comparing keyboard handling in SwiftUI and UIKit tabs.

## Blog Topic

Building a scrollable input screen where action buttons and the text field stay right above the keyboard.

## What It Shows

- One app with two tabs: **SwiftUI** and **UIKit**.
- Both tabs use a scrollable message list plus a composer area.
- Composer area includes action buttons (`Attach`, `Emoji`, `Clear`, `Dismiss`) and a text input + `Send`.
- `Dismiss` explicitly closes the keyboard or active presentation.
- SwiftUI `Attach` opens a medium-detent sheet with selectable sources (`Photo Library`, `Camera`, `Files`).
- UIKit `Attach` replaces the system keyboard with a custom attachment `UIInputView` hosted by an invisible first responder.
- SwiftUI tab uses `safeAreaInset(edge: .bottom)` for keyboard-safe placement.
- UIKit tab keeps the composer pinned to `keyboardLayoutGuide` while UIKit owns both the system keyboard and custom attachment input surface.

## Requirements

- Xcode with iOS Simulator support
- XcodeGen
- XcodeBuildMCP when available for simulator workflows

## Generate

```bash
xcodegen generate
```

## Run

```bash
open KeyboardHandlingTabs.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project KeyboardHandlingTabs.xcodeproj -scheme KeyboardHandlingTabs -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `KeyboardHandlingTabs/ContentView.swift` wires the two tabs.
- `KeyboardHandlingTabs/SwiftUIKeyboardTabView.swift` demonstrates SwiftUI keyboard-safe composer layout and sheet-based source selection.
- `KeyboardHandlingTabs/UIKitKeyboardViewController.swift` demonstrates UIKit keyboard-safe composer layout with `keyboardLayoutGuide` plus first-responder switching to a custom attachment `UIInputView`.
- `KeyboardHandlingTabs/KeyboardDemoModel.swift` contains shared demo state and action behavior.
- `KeyboardHandlingTabsTests/KeyboardDemoModelTests.swift` verifies focused model behavior.
- `docs/ui-preview.html` is a browser-friendly visual mock of both tabs.
