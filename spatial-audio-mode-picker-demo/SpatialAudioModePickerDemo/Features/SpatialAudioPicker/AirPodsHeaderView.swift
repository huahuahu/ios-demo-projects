import SwiftUI

struct AirPodsHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "airpods.max")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)

            Text("已连接的 AirPods")
                .font(.headline)
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}
