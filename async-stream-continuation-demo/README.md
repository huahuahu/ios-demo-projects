# AsyncStream Continuation Demo

A focused SwiftUI demo for understanding how `AsyncStream` and its `Continuation` work together.

## Blog Topic

Explaining `AsyncStream`, continuation lifecycle, `yield`, `finish`, cancellation, `onTermination`, and memory management cleanup.

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
open AsyncStreamContinuationDemo.xcodeproj
```

Run the `AsyncStreamContinuationDemo` scheme on the dedicated simulator configured in the repository root `.xcodebuildmcp/config.yaml`.

## Logs

The app intentionally does not render a live log list. Open Xcode's debug console, Simulator console, or system log output and filter for:

```text
com.huahuahu.demo.AsyncStreamContinuationDemo
```

Important log points include stream creation, continuation storage, `yield` result, consumer receive, cancel, finish, `onTermination`, cleanup, and `deinit`.

## Test

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults, or run the equivalent Xcode test action for the `AsyncStreamContinuationDemo` scheme.

## Key Files

- `AsyncStreamContinuationDemo/AsyncEventSource.swift` owns `AsyncStream`, continuation, producer task, and cleanup.
- `AsyncStreamContinuationDemo/StreamDemoViewModel.swift` owns user actions and the consumer task.
- `AsyncStreamContinuationDemo/ContentView.swift` provides the focused SwiftUI controls.
- `AsyncStreamContinuationDemoTests/` verifies lifecycle behavior with Swift Testing.
