import UIKit

struct DemoDocument: Hashable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let tintColor: UIColor
    let body: String

    static let samples: [DemoDocument] = [
        DemoDocument(
            id: "message",
            title: "message.txt",
            subtitle: "Core Data 调试日志",
            symbolName: "doc.text",
            tintColor: .systemBlue,
            body: """
            CoreData: error: Failed to stat path
            '/Users/demo/Library/Developer/CoreSimulator/
            Devices/DEMO-DEVICE-ID/data/Containers/Shared/
            AppGroup/Library/Application Support/default.store',
            errno 2 / No such file or directory.

            CoreData: error: Executing as effective user 501
            CoreData: error: Sandbox access to file-write-create denied
            CoreData: error: Failed to statfs file; errno 2

            CoreData: error: Information for file system
            CoreData: error: ----------------------------
            CoreData: error: File system type: 0
            CoreData: error: File system flags: 0
            CoreData: error: Total data blocks: 0
            """
        ),
        DemoDocument(
            id: "language-model",
            title: "copilotLanguageModelWrapper.swift",
            subtitle: "语言模型适配层",
            symbolName: "swift",
            tintColor: .systemOrange,
            body: """
            final class LanguageModelWrapper {
                private let session: ModelSession

                init(session: ModelSession) {
                    self.session = session
                }

                func respond(to prompt: String) async throws -> String {
                    let response = try await session.respond(to: prompt)
                    return response.content
                }
            }

            // 这是第二个可最小化页面。
            // 先点右上角按钮将它停靠到底部，
            // 再打开其他文件，便可以观察多卡片堆叠。
            """
        ),
        DemoDocument(
            id: "architecture",
            title: "MiniDockArchitecture.md",
            subtitle: "容器、快照与状态机",
            symbolName: "square.stack.3d.up",
            tintColor: .systemPurple,
            body: """
            # Mini Dock Architecture

            1. 根容器同时持有 UITabBarController 和 MiniDock。
            2. 文件页最小化时生成 snapshot，但保留 ViewController。
            3. 收起状态只显示最上层标题条。
            4. 多文件展开后使用 CATransform3D 形成透视卡片栈。
            5. 横向拖动关闭，点击卡片恢复，下拉收起。

            这个 Demo 刻意把布局算法放在 Domain 中，方便单元测试。
            """
        )
    ]
}
