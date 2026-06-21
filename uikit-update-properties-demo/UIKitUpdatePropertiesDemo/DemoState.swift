import Observation
import UIKit

@Observable
final class DemoState {
    var isDetailHidden = false
    var detailHeight: CGFloat = 140
    /// Incremented by layoutOnly action; not read by updateConstraints, so it does not create a constraints dependency.
    var layoutMarker: Int = 0
    var controllerMessage = "Controller title is normal"
    var statusText = "Tap an action to observe which UIKit callbacks run."

    func apply(_ action: DemoAction) {
        switch action {
        case .controllerTextOnly:
            controllerMessage = controllerMessage == "Controller title is normal"
                ? "Controller text changed by state only"
                : "Controller title is normal"
        case .toggleHidden:
            isDetailHidden.toggle()
        case .constraintUpdate:
            isDetailHidden = false
            detailHeight = detailHeight == 72 ? 140 : 72
        case .layoutOnly:
            layoutMarker += 1
        }

        statusText = action.explanation
    }
}
