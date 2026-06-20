import Testing
import UIKit
@testable import KeyboardHandlingTabs

@MainActor
struct UIKitKeyboardViewControllerAttachmentInputTests {
    @Test
    func controllerInstallsAppOwnedAttachmentPanel() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))
            let titleLabel = try #require(controller.view.label(withAccessibilityIdentifier: "UIKitAttachmentPanelTitle"))
            let optionsStack = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanelOptions"))

            #expect(panel.isHidden)
            #expect(titleLabel.text == "Choose attachment source")
            let hostViews = controller.view.allSubviews().filter { view in
                String(describing: type(of: view)) == "AttachmentInputHostView"
            }

            #expect(optionsStack is UIStackView)
            #expect(hostViews.isEmpty)
        }
    }

    @Test
    func controllerStartsWithComposerPinnedToBottomWhenNoInputSurfaceIsActive() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let keyboardConstraint = try #require(
                mirroredConstraint(named: "composerBottomToKeyboardConstraint", in: controller)
            )
            let bottomConstraint = try #require(
                mirroredConstraint(named: "composerBottomToBottomConstraint", in: controller)
            )

            #expect(!keyboardConstraint.isActive)
            #expect(bottomConstraint.isActive)
        }
    }

    @Test
    func attachmentPanelIsPinnedBehindTabBarAndKeyboardArea() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let panelBottomConstraint = try #require(
                mirroredConstraint(named: "attachmentPanelBottomConstraint", in: controller)
            )

            #expect(panelBottomConstraint.firstItem as? UIView === controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))
            #expect(panelBottomConstraint.firstAttribute == .bottom)
            #expect(panelBottomConstraint.secondItem as? UIView === controller.view)
            #expect(panelBottomConstraint.secondAttribute == .bottom)
        }
    }

    @Test
    func attachActionResignsFocusedTextFieldAndShowsAttachmentPanel() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))

            #expect(draftTextField.becomeFirstResponder())
            #expect(draftTextField.isFirstResponder)

            attachButton.sendActions(for: .touchUpInside)

            #expect(!draftTextField.isFirstResponder)
            #expect(!panel.isHidden)
            #expect(panel.alpha == 1)
        }
    }

    @Test
    func attachActionPinsComposerAboveKeyboardAndAttachmentUntilKeyboardFinishesHiding() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let panelConstraint = try #require(
                mirroredConstraint(named: "composerBottomToAttachmentPanelConstraint", in: controller)
            )
            let aboveKeyboardConstraint = try #require(
                mirroredConstraint(named: "composerBottomAboveKeyboardDuringPanelCoverConstraint", in: controller)
            )
            let abovePanelConstraint = try #require(
                mirroredConstraint(named: "composerBottomAboveAttachmentDuringPanelCoverConstraint", in: controller)
            )
            let pullDownConstraint = try #require(
                mirroredConstraint(named: "composerBottomPullDownDuringPanelCoverConstraint", in: controller)
            )

            #expect(draftTextField.delegate?.textFieldShouldBeginEditing?(draftTextField) ?? true)
            attachButton.sendActions(for: .touchUpInside)

            #expect(!panelConstraint.isActive)
            #expect(aboveKeyboardConstraint.isActive)
            #expect(abovePanelConstraint.isActive)
            #expect(pullDownConstraint.isActive)

            postKeyboardDidHide()

            #expect(panelConstraint.isActive)
            #expect(!aboveKeyboardConstraint.isActive)
            #expect(!abovePanelConstraint.isActive)
            #expect(!pullDownConstraint.isActive)
        }
    }

    @Test
    func beginningTextFieldEditingKeepsAttachmentPanelUntilKeyboardCoversIt() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            #expect(draftTextField.delegate?.textFieldShouldBeginEditing?(draftTextField) ?? true)

            #expect(!panel.isHidden)
            postKeyboardDidShow()

            #expect(panel.isHidden)
        }
    }

    @Test
    func beginningTextFieldEditingPinsComposerAboveKeyboardAndAttachmentDuringCoverTransition() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let keyboardConstraint = try #require(
                mirroredConstraint(named: "composerBottomToKeyboardConstraint", in: controller)
            )
            let panelConstraint = try #require(
                mirroredConstraint(named: "composerBottomToAttachmentPanelConstraint", in: controller)
            )
            let aboveKeyboardConstraint = try #require(
                mirroredConstraint(named: "composerBottomAboveKeyboardDuringPanelCoverConstraint", in: controller)
            )
            let abovePanelConstraint = try #require(
                mirroredConstraint(named: "composerBottomAboveAttachmentDuringPanelCoverConstraint", in: controller)
            )
            let pullDownConstraint = try #require(
                mirroredConstraint(named: "composerBottomPullDownDuringPanelCoverConstraint", in: controller)
            )

            attachButton.sendActions(for: .touchUpInside)
            #expect(draftTextField.delegate?.textFieldShouldBeginEditing?(draftTextField) ?? true)

            #expect(!keyboardConstraint.isActive)
            #expect(!panelConstraint.isActive)
            #expect(aboveKeyboardConstraint.isActive)
            #expect(abovePanelConstraint.isActive)
            #expect(pullDownConstraint.isActive)
        }
    }

    @Test
    func attachDuringKeyboardPresentationCancelsPanelCoverAndResignsTextField() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            #expect(draftTextField.delegate?.textFieldShouldBeginEditing?(draftTextField) ?? true)
            #expect(draftTextField.becomeFirstResponder())
            #expect(draftTextField.isFirstResponder)
            #expect(!panel.isHidden)

            attachButton.sendActions(for: .touchUpInside)

            #expect(!draftTextField.isFirstResponder)
            #expect(!panel.isHidden)

            postKeyboardDidShow()

            #expect(!panel.isHidden)
        }
    }

    @Test
    func dismissDuringKeyboardPresentationDismissesKeyboardBeforeReturningComposerToBottom() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let dismissButton = try #require(controller.view.button(named: KeyboardAction.dismissKeyboard.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            #expect(draftTextField.delegate?.textFieldShouldBeginEditing?(draftTextField) ?? true)
            #expect(draftTextField.becomeFirstResponder())
            #expect(draftTextField.isFirstResponder)

            dismissButton.sendActions(for: .touchUpInside)

            #expect(!draftTextField.isFirstResponder)
            #expect(panel.isHidden)

            postKeyboardDidShow()

            #expect(panel.isHidden)
        }
    }

    @Test
    func selectingAttachmentDuringKeyboardPresentationKeepsComposerWithKeyboard() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let photoButton = try #require(controller.view.button(named: AttachmentSource.photoLibrary.rawValue))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))
            let keyboardConstraint = try #require(
                mirroredConstraint(named: "composerBottomToKeyboardConstraint", in: controller)
            )
            let bottomConstraint = try #require(
                mirroredConstraint(named: "composerBottomToBottomConstraint", in: controller)
            )

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            #expect(draftTextField.delegate?.textFieldShouldBeginEditing?(draftTextField) ?? true)
            #expect(draftTextField.becomeFirstResponder())
            #expect(draftTextField.isFirstResponder)

            photoButton.sendActions(for: .touchUpInside)

            #expect(draftTextField.text == AttachmentSource.photoLibrary.token)
            #expect(panel.isHidden)
            #expect(keyboardConstraint.isActive)
            #expect(!bottomConstraint.isActive)

            postKeyboardDidShow()

            #expect(panel.isHidden)
            #expect(keyboardConstraint.isActive)
            #expect(!bottomConstraint.isActive)
        }
    }

    @Test
    func selectingAttachmentSourceUpdatesDraftAndDismissesAttachmentPanel() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let draftTextField = try #require(controller.view.firstSubview(ofType: UITextField.self))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))
            let photoButton = try #require(controller.view.button(named: AttachmentSource.photoLibrary.rawValue))

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)

            photoButton.sendActions(for: .touchUpInside)

            #expect(draftTextField.text == AttachmentSource.photoLibrary.token)
            #expect(panel.isHidden)
        }
    }

    @Test
    func dismissActionSlidesAttachmentPanelDownWhenPanelIsActive() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let dismissButton = try #require(controller.view.button(named: KeyboardAction.dismissKeyboard.title))
            let panel = try #require(controller.view.subview(withAccessibilityIdentifier: "UIKitAttachmentPanel"))
            let panelBottomConstraint = try #require(
                mirroredConstraint(named: "attachmentPanelBottomConstraint", in: controller)
            )
            let panelConstraint = try #require(
                mirroredConstraint(named: "composerBottomToAttachmentPanelConstraint", in: controller)
            )
            let bottomConstraint = try #require(
                mirroredConstraint(named: "composerBottomToBottomConstraint", in: controller)
            )

            attachButton.sendActions(for: .touchUpInside)
            #expect(!panel.isHidden)
            #expect(panelBottomConstraint.constant == 0)

            dismissButton.sendActions(for: .touchUpInside)

            #expect(!panel.isHidden)
            #expect(panelBottomConstraint.constant > 0)
            #expect(panelConstraint.isActive)
            #expect(!bottomConstraint.isActive)
        }
    }

    @Test
    func attachActionDoesNotReanimateWhenAttachmentPanelIsAlreadyActive() throws {
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let panelBottomConstraint = try #require(
                mirroredConstraint(named: "attachmentPanelBottomConstraint", in: controller)
            )

            attachButton.sendActions(for: .touchUpInside)
            #expect(panelBottomConstraint.constant == 0)

            attachButton.sendActions(for: .touchUpInside)

            #expect(panelBottomConstraint.constant == 0)
        }
    }

    @Test
    func dismissingAttachmentPanelKeepsComposerAtBottomEvenIfKeyboardGuideStillTracksKeyboard() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let attachButton = try #require(controller.view.button(named: KeyboardAction.attach.title))
            let dismissButton = try #require(controller.view.button(named: KeyboardAction.dismissKeyboard.title))
            let textField = try #require(controller.view.textField())
            let composerContainer = try #require(controller.view.directSubviewContaining(textField))
            #expect(activeKeyboardConstraints(in: controller, for: composerContainer).isEmpty)

            attachButton.sendActions(for: .touchUpInside)
            dismissButton.sendActions(for: .touchUpInside)
            controller.view.layoutIfNeeded()

            #expect(activeKeyboardConstraints(in: controller, for: composerContainer).isEmpty)
        }
    }

    @Test
    func dismissingKeyboardKeepsComposerWithKeyboardUntilKeyboardFinishesHiding() throws {
        let (window, controller) = try makeVisibleController()

        try withExtendedLifetime(window) {
            let dismissButton = try #require(controller.view.button(named: KeyboardAction.dismissKeyboard.title))
            let textField = try #require(controller.view.textField())
            let keyboardConstraint = try #require(
                mirroredConstraint(named: "composerBottomToKeyboardConstraint", in: controller)
            )
            let bottomConstraint = try #require(
                mirroredConstraint(named: "composerBottomToBottomConstraint", in: controller)
            )
            #expect(textField.delegate?.textFieldShouldBeginEditing?(textField) ?? true)

            #expect(keyboardConstraint.isActive)
            #expect(!bottomConstraint.isActive)

            dismissButton.sendActions(for: .touchUpInside)
            controller.view.layoutIfNeeded()

            #expect(keyboardConstraint.isActive)
            #expect(!bottomConstraint.isActive)

            postKeyboardFrameChange(to: controller, endFrameInView: CGRect(
                x: 0,
                y: controller.view.bounds.maxY + controller.view.safeAreaInsets.bottom,
                width: controller.view.bounds.width,
                height: 0
            ))
            controller.view.layoutIfNeeded()

            #expect(keyboardConstraint.isActive)
            #expect(!bottomConstraint.isActive)

            postKeyboardDidHide()
            controller.view.layoutIfNeeded()

            #expect(!keyboardConstraint.isActive)
            #expect(bottomConstraint.isActive)
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

    private func activeKeyboardConstraints(
        in controller: UIKitKeyboardViewController,
        for composerContainer: UIView
    ) -> [NSLayoutConstraint] {
        controller.view.constraints.filter { constraint in
            guard constraint.isActive else {
                return false
            }
            let firstView = constraint.firstItem as? UIView
            let secondView = constraint.secondItem as? UIView
            let firstGuide = constraint.firstItem as? UIKeyboardLayoutGuide
            let secondGuide = constraint.secondItem as? UIKeyboardLayoutGuide
            return (
                firstView === composerContainer
                    && constraint.firstAttribute == .bottom
                    && secondGuide === controller.view.keyboardLayoutGuide
            ) || (
                secondView === composerContainer
                    && constraint.secondAttribute == .bottom
                    && firstGuide === controller.view.keyboardLayoutGuide
            )
        }
    }

    private func mirroredConstraint(
        named name: String,
        in controller: UIKitKeyboardViewController
    ) -> NSLayoutConstraint? {
        Mirror(reflecting: controller).children.first { child in
            child.label == name
        }?.value as? NSLayoutConstraint
    }

    private func postKeyboardFrameChange(
        to controller: UIKitKeyboardViewController,
        endFrameInView: CGRect
    ) {
        guard let coordinateSpace = controller.view.window?.screen.coordinateSpace else {
            return
        }
        let endFrame = controller.view.convert(
            endFrameInView,
            to: coordinateSpace
        )
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: endFrame
            ]
        )
    }

    private func postKeyboardDidHide() {
        NotificationCenter.default.post(
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    private func postKeyboardDidShow() {
        NotificationCenter.default.post(
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
    }
}
