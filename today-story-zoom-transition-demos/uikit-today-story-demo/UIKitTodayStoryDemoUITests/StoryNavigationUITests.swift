import XCTest

final class StoryNavigationUITests: XCTestCase {
    @MainActor
    func testInteractivePopAndBottomCellClose() {
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.cells["story.cell.city-after-rain"]
        XCTAssertTrue(firstCell.waitForExistence(timeout: 8))
        firstCell.tap()

        let closeButton = app.buttons["story.detail.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["story.detail.hero.city-after-rain"].waitForExistence(timeout: 3))

        app.swipeLeft()
        let secondHero = app.otherElements["story.detail.hero.slow-breakfast"]
        XCTAssertTrue(secondHero.waitForExistence(timeout: 5), "横向滑动应切换到第二个 Story")
        app.scrollViews["story.detail.scroll.slow-breakfast"].swipeUp()

        dragFromLeftEdge(in: app, destinationX: 0.28)
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3), "取消 interactive pop 后应恢复详情")
        XCTAssertTrue(secondHero.exists, "取消返回后应保留当前 Story")

        dragFromLeftEdge(in: app, destinationX: 0.92)
        let secondCell = app.cells["story.cell.slow-breakfast"]
        XCTAssertTrue(secondCell.waitForExistence(timeout: 5), "完成 interactive pop 后应回到当前页对应 Cell")

        let collectionView = app.collectionViews["story.collection"]
        let lastCell = app.cells["story.cell.listen-to-stars"]
        for _ in 0..<4 where !lastCell.exists {
            collectionView.swipeUp()
        }
        XCTAssertTrue(lastCell.waitForExistence(timeout: 5))
        lastCell.tap()

        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
        XCTAssertTrue(lastCell.waitForExistence(timeout: 5), "关闭按钮应返回底部来源 Cell")
    }

    @MainActor
    private func dragFromLeftEdge(in app: XCUIApplication, destinationX: CGFloat) {
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.52))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: destinationX, dy: 0.52))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
