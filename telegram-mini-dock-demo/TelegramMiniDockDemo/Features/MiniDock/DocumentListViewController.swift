import UIKit

final class DocumentListViewController: UITableViewController {
    var onOpenDocument: ((DemoDocument) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mini Dock"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DocumentCell")
        tableView.accessibilityIdentifier = "document.list"

        let header = UILabel()
        header.numberOfLines = 0
        header.text = "打开一个文件，点右上角 ↓ 将它停靠到底部。停靠两个以上文件后，点击 Dock 查看 Telegram 风格卡片栈。"
        header.font = .preferredFont(forTextStyle: .body)
        header.textColor = .secondaryLabel
        header.backgroundColor = .secondarySystemGroupedBackground
        header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 108)
        tableView.tableHeaderView = header
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DemoDocument.samples.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let document = DemoDocument.samples[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = document.title
        configuration.secondaryText = document.subtitle
        configuration.image = UIImage(systemName: document.symbolName)
        configuration.imageProperties.tintColor = document.tintColor
        cell.contentConfiguration = configuration
        cell.accessoryType = .disclosureIndicator
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = [.button]
        cell.accessibilityLabel = "\(document.title)，\(document.subtitle)"
        cell.accessibilityIdentifier = "document.row.\(document.id)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onOpenDocument?(DemoDocument.samples[indexPath.row])
    }
}
