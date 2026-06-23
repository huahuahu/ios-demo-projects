import SwiftUI

struct CategorySummaryHeader: View {
    let loadedCount: Int
    let hasMore: Bool

    var body: some View {
        Text(summaryText)
    }

    private var summaryText: String {
        hasMore ? "Loaded \(loadedCount) categories. More pages available." : "Loaded all \(loadedCount) categories."
    }
}
