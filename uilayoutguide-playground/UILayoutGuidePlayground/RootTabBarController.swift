import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = DemoTab.allCases.map { tab in
            let viewController = tab.makeViewController()
            viewController.title = tab.title

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.tabBarItem = UITabBarItem(
                title: tab.title,
                image: UIImage(systemName: tab.systemImageName),
                selectedImage: nil
            )
            return navigationController
        }
    }
}

private enum DemoTab: CaseIterable {
    case ownership
    case guideLayout
    case spacerComparison

    var title: String {
        switch self {
        case .ownership:
            "Ownership"
        case .guideLayout:
            "Guide Layout"
        case .spacerComparison:
            "Spacer vs Guide"
        }
    }

    var systemImageName: String {
        switch self {
        case .ownership:
            "link"
        case .guideLayout:
            "rectangle.3.group"
        case .spacerComparison:
            "arrow.left.and.right"
        }
    }

    @MainActor
    func makeViewController() -> UIViewController {
        switch self {
        case .ownership:
            GuideOwnershipViewController()
        case .guideLayout:
            GuideLayoutViewController()
        case .spacerComparison:
            SpacerComparisonViewController()
        }
    }
}
