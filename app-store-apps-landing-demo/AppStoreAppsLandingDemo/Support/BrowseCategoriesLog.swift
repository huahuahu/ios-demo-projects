import OSLog

enum BrowseCategoriesLog {
  nonisolated static let subsystem = "com.huahuahu.demo.AppStoreAppsLandingDemo"

  private nonisolated static let logger = Logger(
    subsystem: subsystem,
    category: "BrowseCategories"
  )

  nonisolated static func responsiveLayout(
    horizontalSizeClass: String,
    visibleColumnCount: Int,
    spacing: Double
  ) {
    logger.info(
      """
      [宽度自适应] sizeClass=\(horizontalSizeClass, privacy: .public), \
      visibleColumnCount=\(visibleColumnCount, privacy: .public), \
      spacing=\(spacing, privacy: .public). \
      containerRelativeFrame 会把横向滚动容器的可用宽度扣除列间距后等分；\
      compact 一屏 2 列，regular 一屏 4 列。
      """
    )
  }

  nonisolated static func scrollAlignment(
    startingX: Double,
    naturalTargetX: Double,
    finalTargetX: Double,
    velocityX: Double,
    containerWidth: Double,
    visibleColumnCount: Int,
    spacing: Double,
    columnWidth: Double,
    oneColumnDistance: Double,
    maximumOffset: Double
  ) {
    let naturalDistance = naturalTargetX - startingX
    let finalDistance = finalTargetX - startingX
    let didLimitToOneColumn = abs(naturalDistance) > abs(finalDistance) + 0.5

    logger.info(
      """
      [横向对齐] startingX=\(startingX, privacy: .public), \
      naturalTargetX=\(naturalTargetX, privacy: .public), \
      finalTargetX=\(finalTargetX, privacy: .public), \
      naturalDistance=\(naturalDistance, privacy: .public), \
      finalDistance=\(finalDistance, privacy: .public), \
      velocityX=\(velocityX, privacy: .public), \
      didLimitToOneColumn=\(didLimitToOneColumn, privacy: .public). \
      columnWidth=(\(containerWidth, privacy: .public) - \
      (\(visibleColumnCount, privacy: .public) - 1) * \
      \(spacing, privacy: .public)) / \
      \(visibleColumnCount, privacy: .public) = \
      \(columnWidth, privacy: .public); \
      oneColumnDistance=columnWidth+spacing=\(oneColumnDistance, privacy: .public), \
      maximumOffset=\(maximumOffset, privacy: .public).
      """
    )
  }
}
