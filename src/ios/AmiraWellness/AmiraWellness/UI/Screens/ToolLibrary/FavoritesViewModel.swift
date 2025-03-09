import Foundation // Version: Latest - Core Swift functionality
import Combine // Version: Latest - Reactive programming for handling asynchronous events
import SwiftUI // Version: Latest - For ObservableObject conformance and property wrappers

// Internal imports
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift - Core data model for tools in the library
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift - Enumeration of tool categories for filtering
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift - Service for fetching and managing favorite tools
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift - Logging service for debugging and error tracking
import AnalyticsManager // src/ios/AmiraWellness/AmiraWellness/Managers/AnalyticsManager.swift - Tracking user interactions with favorite tools

/// Defines sort options for the favorites screen
enum FavoritesSortOption: String, CaseIterable {
    case nameAsc, nameDesc, categoryAsc, categoryDesc, recentlyAdded
    
    /// Returns the localized display name for the sort option
    func displayName() -> String {
        switch self {
        case .nameAsc:
            return NSLocalizedString("Nombre (A-Z)", comment: "Sort by name ascending")
        case .nameDesc:
            return NSLocalizedString("Nombre (Z-A)", comment: "Sort by name descending")
        case .categoryAsc:
            return NSLocalizedString("Categoría (A-Z)", comment: "Sort by category ascending")
        case .categoryDesc:
            return NSLocalizedString("Categoría (Z-A)", comment: "Sort by category descending")
        case .recentlyAdded:
            return NSLocalizedString("Recientemente añadidos", comment: "Sort by recently added")
        }
    }
}

/// A view model that manages the state and business logic for the Favorites screen
@MainActor
class FavoritesViewModel: ObservableObject {
    
    /// Published property to store the list of favorite tools
    @Published var favoriteTools: [Tool] = []
    /// Published property to store the filtered list of favorite tools based on search query and category
    @Published var filteredTools: [Tool] = []
    /// Published property to store the search query
    @Published var searchQuery: String = ""
    /// Published property to indicate if the data is loading
    @Published var isLoading: Bool = false
    /// Published property to indicate if the data is refreshing
    @Published var isRefreshing: Bool = false
    /// Published property to store any error message
    @Published var errorMessage: String? = nil
    /// Published property to store the selected sort option
    @Published var sortOption: FavoritesSortOption = .nameAsc
    /// Published property to store the selected category for filtering
    @Published var selectedCategory: ToolCategory? = nil
    
    /// Private property to hold the ToolService instance
    private let toolService: ToolService
    /// Private property to hold the Logger instance
    private let logger: Logger
    /// Private property to hold the set of Combine cancellables
    private var cancellables: Set<AnyCancellable> = []
    
    /// Initializes the FavoritesViewModel with dependencies
    /// - Parameters:
    ///   - toolService: Optional ToolService instance for dependency injection (default: ToolService.shared)
    ///   - logger: Optional Logger instance for dependency injection (default: Logger.shared)
    init(toolService: ToolService? = nil, logger: Logger? = nil) {
        // Initialize toolService with provided service or ToolService.shared
        self.toolService = toolService ?? ToolService.shared
        // Initialize logger with provided logger or Logger.shared
        self.logger = logger ?? Logger.shared
        // Initialize favoriteTools as an empty array
        self.favoriteTools = []
        // Initialize filteredTools as an empty array
        self.filteredTools = []
        // Initialize searchQuery as an empty string
        self.searchQuery = ""
        // Initialize isLoading as false
        self.isLoading = false
        // Initialize isRefreshing as false
        self.isRefreshing = false
        // Initialize errorMessage as nil
        self.errorMessage = nil
        // Initialize sortOption as .nameAsc
        self.sortOption = .nameAsc
        // Initialize selectedCategory as nil
        self.selectedCategory = nil
        // Initialize cancellables as an empty set
        self.cancellables = []
        
        // Set up Combine publishers for reactive updates
        setupPublishers()
        
        // Load initial data
        loadData()
    }
    
