import SwiftUI

struct OneColumnScrollTargetBehavior: ScrollTargetBehavior {
  let visibleColumnCount: Int
  let spacing: CGFloat

  func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
    guard context.axes.contains(.horizontal) else {
      return
    }

    let safeVisibleColumnCount = max(visibleColumnCount, 1)
    let totalGapWidth = CGFloat(safeVisibleColumnCount - 1) * spacing

    // 这里复用 containerRelativeFrame 的同一套尺寸公式：容器可用宽度先扣除
    // 同屏列之间的间距，再平均分给每一列。这样 compact 的两列与 regular
    // 的四列都会得到真实列宽，不需要读取 UIScreen 或写死设备尺寸。
    let availableColumnWidth = max(context.containerSize.width - totalGapWidth, 0)
    let columnWidth = availableColumnWidth / CGFloat(safeVisibleColumnCount)
    let oneColumnDistance = columnWidth + spacing

    let startingX = context.originalTarget.rect.minX
    let naturalTargetX = target.rect.minX
    let maximumOffset = max(context.contentSize.width - context.containerSize.width, 0)

    // naturalTargetX 是系统结合拖动距离和惯性预测出的自然终点，快速甩动时可能
    // 跨过多列。最终位置始终从 originalTarget 出发计算，因此一次交互最多只会
    // 前进或后退 oneColumnDistance。1/3 列的阈值与文章中的分页策略一致。
    let finalTargetX = Self.destination(
      originalOffset: startingX,
      proposedOffset: naturalTargetX,
      columnDistance: oneColumnDistance,
      maximumOffset: maximumOffset
    )

    // 自定义行为直接覆盖系统预测终点，避免依赖 alwaysByOne 当前并不稳定的限制。
    // leading anchor 与 scrollTargetLayout 注册的 CategoryColumnView 左边缘保持一致。
    target.rect.origin.x = finalTargetX
    target.anchor = .leading

    BrowseCategoriesLog.scrollAlignment(
      startingX: startingX,
      naturalTargetX: naturalTargetX,
      finalTargetX: finalTargetX,
      velocityX: context.velocity.dx,
      containerWidth: context.containerSize.width,
      visibleColumnCount: safeVisibleColumnCount,
      spacing: spacing,
      columnWidth: columnWidth,
      oneColumnDistance: oneColumnDistance,
      maximumOffset: maximumOffset
    )
  }

  /// 根据系统预测终点决定本次手势最终停靠的位置。
  ///
  /// 算法有三个约束：短拖动回到当前列；有效拖动最多移动一列；首尾位置不能越界。
  /// 把这部分保留为纯计算函数，方便用单元测试覆盖快速甩动和边界情况。
  static func destination(
    originalOffset: CGFloat,
    proposedOffset: CGFloat,
    columnDistance: CGFloat,
    maximumOffset: CGFloat
  ) -> CGFloat {
    guard columnDistance > 0, maximumOffset > 0 else {
      return 0
    }

    let boundedOriginalOffset = min(max(originalOffset, 0), maximumOffset)

    // originalTarget 理论上已经位于列边界。round 可以在尺寸变化或浮点误差
    // 导致轻微偏移时，把它重新吸附到最近的一列；首尾仍以真实边界为准。
    let currentColumn = (boundedOriginalOffset / columnDistance).rounded()
    let alignedOriginalOffset = min(
      max(currentColumn * columnDistance, 0),
      maximumOffset
    )

    let proposedDistance = proposedOffset - originalOffset
    guard abs(proposedDistance) > 0.5 else {
      return alignedOriginalOffset
    }

    let remainingDistance =
      proposedDistance > 0
      ? maximumOffset - alignedOriginalOffset
      : alignedOriginalOffset
    let availableStep = min(columnDistance, remainingDistance)

    // 使用一列距离的 1/3 作为翻列阈值；接近首尾时改用剩余距离的 1/3，
    // 这样最后不足一整列的内容也能自然贴合边界。
    let threshold = availableStep / 3
    guard abs(proposedDistance) > threshold else {
      return alignedOriginalOffset
    }

    let destination =
      alignedOriginalOffset + (proposedDistance > 0 ? availableStep : -availableStep)
    return min(max(destination, 0), maximumOffset)
  }
}
