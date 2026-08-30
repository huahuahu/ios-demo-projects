import SwiftUI

struct AirPodsVolumeView: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(.white.opacity(0.12))

                Capsule()
                    .fill(.white.opacity(0.94))
                    .frame(height: 116)
            }
            .frame(width: 108, height: 264)
            .glassEffect(.regular, in: .capsule)

            Label("立体声", systemImage: "waveform")
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AirPods 音量百分之四十四，立体声")
    }
}
