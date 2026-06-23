import SwiftUI

struct CategoryBrowserView: View {
    @State private var viewModel = CategoryBrowserViewModel()
    @State private var displayMode = CategoryDisplayMode.launchMode() ?? .grid
    @State private var searchText = ""
    @State private var selectedItem: HealthCategoryItem?

    private let columns = [
        GridItem(.adaptive(minimum: 172), spacing: 18)
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch displayMode {
                case .list:
                    listContent
                case .grid:
                    gridContent
                }
            }
            .navigationTitle("Health Categories")
            .searchable(text: $searchText, prompt: "Search categories")
            .safeAreaInset(edge: .top) {
                modePicker
            }
            .task {
                await viewModel.loadInitialPage()
            }
            .task(id: searchText) {
                try? await Task.sleep(for: .milliseconds(250))
                guard Task.isCancelled == false else { return }
                await viewModel.applySearch(searchText)
            }
            .alert("Loading failed", isPresented: errorIsVisible) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .sheet(item: $selectedItem) { item in
                CategoryDetailView(item: item)
            }
        }
    }

    private var modePicker: some View {
        Picker("Display Mode", selection: $displayMode) {
            ForEach(CategoryDisplayMode.allCases) { mode in
                Label(mode.title, systemImage: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var listContent: some View {
        List {
            Section {
                ForEach(viewModel.items) { item in
                    NavigationLink {
                        CategoryDetailView(item: item)
                    } label: {
                        CategoryListRowView(item: item)
                    }
                        .task {
                            await viewModel.loadMoreIfNeeded(currentItem: item)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(item)
                            }
                        }
                }
            } header: {
                CategorySummaryHeader(loadedCount: viewModel.items.count, hasMore: viewModel.hasMore)
            }

            loadingFooter
        }
        .listStyle(.insetGrouped)
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .center, spacing: 18) {
                ForEach(viewModel.items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        CategoryCardView(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            viewModel.delete(item)
                        }
                    }
                    .task {
                        await viewModel.loadMoreIfNeeded(currentItem: item)
                    }
                }

                loadingFooter
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .topLeading) {
            CategorySummaryPill(loadedCount: viewModel.items.count, hasMore: viewModel.hasMore)
                .padding(.horizontal, 20)
                .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var loadingFooter: some View {
        if viewModel.isLoading {
            ProgressView("Loading more categories")
                .frame(maxWidth: .infinity)
                .padding()
        } else if viewModel.items.isEmpty {
            ContentUnavailableView("No categories", systemImage: "magnifyingglass", description: Text("Try a different search."))
                .frame(maxWidth: .infinity)
                .padding()
        }
    }

    private var errorIsVisible: Binding<Bool> {
        Binding {
            viewModel.errorMessage != nil
        } set: { isVisible in
            if isVisible == false {
                viewModel.dismissError()
            }
        }
    }
}
