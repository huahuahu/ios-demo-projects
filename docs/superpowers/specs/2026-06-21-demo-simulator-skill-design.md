# Demo Simulator Skill Design

## Goal

Update the `ios-demo-project-creator` skill so every newly created demo gets its own iPhone 17 Pro Max simulator whose name is derived from the demo.

## Requirements

- Infer `DemoName` as the existing PascalCase app and scheme name.
- Create a dedicated simulator named `{DemoName} iPhone 17 Pro Max`.
- Use the iPhone 17 Pro Max device type with the latest available iOS runtime.
- Store the returned simulator UUID in that demo's `.xcodebuildmcp/config.yaml`.
- Replace the current fixed simulator name and simulator ID in the config template with placeholders.

## Design

The skill will add a simulator provisioning step after the Xcode project and `.xcodebuildmcp` config template are prepared. The creator should run `xcrun simctl create` for the derived simulator name, capture the UUID, and use it to replace `{SimulatorId}`. The same derived name replaces `{SimulatorName}`.

The XcodeBuildMCP config template will no longer contain a shared hardcoded simulator UUID. Each generated demo receives a config that points to its own simulator, keeping builds, launches, logs, and UI automation isolated per demo.

## Validation

After creating or changing a demo, validation still uses XcodeBuildMCP MCP tools. The generated `.xcodebuildmcp/config.yaml` must contain the demo-specific simulator name and UUID before running `test_sim` or build/run actions.
