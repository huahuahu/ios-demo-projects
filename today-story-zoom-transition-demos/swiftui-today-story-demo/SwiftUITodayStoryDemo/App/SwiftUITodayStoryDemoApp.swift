import SwiftUI

@main
struct SwiftUITodayStoryDemoApp: App {
    @StateObject private var playbackStore = StoryPlaybackStore()

    var body: some Scene {
        WindowGroup {
            StoryListView()
                .environmentObject(playbackStore)
        }
    }
}
