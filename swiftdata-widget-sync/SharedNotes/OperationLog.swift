import Foundation
import SwiftData

@Model
final class OperationLog {
    var operationName: String
    var author: String
    var targetIdentifier: String?
    var targetTitle: String?
    var noteCount: Int
    var detail: String
    var createdAt: Date

    init(
        operationName: String,
        author: String,
        targetIdentifier: String? = nil,
        targetTitle: String? = nil,
        noteCount: Int = 0,
        detail: String = "",
        createdAt: Date = .now
    ) {
        self.operationName = operationName
        self.author = author
        self.targetIdentifier = targetIdentifier
        self.targetTitle = targetTitle
        self.noteCount = noteCount
        self.detail = detail
        self.createdAt = createdAt
    }
}
