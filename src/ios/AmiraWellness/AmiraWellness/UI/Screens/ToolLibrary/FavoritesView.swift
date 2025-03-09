import SwiftUI // Version: iOS SDK
import Combine // Version: Latest - Reactive programming for handling asynchronous events

// Internal imports
import FavoritesViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/FavoritesViewModel.swift - Provides the business logic and state management for the favorites screen
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift - Core data model for tools in the library
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift - Enumeration of tool categories for filtering
import ToolCard // src/ios/AmiraWellness/AmiraWellness/UI/Components/Cards/ToolCard.swift - Reusable card component for displaying tool information
import SearchBar // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/SearchBar.swift - Reusable search component for filtering tools
import EmptyStateView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/EmptyStateView.swift - Displays a message when no favorites are available
import ToolDetailView // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolDetailView.swift - View for displaying detailed tool information
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift - Color constants for consistent styling

/// A SwiftUI view that displays the user's favorite tools from the tool library
struct FavoritesView: View {
    
    /// Observed object for managing the favorites screen state
    @StateObject var viewModel: FavoritesViewModel
    
    /// State variable to control the visibility of the sort options
    @State private var showSortOptions: Bool = false
    
    /// State variable to control the visibility of the category filter
    @State private var showCategoryFilter: Bool = false
    
    /// State variable to control the navigation to the tool detail view
    @State private var showToolDetail: Bool = false
    
    /// State variable to store the ID of the selected tool for detail view
    @State private var selectedToolId: String? = nil
    
    /// State variable to track whether the search field is focused
    @State private var isSearchFocused: Bool = false
    
    /// Initializes a new FavoritesView with an optional view model
    /// - Parameter viewModel: An optional FavoritesViewModel instance. If nil, a new one will be created.
    init(viewModel: FavoritesViewModel? = nil) {
        // Initialize viewModel as a StateObject with the provided viewModel or create a new one
        _viewModel = StateObject(wrappedValue: viewModel ?? FavoritesViewModel())
        
        // Initialize showSortOptions to false
        _showSortOptions = State(initialValue: false)
        
        // Initialize showCategoryFilter to false
        _showCategoryFilter = State(initialValue: false)
        
        // Initialize showToolDetail to false
        _showToolDetail = State(initialValue: false)
        
        // Initialize selectedToolId to nil
        _selectedToolId = State(initialValue: nil)
        
        // Initialize isSearchFocused to false
        _isSearchFocused = State(initialValue: false)
    }
    
    /// Builds the view's body with the favorites UI
    /// - Returns: The composed view hierarchy
    var body: some View {
        NavigationView {
            ZStack {
                // Add a ZStack to layer the content
                
                // Add a background color using ColorConstants.background
                ColorConstants.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Add a VStack containing the main content
                    
                    // Include a header section with title and filter options
                    headerView()
                    
                    // Include a search bar for filtering tools by name
                    searchBarView()
                    
                    // Include a category filter section if showCategoryFilter is true
                    if showCategoryFilter {
                        categoryFilterView()
                    }
                    
                    // Include a sort options section if showSortOptions is true
                    if showSortOptions {
                        sortOptionsView()
                    }
                    
                    // Include a ScrollView with the list of favorite tools
                    ScrollView {
                        // If viewModel.filteredTools is empty, show EmptyStateView
                        if viewModel.filteredTools.isEmpty {
                            emptyStateView()
                        } else {
                            // Otherwise, show a LazyVStack with ToolCard for each tool
                            LazyVStack {
                                ForEach(viewModel.filteredTools, id: \\.id) { tool in
                                    ToolCard(
                                        tool: tool,
                                        onTap: {
                                            // Configure onTap to select the tool for detail view
                                            selectedToolId = tool.id.uuidString
                                            viewModel.navigateToToolDetail(tool: tool)
                                            showToolDetail = true
                                        },
                                        onFavoriteToggle: { isFavorite in
                                            // Configure onFavoriteToggle to call viewModel.toggleFavorite
                                            viewModel.toggleFavorite(tool: tool)
                                        }
                                    )
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                    }
                    .refreshable {
                        // Add a RefreshControl for pull-to-refresh functionality
                        viewModel.refreshData()
                    }
                    
                    // Add a NavigationLink to ToolDetailView when a tool is selected
                    NavigationLink(
                        destination: ToolDetailView(toolId: selectedToolId ?? ""),
                        isActive: $showToolDetail,
                        label: { EmptyView() }
                    )
                    .hidden()
                }
                .padding()
            }
            // Add error alert when viewModel.errorMessage is not nil
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "Ocurri\u00f3 un error inesperado."),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Add onAppear lifecycle hook to load data
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    /// Creates the header section with title and filter options
    /// - Returns: The header view
    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            // Create an HStack for the header content
            
            Text("Mis Favoritos")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            Spacer()
            
            Button {
                // Add a filter button that toggles showCategoryFilter
                showCategoryFilter.toggle()
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(ColorConstants.textPrimary)
            }
            
            Button {
                // Add a sort button that toggles showSortOptions
                showSortOptions.toggle()
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .foregroundColor(ColorConstants.textPrimary)
            }
        }
    }
    
    /// Creates a search bar for filtering tools by name
    /// - Returns: The search bar view
    @ViewBuilder
    private func searchBarView() -> some View {
        SearchBar(
            text: $viewModel.searchQuery,
            isFocused: $isSearchFocused,
            onTextChange: { query in
                // Configure onTextChange to call viewModel.updateSearchQuery
                viewModel.updateSearchQuery(query: query)
            }
        )
        .padding(.vertical, 8)
    }
    
    /// Creates a view for filtering tools by category
    /// - Returns: The category filter view
    @ViewBuilder
    private func categoryFilterView() -> some View {
        VStack(alignment: .leading) {
            // Create a VStack for the category filter content
            
            Text("Filtrar por categor\u00eda")
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                // Add a ScrollView with horizontal scroll direction
                
                HStack {
                    // Add an HStack containing category filter chips
                    
                    categoryChip(category: nil, isSelected: viewModel.selectedCategory == nil, count: viewModel.getCategoryCount(category: nil))
                        .onTapGesture {
                            // Configure each chip to call viewModel.selectCategory when tapped
                            viewModel.selectCategory(category: nil)
                        }
                    
                    ForEach(ToolCategory.allCases, id: \\.self) { category in
                        categoryChip(category: category, isSelected: viewModel.selectedCategory == category, count: viewModel.getCategoryCount(category: category))
                            .onTapGesture {
                                // Configure each chip to call viewModel.selectCategory when tapped
                                viewModel.selectCategory(category: category)
                            }
                    }
                }
            }
        }
    }
    
