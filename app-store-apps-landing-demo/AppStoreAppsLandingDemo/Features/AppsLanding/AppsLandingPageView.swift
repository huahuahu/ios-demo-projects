import SwiftUI

struct AppsLandingPageView: View {
  let sections: [AppCatalogSection]

  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(spacing: StoreDesign.sectionSpacing) {
        ForEach(sections) { section in
          CatalogSectionView(section: section)
        }
      }
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("App")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("账户", systemImage: "person.crop.circle") {}
          .labelStyle(.iconOnly)
          .font(.title2)
          .frame(minWidth: 44, minHeight: 44)
      }
    }
    .accessibilityIdentifier("apps-landing-vertical-scroll")
  }
}
