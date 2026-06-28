# AsyncStream Demo File Organization Design

## 目标

重组 `async-stream-continuation-demo` 的 Swift 文件布局，让磁盘目录和 Xcode Navigator 都能清楚表达 demo 的职责边界。此次变更只调整文件组织和 README 导览，不改变 `AsyncStream` demo 的运行行为、UI 行为、日志语义或测试断言。

当前 app target 的 Swift 文件全部平铺在 `AsyncStreamContinuationDemo/` 下，test target 也全部平铺在 `AsyncStreamContinuationDemoTests/` 下。随着 demo 覆盖 UI、view model、domain model、async source、logging 和 test support，平铺结构会让读者不容易判断应该先看哪些文件，也不利于后续博客引用。

## 推荐结构

App target 调整为：

```text
AsyncStreamContinuationDemo/
  App/
    AsyncStreamContinuationDemoApp.swift
  Domain/
    AsyncEventSource.swift
    EventSourceSnapshot.swift
    StreamEvent.swift
  Features/
    StreamDemo/
      ContentView.swift
      DemoStatus.swift
      StreamDemoViewModel.swift
  Support/
    DemoLogging.swift
```

Test target 调整为：

```text
AsyncStreamContinuationDemoTests/
  Domain/
    AsyncEventSourceTests.swift
    StreamEventTests.swift
  Features/
    StreamDemoViewModelTests.swift
  Support/
    AsyncTestSupport.swift
```

`project.yml` 的 source root 继续指向 target 根目录：

```yaml
sources:
  - "AsyncStreamContinuationDemo"
```

移动文件后重新运行 XcodeGen，生成的 `.xcodeproj` 会按真实目录在 Xcode Navigator 中显示分组。

## 分组职责

### `App/`

只放 app entry point。`AsyncStreamContinuationDemoApp` 负责启动 SwiftUI scene，并把主要界面交给 feature 层。

### `Features/StreamDemo/`

放这个 demo 的交互界面和 presentation state：

- `ContentView`：展示说明、状态和按钮。
- `DemoStatus`：demo 状态枚举和说明文案。
- `StreamDemoViewModel`：响应用户动作，管理 source owner 和 consumer task。

这个目录回答“用户如何操作 demo、UI 如何反映生命周期”。

### `Domain/`

放 `AsyncStream` 教学核心：

- `AsyncEventSource`：封装 continuation、producer task、`yield`、`finish`、`onTermination` cleanup。
- `StreamEvent`：stream 中传递的事件值。
- `EventSourceSnapshot`：测试可读的 source 内部状态快照。

这个目录回答“AsyncStream 和 continuation 是如何工作的”。

### `Support/`

放横切辅助能力：

- `DemoLogging`：系统 Logger 和测试用 silent logger。

它不属于 UI，也不属于核心 domain 行为，但被多个层使用。

## README 导览

README 增加一个简短“代码导览”小节，建议读者按以下顺序阅读：

1. `Domain/AsyncEventSource.swift`
2. `Features/StreamDemo/StreamDemoViewModel.swift`
3. `Features/StreamDemo/ContentView.swift`
4. `Support/DemoLogging.swift`
5. 对应 tests

这样能把学习路径和目录结构对齐。

## 构建与测试

变更步骤：

1. 移动 Swift 文件到新目录。
2. 运行 `xcodegen generate` 更新 `.xcodeproj`。
3. 使用 XcodeBuildMCP 跑 `AsyncStreamContinuationDemo` test suite。

通过标准是 Swift Testing suite 继续全部通过。现有 tests 覆盖 domain lifecycle、view model action 和 value primitives，足以证明移动文件没有破坏 target membership 或 imports。

## 非目标

- 不拆分 Swift 类型。
- 不改变 UI 文案、按钮或日志内容。
- 不改变 `.xcodebuildmcp/config.yaml` 默认 simulator。
- 不新增内置日志列表或新的 runtime 行为。
