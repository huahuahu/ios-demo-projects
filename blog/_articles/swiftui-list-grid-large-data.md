---
title: SwiftUI 中用 List 和 LazyVGrid 构建大数据列表/网格切换
description: 记录一次用 SwiftUI 实现大数据分页、原生列表交互和 Health 风格 category grid 的 demo 过程。
summary: 用一个独立 demo 说明为什么列表模式保留 List、网格模式使用 LazyVGrid，以及大数据分页、搜索和删除状态需要注意的 SwiftUI 数据流问题。
category: Investigation
tag: SwiftUI
date: 2026-06-22
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/swiftui-list-grid-large-data
---

## 最开始的问题

很多 App 都有一个常见界面：同一批数据既可以按列表显示，也可以按网格或窗格显示。列表模式看起来像系统列表，适合浏览细节、滑动删除和编辑；网格模式更适合展示一组视觉入口，例如 Apple Health 里的 Health Categories。

我一开始的问题是：如果用 SwiftUI 做这种界面，是否应该统一用 `LazyVStack` 和 `LazyVGrid`？如果数据量很大，还需要分批加载，SwiftUI 有没有类似 `UITableViewDataSourcePrefetching` 的标准 prefetch 方法？

这次 demo 的结论是：

- 列表模式优先保留 `List`，因为它自带系统样式、分组、selection、swipe actions 和 accessibility 行为。
- 网格模式使用 `ScrollView + LazyVGrid`，自己设计卡片视觉。
- 大数据分页在 SwiftUI 中常用 `.task`、末尾阈值判断或 iOS 18+ 的 scroll visibility API 触发。
- 如果需要 `UITableView` / `UICollectionView` 级别的精确 prefetch、cancel、复杂拖拽和复用控制，仍然可以回到 UIKit。

对应 demo 是 `swiftui-list-grid-large-data/`。

## Demo 效果

网格模式用 `LazyVGrid` 展示 Health 风格的渐变卡片。每张卡片保留图标、标题和摘要数据，重点是让分类入口有足够强的视觉辨识度。

![SwiftUI LazyVGrid 网格模式截图]({{ '/swiftui-list-grid-large-data/assets/grid-mode.png' | relative_url }})

列表模式保留 `List` 的系统质感，用 `insetGrouped` 样式和原生列表行承载同一批数据。这个模式更适合细节浏览、导航和滑动删除。

![SwiftUI List 列表模式截图]({{ '/swiftui-list-grid-large-data/assets/list-mode.png' | relative_url }})

## 什么是 category grid

这里的 category grid 指的是“分类入口网格”。它不是普通数据表格，而是一组可点击的分类卡片。Apple Health 中的 `Activity`、`Heart`、`Sleep`、`Nutrition` 这类入口就是典型例子。

这类 UI 的重点不是滑动删除，而是：

- 明确的分类名称；
- 高辨识度图标；
- 圆角渐变卡片；
- 响应式列数；
- 点击进入详情；
- 在 iPhone、iPad、横竖屏上都能自然布局。

所以 demo 中网格模式不是模仿 `List` 的 row，而是用 `CategoryCardView` 画出 Health 风格卡片。

## 为什么列表模式不用 LazyVStack

`LazyVStack` 的优势是轻量、可高度自定义，但它默认没有 `List` 的系统质感。比如 `List` 已经帮我们处理了：

- `insetGrouped` 分组背景；
- 行间距和系统 row 高度；
- `NavigationLink` 的列表行为；
- `.swipeActions`；
- VoiceOver 对列表行的基本理解；
- 编辑模式和 selection 的平台习惯。

因此 demo 中列表模式直接使用 `List`：

```swift
List {
    Section {
        ForEach(viewModel.items) { item in
            NavigationLink {
                CategoryDetailView(item: item)
            } label: {
                CategoryListRowView(item: item)
            }
            .task {
                await viewModel.loadMoreIfNeeded(currentItem: item)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", role: .destructive) {
                    viewModel.delete(item)
                }
            }
        }
    }
}
.listStyle(.insetGrouped)
```

也就是说，列表保留原生列表交互；网格再另外设计视觉。

## LazyVGrid 的列布局

网格模式的列配置在 `CategoryBrowserView.swift`：

```swift
private let columns = [
    GridItem(.adaptive(minimum: 172), spacing: 18)
]
```

这表示每个卡片的最小宽度是 `172pt`，SwiftUI 会根据容器宽度自动决定一行放几列。iPhone 竖屏可能是一到两列，iPad 或横屏可以自动增加到三列、四列或更多。

如果改成：

```swift
GridItem(.flexible(), spacing: 18)
```

它只代表“一列是弹性宽度”。真正有几列取决于数组里写了几个 `GridItem`：

```swift
let columns = [
    GridItem(.flexible(), spacing: 18),
    GridItem(.flexible(), spacing: 18)
]
```

这就是固定两列，每列平分可用宽度。

简单记法是：

