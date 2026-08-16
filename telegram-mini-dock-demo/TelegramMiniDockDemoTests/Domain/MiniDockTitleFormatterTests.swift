import XCTest
@testable import TelegramMiniDockDemo

final class MiniDockTitleFormatterTests: XCTestCase {
    func testEmptyTitlesProduceEmptyText() {
        XCTAssertEqual(
            MiniDockTitleFormatter.collapsedTitle(titles: []),
            ""
        )
    }

    func testOneTitleIsDisplayedWithoutSuffix() {
        XCTAssertEqual(
            MiniDockTitleFormatter.collapsedTitle(titles: ["message.txt"]),
            "message.txt"
        )
    }

    func testMultipleTitlesUseLastTitleAndOthersCount() {
        XCTAssertEqual(
            MiniDockTitleFormatter.collapsedTitle(
                titles: ["message.txt", "notes.md", "model.swift"]
            ),
            "model.swift 及其他 2 个"
        )
    }

    func testLongLastTitleIsTruncated() {
        let result = MiniDockTitleFormatter.collapsedTitle(
            titles: ["first.txt", "copilotLanguageModelWrapper.swift"],
            maximumLastTitleLength: 10
        )

        XCTAssertEqual(result, "copilotLan… 及其他 1 个")
    }
}
