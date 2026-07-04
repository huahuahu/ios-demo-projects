---
title: UICollectionView 动画更新时数据源又变了怎么办
description: 用一个 UIKit demo 对比 Diffable Data Source 和传统 performBatchUpdates，梳理动画期间数据源继续变化时的安全处理方式。
summary: CollectionView 动画更新期间不要重入更新；用稳定 id、串行队列、pending 合并和必要的 reloadData fallback，才能避免 Invalid update。
category: Investigation
tag: UIKit
date: 2026-07-01
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/collectionview-animated-updates-demo
---

## 实验问题

这次想弄清楚一个很常见但容易踩坑的问题：`UICollectionView` 正在做动画更新时，如果数据源又来了新变化，应该怎么处理？

直觉上，我们可能会想“来一次数据就更新一次 UI”。但对 `UICollectionView` 来说，动画更新不是一个瞬时操作。无论是 `UICollectionViewDiffableDataSource.apply(_:animatingDifferences:)`，还是传统的 `performBatchUpdates`，在动画完成前，collection view 都处在一次更新事务里。这个时候如果继续改 backing data、继续发新的 insert/delete/move，很容易出现数据源数量和 batch 操作不一致，最后触发熟悉的 `Invalid update`。

我做了一个 demo：`collectionview-animated-updates-demo`。它把同一套高频数据变化分别接到两种更新方式上：

- `Diffable`：使用 `UICollectionViewDiffableDataSource` 和 snapshot。
- `Manual`：使用传统 `UICollectionViewDataSource` 和手写 `performBatchUpdates`。

目标不是证明哪一种永远更好，而是把两者共同需要遵守的规则看清楚：**数据变化可以合并，但更新事务必须串行。**

## 背景：CollectionView 更新里有三种状态

这个问题之所以绕，是因为同时存在三种状态：

1. **业务数据状态**：服务端、用户操作、定时器或本地状态机产生的新数组。
2. **data source 当前状态**：`UICollectionView` 查询 `numberOfItems` 和 `cellForItemAt` 时看到的 backing array。
3. **UI 动画事务状态**：上一轮 insert/delete/move/reload 动画是否已经完成。

如果把它们混成一个“数组变了就刷新”的概念，代码很容易写成：

```swift
items = newItems
collectionView.performBatchUpdates {
    collectionView.deleteItems(at: deletes)
    collectionView.insertItems(at: inserts)
}
```

这段代码本身不一定错，真正危险的是：上一轮 batch 还没结束时，又来了下一轮 `items = newerItems` 和另一次 batch。此时 collection view 校验的“更新前数量”和 data source 暴露的数量就可能对不上。

所以 demo 的核心不是某个动画 API，而是一个串行化更新队列：`SnapshotUpdateQueue`。

## 第一条规则：稳定 id，而不是依赖 indexPath

无论是否使用 diffable data source，demo 都把 `DemoItem.id` 作为 item identity。

```swift
struct DemoItem: Hashable, Identifiable {
    let id: UUID
    let title: String
}
```

这点很关键。`IndexPath` 是某一刻的坐标，不是业务身份。动画更新过程中，某个 item 可以从旧 index 移到新 index，也可以被删除、插入，甚至因为前面的删除导致 index 全部偏移。如果只拿 indexPath 做判断，很容易把“同一个 item 移动了”和“旧 item 删除、新 item 插入”混在一起。

在 diffable 模式里，稳定 id 被交给 snapshot：

```swift
var snapshot = NSDiffableDataSourceSnapshot<Section, DemoItem.ID>()
snapshot.appendSections([.main])
snapshot.appendItems(items.map(\.id), toSection: .main)
```

在 manual 模式里，稳定 id 用来计算 old/new 数组之间的差异：

```swift
let oldIDs = oldItems.map(\.id)
let newIDs = newItems.map(\.id)
let difference = newIDs.difference(from: oldIDs).inferringMoves()
```

这两条路径的共同点是：**先确认“谁是谁”，再谈它在第几个位置。**

## 第二条规则：动画期间只保留最新 pending

demo 里最核心的文件是 `CollectionViewAnimatedUpdatesDemo/Domain/SnapshotUpdateQueue.swift`。它做三件事：

1. 如果当前没有动画更新在跑，立刻启动一次 apply。
2. 如果正在 apply，新的状态只写入 `pendingRequest`。
3. 如果 pending 被更新的状态覆盖，被覆盖的请求会收到 `.coalesced` completion。

简化后的结构是：

