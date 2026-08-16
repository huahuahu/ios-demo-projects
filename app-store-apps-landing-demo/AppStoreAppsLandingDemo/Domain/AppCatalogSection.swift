struct AppCatalogSection: Identifiable, Sendable {
  let id: String
  let title: String
  let subtitle: String?
  let content: CatalogSectionContent

  var style: CatalogSectionStyle {
    content.style
  }

  var pages: [AppGroupPage] {
    content.pages
  }

  var categoryColumns: [CategoryColumn] {
    content.categoryColumns
  }
}
