import SwiftUI

struct AppGroupPageView: View {
  let page: AppGroupPage

  var body: some View {
    VStack(spacing: 0) {
      ForEach(page.items.enumerated(), id: \.element.id) { index, item in
        if index > 0 {
          Divider()
            .padding(.leading, 82)
        }

        AppRowView(item: item)
      }
    }
    .padding(.horizontal, 14)
    .background(.background.secondary)
    .clipShape(.rect(cornerRadius: StoreDesign.listPageCornerRadius))
  }
}
