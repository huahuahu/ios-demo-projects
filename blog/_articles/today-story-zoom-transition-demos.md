---
title: 用 SwiftUI 和 UIKit 复刻 App Store Today Story 的缩放转场
description: 用两个 iOS 26 Demo 拆解 Story 卡片到详情的系统 zoom transition、交互式返回、横向分页、视频连续播放与动态来源定位。
summary: 从 App Store Today Story 的手势观察出发，对比 SwiftUI 与 UIKit 的系统 zoom transition，并处理视频、纵向滚动、横向分页和正确缩回当前卡片的问题。
category: Investigation
tag: iOS Navigation
date: 2026-08-23
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/today-story-zoom-transition-demos
---

## 想解决的问题

App Store 的 Today Story 看起来像一个普通的卡片放大动画，但真正难复刻的不是“把一个矩形变大”，而是整套交互必须同时成立：

- 卡片连续放大成详情，返回时再准确缩回原位。
- 返回过程可以由系统左边缘手势实时控制，也可以拖到一半后取消。
- 详情内部仍然可以纵向滚动，不能为了转场加一个抢走滚动事件的全屏 `DragGesture` 或 `UIPanGestureRecognizer`。
- 详情可以横向切换 Story，返回时要缩回当前 Story 对应的卡片，而不是最初点开的卡片。
- 卡片里如果播放视频，进入、取消返回和完成返回时不能主动重建播放器、跳时间或暂停。
- 来源卡片可能因为列表滚动而离屏，转场不能因为拿不到旧 Cell 引用而崩溃。

为此我做了两个独立 Demo：一个用 SwiftUI，一个用 UIKit。它们都使用 Swift 6、最低 iOS 26、本地视频和系统导航栈，不用 sheet，也没有自己实现百分比驱动的转场。

## 当前效果

<figure>
  <img src="{{ '/today-story-zoom-transition-demos/assets/swiftui-home.jpg' | relative_url }}" alt="SwiftUI Today Story 首页" style="width: min(100%, 368px); border-radius: 18px;">
  <figcaption>SwiftUI：ScrollView + LazyVStack 中的 Story 卡片。</figcaption>
</figure>

<figure>
  <img src="{{ '/today-story-zoom-transition-demos/assets/uikit-detail.jpg' | relative_url }}" alt="UIKit Today Story 详情" style="width: min(100%, 368px); border-radius: 18px;">
  <figcaption>UIKit：可纵向滚动的 Story 详情。</figcaption>
</figure>

下面两段录屏包含本地视频播放、详情纵向滚动、横向换页、interactive pop 取消和完成，以及关闭按钮返回。

<figure>
  <video controls playsinline muted preload="metadata" style="width: 100%; border-radius: 12px;">
    <source src="{{ '/today-story-zoom-transition-demos/assets/swiftui-video-scroll-interactive-pop.mp4' | relative_url }}" type="video/mp4">
  </video>
  <figcaption>SwiftUI Demo。</figcaption>
</figure>

<figure>
  <video controls playsinline muted preload="metadata" style="width: 100%; border-radius: 12px;">
    <source src="{{ '/today-story-zoom-transition-demos/assets/uikit-video-scroll-interactive-pop.mp4' | relative_url }}" type="video/mp4">
  </video>
  <figcaption>UIKit Demo。</figcaption>
</figure>

## 先分清：这是导航转场，不是 matched geometry 动画

SwiftUI 的关键 API 是：

```swift
@Namespace private var storyTransition

StoryCardView(story: story)
    .matchedTransitionSource(id: story.id, in: storyTransition)

StoryDetailPagerView(...)
    .navigationTransition(
        .zoom(sourceID: selectedStoryID, in: storyTransition)
    )
```

来源通过稳定的 `Story.ID` 注册为 `matchedTransitionSource`，目标页面通过 `navigationTransition(.zoom(...))` 指向同一个 ID 和 namespace。它仍然是 `NavigationStack + NavigationLink` 的 push/pop，不是用 `matchedGeometryEffect` 把两个任意 View 手工拼成一次动画。

UIKit 对应的入口是目标控制器的 `preferredTransition`：

```swift
detailViewController.preferredTransition = .zoom { [weak self] context in

    guard
        let self,
        let detail = context.zoomedViewController
            as? StoryDetailViewController
    else { return nil }

    return self.transitionSourceView(for: detail.currentStory.id)
}
```

