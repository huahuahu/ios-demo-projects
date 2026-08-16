import SwiftUI

struct StoreTabPlaceholderView: View {
  let tab: StoreTab

  var body: some View {
    ContentUnavailableView(
      "\(tab.title) 仅作导航示意",
      systemImage: tab.symbol,
      description: Text("本 Demo 聚焦 App 列表首页的嵌套滚动与按组吸附。")
    )
  }
}
