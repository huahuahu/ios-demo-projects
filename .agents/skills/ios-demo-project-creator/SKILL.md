---
name: ios-demo-project-creator
description: Use this project-local skill when creating or extending any iOS demo project in this repository. Trigger for tasks that ask an AI assistant to add a new demo, scaffold an iOS/Xcode sample, create a SwiftUI/UIKit experiment, make a blog-referenced demo project, configure XcodeGen, use XcodeBuildMCP to discover/build/test/run a demo, or add focused docs/scripts/prompts for a demo.
---

# iOS Demo Project Creator

## Purpose

Create small, reproducible iOS demo projects for this repository. These demos are intended to be linked from blog posts, so each one should be easy to inspect, run, and explain.

Prefer a focused demo over a large app. The first screen should demonstrate the topic directly.

## Default Shape

Use this layout unless the demo has a strong reason to differ:

```text
demo-name/
  README.md
  project.yml
  DemoName/
    App/
    Domain/
    Features/
      MainFeature/
    Support/
  DemoNameTests/
    Domain/
    Features/
    Support/
  scripts/
  docs/
  samples/
```

Use XcodeGen for new scaffolded projects. Generate and keep `.xcodeproj` when the user wants the demo immediately openable from Xcode.

Keep source files grouped by responsibility by default. Do not place all app or test Swift files directly in the target root unless the demo truly has only one or two files.

## Creation Workflow

1. Infer the demo project name from the user's input. Use a short kebab-case directory name and a PascalCase `{DemoName}` app/scheme name derived from the same topic.
2. Create a standalone directory under the repo root.
3. Add `README.md` with the demo goal, corresponding blog topic, setup, run, and test commands.
4. Add `project.yml` from `templates/project.yml` by copying the template and using plain string replacement for `{DemoName}`, `{BundleIdPrefix}`, `{DeploymentTarget}`, `{SwiftVersion}`, and `{DevelopmentTeam}`.
5. Add the smallest SwiftUI or UIKit implementation that demonstrates the topic, using the source organization below.
6. Add focused tests when the demo has logic or behavior worth verifying. Mirror the app source organization in the test target where practical.
7. Add `docs/`, `scripts/`, `samples/`, or `prompts/` only when they support the demo's purpose.
8. Run `xcodegen generate` from the demo directory.
9. Create a dedicated iPhone 17 Pro Max simulator for the demo before writing the XcodeBuildMCP config:
   - Set `{SimulatorName}` to `{DemoName} iPhone 17 Pro Max`.
   - Prefer XcodeBuildMCP CLI/MCP simulator creation if that workflow is available in the current environment.
   - If XcodeBuildMCP cannot create simulators, use `xcrun simctl create "{SimulatorName}"` as a fallback with the iPhone 17 Pro Max device type and the latest available iOS runtime.
   - Capture the returned UUID as `{SimulatorId}`.
10. Update the repository root `.xcodebuildmcp/config.yaml` from `templates/xcodebuildmcp-config.yaml` by copying the template to the root config path and using plain string replacement for `{DemoDirectory}`, `{DemoName}`, `{SimulatorName}`, and `{SimulatorId}`. Use the kebab-case demo directory name for `{DemoDirectory}`. Do not create `demo-name/.xcodebuildmcp/config.yaml`.
11. Use XcodeBuildMCP where available to discover schemes, build, test, run, launch, capture logs, or inspect simulator state. Before using MCP tools in the same session, call `session_set_defaults` with the same root-relative values from the root config when current defaults do not already match.
12. For verification, use XcodeBuildMCP MCP tools rather than command-line `xcodebuildmcp` commands.

## XcodeGen Pattern

Start from `templates/project.yml` and replace placeholders:

- `{DemoName}`: PascalCase app and scheme name, for example `ButtonStyleResearch`
- `{BundleIdPrefix}`: hardcode to `com.huahuahu.demo`
- `{DeploymentTarget}`: hardcode to `26.0`
- `{SwiftVersion}`: hardcode to `6.0`
- `{DevelopmentTeam}`: Apple development team id. Set to an empty string for local simulator demos

The template enables generated Info.plist files for both the app and test targets with `GENERATE_INFOPLIST_FILE: YES`. Adjust deployment target, bundle id, app type, settings, and dependencies to fit the demo.

The template points each target's `sources` at the target root. Keep it that way for normal demos so XcodeGen recursively includes grouped subdirectories and Xcode Navigator reflects the on-disk folders after `xcodegen generate`.

## Source Organization

Use this source layout for new demos unless the demo has a clear reason to differ:

```text
DemoName/
  App/
    DemoNameApp.swift
  Domain/
    Core models, data sources, algorithms, and state types
  Features/
    MainFeature/
      SwiftUI/UIKit views and view models for the primary demo screen
  Support/
    Logging, test doubles shared with previews, adapters, and small helpers

DemoNameTests/
  Domain/
    Tests for core models, data sources, algorithms, and state types
  Features/
    Tests for view models and interaction behavior
  Support/
    Async/test helpers and fixtures
```

Map files by responsibility:

| File role | Default location |
| --- | --- |
| App entry point | `DemoName/App/` |
| SwiftUI/UIKit screen | `DemoName/Features/<FeatureName>/` |
| View model or presentation state | `DemoName/Features/<FeatureName>/` |
| Domain model, event, state enum, data source, service, or algorithm | `DemoName/Domain/` |
| Logger, formatter, adapter, fixture factory, or small cross-cutting helper | `DemoName/Support/` |
| Domain tests | `DemoNameTests/Domain/` |
| View model or interaction tests | `DemoNameTests/Features/` |
| Test-only async helpers, fixtures, and utilities | `DemoNameTests/Support/` |

Prefer a feature directory named after the demo's main concept, such as `StreamDemo`, `LayoutComparison`, or `ObservationFlow`. If there is only one screen and no domain logic, still use `App/` plus one `Features/<FeatureName>/` directory so the project does not start flat.

## XcodeBuildMCP First


Prefer XcodeBuildMCP for:

- project discovery and session defaults
- simulator build/test/run
- app launch with logs
- simulator or device log capture

Use direct `xcodebuild`, `xcrun simctl` only when MCP tools are unavailable or for non-verification fallback evidence.

## Dedicated Simulator

Every newly created demo gets its own simulator.

- `{SimulatorName}`: `{DemoName} iPhone 17 Pro Max`
- Device type: iPhone 17 Pro Max
- Runtime: latest available iOS runtime
- `{SimulatorId}`: the UUID returned by the simulator creation command

Prefer XcodeBuildMCP CLI/MCP simulator creation when the current environment exposes it. If not, fall back to `xcrun simctl` only for simulator creation/discovery. Use `xcrun simctl list devicetypes` and `xcrun simctl list runtimes` to confirm the exact local identifiers. On this machine, use `com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max` and `com.apple.CoreSimulator.SimRuntime.iOS-26-5`. Create the simulator with the derived name:

```bash
xcrun simctl create "{DemoName} iPhone 17 Pro Max" "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max" "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
```

Copy the returned UUID into the repository root `.xcodebuildmcp/config.yaml` as `simulatorId`. Do not reuse the UUID from another demo.

## XcodeBuildMCP Config

After generating the Xcode project and creating the dedicated simulator, update the repository root `.xcodebuildmcp/config.yaml` from `templates/xcodebuildmcp-config.yaml`. Replace `{DemoDirectory}` with the kebab-case demo directory name, `{DemoName}` with the inferred PascalCase demo name, `{SimulatorName}` with `{DemoName} iPhone 17 Pro Max`, and `{SimulatorId}` with the UUID returned by the simulator creation command.

The persisted `projectPath` must be relative to the repository root, for example `demo-name/DemoName.xcodeproj`. Do not write or create `demo-name/.xcodebuildmcp/config.yaml`. If an older demo-local config already exists, leave it untouched unless the user explicitly asks to migrate or remove it.


## Blog-Friendly README

Every demo README should answer:

- What does this demo show?
- Which blog post or topic is it for?
- Which Xcode/iOS versions are expected?
- How do I generate/open the project?
- How do I run or test it?
- Which files matter most?

Keep README concise. Include a short code tour that follows the grouped source layout, such as `Domain/` first for the concept, `Features/` for interaction, and `Support/` for logging/helpers. Put deeper notes in `docs/`.

## Validation

After creating or changing a demo:

```bash
cd demo-name
xcodegen generate
```

Then use XcodeBuildMCP MCP tools, not command-line `xcodebuildmcp`, to validate:

1. `session_show_defaults` to confirm the active MCP defaults match the repository root `.xcodebuildmcp/config.yaml`; if they do not, call `session_set_defaults` with `projectPath: demo-name/{DemoName}.xcodeproj`, `scheme: {DemoName}`, `simulatorName: {DemoName} iPhone 17 Pro Max`, and the dedicated `simulatorId`.
2. `test_sim` to verify can test on the simulator

If XcodeBuildMCP MCP tools are unavailable, fall back to `xcodebuild` with an explicit destination such as `platform=iOS Simulator,name={DemoName} iPhone 17 Pro Max,OS=latest`. If validation fails, inspect the logs and report the specific blocker.
