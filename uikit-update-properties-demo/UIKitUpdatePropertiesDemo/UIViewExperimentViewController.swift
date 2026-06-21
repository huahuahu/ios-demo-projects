import UIKit

final class UIViewExperimentViewController: UIViewController {
    private let state = DemoState()
    private lazy var panelView = InstrumentedPanelView(state: state)

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIView"
        configure()
    }

    private func configure() {
        let buttonStack = UIStackView(arrangedSubviews: [
            makeButton(for: .toggleHidden),
            makeButton(for: .constraintUpdate),
            makeButton(for: .layoutOnly),
            makeClearButton()
        ])
        buttonStack.axis = .vertical
        buttonStack.spacing = 10

        let rootStack = UIStackView(arrangedSubviews: [buttonStack, panelView])
        rootStack.axis = .vertical
        rootStack.spacing = 16
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeButton(for action: DemoAction) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = action.title
        configuration.subtitle = action.explanation

        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.apply(action)
        }, for: .touchUpInside)
        return button
    }

    private func makeClearButton() -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Clear log"

        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.panelView.clearLog()
        }, for: .touchUpInside)
        return button
    }

    private func apply(_ action: DemoAction) {
        state.apply(action)

        switch action.expectation {
        case .propertiesOnly:
            break
        case .trackedConstraints:
            // updateConstraints() reads state.detailHeight, so observation tracking re-runs it automatically.
            break
        case .propertiesAndLayout:
            panelView.setNeedsLayout()
        }
    }
}
