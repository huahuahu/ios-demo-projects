import SwiftUI

struct SpatialAudioModePicker: View {
    let model: SpatialAudioPickerModel

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    var body: some View {
        VStack(spacing: 8) {
            SpatialAudioPickerControl(
                isExpanded: model.isExpanded,
                selectedMode: model.selectedMode,
                differentiateWithoutColor: differentiateWithoutColor,
                glassNamespace: glassNamespace,
                action: handleTap
            )

            SpatialAudioPickerLabels(
                isExpanded: model.isExpanded,
                selectedMode: model.selectedMode,
                reduceMotion: reduceMotion
            )
        }
        .animation(
            reduceMotion ? nil : SpatialAudioDesign.expansionAnimation,
            value: model.isExpanded
        )
        .animation(
            reduceMotion ? nil : SpatialAudioDesign.selectionAnimation,
            value: model.selectedMode
        )
        .sensoryFeedback(.selection, trigger: model.selectedMode)
        .symbolEffectsRemoved(reduceMotion)
    }

    private func handleTap(_ mode: SpatialAudioMode) {
        if reduceMotion {
            model.handleTap(on: mode)
        } else {
            withAnimation(
                model.isExpanded && model.selectedMode != mode
                    ? SpatialAudioDesign.selectionAnimation
                    : SpatialAudioDesign.expansionAnimation
            ) {
                model.handleTap(on: mode)
            }
        }
    }
}
