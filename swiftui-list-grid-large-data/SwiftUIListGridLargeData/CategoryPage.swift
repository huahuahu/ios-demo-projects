struct CategoryPageRequest: Equatable, Sendable {
    let offset: Int
    let limit: Int
    let query: String
}

struct CategoryPage: Equatable, Sendable {
    let items: [HealthCategoryItem]
    let nextOffset: Int
    let hasMore: Bool
}
