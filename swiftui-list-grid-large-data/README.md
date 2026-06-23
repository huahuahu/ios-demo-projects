# SwiftUI List Grid Large Data

A focused SwiftUI demo that shows how to switch between a native `List` and a Health-style `LazyVGrid` while paging through a large generated data set.

## Blog Topic

Building large SwiftUI collection screens that keep native list interactions, add a polished category-card grid, and load data in batches.

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
open SwiftUIListGridLargeData.xcodeproj
```

Then run the `SwiftUIListGridLargeData` scheme on an iOS Simulator.

## Test

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults, or run the equivalent Xcode test action for the `SwiftUIListGridLargeData` scheme.

## Key Files

- `SwiftUIListGridLargeData/CategoryBrowserView.swift` switches between `List` and `LazyVGrid`.
- `SwiftUIListGridLargeData/CategoryCardView.swift` draws the Health-style gradient grid cards.
- `SwiftUIListGridLargeData/CategoryBrowserViewModel.swift` owns paging, search, and load-more thresholds.
- `SwiftUIListGridLargeData/GeneratedHealthCategoryDataSource.swift` simulates a large data source.
- `SwiftUIListGridLargeDataTests/` verifies paging behavior with Swift Testing.
