import SwiftUI
import XCTest
@testable import ChatBubbleShapeDemo

final class TailPrototypeShapeTests: XCTestCase {
    func testPrototypeTailUsesLeftTipAndRightBottomConnection() {
        let shape = TailPrototypeBubbleShape()

        let geometry = shape.computeGeometry(in: CGRect(x: 0, y: 0, width: 160, height: 96))

        XCTAssertGreaterThanOrEqual(geometry.tailCapTop.x, geometry.body.minX)
        XCTAssertGreaterThanOrEqual(geometry.tailCapBottom.x, geometry.body.minX)
        XCTAssertGreaterThan(geometry.tailCapTop.x, geometry.tailUpperJoin.x)
        XCTAssertLessThan(geometry.tailCapBottom.x, geometry.tailLowerJoin.x)
        XCTAssertGreaterThan(geometry.tailLowerJoin.x - geometry.tailCapBottom.x, 20)
        XCTAssertGreaterThan(geometry.tailCapBottom.y - geometry.tailCapTop.y, 6)
        XCTAssertGreaterThan(geometry.tailCapBottom.y, geometry.body.maxY)
        XCTAssertGreaterThanOrEqual(geometry.tailUpperJoin.y, geometry.body.maxY - 10)
        XCTAssertLessThanOrEqual(geometry.tailUpperJoin.y, geometry.body.maxY + 4)
        XCTAssertEqual(geometry.tailLowerJoin.y, geometry.body.maxY, accuracy: 0.001)
    }

    func testPrototypeTailPathStaysInsideRect() {
        let rect = CGRect(x: 0, y: 0, width: 160, height: 96)
        let bounds = TailPrototypeBubbleShape().path(in: rect).boundingRect

        XCTAssertFalse(bounds.isNull)
        XCTAssertGreaterThanOrEqual(bounds.minX, rect.minX)
        XCTAssertGreaterThanOrEqual(bounds.minY, rect.minY)
        XCTAssertLessThanOrEqual(bounds.maxX, rect.maxX)
        XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY)
    }
}
