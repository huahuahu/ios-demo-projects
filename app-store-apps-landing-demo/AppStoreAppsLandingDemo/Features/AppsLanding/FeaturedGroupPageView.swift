import SwiftUI

struct FeaturedGroupPageView: View {
  let page: AppGroupPage

  var body: some View {
    if let item = page.items.first {
      FeaturedAppCardView(item: item)
    } else {
      ContentUnavailableView("暂无精选", systemImage: "sparkles")
    }
  }
}
