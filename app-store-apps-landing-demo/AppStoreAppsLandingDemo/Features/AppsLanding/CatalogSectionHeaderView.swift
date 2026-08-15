import SwiftUI

struct CatalogSectionHeaderView: View {
  let section: AppCatalogSection

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(section.title)
        .font(.title2)
        .bold()

      if let subtitle = section.subtitle {
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, StoreDesign.pageInset)
    .accessibilityElement(children: .combine)
  }
}
