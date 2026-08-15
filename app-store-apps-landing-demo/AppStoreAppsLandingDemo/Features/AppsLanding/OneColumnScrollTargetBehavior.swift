import SwiftUI

struct OneColumnScrollTargetBehavior: ScrollTargetBehavior {
  let visibleColumnCount: Int
  let spacing: CGFloat

  func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
    let startingX = context.originalTarget.rect.minX
    let naturalTargetX = target.rect.minX

    // LazyHStack 上的 scrollTargetLayout() 已把“上下两张卡组成的一列”注册成 target。
    // 先交给系统选择最近的列，并要求它的 leading 与滚动容器的 leading 对齐。
    ViewAlignedScrollTargetBehavior(
      limitBehavior: .alwaysByOne,
      anchor: .leading
    )
    .updateTarget(&target, context: context)

    let proposedDelta = target.rect.minX - startingX
    guard abs(proposedDelta) > 0.5 else {
      return
    }

    let safeVisibleColumnCount = max(visibleColumnCount, 1)
    let gapCount = safeVisibleColumnCount - 1
    let totalGapWidth = CGFloat(gapCount) * spacing

    // containerSize 是 ScrollView 当前真实可用宽度。用同一个可见列数和 spacing
    // 反推 containerRelativeFrame 分配给每列的宽度，因此无需读取屏幕尺寸。
    let columnWidth =
      (context.containerSize.width - totalGapWidth) / CGFloat(safeVisibleColumnCount)
    let oneColumnDistance = columnWidth + spacing
    let clampedDelta = min(abs(proposedDelta), oneColumnDistance)
    let finalTargetX =
      startingX + clampedDelta * (proposedDelta > 0 ? 1 : -1)

    // 即便惯性目标跨过多列，最终 target 相对手势起点也最多只移动“一列 + 一个间距”。
    target.rect.origin.x = finalTargetX
    target.anchor = .leading

    BrowseCategoriesLog.scrollAlignment(
      startingX: startingX,
      naturalTargetX: naturalTargetX,
      alignedTargetX: startingX + proposedDelta,
      velocityX: context.velocity.dx,
      containerWidth: context.containerSize.width,
      visibleColumnCount: safeVisibleColumnCount,
      spacing: spacing,
      columnWidth: columnWidth,
      oneColumnDistance: oneColumnDistance,
      finalTargetX: finalTargetX,
      didClamp: abs(proposedDelta) > oneColumnDistance
    )
  }
}
