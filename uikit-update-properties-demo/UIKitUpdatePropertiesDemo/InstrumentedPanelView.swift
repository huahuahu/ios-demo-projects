import UIKit

final class InstrumentedPanelView: UIView {
    let recorder = LifecycleEventRecorder()
    let logView = LogView()

    var state: DemoState {
        didSet {
            setNeedsUpdateProperties()
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }

    private let statusLabel = UILabel()
    private let detailView = UIView()
    private let detailLabel = UILabel()
    private var detailHeightConstraint: NSLayoutConstraint!

    init(state: DemoState) {
        self.state = state
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateProperties() {
        super.updateProperties()
        recorder.record(.updateProperties, note: "UIView read observable state")
        statusLabel.text = state.statusText
        detailView.isHidden = state.isDetailHidden
        detailLabel.text = state.isDetailHidden ? "Hidden by state" : "Visible detail area"
        refreshLog()
    }

    override func updateConstraints() {
        recorder.record(.updateConstraints, note: "UIView applied height constraint = \(Int(state.detailHeight))")
        detailHeightConstraint.constant = state.detailHeight
        refreshLog()
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        recorder.record(.layoutSubviews, note: "UIView laid out subviews")
        refreshLog()
    }

    func refreshLog() {
        logView.update(recorder: recorder)
    }

    func clearLog() {
        recorder.clear()
        refreshLog()
    }

    private func configure() {
        backgroundColor = .systemBackground

        statusLabel.font = .preferredFont(forTextStyle: .callout)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel

        detailView.backgroundColor = .systemBlue.withAlphaComponent(0.14)
        detailView.layer.cornerRadius = 16

        detailLabel.font = .preferredFont(forTextStyle: .headline)
        detailLabel.textAlignment = .center
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(detailLabel)

        detailHeightConstraint = detailView.heightAnchor.constraint(equalToConstant: state.detailHeight)

        let explanationLabel = UILabel()
        explanationLabel.text = "UIView experiment: updateProperties updates state-derived properties. Constraint changes only happen in updateConstraints when constraints are invalidated."
        explanationLabel.font = .preferredFont(forTextStyle: .body)
        explanationLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [explanationLabel, statusLabel, detailView, logView])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            detailHeightConstraint,
            detailLabel.centerXAnchor.constraint(equalTo: detailView.centerXAnchor),
            detailLabel.centerYAnchor.constraint(equalTo: detailView.centerYAnchor)
        ])
    }
}
