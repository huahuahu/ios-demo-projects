import SwiftUI

struct CategoryColumnView: View {
  let column: CategoryColumn

  var body: some View {
    VStack(spacing: StoreDesign.pageSpacing) {
      ForEach(column.categories) { category in
        CategoryCardView(category: category)
      }
    }
  }
}
