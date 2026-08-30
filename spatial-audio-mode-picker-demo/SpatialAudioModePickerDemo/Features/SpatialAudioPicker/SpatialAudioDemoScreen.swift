import SwiftUI

struct SpatialAudioDemoScreen: View {
    @State private var model = SpatialAudioPickerModel()

    var body: some View {
        ZStack {
            DemoBackdropView()

            VStack(spacing: 22) {
                AirPodsHeaderView()

                Spacer(minLength: 8)

                AirPodsVolumeView()

                Spacer(minLength: 8)

                SpatialAudioModePicker(model: model)

                Text("点按按钮展开 · 选择其他模式 · 再次点按当前模式收起")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SpatialAudioDemoScreen()
}
