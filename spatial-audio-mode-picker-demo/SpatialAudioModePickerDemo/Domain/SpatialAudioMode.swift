enum SpatialAudioMode: String, CaseIterable, Identifiable, Sendable {
    case off
    case fixed
    case headTracked

    var id: Self { self }

    var index: Int {
        switch self {
        case .off:
            0
        case .fixed:
            1
        case .headTracked:
            2
        }
    }

    var title: String {
        switch self {
        case .off:
            "关闭"
        case .fixed:
            "固定"
        case .headTracked:
            "头部跟踪"
        }
    }

    var systemImage: String {
        switch self {
        case .off:
            "person.fill"
        case .fixed:
            "person.spatialaudio.stereo.fill"
        case .headTracked:
            "person.wave.2.fill"
        }
    }

    var isSpatialAudioEnabled: Bool {
        self != .off
    }
}
