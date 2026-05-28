import Foundation
import Testing
@testable import SwiftUINavigationHandling

@MainActor
struct RouterTests {
    @Test func pushUpdatesSelectedTabPath() {
        let router = Router()

        router.push(.settingsDetail("account"), on: .settings)

        #expect(router.selectedTab == .settings)
        #expect(router.settingsPath == [.settingsDetail("account")])
        #expect(router.inboxPath.isEmpty)
    }

    @Test func rootPresentationCreatesPresentationNode() throws {
        let router = Router()

        router.presentSheet(.filters)
        router.presentFullScreen(.onboarding)

        let sheet = try #require(router.sheet)
        let cover = try #require(router.fullScreen)

        #expect(sheet.route == .sheet(.filters))
        #expect(cover.route == .fullScreen(.onboarding))
        #expect(sheet.path.isEmpty)
        #expect(cover.path.isEmpty)
    }

    @Test func presentedNodeCanPushInsideItsOwnNavigationStack() throws {
        let router = Router()
        router.presentSheet(.filters)
        let sheet = try #require(router.sheet)

        // presented view 内部 push 应该落在 node.path，不应该污染背后的 tab path。
        sheet.push(.message(301))

        #expect(sheet.path == [.message(301)])
        #expect(router.inboxPath.isEmpty)
    }

    @Test func presentedNodeCanPresentNestedSheet() throws {
        let rootSheet = PresentationNode(route: .sheet(.filters), path: [.message(301)])

        rootSheet.presentSheet(.composer(replyTo: 301))
        let nestedSheet = try #require(rootSheet.sheet)
        nestedSheet.push(.composer(replyTo: 301))

        #expect(rootSheet.route == .sheet(.filters))
        #expect(rootSheet.path == [.message(301)])
        #expect(nestedSheet.route == .sheet(.composer(replyTo: 301)))
        #expect(nestedSheet.path == [.composer(replyTo: 301)])
    }

    @Test func closingNestedSheetReturnsToParentSheet() throws {
        let router = Router()
        router.presentSheet(.filters)
        let filterSheet = try #require(router.sheet)

        // 这是 nested present 的关键回归：关闭 child sheet 后仍然停留在 parent Filter sheet。
        filterSheet.presentSheet(.composer(replyTo: nil))
        #expect(filterSheet.sheet?.route == .sheet(.composer(replyTo: nil)))

        filterSheet.dismissSheet()

        #expect(router.sheet === filterSheet)
        #expect(router.sheet?.route == .sheet(.filters))
        #expect(filterSheet.sheet == nil)
    }

    @Test func presentedNodeCanPresentNestedFullScreenCover() throws {
        let rootCover = PresentationNode(route: .fullScreen(.onboarding), path: [.settingsDetail("account")])

        rootCover.presentFullScreen(.messagePreview(101))
        let nestedCover = try #require(rootCover.fullScreen)
        nestedCover.push(.message(101))

        #expect(rootCover.route == .fullScreen(.onboarding))
        #expect(rootCover.path == [.settingsDetail("account")])
        #expect(nestedCover.route == .fullScreen(.messagePreview(101)))
        #expect(nestedCover.path == [.message(101)])
    }

    @Test func presentationNodesCanNestMultipleLevels() throws {
        let rootSheet = PresentationNode(route: .sheet(.filters))
        rootSheet.presentSheet(.composer(replyTo: nil))

        let childSheet = try #require(rootSheet.sheet)
        childSheet.presentFullScreen(.messagePreview(101))

        let grandchildCover = try #require(childSheet.fullScreen)
        grandchildCover.push(.message(101))

        #expect(rootSheet.route == .sheet(.filters))
        #expect(childSheet.route == .sheet(.composer(replyTo: nil)))
        #expect(grandchildCover.route == .fullScreen(.messagePreview(101)))
        #expect(grandchildCover.path == [.message(101)])
    }

    @Test func hotDeepLinkDismissesActivePresentationTreeBeforeRouting() throws {
        let message = DemoData.messages[0]
        let router = Router()
        router.presentSheet(.filters)
        let sheet = try #require(router.sheet)
        sheet.presentSheet(.composer(replyTo: 101))

        // Hot link 来时先清 root presentation tree，把真实跳转延后到 dismiss 完成后。
        router.openDeepLink(.message(message))

        #expect(router.sheet == nil)
        #expect(router.fullScreen == nil)
        #expect(router.deferredDeepLink == .message(message))
        #expect(router.inboxPath.isEmpty)

        router.applyDeferredDeepLinkIfReady()

        #expect(router.inboxPath == [.collection(message.collectionID), .message(message.id)])
        #expect(router.deferredDeepLink == nil)
    }

    @Test func coldLaunchDeepLinkAppliesImmediately() {
        let message = DemoData.messages[1]
        let router = Router()

        router.openColdLaunchDeepLink(.message(message))

        #expect(router.selectedTab == .inbox)
        #expect(router.inboxPath == [.collection(message.collectionID), .message(message.id)])
        #expect(router.sheet == nil)
        #expect(router.fullScreen == nil)
    }

    @Test func presentedViewCanStillNavigateBehindPresentationWhenRequested() throws {
        let message = DemoData.messages[4]
        let router = Router()
        router.presentSheet(.filters)
        let sheet = try #require(router.sheet)

        router.push(.message(message.id), on: .inbox)

        #expect(sheet.route == .sheet(.filters))
        #expect(router.inboxPath == [.message(message.id)])
    }

    @Test func parserSupportsMessageURLs() throws {
        let url = try #require(URL(string: "swiftuinavigationhandling://message/101"))

        let deepLink = DeepLinkParser.deepLink(from: url)

        #expect(deepLink == .message(DemoData.messages[0]))
    }

    @Test func parserSupportsLaunchArguments() {
        let deepLink = DeepLinkParser.deepLink(
            from: ["App", "--deep-link", "swiftuinavigationhandling://settings/notifications"]
        )

        #expect(deepLink == .settingsDetail(DemoData.settings[1]))
    }
}
