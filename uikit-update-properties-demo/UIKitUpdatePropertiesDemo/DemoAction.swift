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
    case controllerTextOnly
    case toggleHidden
    case constraintUpdate
    case layoutOnly

    var title: String {
        switch self {
        case .controllerTextOnly:
            "Controller text only"
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
        case .controllerTextOnly:
            "Changes controllerMessage read only by UIViewController.updateProperties(). No manual layout or constraints request is made."
        case .toggleHidden:
            "Mutates isDetailHidden via updateProperties tracking. UIStackView may affect layout, but this does not create a constraints dependency unless updateConstraints reads that state."
        case .constraintUpdate:
            "Changes detailHeight. UIView.updateConstraints() reads it, and the VC also applies it to a height constraint inside updateProperties() via observation tracking — no explicit invalidation call needed."
        case .layoutOnly:
            "Changes layoutMarker (not read by updateConstraints). Explicitly calls setNeedsLayout to show manual layout requests are independent of constraints tracking."
        }
    }

    var expectation: InvalidationExpectation {
        switch self {
        case .controllerTextOnly:
            .propertiesOnly
        case .toggleHidden:
            .propertiesOnly
        case .constraintUpdate:
            .trackedConstraints
        case .layoutOnly:
            .propertiesAndLayout
        }
    }
}
