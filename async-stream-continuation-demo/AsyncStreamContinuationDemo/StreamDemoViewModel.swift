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
        source != nil
    }

    var canDropOwner: Bool {
        source != nil
    }

    func startStream() {
        consumerTask?.cancel()

        let source = sourceFactory()
        self.source = source
        status = .running(lastEvent: nil)

        let events = source.events
        logger.info("consumer task started")

        consumerTask = Task { [weak self, logger] in
            for await event in events {
                logger.info("consumer received event \(event.logDescription)")
                await MainActor.run {
                    self?.status = .running(lastEvent: event.message)
                }
            }

            logger.info("for-await loop ended")
            await MainActor.run {
                guard case .running = self?.status else {
                    return
                }

                self?.status = .finished
            }
        }

        Task {
            await source.startProducing()
        }
    }

    func cancelConsumer() {
        logger.info("cancel requested")
        consumerTask?.cancel()
        consumerTask = nil
        status = .cancelled
    }

    func finishProducer() {
        logger.info("finish requested")
        guard let source else {
            status = .finished
            return
        }

        Task {
            await source.finish()
        }

        status = .finished
    }

    func dropOwner() {
        logger.info("drop owner requested")
        source = nil
        status = .released
    }
}