这里最重要的不是 `.zoom` 三个字符，而是 `sourceViewProvider` 在转场真正开始时才查询来源。它不能捕获用户点击时的旧 Cell，因为 `UICollectionView` 滚动、复用或者详情横向换页后，那个 Cell 很可能已经不是正确来源。

这些 zoom transition API 从 iOS 18 开始提供。本次把 Demo 的最低系统设为 iOS 26，是为了只研究当前系统行为并删除旧系统分支；这并不等于 iOS 26 提供了一个可以完整复制 App Store 私有交互的新公开 API。

## 为什么 App Store 的退出手势看起来不一样

观察 App Store 的录屏时，一个明显特征是：用户从左边缘返回，列表里的来源卡片留在自己的布局位置，详情主要做缩放和圆角变化，不会像一张可自由拖动的纸片那样上下左右乱跑。

这和“给详情添加一个全屏 pan，然后直接修改 `transform.translation`”是两种模型：

- 自定义全屏 pan 把手指位移直接映射到页面位移，容易出现任意方向漂移。
- 系统导航 transition 自己决定转场 representation、裁切、缩放、圆角以及与导航栈的交互进度。
- 来源页面仍由原本的列表布局管理，不应该在返回过程中跟着手指重新排版。

公开 API 可以选择 zoom 来源、设置 alignment rect、决定 interactive dismiss 是否开始，但没有开放 App Store 内部转场的全部几何函数。因此能复刻的是系统公开的 fluid zoom 语义和可取消返回，不应该声称能够逐像素复制 App Store 的私有实现。

## 其他类似实现：从完全自定义到系统接管

在 iOS 18 的系统 zoom transition 出现以前，社区已经有不少 App Store Today Card 仿制项目。它们大致分成三类：UIKit 自定义转场、SwiftUI 手工 matched geometry，以及现在的系统导航转场。

| 方案 | 导航模型 | 手势与动画 | 优点 | 主要代价 |
| --- | --- | --- | --- | --- |
| `sunimp/AppStore-CardTransition` | full-screen modal | 自定义 pan 先缩放，越过阈值后 dismiss | 缩放轨迹可完全控制，视觉很接近“只缩放、不漂移” | 不是真正的系统 interactive pop；来源直接指向 Cell |
| `aunnnn/AppStoreiOS11InteractiveTransition` | custom modal transition | edge pan、下拉、`UIViewPropertyAnimator` 和两阶段退出 | 对 App Store iOS 11 动画的拆解很细 | 手势、scroll、状态恢复和转场生命周期都要自己维护 |
| `appssemble/appstore-card-transition` | `.custom` modal presentation | 封装 edge/down pan 和自定义 animator | 可复用、参数多、兼容 collection/table card | 旧式第三方转场栈；与现代 NavigationStack/UINavigationController 语义不同 |
| `y-okudera/SwiftUICustomTransition` | SwiftUI 状态切换 | `matchedGeometryEffect` + `DragGesture` + `scaleEffect` | 代码直观，适合学习 SwiftUI 几何匹配 | 不是系统 navigation transition，手势冲突和恢复需要自行负责 |
| 本文 iOS 26 Demo | `NavigationStack` / `UINavigationController` push | 系统 zoom 和系统 interactive pop | 取消、完成、Reduce Motion 和导航生命周期由系统统一处理 | 无法完全定制 App Store 私有的缩放函数和合成细节 |

这些项目不是简单的“新方案替代旧方案”。自定义方案仍然适合必须控制每一段几何变化的产品；系统方案更适合重视导航语义、可访问性、手势取消和跨版本维护成本的应用。

### `sunimp/AppStore-CardTransition`：为什么它看起来只缩放

