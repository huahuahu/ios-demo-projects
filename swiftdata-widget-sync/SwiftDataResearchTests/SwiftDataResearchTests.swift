import Foundation
import SwiftData
import Testing
@testable import SwiftDataResearch

@MainActor
struct SwiftDataResearchTests {
    @Test func insertUpdateDeleteRoundTrip() throws {
        let container = try ModelContainer(
            for: ResearchNote.self,
            OperationLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let note = try SharedStore.insertNote(source: "Test", in: context)
        var logs = try SharedStore.fetchOperationLogs(in: context)
        #expect(logs.first?.operationName == "insertNote")
        #expect(logs.first?.author == "Test")

        note.title = "Probe"
        note.detail = "Initial"
        try context.save()

        var descriptor = FetchDescriptor<ResearchNote>(
            sortBy: [SortDescriptor(\ResearchNote.updatedAt, order: .reverse)]
        )
        var notes = try context.fetch(descriptor)
        #expect(notes.map(\.title) == ["Probe"])

        notes[0].source = "Test"
        notes[0].revision += 1
        notes[0].detail = "Updated"
        notes[0].updatedAt = Date(timeIntervalSince1970: 1)
        try context.save()

        descriptor.predicate = #Predicate { $0.source == "Test" }
        notes = try context.fetch(descriptor)
        #expect(notes.count == 1)
        #expect(notes[0].detail == "Updated")
        #expect(notes[0].revision == 2)

        try SharedStore.updateLatestNote(source: "Test", in: context)
        logs = try SharedStore.fetchOperationLogs(in: context)
        #expect(logs.first?.operationName == "updateLatestNote")

        context.delete(notes[0])
        try context.save()

        descriptor.predicate = nil
        notes = try context.fetch(descriptor)
        #expect(notes.isEmpty)
    }
}
