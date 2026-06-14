import UIKit

final class GuideOwnershipViewController: UIViewController {
    private let contentGuide = UILayoutGuide()
    private let guideProxyView = DemoStyle.makeGuideProxyView()
    private let realCardView = DemoStyle.makeCardView()
    private let snapshotLabel = DemoStyle.makeMonospacedLabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Guide Ownership"
        view.backgroundColor = DemoStyle.backgroundColor

        contentGuide.identifier = "customContentGuide"
        view.addLayoutGuide(contentGuide)

        setupViews()
        setupConstraints()
        updateSnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSnapshot()
    }

    private func setupViews() {
        let explanation = DemoStyle.makeBodyLabel(
            text: """
            A UIView can own a UILayoutGuide with addLayoutGuide(_:). The guide is invisible: it does not draw, does not receive touches, and is not listed in subviews. The teal proxy view below only visualizes the guide frame.
            """
        )

        let realCardLabel = DemoStyle.makeHeadlineLabel(text: "Real UIView pinned to the guide")
        let guideLabel = DemoStyle.makeHeadlineLabel(text: "Proxy view mirrors the guide frame")
        let snapshotTitle = DemoStyle.makeHeadlineLabel(text: "Relationship snapshot")

        realCardView.addSubview(realCardLabel)
        guideProxyView.addSubview(guideLabel)

        let stack = DemoStyle.makeSectionStack()
        stack.addArrangedSubview(explanation)
        stack.addArrangedSubview(snapshotTitle)
        stack.addArrangedSubview(snapshotLabel)

        view.addSubview(stack)
        view.addSubview(guideProxyView)
        view.addSubview(realCardView)

        NSLayoutConstraint.activate([
            realCardLabel.centerXAnchor.constraint(equalTo: realCardView.centerXAnchor),
            realCardLabel.centerYAnchor.constraint(equalTo: realCardView.centerYAnchor),
            realCardLabel.leadingAnchor.constraint(greaterThanOrEqualTo: realCardView.leadingAnchor, constant: 12),
            realCardLabel.trailingAnchor.constraint(lessThanOrEqualTo: realCardView.trailingAnchor, constant: -12),

            guideLabel.centerXAnchor.constraint(equalTo: guideProxyView.centerXAnchor),
            guideLabel.topAnchor.constraint(equalTo: guideProxyView.topAnchor, constant: 12),
            guideLabel.leadingAnchor.constraint(greaterThanOrEqualTo: guideProxyView.leadingAnchor, constant: 12),
            guideLabel.trailingAnchor.constraint(lessThanOrEqualTo: guideProxyView.trailingAnchor, constant: -12),

            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 28),
            contentGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -28),
            contentGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 280),
            contentGuide.heightAnchor.constraint(equalToConstant: 140),

            guideProxyView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            guideProxyView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            guideProxyView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            guideProxyView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),

            realCardView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 24),
            realCardView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -24),
            realCardView.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: 24),
            realCardView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -24)
        ])
    }

    private func updateSnapshot() {
        let snapshot = GuideRelationshipProbe.snapshot(owner: view, guide: contentGuide)
        snapshotLabel.text = snapshot.summaryLines.joined(separator: "\n")
    }
}
