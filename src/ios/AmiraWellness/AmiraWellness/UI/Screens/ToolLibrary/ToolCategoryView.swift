import SwiftUI // Version: iOS SDK

// Internal imports
import ToolCategoryViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolCategoryViewModel.swift
import ToolLibrarySortOption // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryViewModel.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import ToolCard // src/ios/AmiraWellness/AmiraWellness/UI/Components/Cards/ToolCard.swift
import SearchBar // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/SearchBar.swift
import EmptyStateView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/EmptyStateView.swift
import LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift
import ErrorView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/ErrorView.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift

/// A SwiftUI view that displays tools within a specific category
struct ToolCategoryView: View {
    /// Observed object for managing the tool category data
    @ObservedObject var viewModel: ToolCategoryViewModel
    /// State variable to control the visibility of sort options
    @State private var showSortOptions: Bool = false
    /// State variable to control the visibility of filter options
    @State private var showFilterOptions: Bool = false
    /// State variable to track whether the search field is focused
    @State private var isSearchFocused: Bool = false

    /// Initializes a new ToolCategoryView with the specified view model
    /// - Parameter viewModel: The view model for the tool category
    init(viewModel: ToolCategoryViewModel) {
        self.viewModel = viewModel
        self._showSortOptions = State(initialValue: false)
        self._showFilterOptions = State(initialValue: false)
        self._isSearchFocused = State(initialValue: false)
    }

    /// Builds the view's body with navigation, search, filters, and tool list
    var body: some View {
        NavigationView {
            VStack {
                headerView()
                searchAndFilterView()
                filterOptionsView()
                sortOptionsView()

                if viewModel.isLoading {
                    loadingStateView()
                } else if let errorMessage = viewModel.errorMessage {
                    errorStateView()
                } else if viewModel.filteredTools.isEmpty {
                    emptyStateView()
                } else {
                    toolListView()
                }
            }
            .background(ColorConstants.background)
            .navigationBarHidden(true)
            .refreshable {
                viewModel.refreshData()
            }
        }
    }

    /// Creates the header section with category title and navigation
    @ViewBuilder private func headerView() -> some View {
        HStack {
            Button(action: {
                viewModel.navigateBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ColorConstants.textPrimary)
            }
            .accessibilityLabel("Back")

            Text(viewModel.category.displayName())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .padding()
    }

    /// Creates the search and filter controls section
    @ViewBuilder private func searchAndFilterView() -> some View {
        VStack {
            SearchBar(
                text: $viewModel.searchQuery,
                placeholder: "Buscar herramientas",
                isFocused: $isSearchFocused,
                onTextChange: { query in
                    viewModel.updateSearchQuery(query: query)
                }
            )
            .padding(.horizontal)

            HStack {
                Button {
                    showFilterOptions.toggle()
                } label: {
                    Label("Filtros", systemImage: "line.horizontal.3.decrease")
                }
                .padding(.horizontal)
                .accessibilityLabel("Filter tools")

                Button {
                    showSortOptions.toggle()
                } label: {
                    Label("Ordenar", systemImage: "arrow.up.arrow.down")
                }
                .padding(.horizontal)
                .accessibilityLabel("Sort tools")
            }
        }
    }

    /// Creates the filter options panel when expanded
    @ViewBuilder private func filterOptionsView() -> some View {
        if showFilterOptions {
            VStack {
                Toggle(isOn: $viewModel.showFavoritesOnly) {
                    Text("Mostrar solo favoritos")
                }
                .padding()
            }
            .transition(.move(edge: .top))
            .animation(.easeInOut, value: showFilterOptions)
        }
    }

    /// Creates the sort options panel when expanded
    @ViewBuilder private func sortOptionsView() -> some View {
        if showSortOptions {
            VStack {
                Picker("Ordenar por", selection: $viewModel.sortOption) {
                    Text("Nombre (A-Z)").tag(ToolLibrarySortOption.nameAsc)
                    Text("Nombre (Z-A)").tag(ToolLibrarySortOption.nameDesc)
                    Text("Duración (menor)").tag(ToolLibrarySortOption.durationAsc)
                    Text("Duración (mayor)").tag(ToolLibrarySortOption.durationDesc)
                    Text("Más populares").tag(ToolLibrarySortOption.popularityDesc)
                }
                .pickerStyle(.segmented)
                .padding()
            }
            .transition(.move(edge: .top))
            .animation(.easeInOut, value: showSortOptions)
        }
    }

    /// Creates the main content section with the list of tools
    @ViewBuilder private func toolListView() -> some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.filteredTools) { tool in
                    ToolCard(
                        tool: tool,
                        onTap: {
                            viewModel.navigateToToolDetail(tool: tool)
                        },
                        onFavoriteToggle: { isFavorite in
                            viewModel.toggleFavorite(tool: tool)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    /// Creates an empty state view when no tools match the criteria
    @ViewBuilder private func emptyStateView() -> some View {
        EmptyStateView(
            message: "No se encontraron herramientas en esta categoría."
        )
    }

    /// Creates a loading state view while fetching tools
    @ViewBuilder private func loadingStateView() -> some View {
        LoadingView(message: "Cargando herramientas en \(viewModel.category.displayName())...")
    }

    /// Creates an error state view when tool loading fails
    @ViewBuilder private func errorStateView() -> some View {
        ErrorView(
            message: viewModel.errorMessage ?? "Error al cargar las herramientas.",
            retryAction: {
                viewModel.loadData()
            }
        )
    }
}