# AsyncStream Continuation Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建一个独立 SwiftUI iOS demo，用按钮触发 `AsyncStream` lifecycle，并通过 Xcode/Simulator console 的 `Logger` 输出解释 continuation、`yield`、`finish`、cancel、`onTermination`、`deinit` 与内存释放关系。

**Architecture:** 新 demo 使用 XcodeGen 生成独立 app target 和 Swift Testing test target。UI 只负责触发动作和展示状态；`StreamDemoViewModel` 管理 consumer task；`AsyncEventSource` actor 管理 stream、continuation、producer task 和 cleanup。生命周期事件统一走 `DemoLogging`，生产代码使用 `OSLog.Logger`，测试使用 silent logger。

**Tech Stack:** SwiftUI, Swift 6.0, iOS 26.0, Swift Concurrency, AsyncStream, Observation, OSLog Logger, Swift Testing, XcodeGen, XcodeBuildMCP。

**Post-review update:** 实现后已把 demo 源码重组到 `App/`、`Domain/`、`Features/StreamDemo/`、`Support/` 目录；`Drop Owner` 也从直接 `source = nil` 改为显式 `finish` → 取消 consumer task → 释放 owner。

## Global Constraints

- Demo 目录必须是 `async-stream-continuation-demo/`。
- App 与 scheme 名称必须是 `AsyncStreamContinuationDemo`。
- Bundle ID prefix 必须是 `com.huahuahu.demo`。
- Deployment target 必须是 iOS `26.0`。
- Swift version 必须是 `6.0`。
- 不引入第三方框架。
- 不做内置实时日志列表；关键事件只打到 Xcode console、Simulator console 或系统日志。
- 使用 `AsyncStream.makeStream(of:bufferingPolicy:)`，buffering policy 使用 `.bufferingNewest(10)`。
- `deinit` 只做日志和兜底取消，不能成为唯一 cleanup 路径；核心 cleanup 必须走 `onTermination` 和显式 `finish()`。
- 新单元测试使用 Swift Testing，不使用 XCTest。
- 首次 XcodeBuildMCP build/run/test 前必须调用 `session_show_defaults`；如果 active defaults 与 `.xcodebuildmcp/config.yaml` 不一致，先用 `session_set_defaults` 应用新 demo defaults。
- 验证 build/test/run 使用 XcodeBuildMCP MCP tools，不使用命令行 `xcodebuildmcp`。

---

## File Structure

Create:

- `async-stream-continuation-demo/README.md` — demo 目标、讲解重点、生成/运行/测试/查看日志方式、关键文件说明。
- `async-stream-continuation-demo/project.yml` — XcodeGen 项目定义。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/App/AsyncStreamContinuationDemoApp.swift` — app entry point。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/Features/StreamDemo/ContentView.swift` — SwiftUI 首屏和按钮。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/Features/StreamDemo/StreamDemoViewModel.swift` — UI action、consumer task、source ownership。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/Features/StreamDemo/DemoStatus.swift` — UI 状态枚举和展示文案。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/Domain/StreamEvent.swift` — stream event value type。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/Domain/EventSourceSnapshot.swift` — 测试可读取的 source 状态快照。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/Support/DemoLogging.swift` — logging abstraction、`SystemDemoLogger`、`SilentDemoLogger`。
- `async-stream-continuation-demo/AsyncStreamContinuationDemo/Domain/AsyncEventSource.swift` — `AsyncStream`、continuation、producer、cleanup 核心实现。
- `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/Domain/StreamEventTests.swift` — event/status 基础测试。
- `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/Domain/AsyncEventSourceTests.swift` — stream lifecycle 测试。
- `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/Features/StreamDemoViewModelTests.swift` — view model action 状态测试。
- `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/Support/AsyncTestSupport.swift` — async timeout/polling helper。

Modify:

- `.xcodebuildmcp/config.yaml` — 指向新 demo 的 project、scheme 和专用 simulator。

Generated:

- `async-stream-continuation-demo/AsyncStreamContinuationDemo.xcodeproj` — 由 `xcodegen generate` 生成并保留。

---

### Task 1: Scaffold the XcodeGen demo shell

**Files:**
- Create: `async-stream-continuation-demo/README.md`
- Create: `async-stream-continuation-demo/project.yml`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/AsyncStreamContinuationDemoApp.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/ContentView.swift`
- Modify: `.xcodebuildmcp/config.yaml`

**Interfaces:**
- Produces: XcodeGen project definition, a compiling SwiftUI app shell, a dedicated simulator, and root XcodeBuildMCP defaults for this demo.
- Later tasks replace `ContentView` body with the interactive UI and add app logic files.

