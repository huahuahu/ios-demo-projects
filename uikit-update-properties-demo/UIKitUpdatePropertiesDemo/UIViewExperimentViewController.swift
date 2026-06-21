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
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

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
        scrollView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            rootStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            rootStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
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
