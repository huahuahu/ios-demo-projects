import QuartzCore
import XCTest
@testable import TelegramMiniDockDemo

final class MiniDockLayoutTests: XCTestCase {
    func testCollapsedHeightIncludesSafeAreaAndTelegramStyleMargins() {
        XCTAssertEqual(
            MiniDockLayout.collapsedHeight(safeAreaBottom: 34),
            96
        )
    }

    func testSpacingUsesAtMostFiveVisibleIntervals() {
        let spacingForFive = MiniDockLayout.interitemSpacing(
            itemCount: 5,
            boundingHeight: 900,
            topInset: 60
        )
        let spacingForTen = MiniDockLayout.interitemSpacing(
            itemCount: 10,
            boundingHeight: 900,
            topInset: 60
        )

        XCTAssertEqual(spacingForFive, spacingForTen)
        XCTAssertLessThanOrEqual(spacingForTen, MiniDockLayout.maximumInteritemSpacing)
    }

    func testPerspectiveTransformRetainsNegativePerspectiveAfterRotation() {
        let transform = MiniDockLayout.transform(
            angle: -.pi / 4,
            cardHeight: 800
        )

        XCTAssertLessThan(transform.m34, 0)
        XCTAssertLessThanOrEqual(
            abs(transform.m34),
            abs(MiniDockLayout.perspectiveCorrection)
        )
        XCTAssertFalse(CATransform3DIsIdentity(transform))
    }

    func testCardsRotateFurtherAsTheyMoveDownTheViewport() {
        let topAngle = MiniDockLayout.angle(
            cardOriginY: 80,
            itemCount: 3,
            viewportHeight: 900,
            contentOffsetY: 0,
            topInset: 60
        )
        let lowerAngle = MiniDockLayout.angle(
            cardOriginY: 500,
            itemCount: 3,
            viewportHeight: 900,
            contentOffsetY: 0,
            topInset: 60
        )

        XCTAssertLessThan(lowerAngle, topAngle)
    }
}