- [ ] **Step 1: Create directories**

Run:

```bash
mkdir -p async-stream-continuation-demo/AsyncStreamContinuationDemo async-stream-continuation-demo/AsyncStreamContinuationDemoTests
```

Expected: directories exist under `async-stream-continuation-demo/`.

- [ ] **Step 2: Add `project.yml`**

Create `async-stream-continuation-demo/project.yml`:

```yaml
name: "AsyncStreamContinuationDemo"
options:
  bundleIdPrefix: "com.huahuahu.demo"
  deploymentTarget:
    iOS: "26.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    DEVELOPMENT_TEAM: ""
targets:
  "AsyncStreamContinuationDemo":
    type: application
    platform: iOS
    sources:
      - "AsyncStreamContinuationDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.AsyncStreamContinuationDemo"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
    scheme:
      testTargets:
        - "AsyncStreamContinuationDemoTests"
  "AsyncStreamContinuationDemoTests":
    type: bundle.unit-test
    platform: iOS
    sources:
      - "AsyncStreamContinuationDemoTests"
    dependencies:
      - target: "AsyncStreamContinuationDemo"
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: "com.huahuahu.demo.AsyncStreamContinuationDemoTests"
```

- [ ] **Step 3: Add app entry point**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/AsyncStreamContinuationDemoApp.swift`:

```swift
import SwiftUI

