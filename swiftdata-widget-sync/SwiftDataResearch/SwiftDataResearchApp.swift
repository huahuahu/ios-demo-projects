import SwiftData
import SwiftUI

@main
struct SwiftDataResearchApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try SharedStore.makeModelContainer()
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: modelContainer)
        }
        .modelContainer(modelContainer)
    }
}
