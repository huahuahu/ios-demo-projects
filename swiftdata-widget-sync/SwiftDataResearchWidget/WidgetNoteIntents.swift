import AppIntents
import SwiftData
import WidgetKit

struct InsertWidgetNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Insert Widget Note"
    static let description = IntentDescription("Insert a note into the shared SwiftData store.")

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedLog.widget.info("Widget insert intent started")
        do {
            let container = try SharedStore.makeModelContainer()
            let note = try SharedStore.insertNote(source: "Widget", in: container.mainContext)
            SharedLog.widget.info("Widget insert intent succeeded: \(note.title, privacy: .public)")
            return .result()
        } catch {
            SharedLog.widget.error("Widget insert intent failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}

struct UpdateWidgetNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Update Widget Note"
    static let description = IntentDescription("Update the latest note in the shared SwiftData store.")

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedLog.widget.info("Widget update intent started")
        do {
            let container = try SharedStore.makeModelContainer()
            try SharedStore.updateLatestNote(source: "Widget", in: container.mainContext)
            SharedLog.widget.info("Widget update intent succeeded")
            return .result()
        } catch {
            SharedLog.widget.error("Widget update intent failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
