import SwiftUI

struct EditorialGroupPageView: View {
  let page: AppGroupPage

  var body: some View {
    if let item = page.items.first {
      EditorialAppCardView(item: item)
    } else {
      ContentUnavailableView("暂无专题", systemImage: "rectangle.stack")
    }
  }
}
