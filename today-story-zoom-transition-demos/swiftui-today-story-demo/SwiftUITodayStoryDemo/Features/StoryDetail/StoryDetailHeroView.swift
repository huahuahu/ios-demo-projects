import SwiftUI

struct StoryDetailHeroView: View {
    @EnvironmentObject private var playbackStore: StoryPlaybackStore

    let story: Story
    let colorScheme: ColorScheme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            mediaBackground

            if story.media == .artwork {
                Image(systemName: story.symbolName)
                    .font(.system(size: 150, weight: .bold))
                    .foregroundStyle(.white.opacity(0.22))
                    .offset(x: 150, y: -110)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(story.eyebrow.uppercased())
                    .font(.headline)
                Text(story.title)
                    .font(.largeTitle)
                    .bold()
                Text(story.subtitle)
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 430, alignment: .bottomLeading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("story.detail.hero.\(story.id)")
    }

    @ViewBuilder
    private var mediaBackground: some View {
        if let player = playbackStore.player(for: story) {
            PlayerLayerView(player: player)
                .overlay {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        } else {
            StoryPalette.gradient(for: story.paletteIndex, colorScheme: colorScheme)
        }
    }
}
