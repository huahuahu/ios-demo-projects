import XCTest

final class LogResearchDemoTests: XCTestCase {
    func testExampleLogAnalysisFixture() throws {
        NSLog("[LogResearchDemoTests] Starting sample test log fixture")

        let rawMessage = "Synthetic warning for AI log analysis batch 1"
        XCTAssertTrue(rawMessage.contains("warning"))

        NSLog("[LogResearchDemoTests] Finished sample test log fixture")
    }
}

