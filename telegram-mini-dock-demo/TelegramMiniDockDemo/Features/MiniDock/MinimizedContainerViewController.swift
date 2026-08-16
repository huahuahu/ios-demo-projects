import UIKit

private final class DockPassthroughView: UIView {
    var capturesWholeScreen = false
    var collapsedHitFrame = CGRect.zero

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !capturesWholeScreen, !collapsedHitFrame.contains(point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}

final class MinimizedContainerViewController: UIViewController,
    UIScrollViewDelegate,
    UIGestureRecognizerDelegate
{
    enum PresentationState {
        case collapsed
        case expanded
    }

    var onItemsChanged: (() -> Void)?
    var onWillRestore: ((MinimizableViewController) -> Void)?
    var onDidRestore: ((MinimizableViewController) -> Void)?

    private(set) var items: [MiniDockItem] = []
    private(set) var presentationState: PresentationState = .collapsed

    private let backgroundBlurView = UIVisualEffectView(effect: nil)
    private let dimView = UIView()
    private let scrollView = UIScrollView()
    private var cardViews: [AnyHashable: MiniDockCardView] = [:]
    private var pendingInitialCardID: AnyHashable?
    private var draggedCardID: AnyHashable?
    private var draggedCardStartCenter = CGPoint.zero
    private var transitionInProgress = false

    private var passthroughView: DockPassthroughView {
        view as! DockPassthroughView
    }

    override func loadView() {
        view = DockPassthroughView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        dimView.alpha = 0
        view.addSubview(backgroundBlurView)
        view.addSubview(dimView)

        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        backgroundTap.delegate = self
        scrollView.addGestureRecognizer(backgroundTap)

        let expandPan = UIPanGestureRecognizer(target: self, action: #selector(handleExpandPan(_:)))
        expandPan.delegate = self
        view.addGestureRecognizer(expandPan)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundBlurView.frame = view.bounds
        dimView.frame = view.bounds
        scrollView.frame = view.bounds

        let collapsedHeight = MiniDockLayout.collapsedHeight(
            safeAreaBottom: view.safeAreaInsets.bottom
        )
        passthroughView.collapsedHitFrame = items.isEmpty
            ? .zero
            : CGRect(
                x: 0,
                y: view.bounds.height - collapsedHeight,
                width: view.bounds.width,
                height: collapsedHeight
            )
        layoutCards()
    }

    @discardableResult
    func addMinimizedController(_ controller: MinimizableViewController) -> Bool {
        guard !items.contains(where: { $0.id == controller.minimizedIdentifier }),
              let snapshot = controller.makeMinimizedSnapshotView()
        else { return false }

        controller.isMinimized = true
        controller.view.isUserInteractionEnabled = false

        let item = MiniDockItem(controller: controller, snapshotView: snapshot)
        let card = MiniDockCardView(item: item)
        card.bounds = view.bounds
        card.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        card.layer.cornerRadius = 0
        configureCallbacks(for: card)

        items.append(item)
        cardViews[item.id] = card
        scrollView.addSubview(card)
        pendingInitialCardID = item.id
        presentationState = .collapsed
        updateInteractionMode()
        onItemsChanged?()
        return true
    }

    func commitPendingMinimizationLayout() {
        pendingInitialCardID = nil
        view.setNeedsLayout()
    }

    func layoutDuringParentAnimation() {
        view.layoutIfNeeded()
        layoutCards()
    }

    func expand() {
        guard items.count > 1, !transitionInProgress else {
            if let onlyItem = items.first {
                restore(onlyItem)
            }
            return
        }

        presentationState = .expanded
        transitionInProgress = true
        updateInteractionMode()
        scrollView.contentOffset = .zero
        backgroundBlurView.effect = UIBlurEffect(style: .systemMaterial)

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.dimView.alpha = 1
            self.layoutCards()
        } completion: { _ in
            self.transitionInProgress = false
        }
    }

    func collapse() {
        guard presentationState == .expanded, !transitionInProgress else { return }
        presentationState = .collapsed
        transitionInProgress = true
        updateInteractionMode()

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.backgroundBlurView.effect = nil
            self.dimView.alpha = 0
            self.scrollView.contentOffset = .zero
            self.layoutCards()
        } completion: { _ in
            self.transitionInProgress = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard presentationState == .expanded, !transitionInProgress else { return }
        layoutExpandedCards()

        if scrollView.contentOffset.y < -64,
           !scrollView.isDragging
        {
            collapse()
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        if gestureRecognizer.view === scrollView,
           gestureRecognizer is UITapGestureRecognizer
        {
            return touch.view === scrollView
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              gestureRecognizer.view === view
        else { return true }

        let velocity = pan.velocity(in: view)
        return presentationState == .collapsed
            && abs(velocity.y) > abs(velocity.x)
            && velocity.y < 0
    }

    private func configureCallbacks(for card: MiniDockCardView) {
        let itemID = card.item.id
        card.onOpen = { [weak self] in
            guard let self,
                  let item = self.items.first(where: { $0.id == itemID })
            else { return }

            if self.presentationState == .collapsed, self.items.count > 1 {
                self.expand()
            } else {
                self.restore(item)
            }
        }
        card.onClose = { [weak self] in
            self?.requestClose(itemID: itemID)
        }
        card.onHorizontalPan = { [weak self] card, recognizer in
            self?.handleHorizontalPan(card: card, recognizer: recognizer)
        }
    }

    private func layoutCards() {
        guard !items.isEmpty else {
            scrollView.contentSize = view.bounds.size
            return
        }

        switch presentationState {
        case .collapsed:
            layoutCollapsedCards()
        case .expanded:
            layoutExpandedCards()
        }
    }

    private func layoutCollapsedCards() {
        let size = view.bounds.size
        let collapsedHeight = MiniDockLayout.collapsedHeight(
            safeAreaBottom: view.safeAreaInsets.bottom
        )
        let originY = size.height - collapsedHeight + MiniDockLayout.topMargin

        for (index, item) in items.enumerated() {
            guard item.id != pendingInitialCardID,
                  let card = cardViews[item.id]
            else { continue }

            card.bounds = CGRect(origin: .zero, size: size)
            var center = CGPoint(
                x: size.width / 2,
                y: originY + size.height / 2
            )
            let isTop = index == items.count - 1
            let transform: CATransform3D

            if isTop {
                if items.count > 1 { center.y += 6 }
                transform = CATransform3DIdentity
                card.layer.zPosition = 10_000
            } else {
                let scale = (size.width - 20) / size.width
                let scaledHeight = size.height * scale
                center.y -= (size.height - scaledHeight) / 2
                transform = CATransform3DMakeScale(scale, scale, 1)
                card.layer.zPosition = CGFloat(index)
            }

            card.center = center
            card.layer.transform = transform
            card.layer.cornerRadius = 25
            card.update(
                title: isTop ? collapsedTitle : item.controller.minimizedTitle,
                showsIcon: false,
                isCovered: index <= items.count - 2,
                showsContent: false
            )
        }
        scrollView.contentSize = size
    }

    private func layoutExpandedCards() {
        let size = view.bounds.size
        let topInset = view.safeAreaInsets.top
        let spacing = MiniDockLayout.interitemSpacing(
            itemCount: items.count,
            boundingHeight: size.height,
            topInset: topInset
        )
        let cardSize = CGSize(
            width: size.width - 20,
            height: size.height - topInset - 32
        )

        for (index, item) in items.enumerated() {
            guard let card = cardViews[item.id] else { continue }
            let originY = MiniDockLayout.additionalTopInset
                + topInset
                + spacing * CGFloat(index)
            let angle = MiniDockLayout.angle(
                cardOriginY: originY,
                itemCount: items.count,
                viewportHeight: size.height,
                contentOffsetY: scrollView.contentOffset.y,
                topInset: topInset
            )

            card.bounds = CGRect(origin: .zero, size: cardSize)
            if draggedCardID != item.id {
                card.center = CGPoint(
                    x: size.width / 2,
                    y: originY + cardSize.height / 2
                )
            }
            card.layer.transform = MiniDockLayout.transform(
                angle: angle,
                cardHeight: cardSize.height
            )
            card.layer.cornerRadius = 25
            card.layer.zPosition = CGFloat(index)
            card.update(
                title: item.controller.minimizedTitle,
                showsIcon: true,
                isCovered: false,
                showsContent: true
            )
        }

        let lastOrigin = MiniDockLayout.additionalTopInset
            + topInset
            + spacing * CGFloat(max(items.count - 1, 0))
        scrollView.contentSize = CGSize(
            width: size.width,
            height: max(size.height + 1, lastOrigin + cardSize.height * 0.7)
        )
    }

    private var collapsedTitle: String {
        MiniDockTitleFormatter.collapsedTitle(
            titles: items.map(\.controller.minimizedTitle)
        )
    }

    private func updateInteractionMode() {
        let expanded = presentationState == .expanded
        passthroughView.capturesWholeScreen = expanded
        scrollView.isScrollEnabled = expanded
        dimView.isUserInteractionEnabled = expanded
    }

    @objc private func handleBackgroundTap(_ recognizer: UITapGestureRecognizer) {
        guard presentationState == .expanded else { return }
        collapse()
    }

    @objc private func handleExpandPan(_ recognizer: UIPanGestureRecognizer) {
        guard presentationState == .collapsed else { return }
        if recognizer.state == .changed,
           recognizer.translation(in: view).y < -10
        {
            recognizer.isEnabled = false
            recognizer.isEnabled = true
            expand()
        }
    }

    private func handleHorizontalPan(
        card: MiniDockCardView,
        recognizer: UIPanGestureRecognizer
    ) {
        guard presentationState == .expanded, !transitionInProgress else { return }

        switch recognizer.state {
        case .began:
            draggedCardID = card.item.id
            draggedCardStartCenter = card.center
            scrollView.isScrollEnabled = false
        case .changed:
            let translation = recognizer.translation(in: card)
            let effectiveX = translation.x > 0
                ? translation.x / 5
                : translation.x
            card.center = CGPoint(
                x: draggedCardStartCenter.x + effectiveX,
                y: draggedCardStartCenter.y
            )
        case .ended:
            let translation = recognizer.translation(in: card)
            let velocity = recognizer.velocity(in: card)
            if translation.x < -view.bounds.width / 3 || velocity.x < -300 {
                dismiss(card.item, card: card)
            } else {
                draggedCardID = nil
                scrollView.isScrollEnabled = true
                UIView.animate(
                    withDuration: 0.4,
                    delay: 0,
                    usingSpringWithDamping: 0.82,
                    initialSpringVelocity: 0,
                    options: [.beginFromCurrentState]
                ) {
                    card.center = self.draggedCardStartCenter
                }
            }
        default:
            draggedCardID = nil
            scrollView.isScrollEnabled = true
            layoutExpandedCards()
        }
    }

    private func requestClose(itemID: AnyHashable) {
        guard let item = items.first(where: { $0.id == itemID }),
              let card = cardViews[itemID]
        else { return }

        if presentationState == .collapsed, items.count > 1 {
            let alert = UIAlertController(
                title: "关闭所有最小化文件？",
                message: "当前停靠了 \(items.count) 个文件。",
                preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "关闭全部", style: .destructive) { [weak self] _ in
                self?.dismissAll()
            })
            present(alert, animated: true)
        } else {
            dismiss(item, card: card)
        }
    }

    private func dismiss(_ item: MiniDockItem, card: MiniDockCardView) {
        transitionInProgress = true
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState]
        ) {
            card.center.x = -self.view.bounds.width
        } completion: { _ in
            self.remove(item)
            self.draggedCardID = nil
            self.scrollView.isScrollEnabled = self.presentationState == .expanded
            self.transitionInProgress = false
            self.layoutCards()
        }
    }

