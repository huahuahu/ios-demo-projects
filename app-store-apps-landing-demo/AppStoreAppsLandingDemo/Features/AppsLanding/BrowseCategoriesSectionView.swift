import SwiftUI

struct BrowseCategoriesSectionView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  let columns: [CategoryColumn]

  var body: some View {
    let visibleColumnCount = StoreDesign.visibleCategoryColumnCount(
      for: horizontalSizeClass
    )

    ScrollView(.horizontal) {
      LazyHStack(spacing: StoreDesign.pageSpacing) {
        ForEach(columns) { column in
          CategoryColumnView(column: column)
            .containerRelativeFrame(
              .horizontal,
              count: visibleColumnCount,
              span: 1,
              spacing: StoreDesign.pageSpacing
            )
        }
      }
      .scrollTargetLayout()
    }
    .contentMargins(.horizontal, StoreDesign.pageInset, for: .scrollContent)
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(
      OneColumnScrollTargetBehavior(
        visibleColumnCount: visibleColumnCount,
        spacing: StoreDesign.pageSpacing
      )
    )
    .accessibilityIdentifier("section-scroll-categories")
    .task(id: visibleColumnCount) {
      BrowseCategoriesLog.responsiveLayout(
        horizontalSizeClass: horizontalSizeClass == .regular ? "regular" : "compact",
        visibleColumnCount: visibleColumnCount,
        spacing: StoreDesign.pageSpacing
      )
    }
  }
}
