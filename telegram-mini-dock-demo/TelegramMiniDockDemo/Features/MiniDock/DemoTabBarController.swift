import UIKit

final class DemoTabBarController: UITabBarController {
    var onOpenDocument: ((DemoDocument) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let documentList = DocumentListViewController(style: .insetGrouped)
        documentList.onOpenDocument = { [weak self] document in
            self?.onOpenDocument?(document)
        }
        let chats = UINavigationController(rootViewController: documentList)
        chats.tabBarItem = UITabBarItem(
            title: "聊天",
            image: UIImage(systemName: "bubble.left.and.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )

        viewControllers = [
            makePlaceholder(title: "联系人", symbol: "person.crop.circle"),
            makePlaceholder(title: "通话", symbol: "phone"),
            chats,
            makePlaceholder(title: "设置", symbol: "gearshape")
        ]
        selectedIndex = 2
    }

    private func makePlaceholder(title: String, symbol: String) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemGroupedBackground
        controller.title = title

        let image = UIImageView(image: UIImage(systemName: symbol))
        image.tintColor = .secondaryLabel
        image.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        image.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "切换标签后，底部 Dock 仍会保留"
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false

        controller.view.addSubview(image)
        controller.view.addSubview(label)
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor, constant: -24),
            label.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 16)
        ])

        let navigation = UINavigationController(rootViewController: controller)
        navigation.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: symbol),
            selectedImage: UIImage(systemName: "\(symbol).fill")
        )
        return navigation
    }
}
