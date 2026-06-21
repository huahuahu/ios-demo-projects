import UIKit

final class LogView: UIView {
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let eventLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(recorder: LifecycleEventRecorder) {
        summaryLabel.text = recorder.summaryLines().joined(separator: "\n")
        eventLabel.text = recorder.eventLines().joined(separator: "\n")
    }

    private func configure() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 14

        titleLabel.text = "Lifecycle log"
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        summaryLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        summaryLabel.numberOfLines = 0

        eventLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        eventLabel.numberOfLines = 0
        eventLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel, eventLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }
}
