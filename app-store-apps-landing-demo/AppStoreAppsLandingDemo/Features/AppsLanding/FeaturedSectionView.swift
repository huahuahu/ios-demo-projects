import SwiftUI

struct FeaturedSectionView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  let section: AppCatalogSection

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: StoreDesign.pageSpacing) {
        ForEach(section.pages) { page in
          FeaturedGroupPageView(page: page)
            .containerRelativeFrame(
              .horizontal,
              count: StoreDesign.horizontalPageCount(for: horizontalSizeClass),
              span: 1,
              spacing: StoreDesign.pageSpacing
            )
            .accessibilityIdentifier("featured-page-\(page.id)")
        }
      }
      .scrollTargetLayout()
    }
    .contentMargins(.horizontal, StoreDesign.pageInset, for: .scrollContent)
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(.viewAligned)
    .accessibilityIdentifier("section-scroll-\(section.id)")
  }
}
