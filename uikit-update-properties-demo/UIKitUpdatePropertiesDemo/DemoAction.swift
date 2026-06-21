import Foundation

enum InvalidationExpectation: Equatable {
    /// Only updateProperties re-runs via observation tracking.
    case propertiesOnly
    /// updateConstraints re-runs automatically because it reads an observable property that changed.
    case trackedConstraints
    /// Explicit setNeedsLayout() is called; constraints tracking is unaffected.
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
            "Mutates isDetailHidden via updateProperties tracking. UIStackView may affect layout, but this does not create a constraints dependency unless updateConstraints reads that state."
        case .constraintUpdate:
            "Changes detailHeight. updateConstraints() reads detailHeight, so it re-runs automatically via observation tracking — no explicit invalidation call needed."
        case .layoutOnly:
            "Changes layoutMarker (not read by updateConstraints). Explicitly calls setNeedsLayout to show manual layout requests are independent of constraints tracking."
        }
    }

    var expectation: InvalidationExpectation {
        switch self {
        case .toggleHidden:
            .propertiesOnly
        case .constraintUpdate:
            .trackedConstraints
        case .layoutOnly:
            .propertiesAndLayout
        }
    }
}
