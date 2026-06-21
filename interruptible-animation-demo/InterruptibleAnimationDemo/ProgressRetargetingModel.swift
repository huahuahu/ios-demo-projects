import CoreGraphics
import Foundation

struct ProgressRetargetingModel {
    struct Animation: Equatable {
        let startProgress: CGFloat
        let targetState: AnimationSnapState
        let startTime: TimeInterval
        let duration: TimeInterval

        var targetProgress: CGFloat {
            targetState.targetProgress
        }
    }

    static func progress(for animation: Animation, now: TimeInterval) -> CGFloat {
        guard animation.duration > 0 else {
            return animation.targetProgress
        }

        let elapsedFraction = AnimationProgressModel.clampedProgress(
            CGFloat((now - animation.startTime) / animation.duration)
        )
        let easedFraction = elapsedFraction * elapsedFraction * (3 - 2 * elapsedFraction)
        let delta = animation.targetProgress - animation.startProgress

        return AnimationProgressModel.clampedProgress(animation.startProgress + delta * easedFraction)
    }

    static func isComplete(_ animation: Animation, now: TimeInterval) -> Bool {
        now - animation.startTime >= animation.duration
    }
}
