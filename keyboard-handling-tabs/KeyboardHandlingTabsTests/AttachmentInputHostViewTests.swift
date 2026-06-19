import Testing
import UIKit
@testable import KeyboardHandlingTabs

@MainActor
struct AttachmentInputHostViewTests {
    @Test
    func canBecomeFirstResponderAndReturnsProvidedInputView() {
        let inputView = AttachmentInputView { _ in }
        let hostView = AttachmentInputHostView(inputView: inputView)

        #expect(hostView.canBecomeFirstResponder)
        #expect(hostView.inputView === inputView)
    }

    @Test
    func staysInvisibleWithoutLeavingResponderHierarchy() {
        let inputView = AttachmentInputView { _ in }
        let hostView = AttachmentInputHostView(inputView: inputView)

        #expect(hostView.alpha == 0)
        #expect(hostView.isHidden == false)
        #expect(hostView.isUserInteractionEnabled == false)
        #expect(hostView.isAccessibilityElement == false)
        #expect(hostView.accessibilityElementsHidden == true)
    }
}
