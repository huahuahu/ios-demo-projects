import SwiftUI

enum StoreDesign {
  static let pageInset = 20.0
  static let pageSpacing = 14.0
  static let sectionSpacing = 34.0
  static let cardCornerRadius = 24.0
  static let iconCornerRadius = 14.0
  static let listPageCornerRadius = 22.0
  static let categoryCardCornerRadius = 18.0
  static let categoryCardHeight = 108.0

  static func horizontalPageCount(for sizeClass: UserInterfaceSizeClass?) -> Int {
    sizeClass == .regular ? 2 : 1
  }

  static func visibleCategoryColumnCount(for sizeClass: UserInterfaceSizeClass?) -> Int {
    sizeClass == .regular ? 4 : 2
  }
}