@main
struct AsyncStreamContinuationDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 4: Add temporary `ContentView`**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.trianglehead.2.clockwise")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text("AsyncStream Continuation Demo")
                .font(.title)
                .fontWeight(.semibold)

            Text("Use this demo to observe AsyncStream lifecycle logs in Xcode or Simulator console.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 5: Add README**

Create `async-stream-continuation-demo/README.md`:

```markdown
# AsyncStream Continuation Demo

A focused SwiftUI demo for understanding how `AsyncStream` and its `Continuation` work together.

## Blog Topic

Explaining `AsyncStream`, continuation lifecycle, `yield`, `finish`, cancellation, `onTermination`, and memory management cleanup.

## Requirements

- Xcode with iOS Simulator support
- iOS 26.0 SDK
- Swift 6.0
- XcodeGen
- XcodeBuildMCP for simulator validation

## Generate

```bash
xcodegen generate
```

## Run

```bash
open AsyncStreamContinuationDemo.xcodeproj
```

Run the `AsyncStreamContinuationDemo` scheme on the dedicated simulator configured in the repository root `.xcodebuildmcp/config.yaml`.

## Logs

The app intentionally does not render a live log list. Open Xcode's debug console, Simulator console, or system log output and filter for:

```text
com.huahuahu.demo.AsyncStreamContinuationDemo
```

Important log points include stream creation, continuation storage, `yield` result, consumer receive, cancel, finish, `onTermination`, cleanup, and `deinit`.

## Test

Use XcodeBuildMCP with the checked-in `.xcodebuildmcp/config.yaml` defaults, or run the equivalent Xcode test action for the `AsyncStreamContinuationDemo` scheme.

## Key Files

- `AsyncStreamContinuationDemo/AsyncEventSource.swift` owns `AsyncStream`, continuation, producer task, and cleanup.
- `AsyncStreamContinuationDemo/StreamDemoViewModel.swift` owns user actions and the consumer task.
- `AsyncStreamContinuationDemo/ContentView.swift` provides the focused SwiftUI controls.
- `AsyncStreamContinuationDemoTests/` verifies lifecycle behavior with Swift Testing.
```

- [ ] **Step 6: Generate the project**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Expected: command exits 0 and creates `async-stream-continuation-demo/AsyncStreamContinuationDemo.xcodeproj`.

- [ ] **Step 7: Confirm available simulator identifiers**

Run:

```bash
xcrun simctl list devicetypes | rg "iPhone 17 Pro Max"
xcrun simctl list runtimes | rg "iOS 26.5"
```

Expected output includes:

```text
iPhone 17 Pro Max (com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max)
iOS 26.5 (26.5 - 23F5053f) - com.apple.CoreSimulator.SimRuntime.iOS-26-5
```

- [ ] **Step 8: Create the dedicated simulator**

Run:

```bash
SIMULATOR_ID=$(xcrun simctl create "AsyncStreamContinuationDemo iPhone 17 Pro Max" "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max" "com.apple.CoreSimulator.SimRuntime.iOS-26-5")
printf '%s\n' "$SIMULATOR_ID" > /tmp/async-stream-continuation-demo-simulator-id
printf 'Created simulator %s\n' "$SIMULATOR_ID"
```

Expected: command prints `Created simulator ` followed by one UUID, and `/tmp/async-stream-continuation-demo-simulator-id` contains that same UUID.

- [ ] **Step 9: Update root XcodeBuildMCP config**

Run:

```bash
SIMULATOR_ID=$(cat /tmp/async-stream-continuation-demo-simulator-id)
SIMULATOR_ID="$SIMULATOR_ID" ruby -e '
simulator_id = ENV.fetch("SIMULATOR_ID")
File.write(".xcodebuildmcp/config.yaml", <<~YAML)
schemaVersion: 1
enabledWorkflows:
  - simulator
  - debugging
  - logging
  - ui-automation
  - utilities
  - xcode-ide
debug: true
sentryDisabled: false
sessionDefaults:
  projectPath: async-stream-continuation-demo/AsyncStreamContinuationDemo.xcodeproj
  scheme: AsyncStreamContinuationDemo
  simulatorName: AsyncStreamContinuationDemo iPhone 17 Pro Max
  simulatorId: #{simulator_id}
YAML
'
```

Expected: `.xcodebuildmcp/config.yaml` contains the simulator UUID from Step 8 in `sessionDefaults.simulatorId`.

- [ ] **Step 10: Show and apply active XcodeBuildMCP defaults**

Use XcodeBuildMCP MCP tool:

```text
session_show_defaults
```

If active defaults do not match `.xcodebuildmcp/config.yaml`, use XcodeBuildMCP MCP tool:

```text
session_set_defaults
projectPath: async-stream-continuation-demo/AsyncStreamContinuationDemo.xcodeproj
scheme: AsyncStreamContinuationDemo
simulatorName: AsyncStreamContinuationDemo iPhone 17 Pro Max
simulatorId: the UUID stored in .xcodebuildmcp/config.yaml
```

Expected: active defaults match the root config before any MCP build/run/test call.

- [ ] **Step 11: Commit scaffold and MCP config**

Run:

```bash
git add async-stream-continuation-demo
git add .xcodebuildmcp/config.yaml
git commit -m "feat: scaffold async stream continuation demo" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

Expected: commit includes README, project.yml, app shell files, generated `.xcodeproj`, and root XcodeBuildMCP config for the new demo.

---

### Task 2: Add event, status, and logging primitives

**Files:**
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/StreamEvent.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/DemoStatus.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/DemoLogging.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/EventSourceSnapshot.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/StreamEventTests.swift`

**Interfaces:**
- Produces: `StreamEvent`, `DemoStatus`, `EventSourceSnapshot`, `DemoLogging`, `SystemDemoLogger`, `SilentDemoLogger`.
- Later tasks consume:
  - `StreamEvent(id:createdAt:message:)`
  - `StreamEvent.logDescription: String`
  - `DemoStatus.title: String`
  - `DemoStatus.detail: String`
  - `DemoLogging.debug(_:)`
  - `DemoLogging.info(_:)`
  - `EventSourceSnapshot(yieldAttemptCount:deliveredOrBufferedCount:cleanupCount:isFinished:isProducing:)`

- [ ] **Step 1: Write failing tests**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/StreamEventTests.swift`:

```swift
import Foundation
import Testing
@testable import AsyncStreamContinuationDemo

struct StreamEventTests {
    @Test
    func logDescriptionIncludesIdentifierAndMessage() {
        let event = StreamEvent(
            id: 3,
            createdAt: Date(timeIntervalSince1970: 0),
            message: "manual sample"
        )

        #expect(event.logDescription == "#3 manual sample")
    }

    @Test
    func statusTextExplainsTheCurrentLifecycleState() {
        #expect(DemoStatus.idle.title == "Idle")
        #expect(DemoStatus.running(lastEvent: "Event 1").title == "Running")
        #expect(DemoStatus.cancelled.title == "Cancelled")
        #expect(DemoStatus.finished.title == "Finished")
        #expect(DemoStatus.released.title == "Owner Released")

        #expect(DemoStatus.running(lastEvent: "Event 1").detail == "Latest event: Event 1")
        #expect(DemoStatus.running(lastEvent: nil).detail == "Waiting for the producer to yield.")
    }

    @Test
    func eventSourceSnapshotReportsLifecycleState() {
        let snapshot = EventSourceSnapshot(
            yieldAttemptCount: 2,
            deliveredOrBufferedCount: 1,
            cleanupCount: 1,
            isFinished: true,
            isProducing: false
        )

        #expect(snapshot.yieldAttemptCount == 2)
        #expect(snapshot.deliveredOrBufferedCount == 1)
        #expect(snapshot.cleanupCount == 1)
        #expect(snapshot.isFinished)
        #expect(snapshot.isProducing == false)
    }
}
```

- [ ] **Step 2: Run tests and verify they fail because types do not exist**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Then use XcodeBuildMCP MCP tool:

```text
test_sim
extraArgs: ["-only-testing:AsyncStreamContinuationDemoTests/StreamEventTests"]
```

Expected: FAIL with compiler errors mentioning missing `StreamEvent`, `DemoStatus`, or `EventSourceSnapshot`.

- [ ] **Step 3: Implement `StreamEvent`**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/StreamEvent.swift`:

```swift
import Foundation

struct StreamEvent: Equatable, Identifiable, Sendable {
    let id: Int
    let createdAt: Date
    let message: String

    init(id: Int, createdAt: Date = .now, message: String) {
        self.id = id
        self.createdAt = createdAt
        self.message = message
    }

    var logDescription: String {
        "#\(id) \(message)"
    }
}
```

- [ ] **Step 4: Implement `DemoStatus`**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/DemoStatus.swift`:

```swift
enum DemoStatus: Equatable, Sendable {
    case idle
    case running(lastEvent: String?)
    case cancelled
    case finished
    case released

    var title: String {
        switch self {
        case .idle:
            "Idle"
        case .running:
            "Running"
        case .cancelled:
            "Cancelled"
        case .finished:
            "Finished"
        case .released:
            "Owner Released"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            "Tap Start Stream to create an AsyncStream and store its continuation."
        case .running(let lastEvent):
            if let lastEvent {
                "Latest event: \(lastEvent)"
            } else {
                "Waiting for the producer to yield."
            }
        case .cancelled:
            "The consumer task was cancelled. Watch for onTermination cleanup in the console."
        case .finished:
            "The producer called finish(). The for-await loop can end normally."
        case .released:
            "The view model released its source reference. Cleanup should still be explicit."
        }
    }
}
```

- [ ] **Step 5: Implement logging abstraction**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/DemoLogging.swift`:

```swift
import OSLog

protocol DemoLogging: Sendable {
    func debug(_ message: String)
    func info(_ message: String)
}

struct SystemDemoLogger: DemoLogging {
    private let logger: Logger

    init(category: String) {
        logger = Logger(
            subsystem: "com.huahuahu.demo.AsyncStreamContinuationDemo",
            category: category
        )
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
}

struct SilentDemoLogger: DemoLogging {
    func debug(_ message: String) {}

    func info(_ message: String) {}
}
```

- [ ] **Step 6: Implement source snapshot**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/EventSourceSnapshot.swift`:

```swift
struct EventSourceSnapshot: Equatable, Sendable {
    let yieldAttemptCount: Int
    let deliveredOrBufferedCount: Int
    let cleanupCount: Int
    let isFinished: Bool
    let isProducing: Bool
}
```

- [ ] **Step 7: Run tests and verify they pass**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Then use XcodeBuildMCP MCP tool:

```text
test_sim
extraArgs: ["-only-testing:AsyncStreamContinuationDemoTests/StreamEventTests"]
```

Expected: PASS for `StreamEventTests`.

- [ ] **Step 8: Commit primitives**

Run:

```bash
git add async-stream-continuation-demo
git commit -m "feat: add async stream demo primitives" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

Expected: commit includes event, status, snapshot, logging, and tests.

---

### Task 3: Implement AsyncEventSource lifecycle

**Files:**
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/AsyncEventSource.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/AsyncTestSupport.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/AsyncEventSourceTests.swift`

**Interfaces:**
- Consumes: `StreamEvent`, `EventSourceSnapshot`, `DemoLogging`, `SystemDemoLogger`, `SilentDemoLogger`.
- Produces:
  - `actor AsyncEventSource`
  - `nonisolated let events: AsyncStream<StreamEvent>`
  - `init(logger: any DemoLogging = SystemDemoLogger(category: "EventSource"), bufferingPolicy: AsyncStream<StreamEvent>.Continuation.BufferingPolicy = .bufferingNewest(10))`
  - `func startProducing(interval: Duration = .milliseconds(700))`
  - `@discardableResult func emitNext() -> AsyncStream<StreamEvent>.Continuation.YieldResult`
  - `func finish()`
  - `func snapshot() -> EventSourceSnapshot`

- [ ] **Step 1: Add async test support**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/AsyncTestSupport.swift`:

```swift
import Foundation

enum AsyncTestTimeoutError: Error, Equatable {
    case timedOut
}

enum AsyncTestSupport {
    static func value<T: Sendable>(
        timeout: Duration = .seconds(1),
        operation: @escaping @Sendable () async -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try await Task.sleep(for: timeout)
                throw AsyncTestTimeoutError.timedOut
            }

            guard let result = try await group.next() else {
                throw AsyncTestTimeoutError.timedOut
            }

            group.cancelAll()
            return result
        }
    }

    static func waitUntil(
        attempts: Int = 200,
        delay: Duration = .milliseconds(5),
        condition: @escaping @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<attempts {
            if await condition() {
                return true
            }

            try? await Task.sleep(for: delay)
        }

        return false
    }
}
```

- [ ] **Step 2: Write failing lifecycle tests**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/AsyncEventSourceTests.swift`:

```swift
import Testing
@testable import AsyncStreamContinuationDemo

struct AsyncEventSourceTests {
    @Test(.timeLimit(.minutes(1)))
    func emitNextProducesTheFirstEvent() async throws {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let eventTask = Task<StreamEvent?, Never> {
            var iterator = source.events.makeAsyncIterator()
            return await iterator.next()
        }

        _ = await source.emitNext()

        let event = try await AsyncTestSupport.value {
            await eventTask.value
        }
        let unwrappedEvent = try #require(event)

        #expect(unwrappedEvent.id == 1)
        #expect(unwrappedEvent.message == "Event 1")

        let snapshot = await source.snapshot()
        #expect(snapshot.yieldAttemptCount == 1)
        #expect(snapshot.deliveredOrBufferedCount == 1)

        await source.finish()
    }

    @Test(.timeLimit(.minutes(1)))
    func finishEndsTheStreamAndRunsCleanup() async throws {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let eventTask = Task<StreamEvent?, Never> {
            var iterator = source.events.makeAsyncIterator()
            return await iterator.next()
        }

        await source.finish()

        let event = try await AsyncTestSupport.value {
            await eventTask.value
        }

        #expect(event == nil)

        let cleanedUp = await AsyncTestSupport.waitUntil {
            let snapshot = await source.snapshot()
            return snapshot.cleanupCount == 1 && snapshot.isProducing == false
        }

        #expect(cleanedUp)

        let snapshot = await source.snapshot()
        #expect(snapshot.isFinished)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingTheConsumerRunsTerminationCleanup() async {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let consumer = Task<Void, Never> {
            for await _ in source.events {}
        }

        await Task.yield()
        consumer.cancel()

        let cleanedUp = await AsyncTestSupport.waitUntil {
            let snapshot = await source.snapshot()
            return snapshot.cleanupCount == 1
        }

        #expect(cleanedUp)
        #expect(consumer.isCancelled)
    }

    @Test(.timeLimit(.minutes(1)))
    func cleanupStopsTheProducerTask() async {
        let source = AsyncEventSource(logger: SilentDemoLogger())

        await source.startProducing(interval: .milliseconds(10))

        let startedSnapshot = await source.snapshot()
        #expect(startedSnapshot.isProducing)

        await source.finish()

        let stopped = await AsyncTestSupport.waitUntil {
            let snapshot = await source.snapshot()
            return snapshot.cleanupCount == 1 && snapshot.isProducing == false
        }

        #expect(stopped)
    }
}
```

- [ ] **Step 3: Run tests and verify they fail because `AsyncEventSource` does not exist**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Then use XcodeBuildMCP MCP tool:

```text
test_sim
extraArgs: ["-only-testing:AsyncStreamContinuationDemoTests/AsyncEventSourceTests"]
```

Expected: FAIL with compiler errors mentioning missing `AsyncEventSource`.

- [ ] **Step 4: Implement `AsyncEventSource`**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/AsyncEventSource.swift`:

