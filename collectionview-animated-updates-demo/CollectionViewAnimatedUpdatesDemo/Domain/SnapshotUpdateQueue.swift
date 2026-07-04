import Foundation

enum SnapshotUpdateCompletion: Equatable {
    case applied
    case coalesced
}

@MainActor
final class SnapshotUpdateQueue<State> {
    typealias Apply = @MainActor (State) async -> Void

    private struct Request {
        let state: State
        let onComplete: @MainActor (SnapshotUpdateCompletion) -> Void
    }

    private(set) var currentState: State
    private var pendingRequest: Request?
    private var isApplying = false

    private let apply: Apply

    private(set) var applyCount = 0

    var hasPending: Bool {
        pendingRequest != nil
    }

    var isBusy: Bool {
        isApplying
    }

    init(initialState: State, apply: @escaping Apply) {
        self.currentState = initialState
        self.apply = apply
    }

    func submit(
        _ newState: State,
        onComplete: @escaping @MainActor (SnapshotUpdateCompletion) -> Void = { _ in }
    ) {
        let coalescedRequest = pendingRequest
        pendingRequest = Request(state: newState, onComplete: onComplete)
        coalescedRequest?.onComplete(.coalesced)

        guard !isApplying else {
            return
        }

        isApplying = true

        Task { @MainActor [weak self] in
            await self?.drain()
        }
    }

    private func drain() async {
        while let nextRequest = pendingRequest {
            pendingRequest = nil
            applyCount += 1
            currentState = nextRequest.state
            await apply(nextRequest.state)
            nextRequest.onComplete(.applied)
        }

        isApplying = false
    }
}
