import UIKit

final class DemoRootViewController: UIViewController {
    private let mainTabController = DemoTabBarController()
    private let minimizedContainer = MinimizedContainerViewController()
    private var activeDocumentController: DocumentViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        addChild(mainTabController)
        view.addSubview(mainTabController.view)
        mainTabController.didMove(toParent: self)

        addChild(minimizedContainer)
        view.addSubview(minimizedContainer.view)
        minimizedContainer.didMove(toParent: self)

        mainTabController.onOpenDocument = { [weak self] document in
            self?.open(document)
        }
        minimizedContainer.onItemsChanged = { [weak self] in
            self?.view.setNeedsLayout()
        }
        minimizedContainer.onWillRestore = { [weak self] controller in
            self?.installRestoredControllerBehindDock(controller)
        }
        minimizedContainer.onDidRestore = { [weak self] controller in
            self?.finishRestoring(controller)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        minimizedContainer.view.frame = view.bounds

        let dockHeight = minimizedContainer.items.isEmpty
            ? 0
            : MiniDockLayout.collapsedHeight(safeAreaBottom: view.safeAreaInsets.bottom)
        let gap: CGFloat = minimizedContainer.items.isEmpty ? 0 : 8
        mainTabController.view.frame = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: view.bounds.height - dockHeight - gap
        )

        let radius: CGFloat = minimizedContainer.items.isEmpty ? 0 : 30
        mainTabController.view.layer.cornerRadius = radius
        mainTabController.view.layer.cornerCurve = .continuous
        mainTabController.view.layer.maskedCorners = [
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
        ]
        mainTabController.view.clipsToBounds = radius > 0

        activeDocumentController?.view.frame = view.bounds
    }

    private func open(_ document: DemoDocument) {
        guard activeDocumentController == nil else { return }

        let controller = DocumentViewController(document: document)
        controller.onClose = { [weak self, weak controller] in
            guard let self, let controller else { return }
            self.removeActiveDocument(controller)
        }
        controller.onMinimize = { [weak self, weak controller] in
            guard let self, let controller else { return }
            self.minimize(controller)
        }

        activeDocumentController = controller
        addChild(controller)
        controller.view.frame = view.bounds
        view.addSubview(controller.view)
        controller.didMove(toParent: self)

        controller.view.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        controller.view.alpha = 0
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState]
        ) {
            controller.view.transform = .identity
            controller.view.alpha = 1
        }
    }

    private func minimize(_ controller: DocumentViewController) {
        guard minimizedContainer.addMinimizedController(controller) else { return }

        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        activeDocumentController = nil
        view.bringSubviewToFront(minimizedContainer.view)

        view.setNeedsLayout()
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.minimizedContainer.commitPendingMinimizationLayout()
            self.view.layoutIfNeeded()
            self.minimizedContainer.layoutDuringParentAnimation()
        }
    }

    private func installRestoredControllerBehindDock(_ controller: MinimizableViewController) {
        guard let document = controller as? DocumentViewController else { return }
        activeDocumentController = document
        addChild(document)
        document.view.frame = view.bounds
        view.insertSubview(document.view, belowSubview: minimizedContainer.view)
        document.didMove(toParent: self)
    }

    private func finishRestoring(_ controller: MinimizableViewController) {
        guard let document = controller as? DocumentViewController else { return }
        view.bringSubviewToFront(document.view)
        document.view.isUserInteractionEnabled = true
        view.setNeedsLayout()
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func removeActiveDocument(_ controller: DocumentViewController) {
        UIView.animate(withDuration: 0.22) {
            controller.view.alpha = 0
            controller.view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { _ in
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
            self.activeDocumentController = nil
            self.view.bringSubviewToFront(self.minimizedContainer.view)
        }
    }
}
