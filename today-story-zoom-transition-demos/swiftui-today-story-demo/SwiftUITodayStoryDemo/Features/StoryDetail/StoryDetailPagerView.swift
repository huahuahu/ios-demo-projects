import SwiftUI

struct StoryDetailPagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStoryID: Story.ID
    @State private var scrollPositionID: Story.ID?

    let stories: [Story]
    let transitionNamespace: Namespace.ID
    let onSelectionChanged: (Story.ID) -> Void

    private var selectedStory: Story {
        stories.first(where: { $0.id == selectedStoryID }) ?? stories[0]
    }

    init(
        stories: [Story],
        initialStory: Story,
        transitionNamespace: Namespace.ID,
        onSelectionChanged: @escaping (Story.ID) -> Void
    ) {
        self.stories = stories
        self.transitionNamespace = transitionNamespace
        self.onSelectionChanged = onSelectionChanged
        _selectedStoryID = State(initialValue: initialStory.id)
        _scrollPositionID = State(initialValue: initialStory.id)
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(stories) { story in
                    StoryDetailView(story: story)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(story.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollPositionID)
        .overlay(alignment: .bottom) {
            StoryPageIndicatorView(
                stories: stories,
                selectedStoryID: selectedStoryID
            )
        }
        .background(Color(.systemBackground))
        .navigationTitle(selectedStory.eyebrow)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: selectedStoryID, in: transitionNamespace))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("关闭 Story", systemImage: "xmark", action: close)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityIdentifier("story.detail.close")
            }
        }
        .onAppear {
            onSelectionChanged(selectedStoryID)
        }
        .onChange(of: selectedStoryID) {
            onSelectionChanged(selectedStoryID)
        }
        .onChange(of: scrollPositionID) {
            guard let scrollPositionID else { return }
            selectedStoryID = scrollPositionID
        }
        .accessibilityIdentifier("story.detail.pager")
    }

    private func close() {
        dismiss()
    }
}

#Preview {
    @Previewable @Namespace var transitionNamespace

    NavigationStack {
        StoryDetailPagerView(
            stories: Story.samples,
            initialStory: Story.samples[0],
            transitionNamespace: transitionNamespace,
            onSelectionChanged: { _ in }
        )
    }
    .environmentObject(StoryPlaybackStore())
}
