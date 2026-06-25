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
    func dropOwnerMovesToReleased() {
        let viewModel = StreamDemoViewModel(
            logger: SilentDemoLogger(),
            sourceFactory: { AsyncEventSource(logger: SilentDemoLogger()) }
        )

        viewModel.startStream()
        viewModel.dropOwner()

        #expect(viewModel.status == .released)
        #expect(viewModel.canDropOwner == false)

        viewModel.cancelConsumer()
    }
}
