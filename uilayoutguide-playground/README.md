# UILayoutGuide Playground

A focused UIKit demo project for exploring the relationship between `UIView` and `UILayoutGuide`.

## Blog Topic

Use this project to explain how a `UIView` can own a `UILayoutGuide` with `addLayoutGuide(_:)`, and how that invisible guide can participate in Auto Layout without becoming a rendered subview.

## What It Shows

- `UILayoutGuide` is not a `UIView`: it has no drawing, hit testing, or subview hierarchy.
- A `UIView` owns custom layout guides through `addLayoutGuide(_:)`.
- A guide exposes anchors such as `leadingAnchor`, `topAnchor`, `widthAnchor`, and `heightAnchor`.
- Real views can be pinned to a guide, so changing guide constraints moves the visible views.
- `view.safeAreaLayoutGuide` is a built-in guide owned by UIKit, while custom guides are owned by the view that receives `addLayoutGuide(_:)`.
- A spacer `UIView` can often be replaced by a `UILayoutGuide` when the object only exists to express layout.

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
open UILayoutGuidePlayground.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project UILayoutGuidePlayground.xcodeproj -scheme UILayoutGuidePlayground -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `UILayoutGuidePlayground/AppDelegate.swift` and `SceneDelegate.swift` define the UIKit app lifecycle.
- `UILayoutGuidePlayground/RootTabBarController.swift` lists the three experiments.
- `UILayoutGuidePlayground/GuideOwnershipViewController.swift` shows `addLayoutGuide(_:)`, `layoutGuides`, and `owningView`.
- `UILayoutGuidePlayground/GuideLayoutViewController.swift` uses multiple guides to split a screen into layout regions.
- `UILayoutGuidePlayground/SpacerComparisonViewController.swift` compares a spacer view with a layout guide.
- `UILayoutGuidePlayground/GuideRelationshipSnapshot.swift` contains small inspectable helpers used by the demo and tests.
- `UILayoutGuidePlaygroundTests/UILayoutGuidePlaygroundTests.swift` verifies guide ownership and guide-driven layout behavior.

## Core Pattern

```swift
let contentGuide = UILayoutGuide()
view.addLayoutGuide(contentGuide)

let cardView = UIView()
cardView.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(cardView)

NSLayoutConstraint.activate([
    contentGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
    contentGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
    contentGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
    contentGuide.heightAnchor.constraint(equalToConstant: 160),

    cardView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
    cardView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
    cardView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
    cardView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor)
])
```

The guide owns the layout geometry. The view owns the rendering.
