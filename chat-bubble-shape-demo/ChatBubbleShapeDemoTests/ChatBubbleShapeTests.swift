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
}
