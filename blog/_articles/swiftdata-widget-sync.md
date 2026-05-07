---
title: 让 App 和 Widget 共享 SwiftData，并追踪每一次写入的来源
description: 用 App Group + SwiftData Transaction History + 自定义 OperationLog 让 iOS App 和 WidgetKit Extension 双向读写同一份数据，并能回答“是谁、做了什么业务操作”。
summary: 一次围绕共享 SwiftData store、Widget 交互写入、Transaction History 与业务级 OperationLog 的实验记录。
category: Investigation
tag: SwiftData
date: 2026-05-07
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/swiftdata-widget-sync
result_url: https://github.com/huahuahu/ios-demo-projects/blob/main/swiftdata-widget-sync/result/operation-log-and-transaction-history.md
---

## 想搞清楚的问题

一个常见但又被低估的需求：iOS App 主体和它的 Widget Extension，能不能读写**同一份** SwiftData store？如果可以，App 这边怎么知道 Widget 改了什么？再进一步——能不能区分清楚某条数据变化到底是**谁、因为什么业务操作**写进去的？

这个 demo (`swiftdata-widget-sync`) 就是为了把这三件事一次性跑通：

1. App 和 Widget 双向读写同一个 SwiftData store。
2. 一边写入、另一边自动感知变化。
3. 不仅记录"数据变成了什么样"，还要能回答"这次写入是哪个业务动作触发的"。

## 背景：为什么不能直接 share

SwiftData 默认 store 在 App 自己的沙盒里，Widget Extension 是**另一个进程**，沙盒不互通。要让两边读写同一份 store，必须把 store 放进双方都能访问的容器：**App Group**。

但即使把存储位置共享了，还有第二层问题：写入是各自进程做的，另一边不会自动刷新 UI。所以还需要一个**跨进程的变更通知**机制 + 一个**变更日志**让接收方能消费这些变化。

第三层问题最容易被忽略：Transaction History 告诉你 store 里"insert / update / delete 了什么"，但它**回答不了"用户做了哪个业务操作"**。同样是 `ResearchNote.detail` 被改写，可能来自 App 的 Update 按钮、来自 Widget 的 Update、也可能来自 iCloud 合并。这一层信息要靠业务自己写。

## 整体方案

这个 demo 用三个机制叠在一起：

| 层 | 机制 | 解决的问题 |
|---|---|---|
| 存储位置共享 | App Group + `ModelConfiguration(url:)` | App 和 Widget 物理上指向同一个 store 文件 |
| 跨进程变更感知 | `NSPersistentStoreRemoteChange` + SwiftData Transaction History | 接收方知道 store 里发生了什么变化 |
| 业务意图记录 | `ModelContext.author` + 自定义 `OperationLog` 模型 | 能回答"谁因为哪个业务动作触发了这次写入" |

下面按这三层展开。

## 一、把 store 放到 App Group

App 和 Widget 各自的 entitlements 都加上同一个 App Group：

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.huahuahu.demo.SwiftDataResearch</string>
</array>
```

然后在共享的代码里把 store 文件路径指过去（`SharedNotes/SharedStore.swift`）：

```swift
static func sharedStoreURL() -> URL? {
    FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
        .appending(path: "SwiftDataResearch.store")
}