```swift
@MainActor
final class SnapshotUpdateQueue<State> {
    typealias Apply = @MainActor (State) async -> Void

    private var pendingRequest: Request?
    private var isApplying = false
    private let apply: Apply

    func submit(
        _ newState: State,
        onComplete: @escaping @MainActor (SnapshotUpdateCompletion) -> Void = { _ in }
    ) {
        let coalescedRequest = pendingRequest
        pendingRequest = Request(state: newState, onComplete: onComplete)
        coalescedRequest?.onComplete(.coalesced)

        guard !isApplying else { return }
        isApplying = true

        Task { @MainActor [weak self] in
            await self?.drain()
        }
    }

    private func drain() async {
        while let nextRequest = pendingRequest {
            pendingRequest = nil
            await apply(nextRequest.state)
            nextRequest.onComplete(.applied)
        }

        isApplying = false
    }
}
```

这里有一个重要的设计取舍：**不是 15 次 enqueue 就一定要 15 次 UI 动画**。如果用户在动画中连续来了 15 次数据，真正有意义的通常是第一帧和最后一帧。中间状态如果已经被更新的状态覆盖，再强行逐个动画，不但视觉上拖沓，还会放大 `UICollectionView` 更新重入的风险。

但另一个细节同样重要：**被合并掉的请求也必须 completion**。否则调用方可能永远等不到某次 enqueue 的结束信号。demo 用 `.applied` 和 `.coalesced` 区分：

- `.applied`：这个状态真的应用到了 UI。
- `.coalesced`：这个状态被更新的 pending 状态覆盖，没有单独应用到 UI。

测试里专门覆盖了“15 次 submit 都 completion，但大多数被 coalesced”的场景。

## 为什么把 UIKit completion 包成 async

一开始如果直接把 completion 一层层传进去，代码会很快变成这样：

```swift
queue.submit(items, onComplete: { result in
    ...
}) { state, finishApplying in
    dataSource.apply(snapshot, animatingDifferences: true) {
        finishApplying()
    }
}
```

这个写法能工作，但语义很绕：`onComplete` 是“这次 submit 被结算”，`finishApplying` 是“这轮 UIKit 动画完成”。两个都是 completion，但层级不同，很容易误用。

demo 后来改成把 UIKit completion 统一桥接成 async：

```swift
extension UICollectionViewDiffableDataSource {
    @MainActor
    func applySnapshotAndWait(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool
    ) async {
        await withCheckedContinuation { continuation in
            apply(snapshot, animatingDifferences: animatingDifferences) {
                continuation.resume()
            }
        }
    }
}
```

传统 batch update 也同样处理：

```swift
extension UICollectionView {
    @MainActor
    func performBatchUpdatesAndWait(_ updates: @escaping @MainActor () -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            performBatchUpdates {
                updates()
            } completion: { finished in
                continuation.resume(returning: finished)
            }
        }
    }
}
```

这样 `SnapshotUpdateQueue` 只需要知道一件事：`await apply(state)`。UIKit 的 completion 细节被留在 adapter 层，业务代码就不会出现“completion 里又塞 completion”的嵌套。

## Diffable 路径：把 diff 交给系统

Diffable 模式里，`MainViewController` 只需要维护 `itemByID`，再创建 snapshot：

```swift
private func applyDiffableSnapshotAndWait(
    _ items: [DemoItem],
    animated: Bool,
    reason: String
) async {
    collectionView.dataSource = diffableDataSource
    let snapshot = makeDiffableSnapshot(items)
    await diffableDataSource.applySnapshotAndWait(snapshot, animatingDifferences: animated)
    updateStatus(reason: reason)
}
```

优点是很明显的：

- 不用手写 delete/insert/move 的 indexPath。
- 系统会根据 identifier 计算动画。
- 代码更接近“声明最终状态”。

但 diffable 也不是说可以随便重入。demo 仍然在外层保留 `SnapshotUpdateQueue`，因为我们关心的不只是 diff 计算，而是**动画事务的节奏**：上一轮 `apply` 没结束前，下一轮状态先进入 pending。

## Manual 路径：自己承担 batch update 的规则

如果不用 diffable data source，就必须自己算 batch plan。demo 里对应文件是 `CollectionViewAnimatedUpdatesDemo/Domain/ManualBatchUpdatePlan.swift`。

Manual 模式遵守这些规则：

- `deleteItems` 使用旧 `IndexPath`。
- `insertItems` 使用新 `IndexPath`。
- `moveItem` 使用 old -> new `IndexPath`。
- `performBatchUpdates` closure 内，把 backing array 同步切到 `newItems`。
- 如果变化无法安全表达，直接 fallback 到 `reloadData()`。

真正 apply 时的关键代码是：

