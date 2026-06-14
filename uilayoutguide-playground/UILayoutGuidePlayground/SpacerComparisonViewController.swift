import UIKit

final class SpacerComparisonViewController: UIViewController {
    private let spacerWidthLabel = DemoStyle.makeMonospacedLabel()
    private let hierarchyLabel = DemoStyle.makeMonospacedLabel()
    private let spacerRow = UIView()
    private let guideRow = UIView()
    private let spacerView = DemoStyle.makeCardView(borderColor: UIColor.systemOrange.cgColor, fillColor: DemoStyle.spacerColor)
    private let gapGuide = UILayoutGuide()
    private let controlsStack = DemoStyle.makeSectionStack()

    private var spacerWidthConstraint: NSLayoutConstraint?
    private var guideWidthConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Spacer vs Guide"
        view.backgroundColor = DemoStyle.backgroundColor
        setupViews()
        updateGap(width: 48)
    }

    private func setupViews() {
        let intro = DemoStyle.makeBodyLabel(
            text: """
            If an object only exists to reserve space, a UILayoutGuide can often replace a transparent spacer UIView. The top row uses a real spacer view; the bottom row uses an invisible gap guide.
            """
        )

        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 16
        slider.maximumValue = 112
        slider.value = 48
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        controlsStack.addArrangedSubview(intro)
        controlsStack.addArrangedSubview(spacerWidthLabel)
        controlsStack.addArrangedSubview(slider)
        controlsStack.addArrangedSubview(hierarchyLabel)

        view.addSubview(controlsStack)
        view.addSubview(spacerRow)
        view.addSubview(guideRow)

        spacerRow.translatesAutoresizingMaskIntoConstraints = false
        guideRow.translatesAutoresizingMaskIntoConstraints = false
        spacerRow.backgroundColor = .clear
        guideRow.backgroundColor = .clear
        gapGuide.identifier = "gapGuide"
        guideRow.addLayoutGuide(gapGuide)

        setupSpacerRow()
        setupGuideRow()

        NSLayoutConstraint.activate([
            controlsStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            controlsStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            controlsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            spacerRow.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            spacerRow.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            spacerRow.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 24),
            spacerRow.heightAnchor.constraint(equalToConstant: 90),

            guideRow.leadingAnchor.constraint(equalTo: spacerRow.leadingAnchor),
            guideRow.trailingAnchor.constraint(equalTo: spacerRow.trailingAnchor),
            guideRow.topAnchor.constraint(equalTo: spacerRow.bottomAnchor, constant: 28),
            guideRow.heightAnchor.constraint(equalTo: spacerRow.heightAnchor)
        ])
    }

    private func setupSpacerRow() {
        let leftView = labeledBox(title: "Left UIView")
        let rightView = labeledBox(title: "Right UIView")
        let spacerLabel = DemoStyle.makeHeadlineLabel(text: "Spacer UIView")
        spacerView.addSubview(spacerLabel)

        [leftView, spacerView, rightView].forEach(spacerRow.addSubview)

        let spacerWidthConstraint = spacerView.widthAnchor.constraint(equalToConstant: 48)
        self.spacerWidthConstraint = spacerWidthConstraint

        NSLayoutConstraint.activate([
            leftView.leadingAnchor.constraint(equalTo: spacerRow.leadingAnchor),
            leftView.topAnchor.constraint(equalTo: spacerRow.topAnchor),
            leftView.bottomAnchor.constraint(equalTo: spacerRow.bottomAnchor),

            spacerView.leadingAnchor.constraint(equalTo: leftView.trailingAnchor),
            spacerView.topAnchor.constraint(equalTo: spacerRow.topAnchor),
            spacerView.bottomAnchor.constraint(equalTo: spacerRow.bottomAnchor),
            spacerWidthConstraint,

            rightView.leadingAnchor.constraint(equalTo: spacerView.trailingAnchor),
            rightView.trailingAnchor.constraint(equalTo: spacerRow.trailingAnchor),
            rightView.topAnchor.constraint(equalTo: spacerRow.topAnchor),
            rightView.bottomAnchor.constraint(equalTo: spacerRow.bottomAnchor),
            rightView.widthAnchor.constraint(equalTo: leftView.widthAnchor),

            spacerLabel.centerXAnchor.constraint(equalTo: spacerView.centerXAnchor),
            spacerLabel.centerYAnchor.constraint(equalTo: spacerView.centerYAnchor)
        ])
    }

    private func setupGuideRow() {
        let leftView = labeledBox(title: "Left UIView")
        let rightView = labeledBox(title: "Right UIView")
        let guideProxy = DemoStyle.makeGuideProxyView()
        let guideLabel = DemoStyle.makeHeadlineLabel(text: "gapGuide")
        guideProxy.addSubview(guideLabel)

        [leftView, guideProxy, rightView].forEach(guideRow.addSubview)

        let guideWidthConstraint = gapGuide.widthAnchor.constraint(equalToConstant: 48)
        self.guideWidthConstraint = guideWidthConstraint

        NSLayoutConstraint.activate([
            gapGuide.centerXAnchor.constraint(equalTo: guideRow.centerXAnchor),
            gapGuide.topAnchor.constraint(equalTo: guideRow.topAnchor),
            gapGuide.bottomAnchor.constraint(equalTo: guideRow.bottomAnchor),
            guideWidthConstraint,

            leftView.leadingAnchor.constraint(equalTo: guideRow.leadingAnchor),
            leftView.trailingAnchor.constraint(equalTo: gapGuide.leadingAnchor),
            leftView.topAnchor.constraint(equalTo: guideRow.topAnchor),
            leftView.bottomAnchor.constraint(equalTo: guideRow.bottomAnchor),

            guideProxy.leadingAnchor.constraint(equalTo: gapGuide.leadingAnchor),
            guideProxy.trailingAnchor.constraint(equalTo: gapGuide.trailingAnchor),
            guideProxy.topAnchor.constraint(equalTo: gapGuide.topAnchor),
            guideProxy.bottomAnchor.constraint(equalTo: gapGuide.bottomAnchor),

            rightView.leadingAnchor.constraint(equalTo: gapGuide.trailingAnchor),
            rightView.trailingAnchor.constraint(equalTo: guideRow.trailingAnchor),
            rightView.topAnchor.constraint(equalTo: guideRow.topAnchor),
            rightView.bottomAnchor.constraint(equalTo: guideRow.bottomAnchor),
            rightView.widthAnchor.constraint(equalTo: leftView.widthAnchor),

            guideLabel.centerXAnchor.constraint(equalTo: guideProxy.centerXAnchor),
            guideLabel.centerYAnchor.constraint(equalTo: guideProxy.centerYAnchor)
        ])
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        updateGap(width: CGFloat(sender.value))

        UIView.animate(withDuration: 0.15) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateGap(width: CGFloat) {
        let roundedWidth = Int(width.rounded())
        spacerWidthConstraint?.constant = CGFloat(roundedWidth)
        guideWidthConstraint?.constant = CGFloat(roundedWidth)
        spacerWidthLabel.text = "gap width = \(roundedWidth)"
        hierarchyLabel.text = """
        spacer row subviews: \(spacerRow.subviews.count) (left + spacer view + right)
        guide row subviews: \(guideRow.subviews.count) (left + visual proxy + right)
        guide row layoutGuides: \(guideRow.layoutGuides.count) (gapGuide)
        """
    }

    private func labeledBox(title: String) -> UIView {
        let box = DemoStyle.makeCardView()
        let label = DemoStyle.makeHeadlineLabel(text: title)
        box.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: box.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: box.trailingAnchor, constant: -8)
        ])

        return box
    }
}
