import SwiftData
import SwiftUI

@main
struct SwiftDataDeleteHandlingApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Book.self, BookCover.self)
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ScenarioListView(modelContainer: modelContainer)
        }
        .modelContainer(modelContainer)
    }
}
