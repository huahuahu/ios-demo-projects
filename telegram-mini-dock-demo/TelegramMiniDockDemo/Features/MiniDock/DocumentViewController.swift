import UIKit

final class DocumentViewController: UIViewController, MinimizableViewController {
    let document: DemoDocument

    var onClose: (() -> Void)?
    var onMinimize: (() -> Void)?

    var minimizedIdentifier: AnyHashable { document.id }
    var minimizedTitle: String { document.title }
    var minimizedIcon: UIImage? { UIImage(systemName: document.symbolName) }
    var isMinimized = false

    private let headerGlassView = GlassFactory.effectView(interactive: true)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textView = UITextView()
    private let toolbarGlassView = GlassFactory.effectView(interactive: true)

    private lazy var closeButton = GlassFactory.symbolButton(
        systemName: "xmark",
        accessibilityLabel: "关闭文件",
        action: UIAction { [weak self] _ in self?.onClose?() }
    )

    private lazy var minimizeButton = GlassFactory.symbolButton(
        systemName: "chevron.down",
        accessibilityLabel: "最小化文件",
        action: UIAction { [weak self] _ in self?.onMinimize?() }
    )

    init(document: DemoDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        headerGlassView.layer.cornerRadius = 28
        headerGlassView.accessibilityIdentifier = "document.header"
        view.addSubview(headerGlassView)

        titleLabel.text = document.title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.accessibilityIdentifier = "document.title"

        subtitleLabel.text = document.subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 1
        titleStack.alignment = .fill

        [closeButton, titleStack, minimizeButton].forEach {
            headerGlassView.contentView.addSubview($0)
        }
        closeButton.accessibilityIdentifier = "document.close"
        minimizeButton.accessibilityIdentifier = "document.minimize"

        textView.text = document.body
        textView.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 18, left: 16, bottom: 120, right: 16)
        textView.accessibilityIdentifier = "document.content"
        view.insertSubview(textView, belowSubview: headerGlassView)

        toolbarGlassView.layer.cornerRadius = 30
        view.addSubview(toolbarGlassView)
        let toolbarStack = UIStackView(arrangedSubviews: [
            toolbarButton(systemName: "magnifyingglass", label: "搜索"),
            toolbarButton(systemName: "square.and.arrow.up", label: "分享"),
            toolbarButton(systemName: "doc.text.magnifyingglass", label: "检查")
        ])
        toolbarStack.axis = .horizontal
        toolbarStack.distribution = .fillEqually
        toolbarGlassView.contentView.addSubview(toolbarStack)
        toolbarStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbarStack.leadingAnchor.constraint(equalTo: toolbarGlassView.contentView.leadingAnchor, constant: 8),
            toolbarStack.trailingAnchor.constraint(equalTo: toolbarGlassView.contentView.trailingAnchor, constant: -8),
            toolbarStack.topAnchor.constraint(equalTo: toolbarGlassView.contentView.topAnchor, constant: 6),
            toolbarStack.bottomAnchor.constraint(equalTo: toolbarGlassView.contentView.bottomAnchor, constant: -6)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safe = view.safeAreaInsets
        let headerFrame = CGRect(
            x: 16,
            y: safe.top + 8,
            width: view.bounds.width - 32,
            height: 64
        )
        headerGlassView.frame = headerFrame

        closeButton.frame = CGRect(x: 6, y: 4, width: 56, height: 56)
        minimizeButton.frame = CGRect(
            x: headerFrame.width - 62,
            y: 4,
            width: 56,
            height: 56
        )
        titleLabel.superview?.frame = CGRect(
            x: 68,
            y: 10,
            width: headerFrame.width - 136,
            height: 44
        )

        textView.frame = view.bounds
        textView.contentInset.top = headerFrame.maxY - safe.top + 4

        toolbarGlassView.frame = CGRect(
            x: (view.bounds.width - 240) / 2,
            y: view.bounds.height - safe.bottom - 72,
            width: 240,
            height: 60
        )
    }

    func makeMinimizedSnapshotView() -> UIView? {
        textView.snapshotView(afterScreenUpdates: true)
    }

    func restoreAfterMaximization() {
        isMinimized = false
        view.isUserInteractionEnabled = true
    }

    private func toolbarButton(systemName: String, label: String) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: systemName)
        configuration.baseForegroundColor = .label
        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = label
        return button
    }
}
