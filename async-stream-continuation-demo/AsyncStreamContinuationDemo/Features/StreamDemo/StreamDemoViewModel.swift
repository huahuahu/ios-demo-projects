import Observation

@MainActor
@Observable
final class StreamDemoViewModel {
    typealias SourceFactory = @Sendable () -> AsyncEventSource

    private(set) var status: DemoStatus = .idle

    private var source: AsyncEventSource?
    private var consumerTask: Task<Void, Never>?
    private let logger: any DemoLogging
    private let sourceFactory: SourceFactory
    private var streamGeneration = 0

    init(
        logger: any DemoLogging = SystemDemoLogger(category: "ViewModel"),
        sourceFactory: @escaping SourceFactory = {
            AsyncEventSource(logger: SystemDemoLogger(category: "EventSource"))
        }
    ) {
        self.logger = logger
        self.sourceFactory = sourceFactory
    }

    isolated deinit {
        logger.info("view model deinit")
        consumerTask?.cancel()
    }

    var canCancel: Bool {
        consumerTask != nil
    }

    var canFinish: Bool {
        guard source != nil else {
            return false
        }

        if case .finished = status {
            return false
        }

        if case .released = status {
            return false
        }

        return true
    }

    var canDropOwner: Bool {
        source != nil
    }

    func startStream() async {
        streamGeneration += 1
        let generation = streamGeneration

        if let source {
            logger.info("finishing source before replacement")
            await source.finish()
        }

        guard streamGeneration == generation else {
            return
        }

        consumerTask?.cancel()
        consumerTask = nil

        let source = sourceFactory()
        self.source = source
        status = .running(lastEvent: nil)

        let events = source.events
        logger.info("consumer task started")

        consumerTask = Task { [weak self, logger, generation] in
            for await event in events {
                logger.info("consumer received event \(event.logDescription)")
                await MainActor.run {
                    guard self?.streamGeneration == generation else {
                        return
                    }

                    self?.status = .running(lastEvent: event.message)
                }
            }

            logger.info("for-await loop ended")
            await MainActor.run {
                guard let self, self.streamGeneration == generation else {
                    return
                }

                self.consumerTask = nil
                guard case .running = self.status else {
                    return
                }

                self.status = .finished
            }
        }

        Task {
            await source.startProducing()
        }
    }

    func cancelConsumer() {
        logger.info("cancel requested")
        streamGeneration += 1
        consumerTask?.cancel()
        consumerTask = nil
        status = .cancelled
    }

    func finishProducer() async {
        logger.info("finish requested")
        streamGeneration += 1
        let generation = streamGeneration

        guard let source else {
            consumerTask?.cancel()
            consumerTask = nil
            status = .finished
            return
        }

        await source.finish()

        guard streamGeneration == generation else {
            return
        }

        consumerTask?.cancel()
        consumerTask = nil
        status = .finished
    }

    func dropOwner() async {
        logger.info("drop owner requested")
        streamGeneration += 1
        let generation = streamGeneration

        if let source {
            logger.info("finishing source before owner release")
            await source.finish()
        }

        guard streamGeneration == generation else {
            return
        }

        consumerTask?.cancel()
        consumerTask = nil
        source = nil
        logger.info("source owner released")
        status = .released
    }
}
