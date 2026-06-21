# Demo 模拟器 Skill 设计

## 目标

修改 `ios-demo-project-creator` skill，让每次新建 demo 时都创建一个专属的 iPhone 17 Pro Max 模拟器，模拟器名称和 demo 相关。

## 需求

- 沿用现有流程推导出的 PascalCase app 和 scheme 名称作为 `DemoName`。
- 创建名为 `{DemoName} iPhone 17 Pro Max` 的专属模拟器。
- 使用 iPhone 17 Pro Max 设备类型和本机可用的最新 iOS runtime。
- 将 `xcrun simctl create` 返回的模拟器 UUID 写入该 demo 的 `.xcodebuildmcp/config.yaml`。
- 将当前配置模板里的固定模拟器名称和固定模拟器 UUID 改成占位符。

## 设计

在 skill 的创建流程中，在准备好 Xcode project 和 `.xcodebuildmcp` 配置模板后增加模拟器准备步骤。创建 demo 的 agent 需要用推导出的模拟器名称运行 `xcrun simctl create`，捕获返回的 UUID，并用它替换 `{SimulatorId}`；同一个模拟器名称用于替换 `{SimulatorName}`。

XcodeBuildMCP 配置模板不再包含共享的硬编码模拟器 UUID。每个生成出来的 demo 都会得到一份指向自己专属模拟器的配置，让 build、launch、日志和 UI 自动化都按 demo 隔离。

## 验证

创建或修改 demo 后，验证仍然使用 XcodeBuildMCP MCP 工具。运行 `test_sim` 或 build/run 相关操作前，生成的 `.xcodebuildmcp/config.yaml` 必须包含该 demo 专属的模拟器名称和 UUID。