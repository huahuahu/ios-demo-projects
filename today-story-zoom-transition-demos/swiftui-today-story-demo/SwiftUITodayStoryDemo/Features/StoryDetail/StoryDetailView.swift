import SwiftUI

struct StoryDetailView: View {
    @Environment(\.colorScheme) private var colorScheme

    let story: Story

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                StoryDetailHeroView(story: story, colorScheme: colorScheme)

                ForEach(StoryDetailSection.samples) { section in
                    StoryDetailSectionView(section: section)
                }
            }
            .padding(.bottom, 48)
        }
        .accessibilityIdentifier("story.detail.scroll.\(story.id)")
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        StoryDetailView(story: Story.samples[0])
    }
    .environmentObject(StoryPlaybackStore())
}