```swift
import Foundation

actor AsyncEventSource {
    typealias Continuation = AsyncStream<StreamEvent>.Continuation

    nonisolated let events: AsyncStream<StreamEvent>

    private let continuation: Continuation
    private let logger: any DemoLogging
    private var nextEventID = 1
    private var producerTask: Task<Void, Never>?
    private var cleanedUp = false
    private var finished = false
    private var yieldAttemptCount = 0
    private var deliveredOrBufferedCount = 0
    private var cleanupCount = 0

    init(
        logger: any DemoLogging = SystemDemoLogger(category: "EventSource"),
        bufferingPolicy: Continuation.BufferingPolicy = .bufferingNewest(10)
    ) {
        self.logger = logger
        let streamPair = AsyncStream.makeStream(
            of: StreamEvent.self,
            bufferingPolicy: bufferingPolicy
        )
        events = streamPair.stream
        continuation = streamPair.continuation

        logger.info("stream created")
        logger.info("continuation stored")

        continuation.onTermination = { [weak self] termination in
            Task {
                await self?.handleTermination(termination)
            }
        }
    }

    deinit {
        logger.info("source deinit")
        producerTask?.cancel()
    }

    func startProducing(interval: Duration = .milliseconds(700)) {
        guard producerTask == nil else {
            logger.debug("producer task already running")
            return
        }

        logger.info("producer task started")
        producerTask = Task { [weak self] in
            while Task.isCancelled == false {
                _ = await self?.emitNext()

                do {
                    try await Task.sleep(for: interval)
                } catch {
                    break
                }
            }
        }
    }

    @discardableResult
    func emitNext() -> Continuation.YieldResult {
        let event = StreamEvent(id: nextEventID, message: "Event \(nextEventID)")
        nextEventID += 1
        yieldAttemptCount += 1

        logger.debug("yield requested \(event.logDescription)")
        let result = continuation.yield(event)
        logger.debug("yield result \(describe(result))")

        switch result {
        case .enqueued:
            deliveredOrBufferedCount += 1
        case .dropped:
            deliveredOrBufferedCount += 1
        case .terminated:
            cleanup(reason: "yield returned terminated")
        @unknown default:
            logger.info("yield returned an unknown result")
        }

        return result
    }

    func finish() {
        guard finished == false else {
            logger.debug("finish requested after stream already finished")
            return
        }

        finished = true
        logger.info("finish requested")
        continuation.finish()
        cleanup(reason: "finish requested")
    }

    func snapshot() -> EventSourceSnapshot {
        EventSourceSnapshot(
            yieldAttemptCount: yieldAttemptCount,
            deliveredOrBufferedCount: deliveredOrBufferedCount,
            cleanupCount: cleanupCount,
            isFinished: finished,
            isProducing: producerTask != nil
        )
    }

    private func handleTermination(_ termination: Continuation.Termination) {
        logger.info("continuation onTermination reason \(String(describing: termination))")
        cleanup(reason: "termination \(String(describing: termination))")
    }

    private func cleanup(reason: String) {
        guard cleanedUp == false else {
            logger.debug("cleanup skipped because it already ran")
            return
        }

        cleanedUp = true
        cleanupCount += 1
        logger.info("cleanup started reason=\(reason)")
        producerTask?.cancel()
        producerTask = nil
        logger.info("cleanup completed")
    }

    private func describe(_ result: Continuation.YieldResult) -> String {
        switch result {
        case .enqueued(let remaining):
            "enqueued remaining=\(remaining)"
        case .dropped(let event):
            "dropped \(event.logDescription)"
        case .terminated:
            "terminated"
        @unknown default:
            "unknown"
        }
    }
}
```

