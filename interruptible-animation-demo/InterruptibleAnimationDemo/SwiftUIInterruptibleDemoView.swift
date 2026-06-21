import SwiftUI

struct SwiftUIInterruptibleDemoView: View {
    private let travelDistance: CGFloat = 260

    @State private var currentState: AnimationSnapState = .collapsed
    @State private var interactionStartState: AnimationSnapState = .collapsed
    @State private var interactiveProgress: CGFloat = AnimationSnapState.collapsed.targetProgress
    @State private var phase = "Ready"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SwiftUI: state-driven interruption")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Drag the card. SwiftUI does not expose UIViewPropertyAnimator, but new state changes can interrupt an in-flight animation and retarget the card.")
                    .foregroundStyle(.secondary)

                Text("\(phase)\nprogress: \(Int((AnimationProgressModel.clampedProgress(interactiveProgress) * 100).rounded()))%")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.secondarySystemGroupedBackground))

                card
                    .offset(y: offset(for: interactiveProgress))
                    .gesture(cardDrag)
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

    private var cardDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                if phase != "Scrubbing" {
                    interactionStartState = currentState
                }

                interactiveProgress = AnimationProgressModel.progress(
                    start: interactionStartState,
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
                currentState = targetState
                phase = "Animating to \(targetState.title)"
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                    interactiveProgress = targetState.targetProgress
                }
            }
    }

    private func offset(for progress: CGFloat) -> CGFloat {
        let clampedProgress = AnimationProgressModel.clampedProgress(progress)
        return travelDistance * (0.5 - clampedProgress)
    }
}
