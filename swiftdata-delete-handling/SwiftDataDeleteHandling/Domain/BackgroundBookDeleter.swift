import SwiftData

@ModelActor
actor BackgroundBookDeleter {
    func delete(bookID: PersistentIdentifier) throws -> Bool {
        guard let book = modelContext.model(for: bookID) as? Book else {
            return false
        }

        modelContext.delete(book)
        try modelContext.save()
        return true
    }
}
