import XCTest
@testable import UIKitUpdatePropertiesDemo

final class DemoActionTests: XCTestCase {
    func testActionCopyExplainsInvalidationBoundary() {
        XCTAssertEqual(DemoAction.toggleHidden.title, "Toggle hidden")
        XCTAssertTrue(DemoAction.toggleHidden.explanation.contains("isDetailHidden"))
        XCTAssertEqual(DemoAction.toggleHidden.expectation, .propertiesOnly)
    }

    func testConstraintActionsHaveDifferentExpectations() {
        XCTAssertEqual(DemoAction.constraintUpdate.expectation, .trackedConstraints)
        XCTAssertEqual(DemoAction.layoutOnly.expectation, .propertiesAndLayout)
        XCTAssertTrue(DemoAction.constraintUpdate.explanation.contains("observation tracking"))
        XCTAssertTrue(DemoAction.layoutOnly.explanation.contains("setNeedsLayout"))
        XCTAssertFalse(DemoAction.constraintUpdate.explanation.contains("setNeedsUpdateConstraints"))
    }

    func testControllerTextOnlyActionExplainsPureViewControllerPropertyTracking() {
        XCTAssertEqual(DemoAction.controllerTextOnly.title, "Controller text only")
        XCTAssertEqual(DemoAction.controllerTextOnly.expectation, .propertiesOnly)
        XCTAssertTrue(DemoAction.controllerTextOnly.explanation.contains("UIViewController.updateProperties()"))
        XCTAssertFalse(DemoAction.controllerTextOnly.explanation.contains("setNeedsLayout"))
        XCTAssertFalse(DemoAction.controllerTextOnly.explanation.contains("updateConstraints"))
    }
}
