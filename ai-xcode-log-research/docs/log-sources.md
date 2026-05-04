# XcodeBuildMCP And iOS Log Sources

## XcodeBuildMCP

Use XcodeBuildMCP as the primary AI-facing integration layer. It provides workflows for project discovery, simulator management, builds, tests, app launch, and log capture.

The command-line MCP server is configured as:

```bash
xcodebuildmcp mcp
```

Useful CLI areas for this research:

```bash
xcodebuildmcp project-discovery --help
xcodebuildmcp simulator --help
xcodebuildmcp logging --help
```

The command-line tools below remain useful as reproducible fallbacks and as raw evidence sources.

## Build And Test Logs

Use `xcodebuild` when the goal is reproducible command-line evidence:

```bash
xcodebuild -project LogResearchDemo.xcodeproj -scheme LogResearchDemo -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' test
```

Useful for:

- Compile errors
- Linker errors
- Test failures
- Swift compiler diagnostics
- Package resolution problems

## Result Bundles

Use `-resultBundlePath` to preserve structured Xcode output:

```bash
xcodebuild ... -resultBundlePath artifacts/logs/TestResults.xcresult test
```

Useful for:

- Test summaries
- Attachments
- Failure locations
- Activity logs

## Simulator Inventory

Use `simctl` to understand available runtimes and devices:

```bash
xcrun simctl list devices available
```

Useful for:

- Destination mismatch
- Missing runtime
- Booted simulator state

## Runtime Logs

For app logs emitted through `Logger` or `os_log`, use unified logging with a subsystem predicate:

```bash
log stream --style compact --predicate 'subsystem == "com.tigerguo.demo.LogResearchDemo"'
```

For a bounded capture:

```bash
log show --last 5m --style compact --predicate 'subsystem == "com.tigerguo.demo.LogResearchDemo"'
```

Useful for:

- Runtime warnings
- App lifecycle events
- Recoverable errors
- Feature-specific event traces
