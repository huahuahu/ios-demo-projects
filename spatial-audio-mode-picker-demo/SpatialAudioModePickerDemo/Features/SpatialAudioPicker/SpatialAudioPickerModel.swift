import Observation

@MainActor
@Observable
final class SpatialAudioPickerModel {
    private(set) var isExpanded: Bool
    private(set) var selectedMode: SpatialAudioMode

    init(
        isExpanded: Bool = false,
        selectedMode: SpatialAudioMode = .off
    ) {
        self.isExpanded = isExpanded
        self.selectedMode = selectedMode
    }

    func handleTap(on mode: SpatialAudioMode) {
        guard isExpanded else {
            isExpanded = true
            return
        }

        if selectedMode == mode {
            isExpanded = false
        } else {
            selectedMode = mode
        }
    }
}
