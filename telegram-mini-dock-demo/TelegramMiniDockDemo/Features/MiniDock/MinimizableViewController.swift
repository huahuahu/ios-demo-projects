import UIKit

@MainActor
protocol MinimizableViewController: UIViewController {
    var minimizedIdentifier: AnyHashable { get }
    var minimizedTitle: String { get }
    var minimizedIcon: UIImage? { get }
    var isMinimized: Bool { get set }

    func makeMinimizedSnapshotView() -> UIView?
    func restoreAfterMaximization()
}

@MainActor
final class MiniDockItem {
    let id: AnyHashable
    let controller: MinimizableViewController
    let snapshotView: UIView

    init(controller: MinimizableViewController, snapshotView: UIView) {
        id = controller.minimizedIdentifier
        self.controller = controller
        self.snapshotView = snapshotView
    }
}
