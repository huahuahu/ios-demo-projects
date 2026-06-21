import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let placeholder = UIViewController()
        placeholder.view.backgroundColor = .systemBackground
        placeholder.title = "UIView"
        placeholder.tabBarItem = UITabBarItem(title: "UIView", image: UIImage(systemName: "rectangle.3.group"), tag: 0)

        viewControllers = [
            UINavigationController(rootViewController: placeholder)
        ]
    }
}
