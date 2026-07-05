import SwiftData
import SwiftUI

struct PersistentIDQueryFixDetailView: View {
    let bookID: PersistentIdentifier
    let modelContainer: ModelContainer

    @Environment(\.dismiss) private var dismiss
    @Query private var books: [Book]
    @State private var deleteStatus = "还没有删除。"
    @State private var isDeleting = false

    private var book: Book? {
        books.first
    }

    init(bookID: PersistentIdentifier, modelContainer: ModelContainer) {
        self.bookID = bookID
        self.modelContainer = modelContainer
        _books = Query(filter: #Predicate<Book> { book in
            book.persistentModelID == bookID
        })
    }

    var body: some View {
        Form {
            Section("这个页面只接收 persistentModelID") {
                Text("详情页用 @Query 根据 persistentModelID 反查 Book。后台删除保存后，Query 变空，页面自动 dismiss。")
                    .foregroundStyle(.secondary)

                LabeledContent("persistentModelID", value: String(describing: bookID))
                    .textSelection(.enabled)
            }

            if let book {
                Section("Query 查到的 Book") {
                    LabeledContent("Title", value: book.title)
                    LabeledContent("Author", value: book.author)
                    Text(book.notes)
                        .foregroundStyle(.secondary)
                }

                Section("后台 context 操作") {
                    Button(role: .destructive, action: deleteFromBackgroundContext) {
                        Label("用后台 context 删除这本书", systemImage: "trash")
                    }
                    .disabled(isDeleting)

                    Text(deleteStatus)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Query 已经变空") {
                    ContentUnavailableView {
                        Label("Book 已删除", systemImage: "checkmark.circle")
                    } description: {
                        Text("books.first == nil，正在 dismiss。")
                    }
                }
            }
        }
        .navigationTitle("Solution")
        .onChange(of: books.isEmpty) { _, isEmpty in
            if isEmpty {
                dismiss()
            }
        }
        .task(id: books.isEmpty) {
            if books.isEmpty {
                dismiss()
            }
        }
    }

    private func deleteFromBackgroundContext() {
        isDeleting = true
        deleteStatus = "后台 context 正在删除..."

        Task { @MainActor in
            defer { isDeleting = false }

            do {
                let didDelete = try await BackgroundBookDeleter(modelContainer: modelContainer)
                    .delete(bookID: bookID)
                deleteStatus = didDelete
                    ? "后台 context 已删除并保存；@Query 变空后会自动 dismiss。"
                    : "后台 context 没找到这本书。"
                DemoLog.interaction.info("Solution detail background delete completed: \(didDelete, privacy: .public)")
            } catch {
                deleteStatus = "删除失败：\(error.localizedDescription)"
                DemoLog.interaction.error("Solution detail background delete failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
