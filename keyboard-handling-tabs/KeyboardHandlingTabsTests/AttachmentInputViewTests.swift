import Testing
import UIKit
@testable import KeyboardHandlingTabs

@MainActor
struct AttachmentInputViewTests {
    @Test
    func rendersEveryAttachmentSourceAsAButton() {
        let inputView = AttachmentInputView { _ in }

        let titles = Set(inputView.allButtons().compactMap { $0.configuration?.title })

        #expect(titles == Set(AttachmentSource.allCases.map(\.rawValue)))
    }

    @Test
    func tappingSourceButtonReportsSelectedSource() throws {
        var selectedSource: AttachmentSource?
        let inputView = AttachmentInputView { source in
            selectedSource = source
        }

        let cameraButton = try #require(inputView.button(named: AttachmentSource.camera.rawValue))
        cameraButton.sendActions(for: .touchUpInside)

        #expect(selectedSource == .camera)
    }

    @Test
    func fittingHeightComesFromContentInsteadOfFixedPanelConstant() {
        let inputView = AttachmentInputView { _ in }
        inputView.frame = CGRect(x: 0, y: 0, width: 390, height: 1)
        inputView.setNeedsLayout()
        inputView.layoutIfNeeded()

        let fittingSize = inputView.systemLayoutSizeFitting(
            CGSize(width: 390, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        #expect(fittingSize.height > 120)
    }

    @Test
    func startsWithNonZeroFrameForUIKitInputViewAttachment() {
        let inputView = AttachmentInputView { _ in }

        #expect(inputView.frame.width > 0)
        #expect(inputView.frame.height > 120)
    }

    @Test
    func sourceOptionsUseMinimumHeightInsteadOfFixedHeight() throws {
        let inputView = AttachmentInputView { _ in }
        let optionsStackView = try #require(inputView.firstSubview(ofType: UIStackView.self))

        let heightConstraints = (inputView.constraints + optionsStackView.constraints).filter { constraint in
            (constraint.firstItem as? UIStackView) === optionsStackView
                && constraint.firstAttribute == .height
        }

        #expect(heightConstraints.contains { constraint in
            constraint.relation == .greaterThanOrEqual && constraint.constant == 96
        })
        #expect(!heightConstraints.contains { constraint in
            constraint.relation == .equal && constraint.constant == 96
        })
    }
}
