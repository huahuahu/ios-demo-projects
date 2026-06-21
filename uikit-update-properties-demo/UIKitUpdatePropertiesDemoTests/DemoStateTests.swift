import XCTest
@testable import UIKitUpdatePropertiesDemo

final class DemoStateTests: XCTestCase {
    func testToggleHiddenOnlyChangesVisibilityAndStatus() {
        let state = DemoState()

        state.apply(.toggleHidden)

        XCTAssertTrue(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 140)
        XCTAssertEqual(state.layoutMarker, 0)
        XCTAssertEqual(state.statusText, DemoAction.toggleHidden.explanation)
    }

    func testConstraintUpdateChangesHeightAndStatus() {
        let state = DemoState()

        state.apply(.constraintUpdate)

        XCTAssertFalse(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 72)
        XCTAssertEqual(state.layoutMarker, 0)
        XCTAssertEqual(state.statusText, DemoAction.constraintUpdate.explanation)
    }

    func testLayoutOnlyIncrementsMarkerAndLeavesHeightUnchanged() {
        let state = DemoState()
        let initialHeight = state.detailHeight

        state.apply(.layoutOnly)

        XCTAssertEqual(state.layoutMarker, 1)
        XCTAssertEqual(state.detailHeight, initialHeight, "layoutOnly must not change detailHeight — that would also trigger constraints tracking")
        XCTAssertEqual(state.statusText, DemoAction.layoutOnly.explanation)
    }

    func testLayoutOnlyMarkerAccumulatesAcrossTaps() {
        let state = DemoState()

        state.apply(.layoutOnly)
        state.apply(.layoutOnly)
        state.apply(.layoutOnly)

        XCTAssertEqual(state.layoutMarker, 3)
    }
}
