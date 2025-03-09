import Foundation // Version: Latest
import Combine // Version: Latest
import SwiftUI // Version: Latest

// Internal imports
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import ToolServiceError // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// Defines filter options for the tool library
enum FilterOption: String, CaseIterable {
    case all = "Todos"
    case newest = "Más nuevos"
    case shortest = "Más cortos"
    case beginner = "Principiante"
}

/// Defines sort options for the tool library
enum SortOption: String, CaseIterable {
    case nameAsc = "Nombre (A-Z)"
    case nameDesc = "Nombre (Z-A)"
    case durationAsc = "Duración (menor)"
    case durationDesc = "Duración (mayor)"
    case popularityDesc = "Más populares"
}

/// Protocol for handling navigation from the tool library screen
protocol ToolNavigationDelegate: AnyObject {
    func navigateToToolDetail(toolId: String)
    func navigateToCategory(category: ToolCategory)
}

/// A view model that manages the state and business logic for the Tool Library screen
@ObservableObject
class ToolLibraryViewModel {
    
    /// Published property for the list of tool categories
    @Published var categories: [ToolCategory] = []
    
    /// Published property for the list of all tools
    @Published var allTools: [Tool] = []
    
    /// Published property for the list of filtered tools
    @Published var filteredTools: [Tool] = []
    
    /// Published property for the list of favorite tools
    @Published var favoriteTools: [Tool] = []
    
    /// Published property for the list of recommended tools
    @Published var recommendedTools: [Tool] = []
    
    /// Published property for the search query
    @Published var searchQuery: String = ""
    
    /// Published property indicating if the data is loading
    @Published var isLoading: Bool = true
    
    /// Published property indicating if the data is refreshing
    @Published var isRefreshing: Bool = false
    
    /// Published property for the error message
    @Published var errorMessage: String? = nil
    
    /// Published property indicating if only favorite tools are being shown
    @Published var showingFavorites: Bool = false
    
    /// Published property for the selected category
    @Published var selectedCategory: ToolCategory? = nil
    
    /// Published property for the selected emotion
    @Published var selectedEmotion: EmotionType? = nil
    
    /// Published property for the selected filter option
    @Published var filterOption: FilterOption = .all
    
    /// Published property for the selected sort option
    @Published var sortOption: SortOption = .nameAsc
    
    /// Weak reference to the navigation delegate
    weak var navigationDelegate: ToolNavigationDelegate?
    
    /// Private property for the tool service
    private let toolService: ToolService
    
    /// Private property for the logger
    private let logger: Logger
    
    /// Private property for storing cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Initializes the ToolLibraryViewModel with dependencies
    /// - Parameters:
    ///   - toolService: The tool service to use
    ///   - navigationDelegate: The navigation delegate to use
    init(toolService: ToolService = ToolService.shared, navigationDelegate: ToolNavigationDelegate? = nil) {
        // Store the provided toolService
        self.toolService = toolService
        // Store the provided navigationDelegate
        self.navigationDelegate = navigationDelegate
        // Initialize logger with Logger.shared
        self.logger = Logger.shared
        // Initialize categories as an empty array
        self.categories = []
        // Initialize allTools as an empty array
        self.allTools = []
        // Initialize filteredTools as an empty array
        self.filteredTools = []
        // Initialize favoriteTools as an empty array
        self.favoriteTools = []
        // Initialize recommendedTools as an empty array
        self.recommendedTools = []
        // Initialize searchQuery as an empty string
        self.searchQuery = ""
        // Initialize isLoading as true
        self.isLoading = true
        // Initialize isRefreshing as false
        self.isRefreshing = false
        // Initialize errorMessage as nil
        self.errorMessage = nil
        // Initialize showingFavorites as false
        self.showingFavorites = false
        // Initialize selectedCategory as nil
        self.selectedCategory = nil
        // Initialize selectedEmotion as nil
        self.selectedEmotion = nil
        // Initialize filterOption as .all
        self.filterOption = .all
        // Initialize sortOption as .nameAsc
        self.sortOption = .nameAsc
        // Initialize cancellables as an empty set
        self.cancellables = Set<AnyCancellable>()
        // Set up subscribers for tool service publishers
        setupSubscribers()
        // Call loadData() to load initial data
        loadData()
    }
    
