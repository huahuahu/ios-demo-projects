import Testing
@testable import InterruptibleAnimationDemo

struct AnimatorContinuationPlanTests {
    @Test func continuingTowardForwardTargetReusesPausedAnimatorWithNonZeroDuration() {
        let plan = AnimatorContinuationPlan.plan(
            activeForwardTarget: .expanded,
            releaseTarget: .expanded
        )

        #expect(plan.action == .continuePausedActiveAnimator)
        #expect(plan.isReversed == false)
        #expect(plan.durationFactor > 0)
    }

    @Test func continuingOppositeForwardTargetReversesSamePausedAnimator() {
        let plan = AnimatorContinuationPlan.plan(
            activeForwardTarget: .expanded,
            releaseTarget: .collapsed
        )

        #expect(plan.action == .continuePausedActiveAnimator)
        #expect(plan.isReversed)
        #expect(plan.durationFactor > 0)
    }
}
