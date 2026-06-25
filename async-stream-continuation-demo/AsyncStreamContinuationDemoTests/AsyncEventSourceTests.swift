import Testing
@testable import AsyncStreamContinuationDemo

struct AsyncEventSourceTests {
    @Test(.timeLimit(.minutes(1)))
    func emitNextProducesTheFirstEvent() async throws {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let eventTask = Task<StreamEvent?, Never> {
            var iterator = source.events.makeAsyncIterator()
            return await iterator.next()
        }

        _ = await source.emitNext()

        let event = try await AsyncTestSupport.value {
            await eventTask.value
        }
        let unwrappedEvent = try #require(event)

        #expect(unwrappedEvent.id == 1)
        #expect(unwrappedEvent.message == "Event 1")

        let snapshot = await source.snapshot()
        #expect(snapshot.yieldAttemptCount == 1)
        #expect(snapshot.deliveredOrBufferedCount == 1)

        await source.finish()
    }

    @Test(.timeLimit(.minutes(1)))
    func finishEndsTheStreamAndRunsCleanup() async throws {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let eventTask = Task<StreamEvent?, Never> {
            var iterator = source.events.makeAsyncIterator()
            return await iterator.next()
        }

        await source.finish()

        let event = try await AsyncTestSupport.value {
            await eventTask.value
        }

        #expect(event == nil)

        let cleanedUp = await AsyncTestSupport.waitUntil {
            let snapshot = await source.snapshot()
            return snapshot.cleanupCount == 1 && snapshot.isProducing == false
        }

        #expect(cleanedUp)

        let snapshot = await source.snapshot()
        #expect(snapshot.isFinished)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingTheConsumerRunsTerminationCleanup() async {
        let source = AsyncEventSource(logger: SilentDemoLogger())
        let consumer = Task<Void, Never> {
            for await _ in source.events {}
        }

        await Task.yield()
        consumer.cancel()

        let cleanedUp = await AsyncTestSupport.waitUntil {
            let snapshot = await source.snapshot()
            return snapshot.cleanupCount == 1
        }

        #expect(cleanedUp)
        #expect(consumer.isCancelled)
    }

    @Test(.timeLimit(.minutes(1)))
    func cleanupStopsTheProducerTask() async {
        let source = AsyncEventSource(logger: SilentDemoLogger())

        await source.startProducing(interval: .milliseconds(10))

        let startedSnapshot = await source.snapshot()
        #expect(startedSnapshot.isProducing)

        await source.finish()

        let stopped = await AsyncTestSupport.waitUntil {
            let snapshot = await source.snapshot()
            return snapshot.cleanupCount == 1 && snapshot.isProducing == false
        }

        #expect(stopped)
    }
}
