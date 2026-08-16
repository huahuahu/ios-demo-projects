import UIKit

final class MiniDockCardView: UIView, UIGestureRecognizerDelegate {
    let item: MiniDockItem
    let headerView = MinimizedHeaderView()

    var onOpen: (() -> Void)? {
        didSet { headerView.onOpen = onOpen }
    }
    var onClose: (() -> Void)? {
        didSet { headerView.onClose = onClose }
    }
    var onHorizontalPan: ((MiniDockCardView, UIPanGestureRecognizer) -> Void)?

    private let contentView = UIView()
    private let coveredDimView = UIView()

    init(item: MiniDockItem) {
        self.item = item
        super.init(frame: .zero)

        backgroundColor = .systemBackground
        layer.cornerRadius = 25
        layer.cornerCurve = .continuous
        clipsToBounds = true

        contentView.clipsToBounds = true
        contentView.addSubview(item.snapshotView)
        addSubview(contentView)

        coveredDimView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        coveredDimView.alpha = 0
        coveredDimView.isUserInteractionEnabled = false
        addSubview(coveredDimView)
        addSubview(headerView)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        item.snapshotView.frame = contentView.bounds
        coveredDimView.frame = bounds
        headerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: MiniDockLayout.navigationHeight)
    }

    func update(
        title: String,
        showsIcon: Bool,
        isCovered: Bool,
        showsContent: Bool
    ) {
        headerView.update(
            title: title,
            icon: item.controller.minimizedIcon,
            showsIcon: showsIcon
        )
        coveredDimView.alpha = isCovered ? 1 : 0
        contentView.alpha = showsContent ? 1 : 0
    }

    func setContentVisible(_ visible: Bool) {
        contentView.alpha = visible ? 1 : 0
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        onHorizontalPan?(self, recognizer)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y)
    }
}
