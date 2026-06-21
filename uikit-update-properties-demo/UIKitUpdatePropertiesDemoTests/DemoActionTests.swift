import XCTest
@testable import UIKitUpdatePropertiesDemo

final class DemoActionTests: XCTestCase {
    func testActionCopyExplainsInvalidationBoundary() {
        XCTAssertEqual(DemoAction.toggleHidden.title, "Toggle hidden")
        XCTAssertEqual(
            DemoAction.toggleHidden.explanation,
            "Changes hidden state through updateProperties. This does not promise updateConstraints."
        )
        XCTAssertEqual(DemoAction.toggleHidden.expectation, .propertiesOnly)
    }

    func testConstraintActionsHaveDifferentExpectations() {
        XCTAssertEqual(DemoAction.constraintUpdate.expectation, .propertiesAndConstraints)
        XCTAssertEqual(DemoAction.layoutOnly.expectation, .propertiesAndLayout)
        XCTAssertTrue(DemoAction.constraintUpdate.explanation.contains("setNeedsUpdateConstraints"))
        XCTAssertTrue(DemoAction.layoutOnly.explanation.contains("setNeedsLayout"))
    }
}
