import QuartzCore
import UIKit

enum MiniDockLayout {
    static let navigationHeight: CGFloat = 56
    static let topMargin: CGFloat = 3
    static let maximumInteritemSpacing: CGFloat = 240
    static let additionalTopInset: CGFloat = 16
    static let perspectiveCorrection: CGFloat = -1 / 1_000
    static let zOffset: CGFloat = -60
    static let maximumRotationAngle: CGFloat = -.pi / 2.2

    static func collapsedHeight(safeAreaBottom: CGFloat) -> CGFloat {
        navigationHeight + topMargin + safeAreaBottom + 3
    }

    static func interitemSpacing(
        itemCount: Int,
        boundingHeight: CGFloat,
        topInset: CGFloat
    ) -> CGFloat {
        guard itemCount > 0 else { return maximumInteritemSpacing }
        let fitted = (boundingHeight - additionalTopInset - topInset)
            / CGFloat(min(itemCount, 5))
        return min(maximumInteritemSpacing, fitted)
    }

    static func rotationAngleAtTop(itemCount: Int) -> CGFloat {
        let multiplier = min(CGFloat(itemCount), 5) - 1
        return -.pi / 7 - (.pi / 7) * multiplier / 4
    }

    static func angle(
        cardOriginY: CGFloat,
        itemCount: Int,
        viewportHeight: CGFloat,
        contentOffsetY: CGFloat,
        topInset: CGFloat
    ) -> CGFloat {
        var effectiveOffset = contentOffsetY
        if effectiveOffset < 0 {
            effectiveOffset *= 2
        }

        let yOnScreen = min(
            max(cardOriginY - effectiveOffset - additionalTopInset - topInset, 0),
            viewportHeight
        )
        let start = rotationAngleAtTop(itemCount: itemCount)
        let variance = maximumRotationAngle - start
        return start + variance / viewportHeight * yOnScreen
    }

    static func transform(angle: CGFloat, cardHeight: CGFloat) -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = perspectiveCorrection

        let safeSine = abs(sin(angle)) < 0.001 ? 0.001 : sin(angle)
        let radius = cardHeight / 2 + abs(zOffset / safeSine)
        let zTranslation = radius * sin(angle)
        let yTranslation = radius * (1 - cos(angle))

        transform = CATransform3DTranslate(
            transform,
            0,
            -yTranslation,
            zTranslation
        )
        return CATransform3DRotate(transform, angle, 1, 0, 0)
    }
}