    /// Creates a view for sorting tools by different criteria
    /// - Returns: The sort options view
    @ViewBuilder
    private func sortOptionsView() -> some View {
        VStack(alignment: .leading) {
            // Create a VStack for the sort options content
            
            Text("Ordenar por")
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
            
            ForEach(FavoritesSortOption.allCases, id: \\.self) { option in
                // For each option, create a button that sets the sort option
                sortOptionRow(option: option, isSelected: viewModel.sortOption == option)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Configure each button to call viewModel.setSortOption when tapped
                        viewModel.setSortOption(option: option)
                    }
            }
        }
    }
    
    /// Creates a view displaying the list of favorite tools
    /// - Returns: The tools list view
    @ViewBuilder
    private func toolsListView() -> some View {
        ScrollView {
            // Create a ScrollView for vertical scrolling
            
            LazyVStack {
                // Add a LazyVStack for efficient rendering of tool cards
                
                ForEach(viewModel.filteredTools, id: \\.id) { tool in
                    ToolCard(
                        tool: tool,
                        onTap: {
                            // Configure onTap to select the tool for detail view
                            selectedToolId = tool.id.uuidString
                            showToolDetail = true
                        },
                        onFavoriteToggle: { isFavorite in
                            // Configure onFavoriteToggle to call viewModel.toggleFavorite
                            viewModel.toggleFavorite(tool: tool)
                        }
                    )
                    .padding(.bottom, 8)
                }
            }
        }
        .refreshable {
            // Add a RefreshControl for pull-to-refresh functionality
            viewModel.refreshData()
        }
    }
    
    /// Creates a view displayed when no favorite tools are available
    /// - Returns: The empty state view
    @ViewBuilder
    private func emptyStateView() -> some View {
        EmptyStateView(
            message: viewModel.favoriteTools.isEmpty ?
            "A\u00f1ade herramientas a tus favoritos para verlas aqu\u00ed." :
                "No se encontraron herramientas con los filtros seleccionados."
            ,
            buttonTitle: viewModel.selectedCategory != nil || !viewModel.searchQuery.isEmpty ? "Borrar filtros" : nil,
            buttonAction: {
                viewModel.selectCategory(category: nil)
                viewModel.updateSearchQuery(query: "")
            }
        )
    }
    
    /// Creates a chip view for category filtering
    /// - Parameters:
    ///   - category: The category to display
    ///   - isSelected: Whether the category is currently selected
    /// - Returns: The category chip view
    @ViewBuilder
    private func categoryChip(category: ToolCategory?, isSelected: Bool, count: Int) -> some View {
        HStack {
            // Create an HStack for the chip content
            
            if let category = category {
                // If category is not nil, add an icon using category.iconName()
                Image(systemName: category.iconName())
            }
            
            // Add the category name (or 'All' if category is nil)
            Text((category?.displayName() ?? "Todas") + " (\(count))")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? ColorConstants.primary : Color.clear)
        .foregroundColor(isSelected ? .white : ColorConstants.textPrimary)
        .font(.subheadline)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorConstants.border, lineWidth: 1)
        )
    }
    
    /// Creates a row view for a sort option
    /// - Parameters:
    ///   - option: The sort option to display
    ///   - isSelected: Whether the option is currently selected
    /// - Returns: The sort option row view
    @ViewBuilder
    private func sortOptionRow(option: FavoritesSortOption, isSelected: Bool) -> some View {
        HStack {
            // Create an HStack for the row content
            
            Text(option.displayName())
            
            Spacer()
            
            if isSelected {
                // Add a checkmark icon if isSelected is true
                Image(systemName: "checkmark")
            }
        }
        .padding(.vertical, 8)
    }
}