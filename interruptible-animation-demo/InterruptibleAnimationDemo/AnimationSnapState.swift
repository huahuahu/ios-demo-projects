import CoreGraphics

enum AnimationSnapState: CaseIterable, Equatable {
    case collapsed
    case expanded

    var title: String {
        switch self {
        case .collapsed:
            "Collapsed"
        case .expanded:
            "Expanded"
        }
    }

    var targetProgress: CGFloat {
        switch self {
        case .collapsed:
            0
        case .expanded:
            1
        }
    }
}
