import Foundation
import SwiftData

@Model
final class ResearchNote {
    var title: String
    var detail: String
    var source: String
    var revision: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        detail: String,
        source: String,
        revision: Int = 1,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.title = title
        self.detail = detail
        self.source = source
        self.revision = revision
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
