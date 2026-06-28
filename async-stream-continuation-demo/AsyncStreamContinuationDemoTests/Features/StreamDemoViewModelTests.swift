import Testing
@testable import AsyncStreamContinuationDemo

@MainActor
struct StreamDemoViewModelTests {
    @Test
    func startStreamMovesToRunning() async {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        await viewModel.startStream()

        #expect(viewModel.status == .running(lastEvent: nil))
        #expect(viewModel.canCancel)
        #expect(viewModel.canFinish)
        #expect(viewModel.canDropOwner)

        viewModel.cancelConsumer()
    }

    @Test
    func startingAgainFinishesPreviousSourceBeforeReplacingIt() async {
        let firstSource = AsyncEventSource(logger: SilentDemoLogger())
        let secondSource = AsyncEventSource(logger: SilentDemoLogger())
        let factory = SourceFactorySequence([firstSource, secondSource])
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { factory.next() }
        )

        await viewModel.startStream()
        await viewModel.startStream()

        let previousSourceFinished = await AsyncTestSupport.waitUntil {
            let snapshot = await firstSource.snapshot()
            return snapshot.isFinished && snapshot.cleanupCount == 1 && snapshot.isProducing == false
        }

        #expect(previousSourceFinished)
        guard case .running = viewModel.status else {
            Issue.record("Expected the replacement stream to stay running")
            return
        }

        #expect(viewModel.canCancel)
        #expect(viewModel.canDropOwner)

        await viewModel.dropOwner()
    }

    @Test
    func cancelConsumerMovesToCancelled() async {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        await viewModel.startStream()
        viewModel.cancelConsumer()

        #expect(viewModel.status == .cancelled)
        #expect(viewModel.canCancel == false)
    }

    @Test
    func finishProducerMovesToFinished() async {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        await viewModel.startStream()
        await viewModel.finishProducer()

        #expect(viewModel.status == .finished)
    }

    @Test
    func finishProducerClearsConsumerTaskWhenStreamEnds() async {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        await viewModel.startStream()
        await viewModel.finishProducer()

        #expect(viewModel.status == .finished)
        #expect(viewModel.canCancel == false)
    }

    @Test
    func dropOwnerFinishesSourceAndCancelsConsumerBeforeRelease() async {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { source }
        )

        await viewModel.startStream()
        await viewModel.dropOwner()

        #expect(viewModel.status == .released)
        #expect(viewModel.canDropOwner == false)
        #expect(viewModel.canCancel == false)

        let cleanedUp = await AsyncTestSupport.waitUntil {
            let snapshot = await source.snapshot()
            return snapshot.isFinished && snapshot.cleanupCount == 1 && snapshot.isProducing == false
        }

        #expect(cleanedUp)
    }

    @Test
    func dropOwnerLogsFinishBeforeSourceOwnerRelease() async {
        let logger = RecordingDemoLogger()
        let source = AsyncEventSource(logger: logger)
        let viewModel = StreamDemoViewModel(
            logger: logger,
            sourceFactory: { source }
        )

        await viewModel.startStream()
        await viewModel.dropOwner()

        #expect(logger.containsInOrder([
            "drop owner requested",
            "finishing source before owner release",
            "finish requested",
            "source owner released"
        ]))
    }
}
