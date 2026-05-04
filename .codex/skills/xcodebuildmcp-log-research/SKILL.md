---
name: xcodebuildmcp-log-research
description: Use this project-local skill when creating or extending demo projects in this repository that research how AI can inspect Xcode project logs through XcodeBuildMCP. Trigger for tasks involving XcodeBuildMCP, Xcode logs, iOS demo scaffolding, build/test log collection, simulator log capture, AI log-analysis prompts, or reproducing the ai-xcode-log-research project structure.
---

# XcodeBuildMCP Log Research

## Purpose

Create small, reproducible iOS research demos that answer: how can AI inspect Xcode project logs and produce useful debugging guidance?

Keep the demo focused on log capture and analysis. Do not build a large app unless the research question requires it.

## Default Project Shape

Use this layout for each research demo:

```text
demo-name/
  README.md
  project.yml
  DemoApp/
  DemoAppTests/
  scripts/collect_logs.sh
  docs/research-plan.md
  docs/log-sources.md
  prompts/analyze-xcode-logs.md
  samples/sample-log-notes.md
```

Prefer XcodeGen for scaffolded projects. Keep generated `.xcodeproj` files only when the user wants the project immediately openable from Xcode.

## Creation Workflow

1. Create a standalone directory under the repo root, such as `ai-xcode-log-research/`.
2. Add `project.yml` with one iOS application target and one unit test target.
3. Add a minimal SwiftUI app that emits logs through `Logger` with a stable subsystem.
4. Add a simple XCTest that emits test logs with `NSLog`.
5. Add `scripts/collect_logs.sh` to collect build/test output, simulator inventory, and `.xcresult` output.
6. Add docs describing the research question, log sources, and experiment steps.
7. Add a prompt file that tells AI to quote log evidence and avoid unsupported diagnosis.
8. Run `xcodegen generate` from the demo directory.
9. Run the collection script once and inspect the generated artifact directory.

## XcodeBuildMCP First

The repo-level MCP server should be:

```toml
[mcp_servers.xcodebuildmcp]
command = "xcodebuildmcp"
args = ["mcp"]
```

Prefer XcodeBuildMCP for:

- project discovery
- scheme listing
- simulator listing and booting
- simulator build/test/run
- app launch with logs
- simulator or device log capture

Use direct `xcodebuild`, `xcrun simctl`, `log show`, and `log stream` only as reproducible fallback commands or raw evidence sources.

## Log Collection Pattern

The collection script should:

- create `artifacts/logs/<timestamp>/`
- generate the Xcode project if missing and `xcodegen` is available
- run `xcodebuild test` with `-resultBundlePath`
- write raw output to `xcodebuild-test.log`
- write simulator inventory to `simulators.log`
- extract `.xcresult` summaries when possible
- write a short `summary.md` containing scheme, destination, exit code, and file list

Use a destination that disambiguates duplicate simulator names:

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'
```

If `xcodebuild` returns exit code `70`, inspect the destination section of the log first; it often means the requested simulator destination was ambiguous or unavailable.

## AI Analysis Prompt Requirements

Prompt AI to return:

1. overall status
2. failing phase
3. findings with quoted log evidence
4. smallest next action
5. missing context

Require the model to separate primary errors from follow-on noise and to avoid inventing files, symbols, tests, or build settings.

## Validation

After creating or changing a research demo:

```bash
cd demo-name
xcodegen generate
./scripts/collect_logs.sh
```

If the collection script fails, keep the produced logs. Failed logs are valid research artifacts, but document the cause in the final response.

