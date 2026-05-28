import Foundation

/// App 根层 tab。Router 会根据 deep link 或显式 push 切换 selectedTab。
enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case inbox
    case settings

    var id: String {
        rawValue
    }

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

/// Route 只描述“页面是什么”，不描述它是 push 进来还是 present 出来。
/// Tab stack、presented node 的本地 stack、sheet root、cover root 都复用这组 Route。
enum Route: Hashable, Identifiable {
    case collection(String)
    case message(Int)
    case composer(replyTo: Int?)
    case settingsDetail(String)
    case filters
    case onboarding
    case messagePreview(Int)

    var id: String {
        switch self {
        case let .collection(id):
            "collection-\(id)"
        case let .message(id):
            "message-\(id)"
        case let .composer(replyTo):
            "composer-\(replyTo.map(String.init) ?? "new")"
        case let .settingsDetail(id):
            "settings-\(id)"
        case .filters:
            "filters"
        case .onboarding:
            "onboarding"
        case let .messagePreview(id):
            "preview-\(id)"
        }
    }

    var title: String {
        switch self {
        case let .collection(id):
            DemoData.collection(id: id)?.title ?? "Collection"
        case let .message(id):
            DemoData.message(id: id)?.title ?? "Message"
        case .composer:
            "Compose"
        case let .settingsDetail(id):
            DemoData.setting(id: id)?.title ?? "Settings"
        case .filters:
            "Filters"
        case .onboarding:
            "Onboarding"
        case let .messagePreview(id):
            DemoData.message(id: id)?.title ?? "Preview"
        }
    }
}

/// Deep link 只描述“最终要到哪个 tab/path”，不关心当前是否有 sheet/cover 打开。
struct AppDeepLink: Equatable {
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