[`sunimp/AppStore-CardTransition`](https://github.com/sunimp/AppStore-CardTransition) 是一个 2023 年开始的 UIKit 示例。它没有 push 详情，而是把详情包在新的 `UINavigationController` 中，以 `.fullScreen` modal 方式 present，并把 `CardCoverTransition` 设置为 `transitioningDelegate`。

它的进入和退出由 `UIViewControllerAnimatedTransitioning` 完全手写。转场时会创建一个临时的 `CardCoverTransitionView`，分别计算这些元素的起止状态：

- 卡片和详情的 frame。
- 屏幕圆角与卡片圆角。
- content mask。
- cover、介绍区域和关闭按钮的位置、alpha。
- 背景 blur、导航区域和阴影。

最值得注意的是详情的 pan 实现。手势虽然读取二维 translation，但没有把 translation 设置成 view 的位置，而是取水平或垂直移动量中的较大值，再映射成 scale：

```swift
let translation = gesture.translation(in: self)
let moveDistance = max(translation.x, translation.y)
let scaleDelta = max(min(moveDistance / distanceThreshold, 1), 0)
let scale = 1 - scaleDelta * 0.2

contentShadowView.transform = CGAffineTransform(
    scaleX: scale,
    y: scale
)
```

这正是它不会跟着手指任意上下左右漂移的原因：手势只控制一个标量进度，视觉输出只有缩放、圆角和关闭按钮 alpha，没有二维平移。达到阈值后，它才调用关闭逻辑，触发真正的自定义 dismiss；没有达到阈值则用普通 `UIView.animate` 恢复 identity。

所以它在视觉上很贴近我们观察到的效果，但需要分清“交互预览”和“交互式转场”：源码没有使用 `UIPercentDrivenInteractiveTransition`，手势阶段只是直接修改详情 view，达到阈值以后才开始 modal dismiss。它也同时给根详情 view 和内部 ScrollView 的 pan 添加 target，再通过方向和 `contentOffset.y` 手工判断是否允许退出。

这个方案带来几个与本文 Demo 不同的边界：

- `sourceView` 是一个 weak `TodayCoverCell` 引用，不是按稳定 Story ID 动态查询的 provider。
- 详情不是同一个 `UINavigationController` 中的 push 页面，因此没有系统 interactive pop 的状态机。
- 临时 transition view 会重新构造详情视觉层；若卡片是 live video，还要另行设计播放器或 renderer 的连续性。
- 没有处理详情横向切换 Story 后动态更换返回来源。
- 几何、Safe Area、状态栏、Tab Bar、mask 和取消恢复都由业务代码负责。

如果产品明确要求“无论手指如何斜着拖，页面都只能缩放”，这种实现给了最大控制权；但它不适合拿来证明系统返回手势、纵向 ScrollView 和分页器能够自然共存。

### `aunnnn/AppStoreiOS11InteractiveTransition`：把交互拆成五个阶段

[`aunnnn/AppStoreiOS11InteractiveTransition`](https://github.com/aunnnn/AppStoreiOS11InteractiveTransition) 是更早、也更系统化的一次 UIKit 探索。作者把过程拆成五个阶段：卡片按压反馈、present 前准备、present、interactive shrinking、最后 dismiss 到来源卡片。

它使用 `UIViewControllerAnimatedTransitioning`、`UIViewPropertyAnimator`、左边缘 `UIScreenEdgePanGestureRecognizer` 和下拉 pan。进入详情时，卡片的尺寸扩张使用 linear curve，卡片容器移动使用 spring curve；退出时先让手势控制缩小阶段，再进入回到来源 Cell 的动画阶段。

这个项目的价值不只在代码，还在于它清楚记录了旧方案为什么复杂：

- edge pan 必须优先于下拉 pan 和 ScrollView pan。
- 下拉退出只能在纵向内容到顶后接管。
- 取消时要反向播放 paused `UIViewPropertyAnimator`，并在恢复完成前暂时禁用 gesture。
- 来源 Cell、字体大小、图片缩放、状态栏和 blur 都要分别同步。

作者也明确把“首页到详情的视频/GIF 连续播放”列为未解决项，推测需要把整个 view controller 当作 Cell 内容复用。这恰好说明：复制静态卡片的 frame 不等于复制一个持续变化的媒体 surface。

### `appssemble/appstore-card-transition`：把旧式实现封装成库

[`appssemble/appstore-card-transition`](https://github.com/appssemble/appstore-card-transition) 把上述思路整理成支持 UICollectionView 和 UITableView 的库。Cell 实现 `CardCollectionViewCell`，详情实现 `CardDetailViewController`，再通过 `.custom` modal presentation 接入。

它支持 card inset、圆角、blur、从顶部或中心展开、顶部或底部下拉关闭，以及手势进度回调。内部同样使用 edge pan、普通 pan 和 `UIViewPropertyAnimator.fractionComplete` 先做缩小预览。

一个重要细节是，它的 `interactionControllerForDismissal` 返回 `nil`。也就是说，缩小预览由 `CardDismissHandler` 自己驱动，达到阈值后才调用 `dismiss(animated:)`，最终回卡片的部分由 `DismissCardAnimator` 完成。这能获得高度定制的两段式效果，但不是把系统转场 context 从 0% 连续驱动到 100%。

它适合仍需支持老系统、并愿意接受 custom modal 架构的项目；对于本文要求的 navigation push/pop、系统取消恢复和动态 Story source，则需要较多改造。

### `y-okudera/SwiftUICustomTransition`：matchedGeometryEffect 时代的做法

[`y-okudera/SwiftUICustomTransition`](https://github.com/y-okudera/SwiftUICustomTransition) 展示了 iOS 18 以前常见的 SwiftUI 实现：用共享 namespace 和 `matchedGeometryEffect` 在列表与详情状态之间匹配元素，再给详情 hero 增加 `DragGesture`。

拖动时它根据纵向 translation 修改整个详情的 `scaleEffect`，结束后根据阈值关闭或回弹。这种写法很容易理解，也能快速做出 Today Card 的视觉原型，但详情展示、返回手势和转场状态都属于应用自己的状态机。它不是 `NavigationStack` 的系统 zoom transition，也无法自动继承系统 interactive pop 的全部取消语义。

对于只有简单 ScrollView 的原型，这种方案仍然实用；一旦加入横向分页、纵向长内容、系统边缘返回和稳定来源恢复，全屏 `DragGesture` 的仲裁成本就会迅速上升。

### 怎么选择

可以按需求反推方案：

- 必须精确复制“只缩放、不随手指平移”，并愿意自己维护所有转场状态：参考 `sunimp` 或 `aunnnn` 的自定义 animator 思路。
- 要支持旧系统并快速接入 UICollectionView/UITableView：可以研究 `appssemble` 的协议与 settings 设计，但需要评估多年未更新的实现和第三方维护成本。
- 只做 SwiftUI 视觉原型，不要求系统 navigation 行为：`matchedGeometryEffect + DragGesture` 最直接。
- 面向 iOS 18+，优先保证 push/pop、手势取消、Reduce Motion 和系统一致性：使用系统 zoom transition，再接受它不能开放每一帧几何细节的边界。

本文 Demo 选择最后一种。它不是像素级最接近 App Store 的方案，却是最少伪造系统导航行为、也最容易和当前 UIKit/SwiftUI 生命周期保持一致的方案。

## 返回手势和横向分页如何共存

详情支持左右切换六个 Story，同时保留 navigation 的系统返回交互。这里直接组合系统提供的分页和导航容器，不额外介入手势识别过程。

### SwiftUI

SwiftUI 版本只声明系统横向分页和系统 zoom navigation transition：

```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 0) {
        ForEach(stories) { story in
            StoryDetailView(story: story)
                .containerRelativeFrame([.horizontal, .vertical])
                .id(story.id)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.scrollPosition(id: $scrollPositionID)
.navigationTransition(
    .zoom(sourceID: selectedStoryID, in: transitionNamespace)
)
```

横向分页由 ScrollView 负责，返回由 `NavigationStack` 负责。

### UIKit

UIKit 版本把系统 `UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)` 作为普通 child view controller，page view 直接铺满详情容器：

```swift
addChild(pageViewController)
view.addSubview(pageViewController.view)
pageViewController.didMove(toParent: self)
```

zoom transition 只提供动态来源：

```swift
detailViewController.preferredTransition = .zoom { [weak self] context in
    guard
        let self,
        let detail = context.zoomedViewController
            as? StoryDetailViewController
    else { return nil }

    return self.transitionSourceView(for: detail.currentStory.id)
}
```

分页由 `UIPageViewController` 管理，返回由外层 `UINavigationController` 管理。

### 验证边界

手动验证路径包括：横向切换到第二页、纵向滚动、从左边缘拖动后取消、再次完成返回，以及确认返回到当前 Story 对应的卡片。interactive pop 对拖动起点、距离、速度和时序敏感，XCUITest 的合成 swipe 不等同于真实手指交互，因此本文以 Simulator 中的手动操作结果为准；上线前仍应在支持的系统版本和真机上重复这些手势组合。

## 为什么 UIKit 没有直接 push UIPageViewController

`UIPageViewController` 本身就是 `UIViewController`，当然可以直接：

```swift
navigationController?.pushViewController(pageViewController, animated: true)
```

当前工程选择 push `StoryDetailViewController`，再把系统 `UIPageViewController` 作为 child：

```text
UINavigationController
└─ StoryDetailViewController
   └─ UIPageViewController
      └─ StoryDetailPageViewController
```

外层控制器不是重新实现分页，而是集中承担这些职责：

- 持有并更新 `currentStory`。
- 担任 `UIPageViewControllerDataSource` 和 `Delegate`。
- 设置导航标题、关闭按钮和 `preferredTransition`。
- 持有播放器 store 和来源列表引用。
- 为来源 Cell 离屏的 fallback 测试提供入口。

直接 push 原生 `UIPageViewController` 也能实现同样效果，但因为它的 `dataSource` 和 `delegate` 是 weak，还需要另建并强持有 coordinator，再把当前 Story、zoom source、播放状态和导航按钮的职责迁过去。它不是天然更简单，只是把 composition 换成 coordinator。

这里还有一个命名问题：`StoryDetailPageViewController` 实际表示“单个 Story 内容页”，容易被误读成外层分页器。更准确的名字应该是 `StoryDetailContentViewController`；这是代码可读性问题，不影响当前系统分页行为。

## 横向换页后，pop 应该回到哪张卡片

假设从第一张卡片进入详情，然后向左滑到第二个 Story。此时返回应缩回第二张卡片，因为用户眼前的内容身份已经变了。

SwiftUI 版本让 `scrollPositionID` 驱动 `selectedStoryID`：

```swift
.onChange(of: scrollPositionID) {
    guard let scrollPositionID else { return }
    selectedStoryID = scrollPositionID
}
.navigationTransition(
    .zoom(sourceID: selectedStoryID, in: transitionNamespace)
)
```

选中 ID 改变后，被详情覆盖的列表会在禁用动画的 transaction 里滚到对应卡片。用户看不到列表在背后准备来源，但 pop 开始时系统可以找到正确的 `matchedTransitionSource`。

UIKit 版本在分页完成时更新 `currentStory`。返回开始后，`sourceViewProvider` 根据这个 ID 查询 diffable data source：

```swift
func transitionSourceView(for storyID: Story.ID) -> UIView? {
    guard let indexPath = dataSource.indexPath(for: storyID) else {
        return nil
    }

    if collectionView.indexPathsForVisibleItems.contains(indexPath),
       let cell = collectionView.cellForItem(at: indexPath) as? StoryCell {
        return cell.transitionSourceView
    }

    collectionView.scrollToItem(
        at: indexPath,
        at: .centeredVertically,
        animated: false
    )
    collectionView.layoutIfNeeded()

    return (collectionView.cellForItem(at: indexPath) as? StoryCell)?
        .transitionSourceView
}
```

这同时解决了来源 Cell 暂时离屏的问题：先无动画恢复位置并重新获取 Cell；仍然失败就返回 `nil`，让系统安全退化，而不是强解包一个已经复用或消失的对象。

## 详情顶部已经滚出屏幕后，返回是什么表现

这是最容易凭想象写错的一点。详情中的 hero 卡片如果已经被纵向滚出屏幕，开始 interactive pop 时不应该先把详情 ScrollView 突然滚回顶部。

当前系统行为和 Demo 采用的语义是：

- 详情保持当前 `contentOffset`。
- 当前可见 viewport 作为整个详情控制器的一部分参与缩放。
- 来源列表准备好当前 Story 对应的卡片。
- 手势取消后，详情恢复到原来的 scroll offset。
- 手势完成后，转场结束在来源卡片。

所以“详情顶图当前是否可见”和“列表中哪张卡片是 zoom source”是两件事。目标是整个详情控制器，不需要在退出前重新寻找详情内部那张已经滚走的 hero。

## 视频怎样在 push、pop 和手势取消时持续

如果卡片和详情各自创建一个 `AVPlayer`，进入详情时就会重新开始；interactive pop 取消后还可能再次切换实例。Demo 使用一个高于两端 UI 生命周期的 `StoryPlaybackStore`，按稳定 Story ID 缓存播放 session：

```swift
@MainActor
final class StoryPlaybackStore {
    private var sessions: [Story.ID: PlaybackSession] = [:]

    func player(for story: Story) -> AVQueuePlayer? {
        if let session = sessions[story.id] {
            return session.player
        }

        let session = PlaybackSession(url: url)
        sessions[story.id] = session
        if UIAccessibility.isVideoAutoplayEnabled {
            session.player.play()
        }
        return session.player
    }
}
```

`PlaybackSession` 持有同一个 `AVQueuePlayer` 和 `AVPlayerLooper`。卡片和详情中的 `AVPlayerLayer` 只是 renderer；Cell 复用时 detach renderer，不 pause、不 seek，也不替换 `AVPlayerItem`。这样播放时间轴不会因为 push、pop 或取消返回而被应用代码主动打断。

但这里必须保留一个边界：公开的 SwiftUI/UIKit zoom API 没有承诺 transition representation 在每一帧都实时采样 `AVPlayerLayer`。本次 Simulator 录屏能观察到画面继续变化，只能证明当前环境中的实际表现；API 合约层面能保证的是我们没有主动重建或中断播放器，而不是所有未来系统版本都一定以 live video 方式合成转场。

## Reduce Motion、Dark Mode 和可访问性

两个 Demo 都使用语义字体、动态系统颜色、SF Symbols 和至少 44pt 的控制尺寸，并为 Story 卡片、Cell、关闭按钮提供 accessibility label 与 identifier。

UIKit 在 `UIAccessibility.isReduceMotionEnabled` 为 true 时把 zoom 换成 `.crossDissolve`。视频自动播放还遵守 `UIAccessibility.isVideoAutoplayEnabled`。SwiftUI 的系统导航 transition 交给系统处理 Reduce Motion，同时不增加额外自定义位移动画。

Stable ID 既服务于视觉连续性，也服务于 UI 自动化：测试不依赖某个临时 index path，而是通过 `story.card.<id>`、`story.cell.<id>` 和 `story.detail.scroll.<id>` 找到具体内容。

## 实际验证了什么

两个工程都由 XcodeGen 生成完整 `.xcodeproj`，使用 Swift 6 和 iOS 26 deployment target。现有 XCUITest 覆盖：

1. 打开第一张 Story。
2. 横向切换到第二张 Story。
3. 向上滚动第二页详情。
4. 左边缘拖到约 28% 后取消，确认仍停在第二页。
5. 再拖到约 92% 完成返回，确认列表显示第二张来源卡片。
6. 滚到最后一张卡片并进入详情。
7. 点击关闭按钮，确认回到最后一张来源卡片。

SwiftUI 与 UIKit 的最终 XcodeBuildMCP 测试记录均为 2 tests passed、0 failed，Build & Run 成功。项目同时保存了首页、详情截图以及包含视频、滚动和 interactive pop 的录屏。

需要区分这些证据的范围：自动化测试证明导航状态、当前 Story ID 和可访问性节点符合预期；录屏证明当前 Simulator 的视觉表现；它们都不能把 App Store 私有动画的内部实现变成公开 API 保证。

## 最后得到的认识

- Today Story 的核心不是自定义拖拽，而是让系统导航转场拥有稳定、可动态查询的来源。
- 横向分页后，转场身份必须跟随当前 Story；“最初点击的卡片”不再是返回来源。
- 详情滚动位置和列表来源位置应分别维护。hero 滚出详情屏幕，不代表要先滚回详情顶部。
- 视频连续性的关键是稳定播放器 owner，而不是在两个页面之间同步两个播放器的时间。
- `UIPageViewController` 可以直接 push；使用外层容器是职责组织方式，并不意味着分页是自研的。
- iOS 26 可以让 Demo 专注当前系统实现，但公开 zoom API 仍不足以逐像素复刻 App Store 的私有转场。
- 手势共存必须在真实设备或 Simulator 中验证。只看 recognizer 类型或写一个全屏 pan，无法证明取消恢复、纵向滚动和边缘返回都正确。

## 可以继续实验的方向

- 将 UIKit 单页类型从 `StoryDetailPageViewController` 重命名为 `StoryDetailContentViewController`，消除它与真正 `UIPageViewController` 的语义混淆。
- 在不同 Dynamic Type、Dark Mode 和 Reduce Motion 配置下补充视觉快照。
- 用长视频和高负载页面观察 interactive transition 期间的合成性能与内存占用。
- 在真机上重复边缘返回、快速取消和横向分页交替操作，检查 Simulator 之外的手势手感。
