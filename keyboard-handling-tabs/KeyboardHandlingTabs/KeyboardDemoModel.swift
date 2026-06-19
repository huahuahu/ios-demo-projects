import Foundation

struct KeyboardMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isOutgoing: Bool
}

enum KeyboardPlatform: String {
    case swiftUI = "SwiftUI"
    case uiKit = "UIKit"

    var displayName: String {
        rawValue
    }
}

enum KeyboardAction: Int, CaseIterable, Hashable {
    case attach
    case emoji
    case clear
    case dismissKeyboard

    var title: String {
        switch self {
        case .attach:
            "Attach"
        case .emoji:
            "Emoji"
        case .clear:
            "Clear"
        case .dismissKeyboard:
            "Dismiss"
        }
    }

    var symbolName: String {
        switch self {
        case .attach:
            "paperclip"
        case .emoji:
            "face.smiling"
        case .clear:
            "xmark.circle"
        case .dismissKeyboard:
            "keyboard.chevron.compact.down"
        }
    }
}

enum AttachmentSource: String, CaseIterable, Hashable {
    case photoLibrary = "Photo Library"
    case camera = "Camera"
    case files = "Files"

    var token: String {
        switch self {
        case .photoLibrary:
            "[Photo]"
        case .camera:
            "[Camera]"
        case .files:
            "[File]"
        }
    }

    var symbolName: String {
        switch self {
        case .photoLibrary:
            "photo.on.rectangle"
        case .camera:
            "camera"
        case .files:
            "folder"
        }
    }
}

struct KeyboardDemoState {
    let platform: KeyboardPlatform
    private(set) var messages: [KeyboardMessage]
    private(set) var draft: String

    init(platform: KeyboardPlatform) {
        self.platform = platform
        self.messages = [
            KeyboardMessage(
                id: UUID(),
                text: "\(platform.displayName) tab: ScrollView + input bar pinned above keyboard.",
                isOutgoing: false
            ),
            KeyboardMessage(
                id: UUID(),
                text: "Use action buttons, then send a message to verify keyboard-safe layout.",
                isOutgoing: false
            )
        ]
        self.draft = ""
    }

    mutating func updateDraft(_ text: String) {
        draft = text
    }

    mutating func handleAction(_ action: KeyboardAction) {
        switch action {
        case .attach:
            break
        case .emoji:
            let token = "[Emoji]"
            draft = draft.isEmpty ? token : "\(draft) \(token)"
        case .clear:
            draft = ""
        case .dismissKeyboard:
            break
        }
    }

    mutating func selectAttachmentSource(_ source: AttachmentSource) {
        draft = draft.isEmpty ? source.token : "\(draft) \(source.token)"
    }

    @discardableResult
    mutating func sendDraft() -> KeyboardMessage? {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let message = KeyboardMessage(id: UUID(), text: trimmed, isOutgoing: true)
        messages.append(message)
        draft = ""
        return message
    }
}
