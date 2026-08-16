import SwiftUI

struct FeaturedAppCardView: View {
  let item: StoreAppItem

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      item.palette.gradient

      Image(systemName: item.heroSymbol)
        .font(.system(size: 128, weight: .light))
        .foregroundStyle(.white.opacity(0.24))
        .rotationEffect(.degrees(-8))
        .offset(x: 82, y: -26)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 8) {
        Text(item.eyebrow.uppercased())
          .font(.caption)
          .bold()
          .foregroundStyle(.white.opacity(0.8))

        Text(item.featureTitle)
          .font(.title2)
          .bold()
          .foregroundStyle(.white)
          .fixedSize(horizontal: false, vertical: true)

        Spacer(minLength: 70)

        FeaturedCardAppFooterView(item: item)
      }
      .padding(20)
    }
    .frame(minHeight: 300)
    .clipShape(.rect(cornerRadius: StoreDesign.cardCornerRadius))
    .accessibilityElement(children: .contain)
  }
}
