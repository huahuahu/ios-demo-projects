import SwiftUI

extension AppPalette {
  var colors: [Color] {
    switch self {
    case .aqua: [.cyan, .blue]
    case .coral: [.orange, .pink]
    case .indigo: [.indigo, .blue]
    case .mint: [.mint, .teal]
    case .orange: [.yellow, .orange]
    case .pink: [.pink, .purple]
    case .violet: [.purple, .indigo]
    }
  }

  var gradient: LinearGradient {
    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}
