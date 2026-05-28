import Foundation

// App 根层 tab。Router 会根据 deep link 或显式 push 切换 selectedTab。
enum AppTab: String, CaseIterable, Hashable, Identifiable, Sendable {
    case inbox
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox:
            "Inbox"
        case .settings:
            "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .inbox:
            "tray.full"
        case .settings:
            "gearshape"
        }
    }
}

// NavigationStack 的 push 目的地。Tab stack 和 presented node 的本地 stack 都复用这组 Route。
enum Route: Hashable, Identifiable, Sendable {
    case collection(String)
    case message(Int)
    case composer(replyTo: Int?)
    case settingsDetail(String)

    var id: String {
        switch self {
        case .collection(let id):
            "collection-\(id)"
        case .message(let id):
            "message-\(id)"
        case .composer(let replyTo):
            "composer-\(replyTo.map(String.init) ?? "new")"
        case .settingsDetail(let id):
            "settings-\(id)"
        }
    }

    var title: String {
        switch self {
        case .collection(let id):
            DemoData.collection(id: id)?.title ?? "Collection"
        case .message(let id):
            DemoData.message(id: id)?.title ?? "Message"
        case .composer:
            "Compose"
        case .settingsDetail(let id):
            DemoData.setting(id: id)?.title ?? "Settings"
        }
    }
}

// Root sheet 或 nested sheet 的根页面类型；sheet 内部继续 push 时仍然使用 Route。
enum SheetRoute: Hashable, Identifiable, Sendable {
    case composer(replyTo: Int?)
    case filters

    var id: String {
        switch self {
        case .composer(let replyTo):
            "composer-\(replyTo.map(String.init) ?? "new")"
        case .filters:
            "filters"
        }
    }

    var title: String {
        switch self {
        case .composer:
            "Compose Sheet"
        case .filters:
            "Filters"
        }
    }
}

// Full-screen cover 的根页面类型，和 sheet 分开能让 presentation 语义更清楚。
enum FullScreenRoute: Hashable, Identifiable, Sendable {
    case onboarding
    case messagePreview(Int)

    var id: String {
        switch self {
        case .onboarding:
            "onboarding"
        case .messagePreview(let id):
            "preview-\(id)"
        }
    }

    var title: String {
        switch self {
        case .onboarding:
            "Onboarding"
        case .messagePreview(let id):
            DemoData.message(id: id)?.title ?? "Preview"
        }
    }
}

// PresentationNode 的根 route。一个 node 只代表一层 presented UI，内部导航由 node.path 表达。
enum PresentationRoute: Hashable, Identifiable, Sendable {
    case sheet(SheetRoute)
    case fullScreen(FullScreenRoute)

    var id: String {
        switch self {
        case .sheet(let route):
            "sheet-\(route.id)"
        case .fullScreen(let route):
            "fullScreen-\(route.id)"
        }
    }

    var title: String {
        switch self {
        case .sheet(let route):
            route.title
        case .fullScreen(let route):
            route.title
        }
    }
}

// Deep link 只描述“最终要到哪个 tab/path”，不关心当前是否有 sheet/cover 打开。
struct AppDeepLink: Equatable, Sendable {
    let tab: AppTab
    let path: [Route]

    static func message(_ message: DemoMessage) -> AppDeepLink {
        AppDeepLink(
            tab: .inbox,
            path: [.collection(message.collectionID), .message(message.id)]
        )
    }

    static func settingsDetail(_ setting: DemoSetting) -> AppDeepLink {
        AppDeepLink(tab: .settings, path: [.settingsDetail(setting.id)])
    }
}
