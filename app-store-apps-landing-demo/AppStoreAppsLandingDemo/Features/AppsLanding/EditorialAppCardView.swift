import SwiftUI

struct EditorialAppCardView: View {
  let item: StoreAppItem

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack {
        item.palette.gradient
        Image(systemName: item.heroSymbol)
          .font(.system(size: 96, weight: .light))
          .foregroundStyle(.white.opacity(0.88))
          .accessibilityHidden(true)
      }
      .frame(minHeight: 180)
      .frame(maxWidth: .infinity)

      VStack(alignment: .leading, spacing: 4) {
        Text(item.eyebrow.uppercased())
          .font(.caption)
          .bold()
          .foregroundStyle(.secondary)
        Text(item.featureTitle)
          .font(.headline)
          .lineLimit(2)
        Text(item.name)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(16)
    }
    .background(.background.secondary)
    .clipShape(.rect(cornerRadius: StoreDesign.cardCornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: StoreDesign.cardCornerRadius)
        .stroke(.separator.opacity(0.45), lineWidth: 0.5)
    }
    .accessibilityElement(children: .combine)
  }
}
