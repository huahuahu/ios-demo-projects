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
  DemoName/
  DemoNameTests/
  scripts/
  docs/
  samples/
```

Use XcodeGen for new scaffolded projects. Generate and keep `.xcodeproj` when the user wants the demo immediately openable from Xcode.

## Creation Workflow

1. Pick a short kebab-case directory name that describes the demo topic.
2. Create a standalone directory under the repo root.
3. Add `README.md` with the demo goal, corresponding blog topic, setup, run, and test commands.
4. Add `project.yml` with one iOS app target and one test target unless the user requests another structure.
5. Add the smallest SwiftUI or UIKit implementation that demonstrates the topic.
6. Add focused tests when the demo has logic or behavior worth verifying.
7. Add `docs/`, `scripts/`, `samples/`, or `prompts/` only when they support the demo's purpose.
8. Run `xcodegen generate` from the demo directory.
9. Use XcodeBuildMCP where available to discover schemes, build, test, run, launch, capture logs, or inspect simulator state.
10. Fall back to direct `xcodebuild` and `xcrun simctl` commands when MCP tools are unavailable.

## XcodeGen Pattern

Keep `project.yml` simple and explicit:

```yaml
name: DemoName
options:
  bundleIdPrefix: com.tigerguo.demo
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    SWIFT_VERSION: "5.0"
targets:
  DemoName:
    type: application
    platform: iOS
    sources:
      - DemoName
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.tigerguo.demo.DemoName
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
    scheme:
      testTargets:
        - DemoNameTests
  DemoNameTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - DemoNameTests
    dependencies:
      - target: DemoName
```

Adjust deployment target, bundle id, app type, and dependencies to fit the demo.

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

Use direct `xcodebuild`, `xcrun simctl`, `log show`, and `log stream` as reproducible fallback commands or raw evidence sources.

## Blog-Friendly README

Every demo README should answer:

- What does this demo show?
- Which blog post or topic is it for?
- Which Xcode/iOS versions are expected?
- How do I generate/open the project?
- How do I run or test it?
- Which files matter most?

Keep README concise. Put deeper notes in `docs/`.

## Optional Log Research Pattern

For demos that research AI/Xcode logs, add:

```text
scripts/collect_logs.sh
docs/log-sources.md
prompts/analyze-xcode-logs.md
samples/sample-log-notes.md
```

The collection script should create `artifacts/logs/<timestamp>/`; write raw build/test output, simulator inventory, `.xcresult` summaries, and a short `summary.md`; and use a destination that disambiguates duplicate simulator names:

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'
```

Ignore generated artifacts in `.gitignore`.

## Validation

After creating or changing a demo:

```bash
cd demo-name
xcodegen generate
xcodebuild -project DemoName.xcodeproj -scheme DemoName -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' test
```

If validation fails, inspect the logs and report the specific blocker. Exit code `70` often means the simulator destination is ambiguous or unavailable.

