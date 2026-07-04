import XCTest
@testable import CollectionViewAnimatedUpdatesDemo

@MainActor
final class SnapshotUpdateQueueTests: XCTestCase {
    func testSubmitAppliesImmediatelyWhenIdle() async {
        var appliedStates: [Int] = []
        var completions: [SnapshotUpdateCompletion] = []
        let completionExpectation = expectation(description: "First submit completes")

        let queue = SnapshotUpdateQueue<Int>(initialState: 0) { state in
            appliedStates.append(state)
        }

        queue.submit(1, onComplete: { result in
            completions.append(result)
            completionExpectation.fulfill()
        })

        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertEqual(appliedStates, [1])
        XCTAssertEqual(completions, [.applied])
        XCTAssertEqual(queue.currentState, 1)
        XCTAssertEqual(queue.applyCount, 1)
        XCTAssertFalse(queue.isBusy)
        XCTAssertFalse(queue.hasPending)
    }

    func testSubmitKeepsOnlyLatestPendingStateWhileCompletingEverySubmit() async {
        var appliedStates: [Int] = []
        var completionsByState: [(state: Int, result: SnapshotUpdateCompletion)] = []
        var finishFirstApply: CheckedContinuation<Void, Never>?
        let firstApplyStarted = expectation(description: "First apply starts")
        let completionExpectation = expectation(description: "Every submit completes")
        completionExpectation.expectedFulfillmentCount = 3

        let queue = SnapshotUpdateQueue<Int>(initialState: 0) { state in
            appliedStates.append(state)

            if state == 1 {
                firstApplyStarted.fulfill()
                await withCheckedContinuation { continuation in
                    finishFirstApply = continuation
                }
            }
        }

        queue.submit(1, onComplete: { result in
            completionsByState.append((1, result))
            completionExpectation.fulfill()
        })

        await fulfillment(of: [firstApplyStarted], timeout: 1.0)

        queue.submit(2, onComplete: { result in
            completionsByState.append((2, result))
            completionExpectation.fulfill()
        })
        queue.submit(3, onComplete: { result in
            completionsByState.append((3, result))
            completionExpectation.fulfill()
        })

        XCTAssertTrue(queue.isBusy)
        XCTAssertTrue(queue.hasPending)
        XCTAssertEqual(appliedStates, [1])
        XCTAssertEqual(completionsByState.map(\.state), [2])
        XCTAssertEqual(completionsByState.map(\.result), [.coalesced])

        finishFirstApply?.resume()

        await fulfillment(of: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(appliedStates, [1, 3])
        XCTAssertEqual(completionsByState.map(\.state), [2, 1, 3])
        XCTAssertEqual(completionsByState.map(\.result), [.coalesced, .applied, .applied])
        XCTAssertEqual(queue.currentState, 3)
        XCTAssertEqual(queue.applyCount, 2)
        XCTAssertFalse(queue.isBusy)
        XCTAssertFalse(queue.hasPending)
    }

    func testManySubmitsCompleteOnceEachEvenWhenMostAreCoalesced() async {
        var appliedStates: [Int] = []
        var completions: [SnapshotUpdateCompletion] = []
        var finishFirstApply: CheckedContinuation<Void, Never>?
        let firstApplyStarted = expectation(description: "First apply starts")
        let completionExpectation = expectation(description: "Every submit completes")
        completionExpectation.expectedFulfillmentCount = 15

        let queue = SnapshotUpdateQueue<Int>(initialState: 0) { state in
            appliedStates.append(state)

            if state == 1 {
                firstApplyStarted.fulfill()
                await withCheckedContinuation { continuation in
                    finishFirstApply = continuation
                }
            }
        }

        queue.submit(1, onComplete: { result in
            completions.append(result)
            completionExpectation.fulfill()
        })

        await fulfillment(of: [firstApplyStarted], timeout: 1.0)

        for state in 2...15 {
            queue.submit(state, onComplete: { result in
                completions.append(result)
                completionExpectation.fulfill()
            })
        }

        finishFirstApply?.resume()

        await fulfillment(of: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(completions.count, 15)
        XCTAssertEqual(completions.filter { $0 == .coalesced }.count, 13)
        XCTAssertEqual(completions.filter { $0 == .applied }.count, 2)
        XCTAssertEqual(appliedStates, [1, 15])
        XCTAssertEqual(queue.currentState, 15)
    }
}
