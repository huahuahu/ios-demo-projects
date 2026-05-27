import SwiftUI

@MainActor
@Observable
final class PresentationNode: Identifiable {
    let id = UUID()
    let route: PresentationRoute
    var path: [Route]
    var sheet: PresentationNode?
    var fullScreen: PresentationNode?

    init(route: PresentationRoute, path: [Route] = []) {
        self.route = route
        self.path = path
    }

    func presentSheet(_ route: SheetRoute) {
        sheet = PresentationNode(route: .sheet(route))
    }

    func presentFullScreen(_ route: FullScreenRoute) {
        fullScreen = PresentationNode(route: .fullScreen(route))
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissFullScreen() {
        fullScreen = nil
    }

    func push(_ route: Route) {
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

@MainActor
@Observable
final class Router {
    var selectedTab: AppTab
    var inboxPath: [Route]
    var settingsPath: [Route]
    var sheet: PresentationNode?
    var fullScreen: PresentationNode?
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
        let targetTab = tab ?? selectedTab
        selectedTab = targetTab
        var path = path(for: targetTab)
        path.append(route)
        setPath(path, for: targetTab)
    }

    func presentSheet(_ route: SheetRoute) {
        sheet = PresentationNode(route: .sheet(route))
    }

    func presentFullScreen(_ route: FullScreenRoute) {
        fullScreen = PresentationNode(route: .fullScreen(route))
    }

    func dismissSheet() {
        sheet = nil
        applyDeferredDeepLinkIfReady()
    }

    func dismissFullScreen() {
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
        if hasActivePresentation {
            deferredDeepLink = deepLink
            sheet = nil
            fullScreen = nil
            return
        }

        apply(deepLink)
    }

    func openColdLaunchDeepLink(_ deepLink: AppDeepLink?) {
        guard let deepLink else { return }
        apply(deepLink)
    }

    func applyDeferredDeepLinkIfReady() {
        guard !hasActivePresentation, let deferredDeepLink else { return }
        self.deferredDeepLink = nil
        apply(deferredDeepLink)
    }

    private var hasActivePresentation: Bool {
        sheet != nil || fullScreen != nil
    }

    private func apply(_ deepLink: AppDeepLink) {
        selectedTab = deepLink.tab
        setPath(deepLink.path, for: deepLink.tab)
        deferredDeepLink = nil
    }
}