- [ ] **Step 5: Run lifecycle tests and verify they pass**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Then use XcodeBuildMCP MCP tool:

```text
test_sim
extraArgs: ["-only-testing:AsyncStreamContinuationDemoTests/AsyncEventSourceTests"]
```

Expected: PASS for `AsyncEventSourceTests`.

- [ ] **Step 6: Commit event source**

Run:

```bash
git add async-stream-continuation-demo
git commit -m "feat: add async event source lifecycle" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

Expected: commit includes `AsyncEventSource`, async test support, and lifecycle tests.

---

### Task 4: Add the view model and interactive SwiftUI controls

**Files:**
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemo/StreamDemoViewModel.swift`
- Modify: `async-stream-continuation-demo/AsyncStreamContinuationDemo/ContentView.swift`
- Create: `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/StreamDemoViewModelTests.swift`

**Interfaces:**
- Consumes: `AsyncEventSource`, `DemoStatus`, `DemoLogging`, `SystemDemoLogger`, `SilentDemoLogger`.
- Produces:
  - `@MainActor @Observable final class StreamDemoViewModel`
  - `private(set) var status: DemoStatus`
  - `func startStream()`
  - `func cancelConsumer()`
  - `func finishProducer()`
  - `func dropOwner()`
  - `var canCancel: Bool`
  - `var canFinish: Bool`
  - `var canDropOwner: Bool`

