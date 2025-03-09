import SwiftUI // Version: iOS SDK

// Internal imports
import ToolLibraryViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryViewModel.swift
import FilterOption // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryViewModel.swift
import SortOption // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryViewModel.swift
import ToolCard // src/ios/AmiraWellness/AmiraWellness/UI/Components/Cards/ToolCard.swift
import SearchBar // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/SearchBar.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import EmotionColors // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift

/// A SwiftUI view that displays the Tool Library screen
struct ToolLibraryView: View {
    // MARK: - Properties

    /// Observed object for the Tool Library view model
    @ObservedObject var viewModel: ToolLibraryViewModel

    /// State variable for showing the filter action sheet
    @State private var showingFilterSheet: Bool = false

    /// State variable for showing the sort action sheet
    @State private var showingSortSheet: Bool = false

    /// State variable for showing the emotion filter action sheet
    @State private var showingEmotionFilterSheet: Bool = false

    /// State variable for tracking the scroll offset
    @State private var scrollOffset: CGFloat = 0

    /// Namespace for animations
    @Namespace private var animation

    // MARK: - Initialization

    /// Initializes the ToolLibraryView with a view model
    /// - Parameter viewModel: The view model for the Tool Library screen
    init(viewModel: ToolLibraryViewModel) {
        // Store the provided viewModel
        self.viewModel = viewModel
        // Initialize showingFilterSheet as false
        self.showingFilterSheet = false
        // Initialize showingSortSheet as false
        self.showingSortSheet = false
        // Initialize showingEmotionFilterSheet as false
        self.showingEmotionFilterSheet = false
        // Initialize scrollOffset as 0
        self.scrollOffset = 0
    }

    // MARK: - Body

