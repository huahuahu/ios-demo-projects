import Foundation

struct StreamEvent: Equatable, Identifiable, Sendable {
    let id: Int
    let createdAt: Date
    let message: String

    init(id: Int, createdAt: Date = .now, message: String) {
        self.id = id
        self.createdAt = createdAt
        self.message = message
    }

    var logDescription: String {
        "#\(id) \(message)"
    }
}