    /// Loads favorite tools from the service
    func loadData() {
        // Set isLoading to true
        isLoading = true
        // Clear errorMessage
        errorMessage = nil
        
        // Call toolService.getFavoriteTools with forceRefresh: false
        toolService.getFavoriteTools(forceRefresh: false) { [weak self] result in
            guard let self = self else { return }
            
            // On success, update favoriteTools and apply filtering and sorting
            switch result {
            case .success(let tools):
                self.favoriteTools = tools
                self.filterTools()
                self.logger.debug("Successfully loaded favorite tools", category: .database)
                
            // On failure, set errorMessage with appropriate error message
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to load favorite tools: \(error)", category: .database)
            }
            
            // Set isLoading to false regardless of outcome
            self.isLoading = false
        }
    }
    
    /// Refreshes favorite tools from the service
    func refreshData() {
        // Set isRefreshing to true
        isRefreshing = true
        // Clear errorMessage
        errorMessage = nil
        
        // Call toolService.getFavoriteTools with forceRefresh: true
        toolService.getFavoriteTools(forceRefresh: true) { [weak self] result in
            guard let self = self else { return }
            
            // On success, update favoriteTools and apply filtering and sorting
            switch result {
            case .success(let tools):
                self.favoriteTools = tools
                self.filterTools()
                self.logger.debug("Successfully refreshed favorite tools", category: .database)
                
            // On failure, set errorMessage with appropriate error message
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to refresh favorite tools: \(error)", category: .database)
            }
            
            // Set isRefreshing to false regardless of outcome
            self.isRefreshing = false
            
            // Track refresh event with analytics
            AnalyticsManager.shared.trackEvent(eventType: .featureUse, parameters: ["feature_name": "refresh_favorite_tools"])
        }
    }
    
    /// Toggles the favorite status of a tool
    /// - Parameter tool: The tool to toggle the favorite status for
    func toggleFavorite(tool: Tool) {
        // Call toolService.toggleFavorite with the provided tool
        toolService.toggleFavorite(tool: tool) { [weak self] result in
            guard let self = self else { return }
            
            // On success, handle the updated tool
            switch result {
            case .success(let updatedTool):
                // If the tool is no longer a favorite, remove it from favoriteTools
                if !updatedTool.isFavorite {
                    self.favoriteTools.removeAll { $0.id == updatedTool.id }
                } else {
                    // Otherwise, update the tool in the favoriteTools array
                    if let index = self.favoriteTools.firstIndex(where: { $0.id == updatedTool.id }) {
                        self.favoriteTools[index] = updatedTool
                    } else {
                        self.favoriteTools.append(updatedTool)
                    }
                }
                
                // Apply filtering and sorting to update filteredTools
                self.filterTools()
                self.logger.debug("Successfully toggled favorite status for tool: \(tool.name)", category: .database)
                
            // On failure, set errorMessage with appropriate error message
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to toggle favorite status for tool: \(tool.name): \(error)", category: .database)
            }
            
            // Track favorite toggle event with analytics
            AnalyticsManager.shared.trackEvent(eventType: .featureUse, parameters: ["feature_name": "toggle_favorite", "tool_id": tool.id.uuidString, "is_favorite": tool.isFavorite])
        }
    }
    
    /// Updates the search query and filters tools accordingly
    /// - Parameter query: The new search query
    func updateSearchQuery(query: String) {
        // Set searchQuery to the provided query
        searchQuery = query
        
        // Track search event with analytics if query is not empty
        if !query.isEmpty {
            AnalyticsManager.shared.trackEvent(eventType: .featureUse, parameters: ["feature_name": "search_tools", "search_query": query])
        }
    }
    
    /// Sets the sort option and reorders tools accordingly
    /// - Parameter option: The new sort option
    func setSortOption(option: FavoritesSortOption) {
        // Set sortOption to the provided option
        sortOption = option
        
        // Apply sorting to update filteredTools
        filterTools()
        
        // Track sort option change with analytics
        AnalyticsManager.shared.trackEvent(eventType: .settingsChanged, parameters: ["setting_name": "sort_option", "sort_option": option.rawValue])
    }
    
