import SwiftUI

struct CatalogSectionView: View {
  let section: AppCatalogSection

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      CatalogSectionHeaderView(section: section)

      switch section.style {
      case .featured:
        FeaturedSectionView(section: section)
      case .editorial:
        EditorialSectionView(section: section)
      case .appList:
        GroupedAppListSectionView(section: section)
      case .categories:
        BrowseCategoriesSectionView(columns: section.categoryColumns)
      }
    }
  }
}
