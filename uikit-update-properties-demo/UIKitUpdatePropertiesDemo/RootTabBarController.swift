import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let uiViewExperiment = UIViewExperimentViewController()
        uiViewExperiment.tabBarItem = UITabBarItem(title: "UIView", image: UIImage(systemName: "rectangle.3.group"), tag: 0)

        let controllerExperiment = UIViewControllerExperimentViewController()
        controllerExperiment.tabBarItem = UITabBarItem(title: "Controller", image: UIImage(systemName: "rectangle.stack"), tag: 1)

        viewControllers = [
            UINavigationController(rootViewController: uiViewExperiment),
            UINavigationController(rootViewController: controllerExperiment)
        ]
    }
}
