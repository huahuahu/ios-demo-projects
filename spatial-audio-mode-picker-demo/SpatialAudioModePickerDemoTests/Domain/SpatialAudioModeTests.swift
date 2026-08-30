import XCTest
@testable import SpatialAudioModePickerDemo

final class SpatialAudioModeTests: XCTestCase {
    func testModesHaveStableVisualOrder() {
        XCTAssertEqual(SpatialAudioMode.allCases, [.off, .fixed, .headTracked])
        XCTAssertEqual(SpatialAudioMode.allCases.map(\.index), [0, 1, 2])
    }

    func testOnlyListeningModesEnableSpatialAudio() {
        XCTAssertFalse(SpatialAudioMode.off.isSpatialAudioEnabled)
        XCTAssertTrue(SpatialAudioMode.fixed.isSpatialAudioEnabled)
        XCTAssertTrue(SpatialAudioMode.headTracked.isSpatialAudioEnabled)
    }
}
