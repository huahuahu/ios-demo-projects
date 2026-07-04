import XCTest
@testable import CollectionViewAnimatedUpdatesDemo

final class StatusFormatterTests: XCTestCase {
    func testMakeStatusTextContainsAllSignals() {
        let text = StatusFormatter.makeStatusText(
            reason: "动画完成",
            mode: "Manual",
            itemCount: 20,
            isApplying: false,
            hasPending: true,
            applyCount: 4,
            enqueueCount: 15,
            completionCount: 15,
            appliedCompletionCount: 2,
            coalescedCompletionCount: 13,
            detail: "manual batch d:1 i:2 m:0 r:0"
        )

        XCTAssertTrue(text.contains("Manual"))
        XCTAssertTrue(text.contains("动画完成"))
        XCTAssertTrue(text.contains("manual batch d:1 i:2 m:0 r:0"))
        XCTAssertTrue(text.contains("items: 20"))
        XCTAssertTrue(text.contains("applying: no"))
        XCTAssertTrue(text.contains("pending: yes"))
        XCTAssertTrue(text.contains("applies: 4"))
        XCTAssertTrue(text.contains("enqueued: 15"))
        XCTAssertTrue(text.contains("completions: 15"))
        XCTAssertTrue(text.contains("applied: 2"))
        XCTAssertTrue(text.contains("coalesced: 13"))
    }
}
