import UIKit

@MainActor
final class AttachmentInputView: UIInputView {
    private let selectSource: (AttachmentSource) -> Void

    init(selectSource: @escaping (AttachmentSource) -> Void) {
        self.selectSource = selectSource
        super.init(frame: .zero, inputViewStyle: .keyboard)
        allowsSelfSizing = true
        backgroundColor = .systemBackground
        configureLayout()
        frame.size = systemLayoutSizeFitting(
            CGSize(width: fittingWidth(for: .zero), height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let fittingWidth = fittingWidth(for: targetSize)
        let fittingSize = super.systemLayoutSizeFitting(
            CGSize(width: fittingWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: fittingWidth, height: fittingSize.height)
    }

    private func fittingWidth(for targetSize: CGSize) -> CGFloat {
        if targetSize.width > 0 {
            return targetSize.width
        }
        if let windowWidth = window?.windowScene?.screen.bounds.width, windowWidth > 0 {
            return windowWidth
        }
        if bounds.width > 0 {
            return bounds.width
        }
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.width }
            .first { $0 > 0 } ?? 390
    }

    private func configureLayout() {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .separator
        addSubview(divider)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Choose attachment source"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        addSubview(titleLabel)

        let optionsStackView = UIStackView()
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.axis = .horizontal
        optionsStackView.spacing = 12
        optionsStackView.distribution = .fillEqually
        addSubview(optionsStackView)

        for source in AttachmentSource.allCases {
            let button = UIButton(type: .system)
            button.configuration = .tinted()
            button.configuration?.title = source.rawValue
            button.configuration?.image = UIImage(systemName: source.symbolName)
            button.configuration?.imagePadding = 8
            button.configuration?.imagePlacement = .top
            let selectedSource = source
            button.addAction(
                UIAction { [weak self] _ in
                    self?.selectSource(selectedSource)
                },
                for: .touchUpInside
            )
            optionsStackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1 / max(traitCollection.displayScale, 1)),

            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),

            optionsStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            optionsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            optionsStackView.heightAnchor.constraint(equalToConstant: 96),
            optionsStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}
