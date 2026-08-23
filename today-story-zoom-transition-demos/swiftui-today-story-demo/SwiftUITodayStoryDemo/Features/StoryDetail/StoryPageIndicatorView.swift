import SwiftUI

struct StoryPageIndicatorView: View {
    let stories: [Story]
    let selectedStoryID: Story.ID

    private var selectedStoryIndex: Int {
        stories.firstIndex(where: { $0.id == selectedStoryID }) ?? 0
    }

    var body: some View {
        HStack(spacing: 7) {
            ForEach(stories) { story in
                Capsule()
                    .fill(indicatorColor(for: story))
                    .frame(width: indicatorWidth(for: story), height: 7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: .capsule)
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Story \(selectedStoryIndex + 1)，共 \(stories.count) 个")
        .accessibilityIdentifier("story.detail.page-indicator")
    }

    private func indicatorColor(for story: Story) -> Color {
        story.id == selectedStoryID ? .primary : .secondary.opacity(0.45)
    }

    private func indicatorWidth(for story: Story) -> CGFloat {
        story.id == selectedStoryID ? 18 : 7
    }
}