- [ ] **Step 1: Write failing view model tests**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemoTests/StreamDemoViewModelTests.swift`:

```swift
import Testing
@testable import AsyncStreamContinuationDemo

@MainActor
struct StreamDemoViewModelTests {
    @Test
    func startStreamMovesToRunning() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()

        #expect(viewModel.status == .running(lastEvent: nil))
        #expect(viewModel.canCancel)
        #expect(viewModel.canFinish)
        #expect(viewModel.canDropOwner)

        viewModel.cancelConsumer()
    }

    @Test
    func cancelConsumerMovesToCancelled() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()
        viewModel.cancelConsumer()

        #expect(viewModel.status == .cancelled)
        #expect(viewModel.canCancel == false)
    }

    @Test
    func finishProducerMovesToFinished() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()
        viewModel.finishProducer()

        #expect(viewModel.status == .finished)
    }

    @Test
    func dropOwnerMovesToReleased() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()
        viewModel.dropOwner()

        #expect(viewModel.status == .released)
        #expect(viewModel.canDropOwner == false)

        viewModel.cancelConsumer()
    }
}
```

- [ ] **Step 2: Run tests and verify they fail because `StreamDemoViewModel` does not exist**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Then use XcodeBuildMCP MCP tool:

```text
test_sim
extraArgs: ["-only-testing:AsyncStreamContinuationDemoTests/StreamDemoViewModelTests"]
```

Expected: FAIL with compiler errors mentioning missing `StreamDemoViewModel`.

- [ ] **Step 3: Implement `StreamDemoViewModel`**

Create `async-stream-continuation-demo/AsyncStreamContinuationDemo/StreamDemoViewModel.swift`:

```swift
import Observation

