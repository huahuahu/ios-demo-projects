import SwiftUI
import XCTest
@testable import ChatBubbleShapeDemo

final class BubbleSampleTests: XCTestCase {
    func testHeroSampleMatchesReferenceGoal() {
        let hero = BubbleSample.hero

        XCTAssertEqual(hero.id, "reference")
        XCTAssertEqual(hero.title, "Reference bubble")
        XCTAssertTrue(hero.message.contains("Japanese washi paper"))
        XCTAssertGreaterThan(hero.style.cornerRadius, 32)
        XCTAssertGreaterThan(hero.style.tailWidth, 20)
        XCTAssertGreaterThan(hero.style.strokeWidth, 4)
    }

    func testComparisonSamplesCoverVisualVariants() {
        let samples = BubbleSample.comparisonSamples

        XCTAssertEqual(samples.map(\.id), ["soft", "bold-outline", "compact-tail"])
        XCTAssertTrue(samples.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(samples.allSatisfy { !$0.description.isEmpty })
        XCTAssertTrue(samples.allSatisfy { !$0.message.isEmpty })
        XCTAssertTrue(samples.allSatisfy { $0.style.cornerRadius > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.tailWidth > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.tailHeight > 0 })
        XCTAssertTrue(samples.allSatisfy { $0.style.strokeWidth > 0 })
    }
}
