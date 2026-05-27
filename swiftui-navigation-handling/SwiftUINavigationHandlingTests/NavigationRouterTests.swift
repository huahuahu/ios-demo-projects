import Testing
@testable import SwiftUINavigationHandling

@MainActor
struct NavigationRouterTests {
    @Test func openDeepLinkBuildsFullPath() {
        let message = DemoData.messages[1]
        let router = NavigationRouter()

        router.openDeepLink(to: message)

        #expect(router.path == [.collection(message.collectionID), .message(message.id)])
    }

    @Test func composeReplyPushesComposerRoute() {
        let message = DemoData.messages[0]
        let router = NavigationRouter(path: [.collection(message.collectionID), .message(message.id)])

        router.compose(replyTo: message)

        #expect(router.path == [
            .collection(message.collectionID),
            .message(message.id),
            .composer(replyTo: message.id)
        ])
    }

    @Test func popToRootClearsNavigationPath() {
        let router = NavigationRouter(path: [.collection("priority"), .message(101)])

        router.popToRoot()

        #expect(router.path.isEmpty)
    }
}
