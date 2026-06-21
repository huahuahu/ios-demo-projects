import SwiftUI

struct SwiftUIInterruptibleDemoView: View {
    private let travelDistance: CGFloat = 260
    private let animationDuration: TimeInterval = 0.65

    @State private var interactionStartProgress: CGFloat = AnimationSnapState.collapsed.targetProgress
    @State private var interactiveProgress: CGFloat = AnimationSnapState.collapsed.targetProgress
    @State private var activeAnimation: ProgressRetargetingModel.Animation?
    @State private var isScrubbing = false
    @State private var phase = "Ready"

    var body: some View {
        TimelineView(.animation) { timeline in
            let displayedProgress = displayedProgress(at: timeline.date)

            content(
                displayedProgress: displayedProgress,
                phaseText: phaseText(at: timeline.date)
            )
        }
    }

    private func content(displayedProgress: CGFloat, phaseText: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SwiftUI: state-driven interruption")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Drag the card. SwiftUI does not expose UIViewPropertyAnimator, but a displayed progress source can retarget an in-flight animation without jumping.")
                    .foregroundStyle(.secondary)

                Text("\(phaseText)\nprogress: \(Int((AnimationProgressModel.clampedProgress(displayedProgress) * 100).rounded()))%")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.secondarySystemGroupedBackground))

                card
                    .offset(y: offset(for: displayedProgress))
                    .gesture(cardDrag(displayedProgress: displayedProgress))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drag me")
                .font(.title3)
                .fontWeight(.semibold)

            Text("gesture state → target state → animated retarget")
                .font(.body)
                .opacity(0.86)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 150)
        .background(Color.purple.gradient, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
        .padding(.horizontal, 24)
    }

    private func cardDrag(displayedProgress: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isScrubbing {
                    interactionStartProgress = displayedProgress
                    activeAnimation = nil
                    isScrubbing = true
                }

                interactiveProgress = AnimationProgressModel.progress(
                    startProgress: interactionStartProgress,
                    translation: value.translation.height,
                    travelDistance: travelDistance
                )
                phase = "Scrubbing"
            }
            .onEnded { value in
                let targetState = AnimationProgressModel.snapState(
                    progress: interactiveProgress,
                    velocity: value.velocity.height
                )
                phase = "Animating to \(targetState.title)"
                isScrubbing = false

                let animation = ProgressRetargetingModel.Animation(
                    startProgress: interactiveProgress,
                    targetState: targetState,
                    startTime: Date().timeIntervalSinceReferenceDate,
                    duration: animationDuration
                )
                activeAnimation = animation

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(animationDuration))

                    if activeAnimation == animation {
                        interactiveProgress = animation.targetProgress
                        activeAnimation = nil
                        phase = "Completed: \(animation.targetState.title)"
                    }
                }
            }
    }

    private func displayedProgress(at date: Date) -> CGFloat {
        if isScrubbing {
            return interactiveProgress
        }

        guard let activeAnimation else {
            return interactiveProgress
        }

        return ProgressRetargetingModel.progress(
            for: activeAnimation,
            now: date.timeIntervalSinceReferenceDate
        )
    }

    private func phaseText(at date: Date) -> String {
        guard let activeAnimation, !isScrubbing else {
            return phase
        }

        if ProgressRetargetingModel.isComplete(
            activeAnimation,
            now: date.timeIntervalSinceReferenceDate
        ) {
            return "Completed: \(activeAnimation.targetState.title)"
        }

        return phase
    }

    private func offset(for progress: CGFloat) -> CGFloat {
        let clampedProgress = AnimationProgressModel.clampedProgress(progress)
        return travelDistance * (0.5 - clampedProgress)
    }
}
