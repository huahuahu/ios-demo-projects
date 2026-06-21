import UIKit

final class UIViewControllerExperimentViewController: UIViewController {
    private let state = DemoState()
    private let recorder = LifecycleEventRecorder()
    private let statusLabel = UILabel()
    private let titlePreviewLabel = UILabel()
    private let logView = LogView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIViewController"
        configure()
    }

    override func updateProperties() {
        super.updateProperties()
        recorder.record(.updateProperties, note: "UIViewController read observable state")
        title = state.isDetailHidden ? "VC Hidden State" : "UIViewController"
        titlePreviewLabel.text = state.isDetailHidden ? "Controller title changed by state" : "Controller title is normal"
        statusLabel.text = state.statusText
        refreshLog()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        recorder.record(.viewWillLayoutSubviews, note: "Controller before view layout")
        refreshLog()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recorder.record(.viewDidLayoutSubviews, note: "Controller after view layout")
        refreshLog()
    }

    private func configure() {
        view.backgroundColor = .systemBackground

        let explanationLabel = UILabel()
        explanationLabel.text = "UIViewController experiment: updateProperties() tracks its own observable dependencies, independent of view layout callbacks. Constraints tracking depends on what updateConstraints() reads — controller property tracking and constraints tracking are separate concerns."
        explanationLabel.font = .preferredFont(forTextStyle: .body)
        explanationLabel.numberOfLines = 0

        titlePreviewLabel.font = .preferredFont(forTextStyle: .headline)
        titlePreviewLabel.numberOfLines = 0

        statusLabel.font = .preferredFont(forTextStyle: .callout)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0

        let buttonStack = UIStackView(arrangedSubviews: [
            makeButton(for: .toggleHidden),
            makeButton(for: .layoutOnly),
            makeClearButton()
        ])
        buttonStack.axis = .vertical
        buttonStack.spacing = 10

        let rootStack = UIStackView(arrangedSubviews: [explanationLabel, buttonStack, titlePreviewLabel, statusLabel, logView])
        rootStack.axis = .vertical
        rootStack.spacing = 16
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            rootStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
            self?.recorder.clear()
            self?.refreshLog()
        }, for: .touchUpInside)
        return button
    }

    private func apply(_ action: DemoAction) {
        state.apply(action)

        if action.expectation == .propertiesAndLayout {
            view.setNeedsLayout()
        }
    }

    private func refreshLog() {
        logView.update(recorder: recorder)
    }
}
