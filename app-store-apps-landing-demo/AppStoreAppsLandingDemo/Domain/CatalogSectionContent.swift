enum CatalogSectionContent: Sendable {
  case featured([AppGroupPage])
  case editorial([AppGroupPage])
  case appList([AppGroupPage])
  case categories([CategoryColumn])

  var style: CatalogSectionStyle {
    switch self {
    case .featured: .featured
    case .editorial: .editorial
    case .appList: .appList
    case .categories: .categories
    }
  }

  var pages: [AppGroupPage] {
    switch self {
    case .featured(let pages), .editorial(let pages), .appList(let pages):
      pages
    case .categories:
      []
    }
  }

  var categoryColumns: [CategoryColumn] {
    switch self {
    case .categories(let columns):
      columns
    case .featured, .editorial, .appList:
      []
    }
  }
}
