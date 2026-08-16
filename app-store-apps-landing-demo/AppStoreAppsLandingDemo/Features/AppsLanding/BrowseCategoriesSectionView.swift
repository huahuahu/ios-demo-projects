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
            // 一列是横向滚动的最小逻辑单位。containerRelativeFrame 根据当前
            // ScrollView 的可用宽度自动算列宽：compact 同屏 2 列，regular 4 列。
            .containerRelativeFrame(
              .horizontal,
              count: visibleColumnCount,
              span: 1,
              spacing: StoreDesign.pageSpacing
            )
        }
      }
      // 直接子 View 是 CategoryColumnView，因此每个 scroll target 是“一列”，
      // 而不是单张类别卡，也不是当前屏幕里同时可见的两列或四列。
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
