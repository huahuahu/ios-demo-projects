import Testing
@testable import SwiftUIListGridLargeData

@MainActor
struct CategoryBrowserViewModelTests {
    @Test
    func displayModeCanBeSelectedFromLaunchArguments() {
        #expect(CategoryDisplayMode.launchMode(from: ["--display-mode", "list"]) == .list)
        #expect(CategoryDisplayMode.launchMode(from: ["--display-mode", "grid"]) == .grid)
        #expect(CategoryDisplayMode.launchMode(from: ["--display-mode", "unknown"]) == nil)
        #expect(CategoryDisplayMode.launchMode(from: []) == nil)
    }

    @Test
    func initialLoadFetchesTheFirstPage() async throws {
        let dataSource = RecordingCategoryDataSource(totalCount: 120)
        let viewModel = CategoryBrowserViewModel(dataSource: dataSource, pageSize: 40)

        await viewModel.loadInitialPage()

        #expect(viewModel.items.count == 40)
        #expect(viewModel.items.first?.title == "Activity 1")
        #expect(viewModel.items.last?.title == "Sleep 40")
        #expect(viewModel.hasMore)
        #expect(await dataSource.requests == [
            CategoryPageRequest(offset: 0, limit: 40, query: "")
        ])
    }

    @Test
    func loadMoreIfNeededPrefetchesWhenItemIsNearTheEnd() async throws {
        let dataSource = RecordingCategoryDataSource(totalCount: 95)
        let viewModel = CategoryBrowserViewModel(dataSource: dataSource, pageSize: 40, prefetchThreshold: 5)

        await viewModel.loadInitialPage()
        let triggerItem = try #require(viewModel.items.dropFirst(35).first)
        await viewModel.loadMoreIfNeeded(currentItem: triggerItem)

        #expect(viewModel.items.count == 80)
        #expect(await dataSource.requests == [
            CategoryPageRequest(offset: 0, limit: 40, query: ""),
            CategoryPageRequest(offset: 40, limit: 40, query: "")
        ])
    }

    @Test
    func loadMoreIfNeededIgnoresItemsBeforeThePrefetchThreshold() async throws {
        let dataSource = RecordingCategoryDataSource(totalCount: 95)
        let viewModel = CategoryBrowserViewModel(dataSource: dataSource, pageSize: 40, prefetchThreshold: 5)

        await viewModel.loadInitialPage()
        let earlyItem = try #require(viewModel.items.dropFirst(8).first)
        await viewModel.loadMoreIfNeeded(currentItem: earlyItem)

        #expect(viewModel.items.count == 40)
        #expect(await dataSource.requests == [
            CategoryPageRequest(offset: 0, limit: 40, query: "")
        ])
    }

    @Test
    func searchResetsLoadedItemsAndStartsFromTheFirstMatchingPage() async throws {
        let dataSource = RecordingCategoryDataSource(totalCount: 200)
        let viewModel = CategoryBrowserViewModel(dataSource: dataSource, pageSize: 20)

        await viewModel.loadInitialPage()
        await viewModel.applySearch("sleep")

        #expect(viewModel.items.count == 20)
        #expect(viewModel.items.allSatisfy { $0.title.localizedCaseInsensitiveContains("sleep") })
        #expect(await dataSource.requests == [
            CategoryPageRequest(offset: 0, limit: 20, query: ""),
            CategoryPageRequest(offset: 0, limit: 20, query: "sleep")
        ])
    }

    @Test
    func searchIgnoresStaleInFlightPageResults() async throws {
        let dataSource = SuspendedCategoryDataSource()
        let viewModel = CategoryBrowserViewModel(dataSource: dataSource, pageSize: 20)

        async let initialLoad: Void = viewModel.loadInitialPage()
        let sawInitialRequest = await dataSource.waitUntilRequestCount(is: 1)
        #expect(sawInitialRequest)

        async let searchLoad: Void = viewModel.applySearch("sleep")
        let sawSearchRequest = await dataSource.waitUntilRequestCount(is: 2)

        await dataSource.resumeRequest(query: "", totalCount: 200)
        if sawSearchRequest {
            await dataSource.resumeRequest(query: "sleep", totalCount: 200)
        }
        _ = await (initialLoad, searchLoad)

        #expect(sawSearchRequest)
        #expect(viewModel.items.count == 20)
        #expect(viewModel.items.allSatisfy { $0.title.localizedCaseInsensitiveContains("sleep") })
        #expect(await dataSource.requests == [
            CategoryPageRequest(offset: 0, limit: 20, query: ""),
            CategoryPageRequest(offset: 0, limit: 20, query: "sleep")
        ])
    }

    @Test
    func deletedItemsStayHiddenAfterSearchReloads() async throws {
        let dataSource = RecordingCategoryDataSource(totalCount: 160)
        let viewModel = CategoryBrowserViewModel(dataSource: dataSource, pageSize: 40)

        await viewModel.loadInitialPage()
        let deletedItem = try #require(viewModel.items.first)
        viewModel.delete(deletedItem)

        await viewModel.applySearch("activity")
        await viewModel.applySearch("")

        #expect(viewModel.items.contains(deletedItem) == false)
    }
}

private actor RecordingCategoryDataSource: HealthCategoryDataProviding {
    private let totalCount: Int
    private(set) var requests: [CategoryPageRequest] = []

    init(totalCount: Int) {
        self.totalCount = totalCount
    }

    func page(after offset: Int, limit: Int, matching query: String) async throws -> CategoryPage {
        requests.append(CategoryPageRequest(offset: offset, limit: limit, query: query))
        let allItems = HealthCategoryItem.generatedItems(count: totalCount)
        let filteredItems = query.isEmpty
            ? allItems
            : allItems.filter { $0.title.localizedCaseInsensitiveContains(query) }
        let pageItems = Array(filteredItems.dropFirst(offset).prefix(limit))

        return CategoryPage(
            items: pageItems,
            nextOffset: offset + pageItems.count,
            hasMore: offset + pageItems.count < filteredItems.count
        )
    }
}

private actor SuspendedCategoryDataSource: HealthCategoryDataProviding {
    private(set) var requests: [CategoryPageRequest] = []
    private var continuations: [String: [CheckedContinuation<CategoryPage, Never>]] = [:]

    func page(after offset: Int, limit: Int, matching query: String) async throws -> CategoryPage {
        requests.append(CategoryPageRequest(offset: offset, limit: limit, query: query))

        return await withCheckedContinuation { continuation in
            continuations[query, default: []].append(continuation)
        }
    }

    func waitUntilRequestCount(is expectedCount: Int) async -> Bool {
        for _ in 0..<100 {
            if requests.count >= expectedCount {
                return true
            }
            await Task.yield()
        }

        return false
    }

    func resumeRequest(query: String, totalCount: Int) {
        guard var queryContinuations = continuations[query], queryContinuations.isEmpty == false else {
            return
        }

        let continuation = queryContinuations.removeFirst()
        continuations[query] = queryContinuations
        let request = requests.first { $0.query == query } ?? CategoryPageRequest(offset: 0, limit: 20, query: query)
        let allItems = HealthCategoryItem.generatedItems(count: totalCount)
        let filteredItems = query.isEmpty
            ? allItems
            : allItems.filter { $0.title.localizedCaseInsensitiveContains(query) }
        let pageItems = Array(filteredItems.dropFirst(request.offset).prefix(request.limit))
        continuation.resume(
            returning: CategoryPage(
                items: pageItems,
                nextOffset: request.offset + pageItems.count,
                hasMore: request.offset + pageItems.count < filteredItems.count
            )
        )
    }
}
