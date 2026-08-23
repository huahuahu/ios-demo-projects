import UIKit

class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()
    private var paletteIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: GradientView, _) in
            view.updateColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(paletteIndex: Int) {
        self.paletteIndex = paletteIndex
        updateColors()
    }

    private func updateColors() {
        let lightPalettes: [[UIColor]] = [
            [.systemBlue, .systemPurple],
            [.systemOrange, .systemYellow],
            [.systemGreen, .systemBlue],
            [.systemIndigo, .systemPink],
            [.systemGreen, .systemYellow],
            [.systemBlue, .systemPurple]
        ]
        let darkPalettes: [[UIColor]] = [
            [UIColor(red: 0.10, green: 0.21, blue: 0.40, alpha: 1), UIColor(red: 0.33, green: 0.16, blue: 0.42, alpha: 1)],
            [UIColor(red: 0.42, green: 0.18, blue: 0.14, alpha: 1), UIColor(red: 0.29, green: 0.24, blue: 0.10, alpha: 1)],
            [UIColor(red: 0.08, green: 0.31, blue: 0.25, alpha: 1), UIColor(red: 0.10, green: 0.18, blue: 0.35, alpha: 1)],
            [UIColor(red: 0.15, green: 0.13, blue: 0.38, alpha: 1), UIColor(red: 0.36, green: 0.12, blue: 0.31, alpha: 1)],
            [UIColor(red: 0.08, green: 0.30, blue: 0.18, alpha: 1), UIColor(red: 0.20, green: 0.28, blue: 0.08, alpha: 1)],
            [UIColor(red: 0.11, green: 0.15, blue: 0.40, alpha: 1), UIColor(red: 0.34, green: 0.13, blue: 0.45, alpha: 1)]
        ]

        let palettes = traitCollection.userInterfaceStyle == .dark ? darkPalettes : lightPalettes
        gradientLayer.colors = palettes[paletteIndex % palettes.count].map { $0.resolvedColor(with: traitCollection).cgColor }
    }
}
