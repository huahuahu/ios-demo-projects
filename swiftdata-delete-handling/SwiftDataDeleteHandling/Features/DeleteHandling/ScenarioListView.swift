import SwiftData
import SwiftUI

struct ScenarioListView: View {
    let modelContainer: ModelContainer

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .forward) private var books: [Book]
    @State private var statusMessage = "打开第一个看问题，打开第二个看推荐修复。"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("两个入口都用后台 ModelContext 删除同一本 Book。差别是详情页保存的是 model 本身，还是 persistentModelID。")
                        .foregroundStyle(.secondary)

                    Button("重置两本示例书", systemImage: "arrow.counterclockwise", action: resetDemoBooks)
                } footer: {
                    Text(statusMessage)
                }

                Section("Demo Cases") {
                    ForEach(DeleteDemoScenario.allCases) { scenario in
                        ScenarioRowView(
                            scenario: scenario,
                            book: book(for: scenario),
                            modelContainer: modelContainer
                        )
                    }
                }
            }
            .navigationTitle("SwiftData Delete")
            .task {
                seedIfNeeded()
            }
        }
    }

    private func book(for scenario: DeleteDemoScenario) -> Book? {
        books.first { $0.scenarioRawValue == scenario.rawValue }
    }

    private func seedIfNeeded() {
        guard books.isEmpty else {
            return
        }

        resetDemoBooks()
    }

    private func resetDemoBooks() {
        do {
            let insertedBooks = try BookStore.resetDemoBooks(in: modelContext)
            statusMessage = "已重置 \(insertedBooks.count) 本示例书。"
            DemoLog.interaction.info("Reset demo books: \(insertedBooks.count, privacy: .public)")
        } catch {
            statusMessage = "重置失败：\(error.localizedDescription)"
            DemoLog.interaction.error("Reset demo books failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

private struct ScenarioRowView: View {
    let scenario: DeleteDemoScenario
    let book: Book?
    let modelContainer: ModelContainer

    var body: some View {
        if let book {
            switch scenario {
            case .bindableProblem:
                NavigationLink {
                    BindableProblemDetailView(book: book, modelContainer: modelContainer)
                } label: {
                    rowContent(isAvailable: true)
                }
            case .persistentIDQueryFix:
                NavigationLink {
                    PersistentIDQueryFixDetailView(
                        bookID: book.persistentModelID,
                        modelContainer: modelContainer
                    )
                } label: {
                    rowContent(isAvailable: true)
                }
            }
        } else {
            rowContent(isAvailable: false)
        }
    }

    private func rowContent(isAvailable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(scenario.title)
                .font(.headline)

            Text(isAvailable ? scenario.subtitle : "这本示例书已经被删了，点重置重新生成。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let container = try! BookStore.makePreviewContainer()

    ScenarioListView(modelContainer: container)
        .modelContainer(container)
}
