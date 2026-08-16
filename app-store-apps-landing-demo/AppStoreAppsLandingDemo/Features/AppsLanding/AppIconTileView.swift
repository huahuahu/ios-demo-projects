import SwiftUI

struct AppIconTileView: View {
  let item: StoreAppItem
  let size: Double

  var body: some View {
    ZStack {
      item.palette.gradient

      Image(systemName: item.iconSymbol)
        .font(.system(size: size * 0.42, weight: .semibold))
        .foregroundStyle(.white)
        .accessibilityHidden(true)
    }
    .frame(width: size, height: size)
    .clipShape(.rect(cornerRadius: size * 0.23))
    .overlay {
      RoundedRectangle(cornerRadius: size * 0.23)
        .stroke(.white.opacity(0.24), lineWidth: 0.75)
    }
    .accessibilityHidden(true)
  }
}
