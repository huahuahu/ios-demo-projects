import XCTest
@testable import SpatialAudioModePickerDemo

@MainActor
final class SpatialAudioPickerModelTests: XCTestCase {
    func testCollapsedPickerExpandsWithoutChangingMode() {
        let model = SpatialAudioPickerModel(selectedMode: .off)

        model.handleTap(on: .off)

        XCTAssertTrue(model.isExpanded)
        XCTAssertEqual(model.selectedMode, .off)
    }

    func testExpandedPickerChangesModeAndStaysOpen() {
        let model = SpatialAudioPickerModel(isExpanded: true, selectedMode: .off)

        model.handleTap(on: .headTracked)

        XCTAssertTrue(model.isExpanded)
        XCTAssertEqual(model.selectedMode, .headTracked)
    }

    func testTappingSelectedModeCollapsesExpandedPicker() {
        let model = SpatialAudioPickerModel(isExpanded: true, selectedMode: .fixed)

        model.handleTap(on: .fixed)

        XCTAssertFalse(model.isExpanded)
        XCTAssertEqual(model.selectedMode, .fixed)
    }
}
