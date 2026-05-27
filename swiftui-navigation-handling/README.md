# SwiftUI Navigation Handling

A focused SwiftUI demo project for handling app navigation with a typed `NavigationStack` route path.

## Blog Topic

Handling SwiftUI navigation with route values, programmatic jumps, detail flows, and root resets.

## What It Shows

- `NavigationStack(path:)` with a typed `[NavigationRoute]` path.
- `NavigationLink(value:)` for list-driven navigation.
- Programmatic navigation for deep-link style jumps.
- Shared routing actions for pushing, popping, and returning to root.

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
open SwiftUINavigationHandling.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project SwiftUINavigationHandling.xcodeproj -scheme SwiftUINavigationHandling -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `SwiftUINavigationHandling/ContentView.swift` wires the `NavigationStack` and destinations.
- `SwiftUINavigationHandling/NavigationRouter.swift` owns programmatic navigation actions.
- `SwiftUINavigationHandling/NavigationRoute.swift` defines the typed route enum.
- `SwiftUINavigationHandling/DemoData.swift` provides stable demo content.
