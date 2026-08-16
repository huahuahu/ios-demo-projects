import SwiftUI

struct StoreTabContainerView: View {
  @State private var selectedTab = StoreTab.apps

  var body: some View {
    TabView(selection: $selectedTab) {
      ForEach(StoreTab.allCases, id: \.self) { tab in
        Tab(tab.title, systemImage: tab.symbol, value: tab) {
          if tab == .apps {
            NavigationStack {
              AppsLandingPageView(sections: SampleCatalog.sections)
            }
          } else {
            StoreTabPlaceholderView(tab: tab)
          }
        }
      }
    }
    .tabViewStyle(.sidebarAdaptable)
  }
}