    /// Selects a category for filtering tools
    /// - Parameter category: The category to filter by
    func selectCategory(category: ToolCategory?) {
        // Set selectedCategory to the provided category
        selectedCategory = category
        
        // Track category selection with analytics
        AnalyticsManager.shared.trackEvent(eventType: .featureUse, parameters: ["feature_name": "filter_tools_by_category", "category_name": category?.rawValue ?? "all"])
    }
    
    /// Prepares for navigation to tool detail
    /// - Parameter tool: The tool to navigate to
    func navigateToToolDetail(tool: Tool) {
        // Track tool selection with analytics
        AnalyticsManager.shared.trackEvent(eventType: .featureUse, parameters: ["feature_name": "select_tool", "tool_id": tool.id.uuidString])
    }
    
    /// Gets the count of tools in a specific category
    /// - Parameter category: The category to count tools in
    /// - Returns: The number of tools in the category
    func getCategoryCount(category: ToolCategory?) -> Int {
        // If category is nil, return the total count of favoriteTools
        guard let category = category else {
            return favoriteTools.count
        }
        
        // Otherwise, filter favoriteTools by the specified category and return the count
        return favoriteTools.filter { $0.category == category }.count
    }
    
    /// Filters tools based on search query and selected category
    private func filterTools() {
        // Start with all favoriteTools
        var tools = favoriteTools
        
        // If searchQuery is not empty, filter tools by name containing the query
        if !searchQuery.isEmpty {
            tools = tools.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        // If selectedCategory is not nil, filter tools by matching category
        if let selectedCategory = selectedCategory {
            tools = tools.filter { $0.category == selectedCategory }
        }
        
        // Apply current sort option
        filteredTools = sortTools(tools: tools)
    }
    
    /// Sorts tools based on the current sort option
    /// - Parameter tools: The array of tools to sort
    /// - Returns: The sorted array of tools
    private func sortTools(tools: [Tool]) -> [Tool] {
        switch sortOption {
        // For nameAsc: Sort by name ascending
        case .nameAsc:
            return tools.sorted { $0.name < $1.name }
        // For nameDesc: Sort by name descending
        case .nameDesc:
            return tools.sorted { $0.name > $1.name }
        // For categoryAsc: Sort by category name ascending
        case .categoryAsc:
            return tools.sorted { $0.category.displayName() < $1.category.displayName() }
        // For categoryDesc: Sort by category name descending
        case .categoryDesc:
            return tools.sorted { $0.category.displayName() > $1.category.displayName() }
        // For recentlyAdded: Sort by most recently added (using createdAt or updatedAt)
        case .recentlyAdded:
            return tools.sorted {
                if let date1 = $0.updatedAt, let date2 = $1.updatedAt {
                    return date1 > date2
                } else if $0.updatedAt != nil {
                    return true // $0 has updatedAt, $1 doesn't
                } else if $1.updatedAt != nil {
                    return false // $1 has updatedAt, $0 doesn't
                } else {
                    return $0.createdAt > $1.createdAt // Both have no updatedAt, sort by createdAt
                }
            }
        }
    }
    
    /// Sets up Combine publishers for reactive updates
    private func setupPublishers() {
        // Create a publisher that combines searchQuery and selectedCategory changes
        Publishers.CombineLatest($searchQuery, $selectedCategory)
        // Debounce to prevent excessive updates during typing
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        // Subscribe to trigger filterTools() when values change
            .sink { [weak self] _ in
                self?.filterTools()
            }
            .store(in: &cancellables)
        
        // Subscribe to toolService.getToolUpdatedPublisher() to handle tool updates
        toolService.getToolUpdatedPublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] updatedTool in
                guard let self = self else { return }
                
                // Update the tool in the favoriteTools array
                if let index = self.favoriteTools.firstIndex(where: { $0.id == updatedTool.id }) {
                    self.favoriteTools[index] = updatedTool
                    self.filterTools()
                    self.logger.debug("Updated tool in favoriteTools array", category: .database)
                }
            }
            .store(in: &cancellables)
    }
}