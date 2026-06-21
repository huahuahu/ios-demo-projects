import Testing
import CoreGraphics
@testable import InterruptibleAnimationDemo

struct ProgressRetargetingModelTests {
    @Test func dragCanRestartFromDisplayedMidFlightProgressInsteadOfEndpointState() {
        let progress = AnimationProgressModel.progress(
            startProgress: 0.4,
            translation: -26,
            travelDistance: 260
        )

        #expect(progress == 0.5)
    }

    @Test func expandedToCollapsedAnimatorUsesInverseLocalFraction() {
        let localFraction = AnimationProgressModel.animatorFraction(
            absoluteProgress: 0.75,
            forwardTarget: .collapsed
        )

        #expect(localFraction == 0.25)
        #expect(AnimationProgressModel.absoluteProgress(animatorFraction: localFraction, forwardTarget: .collapsed) == 0.75)
    }

    @Test func animatorFractionCanStartFromDisplayedMidFlightProgressWithoutJumping() {
        let localFraction = AnimationProgressModel.animatorFraction(
            absoluteProgress: 0.4,
            startProgress: 0.4,
            targetProgress: 1
        )

        #expect(localFraction == 0)
        #expect(
            AnimationProgressModel.absoluteProgress(
                animatorFraction: localFraction,
                startProgress: 0.4,
                targetProgress: 1
            ) == 0.4
        )
    }

    @Test func retargetingAnimationReportsDisplayedProgressBeforeEndpoint() {
        let animation = ProgressRetargetingModel.Animation(
            startProgress: 0.25,
            targetState: .expanded,
            startTime: 10,
            duration: 1
        )

        let progress = ProgressRetargetingModel.progress(for: animation, now: 10.5)

        #expect(progress > 0.25)
        #expect(progress < 1)
    }

    @Test func retargetingAnimationClampsToTargetAfterDuration() {
        let animation = ProgressRetargetingModel.Animation(
            startProgress: 0.75,
            targetState: .collapsed,
            startTime: 10,
            duration: 1
        )

        #expect(ProgressRetargetingModel.progress(for: animation, now: 12) == 0)
    }
}
