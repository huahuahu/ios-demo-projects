---
name: ios-demo-project-creator
description: Use this project-local skill when creating or extending any iOS demo project in this repository. Trigger for tasks that ask Codex to add a new demo, scaffold an iOS/Xcode sample, create a SwiftUI/UIKit experiment, make a blog-referenced demo project, configure XcodeGen, use XcodeBuildMCP to discover/build/test/run a demo, or add focused docs/scripts/prompts for a demo.
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
  .xcodebuildmcp/
    config.yaml
  DemoName/
  DemoNameTests/
  scripts/
  docs/
  samples/
```

Use XcodeGen for new scaffolded projects. Generate and keep `.xcodeproj` when the user wants the demo immediately openable from Xcode.

## Creation Workflow

1. Infer the demo project name from the user's input. Use a short kebab-case directory name and a PascalCase `{DemoName}` app/scheme name derived from the same topic.
2. Create a standalone directory under the repo root.
3. Add `README.md` with the demo goal, corresponding blog topic, setup, run, and test commands.
4. Add `project.yml` from `templates/project.yml` by copying the template and using plain string replacement for `{DemoName}`, `{BundleIdPrefix}`, `{DeploymentTarget}`, `{SwiftVersion}`, and `{DevelopmentTeam}`.
5. Add the smallest SwiftUI or UIKit implementation that demonstrates the topic.
6. Add focused tests when the demo has logic or behavior worth verifying.
7. Add `docs/`, `scripts/`, `samples/`, or `prompts/` only when they support the demo's purpose.
8. Run `xcodegen generate` from the demo directory.
9. Add `.xcodebuildmcp/config.yaml` from `templates/xcodebuildmcp-config.yaml` by copying the template and using plain string replacement for `{DemoName}`.
10. Use XcodeBuildMCP where available to discover schemes, build, test, run, launch, capture logs, or inspect simulator state.
11. For verification, use XcodeBuildMCP MCP tools rather than command-line `xcodebuildmcp` commands.

## XcodeGen Pattern

Start from `templates/project.yml` and replace placeholders:

- `{DemoName}`: PascalCase app and scheme name, for example `ButtonStyleResearch`
- `{BundleIdPrefix}`: hardcode to `com.huahuahu.demo`
- `{DeploymentTarget}`: hardcode to `26.0`
- `{SwiftVersion}`: hardcode to `6.0`
- `{DevelopmentTeam}`: Apple development team id. Set to an empty string for local simulator demos

The template enables generated Info.plist files for both the app and test targets with `GENERATE_INFOPLIST_FILE: YES`. Adjust deployment target, bundle id, app type, settings, and dependencies to fit the demo.

## XcodeBuildMCP First


Prefer XcodeBuildMCP for:

- project discovery and session defaults
- simulator build/test/run
- app launch with logs
- simulator or device log capture

Use direct `xcodebuild`, `xcrun simctl` only when MCP tools are unavailable or for non-verification fallback evidence.

## XcodeBuildMCP Config

After generating the Xcode project, write `.xcodebuildmcp/config.yaml` inside the demo directory from `templates/xcodebuildmcp-config.yaml`. Replace `{DemoName}` with the inferred PascalCase demo name before using it.


## Blog-Friendly README

Every demo README should answer:

- What does this demo show?
- Which blog post or topic is it for?
- Which Xcode/iOS versions are expected?
- How do I generate/open the project?
- How do I run or test it?
- Which files matter most?

Keep README concise. Put deeper notes in `docs/`.

## Validation

After creating or changing a demo:

```bash
cd demo-name
xcodegen generate
```

Then use XcodeBuildMCP MCP tools, not command-line `xcodebuildmcp`, to validate:

1. `test_sim` to verify can test on the simulator

If XcodeBuildMCP MCP tools are unavailable, fall back to `xcodebuild` with an explicit destination such as `platform=iOS Simulator,name=iPhone 16 Pro,OS=latest`. If validation fails, inspect the logs and report the specific blocker.
