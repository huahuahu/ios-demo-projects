import UIKit

@MainActor
final class AttachmentPanelView: UIView {
    var selectSource: ((AttachmentSource) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        accessibilityIdentifier = "UIKitAttachmentPanel"
        backgroundColor = .systemBackground
        isHidden = true
        alpha = 0

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .separator
        addSubview(divider)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "UIKitAttachmentPanelTitle"
        titleLabel.text = "Choose attachment source"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        let optionsStackView = UIStackView()
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.accessibilityIdentifier = "UIKitAttachmentPanelOptions"
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
            button.titleLabel?.numberOfLines = 0
            button.addAction(
                UIAction { [weak self] _ in
                    self?.selectSource?(source)
                },
                for: .touchUpInside
            )
            optionsStackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),

            optionsStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            optionsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            optionsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
            optionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}
