import UIKit

extension UICollectionViewDiffableDataSource {
    @MainActor
    func applySnapshotAndWait(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool
    ) async {
        await withCheckedContinuation { continuation in
            apply(snapshot, animatingDifferences: animatingDifferences) {
                continuation.resume()
            }
        }
    }
}
