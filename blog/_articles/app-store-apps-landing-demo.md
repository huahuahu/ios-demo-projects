---
title: 用 SwiftUI 复现 App Store 列表页：响应式横向 Section 与单列吸附滚动
description: 从 App Store「App」Tab 的两层滚动结构出发，拆解如何让横向 Section 自适应不同屏幕宽度，并让“浏览类别”无论甩多快都只移动一列。
summary: 用 containerRelativeFrame、scrollTargetLayout 和自定义 ScrollTargetBehavior，实现 compact 两列、regular 四列，以及快速横滑最多前进一列的 App Store 风格列表页。
category: Investigation
tag: SwiftUI Layout
date: 2026-08-15
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/app-store-apps-landing-demo
result_url: https://github.com/huahuahu/ios-demo-projects/blob/main/app-store-apps-landing-demo/docs/layout-notes.md
---

## 我想复现的不是一个卡片，而是一套滚动规则

这次最初的问题，是想看清楚 App Store「App」Tab 刚进入时的列表页到底怎样组织。

它不是一个普通的纵向列表。页面外层可以上下滑动，里面又有多个可以左右滑动的 section。不同 section 的内容形态也不一样：有编辑精选大卡片、有每页三行的 App 列表，还有“浏览类别”这种上下两张卡组成一列的布局。

更微妙的是横向手势结束后的行为：内容不会随便停在两张卡之间，而会重新与页面左边距对齐。“浏览类别”虽然一屏能同时看到两列，但快速横滑时又只前进一列。

因此，这个 Demo 真正要回答的不是“卡片圆角是多少”，而是三个结构问题：

1. 外层纵向滚动和 section 内横向滚动怎样组合？
2. 同一套代码怎样在 compact 宽度显示两列、regular 宽度显示四列？
3. 怎样定义横向滚动的最小单位，让快速甩动也最多只移动一列？

![iPhone 上的 App 列表首页]({{ '/app-store-apps-landing-demo/assets/iphone-first-page.jpg' | relative_url }})

## 先划清复现范围

这个 Demo 复现的是用户明确观察到的信息架构和交互规律，不是对某个 iOS 版本 App Store 服务端页面的逐像素复制。

所有 App、类别名称和图形都是离线虚构数据。视觉上只借鉴了 App Store 常见的“大标题、栏目标题、编辑精选卡片、App 图标和获取按钮”等发现型界面语言。真正被验证的是布局和滚动行为：

- 外层纵向、内层横向；
- 普通列表以三行为一个横向 page；
- 类别以两张卡为一列；
- compact 和 regular 宽度使用不同的同屏列数；
- 每个 target 在手势结束后与容器 leading 对齐；
- “浏览类别”一次最多前进一列。

这种边界很重要。公开网页只能帮助确认视觉语言，却不能替代真机或 Simulator 中当前 App Store 页面的实际观察。

## 第一层：一个纵向 ScrollView 承载多个 section

页面最外层只有一个纵向 `ScrollView`。每个 section 根据自己的 style，选择对应的横向内容组件。

```swift
ScrollView(.vertical) {
    LazyVStack(spacing: StoreDesign.sectionSpacing) {
        ForEach(sections) { section in
            CatalogSectionView(section: section)
        }
    }
}
```

`CatalogSectionView` 再把不同数据分发给大卡片、编辑内容、App 列表或类别组件：

```swift
switch section.style {
case .featured:
    FeaturedSectionView(section: section)
case .editorial:
    EditorialSectionView(section: section)
case .appList:
    GroupedAppListSectionView(section: section)
case .categories:
    BrowseCategoriesSectionView(columns: section.categoryColumns)
}
```

这样做之后，纵向滚动只负责“浏览栏目”，每个横向 `ScrollView` 只负责“浏览当前栏目”。方向不同的两个手势各自有明确的容器，也方便后续给每个横向 section 设置不同的吸附规则。

## 第二层：滚动 target 应该和用户感知的“组”一致

横向吸附的关键并不在动画参数，而在于：**究竟哪个 View 是 scroll target？**

以三行 App 列表为例，如果把每一行直接放进横向容器，那么系统看到的 target 就是一行，最终只能逐行吸附。Demo 先在数据层把 App 切成三行一组的 `AppGroupPage`：

