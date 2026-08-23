import SwiftUI

struct StoryCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var playbackStore: StoryPlaybackStore

    let story: Story

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            mediaBackground

            if story.media == .artwork {
                Image(systemName: story.symbolName)
                    .font(.system(size: 116, weight: .bold))
                    .foregroundStyle(.white.opacity(0.22))
                    .rotationEffect(.degrees(-8))
                    .offset(x: 96, y: -72)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(story.eyebrow.uppercased())
                    .font(.subheadline)
                    .bold()
                Text(story.title)
                    .font(.largeTitle)
                    .bold()
                Text(story.subtitle)
                    .font(.body)
            }
            .foregroundStyle(.white)
            .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .bottomLeading)
        .clipShape(.rect(cornerRadius: 28))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.18), radius: 18, y: 9)
        .contentShape(.rect(cornerRadius: 28))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(story.eyebrow)，\(story.title)，\(story.subtitle)")
        .accessibilityHint("打开 Story 详情")
        .accessibilityIdentifier("story.card.\(story.id)")
    }

    @ViewBuilder
    private var mediaBackground: some View {
        if let player = playbackStore.player(for: story) {
            PlayerLayerView(player: player)
                .overlay {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        } else {
            StoryPalette.gradient(for: story.paletteIndex, colorScheme: colorScheme)
        }
    }
}

#Preview {
    StoryCardView(story: Story.samples[0])
        .environmentObject(StoryPlaybackStore())
        .padding()
}
