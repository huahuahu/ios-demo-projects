---
title: SwiftUI Navigation 如何同时处理 Tab、Sheet、Cover 和 Deep Link
description: 用一个 SwiftUI demo 梳理全局 Router、递归 PresentationNode、presented view 内部 push、nested present 和 deep link 的处理方式。
summary: 从 swiftui-navigation-handling demo 总结 SwiftUI 导航状态建模方法，并说明 tab path、modal、本地 push、nested present、deep link 分别该怎么处理和测试。
category: Investigation
tag: SwiftUI Navigation
date: 2026-05-27
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/swiftui-navigation-handling
---

## 想搞清楚的问题

SwiftUI 的 `NavigationStack`、`sheet`、`fullScreenCover` 单独看都不复杂，但放到一个真实 app 里会很快变乱：

1. App 有多个 tab，每个 tab 都有自己的 push path。
2. 任意页面都可能 present sheet 或 full-screen cover。
3. Presented view 内部还要继续 push 新页面。
4. Presented view 里还可能再 present 另一层 sheet 或 cover。
5. Deep link 进来时，如果当前正开着 sheet/cover，需要先处理当前 presentation，再跳到目标页面。
6. 同一套路由逻辑要支持 cold launch 和 hot link。

这个 demo (`swiftui-navigation-handling`) 的目标不是做一个完整邮件 app，而是把这些导航状态用一个可测试的模型收拢起来。

## 最终模型

核心结论：**`Route` 只描述页面身份；root router 管 tab 和 root presentation；每一个 presented layer 自己再拥有一份本地导航状态。**

`Router` 只持有 app 根层的状态：当前 tab、每个 tab 的 path，以及 root sheet / root full-screen cover。

```swift
@Observable
final class Router {
    var selectedTab: AppTab
    var inboxPath: [Route]
    var settingsPath: [Route]
    var sheet: PresentationNode?
    var fullScreen: PresentationNode?
    private(set) var deferredDeepLink: AppDeepLink?
}
```

真正解决 nested present 的是 `PresentationNode`。每一个被 present 出来的 view 都不是只有一个 route，而是一个 presentation node：它有自己的 root route、自己的 push path、自己的 child sheet 和 child cover。

```swift
@Observable
final class PresentationNode: Identifiable {
    let id = UUID()
    let route: Route
    var path: [Route]
    var sheet: PresentationNode?
    var fullScreen: PresentationNode?
}
```

这回答了一个关键问题：presented view 是否也需要一个 Route？需要，但更准确地说，**每个 presented layer 需要一个 node**。`route` 只描述这一层的根页面；`path/sheet/fullScreen` 描述这一层内部继续发生的导航。

这里不要把页面拆成 `SheetRoute` / `FullScreenRoute` / push-only `Route`。真实 app 里同一个页面很可能今天从 sheet 打开，明天从 push 打开。页面身份应该是一份统一的 `Route`；push、sheet、cover 是承载这个 route 的上下文。

下面这张图是这个 demo 的状态结构：

![SwiftUI navigation handling structure]({{ '/swiftui-navigation-handling/assets/navigation-structure.svg' | relative_url }})

图里最重要的边界是：`Router` 不知道 nested sheet 的细节，它只知道 root sheet / cover；nested sheet 挂在父 `PresentationNode` 上。因此关闭 child sheet 时，只会回到父 sheet。

## Case 1：Tab 内 push

Tab app 不应该共用一条全局 `NavigationPath`。每个 tab 都应该有自己的 path，否则切 tab 后返回栈会互相污染。

Demo 用 `AppTab` 区分目标 tab，用 typed `Route` 表示 push 目的地：

```swift
enum Route: Hashable, Identifiable, Sendable {
    case collection(String)
    case message(Int)
    case composer(replyTo: Int?)
    case settingsDetail(String)
    case filters
    case onboarding
    case messagePreview(Int)
}
```

Push 时先决定目标 tab，再只改那一个 tab 的 path：

```swift
func push(_ route: Route, on tab: AppTab? = nil) {
    let targetTab = tab ?? selectedTab
    selectedTab = targetTab
    var path = path(for: targetTab)
    path.append(route)
    setPath(path, for: targetTab)
}
```

这让 deep link、按钮点击、子视图跳转都走同一条状态更新路径。

## Case 2：Root 页面 present sheet / cover

Root 层的 `sheet` 和 `fullScreenCover` 直接绑定到 `Router`：

```swift
.sheet(item: $router.sheet, onDismiss: router.applyDeferredDeepLinkIfReady) { node in
    PresentationNodeView(node: node) {
        router.dismissSheet()
    }
    .environment(router)
}
.fullScreenCover(item: $router.fullScreen, onDismiss: router.applyDeferredDeepLinkIfReady) { node in
    PresentationNodeView(node: node) {
        router.dismissFullScreen()
    }
    .environment(router)
}
```

