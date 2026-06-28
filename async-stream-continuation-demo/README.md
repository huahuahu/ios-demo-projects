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
cd async-stream-continuation-demo
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

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults:

1. `session_show_defaults`
2. `session_set_defaults` if the active defaults do not match the repository root config
3. `test_sim`

You can also run the equivalent Xcode test action for the `AsyncStreamContinuationDemo` scheme.

## Key Files

- `AsyncStreamContinuationDemo/Domain/AsyncEventSource.swift` owns `AsyncStream`, continuation, producer task, and cleanup.
- `AsyncStreamContinuationDemo/Domain/StreamEvent.swift` defines the values sent through the stream.
- `AsyncStreamContinuationDemo/Features/StreamDemo/StreamDemoViewModel.swift` owns user actions and the consumer task.
- `AsyncStreamContinuationDemo/Features/StreamDemo/ContentView.swift` provides the focused SwiftUI controls.
- `AsyncStreamContinuationDemo/Support/DemoLogging.swift` centralizes console logging.
- `AsyncStreamContinuationDemoTests/Domain/` and `AsyncStreamContinuationDemoTests/Features/` verify lifecycle behavior with Swift Testing.
