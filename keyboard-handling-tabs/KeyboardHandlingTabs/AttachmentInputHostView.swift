import UIKit

@MainActor
final class AttachmentInputHostView: UIView {
    private let providedInputView: UIInputView

    init(inputView: UIInputView) {
        self.providedInputView = inputView
        super.init(frame: .zero)
        alpha = 0
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var inputView: UIView? {
        providedInputView
    }
}