    private func dismissAll() {
        let oldCards = Array(cardViews.values)
        items.removeAll()
        cardViews.removeAll()
        presentationState = .collapsed
        updateInteractionMode()

        UIView.animate(withDuration: 0.3) {
            oldCards.forEach { $0.center.y += self.view.bounds.height * 0.35 }
        } completion: { _ in
            oldCards.forEach { $0.removeFromSuperview() }
            self.onItemsChanged?()
        }
    }

    private func restore(_ item: MiniDockItem) {
        guard let card = cardViews[item.id], !transitionInProgress else { return }
        transitionInProgress = true
        onWillRestore?(item.controller)

        let targetCenter = CGPoint(
            x: view.bounds.midX,
            y: view.bounds.midY + scrollView.contentOffset.y
        )
        card.setContentVisible(true)
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState]
        ) {
            self.backgroundBlurView.effect = nil
            self.dimView.alpha = 0
            card.bounds = self.view.bounds
            card.center = targetCenter
            card.layer.transform = CATransform3DIdentity
            card.layer.cornerRadius = 0
        } completion: { _ in
            self.remove(item)
            self.presentationState = .collapsed
            self.updateInteractionMode()
            self.transitionInProgress = false
            item.controller.restoreAfterMaximization()
            self.onDidRestore?(item.controller)
            self.layoutCards()
        }
    }

    private func remove(_ item: MiniDockItem) {
        items.removeAll { $0.id == item.id }
        cardViews.removeValue(forKey: item.id)?.removeFromSuperview()
        item.controller.isMinimized = false
        if items.isEmpty {
            passthroughView.collapsedHitFrame = .zero
        }
        onItemsChanged?()
    }
}
