import SwiftData
import SwiftUI
import UIKit
import WidgetKit

struct ContentView: View {
    let modelContainer: ModelContainer

    @Environment(\.modelContext) private var modelContext
    @State private var notes: [ResearchNote] = []
    @State private var operationLogs: [OperationLog] = []
    @State private var lastOperation = "No operation yet"
    @State private var lastHistorySummary = "No history summary yet"

    var body: some View {
        NavigationStack {
            List {
                Section("Shared Store") {
                    Text(SharedStore.sharedStoreURL()?.path(percentEncoded: false) ?? "App Group store is unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Section("App Writes") {
                    HStack(spacing: 12) {
                        Button("Insert") {
                            insertNote()
                        }

                        Button("Update Latest") {
                            updateLatestNote()
                        }
                        .disabled(notes.isEmpty)

                        Button("Delete All", role: .destructive) {
                            deleteAllNotes()
                        }
                        .disabled(notes.isEmpty)
                    }
                    .buttonStyle(.bordered)

                    LabeledContent("Last operation", value: lastOperation)
                        .font(.footnote)

                    LabeledContent("History summary", value: lastHistorySummary)
                        .font(.footnote)
                }

                Section("Recent Operation Logs") {
                    ForEach(operationLogs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.operationName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text(log.author)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(log.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("count \(log.noteCount)")
                                Text(log.createdAt, format: .dateTime.hour().minute().second())
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Live Shared Results") {
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(note.title)
                                    .font(.headline)

                                Text(note.source)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary, in: Capsule())
                            }

                            Text(note.detail)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("Revision \(note.revision)")
                                Text(note.updatedAt, format: .dateTime.hour().minute().second())
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
            }
            .navigationTitle("App Widget Sync")
            .task {
                refreshNotes(reason: "Loaded shared store")
                await subscribeToStoreChanges()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                SharedLog.app.info("App became active; refreshing notes")
                refreshNotes(reason: "App became active")
            }
            .onChange(of: lastOperation) { oldValue, newValue in
                SharedLog.app.debug("Last operation changed: \(oldValue, privacy: .public) -> \(newValue, privacy: .public)")
            }
        }
    }

    private func subscribeToStoreChanges() async {
        SharedLog.app.info("Starting NSPersistentStoreRemoteChange subscription")
        let monitor = SharedStoreHistoryMonitor(modelContainer: modelContainer)

        for await _ in NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange) {
            SharedLog.app.info("Received NSPersistentStoreRemoteChange notification")
            let summary = await monitor.processNewTransactions()

            await MainActor.run {
                SharedLog.app.info("Refreshing notes after history processing: \(summary.operationDescription, privacy: .public)")
                lastHistorySummary = summary.operationDescription
                refreshNotes()
            }
        }
    }

    private func insertNote() {
        do {
            SharedLog.app.info("App insert button tapped")
            let note = try SharedStore.insertNote(source: "App", in: modelContext)
            SharedLog.app.info("App insert succeeded: \(note.title, privacy: .public)")
            refreshNotes(reason: "Inserted \(note.title)")
        } catch {
            SharedLog.app.error("App insert failed: \(error.localizedDescription, privacy: .public)")
            lastOperation = "Insert failed: \(error.localizedDescription)"
        }
    }

    private func updateLatestNote() {
        do {
            SharedLog.app.info("App update latest button tapped")
            try SharedStore.updateLatestNote(source: "App", in: modelContext)
            SharedLog.app.info("App update latest succeeded")
            refreshNotes(reason: "Updated latest note from App")
        } catch {
            SharedLog.app.error("App update latest failed: \(error.localizedDescription, privacy: .public)")
            lastOperation = "Update failed: \(error.localizedDescription)"
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        do {
            SharedLog.app.warning("Deleting selected notes from app list: \(offsets.count, privacy: .public) note(s)")
            SharedStore.markAuthor("App", in: modelContext)
            let deletedNotes = offsets.map { notes[$0] }
            for note in deletedNotes {
                modelContext.delete(note)
            }
            SharedStore.insertOperationLog(
                operationName: "deleteSelectedNotes",
                author: "App",
                target: deletedNotes.first,
                noteCount: deletedNotes.count,
                detail: "Deleted selected notes",
                in: modelContext
            )
            try modelContext.save()
            SharedLog.app.info("Saved shared store after deleting selected notes")
            WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.widgetKind)
            SharedLog.app.debug("Requested widget timeline reload after deleting selected notes")
            refreshNotes(reason: "Deleted \(offsets.count) note(s)")
        } catch {
            SharedLog.app.error("Delete selected notes failed: \(error.localizedDescription, privacy: .public)")
            lastOperation = "Delete failed: \(error.localizedDescription)"
        }
    }

    private func deleteAllNotes() {
        do {
            SharedLog.app.warning("Delete all button tapped")
            try SharedStore.deleteAll(in: modelContext)
            SharedLog.app.info("Delete all succeeded")
            refreshNotes(reason: "Deleted all notes")
        } catch {
            SharedLog.app.error("Delete all failed: \(error.localizedDescription, privacy: .public)")
            lastOperation = "Delete all failed: \(error.localizedDescription)"
        }
    }

    private func refreshNotes(reason: String? = nil) {
        do {
            notes = try SharedStore.fetchNotes(in: modelContext)
            operationLogs = try SharedStore.fetchOperationLogs(in: modelContext)
            SharedLog.app.debug("Refreshed visible notes: \(notes.count, privacy: .public) note(s), operation logs: \(operationLogs.count, privacy: .public), reason: \(reason ?? "none", privacy: .public)")
            if let reason {
                lastOperation = reason
            }
        } catch {
            SharedLog.app.error("Refresh notes failed: \(error.localizedDescription, privacy: .public)")
            lastOperation = "Refresh failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let container = try! SharedStore.makeModelContainer(inMemory: true)

    ContentView(modelContainer: container)
        .modelContainer(container)
}
