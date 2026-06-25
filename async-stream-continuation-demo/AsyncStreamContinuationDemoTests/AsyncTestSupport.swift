import Foundation

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