```swift
static func pages(
    sectionID: String,
    items: [StoreAppItem],
    pageSize: Int
) -> [AppGroupPage] {
    guard pageSize > 0 else { return [] }

    return stride(from: 0, to: items.count, by: pageSize)
        .enumerated()
        .map { pageIndex, startIndex in
            let endIndex = min(startIndex + pageSize, items.count)
            return AppGroupPage(
                id: "\(sectionID)-page-\(pageIndex)",
                items: Array(items[startIndex..<endIndex])
            )
        }
}
```

视图层再把整个 `AppGroupPageView` 放进 `LazyHStack`：

```swift
LazyHStack(spacing: StoreDesign.pageSpacing) {
    ForEach(section.pages) { page in
        AppGroupPageView(page: page)
            .containerRelativeFrame(
                .horizontal,
                count: StoreDesign.horizontalPageCount(
                    for: horizontalSizeClass
                ),
                span: 1,
                spacing: StoreDesign.pageSpacing
            )
    }
}
.scrollTargetLayout()
```

`scrollTargetLayout()` 登记的是整个 page，所以 `.scrollTargetBehavior(.viewAligned)` 对齐的也是整个三行列表。数据分组、View 分组和滚动分组保持一致，交互才会稳定。

![横滑后仍以三行 App 为一组]({{ '/app-store-apps-landing-demo/assets/iphone-snapped-second-group.jpg' | relative_url }})

## 宽度自适应：不要先问屏幕多宽，先声明同屏显示几列

“浏览类别”在 iPhone 的 compact 宽度显示两列，在 iPad 的 regular 宽度显示四列。列数由 size class 决定：

```swift
static func visibleCategoryColumnCount(
    for sizeClass: UserInterfaceSizeClass?
) -> Int {
    sizeClass == .regular ? 4 : 2
}
```

每一个 `CategoryColumnView` 再使用 `containerRelativeFrame` 声明自己占容器的一份：

```swift
CategoryColumnView(column: column)
    .containerRelativeFrame(
        .horizontal,
        count: visibleColumnCount,
        span: 1,
        spacing: StoreDesign.pageSpacing
    )
```

这里最重要的变化，是没有使用 `UIScreen.main.bounds`，也不需要在外层放一个 `GeometryReader`。

`containerRelativeFrame` 关注的是当前 `ScrollView` 真正可用的容器宽度。概念上，每列宽度可以写成：

```text
columnWidth =
    (containerWidth - (visibleColumnCount - 1) × spacing)
    / visibleColumnCount
```

当 size class 从 compact 变为 regular 时，代码只把 `visibleColumnCount` 从 2 改成 4。同一套布局会根据新的容器宽度和间距重新分配列宽。

这比读取全屏尺寸更可靠，因为窗口宽度不一定等于物理屏幕宽度。iPad 分屏、未来窗口化环境，以及被其他容器约束的 SwiftUI View，都可能让 `UIScreen` 给出的全屏尺寸失去布局意义。

![iPad regular 宽度下的双页布局]({{ '/app-store-apps-landing-demo/assets/ipad-two-column-landscape.jpg' | relative_url }})

## “一屏两列”不等于“两列是一页”

这是实现“浏览类别”时最容易混淆的地方。

一屏显示两列，只描述可见数量；一次滚动移动几列，则由 target 的粒度决定。两者是不同的概念。

数据层先把每两张类别卡组成一个 `CategoryColumn`：

```swift
static func columns(
    sectionID: String,
    categories: [StoreCategory],
    itemsPerColumn: Int = 2
) -> [CategoryColumn] {
    guard itemsPerColumn > 0 else { return [] }

    return stride(from: 0, to: categories.count, by: itemsPerColumn)
        .enumerated()
        .map { columnIndex, startIndex in
            let endIndex = min(startIndex + itemsPerColumn, categories.count)
            return CategoryColumn(
                id: "\(sectionID)-column-\(columnIndex)",
                categories: Array(categories[startIndex..<endIndex])
            )
        }
}
```

视图层的一个 `CategoryColumnView` 只是一个竖向 `VStack`：

```swift
VStack(spacing: StoreDesign.pageSpacing) {
    ForEach(column.categories) { category in
        CategoryCardView(category: category)
    }
}
```

随后，横向 `LazyHStack` 把**每一列**登记为 target。于是 compact 宽度可以同时看到两列，但最小吸附单位仍然是一列，而不是两张单独的卡，也不是两列合成的一整页。

![iPhone 上的浏览类别区域]({{ '/app-store-apps-landing-demo/assets/iphone-category-section.jpg' | relative_url }})

## 先让系统对齐，再把位移限制为一列

Demo 使用自定义 `OneColumnScrollTargetBehavior`。它不是重新实现完整的滚动物理，而是分成两步处理。

