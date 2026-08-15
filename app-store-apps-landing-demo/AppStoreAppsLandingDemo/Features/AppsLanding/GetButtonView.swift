import SwiftUI

struct GetButtonView: View {
  let appName: String
  let highContrast: Bool

  var body: some View {
    Button("获取") {}
      .buttonStyle(.bordered)
      .buttonBorderShape(.capsule)
      .tint(highContrast ? .white : .accentColor)
      .accessibilityLabel("获取 \(appName)")
  }
}
