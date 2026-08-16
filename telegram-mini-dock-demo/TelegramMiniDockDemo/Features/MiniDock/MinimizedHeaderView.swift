import UIKit

final class MinimizedHeaderView: UIView {
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?

    private let glassView = GlassFactory.effectView(interactive: true)
    private let titleButton = UIButton(type: .system)
    private let closeButton: UIButton
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        closeButton = GlassFactory.symbolButton(
            systemName: "xmark",
            accessibilityLabel: "关闭最小化文件",
            action: UIAction { _ in }
        )
        super.init(frame: frame)

        glassView.layer.cornerRadius = 25
        addSubview(glassView)

        titleButton.setTitleColor(.label, for: .normal)
        titleButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        titleButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
        titleButton.addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
        titleButton.accessibilityIdentifier = "dock.open"

        closeButton.removeTarget(nil, action: nil, for: .allEvents)
        closeButton.addAction(UIAction { [weak self] _ in self?.onClose?() }, for: .touchUpInside)
        closeButton.accessibilityIdentifier = "dock.close"

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .label

        [titleButton, closeButton, iconView].forEach {
            glassView.contentView.addSubview($0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
        closeButton.frame = CGRect(x: 2, y: 0, width: 56, height: bounds.height)
        iconView.frame = CGRect(x: 66, y: (bounds.height - 20) / 2, width: 20, height: 20)
        titleButton.frame = CGRect(x: 92, y: 0, width: bounds.width - 148, height: bounds.height)
    }

    func update(title: String, icon: UIImage?, showsIcon: Bool) {
        titleButton.setTitle(title, for: .normal)
        iconView.image = icon
        iconView.isHidden = !showsIcon || icon == nil
        setNeedsLayout()
    }
}
