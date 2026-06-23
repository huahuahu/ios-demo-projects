struct GeneratedHealthCategoryDataSource: HealthCategoryDataProviding {
    private let allItems: [HealthCategoryItem]

    init(totalCount: Int = 5_000) {
        allItems = HealthCategoryItem.generatedItems(count: totalCount)
    }

    func page(after offset: Int, limit: Int, matching query: String) async throws -> CategoryPage {
        try Task.checkCancellation()

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredItems = normalizedQuery.isEmpty
            ? allItems
            : allItems.filter { $0.title.localizedCaseInsensitiveContains(normalizedQuery) }
        let pageItems = Array(filteredItems.dropFirst(offset).prefix(limit))

        return CategoryPage(
            items: pageItems,
            nextOffset: offset + pageItems.count,
            hasMore: offset + pageItems.count < filteredItems.count
        )
    }
}
