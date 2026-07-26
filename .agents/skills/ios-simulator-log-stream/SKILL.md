---
name: ios-simulator-log-stream
description: Use this project-local skill when the user asks an AI assistant to capture, inspect, stream, save, filter, or debug iOS Simulator logs from an app using xcrun simctl spawn log stream. Trigger for simulator logging, Logger/os_log investigation, agentic coding log capture, or checking app runtime output from terminal-accessible simulator logs.
---

# iOS Simulator Log Stream

## Purpose

Capture iOS Simulator unified logs from the terminal in a way an AI assistant can inspect and summarize. Prefer `xcrun simctl spawn <device> log stream ...` over UI-only tools such as Console.app or Xcode Console.

## Correct Command Shape

Use `simctl spawn` to run `log stream` inside the simulator environment:

```bash
xcrun simctl spawn booted log stream \
  --level info \
  --predicate 'process == "AppProcessName"' \
  --style compact
```

Important:

- The command is `simctl`, not `simctrl`.
- Use `xcrun simctl spawn <device> log stream`, not `xcrun simctl log stream`. The local reference investigation saw `Unrecognized subcommand: log` for the direct form.
- Use `--level info` when expecting Swift `Logger.info` output.
- `os_log` may appear without `--level info`, but keep `--level info` by default for app debugging.
- `print` output is not reliable in unified logging and may not appear in `log stream`.

## Workflow

1. Identify the target app process name. Usually this is the app or scheme name, for example `SimulatorLogCapture`.
2. Prefer `booted` when exactly one simulator is running.
3. If multiple simulators are booted, use the simulator UUID instead of `booted`.
4. Start `log stream` before triggering the app behavior when possible.
5. Trigger the app behavior in the simulator.
6. Stop the stream after enough output is captured and summarize only relevant lines.

## Useful Predicates

Filter by process name:

```bash
--predicate 'process == "AppProcessName"'
```

Filter by subsystem when the app uses Swift `Logger(subsystem:category:)`:

```bash
--predicate 'subsystem == "com.example.app"'
```

Filter by process and message text:

```bash
--predicate 'process == "AppProcessName" AND eventMessage CONTAINS "SearchText"'
```

## Saving Logs

When the user wants a durable artifact, save logs into the related demo's `result/` directory when it exists:

```bash
xcrun simctl spawn booted log stream \
  --level info \
  --predicate 'process == "AppProcessName"' \
  --style compact
```

Prefer a filename such as `result/simctl-log-stream.txt`. If the command is run interactively, stop it after the target action emits logs.

## Reporting

When reporting results:

- Include the exact command shape used, with process name or simulator UUID.
- Quote the relevant log lines, not the full stream.
- State whether `Logger.info`, `os_log`, or expected app messages were seen.
- If no logs appear, check process name, simulator boot state, `--level info`, and whether the app behavior was triggered after the stream started.

## Repository Context

The existing reference demo and article are:

- `simulator-log-capture/`
- `blog/_articles/simulator-log-capture.md`

Use those as the local baseline for simulator log behavior in this repository.