第一步，交给 `ViewAlignedScrollTargetBehavior` 选择合法的列，并让列的 leading 与滚动容器 leading 对齐：

```swift
ViewAlignedScrollTargetBehavior(
    limitBehavior: .alwaysByOne,
    anchor: .leading
)
.updateTarget(&target, context: context)
```

第二步，根据当前容器宽度反推出一列的真实宽度，并把最终位移硬限制为“一列宽度 + 一个间距”：

```swift
let safeVisibleColumnCount = max(visibleColumnCount, 1)
let gapCount = safeVisibleColumnCount - 1
let totalGapWidth = CGFloat(gapCount) * spacing

let columnWidth =
    (context.containerSize.width - totalGapWidth)
    / CGFloat(safeVisibleColumnCount)

let oneColumnDistance = columnWidth + spacing
let proposedDelta = target.rect.minX - startingX
let clampedDelta = min(abs(proposedDelta), oneColumnDistance)

target.rect.origin.x =
    startingX + clampedDelta * (proposedDelta > 0 ? 1 : -1)
target.anchor = .leading
```

这里使用的 `context.containerSize`，与前面的 `containerRelativeFrame` 属于同一个容器语境。因此布局时怎样分配列宽，滚动结束时就怎样反推单列步长，不需要额外维护一份设备尺寸表。

`max(visibleColumnCount, 1)` 也是有意保留的防御：当前业务只会传入 2 或 4，但底层算法不应该因为未来错误传入 0 而出现除零或无效宽度。

## 用日志把一次滚动拆开来看

只看最终画面，很容易误以为“系统自然就只滚了一列”。为了区分系统惯性目标、对齐目标和最后的限位结果，Demo 使用 `Logger` 输出两类关键日志。

页面首次出现，或可见列数发生变化时，记录宽度决策：

```text
[宽度自适应] sizeClass=compact,
visibleColumnCount=2,
spacing=14.0
```

这条日志放在 `.task(id: visibleColumnCount)` 中，而不是直接写进 `body`。`body` 是 SwiftUI 的计算属性，可能被频繁重新求值；在那里记录日志很容易制造大量与真实状态变化无关的噪声。

横向手势结束时，记录完整的 target 计算过程：

```text
[横向对齐]
startingX=0.0,
naturalTargetX=621.0,
viewAlignedTargetX=621.0,
columnWidth=(400.0 - (2 - 1) * 14.0) / 2 = 193.0,
oneColumnDistance=207.0,
finalTargetX=207.0,
didClamp=true
```

这次真实 Simulator 记录很直观：

- 横向容器宽度是 400 点；
- compact 模式下一屏两列，间距 14 点；
- 每列宽度是 193 点；
- 从一列 leading 移到下一列 leading，需要 207 点；
- 惯性和系统对齐给出的目标是 621 点；
- 最终目标被限制为 207 点；
- `didClamp=true` 说明硬限位确实被触发。

换句话说，最终“只前进一列”不是视觉猜测，而是可以从输入、公式和输出三个层面复核。

## 怎样捕获 Logger.info

除了 Xcode Console，也可以在终端中通过 Simulator unified logging 捕获这些日志：

```bash
xcrun simctl spawn <SIMULATOR_UDID> log stream \
  --level info \
  --predicate 'subsystem == "com.huahuahu.demo.AppStoreAppsLandingDemo"' \
  --style compact
```

这里的命令形态是 `simctl spawn <device> log stream`。因为代码使用的是 `Logger.info`，捕获时需要保留 `--level info`。

日志使用固定 subsystem 和 `BrowseCategories` category，避免从整个 Simulator 的系统输出里搜索无关文本：

```swift
Logger(
    subsystem: "com.huahuahu.demo.AppStoreAppsLandingDemo",
    category: "BrowseCategories"
)
```

## 自动化证据和人工手感需要两套工具

滚动行为既需要可重复验证，也需要开发者亲自感受。

这次使用 XcodeBuildMCP 完成构建、启动、语义化 UI snapshot 和快速滑动。对 `section-scroll-categories` 执行一次 `distance: 1`、`duration: 0.1s` 的快速左甩后：

- iPhone compact 从第 1–2 列变为第 2–3 列；
- iPad regular 从第 1–4 列变为第 2–5 列。

它适合提供可重复的“之前和之后”证据，但 snapshot 不能完整表达滚动动画的手感。因此又把同一个 Simulator UDID 通过 Simulator Browser 镜像到浏览器中，直接用鼠标或触控板纵滑、横滑，并观察吸附过程。