```swift
let plan = ManualBatchUpdatePlan.make(oldItems: manualItems, newItems: items)

guard !plan.shouldReloadData else {
    manualItems = items
    collectionView.reloadData()
    return
}

let finished = await collectionView.performBatchUpdatesAndWait { [weak self] in
    guard let self else { return }

    self.manualItems = items
    self.collectionView.deleteItems(at: plan.deletes)
    self.collectionView.insertItems(at: plan.inserts)

    for move in plan.moves {
        self.collectionView.moveItem(at: move.from, to: move.to)
    }

    if !plan.reloads.isEmpty {
        self.collectionView.reloadItems(at: plan.reloads)
    }
}
```

这段里最容易忽略的是 `self.manualItems = items` 的位置。传统 data source 下，collection view 在 batch update 前后会询问 data source 数量。closure 内切换 backing array，是为了让 batch 后的 `numberOfItems` 和执行的 delete/insert/move 结果对齐。

demo 也明确检查了数量方程：

```swift
oldItems.count - deletes.count + inserts.count == newItems.count
```

如果这个方程都不成立，就不要继续 batch。

## 为什么 manual 模式需要 fallback

传统 `performBatchUpdates` 可以很强，但它的安全边界比 diffable 窄。demo 目前对这些情况选择 fallback 到 `reloadData()`：

- 出现重复 id。
- count equation 不成立。
- 同一轮里既有结构变化，又有 item 内容变化。

最后一个选择有点保守，但符合这个 demo 的目标：先演示稳定、安全的更新原则，而不是在一篇 demo 里把所有复杂组合都动画化。真实项目里当然可以继续细分，比如把内容变化转成 cell reconfiguration，或者把复杂变化拆成多轮事务。但如果只是为了避免 `Invalid update`，保守 fallback 往往比“硬凑一组 indexPath”更可靠。

## 高频更新：15 次 enqueue 不等于 15 次动画

demo 的“高频更新（15次）”按钮会连续提交 15 次数据变化。状态栏会显示：

- `enqueued`：提交了多少次。
- `completions`：有多少次 submit 已经结算。
- `applied`：真的应用到 UI 的次数。
- `coalesced`：被后续 pending 覆盖的次数。

这个观察解决了一个容易误解的问题：如果合并 pending，中间状态不动画，那么 completion 会不会丢？

答案应该是：**不应该丢**。在当前实现里，被覆盖的 pending 会立即收到 `.coalesced`，真正进入 UI 的状态会收到 `.applied`。所以调用方可以放心做计数、埋点、状态机收尾，而不需要猜某次 enqueue 是否还悬空。

## 验证方式

这个 demo 用 XcodeGen 生成工程：

```bash
cd collectionview-animated-updates-demo
xcodegen generate
```

测试覆盖了两类核心行为：

- `SnapshotUpdateQueueTests`：验证串行 apply、pending 合并，以及 15 次 enqueue 都 completion。
- `ManualBatchUpdatePlanTests`：验证 insert/delete、move、content reload、重复 id fallback、结构变化混合内容变化 fallback。

本次验证中，XcodeBuildMCP 的 `test_sim` 在当前环境里因为 `spawn /usr/bin/xcrun ENOENT` 失败，所以回退到了显式 `xcodebuild test`：

```bash
xcodebuild test \
  -project CollectionViewAnimatedUpdatesDemo.xcodeproj \
  -scheme CollectionViewAnimatedUpdatesDemo \
  -destination 'platform=iOS Simulator,id=989B8721-5992-43B0-8496-F3A5CCB18557'
```

最终执行 9 个测试，全部通过。

## 这次实验后的理解

这次最重要的结论是：`UICollectionView` 动画更新期间的数据变化，不应该直接重入 UI 更新。更稳的做法是把“数据状态变化”和“UI 动画事务”解耦。

具体来说：

1. 用稳定 id 表达 item identity。
2. 用队列串行化 collection view apply。
3. 动画期间只保留最新 pending 状态。
4. 每次 enqueue 都 completion，用 `.applied` / `.coalesced` 区分结局。
5. Diffable 模式让系统算 diff，但仍然需要控制 apply 节奏。
6. Manual 模式必须自己保证 old/new indexPath、backing array 更新时机和 count equation。
7. 复杂变化不要硬做 batch，fallback 到 `reloadData()` 是正常工程策略。

如果只记一句话：**可以合并数据状态，但不要并发执行 collection view 动画更新事务。**

## 可继续补充

这篇文章还可以继续补两类材料：

- 一张 demo 运行截图，展示 Diffable / Manual segmented control 和状态栏里的 `applied/coalesced` 计数。
- 一组更复杂的 manual batch case，例如多 section、section insert/delete、以及 content reconfiguration 和 move 同时发生时的拆分策略。