static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
    let configuration: ModelConfiguration
    if let storeURL = sharedStoreURL() {
        configuration = ModelConfiguration(url: storeURL)
    } else {
        configuration = ModelConfiguration()
    }
    return try ModelContainer(
        for: ResearchNote.self, OperationLog.self,
        configurations: configuration
    )
}
```

App、Widget、单元测试都通过 `SharedStore.makeModelContainer()` 取容器，schema 也都在共享代码里（`ResearchNote` + `OperationLog`），保证两边的 SwiftData 模型完全一致。

> 待确认：跨 target 共享 `@Model` 类目前直接放在 sources group 里，如果未来 SwiftData 在跨 module 场景下出现 schema identity 不一致的问题，可能需要把模型抽成单独的 Swift Package。

## 二、Widget 也能写：用 AppIntent

Widget 自身不能跑普通的 SwiftUI 按钮 action，但 iOS 17+ 的交互 widget 可以挂 `AppIntent`。这个 demo 在 Widget 里塞了两个按钮，一个 Insert、一个 Update，分别绑到两个 intent (`SwiftDataResearchWidget/WidgetNoteIntents.swift`)：

```swift
struct InsertWidgetNoteIntent: AppIntent {
    @MainActor
    func perform() async throws -> some IntentResult {
        let container = try SharedStore.makeModelContainer()
        let note = try SharedStore.insertNote(source: "Widget", in: container.mainContext)
        return .result()
    }
}
```

关键点：

- Intent 在 **Widget 进程**里直接打开同一个共享 SwiftData container 写入。
- 写入完成后，`SharedStore.insertNote` 会调 `WidgetCenter.shared.reloadTimelines(ofKind:)`，让 Widget 自己也立刻刷新 UI。
- App 那边并不用做任何主动轮询，靠下面的远程通知机制感知。

## 三、跨进程感知：NSPersistentStoreRemoteChange + Transaction History

App 启动后订阅一个跨进程通知（`SwiftDataResearch/ContentView.swift`）：

```swift
for await _ in NotificationCenter.default
    .notifications(named: .NSPersistentStoreRemoteChange) {
    let summary = await monitor.processNewTransactions()
    await MainActor.run {
        lastHistorySummary = summary.operationDescription
        refreshNotes()
    }
}
```

只看到通知是不够的——通知不会告诉你具体变了什么。真正的"变了什么"要从 SwiftData Transaction History 里捞。`SharedStoreHistoryMonitor` 做了三件事：

1. 用上次保存的 `DefaultHistoryToken` 当游标，`fetchHistory` 拉所有新 transaction。
2. 遍历每条 transaction 的 changes，按模型类型分别累加 insert / update / delete 计数。
3. 拉完后保存最新 token，并把上次 token 之前的 history 删掉，防止历史无限堆积。

核心代码：

```swift
private func fetchTransactions(after token: DefaultHistoryToken?) -> [DefaultHistoryTransaction] {
    var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
    if let token {
        descriptor.predicate = #Predicate { transaction in
            transaction.token > token
        }
    }
    return (try? modelContext.fetchHistory(descriptor)) ?? []
}
```

每条 transaction 自带的元数据是这次调研里最值钱的部分：

- `transactionIdentifier`：SwiftData 给每次 store transaction 自动生成的 ID。
- `storeIdentifier`：产生这次 transaction 的 backing store ID。
- `author`：写入方主动设置的标签（看下一节）。
- `bundleIdentifier`、`processIdentifier`：写入进程的 bundle / 进程名，能直接区分 App 和 Widget。
- `timestamp`：写入时间。

> 注意：`transactionIdentifier` / `storeIdentifier` 是 history 元数据，**不应该当成业务标识**用来"标记这是 App 写的还是 Widget 写的"。要区分写入来源，应使用 `ModelContext.author` 或自己的业务字段。

## 四、追踪来源：ModelContext.author

写入前显式设一行：

```swift
context.author = source   // "App" 或 "Widget"
```

之后这条 transaction 在 history 里就带上了这个 author 字段。App 侧拉到 history 时能直接看到：

```text
Transaction id=3, store=0994F47E-…, author=Widget,
  bundle=com.huahuahu.demo.SwiftDataResearch.Widget,
  process=SwiftDataResearchWidget, timestamp=2026-05-07T13:33:54Z, changes=2
