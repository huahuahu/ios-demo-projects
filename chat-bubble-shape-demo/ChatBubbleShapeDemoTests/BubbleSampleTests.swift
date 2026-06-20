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
        XCTAssertLessThanOrEqual(hero.style.tailWidth, 16)
        XCTAssertLessThanOrEqual(hero.style.tailHeight, 14)
        XCTAssertLessThanOrEqual(hero.style.tailInset, 6)
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

    @MainActor
    func testChatBubbleViewCanBeConstructedWithPresetData() {
        let view = ChatBubbleView(
            message: BubbleSample.hero.message,
            style: BubbleSample.hero.style,
            font: .title2
        )

        XCTAssertEqual(view.message, BubbleSample.hero.message)
        XCTAssertEqual(view.style, BubbleSample.hero.style)
    }

    func testAllStylePresetsHaveTextColor() {
        let textColor = Color(red: 0.12, green: 0.11, blue: 0.18)
        XCTAssertEqual(ChatBubbleStyle.reference.textColor, textColor)
        XCTAssertEqual(ChatBubbleStyle.soft.textColor, textColor)
        XCTAssertEqual(ChatBubbleStyle.boldOutline.textColor, textColor)
        XCTAssertEqual(ChatBubbleStyle.compactTail.textColor, textColor)
    }
}
