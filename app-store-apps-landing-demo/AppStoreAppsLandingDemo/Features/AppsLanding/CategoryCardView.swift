import SwiftUI

struct CategoryCardView: View {
  let category: StoreCategory

  var body: some View {
    Button {
    } label: {
      ZStack(alignment: .bottomLeading) {
        category.palette.gradient

        Image(systemName: category.symbol)
          .font(.system(size: 42, weight: .semibold))
          .symbolRenderingMode(.palette)
          .foregroundStyle(.white, .white.opacity(0.68))
          .shadow(color: .black.opacity(0.14), radius: 5, y: 4)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding(16)

        Text(category.title)
          .font(.title3)
          .bold()
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .padding(14)
      }
      .frame(height: StoreDesign.categoryCardHeight)
      .clipShape(.rect(cornerRadius: StoreDesign.categoryCardCornerRadius))
      .contentShape(.rect)
    }
    .buttonStyle(CategoryCardButtonStyle())
    .accessibilityLabel("浏览\(category.title)类别")
    .accessibilityIdentifier("category-card-\(category.id)")
  }
}
