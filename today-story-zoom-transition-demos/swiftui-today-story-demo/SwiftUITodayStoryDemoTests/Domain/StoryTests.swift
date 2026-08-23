import Testing
@testable import SwiftUITodayStoryDemo

struct StoryTests {
    @Test
    func sampleStoriesHaveStableUniqueIdentifiers() {
        let identifiers = Story.samples.map(\.id)

        #expect(identifiers.count >= 6)
        #expect(Set(identifiers).count == identifiers.count)
        #expect(identifiers == Story.samples.map(\.id))
    }
}
