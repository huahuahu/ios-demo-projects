import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let uiViewExperiment = UIViewExperimentViewController()
        uiViewExperiment.tabBarItem = UITabBarItem(title: "UIView", image: UIImage(systemName: "rectangle.3.group"), tag: 0)

        viewControllers = [
            UINavigationController(rootViewController: uiViewExperiment)
        ]
    }
}
