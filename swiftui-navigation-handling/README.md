# SwiftUI Navigation Handling

A focused SwiftUI demo project for handling tab navigation, modal routing, and deep links with one global router.

## Blog Topic

Handling SwiftUI navigation with tab paths, global presentation state, cold-launch deep links, hot links, and presented-view navigation.

## What It Shows

- A tab-based SwiftUI app with separate paths for Inbox and Settings.
- A global `Router` stored in the SwiftUI environment with `@Environment(Router.self)`.
- Typed `Route`, `SheetRoute`, and `FullScreenRoute` enums that are `Hashable` and `Identifiable`.
- Shared sheet and full-screen-cover navigation state.
- A recursive `PresentationNode` model so every presented view has its own `route`, `path`, `sheet`, and `fullScreen` state.
- Deep-link handling that dismisses active sheets/covers before applying the requested route.
- Cold launch links through `--deep-link` launch arguments and hot links through `onOpenURL`.
- Presented views that can keep navigating through the same global router.

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
- `SwiftUINavigationHandling/ContentView.swift` wires the tab app, stacks, sheets, covers, and destinations.
- `SwiftUINavigationHandling/Router.swift` owns all navigation state.
- `SwiftUINavigationHandling/NavigationTypes.swift` defines typed routes, sheets, full-screen routes, tabs, and deep-link values.
- `SwiftUINavigationHandling/DeepLinkParser.swift` maps URLs and launch arguments into router actions.
- `SwiftUINavigationHandling/DemoData.swift` provides stable demo content.
- `SwiftUINavigationHandlingTests/RouterTests.swift` verifies router behavior.

## Presented View Navigation

Presented roots use their own node path instead of reusing the tab path:

```swift
NavigationStack(path: $node.path) {
    PresentedRootView(node: node)
        .navigationDestination(for: Route.self) { route in
            DestinationView(route: route)
        }
}
```

Inside the sheet, a child view can push a new modal-local destination through its current node:

```swift
@Bindable var node: PresentationNode

Button("Push Inside Sheet") {
    node.push(.message(301))
}
```

The demo keeps `node.push(_:)` separate from `router.push(_:on:)` so it is visible whether a route is pushed inside the presented view or onto a tab stack behind the presentation.

## Nested Presentations

If a presented view needs to present another view, put presentation state on the current presentation node. That avoids hardcoding `nestedSheet`, `nestedNestedSheet`, and so on:

```swift
@Observable
final class PresentationNode: Identifiable {
    let route: PresentationRoute
    var path: [Route]
    var sheet: PresentationNode?
    var fullScreen: PresentationNode?
}
```

Each node renders the same recursive container:

```swift
NavigationStack(path: $node.path) {
    PresentedRootView(node: node)
}
.sheet(item: $node.sheet) { child in
    PresentationNodeView(node: child)
}
.fullScreenCover(item: $node.fullScreen) { child in
    PresentationNodeView(node: child)
}
```

Then a child inside any presented view can show another modal without replacing its parent presentation:

```swift
Button("Present Sheet From Sheet") {
    node.presentSheet(.composer(replyTo: nil))
}
```

Closing that nested sheet should clear only the parent node's `sheet`, so the user returns to the parent filter sheet:

```swift
node.dismissSheet()
```

Deep links clear the root presentation nodes before applying the link, which removes the whole presentation subtree.

## Deep Link Examples

```bash
xcrun simctl openurl booted swiftuinavigationhandling://message/101
xcrun simctl openurl booted swiftuinavigationhandling://settings/notifications
```

Cold-launch behavior can be exercised by passing launch arguments from Xcode:

```text
--deep-link swiftuinavigationhandling://message/102
```
