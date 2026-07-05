# SwiftDataDeleteHandling

This demo shows why a SwiftUI detail page should not keep a deleted SwiftData model alive, and demonstrates the recommended `persistentModelID` + `@Query` fix.

## Blog Topic

Use this project for a blog post about a SwiftData + SwiftUI navigation bug pattern: a detail view receives `@Bindable var book`, another `ModelContext` deletes that book and saves, then the detail page does not automatically pop after the main context observes the deletion.

The first row demonstrates the problem. The second row demonstrates the preferred fix: navigate with `book.persistentModelID`, use `@Query` with a predicate for that ID, and call `dismiss()` when `books.first == nil`.

## Requirements

- Xcode with iOS 26 SDK
- XcodeGen 2.45 or newer
- Swift 6.0

## Generate and Open

```bash
cd swiftdata-delete-handling
xcodegen generate
open SwiftDataDeleteHandling.xcodeproj
```

## Run and Test

```bash
cd swiftdata-delete-handling
xcodebuild test \
  -project SwiftDataDeleteHandling.xcodeproj \
  -scheme SwiftDataDeleteHandling \
  -destination 'platform=iOS Simulator,name=SwiftDataDeleteHandling iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `SwiftDataDeleteHandling/Domain/Book.swift`: the SwiftData `@Model` used by both scenarios.
- `SwiftDataDeleteHandling/Domain/BookCover.swift`: a relationship target used to demonstrate a late relationship fault.
- `SwiftDataDeleteHandling/Domain/BackgroundBookDeleter.swift`: a `@ModelActor` that deletes a book through a background SwiftData context.
- `SwiftDataDeleteHandling/Domain/BookStore.swift`: sample seeding and fetch helpers.
- `SwiftDataDeleteHandling/Features/DeleteHandling/ScenarioListView.swift`: the two-row demo launcher.
- `SwiftDataDeleteHandling/Features/DeleteHandling/BindableProblemDetailView.swift`: the problematic `@Bindable var book` detail.
- `SwiftDataDeleteHandling/Features/DeleteHandling/PersistentIDQueryFixDetailView.swift`: the recommended `persistentModelID` + `@Query` detail.
- `SwiftDataDeleteHandlingTests/Domain/BookStoreTests.swift`: in-memory SwiftData tests for sample seeding and background deletion.

## Research Notes

- The problem detail intentionally keeps `@Bindable var book`, then shows `book.isDeleted` / `book.modelContext` after background deletion.
- The problem detail includes a relationship button that reads `book.cover` only after the book is deleted, demonstrating why a not-yet-materialized relationship can be dangerous.
- It also includes a stronger crash button that asks a fresh context for a fault using the deleted `persistentModelID`, then reads a property to trigger SwiftData/CoreData's invalidated-object path.
- The solution detail never stores a `Book`; it stores `PersistentIdentifier` and derives the current book from `@Query`.
- When the solution query becomes empty, `dismiss()` pops back to the list automatically.
