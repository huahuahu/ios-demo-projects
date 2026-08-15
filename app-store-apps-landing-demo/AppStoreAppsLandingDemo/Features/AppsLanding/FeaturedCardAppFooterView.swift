import SwiftUI

struct FeaturedCardAppFooterView: View {
  let item: StoreAppItem

  var body: some View {
    HStack(spacing: 12) {
      AppIconTileView(item: item, size: 52)

      VStack(alignment: .leading, spacing: 2) {
        Text(item.name)
          .font(.headline)
          .foregroundStyle(.white)
        Text(item.subtitle)
          .font(.subheadline)
          .foregroundStyle(.white.opacity(0.82))
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      GetButtonView(appName: item.name, highContrast: true)
    }
  }
}
