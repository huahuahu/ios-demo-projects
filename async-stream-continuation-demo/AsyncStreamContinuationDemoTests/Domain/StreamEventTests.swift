import Foundation
import Testing
@testable import AsyncStreamContinuationDemo

struct StreamEventTests {
    @Test
    func logDescriptionIncludesIdentifierAndMessage() {
        let event = StreamEvent(
            id: 3,
            createdAt: Date(timeIntervalSince1970: 0),
            message: "manual sample"
        )

        #expect(event.logDescription == "#3 manual sample")
    }

    @Test
    func statusTextExplainsTheCurrentLifecycleState() {
        #expect(DemoStatus.idle.title == "Idle")
        #expect(DemoStatus.running(lastEvent: "Event 1").title == "Running")
        #expect(DemoStatus.cancelled.title == "Cancelled")
        #expect(DemoStatus.finished.title == "Finished")
        #expect(DemoStatus.released.title == "Owner Released")

        #expect(DemoStatus.running(lastEvent: "Event 1").detail == "Latest event: Event 1")
        #expect(DemoStatus.running(lastEvent: nil).detail == "Waiting for the producer to yield.")
    }

    @Test
    func eventSourceSnapshotReportsLifecycleState() {
        let snapshot = EventSourceSnapshot(
            yieldAttemptCount: 2,
            deliveredOrBufferedCount: 1,
            cleanupCount: 1,
            isFinished: true,
            isProducing: false
        )

        #expect(snapshot.yieldAttemptCount == 2)
        #expect(snapshot.deliveredOrBufferedCount == 1)
        #expect(snapshot.cleanupCount == 1)
        #expect(snapshot.isFinished)
        #expect(snapshot.isProducing == false)
    }
}
