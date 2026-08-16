import Testing

@testable import AppStoreAppsLandingDemo

struct SampleCatalogTests {
  @Test("示例目录覆盖大卡片、三行列表与浏览类别")
  func containsMultipleSectionStyles() {
    let styles = SampleCatalog.sections.map(\.style)

    #expect(styles.contains(.featured))
    #expect(styles.contains(.editorial))
    #expect(styles.contains(.appList))
    #expect(styles.contains(.categories))
  }

  @Test("所有非类别 section 都有页面，列表页面最多三行")
  func pagesContainExpectedRows() {
    #expect(
      SampleCatalog.sections
        .filter { $0.style != .categories }
        .allSatisfy { !$0.pages.isEmpty }
    )
    #expect(
      SampleCatalog.sections
        .filter { $0.style == .appList }
        .flatMap(\.pages)
        .allSatisfy { (1...3).contains($0.items.count) }
    )
  }

  @Test("浏览类别每列包含上下两张卡")
  func categorySectionContainsTwoCardsPerColumn() throws {
    let section = try #require(
      SampleCatalog.sections.first { $0.style == .categories }
    )

    #expect(section.categoryColumns.count == 5)
    #expect(section.categoryColumns.allSatisfy { $0.categories.count == 2 })
  }
}
