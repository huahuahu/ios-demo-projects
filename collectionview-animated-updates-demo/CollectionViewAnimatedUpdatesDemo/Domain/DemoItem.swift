import Foundation

struct DemoItem: Hashable, Identifiable {
    let id: UUID
    let title: String

    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}
