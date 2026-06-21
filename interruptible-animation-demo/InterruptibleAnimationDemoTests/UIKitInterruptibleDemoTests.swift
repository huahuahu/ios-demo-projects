import Testing
import UIKit
@testable import InterruptibleAnimationDemo

@MainActor
struct UIKitInterruptibleDemoTests {
    @Test func viewControllerLoadsConfiguredUIKitDemo() {
        let viewController = InterruptibleUIKitViewController()

        viewController.loadViewIfNeeded()

        #expect(viewController.view.backgroundColor == UIColor.systemGroupedBackground)
        #expect(viewController.view.containsLabel(text: "UIKit: UIViewPropertyAnimator"))
        #expect(viewController.view.containsLabel(text: "Ready\nprogress: 0%"))
    }
}

private extension UIView {
    func containsLabel(text: String) -> Bool {
        if let label = self as? UILabel, label.text == text {
            return true
        }

        return subviews.contains { $0.containsLabel(text: text) }
    }
}