@MainActor
@Observable
final class StreamDemoViewModel {
    typealias SourceFactory = @Sendable () -> AsyncEventSource

    private(set) var status: DemoStatus = .idle

    private var source: AsyncEventSource?
    private var consumerTask: Task<Void, Never>?
    private let logger: any DemoLogging
    private let sourceFactory: SourceFactory

    init(
        logger: any DemoLogging = SystemDemoLogger(category: "ViewModel"),
        sourceFactory: @escaping SourceFactory = {
            AsyncEventSource(logger: SystemDemoLogger(category: "EventSource"))
        }
    ) {
        self.logger = logger
        self.sourceFactory = sourceFactory
    }

    deinit {
        logger.info("view model deinit")
        consumerTask?.cancel()
    }

    var canCancel: Bool {
        consumerTask != nil
    }

    var canFinish: Bool {
        source != nil
    }

    var canDropOwner: Bool {
        source != nil
    }

    func startStream() {
        consumerTask?.cancel()

        let source = sourceFactory()
        self.source = source
        status = .running(lastEvent: nil)

        let events = source.events
        logger.info("consumer task started")

        consumerTask = Task { [weak self, logger] in
            for await event in events {
                logger.info("consumer received event \(event.logDescription)")
                await MainActor.run {
                    self?.status = .running(lastEvent: event.message)
                }
            }

            logger.info("for-await loop ended")
            await MainActor.run {
                guard case .running = self?.status else {
                    return
                }

                self?.status = .finished
            }
        }

        Task {
            await source.startProducing()
        }
    }

    func cancelConsumer() {
        logger.info("cancel requested")
        consumerTask?.cancel()
        consumerTask = nil
        status = .cancelled
    }

    func finishProducer() async {
        logger.info("finish requested")
        guard let source else {
            consumerTask?.cancel()
            consumerTask = nil
            status = .finished
            return
        }

        await source.finish()
        consumerTask?.cancel()
        consumerTask = nil
        status = .finished
    }

