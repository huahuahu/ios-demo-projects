enum CategoryGroupingStrategy {
  static func columns(
    sectionID: String,
    categories: [StoreCategory],
    itemsPerColumn: Int = 2
  ) -> [CategoryColumn] {
    guard itemsPerColumn > 0 else {
      return []
    }

    return stride(from: 0, to: categories.count, by: itemsPerColumn).enumerated().map {
      columnIndex,
      startIndex in
      let endIndex = min(startIndex + itemsPerColumn, categories.count)
      return CategoryColumn(
        id: "\(sectionID)-column-\(columnIndex)",
        categories: Array(categories[startIndex..<endIndex])
      )
    }
  }
}
