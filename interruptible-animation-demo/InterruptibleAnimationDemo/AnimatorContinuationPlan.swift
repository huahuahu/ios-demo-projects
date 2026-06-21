import CoreGraphics

struct AnimatorContinuationPlan: Equatable {
    enum Action: Equatable {
        case continuePausedActiveAnimator
    }

    let action: Action
    let isReversed: Bool
    let durationFactor: CGFloat

    static func plan(
        activeForwardTarget: AnimationSnapState,
        releaseTarget: AnimationSnapState
    ) -> AnimatorContinuationPlan {
        AnimatorContinuationPlan(
            action: .continuePausedActiveAnimator,
            isReversed: releaseTarget != activeForwardTarget,
            durationFactor: 1
        )
    }
}
