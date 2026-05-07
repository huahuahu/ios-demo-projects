import Foundation
import os
import SwiftData
import WidgetKit

enum SharedStore {
    static let appGroupIdentifier = "group.com.huahuahu.demo.SwiftDataResearch"
    static let widgetKind = "SwiftDataResearchWidget"

    static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration

        if inMemory {
            SharedLog.store.debug("Creating in-memory SwiftData container")
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else if let storeURL = sharedStoreURL() {
            SharedLog.store.info("Creating SwiftData container at \(storeURL.path(percentEncoded: false), privacy: .public)")
            configuration = ModelConfiguration(url: storeURL)
        } else {
            SharedLog.store.error("App Group store URL is unavailable; falling back to default SwiftData configuration")
            configuration = ModelConfiguration()
        }

        let container = try ModelContainer(for: ResearchNote.self, OperationLog.self, configurations: configuration)
        SharedLog.store.debug("SwiftData container created")
        return container
    }

    static func sharedStoreURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appending(path: "SwiftDataResearch.store")
    }

    static func fetchNotes(in context: ModelContext) throws -> [ResearchNote] {
        let descriptor = FetchDescriptor<ResearchNote>(
            sortBy: [SortDescriptor(\ResearchNote.updatedAt, order: .reverse)]
        )
        let notes = try context.fetch(descriptor)
        SharedLog.store.debug("Fetched \(notes.count, privacy: .public) note(s) from shared store")
        return notes
    }

    static func fetchOperationLogs(in context: ModelContext, limit: Int = 8) throws -> [OperationLog] {
        var descriptor = FetchDescriptor<OperationLog>(
            sortBy: [SortDescriptor(\OperationLog.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let logs = try context.fetch(descriptor)
        SharedLog.store.debug("Fetched \(logs.count, privacy: .public) operation log(s)")
        return logs
    }

    static func markAuthor(_ author: String, in context: ModelContext) {
        context.author = author
        SharedLog.store.debug("Set SwiftData context author to \(author, privacy: .public)")
    }

    @discardableResult
    static func insertNote(source: String, in context: ModelContext) throws -> ResearchNote {
        let now = Date()
        let timestamp = insertionTimestamp(for: now)
        let note = ResearchNote(
            title: "\(source) note \(timestamp)",
            detail: "Created by \(source) at \(timestamp)",
            source: source,
            createdAt: now,
            updatedAt: now
        )
        markAuthor(source, in: context)
        SharedLog.store.info("Inserting note from \(source, privacy: .public): \(note.title, privacy: .public)")
        context.insert(note)
        insertOperationLog(
            operationName: "insertNote",
            author: source,
            target: note,
            noteCount: 1,
            detail: "Inserted \(note.title)",
            in: context
        )
        try context.save()
        SharedLog.store.info("Inserted note and saved shared store: \(note.title, privacy: .public)")
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        SharedLog.store.debug("Requested widget timeline reload after insert")
        return note
    }

    static func updateLatestNote(source: String, in context: ModelContext) throws {
        markAuthor(source, in: context)
        let notes = try fetchNotes(in: context)
        let timestamp = insertionTimestamp(for: .now)

        if let note = notes.first {
            SharedLog.store.info("Updating latest note from \(source, privacy: .public): \(note.title, privacy: .public), current revision \(note.revision, privacy: .public)")
            note.revision += 1
            note.detail = "Updated by \(source) at \(timestamp), revision \(note.revision)"
            note.source = source
            note.updatedAt = .now
            insertOperationLog(
                operationName: "updateLatestNote",
                author: source,
                target: note,
                noteCount: 1,
                detail: "Updated latest note to revision \(note.revision)",
                in: context
            )
        } else {
            SharedLog.store.info("No note exists during update from \(source, privacy: .public); inserting fallback note")
            let note = ResearchNote(
                title: "\(source) note \(timestamp)",
                detail: "Created by \(source) during update at \(timestamp)",
                source: source
            )
            context.insert(note)
            insertOperationLog(
                operationName: "updateLatestNoteInsertedFallback",
                author: source,
                target: note,
                noteCount: 1,
                detail: "Inserted fallback note during update",
                in: context
            )
        }

        try context.save()
        SharedLog.store.info("Saved shared store after update from \(source, privacy: .public)")
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        SharedLog.store.debug("Requested widget timeline reload after update")
    }

    static func deleteAll(in context: ModelContext) throws {
        markAuthor("App", in: context)
        let notes = try fetchNotes(in: context)
        SharedLog.store.warning("Deleting all notes from shared store: \(notes.count, privacy: .public) note(s)")
        for note in notes {
            context.delete(note)
        }
        insertOperationLog(
            operationName: "deleteAllNotes",
            author: "App",
            target: nil,
            noteCount: notes.count,
            detail: "Deleted all notes",
            in: context
        )

        try context.save()
        SharedLog.store.info("Saved shared store after deleting all notes")
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        SharedLog.store.debug("Requested widget timeline reload after delete all")
    }

    static func insertOperationLog(
        operationName: String,
        author: String,
        target: ResearchNote?,
        noteCount: Int,
        detail: String,
        in context: ModelContext
    ) {
        let targetIdentifier = target.map { "\($0.persistentModelID)" }
        let log = OperationLog(
            operationName: operationName,
            author: author,
            targetIdentifier: targetIdentifier,
            targetTitle: target?.title,
            noteCount: noteCount,
            detail: detail
        )
        context.insert(log)
        SharedLog.store.info("Queued operation log: \(operationName, privacy: .public), author=\(author, privacy: .public), target=\(target?.title ?? "nil", privacy: .public), count=\(noteCount, privacy: .public)")
    }

    private static func insertionTimestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