```

这一步只解决了"**谁**写的"。但它解决不了"**做了什么业务操作**"——因为同样是 author=App、修改了 `ResearchNote.detail`，可能是 Update 按钮，也可能是某个后台逻辑。

## 五、关键一步：业务级 OperationLog

Transaction History 是**数据层**的真相，回答 "store 里什么变了"。但业务意图必须自己显式记录。这个 demo 加了一个 `OperationLog` 模型：

```swift
@Model
final class OperationLog {
    var operationName: String      // insertNote / updateLatestNote / deleteSelectedNotes / deleteAllNotes
    var author: String             // App / Widget
    var targetIdentifier: String?  // 目标 ResearchNote 的 persistent model id
    var targetTitle: String?
    var noteCount: Int
    var detail: String
    var createdAt: Date
}
```

每次业务写入，**在同一个 transaction 里**插入一条 OperationLog：

```swift
context.insert(note)
insertOperationLog(
    operationName: "insertNote",
    author: source,
    target: note,
    noteCount: 1,
    detail: "Inserted \(note.title)",
    in: context
)
try context.save()
```

这样有两层好处：

- OperationLog 本身也能被 Transaction History 看到。监控代码顺手把它和 ResearchNote 分开计数：

  ```swift
  case .insert(_ as DefaultHistoryInsert<ResearchNote>): insertedCount += 1
  case .update(_ as DefaultHistoryUpdate<ResearchNote>): updatedCount += 1
  case .delete(_ as DefaultHistoryDelete<ResearchNote>): deletedCount += 1
  case .insert(_ as DefaultHistoryInsert<OperationLog>): operationLogCount += 1
  ```

  汇总后能产出像 `History: 1 transaction(s), notes +1 ~0 -0, ops 1` 这样的摘要。
- App UI 直接读取最近 N 条 OperationLog 显示给用户，跨进程也通用——Widget 写的操作日志，App 重启或感知到 remote change 时一样能拿到。

> 一个容易踩的细节：App 列表的滑动删除走的是 `ContentView.deleteNotes`，不会经过 `SharedStore.deleteAll`。所以这条路径里要**手动**插一条 OperationLog（`operationName: "deleteSelectedNotes"`），否则业务日志会缺失，但 transaction history 里依然能看到一次 delete——这正是"两条记录互为补充"的典型例子。

## 实测一次完整流程

按照 `result/1.log` 和下面这张截图复盘，从 21:33:41 到 21:34:15 操作了 6 次：

![App 端最近操作日志]({{ '/swiftdata-widget-sync/assets/app-recent-operation-logs.png' | relative_url }})

| 时间 | 来源 | 业务操作 | Transaction History 摘要 |
|---|---|---|---|
| 21:33:41 | App | Insert | `notes +1 ~0 -0, ops 1`，author=App |
| 21:33:49 | App | Update Latest | `notes +0 ~1 -0, ops 1`，author=App |
| 21:33:54 | Widget | Update | `notes +0 ~1 -0, ops 1`，author=Widget |
| 21:33:58 | Widget | Insert | `notes +1 ~0 -0, ops 1`，author=Widget |
| 21:34:05 | App | Update Latest | `notes +0 ~1 -0, ops 1`，author=App |
| 21:34:15 | App | 滑动删除 | `notes +0 ~0 -1, ops 1`，author=App |

值得注意的细节：第 3、4 步连在一起从 Widget 写出，但 App 在前台时是**一次性**收到一个 `NSPersistentStoreRemoteChange`，然后从 history 里拉到 **2 条 transaction**——也就是 `Fetched 2 history transaction(s)`。这是 SwiftData history 跨进程合并消费的标准行为，预期就是批量交付而不是一次一条。

## 解决的几个具体问题

把这一轮回头数一下，这个 demo 实际上一并解决了好几件容易混淆的事：

1. **App ↔ Widget 双向读写同一份数据**：靠 App Group + `ModelConfiguration(url:)`，两边的 `ModelContainer` 物理上落到同一个 `.store` 文件。
2. **Widget 主动写**：通过 `AppIntent`，在 Widget 进程内直接写共享 container；写完调用 `WidgetCenter.shared.reloadTimelines(ofKind:)`。
3. **App 自动感知 Widget 的写入**：订阅 `NSPersistentStoreRemoteChange`，用 SwiftData history token 增量消费 transaction。
4. **历史不会无限增长**：每次消费完保存最新 token，并 `deleteHistory` 掉旧的 transaction。
5. **能区分写入来源（进程 / 角色）**：靠 `ModelContext.author` + transaction 自带的 `bundleIdentifier` / `processIdentifier`。
6. **能区分业务意图**：靠业务自己写的 `OperationLog`，这是 Transaction History 没法替代的一层。
7. **数据层与业务层互相校验**：`History: 1 transaction(s), notes +1 ~0 -0, ops 1` 这种摘要既能反推业务，也能发现"业务日志缺失"或"出现非预期写入路径"。
8. **可观测性**：`SharedLog` 把 SharedStore / App / History / Widget 四个 category 分开打 `os.Logger`，跑 demo 时用 `simctl spawn ... log stream` 就能完整复现一遍上面这个时间线。

## 一些可以避开的坑

- **千万别用 `transactionIdentifier` / `storeIdentifier` 做业务标识**。它们是 history 元数据，会重新生成，且和"哪个用户、哪个设备、哪个业务动作"完全没有语义关系。要这些信息请用 `author` 或 `OperationLog` 字段。
- **滑动删除不会自动产生 OperationLog**。如果项目里有多个删除路径（侧滑、批量、清空、iCloud 合并），每条路径都要单独决定要不要写业务日志。
- **`ModelContext.author` 必须在 `save()` 之前设置**。设晚了 history 里 author 会是 nil。
- **Widget 写入不要忘记 `WidgetCenter.shared.reloadTimelines(ofKind:)`**。否则 Widget 自己 UI 不会立即更新（App 那边靠 remote change 仍然会更新）。

## 验证

```bash
xcodegen generate
xcodebuild build \
  -project SwiftDataResearch.xcodeproj \
  -scheme SwiftDataResearch \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .derivedData
```

结果：`BUILD SUCCEEDED`。然后在 iPhone 17 Pro Max 模拟器上手工跑了上面那 6 步流程，截图和 `result/1.log` 完全对得上。

## 可继续挖的方向

- 把 `author` 从 `App` / `Widget` 升级成 `App@deviceID` / `Widget@deviceID`，区分多设备。
- 给 `OperationLog` 增加 `userID`、`sessionID`、`appVersion`，便于线上聚合。
- 把 `HistoryUpdate.updatedAttributes` 里的 keypath 映射成可读字段名，能在数据层就直接看出"改了 detail"还是"改了 revision"。
- 接入 iCloud 同步后，观察合并产生的 transaction 在 `author` / `bundleIdentifier` / `processIdentifier` 上的表现，验证是否需要再加一层"来源类型"枚举（local-write / icloud-merge / migration）。
