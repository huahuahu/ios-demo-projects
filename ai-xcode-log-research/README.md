# AI Xcode Log Research

这个 demo project 用来调研：如何通过 XcodeBuildMCP 让 AI 查看、整理和分析 Xcode project 里的日志。

重点不是做一个复杂 App，而是建立一条可重复的日志采集和分析链路：通过 XcodeBuildMCP 运行构建、测试、模拟器和日志捕获，再把相关上下文交给 AI 做摘要、归因和下一步排查建议。

## 研究问题

- AI 应该读取哪些 Xcode 相关日志，才能理解一次构建、测试或运行失败？
- 哪些日志适合直接喂给 AI，哪些需要先裁剪、脱敏或结构化？
- 如何把 XcodeBuildMCP 的 build/test/log capture 工具和必要的 `xcodebuild` fallback 信息组合起来？
- AI 分析日志时，需要怎样的 prompt 才能输出稳定、有用、可执行的结论？

## Project 结构

```text
ai-xcode-log-research/
  project.yml                 # XcodeGen 配置
  LogResearchDemo/            # 示例 iOS App，会主动输出几类日志
  LogResearchDemoTests/       # 示例测试，用于产生 test log
  scripts/collect_logs.sh     # 日志采集脚本
  docs/research-plan.md       # 调研计划
  docs/log-sources.md         # Xcode/iOS 日志来源清单
  prompts/analyze-xcode-logs.md
  samples/sample-log-notes.md
```

## 生成 Xcode project

本目录使用 XcodeGen 生成 `.xcodeproj`：

```bash
cd ai-xcode-log-research
xcodegen generate
```

生成后可以打开：

```bash
open LogResearchDemo.xcodeproj
```

## 采集日志

脚本会收集一次 build/test 的输出，并整理到 `artifacts/logs/`：

```bash
cd ai-xcode-log-research
./scripts/collect_logs.sh
```

默认 scheme 是 `LogResearchDemo`。如果需要指定模拟器：

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' ./scripts/collect_logs.sh
```

如果当前 Codex session 暴露了 XcodeBuildMCP 工具，优先使用它执行 project discovery、simulator build/test 和 log capture；脚本保留为可复现的命令行 fallback。

## AI 分析入口

采集完成后，把 `artifacts/logs/summary.md` 和相关 `.log` 文件交给 AI，并使用 [prompts/analyze-xcode-logs.md](prompts/analyze-xcode-logs.md) 里的 prompt。

## 当前结论假设

初步假设是：AI 不适合直接读取无限长的实时日志流。更可靠的方式是先把日志按阶段、来源、严重级别和时间窗口整理成较小的证据包，再让 AI 做分析。
