import SwiftUI
import Testing
import UIKit
@testable import KeyboardHandlingTabs

@MainActor
struct KeyboardRootTabBarControllerTests {
    @Test
    func rootTabBarControllerInstallsSwiftUIAndUIKitTabs() throws {
        let controller = KeyboardRootTabBarController()

        controller.loadViewIfNeeded()

        let viewControllers = try #require(controller.viewControllers)
        #expect(viewControllers.count == 2)
        #expect(viewControllers[0] is UIHostingController<SwiftUIKeyboardTabView>)

        let navigationController = try #require(viewControllers[1] as? UINavigationController)
        #expect(navigationController.viewControllers.first is UIKitKeyboardViewController)
        #expect(viewControllers[0].tabBarItem.title == "SwiftUI")
        #expect(viewControllers[1].tabBarItem.title == "UIKit")
    }
}
