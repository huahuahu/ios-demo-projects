# Research Plan

## Goal

Find a practical workflow for using XcodeBuildMCP with AI to inspect logs from an Xcode project and produce useful debugging guidance.

## Scope

This research focuses on local development logs:

- `xcodebuild` build and test output
- `.xcresult` result bundles
- Simulator logs from `simctl`
- App logs emitted through `Logger`, `os_log`, `print`, or `NSLog`
- XcodeBuildMCP project discovery, simulator, build/test, and logging workflows

## Evaluation Criteria

The AI output should be judged by whether it can:

- Identify the failing phase: compile, link, test, launch, runtime, UI test, or simulator setup
- Quote the relevant log lines without hallucinating unsupported causes
- Separate primary errors from secondary noise
- Suggest a minimal next command or code location to inspect
- Explain confidence and missing context

## Experiment Steps

1. Generate the demo Xcode project with `xcodegen generate`.
2. Use XcodeBuildMCP project discovery to identify the project, schemes, and runnable destinations.
3. Use XcodeBuildMCP build/test workflows where available, and keep `scripts/collect_logs.sh` as a command-line fallback.
4. Use XcodeBuildMCP logging workflows to capture simulator or device app logs.
5. Feed `summary.md`, build logs, test logs, and captured runtime logs to AI with `prompts/analyze-xcode-logs.md`.
6. Introduce controlled failures, such as a failing test or compile error.
7. Compare AI diagnosis against the known injected failure.

## Open Questions

- Which XcodeBuildMCP tools produce the most useful context for AI diagnosis?
- Is `xcresulttool` output more useful to AI than raw `xcodebuild` text?
- What is the smallest log slice that still preserves enough context for accurate diagnosis?
- Should logs be converted to JSON records before AI analysis?
