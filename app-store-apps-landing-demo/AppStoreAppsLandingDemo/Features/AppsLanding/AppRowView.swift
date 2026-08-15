import SwiftUI

struct AppRowView: View {
  let item: StoreAppItem

  var body: some View {
    HStack(spacing: 12) {
      AppIconTileView(item: item, size: 64)

      VStack(alignment: .leading, spacing: 3) {
        Text(item.name)
          .font(.headline)
          .lineLimit(1)
        Text(item.subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer(minLength: 8)

      GetButtonView(appName: item.name, highContrast: false)
    }
    .frame(minHeight: 86)
  }
}
