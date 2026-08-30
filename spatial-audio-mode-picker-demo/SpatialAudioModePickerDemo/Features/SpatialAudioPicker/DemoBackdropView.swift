import SwiftUI

struct DemoBackdropView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.21, blue: 0.25),
                    Color(red: 0.08, green: 0.10, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 44)
                .fill(.green.opacity(0.32))
                .frame(width: 280, height: 190)
                .blur(radius: 34)
                .offset(x: -110, y: -80)

            Circle()
                .fill(.orange.opacity(0.28))
                .frame(width: 210, height: 210)
                .blur(radius: 42)
                .offset(x: 140, y: 180)

            Rectangle()
                .fill(.black.opacity(0.24))
                .background(.ultraThinMaterial)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
