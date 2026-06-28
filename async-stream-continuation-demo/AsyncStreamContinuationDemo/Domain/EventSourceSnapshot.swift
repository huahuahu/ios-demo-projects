struct EventSourceSnapshot: Equatable, Sendable {
    let yieldAttemptCount: Int
    let deliveredOrBufferedCount: Int
    let cleanupCount: Int
    let isFinished: Bool
    let isProducing: Bool
}
