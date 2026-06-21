import XCTest
@testable import UIKitUpdatePropertiesDemo

final class DemoStateTests: XCTestCase {
    func testToggleHiddenOnlyChangesVisibilityAndStatus() {
        let state = DemoState()

        state.apply(.toggleHidden)

        XCTAssertTrue(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 140)
        XCTAssertEqual(state.statusText, DemoAction.toggleHidden.explanation)
    }

    func testConstraintUpdateChangesHeightAndStatus() {
        let state = DemoState()

        state.apply(.constraintUpdate)

        XCTAssertFalse(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 72)
        XCTAssertEqual(state.statusText, DemoAction.constraintUpdate.explanation)
    }

    func testLayoutOnlyChangesHeightAndStatus() {
        let state = DemoState()

        state.apply(.layoutOnly)

        XCTAssertFalse(state.isDetailHidden)
        XCTAssertEqual(state.detailHeight, 188)
        XCTAssertEqual(state.statusText, DemoAction.layoutOnly.explanation)
    }
}