    /// Loads all necessary data for the tool library
    func loadData() {
        // Set isLoading to true
        isLoading = true
        // Clear errorMessage
        errorMessage = nil
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        toolService.getToolCategories { [weak self] result in
            defer { dispatchGroup.leave() }
            guard let self = self else { return }
            switch result {
            case .success(let categories):
                self.categories = categories
                self.logger.debug("Successfully loaded categories")
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to load categories: \(error)")
            }
        }
        
        dispatchGroup.enter()
        toolService.getTools { [weak self] result in
            defer { dispatchGroup.leave() }
            guard let self = self else { return }
            switch result {
            case .success(let tools):
                self.allTools = tools
                self.logger.debug("Successfully loaded tools")
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to load tools: \(error)")
            }
        }
        
        dispatchGroup.enter()
        toolService.getFavoriteTools { [weak self] result in
            defer { dispatchGroup.leave() }
            guard let self = self else { return }
            switch result {
            case .success(let tools):
                self.favoriteTools = tools
                self.logger.debug("Successfully loaded favorite tools")
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to load favorite tools: \(error)")
            }
        }
        
        dispatchGroup.enter()
        toolService.getRecommendedTools(emotionType: EmotionType.calm) { [weak self] result in
            defer { dispatchGroup.leave() }
            guard let self = self else { return }
            switch result {
            case .success(let tools):
                self.recommendedTools = tools
                self.logger.debug("Successfully loaded recommended tools")
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to load recommended tools: \(error)")
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // Apply filtering and sorting to tools
            self.applyFiltersAndSort()
            // Set isLoading to false when all data is loaded
            self.isLoading = false
        }
    }
    
    /// Refreshes all tool data from the server
    func refreshData() {
        // Set isRefreshing to true
        isRefreshing = true
        // Call toolService.refreshToolData()
        toolService.refreshToolData { [weak self] result in
            guard let self = self else { return }
            // On success, reload all data
            switch result {
            case .success:
                self.loadData()
                self.logger.debug("Successfully refreshed data")
            // On failure, set errorMessage and log error
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to refresh data: \(error)")
            }
            // Set isRefreshing to false when complete
            self.isRefreshing = false
        }
    }
    
    /// Selects a category for filtering tools
    /// - Parameter category: The category to select
    func selectCategory(category: ToolCategory?) {
        // Set selectedCategory to the provided category
        selectedCategory = category
        // Clear selectedEmotion if a category is selected
        if selectedCategory != nil {
            selectedEmotion = nil
        }
        // Apply filtering and sorting to tools
        applyFiltersAndSort()
        // Log category selection
        logger.debug("Selected category: \(category?.displayName() ?? "All")")
    }
    
    /// Selects an emotion for filtering tools
    /// - Parameter emotion: The emotion to select
    func selectEmotion(emotion: EmotionType?) {
        // Set selectedEmotion to the provided emotion
        selectedEmotion = emotion
        // Clear selectedCategory if an emotion is selected
        if selectedEmotion != nil {
            selectedCategory = nil
            // If emotion is not nil, load recommended tools for that emotion
            toolService.getRecommendedTools(emotionType: emotion!) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let tools):
                    self.recommendedTools = tools
                    self.logger.debug("Successfully loaded recommended tools for emotion: \(emotion!.displayName())")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.logger.error("Failed to load recommended tools for emotion: \(emotion!.displayName()): \(error)")
                }
            }
        }
        // Apply filtering and sorting to tools
        applyFiltersAndSort()
        // Log emotion selection
        logger.debug("Selected emotion: \(emotion?.displayName() ?? "None")")
    }
    
    /// Toggles the favorite status of a tool
    /// - Parameter tool: The tool to toggle
    func toggleFavorite(tool: Tool) {
        // Call toolService.toggleFavorite with the tool
        toolService.toggleFavorite(tool: tool) { [weak self] result in
            guard let self = self else { return }
            // On success, update the tool in all relevant arrays
            switch result {
            case .success(let updatedTool):
                self.updateToolInArrays(updatedTool: updatedTool)
                self.logger.debug("Successfully toggled favorite status for tool: \(tool.name)")
            // On failure, set errorMessage and log error
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to toggle favorite status for tool: \(tool.name): \(error)")
            }
        }
    }
    
    /// Toggles the display of favorite tools only
    func toggleShowFavorites() {
        // Toggle showingFavorites boolean
        showingFavorites.toggle()
        // Apply filtering and sorting to tools
        applyFiltersAndSort()
        // Log favorites toggle
        logger.debug("Showing favorites toggled to: \(showingFavorites)")
    }
    
    /// Sets the filter option for tools
    /// - Parameter option: The filter option to set
    func setFilterOption(option: FilterOption) {
        // Set filterOption to the provided option
        filterOption = option
        // Apply filtering and sorting to tools
        applyFiltersAndSort()
        // Log filter option change
        logger.debug("Filter option set to: \(option.rawValue)")
    }
    
    /// Sets the sort option for tools
    /// - Parameter option: The sort option to set
    func setSortOption(option: SortOption) {
        // Set sortOption to the provided option
        sortOption = option
        // Apply filtering and sorting to tools
        applyFiltersAndSort()
        // Log sort option change
        logger.debug("Sort option set to: \(option.rawValue)")
    }
    
    /// Updates the search query for filtering tools
    /// - Parameter query: The search query to set
    func updateSearchQuery(query: String) {
        // Set searchQuery to the provided query
        searchQuery = query
        // Apply filtering and sorting to tools
        applyFiltersAndSort()
        // Log search query update if not empty
        if !query.isEmpty {
            logger.debug("Search query updated to: \(query)")
        }
    }
    
    /// Navigates to the detail screen for a specific tool
    /// - Parameter tool: The tool to navigate to
    func navigateToToolDetail(tool: Tool) {
        // Call navigationDelegate?.navigateToToolDetail with tool.id
        navigationDelegate?.navigateToToolDetail(toolId: tool.id.uuidString)
        // Log navigation to tool detail
        logger.debug("Navigating to tool detail for tool: \(tool.name)")
    }
    
    /// Navigates to a view of tools filtered by category
    /// - Parameter category: The category to navigate to
    func navigateToCategoryDetail(category: ToolCategory) {
        // Call navigationDelegate?.navigateToCategory with category
        navigationDelegate?.navigateToCategory(category: category)
        // Set selectedCategory to the provided category
        selectedCategory = category
        // Clear selectedEmotion
        selectedEmotion = nil
        // Apply filtering and sorting to tools
        applyFiltersAndSort()
        // Log navigation to category detail
        logger.debug("Navigating to category detail for category: \(category.displayName())")
    }
    
    /// Applies current filters and sorting to the tools collection
    private func applyFiltersAndSort() {
        // Start with allTools as the base collection
        var tools = allTools
        
        // If showingFavorites is true, filter to only favorite tools
        if showingFavorites {
            tools = tools.filter { $0.isFavorite }
        }
        
        // If selectedCategory is not nil, filter by category
        if let selectedCategory = selectedCategory {
            tools = tools.filter { $0.category == selectedCategory }
        }
        
        // If selectedEmotion is not nil, filter by emotion
        if let selectedEmotion = selectedEmotion {
            tools = tools.filter { $0.targetEmotions.contains(selectedEmotion) }
        }
        
        // If searchQuery is not empty, filter by name containing query
        if !searchQuery.isEmpty {
            tools = tools.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        // Apply additional filtering based on filterOption
        switch filterOption {
        case .newest:
            tools = tools.sorted { $0.createdAt > $1.createdAt }
        case .shortest:
            tools = tools.sorted { $0.estimatedDuration < $1.estimatedDuration }
        case .beginner:
            tools = tools.filter { $0.difficulty == .beginner }
        case .all:
            break
        }
        
        // Apply sorting based on sortOption
        switch sortOption {
        case .nameAsc:
            tools = tools.sorted { $0.name < $1.name }
        case .nameDesc:
            tools = tools.sorted { $0.name > $1.name }
        case .durationAsc:
            tools = tools.sorted { $0.estimatedDuration < $1.estimatedDuration }
        case .durationDesc:
            tools = tools.sorted { $0.estimatedDuration > $1.estimatedDuration }
        case .popularityDesc:
            tools = tools.sorted { $0.usageCount > $1.usageCount }
        }
        
        // Update filteredTools with the result
        filteredTools = tools
        // Log filter and sort application
        logger.debug("Applied filters and sort, resulting in \(filteredTools.count) tools")
    }
    
    /// Sets up subscribers to tool service publishers
    private func setupSubscribers() {
        // Subscribe to toolService.getToolUpdatedPublisher()
        toolService.getToolUpdatedPublisher()
            .sink { [weak self] updatedTool in
                guard let self = self else { return }
                // When a tool is updated, update it in all relevant arrays
                self.updateToolInArrays(updatedTool: updatedTool)
                self.logger.debug("Tool updated: \(updatedTool.name)")
            }
            .store(in: &cancellables)
        
        // Subscribe to toolService.getToolsLoadedPublisher()
        toolService.getToolsLoadedPublisher()
            .sink { [weak self] in
                guard let self = self else { return }
                // When tools are loaded, reload all tools and favorites
                self.loadData()
                self.logger.debug("Tools loaded, reloading data")
            }
            .store(in: &cancellables)
        
        // Subscribe to toolService.getCategoriesLoadedPublisher()
        toolService.getCategoriesLoadedPublisher()
            .sink { [weak self] in
                guard let self = self else { return }
                // When categories are loaded, reload categories
                self.loadData()
                self.logger.debug("Categories loaded, reloading data")
            }
            .store(in: &cancellables)
    }
    
    /// Updates a tool in all relevant arrays
    /// - Parameter updatedTool: The tool to update
    private func updateToolInArrays(updatedTool: Tool) {
        // Update the tool in allTools array
        if let index = allTools.firstIndex(where: { $0.id == updatedTool.id }) {
            allTools[index] = updatedTool
        }
        
        // Update the tool in filteredTools array
        if let index = filteredTools.firstIndex(where: { $0.id == updatedTool.id }) {
            filteredTools[index] = updatedTool
        }
        
        // Update the tool in favoriteTools array if present
        if updatedTool.isFavorite {
            if !favoriteTools.contains(where: { $0.id == updatedTool.id }) {
                favoriteTools.append(updatedTool)
            }
        } else {
            favoriteTools.removeAll { $0.id == updatedTool.id }
        }
        
        // Update the tool in recommendedTools array if present
        if let index = recommendedTools.firstIndex(where: { $0.id == updatedTool.id }) {
            recommendedTools[index] = updatedTool
        }
        
        // Apply filtering and sorting to ensure consistency
        applyFiltersAndSort()
    }
}