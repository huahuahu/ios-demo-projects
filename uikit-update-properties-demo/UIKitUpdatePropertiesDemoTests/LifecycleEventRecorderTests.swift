import XCTest
@testable import UIKitUpdatePropertiesDemo

final class LifecycleEventRecorderTests: XCTestCase {
    func testRecordsOrderedEventsAndCountsByCallback() {
        let recorder = LifecycleEventRecorder()

        recorder.record(.updateProperties, note: "first property pass")
        recorder.record(.layoutSubviews, note: "layout after property pass")
        recorder.record(.updateProperties, note: "second property pass")

        XCTAssertEqual(recorder.count(for: .updateProperties), 2)
        XCTAssertEqual(recorder.count(for: .layoutSubviews), 1)
        XCTAssertEqual(recorder.count(for: .updateConstraints), 0)
        XCTAssertEqual(recorder.events.map(\.sequence), [1, 2, 3])
        XCTAssertEqual(recorder.events.map(\.callback), [.updateProperties, .layoutSubviews, .updateProperties])
    }

    func testSummaryAndEventLinesAreStableForTheDemoUI() {
        let recorder = LifecycleEventRecorder()

        recorder.record(.viewWillLayoutSubviews, note: "controller before layout")
        recorder.record(.viewDidLayoutSubviews, note: "controller after layout")

        XCTAssertEqual(
            recorder.summaryLines(),
            [
                "updateProperties: 0",
                "updateConstraints: 0",
                "layoutSubviews: 0",
                "viewWillLayoutSubviews: 1",
                "viewDidLayoutSubviews: 1"
            ]
        )
        XCTAssertEqual(
            recorder.eventLines(),
            [
                "#1 viewWillLayoutSubviews - controller before layout",
                "#2 viewDidLayoutSubviews - controller after layout"
            ]
        )
    }

    func testClearRemovesEventsAndResetsCounts() {
        let recorder = LifecycleEventRecorder()

        recorder.record(.updateProperties, note: "tracked")
        recorder.clear()

        XCTAssertTrue(recorder.events.isEmpty)
        XCTAssertEqual(recorder.count(for: .updateProperties), 0)
    }
}
