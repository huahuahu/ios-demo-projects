import UIKit

struct ManualBatchUpdatePlan: Equatable {
    enum FallbackReason: Equatable {
        case duplicateItemID
        case invalidCountEquation
        case contentChangedDuringStructuralUpdate
    }

    struct Move: Equatable {
        let from: IndexPath
        let to: IndexPath
    }

    let deletes: [IndexPath]
    let inserts: [IndexPath]
    let moves: [Move]
    let reloads: [IndexPath]
    let fallbackReason: FallbackReason?

    var shouldReloadData: Bool {
        fallbackReason != nil
    }

    var isNoOp: Bool {
        deletes.isEmpty && inserts.isEmpty && moves.isEmpty && reloads.isEmpty && fallbackReason == nil
    }

    var summary: String {
        if let fallbackReason {
            return "manual fallback: \(fallbackReason.label)"
        }

        return "manual batch d:\(deletes.count) i:\(inserts.count) m:\(moves.count) r:\(reloads.count)"
    }

    static func make(oldItems: [DemoItem], newItems: [DemoItem], section: Int = 0) -> ManualBatchUpdatePlan {
        guard hasUniqueIDs(oldItems), hasUniqueIDs(newItems) else {
            return fallback(.duplicateItemID)
        }

        let oldIDs = oldItems.map(\.id)
        let newIDs = newItems.map(\.id)
        let difference = newIDs.difference(from: oldIDs).inferringMoves()

        var deletes: [IndexPath] = []
        var inserts: [IndexPath] = []
        var moves: [Move] = []

        for change in difference {
            switch change {
            case let .remove(offset, _, associatedWith):
                if associatedWith == nil {
                    deletes.append(IndexPath(item: offset, section: section))
                }

            case let .insert(offset, _, associatedWith):
                if let oldOffset = associatedWith {
                    moves.append(
                        Move(
                            from: IndexPath(item: oldOffset, section: section),
                            to: IndexPath(item: offset, section: section)
                        )
                    )
                } else {
                    inserts.append(IndexPath(item: offset, section: section))
                }
            }
        }

        deletes.sort { $0.item > $1.item }
        inserts.sort { $0.item < $1.item }
        moves.sort {
            if $0.from.item == $1.from.item {
                return $0.to.item < $1.to.item
            }

            return $0.from.item < $1.from.item
        }

        guard oldItems.count - deletes.count + inserts.count == newItems.count else {
            return fallback(.invalidCountEquation)
        }

        let oldItemByID = Dictionary(uniqueKeysWithValues: oldItems.map { ($0.id, $0) })
        let contentChangedIDs = Set<DemoItem.ID>(
            newItems.compactMap { newItem -> DemoItem.ID? in
                guard let oldItem = oldItemByID[newItem.id], oldItem != newItem else {
                    return nil
                }

                return newItem.id
            }
        )

        if !contentChangedIDs.isEmpty && (!deletes.isEmpty || !inserts.isEmpty || !moves.isEmpty) {
            return fallback(.contentChangedDuringStructuralUpdate)
        }

        let reloads = newItems.enumerated().compactMap { index, newItem -> IndexPath? in
            contentChangedIDs.contains(newItem.id) ? IndexPath(item: index, section: section) : nil
        }

        return ManualBatchUpdatePlan(
            deletes: deletes,
            inserts: inserts,
            moves: moves,
            reloads: reloads,
            fallbackReason: nil
        )
    }

    private static func fallback(_ reason: FallbackReason) -> ManualBatchUpdatePlan {
        ManualBatchUpdatePlan(
            deletes: [],
            inserts: [],
            moves: [],
            reloads: [],
            fallbackReason: reason
        )
    }

    private static func hasUniqueIDs(_ items: [DemoItem]) -> Bool {
        Set(items.map(\.id)).count == items.count
    }
}

private extension ManualBatchUpdatePlan.FallbackReason {
    var label: String {
        switch self {
        case .duplicateItemID:
            "duplicate id"
        case .invalidCountEquation:
            "invalid count equation"
        case .contentChangedDuringStructuralUpdate:
            "content changed during structural update"
        }
    }
}
