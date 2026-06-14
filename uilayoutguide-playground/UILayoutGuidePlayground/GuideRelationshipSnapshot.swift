import UIKit

struct GuideRelationshipSnapshot: Equatable {
    let guideIdentifier: String
    let owningViewMatchesOwner: Bool
    let ownerListsGuide: Bool
    let ownerSubviewCount: Int
    let ownerLayoutGuideCount: Int

    var summaryLines: [String] {
        [
            "guide.identifier: \(guideIdentifier)",
            "guide.owningView === owner: \(owningViewMatchesOwner)",
            "owner.layoutGuides contains guide: \(ownerListsGuide)",
            "owner.subviews.count: \(ownerSubviewCount)",
            "owner.layoutGuides.count: \(ownerLayoutGuideCount)"
        ]
    }
}

@MainActor
enum GuideRelationshipProbe {
    static func snapshot(owner: UIView, guide: UILayoutGuide) -> GuideRelationshipSnapshot {
        GuideRelationshipSnapshot(
            guideIdentifier: guide.identifier,
            owningViewMatchesOwner: guide.owningView === owner,
            ownerListsGuide: owner.layoutGuides.contains { $0 === guide },
            ownerSubviewCount: owner.subviews.count,
            ownerLayoutGuideCount: owner.layoutGuides.count
        )
    }
}