| 写法 | 含义 |
|---|---|
| `.adaptive(minimum:)` | 固定最小宽度，列数自动变化 |
| `.flexible()` | 固定列数，宽度弹性平分 |
| `.fixed()` | 固定列宽 |

Health 风格 category card 更适合 `.adaptive(minimum:)`，因为它天然需要适配不同屏幕尺寸。

## Apple Backyard Birds 也用了类似模式

这类写法不是 demo 自己发明的。Apple 的官方 sample app `Backyard Birds` 也大量使用 `ScrollView + LazyVGrid + adaptive GridItem` 这种组合。

在 `apple/sample-backyard-birds` 仓库里，可以看到几个类似位置：

- `Multiplatform/Birds/BirdsNavigationStack.swift` 使用 `LazyVGrid(columns: [.init(.adaptive(minimum: 110), alignment: .top)], spacing: 20)` 展示 bird grid。
- `Multiplatform/Plants/PlantsNavigationStack.swift` 使用 `GridItem(.adaptive(minimum: 110), alignment: .top)` 展示 plant grid。
- `Multiplatform/Backyards/BackyardGrid.swift` 使用 `.adaptive(minimum: 300)` 展示 backyard grid。
- `Multiplatform/Backyards/BackyardDetailView.swift` 使用 `.adaptive(minimum: 400)` 展示详情页里的 supply indicator grid。

这和本 demo 的：

```swift
GridItem(.adaptive(minimum: 172), spacing: 18)
```

属于同一种思路：不手写 iPhone/iPad 的列数分支，而是给出一个最小卡片宽度，让 SwiftUI 根据可用空间自动排布。

## 网格卡片怎么做得更像系统 App

卡片视觉在 `CategoryCardView.swift`。它用 `VStack` 放图标、标题和副标题，再用 `LinearGradient`、连续圆角和阴影形成大卡片：

```swift
VStack(alignment: .leading, spacing: 10) {
    Image(systemName: item.symbolName)
        .font(.title.weight(.semibold))
        .foregroundStyle(.white.opacity(0.92))
        .accessibilityHidden(true)

    Spacer(minLength: 16)

    Text(item.title)
        .font(.headline)
        .foregroundStyle(.white)
        .lineLimit(2)

    Text(item.subtitle)
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.78))
        .lineLimit(1)
}
.padding(18)
.frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
.background(
    LinearGradient(
        colors: item.palette.colors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
.shadow(color: .black.opacity(0.12), radius: 14, y: 7)
```

这里没有用固定字号，而是尽量使用 `.headline`、`.caption` 这类 Dynamic Type 语义字体。图标对 VoiceOver 隐藏，整张卡片提供合并后的 accessibility label。

另外，因为颜色在这个界面里承担了区分作用，demo 也读取了：

```swift
@Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
```

当用户开启“Differentiate Without Color”时，卡片会增加描边，避免只依赖颜色区分。

## SwiftUI 中的分页触发

SwiftUI 没有和 `UITableViewDataSourcePrefetching` 完全等价的 prefetch 协议。更常见的做法是在 cell 或 footer 上挂 `.task`，当视图进入显示范围时检查是否接近末尾。

demo 中的分页触发逻辑在 `CategoryBrowserViewModel.swift`：

```swift
func loadMoreIfNeeded(currentItem: HealthCategoryItem) async {
    guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
    let thresholdIndex = max(items.count - prefetchThreshold, 0)

    if index >= thresholdIndex {
        await loadMore()
    }
}
```

假设已经加载了 80 条，`prefetchThreshold` 是 12，那么阈值是：

```text
80 - 12 = 68
```

当第 68 条之后的 item 出现时，就开始加载下一页。这样用户不需要等到真的滑到底才看到 loading。

在列表和网格里都可以复用同一个触发点：

```swift
.task {
    await viewModel.loadMoreIfNeeded(currentItem: item)
}
```

这是 SwiftUI 中比较自然的分页方式：触发点跟 view 生命周期绑定，真正的防重入和状态管理放在 ViewModel。

## 大数据分页的状态边界

分页的核心状态在 `CategoryBrowserViewModel`：

```swift
private var nextOffset = 0
private var loadedQuery = ""
private var loadGeneration = 0
private var activeLoadCount = 0
private var activeLoads: Set<PageLoadKey> = []
private var deletedItemIDs: Set<HealthCategoryItem.ID> = []
```

这里最值得注意的是两个问题。

第一，搜索会和正在进行的分页请求产生竞态。`@MainActor` 不等于没有 reentrancy：方法执行到 `await dataSource.page(...)` 时会让出 MainActor，其他方法可能在这段时间里修改 `loadedQuery`、`items` 或 `nextOffset`。

所以 `loadMore()` 先捕获本次请求的 generation、query 和 offset：

```swift
let requestOffset = nextOffset
let requestQuery = loadedQuery
let requestGeneration = loadGeneration
```

请求回来后再检查状态是否仍然匹配：

```swift
guard requestGeneration == loadGeneration,
      requestQuery == loadedQuery,
      requestOffset == nextOffset else {
    return
}
```

