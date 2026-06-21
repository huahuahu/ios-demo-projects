import Foundation

enum InvalidationExpectation: Equatable {
    case propertiesOnly
    case propertiesAndConstraints
    case propertiesAndLayout
}

enum DemoAction: CaseIterable, Equatable {
    case toggleHidden
    case constraintUpdate
    case layoutOnly

    var title: String {
        switch self {
        case .toggleHidden:
            "Toggle hidden"
        case .constraintUpdate:
            "Constraint update"
        case .layoutOnly:
            "Layout only"
        }
    }

    var explanation: String {
        switch self {
        case .toggleHidden:
            "Changes hidden state through updateProperties. This does not promise updateConstraints."
        case .constraintUpdate:
            "Changes height state and explicitly calls setNeedsUpdateConstraints."
        case .layoutOnly:
            "Changes height state and explicitly calls setNeedsLayout without requesting constraints."
        }
    }

    var expectation: InvalidationExpectation {
        switch self {
        case .toggleHidden:
            .propertiesOnly
        case .constraintUpdate:
            .propertiesAndConstraints
        case .layoutOnly:
            .propertiesAndLayout
        }
    }
}
