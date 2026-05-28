import SwiftUI

// 每一层被 present 出来的页面都是一个节点：它有自己的根 route、本层 push path，以及下一层 sheet/cover。
// 这样可以自然支持 sheet -> sheet -> cover 这种递归结构，而不是在 Router 里硬编码 nestedSheet。
@MainActor
@Observable
final class PresentationNode: Identifiable {
    let id = UUID()
    let route: PresentationRoute
    var path: [Route]
    // 子 presentation 属于当前节点；关闭子 sheet 时只清这里，不会影响 root sheet。
    var sheet: PresentationNode?
    var fullScreen: PresentationNode?

    init(route: PresentationRoute, path: [Route] = []) {
        self.route = route
        self.path = path
    }

    func presentSheet(_ route: SheetRoute) {
        // 从 presented view 再 present 时，挂到当前 node 下面，保留父层 presented view。
        sheet = PresentationNode(route: .sheet(route))
    }

    func presentFullScreen(_ route: FullScreenRoute) {
        // cover 也用同一套节点模型，所以每层 cover 内部仍然可以继续 push 或 present。
        fullScreen = PresentationNode(route: .fullScreen(route))
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissFullScreen() {
        fullScreen = nil
    }

    func push(_ route: Route) {
        // 这是 modal-local push，只改变当前 presented layer 的 NavigationStack。
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = []
    }
}

// Router 只管理 app 根层导航：当前 tab、各 tab 的 path、root sheet/cover，以及等待中的 deep link。
// Presented view 内部的 path 和 nested presentation 交给 PresentationNode 管，避免所有状态都挤在 root。
@MainActor
@Observable
final class Router {
    var selectedTab: AppTab
    // Tab 之间保留独立 path，切换 tab 时不会互相污染返回栈。
    var inboxPath: [Route]
    var settingsPath: [Route]
    // Root-level presentation。值是 PresentationNode，而不是单纯的 SheetRoute/FullScreenRoute。
    var sheet: PresentationNode?
    var fullScreen: PresentationNode?
    // Hot link 到来时如果正在展示 sheet/cover，先 dismiss，再延后应用目标 path。
    private(set) var deferredDeepLink: AppDeepLink?

    init(
        selectedTab: AppTab = .inbox,
        inboxPath: [Route] = [],
        settingsPath: [Route] = [],
        sheet: PresentationNode? = nil,
        fullScreen: PresentationNode? = nil
    ) {
        self.selectedTab = selectedTab
        self.inboxPath = inboxPath
        self.settingsPath = settingsPath
        self.sheet = sheet
        self.fullScreen = fullScreen
    }

    func binding(for tab: AppTab) -> Binding<[Route]> {
        // NavigationStack 需要 Binding<[Route]>；Router 仍然集中负责读写具体 tab path。
        Binding(
            get: { self.path(for: tab) },
            set: { self.setPath($0, for: tab) }
        )
    }

    func path(for tab: AppTab) -> [Route] {
        switch tab {
        case .inbox:
            inboxPath
        case .settings:
            settingsPath
        }
    }

    func setPath(_ path: [Route], for tab: AppTab) {
        switch tab {
        case .inbox:
            inboxPath = path
        case .settings:
            settingsPath = path
        }
    }

    func push(_ route: Route, on tab: AppTab? = nil) {
        // Root-level push 会切到目标 tab，然后只更新该 tab 的 path。
        let targetTab = tab ?? selectedTab
        selectedTab = targetTab
        var path = path(for: targetTab)
        path.append(route)
        setPath(path, for: targetTab)
    }

    func presentSheet(_ route: SheetRoute) {
        // Root 发起的 presentation 挂在 Router 下，是整个 presentation tree 的入口。
        sheet = PresentationNode(route: .sheet(route))
    }

    func presentFullScreen(_ route: FullScreenRoute) {
        // Root cover 与 root sheet 并列；deep link 会一起清掉 root presentation tree。
        fullScreen = PresentationNode(route: .fullScreen(route))
    }

    func dismissSheet() {
        // Root sheet 关闭后，可能刚好可以继续执行等待中的 deep link。
        sheet = nil
        applyDeferredDeepLinkIfReady()
    }

    func dismissFullScreen() {
        // Root cover 的 dismiss 也走同一套 deferred deep link 检查。
        fullScreen = nil
        applyDeferredDeepLinkIfReady()
    }

    func dismissPresentation() {
        sheet = nil
        fullScreen = nil
        applyDeferredDeepLinkIfReady()
    }

    func pop(on tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        var path = path(for: targetTab)
        guard !path.isEmpty else { return }
        path.removeLast()
        setPath(path, for: targetTab)
    }

    func popToRoot(on tab: AppTab? = nil) {
        setPath([], for: tab ?? selectedTab)
    }

    func openDeepLink(_ deepLink: AppDeepLink) {
        // Hot link 是全局导航意图；如果当前有 modal，先关闭 modal tree，避免边 dismiss 边改 path。
        if hasActivePresentation {
            deferredDeepLink = deepLink
            sheet = nil
            fullScreen = nil
            return
        }

        apply(deepLink)
    }

    func openColdLaunchDeepLink(_ deepLink: AppDeepLink?) {
        // Cold launch 时还没有 active presentation，可以直接落到目标 tab/path。
        guard let deepLink else { return }
        apply(deepLink)
    }

    func applyDeferredDeepLinkIfReady() {
        // 只有 root sheet/cover 都清空后，才真正应用 deferred link。
        guard !hasActivePresentation, let deferredDeepLink else { return }
        self.deferredDeepLink = nil
        apply(deferredDeepLink)
    }

    private var hasActivePresentation: Bool {
        sheet != nil || fullScreen != nil
    }

    private func apply(_ deepLink: AppDeepLink) {
        // Deep link 的最终效果就是选中目标 tab，并重置该 tab 的 path。
        selectedTab = deepLink.tab
        setPath(deepLink.path, for: deepLink.tab)
        deferredDeepLink = nil
    }
}
