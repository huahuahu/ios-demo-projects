enum GroupingStrategy {
  static func pages(
    sectionID: String,
    items: [StoreAppItem],
    pageSize: Int
  ) -> [AppGroupPage] {
    guard pageSize > 0 else {
      return []
    }

    return stride(from: 0, to: items.count, by: pageSize).enumerated().map {
      pageIndex,
      startIndex in
      let endIndex = min(startIndex + pageSize, items.count)
      return AppGroupPage(
        id: "\(sectionID)-page-\(pageIndex)",
        items: Array(items[startIndex..<endIndex])
      )
    }
  }
}
