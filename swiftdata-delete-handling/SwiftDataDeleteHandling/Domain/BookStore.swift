import Foundation
import SwiftData

enum BookStore {
    @discardableResult
    @MainActor
    static func resetDemoBooks(in context: ModelContext) throws -> [Book] {
        for book in try fetchBooks(in: context) {
            context.delete(book)
        }

        let baseDate = Date(timeIntervalSinceReferenceDate: 0)
        let books = DeleteDemoScenario.allCases.enumerated().map { index, scenario in
            let book = Book(
                title: scenario.sampleTitle,
                author: scenario.sampleAuthor,
                notes: scenario.sampleNotes,
                scenario: scenario,
                createdAt: baseDate.addingTimeInterval(TimeInterval(index))
            )
            let cover = BookCover(
                caption: "\(scenario.sampleTitle) cover",
                colorName: index == 0 ? "red" : "green",
                book: book
            )
            book.cover = cover
            context.insert(book)
            context.insert(cover)
            return book
        }

        try context.save()
        return books
    }

    static func fetchBooks(in context: ModelContext) throws -> [Book] {
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\Book.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    static func containsBook(
        with id: PersistentIdentifier,
        in context: ModelContext
    ) throws -> Bool {
        var descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { book in
                book.persistentModelID == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).isEmpty == false
    }

    @MainActor
    static func makePreviewContainer() throws -> ModelContainer {
        let container = try ModelContainer(
            for: Book.self,
            BookCover.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        try resetDemoBooks(in: container.mainContext)
        return container
    }
}
