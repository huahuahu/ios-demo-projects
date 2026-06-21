# Demo Simulator Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修改 `ios-demo-project-creator` skill，让每次新建 demo 时都创建一个名称与 demo 相关的专属 iPhone 17 Pro Max 模拟器。

**Architecture:** 这是一个 project-local skill 文档和模板变更，不需要新增运行时代码。`SKILL.md` 负责指导 agent 在创建 demo 时创建专属模拟器、捕获 UUID、写入配置；`templates/xcodebuildmcp-config.yaml` 负责提供可替换的 `{SimulatorName}` 和 `{SimulatorId}` 占位符。

**Tech Stack:** Markdown skill 文档、YAML 模板、XcodeBuildMCP 配置、`xcrun simctl`。

## Global Constraints

- `DemoName` 使用现有流程推导出的 PascalCase app 和 scheme 名称。
- 专属模拟器名称必须是 `{DemoName} iPhone 17 Pro Max`。
- 设备类型必须是 iPhone 17 Pro Max，runtime 使用本机可用的最新 iOS runtime。
- `xcrun simctl create` 返回的 UUID 必须写入该 demo 的 `.xcodebuildmcp/config.yaml`。
- 配置模板不能再包含共享的硬编码模拟器 UUID。
- demo 验证继续使用 XcodeBuildMCP MCP 工具。

---

### Task 1: 更新模拟器配置模板

**Files:**
- Modify: `.github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml`

**Interfaces:**
- Consumes: `DemoName` from the skill's existing project-name inference flow.
- Produces: YAML template placeholders `{SimulatorName}` and `{SimulatorId}` for later replacement when creating a demo.

- [ ] **Step 1: Write the failing template check**

Run:

```bash
grep -n "simulatorName: {SimulatorName}" .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml && \
grep -n "simulatorId: {SimulatorId}" .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml && \
! grep -n "62706291-A205-4E42-AD8C-3056825895D4" .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml
```

Expected: FAIL because the template still has `simulatorName: iPhone 17 Pro Max` and the hardcoded UUID.

- [ ] **Step 2: Replace the simulator defaults with placeholders**

Edit `.github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml` so the `sessionDefaults` block is exactly:

```yaml
sessionDefaults:
  projectPath: {DemoName}.xcodeproj
  scheme: {DemoName}
  simulatorName: {SimulatorName}
  simulatorId: {SimulatorId}
```

- [ ] **Step 3: Run the template check**

Run:

```bash
grep -n "simulatorName: {SimulatorName}" .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml && \
grep -n "simulatorId: {SimulatorId}" .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml && \
! grep -n "62706291-A205-4E42-AD8C-3056825895D4" .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml
```

Expected: PASS and print the two placeholder lines.

- [ ] **Step 4: Commit**

```bash
git add .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml
git commit -m "chore: parameterize demo simulator config" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 2: 更新 skill 创建流程

**Files:**
- Modify: `.github/skills/ios-demo-project-creator/SKILL.md`

**Interfaces:**
- Consumes: template placeholders `{DemoName}`, `{SimulatorName}`, and `{SimulatorId}` from Task 1.
- Produces: creation workflow instructions that define `SimulatorName = "{DemoName} iPhone 17 Pro Max"` and `SimulatorId = xcrun simctl create` output.

- [ ] **Step 1: Write the failing workflow checks**

Run:

```bash
grep -n "SimulatorName.*{DemoName} iPhone 17 Pro Max" .github/skills/ios-demo-project-creator/SKILL.md && \
grep -n "xcrun simctl create" .github/skills/ios-demo-project-creator/SKILL.md && \
grep -n "{SimulatorId}" .github/skills/ios-demo-project-creator/SKILL.md && \
grep -n "latest available iOS runtime" .github/skills/ios-demo-project-creator/SKILL.md
```

Expected: FAIL because the current skill does not describe dedicated simulator provisioning or the new placeholders.

- [ ] **Step 2: Update the Creation Workflow section**

In `.github/skills/ios-demo-project-creator/SKILL.md`, replace the existing workflow items 9-11 with these items:

```markdown
9. Create a dedicated iPhone 17 Pro Max simulator for the demo before writing the XcodeBuildMCP config:
   - Set `{SimulatorName}` to `{DemoName} iPhone 17 Pro Max`.
   - Use `xcrun simctl create "{SimulatorName}"` with the iPhone 17 Pro Max device type and the latest available iOS runtime.
   - Capture the returned UUID as `{SimulatorId}`.
