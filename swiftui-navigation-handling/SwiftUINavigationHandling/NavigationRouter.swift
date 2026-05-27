import SwiftUI

@MainActor
final class NavigationRouter: ObservableObject {
    @Published var path: [NavigationRoute]

    init(path: [NavigationRoute] = []) {
        self.path = path
    }

    func openCollection(_ collection: DemoCollection) {
        path.append(.collection(collection.id))
    }

    func openMessage(_ message: DemoMessage) {
        path.append(.message(message.id))
    }

    func compose(replyTo message: DemoMessage? = nil) {
        path.append(.composer(replyTo: message?.id))
    }

    func openDeepLink(to message: DemoMessage) {
        path = [
            .collection(message.collectionID),
            .message(message.id)
        ]
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
