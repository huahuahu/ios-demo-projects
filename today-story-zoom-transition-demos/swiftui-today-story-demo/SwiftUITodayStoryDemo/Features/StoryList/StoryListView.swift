import SwiftUI

struct StoryListView: View {
    @Namespace private var storyTransition
    @State private var visibleTransitionSourceID: Story.ID?

    private let stories = Story.samples

    var body: some View {
        ScrollViewReader { proxy in
            NavigationStack {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(stories) { story in
                            NavigationLink(value: story) {
                                StoryCardView(story: story)
                                    .matchedTransitionSource(id: story.id, in: storyTransition)
                            }
                            .buttonStyle(.plain)
                            .id(story.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Today")
                .navigationDestination(for: Story.self) { story in
                    StoryDetailPagerView(
                        stories: stories,
                        initialStory: story,
                        transitionNamespace: storyTransition,
                        onSelectionChanged: { selectedStoryID in
                            visibleTransitionSourceID = selectedStoryID
                        }
                    )
                }
                .onChange(of: visibleTransitionSourceID) {
                    guard let visibleTransitionSourceID else { return }
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        proxy.scrollTo(visibleTransitionSourceID, anchor: .center)
                    }
                }
            }
        }
    }
}

#Preview {
    StoryListView()
        .environmentObject(StoryPlaybackStore())
}
