import Testing
@testable import AsyncStreamContinuationDemo

@MainActor
struct StreamDemoViewModelTests {
    @Test
    func startStreamMovesToRunning() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()

        #expect(viewModel.status == .running(lastEvent: nil))
        #expect(viewModel.canCancel)
        #expect(viewModel.canFinish)
        #expect(viewModel.canDropOwner)

        viewModel.cancelConsumer()
    }

    @Test
    func cancelConsumerMovesToCancelled() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()
        viewModel.cancelConsumer()

        #expect(viewModel.status == .cancelled)
        #expect(viewModel.canCancel == false)
    }

    @Test
    func finishProducerMovesToFinished() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()
        viewModel.finishProducer()

        #expect(viewModel.status == .finished)
    }

    @Test
    func dropOwnerFinishesSourceAndCancelsConsumerBeforeRelease() async {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { source }
        )

        viewModel.startStream()
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
}
