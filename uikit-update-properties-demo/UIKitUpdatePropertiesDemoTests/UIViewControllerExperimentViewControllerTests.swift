import UIKit
import XCTest
@testable import UIKitUpdatePropertiesDemo

final class UIViewControllerExperimentViewControllerTests: XCTestCase {
    @MainActor
    func testControllerPropertyBindingAppliesStateHeightToConstraintConstant() {
        let preview = UIView()
        let heightConstraint = preview.heightAnchor.constraint(equalToConstant: 140)

        ControllerPropertyBinding.apply(detailHeight: 72, to: heightConstraint)

        XCTAssertEqual(heightConstraint.constant, 72)
    }
}
