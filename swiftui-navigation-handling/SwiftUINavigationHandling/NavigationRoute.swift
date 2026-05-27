import Foundation

enum NavigationRoute: Hashable, Sendable {
    case collection(String)
    case message(Int)
    case composer(replyTo: Int?)
}

extension NavigationRoute {
    var title: String {
        switch self {
        case .collection(let id):
            DemoData.collection(id: id)?.title ?? "Collection"
        case .message(let id):
            DemoData.message(id: id)?.title ?? "Message"
        case .composer:
            "Compose"
        }
    }
}
