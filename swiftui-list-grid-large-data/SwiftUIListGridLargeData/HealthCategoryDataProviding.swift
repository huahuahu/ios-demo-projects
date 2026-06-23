protocol HealthCategoryDataProviding: Sendable {
    func page(after offset: Int, limit: Int, matching query: String) async throws -> CategoryPage
}
