import XCTest
@testable import FontSizeResearch

final class FontSizeResearchTests: XCTestCase {
    func testDefaultSamplesAreOrderedByPointSize() {
        let samples = FontSample.defaultSamples
        let sizes = samples.map(\.pointSize)

        XCTAssertEqual(sizes, sizes.sorted())
    }

    func testDefaultSamplesHaveUniqueIdentifiers() {
        let samples = FontSample.defaultSamples
        let identifiers = Set(samples.map(\.id))

        XCTAssertEqual(identifiers.count, samples.count)
    }
}

