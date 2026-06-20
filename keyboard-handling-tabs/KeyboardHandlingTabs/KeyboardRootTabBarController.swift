import SwiftUI
import UIKit

final class KeyboardRootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [makeSwiftUITab(), makeUIKitTab()]
    }

    private func makeSwiftUITab() -> UIViewController {
        let controller = UIHostingController(rootView: SwiftUIKeyboardTabView())
        controller.tabBarItem = UITabBarItem(
            title: "SwiftUI",
            image: UIImage(systemName: "swift"),
            selectedImage: UIImage(systemName: "swift")
        )
        return controller
    }

    private func makeUIKitTab() -> UIViewController {
        let controller = UINavigationController(rootViewController: UIKitKeyboardViewController())
        controller.tabBarItem = UITabBarItem(
            title: "UIKit",
            image: UIImage(systemName: "square.stack.3d.up.fill"),
            selectedImage: UIImage(systemName: "square.stack.3d.up.fill")
        )
        return controller
    }
}
