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
        guard travelDistance > 0 else {
            return start.targetProgress
        }

        let delta = -translation / travelDistance
        return clampedProgress(start.targetProgress + delta)
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
