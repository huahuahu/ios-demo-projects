import UIKit

@MainActor
extension UIView {
    func allSubviews() -> [UIView] {
        subviews + subviews.flatMap { $0.allSubviews() }
    }

    func allButtons() -> [UIButton] {
        allSubviews().compactMap { $0 as? UIButton }
    }

    func allLabels() -> [UILabel] {
        allSubviews().compactMap { $0 as? UILabel }
    }

    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        allSubviews().compactMap { $0 as? T }.first
    }

    func subview(withAccessibilityIdentifier identifier: String) -> UIView? {
        allSubviews().first { $0.accessibilityIdentifier == identifier }
    }

    func label(withAccessibilityIdentifier identifier: String) -> UILabel? {
        allLabels().first { $0.accessibilityIdentifier == identifier }
    }

    func textField() -> UITextField? {
        firstSubview(ofType: UITextField.self)
    }

    func directSubviewContaining(_ descendant: UIView) -> UIView? {
        subviews.first { subview in
            subview === descendant || subview.allSubviews().contains { $0 === descendant }
        }
    }

    func button(named title: String) -> UIButton? {
        allButtons().first { button in
            button.configuration?.title == title || button.title(for: .normal) == title
        }
    }
}
