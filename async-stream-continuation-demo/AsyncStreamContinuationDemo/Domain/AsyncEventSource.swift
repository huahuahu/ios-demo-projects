import Foundation

actor AsyncEventSource {
    typealias Continuation = AsyncStream<StreamEvent>.Continuation

    nonisolated let events: AsyncStream<StreamEvent>

    private let continuation: Continuation
    private let logger: any DemoLogging
    private var nextEventID = 1
    private var producerTask: Task<Void, Never>?
    private var cleanedUp = false
    private var finished = false
    private var yieldAttemptCount = 0
    private var deliveredOrBufferedCount = 0
    private var cleanupCount = 0

    init(
        logger: any DemoLogging = SystemDemoLogger(category: "EventSource"),
        bufferingPolicy: Continuation.BufferingPolicy = .bufferingNewest(10)
    ) {
        self.logger = logger
        let streamPair = AsyncStream.makeStream(
            of: StreamEvent.self,
            bufferingPolicy: bufferingPolicy
        )
        events = streamPair.stream
        continuation = streamPair.continuation

        logger.info("stream created")
        logger.info("continuation stored")

        continuation.onTermination = { [weak self] termination in
            Task {
                await self?.handleTermination(termination)
            }
        }
    }

    deinit {
        logger.info("source deinit")
        producerTask?.cancel()
    }

    func startProducing(interval: Duration = .milliseconds(700)) {
        guard finished == false && cleanedUp == false else {
            logger.debug("producer task not started because stream is already finished")
            return
        }

        guard producerTask == nil else {
            logger.debug("producer task already running")
            return
        }

        logger.info("producer task started")
        producerTask = Task { [weak self] in
            while Task.isCancelled == false {
                _ = await self?.emitNext()

                do {
                    try await Task.sleep(for: interval)
                } catch {
                    break
                }
            }
        }
    }

    @discardableResult
    func emitNext() -> Continuation.YieldResult {
        let event = StreamEvent(id: nextEventID, message: "Event \(nextEventID)")
        nextEventID += 1
        yieldAttemptCount += 1

        logger.debug("yield requested \(event.logDescription)")
        let result = continuation.yield(event)
        logger.debug("yield result \(describe(result))")

        switch result {
        case .enqueued:
            deliveredOrBufferedCount += 1
        case .dropped:
            deliveredOrBufferedCount += 1
        case .terminated:
            cleanup(reason: "yield returned terminated")
        @unknown default:
            logger.info("yield returned an unknown result")
        }

        return result
    }

    func finish() {
        guard finished == false else {
            logger.debug("finish requested after stream already finished")
            return
        }

        finished = true
        logger.info("finish requested")
        continuation.finish()
        cleanup(reason: "finish requested")
    }

    func snapshot() -> EventSourceSnapshot {
        EventSourceSnapshot(
            yieldAttemptCount: yieldAttemptCount,
            deliveredOrBufferedCount: deliveredOrBufferedCount,
            cleanupCount: cleanupCount,
            isFinished: finished,
            isProducing: producerTask != nil
        )
    }

    private func handleTermination(_ termination: Continuation.Termination) {
        logger.info("continuation onTermination reason \(String(describing: termination))")
        cleanup(reason: "termination \(String(describing: termination))")
    }

    private func cleanup(reason: String) {
        guard cleanedUp == false else {
            logger.debug("cleanup skipped because it already ran")
            return
        }

        cleanedUp = true
        cleanupCount += 1
        logger.info("cleanup started reason=\(reason)")
        producerTask?.cancel()
        producerTask = nil
        logger.info("cleanup completed")
    }

    private func describe(_ result: Continuation.YieldResult) -> String {
        switch result {
        case .enqueued(let remaining):
            "enqueued remaining=\(remaining)"
        case .dropped(let event):
            "dropped \(event.logDescription)"
        case .terminated:
            "terminated"
        @unknown default:
            "unknown"
        }
    }
}