    func dropOwner() async {
        logger.info("drop owner requested")
        if let source {
            logger.info("finishing source before owner release")
            await source.finish()
        }

        consumerTask?.cancel()
        consumerTask = nil
        source = nil
        logger.info("source owner released")
        status = .released
    }
}
```

- [ ] **Step 4: Replace `ContentView` with the interactive UI**

Replace `async-stream-continuation-demo/AsyncStreamContinuationDemo/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @State private var viewModel = StreamDemoViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    explanation
                    statusCard
                    controls
                    logHint
                }
                .padding()
            }
            .navigationTitle("AsyncStream")
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AsyncStream + Continuation")
                .font(.title.bold())

            Text("The source owns the continuation and yields values. The consumer owns a task that reads the stream with for-await. Watch the console to see when finish, cancellation, onTermination, cleanup, and deinit happen.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.status.title)
                .font(.headline)

            Text(viewModel.status.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button("Start Stream", systemImage: "play.fill") {
                viewModel.startStream()
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel Consumer", systemImage: "xmark.circle") {
                viewModel.cancelConsumer()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.canCancel == false)

            Button("Finish Producer", systemImage: "checkmark.circle") {
                viewModel.finishProducer()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.canFinish == false)

            Button("Drop Owner", systemImage: "trash") {
                viewModel.dropOwner()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.canDropOwner == false)
        }
        .frame(maxWidth: .infinity)
    }

    private var logHint: some View {
        Text("Open Xcode or Simulator console and filter for com.huahuahu.demo.AsyncStreamContinuationDemo.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 5: Run view model tests and verify they pass**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Then use XcodeBuildMCP MCP tool:

```text
test_sim
extraArgs: ["-only-testing:AsyncStreamContinuationDemoTests/StreamDemoViewModelTests"]
```

Expected: PASS for `StreamDemoViewModelTests`.

- [ ] **Step 6: Run all XcodeBuildMCP simulator tests for the demo**

Run:

```bash
cd async-stream-continuation-demo && xcodegen generate
```

Then use XcodeBuildMCP MCP tool:

```text
test_sim
```

Expected: PASS for all `AsyncStreamContinuationDemoTests`.

- [ ] **Step 7: Commit UI and view model**

Run:

```bash
git add async-stream-continuation-demo
git commit -m "feat: add async stream demo UI" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

Expected: commit includes view model, interactive SwiftUI UI, and view model tests.

---

### Task 5: Validate with XcodeBuildMCP and verify logs

**Files:**
- No source file changes expected.

**Interfaces:**
- Consumes: `.xcodebuildmcp/config.yaml` from Task 1.
- Produces: verified XcodeBuildMCP test/run evidence.

- [ ] **Step 1: Show active XcodeBuildMCP defaults**

Use XcodeBuildMCP MCP tool:

```text
session_show_defaults
```

Expected active defaults:

```text
projectPath: async-stream-continuation-demo/AsyncStreamContinuationDemo.xcodeproj
scheme: AsyncStreamContinuationDemo
simulatorName: AsyncStreamContinuationDemo iPhone 17 Pro Max
simulatorId: the same UUID stored in .xcodebuildmcp/config.yaml
```

- [ ] **Step 2: Apply defaults if active values are missing or stale**

If Step 1 does not match `.xcodebuildmcp/config.yaml`, use XcodeBuildMCP MCP tool:

```text
session_set_defaults
projectPath: async-stream-continuation-demo/AsyncStreamContinuationDemo.xcodeproj
scheme: AsyncStreamContinuationDemo
simulatorName: AsyncStreamContinuationDemo iPhone 17 Pro Max
simulatorId: the UUID stored in .xcodebuildmcp/config.yaml
```

Expected: active defaults now match the root config.

- [ ] **Step 3: Run simulator tests with XcodeBuildMCP**

Use XcodeBuildMCP MCP tool:

```text
test_sim
```

Expected: build succeeds and all `AsyncStreamContinuationDemoTests` pass.

- [ ] **Step 4: Build and launch the demo with XcodeBuildMCP**

Use XcodeBuildMCP MCP tool:

```text
build_run_sim
```

Expected: app builds, installs, and launches on `AsyncStreamContinuationDemo iPhone 17 Pro Max`. The tool response includes a runtime log file path.

- [ ] **Step 5: Exercise the app manually or through the simulator UI**

In the launched app, tap these buttons:

```text
Start Stream
Finish Producer
Start Stream
Cancel Consumer
Start Stream
Drop Owner
```

Expected status changes:

```text
Running
Finished
Running
Cancelled
Running
Owner Released
```

- [ ] **Step 6: Verify console log points**

Inspect the XcodeBuildMCP runtime log path from Step 4, Xcode console, or Simulator console. Filter for:

```text
com.huahuahu.demo.AsyncStreamContinuationDemo
```

Expected log messages include:

```text
stream created
continuation stored
producer task started
yield requested
yield result
consumer task started
consumer received event
finish requested
cancel requested
for-await loop ended
continuation onTermination reason
cleanup started
cleanup completed
source deinit
view model deinit
```

- [ ] **Step 7: Commit final verification-only adjustments if any were needed**

If no source files changed during validation, skip this step. If a validation fix was necessary, run:

```bash
git add async-stream-continuation-demo .xcodebuildmcp/config.yaml
git commit -m "fix: finalize async stream continuation demo" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

Expected: commit contains only validation-driven fixes.

---

## Self-Review Checklist

- Spec coverage: Tasks 1-5 cover demo directory, README, XcodeGen, SwiftUI controls, `AsyncStream.makeStream`, `.bufferingNewest(10)`, Logger points, cleanup semantics, Swift Testing coverage, dedicated simulator, root XcodeBuildMCP config, and MCP validation.
- Type consistency: `AsyncEventSource`, `StreamDemoViewModel`, `StreamEvent`, `DemoStatus`, `EventSourceSnapshot`, and `DemoLogging` signatures are defined before later tasks consume them.
- Test strategy: Logic tests use Swift Testing, async timeout helpers, `#expect`, and `#require`; no UI tests are added.
- Memory management: The plan makes `onTermination` and `finish()` run cleanup, keeps `deinit` as a fallback, stores/cancels consumer and producer tasks, and logs lifecycle order.
