import Foundation

enum LifecycleCallback: String, CaseIterable, Equatable {
    case updateProperties
    case updateConstraints
    case layoutSubviews
    case viewWillLayoutSubviews
    case viewDidLayoutSubviews
}

struct LifecycleEvent: Equatable {
    let sequence: Int
    let callback: LifecycleCallback
    let note: String
}

final class LifecycleEventRecorder {
    private(set) var events: [LifecycleEvent] = []

    func record(_ callback: LifecycleCallback, note: String) {
        events.append(
            LifecycleEvent(
                sequence: events.count + 1,
                callback: callback,
                note: note
            )
        )
    }

    func count(for callback: LifecycleCallback) -> Int {
        events.filter { $0.callback == callback }.count
    }

    func clear() {
        events.removeAll()
    }

    func summaryLines() -> [String] {
        LifecycleCallback.allCases.map { callback in
            "\(callback.rawValue): \(count(for: callback))"
        }
    }

    func eventLines(limit: Int = 12) -> [String] {
        events.suffix(limit).map { event in
            "#\(event.sequence) \(event.callback.rawValue) - \(event.note)"
        }
    }
}
