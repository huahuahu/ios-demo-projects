import Observation
import UIKit

@Observable
final class DemoState {
    var isDetailHidden = false
    var detailHeight: CGFloat = 140
    var statusText = "Tap an action to observe which UIKit callbacks run."

    func apply(_ action: DemoAction) {
        switch action {
        case .toggleHidden:
            isDetailHidden.toggle()
        case .constraintUpdate:
            isDetailHidden = false
            detailHeight = detailHeight == 72 ? 140 : 72
        case .layoutOnly:
            isDetailHidden = false
            detailHeight = detailHeight == 188 ? 140 : 188
        }

        statusText = action.explanation
    }
}
