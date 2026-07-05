import Foundation

enum DeleteDemoScenario: String, CaseIterable, Identifiable {
    case bindableProblem
    case persistentIDQueryFix

    var id: Self { self }

    var title: String {
        switch self {
        case .bindableProblem:
            "问题：详情页持有 @Bindable var book"
        case .persistentIDQueryFix:
            "解决：传 persistentModelID 后用 @Query 反查"
        }
    }

    var subtitle: String {
        switch self {
        case .bindableProblem:
            "后台 context 删除后，详情页仍停在原导航层级。"
        case .persistentIDQueryFix:
            "Query 结果变空后自动 dismiss，避免继续读已删除模型。"
        }
    }

    var sampleTitle: String {
        switch self {
        case .bindableProblem:
            "Bindable Problem Book"
        case .persistentIDQueryFix:
            "Persistent ID Query Book"
        }
    }

    var sampleAuthor: String {
        switch self {
        case .bindableProblem:
            "Stale Binding"
        case .persistentIDQueryFix:
            "SwiftData Query"
        }
    }

    var sampleNotes: String {
        switch self {
        case .bindableProblem:
            "Open this row, delete it from a background ModelContext, and notice the detail page does not automatically pop."
        case .persistentIDQueryFix:
            "Open this row, delete it from a background ModelContext, and the detail view dismisses when @Query returns no book."
        }
    }
}
