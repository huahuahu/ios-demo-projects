import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct SharedNotesEntry: TimelineEntry {
    let date: Date
    let notes: [NoteSnapshot]
}

struct NoteSnapshot: Identifiable {
    let id: String
    let title: String
    let detail: String
    let source: String
    let revision: Int
    let updatedAt: Date

    init(note: ResearchNote) {
        id = "\(note.persistentModelID)"
        title = note.title
        detail = note.detail
        source = note.source
        revision = note.revision
        updatedAt = note.updatedAt
    }
}

struct SharedNotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> SharedNotesEntry {
        SharedNotesEntry(date: .now, notes: [
            NoteSnapshot.preview
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SharedNotesEntry) -> Void) {
        SharedLog.widget.debug("Widget snapshot requested")
        completion(loadEntry(reason: "snapshot"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SharedNotesEntry>) -> Void) {
        SharedLog.widget.info("Widget timeline requested")
        completion(Timeline(entries: [loadEntry(reason: "timeline")], policy: .never))
    }

    private func loadEntry(reason: String) -> SharedNotesEntry {
        do {
            SharedLog.widget.debug("Loading widget entry for \(reason, privacy: .public)")
            let container = try SharedStore.makeModelContainer()
            let context = ModelContext(container)
            let notes = try SharedStore.fetchNotes(in: context)
                .prefix(3)
                .map(NoteSnapshot.init(note:))
            let snapshots = Array(notes)
            SharedLog.widget.info("Loaded widget entry for \(reason, privacy: .public): \(snapshots.count, privacy: .public) note(s)")
            return SharedNotesEntry(date: .now, notes: snapshots)
        } catch {
            SharedLog.widget.error("Widget entry load failed for \(reason, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return SharedNotesEntry(date: .now, notes: [
                NoteSnapshot(title: "Read failed", detail: error.localizedDescription, source: "Widget", revision: 0, updatedAt: .now)
            ])
        }
    }
}

struct SwiftDataResearchWidgetView: View {
    let entry: SharedNotesEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Shared Notes")
                    .font(.headline)

                Spacer()

                Text(entry.date, format: .dateTime.hour().minute().second())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.notes.isEmpty {
                Text("No notes yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.notes.prefix(2)) { note in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text("r\(note.revision) by \(note.source)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button(intent: InsertWidgetNoteIntent()) {
                    Label("Add", systemImage: "plus")
                }

                Button(intent: UpdateWidgetNoteIntent()) {
                    Label("Update", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .font(.caption2)
        }
        .containerBackground(.background, for: .widget)
    }
}

struct SwiftDataResearchWidget: Widget {
    let kind = SharedStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SharedNotesProvider()) { entry in
            SwiftDataResearchWidgetView(entry: entry)
        }
        .configurationDisplayName("SwiftData Sync")
        .description("Writes to the same SwiftData store as the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SwiftDataResearchWidgetBundle: WidgetBundle {
    var body: some Widget {
        SwiftDataResearchWidget()
    }
}

extension NoteSnapshot {
    static let preview = NoteSnapshot(
        title: "Preview note",
        detail: "Shared SwiftData",
        source: "Preview",
        revision: 1,
        updatedAt: .now
    )

    init(title: String, detail: String, source: String, revision: Int, updatedAt: Date) {
        id = title
        self.title = title
        self.detail = detail
        self.source = source
        self.revision = revision
        self.updatedAt = updatedAt
    }
}