10. Add `.xcodebuildmcp/config.yaml` from `templates/xcodebuildmcp-config.yaml` by copying the template and using plain string replacement for `{DemoName}`, `{SimulatorName}`, and `{SimulatorId}`.
11. Use XcodeBuildMCP where available to discover schemes, build, test, run, launch, capture logs, or inspect simulator state.
12. For verification, use XcodeBuildMCP MCP tools rather than command-line `xcodebuildmcp` commands.
```

- [ ] **Step 3: Add a dedicated simulator section**

Insert this section after `## XcodeBuildMCP First` and before `## XcodeBuildMCP Config`:

````markdown
## Dedicated Simulator

Every newly created demo gets its own simulator.

- `{SimulatorName}`: `{DemoName} iPhone 17 Pro Max`
- Device type: iPhone 17 Pro Max
- Runtime: latest available iOS runtime
- `{SimulatorId}`: the UUID returned by `xcrun simctl create`

Use `xcrun simctl list devicetypes` and `xcrun simctl list runtimes` to confirm the exact local identifiers. On this machine, use `com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max` and `com.apple.CoreSimulator.SimRuntime.iOS-26-5`. Create the simulator with the derived name:

```bash
xcrun simctl create "{DemoName} iPhone 17 Pro Max" "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max" "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
```

Copy the returned UUID into `.xcodebuildmcp/config.yaml` as `simulatorId`. Do not reuse the UUID from another demo.
````

- [ ] **Step 4: Update the XcodeBuildMCP Config section**

Replace the existing sentence in `## XcodeBuildMCP Config` with:

```markdown
After generating the Xcode project and creating the dedicated simulator, write `.xcodebuildmcp/config.yaml` inside the demo directory from `templates/xcodebuildmcp-config.yaml`. Replace `{DemoName}` with the inferred PascalCase demo name, `{SimulatorName}` with `{DemoName} iPhone 17 Pro Max`, and `{SimulatorId}` with the UUID returned by `xcrun simctl create`.
```

- [ ] **Step 5: Update the validation fallback destination**

Replace the final fallback sentence's destination from `platform=iOS Simulator,name=iPhone 16 Pro,OS=latest` to:

```text
platform=iOS Simulator,name={DemoName} iPhone 17 Pro Max,OS=latest
```

- [ ] **Step 6: Run the workflow checks**

Run:

```bash
grep -n "SimulatorName.*{DemoName} iPhone 17 Pro Max" .github/skills/ios-demo-project-creator/SKILL.md && \
grep -n "xcrun simctl create" .github/skills/ios-demo-project-creator/SKILL.md && \
grep -n "{SimulatorId}" .github/skills/ios-demo-project-creator/SKILL.md && \
grep -n "latest available iOS runtime" .github/skills/ios-demo-project-creator/SKILL.md
```

Expected: PASS and print matching lines from the updated skill.

- [ ] **Step 7: Commit**

```bash
git add .github/skills/ios-demo-project-creator/SKILL.md
git commit -m "docs: require dedicated demo simulators" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 3: 验证 skill 和模板一致性

**Files:**
- Verify: `.github/skills/ios-demo-project-creator/SKILL.md`
- Verify: `.github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml`

**Interfaces:**
- Consumes: completed Task 1 and Task 2 changes.
- Produces: evidence that the skill and template agree on placeholder names and no shared simulator UUID remains.

- [ ] **Step 1: Run final consistency checks**

Run:

```bash
grep -n "{SimulatorName}" .github/skills/ios-demo-project-creator/SKILL.md .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml && \
grep -n "{SimulatorId}" .github/skills/ios-demo-project-creator/SKILL.md .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml && \
! grep -R "62706291-A205-4E42-AD8C-3056825895D4" .github/skills/ios-demo-project-creator
```

Expected: PASS. The first two commands print matches in both the skill and template, and the final command prints nothing.

- [ ] **Step 2: Review the git diff**

Run:

```bash
git --no-pager diff HEAD~2..HEAD -- .github/skills/ios-demo-project-creator/SKILL.md .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml
```

Expected: Diff shows only the dedicated simulator instructions and template placeholder changes.

- [ ] **Step 3: Commit if final verification required a fix**

If Step 1 or Step 2 required an additional correction, commit that correction:

```bash
git add .github/skills/ios-demo-project-creator/SKILL.md .github/skills/ios-demo-project-creator/templates/xcodebuildmcp-config.yaml
git commit -m "fix: align demo simulator skill placeholders" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
