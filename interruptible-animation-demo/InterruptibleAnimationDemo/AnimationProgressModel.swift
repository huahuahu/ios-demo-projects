import CoreGraphics

struct AnimationProgressModel {
    private static let snapVelocityThreshold: CGFloat = 700

    static func clampedProgress(_ progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }

    static func progress(
        start: AnimationSnapState,
        translation: CGFloat,
        travelDistance: CGFloat
    ) -> CGFloat {
        progress(
            startProgress: start.targetProgress,
            translation: translation,
            travelDistance: travelDistance
        )
    }

    static func progress(
        startProgress: CGFloat,
        translation: CGFloat,
        travelDistance: CGFloat
    ) -> CGFloat {
        guard travelDistance > 0 else {
            return clampedProgress(startProgress)
        }

        let delta = -translation / travelDistance
        return clampedProgress(startProgress + delta)
    }

    static func animatorFraction(
        absoluteProgress: CGFloat,
        forwardTarget: AnimationSnapState
    ) -> CGFloat {
        switch forwardTarget {
        case .collapsed:
            return animatorFraction(
                absoluteProgress: absoluteProgress,
                startProgress: AnimationSnapState.expanded.targetProgress,
                targetProgress: AnimationSnapState.collapsed.targetProgress
            )
        case .expanded:
            return animatorFraction(
                absoluteProgress: absoluteProgress,
                startProgress: AnimationSnapState.collapsed.targetProgress,
                targetProgress: AnimationSnapState.expanded.targetProgress
            )
        }
    }

    static func animatorFraction(
        absoluteProgress: CGFloat,
        startProgress: CGFloat,
        targetProgress: CGFloat
    ) -> CGFloat {
        let start = clampedProgress(startProgress)
        let target = clampedProgress(targetProgress)
        let distance = target - start

        guard abs(distance) > .ulpOfOne else {
            return 0
        }

        return clampedProgress((clampedProgress(absoluteProgress) - start) / distance)
    }

    static func absoluteProgress(
        animatorFraction: CGFloat,
        forwardTarget: AnimationSnapState
    ) -> CGFloat {
        switch forwardTarget {
        case .collapsed:
            return absoluteProgress(
                animatorFraction: animatorFraction,
                startProgress: AnimationSnapState.expanded.targetProgress,
                targetProgress: AnimationSnapState.collapsed.targetProgress
            )
        case .expanded:
            return absoluteProgress(
                animatorFraction: animatorFraction,
                startProgress: AnimationSnapState.collapsed.targetProgress,
                targetProgress: AnimationSnapState.expanded.targetProgress
            )
        }
    }

    static func absoluteProgress(
        animatorFraction: CGFloat,
        startProgress: CGFloat,
        targetProgress: CGFloat
    ) -> CGFloat {
        let start = clampedProgress(startProgress)
        let target = clampedProgress(targetProgress)
        let fraction = clampedProgress(animatorFraction)

        return clampedProgress(start + (target - start) * fraction)
    }

    static func snapState(progress: CGFloat, velocity: CGFloat) -> AnimationSnapState {
        if velocity <= -snapVelocityThreshold {
            return .expanded
        }

        if velocity >= snapVelocityThreshold {
            return .collapsed
        }

        return clampedProgress(progress) >= 0.5 ? .expanded : .collapsed
    }
}
