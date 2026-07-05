import Foundation
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var notes: String
    var scenarioRawValue: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \BookCover.book)
    var cover: BookCover?

    init(
        title: String,
        author: String,
        notes: String,
        scenario: DeleteDemoScenario,
        createdAt: Date = .now
    ) {
        self.title = title
        self.author = author
        self.notes = notes
        self.scenarioRawValue = scenario.rawValue
        self.createdAt = createdAt
    }
}
