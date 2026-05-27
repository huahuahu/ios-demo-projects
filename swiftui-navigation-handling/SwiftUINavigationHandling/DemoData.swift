import Foundation

struct DemoCollection: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let symbolName: String
    let messageIDs: [Int]
}

struct DemoMessage: Identifiable, Hashable, Sendable {
    let id: Int
    let collectionID: String
    let title: String
    let sender: String
    let preview: String
}

struct DemoSetting: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
}

enum DemoData {
    static let collections: [DemoCollection] = [
        DemoCollection(id: "priority", title: "Priority", symbolName: "flag.fill", messageIDs: [101, 102]),
        DemoCollection(id: "planning", title: "Planning", symbolName: "calendar", messageIDs: [201, 202]),
        DemoCollection(id: "archive", title: "Archive", symbolName: "archivebox", messageIDs: [301])
    ]

    static let messages: [DemoMessage] = [
        DemoMessage(
            id: 101,
            collectionID: "priority",
            title: "Design Review",
            sender: "Rina",
            preview: "Navigation changes need a single source of truth."
        ),
        DemoMessage(
            id: 102,
            collectionID: "priority",
            title: "Release Notes",
            sender: "Mateo",
            preview: "The beta build should open directly to the selected message."
        ),
        DemoMessage(
            id: 201,
            collectionID: "planning",
            title: "Sprint Plan",
            sender: "Ivy",
            preview: "The detail flow needs a reply step and a clean root reset."
        ),
        DemoMessage(
            id: 202,
            collectionID: "planning",
            title: "Roadmap Input",
            sender: "Jun",
            preview: "Keep navigation routes stable so links survive refactors."
        ),
        DemoMessage(
            id: 301,
            collectionID: "archive",
            title: "Older Thread",
            sender: "Nora",
            preview: "Archived items still use the same route destinations."
        )
    ]

    static let settings: [DemoSetting] = [
        DemoSetting(
            id: "account",
            title: "Account",
            detail: "Account settings live on the Settings tab path."
        ),
        DemoSetting(
            id: "notifications",
            title: "Notifications",
            detail: "Deep links can switch tabs before pushing this detail view."
        )
    ]

    static func collection(id: String) -> DemoCollection? {
        collections.first { $0.id == id }
    }

    static func message(id: Int) -> DemoMessage? {
        messages.first { $0.id == id }
    }

    static func messages(in collectionID: String) -> [DemoMessage] {
        messages.filter { $0.collectionID == collectionID }
    }

    static func setting(id: String) -> DemoSetting? {
        settings.first { $0.id == id }
    }
}
