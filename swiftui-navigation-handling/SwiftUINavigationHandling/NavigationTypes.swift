import Foundation

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
