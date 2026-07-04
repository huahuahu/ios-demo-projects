import UIKit

extension UICollectionView {
    @MainActor
    func performBatchUpdatesAndWait(_ updates: @escaping @MainActor () -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            performBatchUpdates {
                updates()
            } completion: { finished in
                continuation.resume(returning: finished)
            }
        }
    }
}
