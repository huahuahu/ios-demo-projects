import Foundation
import Observation

@MainActor
@Observable
final class CategoryBrowserViewModel {
    private let dataSource: any HealthCategoryDataProviding
    private let pageSize: Int
    private let prefetchThreshold: Int
    private var nextOffset = 0
    private var loadedQuery = ""
    private var loadGeneration = 0
    private var activeLoadCount = 0
    private var activeLoads: Set<PageLoadKey> = []
    private var deletedItemIDs: Set<HealthCategoryItem.ID> = []

    private(set) var items: [HealthCategoryItem] = []
    private(set) var isLoading = false
    private(set) var hasMore = true
    private(set) var errorMessage: String?

    init(
        dataSource: any HealthCategoryDataProviding = GeneratedHealthCategoryDataSource(),
        pageSize: Int = 80,
        prefetchThreshold: Int = 12
    ) {
        self.dataSource = dataSource
        self.pageSize = pageSize
        self.prefetchThreshold = prefetchThreshold
    }

    func loadInitialPage() async {
        guard items.isEmpty else { return }
        await loadMore()
    }

    func applySearch(_ query: String) async {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery != loadedQuery else { return }

        loadGeneration += 1
        loadedQuery = normalizedQuery
        items = []
        nextOffset = 0
        hasMore = true
        errorMessage = nil

        await loadMore()
    }

    func loadMoreIfNeeded(currentItem: HealthCategoryItem) async {
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let thresholdIndex = max(items.count - prefetchThreshold, 0)

        if index >= thresholdIndex {
            await loadMore()
        }
    }

    func delete(_ item: HealthCategoryItem) {
        deletedItemIDs.insert(item.id)
        items.removeAll { $0.id == item.id }
    }

    func dismissError() {
        errorMessage = nil
    }

    private func loadMore() async {
        guard hasMore else { return }

        let requestOffset = nextOffset
        let requestQuery = loadedQuery
        let requestGeneration = loadGeneration
        let loadKey = PageLoadKey(generation: requestGeneration, offset: requestOffset, query: requestQuery)
        guard activeLoads.insert(loadKey).inserted else { return }

        activeLoadCount += 1
        isLoading = true
        defer {
            activeLoads.remove(loadKey)
            activeLoadCount -= 1
            isLoading = activeLoadCount > 0
        }

        do {
            let page = try await dataSource.page(after: requestOffset, limit: pageSize, matching: requestQuery)
            guard requestGeneration == loadGeneration, requestQuery == loadedQuery, requestOffset == nextOffset else {
                return
            }

            items.append(contentsOf: page.items.filter { deletedItemIDs.contains($0.id) == false })
            nextOffset = page.nextOffset
            hasMore = page.hasMore
            errorMessage = nil
        } catch is CancellationError {
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PageLoadKey: Hashable {
    let generation: Int
    let offset: Int
    let query: String
}
