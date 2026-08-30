import SwiftUI

struct SpatialAudioPickerLabels: View {
    let isExpanded: Bool
    let selectedMode: SpatialAudioMode
    let reduceMotion: Bool

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                ForEach(SpatialAudioMode.allCases) { mode in
                    Text(mode.title)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: SpatialAudioDesign.slotWidth)
                        .offset(
                            x: reduceMotion ? 0 : expandedLabelOffset(for: mode)
                        )
                }
            }
            .opacity(isExpanded ? 1 : 0)
            .scaleEffect(reduceMotion ? 1 : (isExpanded ? 1 : 0.82))

            VStack(spacing: 2) {
                Text("空间化立体声")
                    .font(.subheadline)

                HStack(spacing: 4) {
                    Text(selectedMode.title)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .opacity(isExpanded ? 0 : 1)
            .scaleEffect(reduceMotion ? 1 : (isExpanded ? 0.86 : 1))
        }
        .frame(
            width: SpatialAudioDesign.expandedWidth,
            height: SpatialAudioDesign.labelHeight,
            alignment: .top
        )
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : SpatialAudioDesign.labelAnimation,
            value: isExpanded
        )
        .accessibilityHidden(true)
    }

    private func expandedLabelOffset(for mode: SpatialAudioMode) -> Double {
        guard !isExpanded else { return 0 }
        return Double(1 - mode.index) * SpatialAudioDesign.slotWidth
    }
}
