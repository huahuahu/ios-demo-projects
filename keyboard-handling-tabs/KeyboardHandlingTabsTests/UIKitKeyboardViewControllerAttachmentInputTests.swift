import Testing
import UIKit
@testable import KeyboardHandlingTabs

@MainActor
struct UIKitKeyboardViewControllerAttachmentInputTests {
    @Test
    func controllerInstallsInvisibleAttachmentInputHost() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let hostView = try #require(controller.view.firstSubview(ofType: AttachmentInputHostView.self))

            #expect((hostView.inputView as? AttachmentInputView) != nil)
            #expect(hostView.alpha == 0)
            #expect(hostView.isHidden == false)
        }
    }

    @Test
    func attachAndDismissActionsSwitchAttachmentHostResponderState() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let hostView = try #require(controller.view.firstSubview(ofType: AttachmentInputHostView.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let dismissButton = try #require(controller.view.button(named: KeyboardAction.dismissKeyboard.title))

            attachButton.sendActions(for: .touchUpInside)
            #expect(hostView.isFirstResponder)

            dismissButton.sendActions(for: .touchUpInside)
            #expect(!hostView.isFirstResponder)
        }
    }

    private func makeVisibleController() throws -> (UIWindow, UIKitKeyboardViewController) {
        let windowScene = try #require(
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
        )
        let window = UIWindow(windowScene: windowScene)
        window.frame = windowScene.screen.bounds
        let controller = UIKitKeyboardViewController()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        return (window, controller)
    }
}
