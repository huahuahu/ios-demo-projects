import Foundation

// Parser 只把外部输入翻译成 AppDeepLink，不直接修改 Router。
// 这样 cold launch、hot link、测试都能复用同一份解析逻辑。
enum DeepLinkParser {
    static let scheme = "swiftuinavigationhandling"

    static func deepLink(from url: URL) -> AppDeepLink? {
        guard url.scheme == scheme else { return nil }

        let parts = pathParts(from: url)
        guard let first = parts.first else { return nil }

        switch first {
        case "message":
            guard parts.count >= 2, let id = Int(parts[1]), let message = DemoData.message(id: id) else { return nil }
            return .message(message)
        case "settings":
            guard parts.count >= 2, let setting = DemoData.setting(id: parts[1]) else { return nil }
            return .settingsDetail(setting)
        default:
            return nil
        }
    }

    static func deepLink(from launchArguments: [String]) -> AppDeepLink? {
        guard let index = launchArguments.firstIndex(of: "--deep-link") else { return nil }
        let urlIndex = launchArguments.index(after: index)
        guard launchArguments.indices.contains(urlIndex), let url = URL(string: launchArguments[urlIndex]) else {
            return nil
        }
        return deepLink(from: url)
    }

    private static func pathParts(from url: URL) -> [String] {
        var parts: [String] = []

        if let host = url.host(), !host.isEmpty {
            parts.append(host)
        }

        parts.append(contentsOf: url.pathComponents.filter { $0 != "/" })
        return parts
    }
}
