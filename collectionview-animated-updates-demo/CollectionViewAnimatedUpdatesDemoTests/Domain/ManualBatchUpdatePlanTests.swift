import XCTest
import UIKit
@testable import CollectionViewAnimatedUpdatesDemo

final class ManualBatchUpdatePlanTests: XCTestCase {
    func testPlansInsertAndDeleteWithStableIDs() {
        let itemA = DemoItem(title: "A")
        let itemB = DemoItem(title: "B")
        let itemC = DemoItem(title: "C")
        let itemD = DemoItem(title: "D")

        let plan = ManualBatchUpdatePlan.make(
            oldItems: [itemA, itemB, itemC],
            newItems: [itemA, itemC, itemD]
        )

        XCTAssertNil(plan.fallbackReason)
        XCTAssertEqual(plan.deletes, [IndexPath(item: 1, section: 0)])
        XCTAssertEqual(plan.inserts, [IndexPath(item: 2, section: 0)])
        XCTAssertTrue(plan.moves.isEmpty)
        XCTAssertTrue(plan.reloads.isEmpty)
        XCTAssertEqual(3 - plan.deletes.count + plan.inserts.count, 3)
    }

    func testPlansMoveWithOldAndNewIndexPaths() {
        let itemA = DemoItem(title: "A")
        let itemB = DemoItem(title: "B")
        let itemC = DemoItem(title: "C")

        let plan = ManualBatchUpdatePlan.make(
            oldItems: [itemA, itemB, itemC],
            newItems: [itemB, itemA, itemC]
        )

        XCTAssertNil(plan.fallbackReason)
        XCTAssertEqual(
            plan.moves,
            [
                ManualBatchUpdatePlan.Move(
                    from: IndexPath(item: 0, section: 0),
                    to: IndexPath(item: 1, section: 0)
                )
            ]
        )
    }

    func testPlansReloadForContentChangeWithoutStructuralChange() {
        let id = UUID()
        let oldItem = DemoItem(id: id, title: "Before")
        let newItem = DemoItem(id: id, title: "After")

        let plan = ManualBatchUpdatePlan.make(oldItems: [oldItem], newItems: [newItem])

        XCTAssertNil(plan.fallbackReason)
        XCTAssertEqual(plan.reloads, [IndexPath(item: 0, section: 0)])
        XCTAssertTrue(plan.deletes.isEmpty)
        XCTAssertTrue(plan.inserts.isEmpty)
        XCTAssertTrue(plan.moves.isEmpty)
    }

    func testFallsBackForDuplicateIDs() {
        let id = UUID()
        let first = DemoItem(id: id, title: "First")
        let duplicate = DemoItem(id: id, title: "Duplicate")

        let plan = ManualBatchUpdatePlan.make(oldItems: [first], newItems: [first, duplicate])

        XCTAssertEqual(plan.fallbackReason, .duplicateItemID)
        XCTAssertTrue(plan.shouldReloadData)
    }

    func testFallsBackWhenContentChangesDuringStructuralUpdate() {
        let id = UUID()
        let itemA = DemoItem(id: id, title: "Before")
        let changedA = DemoItem(id: id, title: "After")
        let itemB = DemoItem(title: "B")

        let plan = ManualBatchUpdatePlan.make(
            oldItems: [itemA, itemB],
            newItems: [itemB, changedA]
        )

        XCTAssertEqual(plan.fallbackReason, .contentChangedDuringStructuralUpdate)
        XCTAssertTrue(plan.shouldReloadData)
    }
}
