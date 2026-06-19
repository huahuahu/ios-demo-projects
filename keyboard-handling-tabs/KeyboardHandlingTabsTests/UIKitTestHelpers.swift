import UIKit

@MainActor
extension UIView {
    func allSubviews() -> [UIView] {
        subviews + subviews.flatMap { $0.allSubviews() }
    }

    func allButtons() -> [UIButton] {
        allSubviews().compactMap { $0 as? UIButton }
    }

    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        allSubviews().compactMap { $0 as? T }.first
    }

    func button(named title: String) -> UIButton? {
        allButtons().first { button in
            button.configuration?.title == title || button.title(for: .normal) == title
        }
    }
}
