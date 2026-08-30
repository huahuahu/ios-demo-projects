import SwiftUI

struct ModeOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.62 : 1)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}
