# CollectionView Animated Updates Demo

一个聚焦 UIKit `UICollectionView` 的 demo，用来演示**动画更新过程中数据源继续变化**时的处理方式。

## Blog Topic

`UICollectionView` 在 `performBatchUpdates` / diffable snapshot 动画期间，如何避免数据源与 UI 不一致、`Invalid update`、以及动画重入。

## What It Shows

- 使用稳定 `item id`（`DemoItem.id`）作为 diffable 和手写 batch update 的共同身份。
- 用 segmented control 对比两种方式：`Diffable` 使用 `UICollectionViewDiffableDataSource`，`Manual` 使用传统 `UICollectionViewDataSource` + `performBatchUpdates`。
- 通过 `SnapshotUpdateQueue` 串行化动画 apply：动画进行中只保留最新 pending 状态，等待 async apply 返回后再继续。
- 每次 enqueue 都会收到 completion；真正应用到 UI 的状态返回 `applied`，被后续状态覆盖的中间请求返回 `coalesced`。
- 将 `UICollectionViewDiffableDataSource.apply` 桥成 async helper，避免业务层出现 `finishApplying` 这类嵌套 completion。
- 将 `performBatchUpdates` 也桥成 async helper，让 manual 模式复用同一套更新队列。
- 提供“强制无动画对齐”按钮，展示变化过大时的兜底策略（无动画 snapshot apply）。

## Manual Batch Rules

不用 diffable data source 时，demo 遵守这些规则：

- `deleteItems` 使用旧 `IndexPath`。
- `insertItems` 使用新 `IndexPath`。
- `moveItem` 使用 old -> new `IndexPath`。
- `performBatchUpdates` closure 内同步切换 backing array 到新数据。
- 当出现重复 id、数量方程不成立、或内容变化混在结构变化中时，直接 fallback 到 `reloadData()`。

## Requirements

- Xcode with iOS 26 SDK
- XcodeGen

## Generate

```bash
cd collectionview-animated-updates-demo
xcodegen generate
```

## Run

```bash
open CollectionViewAnimatedUpdatesDemo.xcodeproj
```

## Test

```bash
xcodebuild test -project CollectionViewAnimatedUpdatesDemo.xcodeproj -scheme CollectionViewAnimatedUpdatesDemo -destination 'platform=iOS Simulator,name=CollectionViewAnimatedUpdatesDemo iPhone 17 Pro Max,OS=latest'
```

## Code Tour

- `CollectionViewAnimatedUpdatesDemo/Domain/DemoItem.swift`：稳定 item identity。
- `CollectionViewAnimatedUpdatesDemo/Domain/SnapshotUpdateQueue.swift`：动画更新串行队列（核心），用 async apply 驱动 drain，并保证 enqueue completion 不丢失。
- `CollectionViewAnimatedUpdatesDemo/Domain/ManualBatchUpdatePlan.swift`：传统 data source 模式下的 delete/insert/move/reload 计划和 fallback 判断。
- `CollectionViewAnimatedUpdatesDemo/Domain/ItemMutationEngine.swift`：模拟增删改与重排数据流。
- `CollectionViewAnimatedUpdatesDemo/Features/MainFeature/MainViewController.swift`：主界面、Diffable/Manual 双模式、高频更新按钮和传统 data source 实现。
- `CollectionViewAnimatedUpdatesDemo/Support/StatusFormatter.swift`：状态文案拼装。
- `CollectionViewAnimatedUpdatesDemo/Support/UICollectionViewDiffableDataSource+Async.swift`：把 diffable data source apply completion 包成 async。
- `CollectionViewAnimatedUpdatesDemo/Support/UICollectionView+BatchUpdatesAsync.swift`：把 `performBatchUpdates` completion 包成 async。
- `CollectionViewAnimatedUpdatesDemoTests/Domain/ManualBatchUpdatePlanTests.swift`：验证 manual batch plan、count equation 和 fallback。
- `CollectionViewAnimatedUpdatesDemoTests/Domain/SnapshotUpdateQueueTests.swift`：验证 pending 合并、串行 apply，以及 15 次 enqueue 都会完成。
