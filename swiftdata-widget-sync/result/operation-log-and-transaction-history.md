# SwiftData Transaction History 与 OperationLog 调研记录

## 背景问题

这个 demo 原本已经可以通过 SwiftData Transaction History 观察 App 和 Widget 对共享 SwiftData store 的改动。继续调研时遇到一个关键问题：

- Transaction History 可以告诉我们 store 里发生了 insert、update、delete。
- 也可以通过 `HistoryUpdate.updatedAttributes` 知道 update 改了哪些字段。
- 但它不能完整表达“用户到底做了哪个业务操作”。

例如同样是 `ResearchNote.detail` 被更新，可能来自：

- App 点击 `Update Latest`
- Widget 点击 `Update`
- iCloud 同步合并
- 某个后台逻辑自动修正数据

这些业务意图不能只靠 transaction 本身稳定推断。

## 解决思路

本轮采用了“双轨记录”的方式：

1. 使用 SwiftData Transaction History 记录数据层变化。
2. 新增 `OperationLog` 模型记录业务操作意图。

两者分工如下：

- Transaction History：回答“store 里实际变了什么”。
- OperationLog：回答“这次写入为什么发生、用户做了什么”。

## 新增的 OperationLog

新增文件：`SharedNotes/OperationLog.swift`

字段包括：

- `operationName`：业务操作名，例如 `insertNote`、`updateLatestNote`、`deleteSelectedNotes`、`deleteAllNotes`。
- `author`：操作来源，例如 `App` 或 `Widget`，后续也可以扩展成 `App@device-id`。
- `targetIdentifier`：目标 `ResearchNote` 的 persistent model id 字符串。
- `targetTitle`：目标 note 标题，方便日志阅读。
- `noteCount`：本次操作影响的 note 数量。
- `detail`：业务描述。
- `createdAt`：操作发生时间。

## 关键实现

### 1. 扩展 SwiftData schema

`SharedStore.makeModelContainer` 从只注册 `ResearchNote`，升级为同时注册：

```swift
ModelContainer(
    for: ResearchNote.self,
    OperationLog.self,
    configurations: configuration
)
```

这样 App、Widget、测试都能读写同一个共享 store 中的 notes 和 operation logs。

### 2. 写入业务数据时同步写入 OperationLog

在 `SharedStore.insertNote` 中：

- 创建 `ResearchNote`
- 设置 `ModelContext.author`
- 插入 `ResearchNote`
- 同事务插入 `OperationLog(operationName: "insertNote")`
- `context.save()`

`updateLatestNote` 和 `deleteAll` 也采用相同模式。

App 侧的滑动删除不走 `SharedStore.deleteAll`，所以在 `ContentView.deleteNotes` 中单独插入：

```swift
SharedStore.insertOperationLog(
    operationName: "deleteSelectedNotes",
    author: "App",
    target: deletedNotes.first,
    noteCount: deletedNotes.count,
    detail: "Deleted selected notes",
    in: modelContext
)
```

### 3. App UI 显示最近操作日志

`ContentView` 新增：

```swift
@State private var operationLogs: [OperationLog] = []
```

刷新时同时读取：

```swift
notes = try SharedStore.fetchNotes(in: modelContext)
operationLogs = try SharedStore.fetchOperationLogs(in: modelContext)
```

页面新增 `Recent Operation Logs` section，用于直接观察最近业务操作。

### 4. Transaction History 继续记录底层变化

`SharedStoreHistoryMonitor` 保留原来的 transaction history 处理，并增加 `OperationLog` 统计：

- `ResearchNote` insert/update/delete 数量
- `OperationLog` insert 数量

history summary 现在类似：

```text
History: 1 transaction(s), notes +1 ~0 -0, ops 1
```

这可以直接看出一次业务写入通常会产生：

- 1 个 note 变化
- 1 条 operation log 插入

## 同时升级的 author 和 timestamp

### ModelContext.author

写入前统一调用：

```swift
context.author = author
```

这样 transaction history 中可以看到：

```swift
transaction.author
```

当前 demo 使用 `App` / `Widget`，后续要区分设备时可以改成：

```text
App@device-8A2F
Widget@device-8A2F
```

### 时间戳

新增和更新文案中的时间戳升级为毫秒级：

```text
yyyy-MM-dd HH:mm:ss.SSS
```

这样连续快速点击也更容易区分。

## 关于 transactionIdentifier 和 storeIdentifier

调研中确认：

- `transaction.transactionIdentifier` 是 SwiftData/Core Data 为每次 store transaction 生成的标识。
- `transaction.storeIdentifier` 是产生该 transaction 的 backing store 标识。
- 它们是 history 元数据，不适合也不应当作为业务侧自定义标识。
- 如果要区分设备、用户、操作来源，应使用 `ModelContext.author`、`OperationLog` 或模型字段。

## 解决的问题

本轮改动解决了三个问题：

1. 能区分“数据发生了什么变化”。
   - 通过 Transaction History。

2. 能区分“是谁触发了变化”。
   - 通过 `ModelContext.author`。

3. 能区分“用户具体做了什么业务操作”。
   - 通过 `OperationLog.operationName` 和相关字段。

## 主要修改文件

- `SharedNotes/OperationLog.swift`
- `SharedNotes/SharedStore.swift`
- `SwiftDataResearch/ContentView.swift`
- `SwiftDataResearch/SharedStoreHistoryMonitor.swift`
- `SwiftDataResearchTests/SwiftDataResearchTests.swift`
- `README.md`

## 验证

已运行：

```bash
xcodegen generate
xcodebuild build \
  -project SwiftDataResearch.xcodeproj \
  -scheme SwiftDataResearch \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/tigerguo/git/learn\ projects/swiftdata-widget-sync/.derivedData
```

结果：

```text
BUILD SUCCEEDED
```

## 后续可继续调研

- 给每台设备生成稳定 `deviceID`，把 `author` 从 `App` / `Widget` 升级成 `App@deviceID` / `Widget@deviceID`。
- 给 `OperationLog` 增加 `userID`、`sessionID`、`appVersion`。
- 在 `HistoryUpdate.updatedAttributes` 中把具体变更字段映射成可读字段名。
- 对 iCloud 同步合并进来的 transaction，观察 `author`、`bundleIdentifier`、`processIdentifier` 的表现。

 