如果用户已经搜索了新关键词，旧请求返回的数据会被丢弃，避免把旧 query 的结果 append 到新列表里。

第二，删除不能只删除当前数组。否则用户删除一个 item 后，再搜索或清空搜索，数据源重新分页时它还会出现。

demo 用 `deletedItemIDs` 记录已删除 ID：

```swift
func delete(_ item: HealthCategoryItem) {
    deletedItemIDs.insert(item.id)
    items.removeAll { $0.id == item.id }
}
```

后续分页 append 前过滤掉已删除项：

```swift
items.append(contentsOf: page.items.filter { deletedItemIDs.contains($0.id) == false })
```

真实项目中，这个状态通常应该落到数据库或后端；demo 中放在 ViewModel 是为了说明数据流边界。

## 搜索的处理

搜索框在 `CategoryBrowserView.swift`：

```swift
.searchable(text: $searchText, prompt: "Search categories")
.task(id: searchText) {
    try? await Task.sleep(for: .milliseconds(250))
    guard Task.isCancelled == false else { return }
    await viewModel.applySearch(searchText)
}
```

这里用 `.task(id:)` 做了一个简单 debounce。`searchText` 改变时，旧 task 会取消；等待 250ms 后，如果没有被取消，再执行搜索。

这不是完整搜索框架，但足够展示 SwiftUI 中“输入变化 -> 取消旧任务 -> 发起新查询”的基本模式。

## List 和 Grid 的交互差异

这次实现也验证了一个设计判断：不要强行让网格拥有和列表完全一样的交互。

列表模式中，`.swipeActions` 很自然：

```swift
.swipeActions(edge: .trailing) {
    Button("Delete", role: .destructive) {
        viewModel.delete(item)
    }
}
```

网格模式中，横滑删除并不是系统常见体验。demo 改用 `contextMenu`：

```swift
.contextMenu {
    Button("Delete", role: .destructive) {
        viewModel.delete(item)
    }
}
```

实际产品里，网格模式还可以继续加编辑模式、多选删除、拖拽排序。它们通常比“小方块横滑删除”更自然。

## 测试覆盖了什么

测试在 `SwiftUIListGridLargeDataTests/CategoryBrowserViewModelTests.swift`，使用 Swift Testing 编写，重点不是 UI snapshot，而是分页和状态行为：

- 初次加载只取第一页；
- 进入末尾阈值时才加载下一页；
- 早于阈值的 item 不触发分页；
- 搜索会清空旧数据并从第一页重新加载；
- 搜索和旧分页请求竞态时，旧结果不会污染新列表；
- 删除项在搜索/重新加载后不会回流。

其中最有价值的是竞态测试。它用一个可挂起的测试 data source 模拟“旧请求还没回来时用户发起搜索”的情况。这个测试暴露了一个容易忽略的问题：SwiftUI ViewModel 即使在 `@MainActor` 上，也要小心 `await` 前后的状态变化。

## Pitfalls

这次 demo 中几个容易踩坑的点：

1. **不要把 `LazyVStack` 当作 `List` 的替代品。** 如果需要原生列表质感和 swipe actions，`List` 更合适。
2. **不要以为 SwiftUI 有 UITableView 那种 prefetch delegate。** 常规 SwiftUI 分页更多依赖 `.task`、footer sentinel、阈值判断或 iOS 18+ scroll visibility API。
3. **不要在 `await` 后直接 append。** 请求期间搜索条件或 offset 可能已经变了。
4. **删除状态不能只改当前页。** 搜索或刷新后会重新从数据源加载，删除项可能回流。
5. **网格交互不应该完全照搬列表。** `contextMenu`、编辑模式和多选通常更自然。

## 结论

如果要用 SwiftUI 做“列表/网格切换 + 大数据分页”，我现在会采用这样的默认方案：

- 列表：`List`，保留系统行为；
- 网格：`ScrollView + LazyVGrid`，用 `.adaptive(minimum:)` 做响应式卡片；
- 分页：cell `.task` + ViewModel 阈值判断；
- 搜索：`.task(id:)` 做取消和 debounce；
- 防竞态：请求时捕获 query/offset/generation，返回后校验；
- 删除：记录 ID 或持久化删除状态，避免重新分页后回流；
- 复杂 prefetch/reorder：需求明显超过 SwiftUI 常规能力时，再考虑 `UICollectionView`。

这个 demo 的价值不只是“画出一个好看的网格”，而是把 SwiftUI 列表和网格的职责分开：列表负责系统交互，网格负责视觉展示，分页和数据一致性统一放在 ViewModel 中。

## 可继续补充

后续如果要继续扩展，可以补三类实验：

- 使用 iOS 18+ 的 `onScrollVisibilityChange` / `onScrollTargetVisibilityChange` 替代当前 item 阈值判断；
- 加入网格编辑模式和多选删除；
- 对比 SwiftUI `LazyVGrid` 与 UIKit `UICollectionViewCompositionalLayout` 在复杂拖拽和大量图片预取场景下的实现成本。
