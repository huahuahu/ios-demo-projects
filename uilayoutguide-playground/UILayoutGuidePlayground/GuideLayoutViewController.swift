import UIKit

final class GuideLayoutViewController: UIViewController {
    private let headerGuide = UILayoutGuide()
    private let sidebarGuide = UILayoutGuide()
    private let contentGuide = UILayoutGuide()
    private let buttonRowGuide = UILayoutGuide()

    private let headerView = DemoStyle.makeCardView(borderColor: UIColor.systemPurple.cgColor, fillColor: UIColor.systemPurple.withAlphaComponent(0.16))
    private let sidebarView = DemoStyle.makeCardView(borderColor: UIColor.systemIndigo.cgColor, fillColor: UIColor.systemIndigo.withAlphaComponent(0.16))
    private let contentView = DemoStyle.makeCardView(borderColor: UIColor.systemGreen.cgColor, fillColor: UIColor.systemGreen.withAlphaComponent(0.16))
    private let buttonRowView = DemoStyle.makeCardView(borderColor: UIColor.systemPink.cgColor, fillColor: UIColor.systemPink.withAlphaComponent(0.16))
    private let detailLabel = DemoStyle.makeBodyLabel()
    private let controlsStack = DemoStyle.makeSectionStack()

    private var sidebarWidthConstraint: NSLayoutConstraint?
    private var buttonRowHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Guide Layout"
        view.backgroundColor = DemoStyle.backgroundColor

        setupGuides()
        setupViews()
        setupConstraints()
        updateDetailLabel(isExpanded: false)
    }

    private func setupGuides() {
        headerGuide.identifier = "headerGuide"
        sidebarGuide.identifier = "sidebarGuide"
        contentGuide.identifier = "contentGuide"
        buttonRowGuide.identifier = "buttonRowGuide"

        [headerGuide, sidebarGuide, contentGuide, buttonRowGuide].forEach(view.addLayoutGuide)
    }

    private func setupViews() {
        let segmentedControl = UISegmentedControl(items: ["Compact", "Expanded"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(layoutModeChanged(_:)), for: .valueChanged)

        let intro = DemoStyle.makeBodyLabel(
            text: """
            Four custom layout guides define invisible regions. The colored UIViews are pinned to those guides, so changing guide constraints reshapes the visible interface.
            """
        )

        headerView.addSubview(DemoStyle.makeHeadlineLabel(text: "Header UIView -> headerGuide"))
        sidebarView.addSubview(DemoStyle.makeHeadlineLabel(text: "Sidebar"))
        contentView.addSubview(DemoStyle.makeHeadlineLabel(text: "Content UIView follows contentGuide"))
        buttonRowView.addSubview(DemoStyle.makeHeadlineLabel(text: "Button row -> buttonRowGuide"))

        controlsStack.addArrangedSubview(intro)
        controlsStack.addArrangedSubview(segmentedControl)
        controlsStack.addArrangedSubview(detailLabel)

        view.addSubview(controlsStack)
        view.addSubview(headerView)
        view.addSubview(sidebarView)
        view.addSubview(contentView)
        view.addSubview(buttonRowView)

        centerFirstLabel(in: headerView)
        centerFirstLabel(in: sidebarView)
        centerFirstLabel(in: contentView)
        centerFirstLabel(in: buttonRowView)

        NSLayoutConstraint.activate([
            controlsStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            controlsStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            controlsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    private func setupConstraints() {
        let sidebarWidthConstraint = sidebarGuide.widthAnchor.constraint(equalToConstant: 84)
        let buttonRowHeightConstraint = buttonRowGuide.heightAnchor.constraint(equalToConstant: 56)
        self.sidebarWidthConstraint = sidebarWidthConstraint
        self.buttonRowHeightConstraint = buttonRowHeightConstraint

        NSLayoutConstraint.activate([
            headerGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            headerGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            headerGuide.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 16),
            headerGuide.heightAnchor.constraint(equalToConstant: 72),

            sidebarGuide.leadingAnchor.constraint(equalTo: headerGuide.leadingAnchor),
            sidebarGuide.topAnchor.constraint(equalTo: headerGuide.bottomAnchor, constant: 16),
            sidebarGuide.bottomAnchor.constraint(equalTo: buttonRowGuide.topAnchor, constant: -16),
            sidebarWidthConstraint,

            contentGuide.leadingAnchor.constraint(equalTo: sidebarGuide.trailingAnchor, constant: 12),
            contentGuide.trailingAnchor.constraint(equalTo: headerGuide.trailingAnchor),
            contentGuide.topAnchor.constraint(equalTo: sidebarGuide.topAnchor),
            contentGuide.bottomAnchor.constraint(equalTo: sidebarGuide.bottomAnchor),

            buttonRowGuide.leadingAnchor.constraint(equalTo: headerGuide.leadingAnchor),
            buttonRowGuide.trailingAnchor.constraint(equalTo: headerGuide.trailingAnchor),
            buttonRowGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonRowHeightConstraint,

            headerView.leadingAnchor.constraint(equalTo: headerGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: headerGuide.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: headerGuide.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: headerGuide.bottomAnchor),

            sidebarView.leadingAnchor.constraint(equalTo: sidebarGuide.leadingAnchor),
            sidebarView.trailingAnchor.constraint(equalTo: sidebarGuide.trailingAnchor),
            sidebarView.topAnchor.constraint(equalTo: sidebarGuide.topAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: sidebarGuide.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),

            buttonRowView.leadingAnchor.constraint(equalTo: buttonRowGuide.leadingAnchor),
            buttonRowView.trailingAnchor.constraint(equalTo: buttonRowGuide.trailingAnchor),
            buttonRowView.topAnchor.constraint(equalTo: buttonRowGuide.topAnchor),
            buttonRowView.bottomAnchor.constraint(equalTo: buttonRowGuide.bottomAnchor)
        ])
    }

    @objc private func layoutModeChanged(_ sender: UISegmentedControl) {
        let isExpanded = sender.selectedSegmentIndex == 1
        sidebarWidthConstraint?.constant = isExpanded ? 132 : 84
        buttonRowHeightConstraint?.constant = isExpanded ? 88 : 56
        updateDetailLabel(isExpanded: isExpanded)

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateDetailLabel(isExpanded: Bool) {
        detailLabel.text = """
        Active guide constraints:
        sidebarGuide.width = \(isExpanded ? 132 : 84)
        buttonRowGuide.height = \(isExpanded ? 88 : 56)
        """
    }

    private func centerFirstLabel(in view: UIView) {
        guard let label = view.subviews.first else {
            return
        }

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -10)
        ])
    }
}
