enum StoreTab: Hashable, CaseIterable {
  case today
  case games
  case apps
  case arcade
  case search

  var title: String {
    switch self {
    case .today: "Today"
    case .games: "游戏"
    case .apps: "App"
    case .arcade: "Arcade"
    case .search: "搜索"
    }
  }

  var symbol: String {
    switch self {
    case .today: "doc.text.image"
    case .games: "gamecontroller.fill"
    case .apps: "square.stack.3d.up.fill"
    case .arcade: "arcade.stick.console.fill"
    case .search: "magnifyingglass"
    }
  }
}
