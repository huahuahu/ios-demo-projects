import SwiftData
import SwiftUI

struct BindableProblemDetailView: View {
    @Bindable var book: Book
    let modelContainer: ModelContainer

    @State private var deleteStatus = "还没有删除。"
    @State private var storeLookupStatus = "未检查"
    @State private var relationshipReadStatus = "尚未读取 cover relationship。"
    @State private var isDeleting = false

    private var isHoldingDeletedModel: Bool {
        book.isDeleted || book.modelContext == nil
    }

    private var didVerifyStoreDeletion: Bool {
        storeLookupStatus == "nil（store 已删除）"
    }

    var body: some View {
        Form {
            Section("这个页面故意持有 @Bindable var book") {
                Text("下面两个值来自 @Bindable 持有的旧对象实例，不是重新 fetch 的 store 状态。跨 context 删除后它们可能仍显示 false / attached，这正是问题。")
                    .foregroundStyle(.secondary)

                LabeledContent("book.isDeleted（旧实例）", value: book.isDeleted ? "true" : "false")
                LabeledContent("book.modelContext（旧实例）", value: book.modelContext == nil ? "nil" : "attached")
                LabeledContent("fresh context fetch", value: storeLookupStatus)
            }

            if isHoldingDeletedModel || didVerifyStoreDeletion {
                Section("问题已经出现") {
                    ContentUnavailableView {
                        Label("详情页仍停在这里", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("Fresh context 已经查不到这本 Book，但 @Bindable 详情页仍然没有自动退出。")
                    }
                }
            }

            Section("仍在直接绑定 SwiftData model") {
                TextField("Title", text: $book.title)
                TextField("Author", text: $book.author)
                TextEditor(text: $book.notes)
                    .frame(minHeight: 120)
            }

            Section("后台 context 操作") {
                Button(role: .destructive, action: deleteFromBackgroundContext) {
                    Label("用后台 context 删除这本书", systemImage: "trash")
                }
                .disabled(isDeleting || isHoldingDeletedModel)

                Text(deleteStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("危险操作") {
                Button(role: .destructive, action: readUnmaterializedRelationship) {
                    Label("读取旧 book.cover 关系", systemImage: "book.closed")
                }
                .disabled(didVerifyStoreDeletion == false)

                Text("先点上面的后台删除。确认 fresh context fetch 为 nil 后，再点这个按钮；它会在 @Bindable 持有的旧 Book 上读取之前没有展示过的 cover relationship。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(relationshipReadStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(role: .destructive, action: crashByReadingDeletedBookFault) {
                    Label("用已删除 ID 触发 fault crash", systemImage: "bolt.trianglebadge.exclamationmark")
                }
                .disabled(didVerifyStoreDeletion == false)

                Text("如果旧实例 relationship 在本轮运行里已经被缓存，上面的按钮可能不会崩；这个按钮会用已删除的 persistentModelID 在新 context 制造 fault，再读取属性。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Problem")
    }

    private func deleteFromBackgroundContext() {
        let bookID = book.persistentModelID
        isDeleting = true
        deleteStatus = "后台 context 正在删除..."

        Task { @MainActor in
            defer { isDeleting = false }

            do {
                let didDelete = try await BackgroundBookDeleter(modelContainer: modelContainer)
                    .delete(bookID: bookID)
                let freshContext = ModelContext(modelContainer)
                let existsInStore = try BookStore.containsBook(with: bookID, in: freshContext)
                storeLookupStatus = existsInStore ? "仍能 fetch 到" : "nil（store 已删除）"
                deleteStatus = didDelete
                    ? "后台 context 已删除并保存；注意这个详情页仍然没有自动 pop。"
                    : "后台 context 没找到这本书。"
                DemoLog.interaction.info("Problem detail background delete completed: \(didDelete, privacy: .public)")
            } catch {
                deleteStatus = "删除失败：\(error.localizedDescription)"
                DemoLog.interaction.error("Problem detail background delete failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func readUnmaterializedRelationship() {
        DemoLog.interaction.info("About to read stale Book.cover relationship")
        let coverCaption = book.cover?.caption ?? "nil"
        relationshipReadStatus = "读取完成：book.cover?.caption = \(coverCaption)。如果没有崩，说明这个 relationship 在当前实例上已经被缓存或返回 nil。"
    }

    private func crashByReadingDeletedBookFault() {
        let bookID = book.persistentModelID
        let faultingContext = ModelContext(modelContainer)
        let deletedBookFault = faultingContext.model(for: bookID) as! Book

        DemoLog.interaction.info("About to read a deleted SwiftData Book fault: \(String(describing: bookID), privacy: .public)")
        _ = deletedBookFault.title
    }
}
