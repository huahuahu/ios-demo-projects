import Testing

@testable import AppStoreAppsLandingDemo

struct GroupingStrategyTests {
  @Test("七个 App 按每组三行分为 3、3、1")
  func groupsThreeRowsPerPage() {
    let pages = GroupingStrategy.pages(
      sectionID: "test",
      items: Array(SampleCatalog.sections[1].pages.flatMap(\.items).prefix(7)),
      pageSize: 3
    )

    #expect(pages.map(\.items.count) == [3, 3, 1])
  }

  @Test("分组 ID 稳定且唯一")
  func producesStableUniqueIDs() {
    let items = Array(SampleCatalog.sections[1].pages.flatMap(\.items).prefix(7))
    let firstRun = GroupingStrategy.pages(sectionID: "stable", items: items, pageSize: 3)
    let secondRun = GroupingStrategy.pages(sectionID: "stable", items: items, pageSize: 3)

    #expect(firstRun.map(\.id) == secondRun.map(\.id))
    #expect(Set(firstRun.map(\.id)).count == firstRun.count)
  }

  @Test("无效的每页数量返回空数组")
  func rejectsInvalidPageSize() {
    let items = SampleCatalog.sections[0].pages.flatMap(\.items)

    #expect(GroupingStrategy.pages(sectionID: "invalid", items: items, pageSize: 0).isEmpty)
  }
}
