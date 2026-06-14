import UIKit

@MainActor
enum DemoStyle {
    static let backgroundColor = UIColor.systemGroupedBackground
    static let cardColor = UIColor.secondarySystemGroupedBackground
    static let guideColor = UIColor.systemTeal.withAlphaComponent(0.18)
    static let guideBorderColor = UIColor.systemTeal.cgColor
    static let spacerColor = UIColor.systemOrange.withAlphaComponent(0.25)
    static let viewColor = UIColor.systemBlue.withAlphaComponent(0.2)
    static let viewBorderColor = UIColor.systemBlue.cgColor

    static func makeBodyLabel(text: String = "") -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }

    static func makeHeadlineLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = .label
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        return label
    }

    static func makeMonospacedLabel(text: String = "") -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = .label
        label.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }

    static func makeCardView(borderColor: CGColor = viewBorderColor, fillColor: UIColor = viewColor) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = fillColor
        view.layer.borderColor = borderColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 12
        return view
    }

    static func makeGuideProxyView() -> UIView {
        let view = makeCardView(borderColor: guideBorderColor, fillColor: guideColor)
        view.isUserInteractionEnabled = false
        return view
    }

    static func makeSectionStack() -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        stack.backgroundColor = cardColor
        stack.layer.cornerRadius = 16
        return stack
    }
}
