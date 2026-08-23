import AVFoundation
import UIKit

@MainActor
final class StoryPlaybackStore: ObservableObject {
    private var sessions: [Story.ID: PlaybackSession] = [:]

    func player(for story: Story) -> AVQueuePlayer? {
        guard case let .loopingVideo(resource, fileExtension) = story.media else { return nil }

        if let session = sessions[story.id] {
            return session.player
        }

        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
            assertionFailure("Missing bundled video: \(resource).\(fileExtension)")
            return nil
        }

        let session = PlaybackSession(url: url)
        sessions[story.id] = session
        if UIAccessibility.isVideoAutoplayEnabled {
            session.player.play()
        }
        return session.player
    }
}

@MainActor
private final class PlaybackSession {
    let player: AVQueuePlayer
    private let looper: AVPlayerLooper

    init(url: URL) {
        let player = AVQueuePlayer()
        self.player = player
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        player.isMuted = true
        player.actionAtItemEnd = .none
    }
}
