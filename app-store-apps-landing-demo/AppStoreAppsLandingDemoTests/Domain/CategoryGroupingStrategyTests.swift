import Testing

@testable import AppStoreAppsLandingDemo

struct CategoryGroupingStrategyTests {
  @Test("七个类别按每列两项分为 2、2、2、1")
  func groupsTwoCardsPerColumn() {
    let categories = (0..<7).map { index in
      StoreCategory(
        id: "category-\(index)",
        title: "类别 \(index)",
        symbol: "square.fill",
        palette: .aqua
      )
    }

    let columns = CategoryGroupingStrategy.columns(
      sectionID: "test",
      categories: categories
    )

    #expect(columns.map(\.categories.count) == [2, 2, 2, 1])
  }

  @Test("类别列 ID 稳定且唯一")
  func producesStableUniqueIDs() {
    let categories = (0..<7).map { index in
      StoreCategory(
        id: "category-\(index)",
        title: "类别 \(index)",
        symbol: "square.fill",
        palette: .aqua
      )
    }
    let firstRun = CategoryGroupingStrategy.columns(
      sectionID: "stable",
      categories: categories
    )
    let secondRun = CategoryGroupingStrategy.columns(
      sectionID: "stable",
      categories: categories
    )

    #expect(firstRun.map(\.id) == secondRun.map(\.id))
    #expect(Set(firstRun.map(\.id)).count == firstRun.count)
  }
}