这两种验证方式不是替代关系：

- XcodeBuildMCP 负责可重复的构建、手势和状态证据；
- Simulator Browser 负责真实画面和人工交互感受；
- unified log 负责解释内部 target 是怎样计算出来的。

三个视角合在一起，才能同时回答“它看起来对不对”“它每次是否都这样”“它为什么这样”。

## Demo 的关键文件

如果想沿着代码重新走一遍，可以按下面的顺序阅读：

- `AppStoreAppsLandingDemo/Features/AppsLanding/AppsLandingPageView.swift`：外层纵向滚动；
- `AppStoreAppsLandingDemo/Features/AppsLanding/CatalogSectionView.swift`：根据 section style 分发组件；
- `AppStoreAppsLandingDemo/Domain/GroupingStrategy.swift`：普通 App 列表的三行分组；
- `AppStoreAppsLandingDemo/Domain/CategoryGroupingStrategy.swift`：类别卡的两张一列分组；
- `AppStoreAppsLandingDemo/Features/AppsLanding/BrowseCategoriesSectionView.swift`：响应式列宽和横向 target 注册；
- `AppStoreAppsLandingDemo/Features/AppsLanding/OneColumnScrollTargetBehavior.swift`：leading 对齐和单列限位；
- `AppStoreAppsLandingDemo/Support/BrowseCategoriesLog.swift`：宽度与 target 计算日志；
- `AppStoreAppsLandingDemoTests/Domain/`：分组数量、稳定 ID 和示例目录测试。

## 这次最容易踩的几个坑

### 1. 把可见列数当成滚动 page 大小

`count: 2` 只意味着同屏两列，不意味着一个 target 必须包含两列。target 的粒度应该由放进 `scrollTargetLayout()` 的直接子 View 决定。

### 2. 把单张类别卡登记为 target

“浏览类别”的上下两张卡在用户感知上属于同一列。先组成 `CategoryColumnView`，再登记 target，才能保持纵向组合不被横向吸附拆开。

### 3. 用 UIScreen 计算卡片宽度

`UIScreen.main.bounds` 描述的是屏幕，不一定是当前 `ScrollView` 的真实容器。用 `containerRelativeFrame` 和 `TargetContext.containerSize` 可以让布局和滚动共享同一套尺寸来源。

### 4. 只设置 viewAligned，却没有验证快速甩动

普通拖动停得正确，不代表高速度手势也符合产品要求。需要刻意用短时长、长距离手势触发惯性，再检查最终 target 和日志中的 `didClamp`。

### 5. 在 SwiftUI body 中直接打印布局日志

`body` 重算不是用户事件。把日志绑定到真正的状态变化，才能让每一行输出都具有解释价值。

### 6. 只看截图，不亲自操作

截图能证明最终位置，却不能证明动画和触控反馈。对于滚动类 UI，自动化 snapshot 与可交互 Simulator Browser 应该同时存在。

## 测试与验证结果

Demo 使用 XcodeGen 生成工程，运行环境为 Swift 6、iOS 26.0+。本次验证包括：

- XcodeBuildMCP build and run 成功；
- 8 个 Swift Testing 测试全部通过；
- 类别数据验证为每列上下两张卡；
- 普通 App 列表验证为每组三行；
- 分组 ID 验证为稳定且唯一；
- `swift-format lint` 通过；
- iPhone compact 和 iPad regular 均完成快速横滑验证；
- unified log 捕获到宽度计算和 `didClamp=true`；
- Simulator Browser 确认真实 Simulator 帧能够持续渲染和交互。

生成并打开项目：

```bash
cd app-store-apps-landing-demo
xcodegen generate
open AppStoreAppsLandingDemo.xcodeproj
```

## 最后得到的认识

这次实现最重要的收获，不是记住某一个 modifier，而是把三个容易混在一起的概念拆开：

1. **可见数量**由 `containerRelativeFrame` 和 size class 决定。
2. **吸附单位**由数据分组、View 分组和 `scrollTargetLayout()` 的 target 粒度决定。
3. **一次允许移动多远**由 `ScrollTargetBehavior` 对最终 target 的约束决定。

只要这三个层次分开设计，“一屏两列，但一次只移动一列”就不再是特殊情况，而是一套可以解释、测试和复用的布局规则。

接下来还可以继续验证动态字体、Right-to-Left 布局、iPad 分屏，以及 Reduce Motion 等环境是否需要调整卡片高度或滚动策略。这些属于下一轮实验，目前 Demo 尚未声称覆盖。
