import SwiftUI

struct SpatialAudioPickerControl: View {
    let isExpanded: Bool
    let selectedMode: SpatialAudioMode
    let differentiateWithoutColor: Bool
    let glassNamespace: Namespace.ID
    let action: (SpatialAudioMode) -> Void

    var body: some View {
        ZStack {
            GlassEffectContainer(spacing: 8) {
                ZStack {
                    Color.clear
                        .frame(
                            width: isExpanded
                                ? SpatialAudioDesign.expandedWidth
                                : SpatialAudioDesign.compactDiameter,
                            height: SpatialAudioDesign.controlHeight
                        )
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .glassEffectID("mode-picker-shell", in: glassNamespace)

                    SpatialAudioSelectionIndicator(
                        mode: selectedMode,
                        differentiateWithoutColor: differentiateWithoutColor,
                        glassNamespace: glassNamespace
                    )
                    .offset(x: selectionOffset)
                }
                .frame(
                    width: SpatialAudioDesign.expandedWidth,
                    height: SpatialAudioDesign.controlHeight
                )
            }

            HStack(spacing: 0) {
                ForEach(SpatialAudioMode.allCases) { mode in
                    ZStack {
                        if isExpanded || selectedMode == mode {
                            SpatialAudioModeButton(
                                mode: mode,
                                isExpanded: isExpanded,
                                isSelected: selectedMode == mode,
                                action: { action(mode) }
                            )
                            .offset(x: optionOffset(for: mode))
                            .transition(optionTransition(for: mode))
                        }
                    }
                    .frame(
                        width: SpatialAudioDesign.slotWidth,
                        height: SpatialAudioDesign.controlHeight
                    )
                }
            }
            .zIndex(1)
        }
        .frame(
            width: SpatialAudioDesign.expandedWidth,
            height: SpatialAudioDesign.controlHeight
        )
    }

    private var selectionOffset: Double {
        guard isExpanded else { return 0 }
        return Double(selectedMode.index - 1) * SpatialAudioDesign.slotWidth
    }

    private func optionOffset(for mode: SpatialAudioMode) -> Double {
        guard !isExpanded else { return 0 }
        return Double(1 - mode.index) * SpatialAudioDesign.slotWidth
    }

    private func optionTransition(for mode: SpatialAudioMode) -> AnyTransition {
        .offset(
            x: Double(1 - mode.index) * SpatialAudioDesign.slotWidth,
            y: 0
        )
        .combined(with: .scale(scale: 0.72))
        .combined(with: .opacity)
    }
}
