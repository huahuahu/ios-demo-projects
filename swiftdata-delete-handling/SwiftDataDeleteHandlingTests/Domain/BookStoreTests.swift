import SwiftData
import Testing
@testable import SwiftDataDeleteHandling

@MainActor
struct BookStoreTests {
    @Test func resetDemoBooksCreatesOneBookForEachScenario() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let insertedBooks = try BookStore.resetDemoBooks(in: context)
        let fetchedBooks = try BookStore.fetchBooks(in: context)

        #expect(insertedBooks.count == DeleteDemoScenario.allCases.count)
        #expect(fetchedBooks.map(\.scenarioRawValue) == DeleteDemoScenario.allCases.map(\.rawValue))
        #expect(fetchedBooks.compactMap(\.cover).count == DeleteDemoScenario.allCases.count)
    }

    @Test func backgroundDeleterRemovesBookByPersistentModelID() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let insertedBooks = try BookStore.resetDemoBooks(in: context)
        let bookID = try #require(insertedBooks.first?.persistentModelID)

        let didDelete = try await BackgroundBookDeleter(modelContainer: container)
            .delete(bookID: bookID)
        let verificationContext = ModelContext(container)
        let remainingBooks = try BookStore.fetchBooks(in: verificationContext)
        let containsDeletedBook = try BookStore.containsBook(
            with: bookID,
            in: verificationContext
        )

        #expect(didDelete)
        #expect(containsDeletedBook == false)
        #expect(remainingBooks.contains { $0.persistentModelID == bookID } == false)
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Book.self,
            BookCover.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
