import SwiftUI

struct SpatialAudioModeButton: View {
    let mode: SpatialAudioMode
    let isExpanded: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(mode.title, systemImage: mode.systemImage)
                .labelStyle(.iconOnly)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce.byLayer, value: isSelected)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(ModeOptionButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("mode-option-\(mode.rawValue)")
        .accessibilityHidden(!isExpanded && !isSelected)
    }

    private var accessibilityLabel: String {
        if isExpanded {
            mode.title
        } else {
            "空间化立体声，当前\(mode.title)"
        }
    }

    private var accessibilityHint: String {
        if isExpanded && isSelected {
            "再次点按收起模式选择器"
        } else if isExpanded {
            "切换到\(mode.title)"
        } else {
            "点按展开模式选择器"
        }
    }
}
