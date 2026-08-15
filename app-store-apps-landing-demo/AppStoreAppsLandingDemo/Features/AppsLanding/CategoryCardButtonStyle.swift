import SwiftUI

struct CategoryCardButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .opacity(configuration.isPressed ? 0.9 : 1)
      .animation(.smooth(duration: 0.16), value: configuration.isPressed)
  }
}