    /// Builds the main view for the Tool Library screen
    /// - Returns: The composed Tool Library view
    var body: some View {
        NavigationView { // Create a NavigationView as the root container
            ZStack { // Inside the NavigationView, create a ZStack for layering content
                ColorConstants.background.ignoresSafeArea() // Add a background color using ColorConstants.background

                VStack { // Add a VStack for the main content
                    headerView // Add a header section with title and filter buttons

                    searchBarView // Add a SearchBar for filtering tools

                    categoriesScrollView // Add a ScrollView for the categories section
                    
                    emotionFilterView // Add a ScrollView for the emotion filters

                    if !viewModel.recommendedTools.isEmpty { // Add a section for recommended tools if available
                        recommendedToolsSection
                    }

                    if viewModel.showingFavorites { // Add a section for favorite tools if showingFavorites is true
                        favoriteToolsSection
                    }

                    toolsGridView // Add a grid of filtered tools
                }
                .padding(.horizontal)
                .overlay(alignment: .bottom) {
                    if viewModel.isLoading { // Add loading indicator when isLoading is true
                        ProgressView()
                            .padding()
                            .background(ColorConstants.surface)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                .overlay(alignment: .center) {
                    if let errorMessage = viewModel.errorMessage { // Add error message when errorMessage is not nil
                        Text(errorMessage)
                            .foregroundColor(ColorConstants.error)
                            .padding()
                            .background(ColorConstants.surface)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                .refreshable { // Add pull-to-refresh functionality
                    viewModel.refreshData()
                }
                .actionSheet(isPresented: $showingFilterSheet) { // Add filter and sort action sheets
                    filterSheet
                }
                .actionSheet(isPresented: $showingSortSheet) {
                    sortSheet
                }
                .actionSheet(isPresented: $showingEmotionFilterSheet) {
                    emotionFilterSheet
                }
                .navigationBarTitle("Herramientas", displayMode: .inline) // Set the navigation bar title and appearance
                .navigationBarItems(trailing: EmptyView())
            }
        }
    }

    /// Creates the header section with title and filter buttons
    /// - Returns: The header view
    private var headerView: some View {
        HStack { // Create an HStack for the header content
            Text("Herramientas") // Add a title "Herramientas" with appropriate styling
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)

            Spacer()

            Button { // Add filter and sort buttons
                showingFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(ColorConstants.primary)
            }
            .accessibilityLabel("Filtrar herramientas")

            Button {
                showingSortSheet = true
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.title2)
                    .foregroundColor(ColorConstants.primary)
            }
            .accessibilityLabel("Ordenar herramientas")
            
            Button {
                showingEmotionFilterSheet = true
            } label: {
                Image(systemName: "face.smiling")
                    .font(.title2)
                    .foregroundColor(ColorConstants.primary)
            }
            .accessibilityLabel("Filtrar por emoción")
        }
        .padding(.top) // Style the header with appropriate padding and spacing
    }

    /// Creates the search bar for filtering tools
    /// - Returns: The search bar view
    private var searchBarView: some View {
        SearchBar( // Create a SearchBar component
            text: $viewModel.searchQuery, // Bind the search text to viewModel.searchQuery
            placeholder: "Buscar herramientas...", // Configure the search bar appearance
            onTextChange: viewModel.updateSearchQuery // Set up the onTextChange callback to update the search query
        )
    }

    /// Creates a horizontal scrolling view of tool categories
    /// - Returns: The categories scroll view
    private var categoriesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) { // Create a ScrollView with horizontal orientation
            HStack { // Add an HStack to contain category buttons
                Button { // Add a button for "All" category
                    viewModel.selectCategory(category: nil)
                } label: {
                    Text("Todas")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedCategory == nil ? ColorConstants.primary : Color.clear)
                        .foregroundColor(viewModel.selectedCategory == nil ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Todas las categorías")

                ForEach(ToolCategory.allCases, id: \.self) { category in // Add buttons for each category in viewModel.categories
                    Button {
                        viewModel.selectCategory(category: category) // Configure tap actions to select categories
                    } label: {
                        Text(category.displayName())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedCategory == category ? ColorConstants.primary : Color.clear) // Style each button based on selection state
                            .foregroundColor(viewModel.selectedCategory == category ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel(category.displayName())
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// Creates a horizontal scrolling view of emotion filters
    /// - Returns: The emotion filter view
    private var emotionFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) { // Create a ScrollView with horizontal orientation
            HStack { // Add an HStack to contain emotion filter buttons
                Button { // Add a button for "All" emotions
                    viewModel.selectEmotion(emotion: nil)
                } label: {
                    Text("Todas las emociones")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedEmotion == nil ? ColorConstants.primary : Color.clear)
                        .foregroundColor(viewModel.selectedEmotion == nil ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Todas las emociones")

                ForEach(EmotionType.allCases, id: \.self) { emotion in // Add buttons for each emotion in EmotionType.allCases
                    Button {
                        viewModel.selectEmotion(emotion: emotion) // Configure tap actions to select emotions
                    } label: {
                        Text(emotion.displayName())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedEmotion == emotion ? EmotionColors.forEmotionType(emotionType: emotion) : Color.clear) // Style each button based on selection state
                            .foregroundColor(viewModel.selectedEmotion == emotion ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel(emotion.displayName())
                }
            }
            .padding(.vertical, 8)
        }
    }

    /// Creates a section displaying recommended tools
    /// - Returns: The recommended tools section
    private var recommendedToolsSection: some View {
        VStack(alignment: .leading) { // Create a VStack for the section content
            Text("Recomendados para ti") // Add a section header with title "Recomendados para ti"
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
                .padding(.bottom, 4)

            ScrollView(.horizontal, showsIndicators: false) { // Add a ScrollView with horizontal orientation
                HStack { // Add an HStack containing ToolCard for each recommended tool
                    ForEach(viewModel.recommendedTools, id: \.id) { tool in
                        ToolCard( // Configure each ToolCard with appropriate actions
                            tool: tool,
                            isCompact: true,
                            onTap: {
                                viewModel.navigateToToolDetail(tool: tool)
                            },
                            onFavoriteToggle: { isFavorite in
                                viewModel.toggleFavorite(tool: tool)
                            }
                        )
                        .frame(width: 200)
                    }
                }
            }
        }
        .padding(.vertical) // Style the section with appropriate padding and spacing
    }

    /// Creates a section displaying favorite tools
    /// - Returns: The favorite tools section
    private var favoriteToolsSection: some View {
        VStack(alignment: .leading) { // Create a VStack for the section content
            HStack {
                Text("Tus favoritos") // Add a section header with title "Tus favoritos"
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorConstants.textPrimary)
                    .padding(.bottom, 4)
                
                Spacer()
                
                Button {
                    viewModel.toggleShowFavorites()
                } label: {
                    Text("Mostrar todos")
                        .font(.subheadline)
                        .foregroundColor(ColorConstants.primary)
                }
            }

            if viewModel.favoriteTools.isEmpty { // Add an empty state view if no favorites exist
                emptyStateView
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) { // Add a grid or list of ToolCards for favorite tools
                    ForEach(viewModel.favoriteTools, id: \.id) { tool in
                        ToolCard( // Configure each ToolCard with appropriate actions
                            tool: tool,
                            onTap: {
                                viewModel.navigateToToolDetail(tool: tool)
                            },
                            onFavoriteToggle: { isFavorite in
                                viewModel.toggleFavorite(tool: tool)
                            }
                        )
                    }
                }
            }
        }
        .padding(.vertical) // Style the section with appropriate padding and spacing
    }

    /// Creates a grid view of filtered tools
    /// - Returns: The tools grid view
    private var toolsGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) { // Create a LazyVGrid with appropriate columns
            ForEach(viewModel.filteredTools, id: \.id) { tool in // Add a ToolCard for each tool in viewModel.filteredTools
                ToolCard( // Configure each ToolCard with onTap, onFavoriteToggle actions
                    tool: tool,
                    onTap: {
                        viewModel.navigateToToolDetail(tool: tool)
                    },
                    onFavoriteToggle: { isFavorite in
                        viewModel.toggleFavorite(tool: tool)
                    }
                )
            }
        }
        .overlay {
            if viewModel.filteredTools.isEmpty { // Add an empty state view if no tools match the current filters
                emptyStateView
            }
        }
        .padding(.vertical) // Style the grid with appropriate padding and spacing
    }

    /// Creates a view displayed when no tools match the current filters
    /// - Returns: The empty state view
    private var emptyStateView: some View {
        VStack(spacing: 12) { // Create a VStack for the empty state content
            Image(systemName: "magnifyingglass") // Add an appropriate icon (e.g., magnifying glass)
                .font(.system(size: 40))
                .foregroundColor(ColorConstants.textSecondary)

            Text("No se encontraron herramientas") // Add a title "No se encontraron herramientas"
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)

            Text("Intenta usar diferentes filtros") // Add a description suggesting to try different filters
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .multilineTextAlignment(.center)

            Button { // Add a button to clear filters
                viewModel.selectCategory(category: nil)
                viewModel.updateSearchQuery(query: "")
            } label: {
                Text("Limpiar filtros")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(ColorConstants.textOnPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ColorConstants.primary)
                    .cornerRadius(8)
            }
        }
        .padding() // Style the view with appropriate padding and spacing
    }

    /// Creates an action sheet for filtering tools
    /// - Returns: The filter action sheet
    private var filterSheet: ActionSheet {
        ActionSheet( // Create an ActionSheet with title "Filtrar herramientas"
            title: Text("Filtrar herramientas"),
            buttons: FilterOption.allCases.map { option in // Add buttons for each FilterOption in FilterOption.allCases
                .default(Text(option.rawValue)) { // Configure each button to call viewModel.setFilterOption
                    viewModel.setFilterOption(option: option)
                }
            } + [.cancel()] // Add a cancel button
        )
    }

    /// Creates an action sheet for sorting tools
    /// - Returns: The sort action sheet
    private var sortSheet: ActionSheet {
        ActionSheet( // Create an ActionSheet with title "Ordenar herramientas"
            title: Text("Ordenar herramientas"),
            buttons: SortOption.allCases.map { option in // Add buttons for each SortOption in SortOption.allCases
                .default(Text(option.rawValue)) { // Configure each button to call viewModel.setSortOption
                    viewModel.setSortOption(option: option)
                }
            } + [.cancel()] // Add a cancel button
        )
    }
    
    /// Creates an action sheet for filtering tools by emotion
    /// - Returns: The emotion filter action sheet
    private var emotionFilterSheet: ActionSheet {
        ActionSheet( // Create an ActionSheet with title "Filtrar por emoción"
            title: Text("Filtrar por emoción"),
            buttons: [ActionSheet.Button.default(Text("Todas las emociones"), action: { // Add a button for "All" emotions
                viewModel.selectEmotion(emotion: nil) // Configure each button to call viewModel.selectEmotion
            })] + EmotionType.allCases.map { emotion in // Add buttons for each emotion in EmotionType.allCases
                .default(Text(emotion.displayName())) {
                    viewModel.selectEmotion(emotion: emotion) // Configure each button to call viewModel.selectEmotion
                }
            } + [.cancel()] // Add a cancel button
        )
    }
}