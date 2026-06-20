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
