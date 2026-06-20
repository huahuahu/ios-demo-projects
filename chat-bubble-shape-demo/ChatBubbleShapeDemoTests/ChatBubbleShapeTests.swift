import SwiftUI
import XCTest
@testable import ChatBubbleShapeDemo

final class ChatBubbleShapeTests: XCTestCase {
    func testReferenceShapeProducesNonEmptyPathInsideRequestedRect() {
        let style = ChatBubbleStyle.reference
        let shape = ChatBubbleShape(
            cornerRadius: style.cornerRadius,
            tailWidth: style.tailWidth,
            tailHeight: style.tailHeight,
            tailInset: style.tailInset
        )

        let rect = CGRect(x: 0, y: 0, width: 320, height: 180)
        let bounds = shape.path(in: rect).boundingRect

        XCTAssertFalse(bounds.isNull)
        XCTAssertGreaterThan(bounds.width, 250)
        XCTAssertGreaterThan(bounds.height, 140)
        XCTAssertGreaterThanOrEqual(bounds.minX, rect.minX)
        XCTAssertGreaterThanOrEqual(bounds.minY, rect.minY)
        XCTAssertLessThanOrEqual(bounds.maxX, rect.maxX)
        XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY)
    }

    func testReferenceTailStaysSmallAndNearLowerLeftCorner() {
        let style = ChatBubbleStyle.reference
        let shape = ChatBubbleShape(
            cornerRadius: style.cornerRadius,
            tailWidth: style.tailWidth,
            tailHeight: style.tailHeight,
            tailInset: style.tailInset
        )

        let geometry = shape.computeGeometry(in: CGRect(x: 0, y: 0, width: 320, height: 180))

        XCTAssertGreaterThanOrEqual(geometry.tailTip.x, geometry.body.minX)
        XCTAssertGreaterThanOrEqual(geometry.tailTop.x, geometry.body.minX)
        XCTAssertGreaterThanOrEqual(geometry.tailBase.x, geometry.body.minX)
        XCTAssertLessThanOrEqual(geometry.tailBase.x - geometry.body.minX, style.cornerRadius * 0.55)
        XCTAssertLessThanOrEqual(geometry.tailJoin.x - geometry.body.minX, style.cornerRadius * 1.3)
        XCTAssertGreaterThanOrEqual(geometry.tailTop.y, geometry.body.maxY - style.tailHeight * 0.75)
        XCTAssertLessThanOrEqual(geometry.tailBase.y - geometry.body.maxY, style.tailHeight * 0.85)
        XCTAssertLessThanOrEqual(geometry.tailTip.y - geometry.body.maxY, style.tailHeight * 0.4)
    }

    func testReferenceTailConnectsToBottomEdgeInsteadOfLeftSide() {
        let style = ChatBubbleStyle.reference
        let shape = ChatBubbleShape(
            cornerRadius: style.cornerRadius,
            tailWidth: style.tailWidth,
            tailHeight: style.tailHeight,
            tailInset: style.tailInset
        )

        let geometry = shape.computeGeometry(in: CGRect(x: 0, y: 0, width: 320, height: 180))

        XCTAssertGreaterThan(
            geometry.tailJoin.y,
            geometry.body.maxY - 0.001,
            "The tail should start from the lower-left corner area, not halfway up the left edge."
        )
        XCTAssertLessThanOrEqual(
            geometry.tailJoin.x - geometry.body.minX,
            style.cornerRadius * 1.3,
            "The bottom-edge connection should stay short instead of forming a long underline."
        )
    }

    func testReferenceTailUsesRoundedFootBeforeJoiningTheBottomEdge() {
        let style = ChatBubbleStyle.reference
        let shape = ChatBubbleShape(
            cornerRadius: style.cornerRadius,
            tailWidth: style.tailWidth,
            tailHeight: style.tailHeight,
            tailInset: style.tailInset
        )

        let geometry = shape.computeGeometry(in: CGRect(x: 0, y: 0, width: 320, height: 180))

        XCTAssertLessThan(
            geometry.tailTip.x,
            geometry.tailBase.x,
            "The rounded foot should curve rightward from the left tail tip."
        )
        XCTAssertGreaterThan(
            geometry.tailBase.y,
            geometry.tailTip.y,
            "The tail should have a soft lower belly instead of a sharp point."
        )
        XCTAssertGreaterThan(
            geometry.tailJoin.x,
            geometry.tailBase.x,
            "The tail should blend into the bottom edge to the right of the rounded foot."
        )
    }

    func testShapeClampsGeometryForSmallRects() {
        let shape = ChatBubbleShape(
            cornerRadius: 80,
            tailWidth: 60,
            tailHeight: 60,
            tailInset: 40
        )

        let rect = CGRect(x: 0, y: 0, width: 48, height: 36)
        let bounds = shape.path(in: rect).boundingRect

        XCTAssertFalse(bounds.isNull)
        XCTAssertGreaterThan(bounds.width, 0)
        XCTAssertGreaterThan(bounds.height, 0)
        XCTAssertGreaterThanOrEqual(bounds.minX, rect.minX)
        XCTAssertGreaterThanOrEqual(bounds.minY, rect.minY)
        XCTAssertLessThanOrEqual(bounds.maxX, rect.maxX)
        XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY)
    }

    func testSmallRectRadiusClampPreventsSelfIntersectingTopEdge() {
        let shape = ChatBubbleShape(
            cornerRadius: 80,
            tailWidth: 60,
            tailHeight: 60,
            tailInset: 40
        )

        let rect = CGRect(x: 0, y: 0, width: 48, height: 36)
        let geometry = shape.computeGeometry(in: rect)

        // Verify body dimensions are non-negative
        XCTAssertGreaterThanOrEqual(geometry.body.width, 0)
        XCTAssertGreaterThanOrEqual(geometry.body.height, 0)

        // Verify radius fits within body to prevent self-intersection
        XCTAssertLessThanOrEqual(geometry.safeRadius, geometry.body.width / 2.0)
        XCTAssertLessThanOrEqual(geometry.safeRadius, geometry.body.height / 2.0)

        // Verify corner points are valid (not inverted)
        XCTAssertLessThanOrEqual(
            geometry.body.minX + geometry.safeRadius,
            geometry.body.maxX - geometry.safeRadius
        )
        XCTAssertLessThanOrEqual(
            geometry.body.minY + geometry.safeRadius,
            geometry.body.maxY - geometry.safeRadius
        )

        // Verify path produces valid bounding rect within requested rect
        let pathBounds = shape.path(in: rect).boundingRect
        XCTAssertFalse(pathBounds.isNull)
        XCTAssertGreaterThanOrEqual(pathBounds.minX, rect.minX)
        XCTAssertGreaterThanOrEqual(pathBounds.minY, rect.minY)
        XCTAssertLessThanOrEqual(pathBounds.maxX, rect.maxX)
        XCTAssertLessThanOrEqual(pathBounds.maxY, rect.maxY)
    }
}
