import Foundation

enum StatusFormatter {
    static func makeStatusText(
        reason: String,
        mode: String,
        itemCount: Int,
        isApplying: Bool,
        hasPending: Bool,
        applyCount: Int,
        enqueueCount: Int,
        completionCount: Int,
        appliedCompletionCount: Int,
        coalescedCompletionCount: Int,
        detail: String
    ) -> String {
        "\(mode) | \(reason) | \(detail) | items: \(itemCount) | applying: \(isApplying ? "yes" : "no") | pending: \(hasPending ? "yes" : "no") | applies: \(applyCount) | enqueued: \(enqueueCount) | completions: \(completionCount) (applied: \(appliedCompletionCount), coalesced: \(coalescedCompletionCount))"
    }
}
