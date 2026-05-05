# Simulator Log Capture

A small SwiftUI demo project for testing how an agentic coding workflow captures iOS Simulator logs.

## Blog Topic

Capturing simulator logs during agentic coding sessions.

我想测试不同的 log 方式，通过不同的方法能不能拿到日志。

## Log Ways

Tap the `Print Logs` button in the app to emit logs in three ways:

1. `print`
2. `os_log`
3. `Logger`

## Capture Ways

### Console app

Open Console app, select the booted simulator, then filter for `SimulatorLogCapture`.

### Xcode Console

Run `SimulatorLogCapture` from Xcode and check the debug console after tapping `Print Logs`.

### simctl log stream

```bash
xcrun simctl log stream booted --predicate 'process == "SimulatorLogCapture"'
```

## Requirements

- Xcode with iOS Simulator support
- XcodeGen
- XcodeBuildMCP for simulator build/run/log workflows

## Generate

```bash
xcodegen generate
```

## Run

```bash
open SimulatorLogCapture.xcodeproj
```

Or use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults.

## Test

```bash
xcodebuild test -project SimulatorLogCapture.xcodeproj -scheme SimulatorLogCapture -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

## Key Files

- `project.yml` defines the XcodeGen project.
- `SimulatorLogCapture/SimulatorLogCaptureApp.swift` is the app entry point.
- `SimulatorLogCapture/ContentView.swift` contains the `Print Logs` button.
