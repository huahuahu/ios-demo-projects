import Testing
@testable import UILayoutGuidePlayground
import UIKit

@MainActor
struct UILayoutGuidePlaygroundTests {
    @Test func addingLayoutGuideAttachesGuideWithoutAddingSubview() {
        let owner = UIView()
        let guide = UILayoutGuide()
        guide.identifier = "testGuide"

        owner.addLayoutGuide(guide)

        let snapshot = GuideRelationshipProbe.snapshot(owner: owner, guide: guide)
        #expect(snapshot.guideIdentifier == "testGuide")
        #expect(snapshot.owningViewMatchesOwner)
        #expect(snapshot.ownerListsGuide)
        #expect(snapshot.ownerSubviewCount == 0)
        #expect(snapshot.ownerLayoutGuideCount == 1)
    }

    @Test func removingLayoutGuideClearsOwningView() {
        let owner = UIView()
        let guide = UILayoutGuide()

        owner.addLayoutGuide(guide)
        owner.removeLayoutGuide(guide)

        #expect(guide.owningView == nil)
        #expect(owner.layoutGuides.isEmpty)
    }

    @Test func guideAnchorsCanDriveSubviewFrame() {
        let owner = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 240))
        let guide = UILayoutGuide()
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false

        owner.addLayoutGuide(guide)
        owner.addSubview(cardView)

        NSLayoutConstraint.activate([
            guide.leadingAnchor.constraint(equalTo: owner.leadingAnchor, constant: 20),
            guide.topAnchor.constraint(equalTo: owner.topAnchor, constant: 30),
            guide.widthAnchor.constraint(equalToConstant: 120),
            guide.heightAnchor.constraint(equalToConstant: 70),

            cardView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: guide.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])

        owner.layoutIfNeeded()

        #expect(cardView.frame == CGRect(x: 20, y: 30, width: 120, height: 70))
    }
}
