import Foundation
import Synchronization
@testable import AsyncStreamContinuationDemo

enum AsyncTestTimeoutError: Error, Equatable {
    case timedOut
}

enum AsyncTestSupport {
    static func value<T: Sendable>(
        timeout: Duration = .seconds(1),
        operation: @escaping @Sendable () async -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try await Task.sleep(for: timeout)
                throw AsyncTestTimeoutError.timedOut
            }

            guard let result = try await group.next() else {
                throw AsyncTestTimeoutError.timedOut
            }

            group.cancelAll()
            return result
        }
    }

    static func waitUntil(
        attempts: Int = 200,
        delay: Duration = .milliseconds(5),
        condition: @escaping @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<attempts {
            if await condition() {
                return true
            }

            try? await Task.sleep(for: delay)
        }

        return false
    }
}

final class RecordingDemoLogger: DemoLogging {
    private let storage = Mutex<[String]>([])

    func debug(_ message: String) {
        storage.withLock { messages in
            messages.append(message)
        }
    }

    func info(_ message: String) {
        storage.withLock { messages in
            messages.append(message)
        }
    }

    var messages: [String] {
        storage.withLock { messages in
            messages
        }
    }

    func containsInOrder(_ fragments: [String]) -> Bool {
        var searchStartIndex = 0
        let currentMessages = messages

        for fragment in fragments {
            guard let matchIndex = currentMessages[searchStartIndex...].firstIndex(where: { $0.contains(fragment) }) else {
                return false
            }

            searchStartIndex = currentMessages.index(after: matchIndex)
        }

        return true
    }
}

final class SourceFactorySequence: Sendable {
    private let storage: Mutex<[AsyncEventSource]>

    init(_ sources: [AsyncEventSource]) {
        storage = Mutex(sources)
    }

    func next() -> AsyncEventSource {
        storage.withLock { sources in
            sources.removeFirst()
        }
    }
}
