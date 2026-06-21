import SwiftUI
import Testing
@testable import InterruptibleAnimationDemo

@MainActor
struct SwiftUIInterruptibleDemoTests {
    @Test func swiftUIComparisonViewLoadsInAHostingController() {
        let hostingController = UIHostingController(rootView: SwiftUIInterruptibleDemoView())

        hostingController.loadViewIfNeeded()

        #expect(hostingController.view != nil)
    }
}