这里 root sheet / cover 的值不是另一套 sheet-only route enum，而是 `PresentationNode`。这样从第一层 modal 开始，就已经具备继续 push 和继续 present 的能力。

所以 `router.presentSheet(.filters)` 和 `router.push(.filters, on: .inbox)` 可以使用同一个 `.filters` route。差异不在 route 本身，而在它被写进了 `router.sheet` 还是某个 tab 的 path。

## Case 3：Presented view 内部 push

Presented view 内部 push 时，不应该默认写到 tab path。否则用户在 sheet 里点了一个“下一步”，背后的 tab stack 也被改了。

Demo 给每个 `PresentationNodeView` 包一层自己的 `NavigationStack`：

```swift
NavigationStack(path: $node.path) {
    PresentedRootView(node: node, dismiss: dismiss)
        .navigationDestination(for: Route.self) { route in
            DestinationView(route: route, context: .presented(node: node, dismiss: nil))
        }
}
```

所以 sheet 内部 push 就是改当前 node 的 path：

```swift
Button("Push Inside This Sheet") {
    node.push(.message(message.id))
}
```

如果确实想让 presented view 改背后的 tab stack，也可以显式走 root router：

```swift
Button("Push Behind Sheet") {
    router.push(.message(message.id), on: .inbox)
}
```

这两个动作要分开建模。一个是 modal-local navigation，一个是 root app navigation。

为了让同一个页面既能被 push 又能被 present，demo 里给 destination 带了一个 `RouteContext`。页面组件不需要知道自己最初是 sheet 还是 push，只要通过 context 把后续动作发到正确的位置：root tab path、当前 node path、root sheet，或当前 node 的 child sheet。

## Case 4：Presented view 再 present

最容易走错的是 nested present。比如 Filter sheet 里再打开 Compose sheet。关闭 Compose 后，用户应该回到 Filter sheet，而不是直接回 root。

错误方向是给 `Router` 加 `nestedSheet`、`nestedNestedSheet` 之类的字段。这个模型扩展不了，也很难表达“关闭当前层只影响父层的 child”。

Demo 采用递归容器：每个 `PresentationNodeView` 都能展示自己的 child sheet / cover。

```swift
.sheet(item: $node.sheet) { child in
    PresentationNodeView(node: child) {
        node.dismissSheet()
    }
    .environment(router)
}
.fullScreenCover(item: $node.fullScreen) { child in
    PresentationNodeView(node: child) {
        node.dismissFullScreen()
    }
    .environment(router)
}
```

关键细节是 `dismiss` closure 是按层传下去的。Root sheet 的关闭动作是 `router.dismissSheet()`；nested sheet 的关闭动作是父 node 的 `node.dismissSheet()`。

这就是为什么 Filter sheet 里 present Compose sheet 后，关闭 Compose 只会清掉 `filterSheet.sheet`，不会清掉 `router.sheet`。用户回到 Filter sheet，root 仍然保持当前 presentation tree。

## Case 5：Deep link 进来时已有 presentation

Hot deep link 最需要明确策略。这个 demo 的策略是：如果当前 root 有 sheet 或 cover，先关闭 presentation tree，把 deep link 暂存在 `deferredDeepLink`，等 presentation 完成 dismiss 后再真正改 tab/path。

```swift
func openDeepLink(_ deepLink: AppDeepLink) {
    if hasActivePresentation {
        deferredDeepLink = deepLink
        sheet = nil
        fullScreen = nil
        return
    }

    apply(deepLink)
}
```

`onDismiss` 里再尝试应用 deferred link：

```swift
func applyDeferredDeepLinkIfReady() {
    guard !hasActivePresentation, let deferredDeepLink else { return }
    self.deferredDeepLink = nil
    apply(deferredDeepLink)
}
```

这个选择的语义很清楚：deep link 是全局导航意图，它会关闭当前 modal subtree，然后把 app 带到目标 tab/path。

Cold launch 不需要 deferred，因为启动时还没有 presentation animation 正在进行：

```swift
func openColdLaunchDeepLink(_ deepLink: AppDeepLink?) {
    guard let deepLink else { return }
    apply(deepLink)
}
```

## Case 6：URL 解析只产出 app-level intent

URL parser 不直接操作 SwiftUI 状态，只把 URL 转成 `AppDeepLink`：

```swift
enum DeepLinkParser {
    static func deepLink(from url: URL) -> AppDeepLink? { ... }
    static func deepLink(from launchArguments: [String]) -> AppDeepLink? { ... }
}
```

Demo 支持两类入口：

```bash
xcrun simctl openurl booted swiftuinavigationhandling://message/101
xcrun simctl openurl booted swiftuinavigationhandling://settings/notifications
```

Cold launch 用 launch argument 模拟：

```text
--deep-link swiftuinavigationhandling://message/102
```

