import Testing

@testable import AppStoreAppsLandingDemo

struct OneColumnScrollTargetBehaviorTests {
  @Test(
    "快速向后甩动最多前进一列",
    .bug("https://openradar.appspot.com/FB16443192")
  )
  func limitsFastForwardFlingToOneColumn() {
    let destination = OneColumnScrollTargetBehavior.destination(
      originalOffset: 120,
      proposedOffset: 840,
      columnDistance: 120,
      maximumOffset: 960
    )

    #expect(destination == 240)
  }

  @Test("快速向前甩动最多返回一列")
  func limitsFastBackwardFlingToOneColumn() {
    let destination = OneColumnScrollTargetBehavior.destination(
      originalOffset: 360,
      proposedOffset: -240,
      columnDistance: 120,
      maximumOffset: 960
    )

    #expect(destination == 240)
  }

  @Test("不足三分之一列的短拖动回到当前列")
  func keepsCurrentColumnForShortDrag() {
    let destination = OneColumnScrollTargetBehavior.destination(
      originalOffset: 240,
      proposedOffset: 270,
      columnDistance: 120,
      maximumOffset: 960
    )

    #expect(destination == 240)
  }

  @Test("首尾甩动不会越过内容边界")
  func clampsToContentBoundaries() {
    let leadingDestination = OneColumnScrollTargetBehavior.destination(
      originalOffset: 0,
      proposedOffset: -600,
      columnDistance: 120,
      maximumOffset: 960
    )
    let trailingDestination = OneColumnScrollTargetBehavior.destination(
      originalOffset: 960,
      proposedOffset: 1_600,
      columnDistance: 120,
      maximumOffset: 960
    )

    #expect(leadingDestination == 0)
    #expect(trailingDestination == 960)
  }

  @Test("内容不足一屏时保持在起点")
  func keepsOriginWhenContentDoesNotScroll() {
    let destination = OneColumnScrollTargetBehavior.destination(
      originalOffset: 0,
      proposedOffset: 200,
      columnDistance: 120,
      maximumOffset: 0
    )

    #expect(destination == 0)
  }
}
