import XCTest

final class StoryNavigationUITests: XCTestCase {
    @MainActor
    func testInteractivePopAndBottomCardClose() {
        let app = XCUIApplication()
        app.launch()

        let firstCard = app.buttons["story.card.city-after-rain"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 8))
        firstCard.tap()

        let closeButton = app.buttons["story.detail.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["story.detail.hero.city-after-rain"].waitForExistence(timeout: 3))

        let pager = app.scrollViews["story.detail.pager"]
        XCTAssertTrue(pager.waitForExistence(timeout: 3))
        pager.swipeLeft()
        let secondStoryScrollView = app.scrollViews["story.detail.scroll.slow-breakfast"]
        XCTAssertTrue(secondStoryScrollView.waitForExistence(timeout: 5), "横向滑动应切换到第二个 Story")
        secondStoryScrollView.swipeUp()

        dragFromLeftEdge(in: app, destinationX: 0.28)
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3), "取消 interactive pop 后应恢复详情")
        XCTAssertTrue(secondStoryScrollView.exists, "取消返回后应保留当前 Story")

        dragFromLeftEdge(in: app, destinationX: 0.92)
        let secondCard = app.buttons["story.card.slow-breakfast"]
        XCTAssertTrue(secondCard.waitForExistence(timeout: 5), "完成 interactive pop 后应回到当前页对应卡片")

        let lastCard = app.buttons["story.card.listen-to-stars"]
        for _ in 0..<4 where !lastCard.exists {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(lastCard.waitForExistence(timeout: 5))
        lastCard.tap()

        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
        XCTAssertTrue(lastCard.waitForExistence(timeout: 5), "关闭按钮应返回底部来源卡片")
    }

    @MainActor
    private func dragFromLeftEdge(in app: XCUIApplication, destinationX: CGFloat) {
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.52))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: destinationX, dy: 0.52))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
