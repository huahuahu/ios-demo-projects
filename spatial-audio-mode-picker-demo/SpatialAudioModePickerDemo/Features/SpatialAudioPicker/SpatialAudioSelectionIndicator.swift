import SwiftUI

struct SpatialAudioSelectionIndicator: View {
    let mode: SpatialAudioMode
    let differentiateWithoutColor: Bool
    let glassNamespace: Namespace.ID

    var body: some View {
        Color.clear
            .frame(
                width: SpatialAudioDesign.indicatorDiameter,
                height: SpatialAudioDesign.indicatorDiameter
            )
            .glassEffect(.regular.tint(tint), in: .circle)
            .glassEffectID("mode-picker-selection", in: glassNamespace)
            .overlay {
                Circle()
                    .strokeBorder(
                        differentiateWithoutColor ? Color.white : Color.clear,
                        lineWidth: 2
                    )
            }
            .accessibilityHidden(true)
    }

    private var tint: Color {
        if mode.isSpatialAudioEnabled {
            .blue
        } else {
            .white.opacity(0.16)
        }
    }
}
