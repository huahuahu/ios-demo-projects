import SwiftUI

struct CategorySummaryPill: View {
    let loadedCount: Int
    let hasMore: Bool

    var body: some View {
        Label(summaryText, systemImage: hasMore ? "arrow.down.circle" : "checkmark.circle")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
    }

    private var summaryText: String {
        hasMore ? "\(loadedCount) loaded" : "All \(loadedCount) loaded"
    }
}
