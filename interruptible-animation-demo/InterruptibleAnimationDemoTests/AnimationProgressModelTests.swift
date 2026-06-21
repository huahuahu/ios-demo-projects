import Testing
import CoreGraphics
@testable import InterruptibleAnimationDemo

struct AnimationProgressModelTests {
    @Test func clampedProgressStaysInsideUnitRange() {
        #expect(AnimationProgressModel.clampedProgress(-0.25) == 0)
        #expect(AnimationProgressModel.clampedProgress(0.4) == 0.4)
        #expect(AnimationProgressModel.clampedProgress(1.25) == 1)
    }

    @Test func collapsedDragUpIncreasesProgress() {
        let progress = AnimationProgressModel.progress(
            start: .collapsed,
            translation: -120,
            travelDistance: 240
        )

        #expect(progress == 0.5)
    }

    @Test func expandedDragDownDecreasesProgress() {
        let progress = AnimationProgressModel.progress(
            start: .expanded,
            translation: 60,
            travelDistance: 240
        )

        #expect(progress == 0.75)
    }

    @Test func invalidTravelDistanceKeepsStartStateProgress() {
        #expect(AnimationProgressModel.progress(start: .collapsed, translation: -120, travelDistance: 0) == 0)
        #expect(AnimationProgressModel.progress(start: .expanded, translation: 120, travelDistance: -1) == 1)
    }

    @Test func snapStateUsesProgressThreshold() {
        #expect(AnimationProgressModel.snapState(progress: 0.49, velocity: 0) == .collapsed)
        #expect(AnimationProgressModel.snapState(progress: 0.5, velocity: 0) == .expanded)
    }

    @Test func snapStateUsesVelocityWhenIntentIsClear() {
        #expect(AnimationProgressModel.snapState(progress: 0.2, velocity: -900) == .expanded)
        #expect(AnimationProgressModel.snapState(progress: 0.8, velocity: 900) == .collapsed)
    }
}