Parser 的责任到 `AppDeepLink` 为止；是否需要 dismiss presentation、切 tab、重设 path，全部交给 `Router`。

## 怎么测试

这个 demo 的测试重点不是点 UI，而是测导航状态机。SwiftUI 的 presentation animation 很难直接单测，但我们可以把真正重要的行为压到 `Router` 和 `PresentationNode` 里。

测试文件是 `SwiftUINavigationHandlingTests/RouterTests.swift`，使用 Swift Testing。

### 测 tab path

`pushUpdatesSelectedTabPath` 验证 push 到 Settings 时：

- `selectedTab` 切到 `.settings`
- `settingsPath` 增加目标 route
- `inboxPath` 不受影响

这个测试防止 tab path 共用或写错 tab。

### 测 root presentation

`rootPresentationCreatesPresentationNode` 验证 root sheet 和 root cover 都创建 `PresentationNode`，并且初始 node path 为空。

这个测试防止后续重构又退回到只存一个裸 route、没有本地 path 和 child presentation 的模型。

`routeIdentityIsIndependentFromPresentationStyle` 额外验证同一个 `.filters` 既可以在 tab path 里，也可以作为 sheet node 的根 route。这个测试直接覆盖“任意页面可能被 present，也可能被 push”的建模约束。

### 测 presented 内部 push

`presentedNodeCanPushInsideItsOwnNavigationStack` 验证 sheet 内部 `node.push(.message(301))` 只改变 `sheet.path`，不会改变 `router.inboxPath`。

这个测试对应“present 的 view 内部怎么 route”。答案是：走当前 node 的 path。

### 测 nested sheet / cover

`presentedNodeCanPresentNestedSheet`、`presentedNodeCanPresentNestedFullScreenCover`、`presentationNodesCanNestMultipleLevels` 验证 presentation tree 可以继续往下长，而且每一层保留自己的 route 和 path。

最关键的回归测试是 `closingNestedSheetReturnsToParentSheet`：

```swift
filterSheet.presentSheet(.composer(replyTo: nil))
filterSheet.dismissSheet()

#expect(router.sheet === filterSheet)
#expect(router.sheet?.route == .filters)
#expect(filterSheet.sheet == nil)
```

这条测试直接锁住行为：关闭 Filter 里面 present 出来的 Compose sheet 后，root sheet 仍然是 Filter sheet。

### 测 deep link

`hotDeepLinkDismissesActivePresentationTreeBeforeRouting` 验证 hot link 进来时：

- root `sheet/fullScreen` 先被清掉
- deep link 进入 `deferredDeepLink`
- tab path 暂时不变
- presentation 清完后再应用 deep link 到目标 path

`coldLaunchDeepLinkAppliesImmediately` 验证 cold launch 直接应用 deep link，不进入 deferred 流程。

### 测 parser

`parserSupportsMessageURLs` 和 `parserSupportsLaunchArguments` 保证 URL 与 launch argument 都能稳定产出 `AppDeepLink`。

这类测试很小，但价值很高。URL scheme 一旦改坏，deep link 行为会从入口处直接断掉。

## 验证命令

先用 XcodeGen 生成项目：

```bash
cd swiftui-navigation-handling
xcodegen generate
```

再跑测试：

```bash
xcodebuild clean test \
  -project SwiftUINavigationHandling.xcodeproj \
  -scheme SwiftUINavigationHandling \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=latest'
```

本次验证结果：Swift Testing 发现并通过了 `RouterTests` 里的 13 个 case，包括 route identity 和 nested sheet close 的回归测试。

## 这次学到的规则

- Tab path 要按 tab 拆开，root router 负责选择目标 tab 并更新对应 path。
- `Route` 表示页面身份，不表示 push/sheet/cover。展示方式应该由 path 或 presentation slot 决定。
- Root-level sheet / cover 可以放在全局 router，但值最好是 presentation node，而不是单薄的 route enum。
- Presented view 内部 push 应该写当前 node 的 `path`，不要默认污染背后的 tab stack。
- Nested present 不要靠 `nestedSheet` 字段硬编码层级，用递归 `PresentationNode` 表达 tree。
- Dismiss 要按层传递 closure。关闭 nested sheet 时清父 node 的 child，不清 root router 的 sheet。
- Hot deep link 遇到 active presentation 时，先 dismiss presentation tree，再 deferred apply。
- Cold launch deep link 可以直接 apply，因为没有正在 dismiss 的 UI 状态。
- 单元测试应该覆盖状态变化和边界语义，UI 只需要补少量 smoke test 或手动验证。

这个模型不追求抽象到所有 app 都直接复用，但它把 SwiftUI 导航里最容易混在一起的几种状态拆开了：root app navigation、modal-local navigation、modal subtree、deep link intent。拆清楚之后，代码和测试都会直接很多。
