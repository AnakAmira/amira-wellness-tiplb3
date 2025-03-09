import Foundation // Version: standard library
import Combine // Version: Latest
import SwiftUI // Version: Latest

// Internal imports
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import ToolServiceError // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import ToolLibrarySortOption // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryViewModel.swift

/// Defines a protocol for handling navigation operations related to tool categories.
protocol ToolCategoryNavigationHandler: AnyObject {
    /// Navigates to the tool detail screen for a given tool ID.
    /// - Parameter toolId: The ID of the tool to navigate to.
    func navigateToToolDetail(toolId: String)

    /// Navigates back to the previous screen.
    func goBack()
}

/// A view model that manages the state and business logic for the Tool Category screen.
@ObservableObject
class ToolCategoryViewModel {
    /// Published property for the category being displayed.
    @Published var category: ToolCategory

    /// Published property for the list of all tools.
    @Published var allTools: [Tool] = []

    /// Published property for the list of filtered tools.
    @Published var filteredTools: [Tool] = []

    /// Published property for the search query.
    @Published var searchQuery: String = ""

    /// Published property indicating if the data is loading.
    @Published var isLoading: Bool = false

    /// Published property indicating if the data is refreshing.
    @Published var isRefreshing: Bool = false

    /// Published property for the error message.
    @Published var errorMessage: String? = nil

    /// Published property for the sort option.
    @Published var sortOption: ToolLibrarySortOption = .nameAsc

    /// Published property indicating if only favorite tools are being shown.
    @Published var showFavoritesOnly: Bool = false

    /// Private property for the tool service.
    private let toolService: ToolService

    /// Private property for the navigation handler.
    private let navigationHandler: ToolCategoryNavigationHandler

    /// Private property for the logger.
    private let logger: Logger

    /// Private property for storing cancellables.
    private var cancellables = Set<AnyCancellable>()

    /// Initializes the ToolCategoryViewModel with dependencies.
    /// - Parameters:
    ///   - category: The category to display.
    ///   - toolService: The tool service to use.
    ///   - navigationHandler: The navigation handler to use.
    init(category: ToolCategory, toolService: ToolService, navigationHandler: ToolCategoryNavigationHandler) {
        // Store the provided category
        self.category = category
        // Store the provided toolService
        self.toolService = toolService
        // Store the provided navigationHandler
        self.navigationHandler = navigationHandler
        // Initialize logger with Logger.shared
        self.logger = Logger.shared
        // Initialize allTools as an empty array
        self.allTools = []
        // Initialize filteredTools as an empty array
        self.filteredTools = []
        // Initialize searchQuery as an empty string
        self.searchQuery = ""
        // Initialize isLoading as true
        self.isLoading = true
        // Initialize isRefreshing as false
        self.isRefreshing = false
        // Initialize errorMessage as nil
        self.errorMessage = nil
        // Initialize sortOption as .nameAsc
        self.sortOption = .nameAsc
        // Initialize showFavoritesOnly as false
        self.showFavoritesOnly = false
        // Initialize cancellables as an empty set
        self.cancellables = Set<AnyCancellable>()
        // Set up subscribers for tool service publishers
        setupSubscribers()
        // Call loadData() to load initial data
        loadData()
    }

    /// Loads tools for the specified category.
    func loadData() {
        // Set isLoading to true
        isLoading = true
        // Clear errorMessage
        errorMessage = nil

        // Call toolService.getTools with the category
        toolService.getTools(category: category) { [weak self] result in
            guard let self = self else { return }
            // On success, store tools in allTools
            switch result {
            case .success(let tools):
                self.allTools = tools
                // Apply filtering and sorting to update filteredTools
                self.applyFiltersAndSort()
                self.logger.debug("Successfully loaded tools for category: \(self.category.displayName())")
            // On failure, set errorMessage and log error
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to load tools for category: \(self.category.displayName()): \(error)")
            }
            // Set isLoading to false regardless of outcome
            self.isLoading = false
        }
    }

    /// Loads tools for the specified category using async/await.
    @available(iOS 15.0, *)
    func loadDataAsync() async {
        // Set isLoading to true
        isLoading = true
        // Clear errorMessage
        errorMessage = nil

        do {
            // Try to call toolService.getToolsAsync with the category
            let tools = try await toolService.getToolsAsync(category: category)
            // On success, store tools in allTools
            self.allTools = tools
            // Apply filtering and sorting to update filteredTools
            self.applyFiltersAndSort()
            self.logger.debug("Successfully loaded tools for category: \(self.category.displayName())")
        } catch {
            // On failure, set errorMessage and log error
            self.errorMessage = error.localizedDescription
            self.logger.error("Failed to load tools for category: \(self.category.displayName()): \(error)")
        }
        // Set isLoading to false regardless of outcome
        self.isLoading = false
    }

    /// Refreshes tools data from the server.
    func refreshData() {
        // Set isRefreshing to true
        isRefreshing = true
        // Clear errorMessage
        errorMessage = nil

        // Call toolService.getTools with the category and forceRefresh set to true
        toolService.getTools(category: category, forceRefresh: true) { [weak self] result in
            guard let self = self else { return }
            // On success, store tools in allTools
            switch result {
            case .success(let tools):
                self.allTools = tools
                // Apply filtering and sorting to update filteredTools
                self.applyFiltersAndSort()
                self.logger.debug("Successfully refreshed tools for category: \(self.category.displayName())")
            // On failure, set errorMessage and log error
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to refresh tools for category: \(self.category.displayName()): \(error)")
            }
            // Set isRefreshing to false regardless of outcome
            self.isRefreshing = false
        }
    }

    /// Refreshes tools data from the server using async/await.
    @available(iOS 15.0, *)
    func refreshDataAsync() async {
        // Set isRefreshing to true
        isRefreshing = true
        // Clear errorMessage
        errorMessage = nil

        do {
            // Try to call toolService.getToolsAsync with the category and forceRefresh set to true
            let tools = try await toolService.getToolsAsync(category: category, forceRefresh: true)
            // On success, store tools in allTools
            self.allTools = tools
            // Apply filtering and sorting to update filteredTools
            self.applyFiltersAndSort()
            self.logger.debug("Successfully refreshed tools for category: \(self.category.displayName())")
        } catch {
            // On failure, set errorMessage and log error
            self.errorMessage = error.localizedDescription
            self.logger.error("Failed to refresh tools for category: \(self.category.displayName()): \(error)")
        }
        // Set isRefreshing to false regardless of outcome
        self.isRefreshing = false
    }

    /// Toggles the favorite status of a tool.
    /// - Parameter tool: The tool to toggle.
    func toggleFavorite(tool: Tool) {
        // Call toolService.toggleFavorite with the tool
        toolService.toggleFavorite(tool: tool) { [weak self] result in
            guard let self = self else { return }
            // On success, update the tool in allTools and filteredTools arrays
            switch result {
            case .success(let updatedTool):
                self.updateToolInArrays(updatedTool: updatedTool)
                // Apply filtering and sorting to ensure consistency
                self.applyFiltersAndSort()
                self.logger.debug("Successfully toggled favorite status for tool: \(tool.name)")
            // On failure, set errorMessage and log error
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.logger.error("Failed to toggle favorite status for tool: \(tool.name): \(error)")
            }
        }
    }

    /// Toggles the favorite status of a tool using async/await.
    @available(iOS 15.0, *)
    func toggleFavoriteAsync(tool: Tool) async {
        do {
            // Try to call toolService.toggleFavoriteAsync with the tool
            let updatedTool = try await toolService.toggleFavoriteAsync(tool: tool)
            // Update the tool in allTools and filteredTools arrays
            self.updateToolInArrays(updatedTool: updatedTool)
            // Apply filtering and sorting to ensure consistency
            self.applyFiltersAndSort()
            self.logger.debug("Successfully toggled favorite status for tool: \(tool.name)")
        } catch {
            // On failure, set errorMessage and log error
            self.errorMessage = error.localizedDescription
            self.logger.error("Failed to toggle favorite status for tool: \(tool.name): \(error)")
        }
    }

    /// Updates the search query for filtering tools.
    /// - Parameter query: The search query to set.
    func updateSearchQuery(query: String) {
        // Set searchQuery to the provided query
        searchQuery = query
        // Apply filtering and sorting to update filteredTools
        applyFiltersAndSort()
        // Log search query update if not empty
        if !query.isEmpty {
            logger.debug("Search query updated to: \(query)")
        }
    }

    /// Sets the sort option for tools.
    /// - Parameter option: The sort option to set.
    func setSortOption(option: ToolLibrarySortOption) {
        // Set sortOption to the provided option
        sortOption = option
        // Apply filtering and sorting to update filteredTools
        applyFiltersAndSort()
        // Log sort option change
        logger.debug("Sort option set to: \(option)")
    }

    /// Toggles the display of favorite tools only.
    func toggleShowFavoritesOnly() {
        // Toggle showFavoritesOnly boolean
        showFavoritesOnly.toggle()
        // Apply filtering and sorting to update filteredTools
        applyFiltersAndSort()
        // Log favorites toggle
        logger.debug("Showing favorites toggled to: \(showFavoritesOnly)")
    }

    /// Navigates to the detail screen for a specific tool.
    /// - Parameter tool: The tool to navigate to.
    func navigateToToolDetail(tool: Tool) {
        // Call navigationHandler.navigateToToolDetail with tool.id
        navigationHandler.navigateToToolDetail(toolId: tool.id.uuidString)
        // Log navigation to tool detail
        logger.debug("Navigating to tool detail for tool: \(tool.name)")
    }

    /// Navigates back to the previous screen.
    func navigateBack() {
        // Call navigationHandler.goBack()
        navigationHandler.goBack()
        // Log navigation back
        logger.debug("Navigating back")
    }

    /// Applies current filters and sorting to the tools collection.
    private func applyFiltersAndSort() {
        // Start with allTools as the base collection
        var tools = allTools

        // If showFavoritesOnly is true, filter to only favorite tools
        if showFavoritesOnly {
            tools = tools.filter { $0.isFavorite }
        }

        // If searchQuery is not empty, filter by name containing query
        if !searchQuery.isEmpty {
            tools = tools.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        // Apply sorting based on sortOption
        tools = sortTools(tools: tools)

        // Update filteredTools with the result
        filteredTools = tools
        // Log filter and sort application
        logger.debug("Applied filters and sort, resulting in \(filteredTools.count) tools")
    }

    /// Sets up subscribers to tool service publishers.
    private func setupSubscribers() {
        // Subscribe to toolService.getToolUpdatedPublisher()
        toolService.getToolUpdatedPublisher()
            .sink { [weak self] updatedTool in
                guard let self = self else { return }
                // When a tool is updated, update it in allTools and filteredTools arrays
                self.updateToolInArrays(updatedTool: updatedTool)
                self.logger.debug("Tool updated: \(updatedTool.name)")
            }
            .store(in: &cancellables)
    }

    /// Updates a tool in all relevant arrays.
    /// - Parameter updatedTool: The tool to update.
    private func updateToolInArrays(updatedTool: Tool) {
        // Update the tool in allTools array if it exists
        if let index = allTools.firstIndex(where: { $0.id == updatedTool.id }) {
            allTools[index] = updatedTool
        }

        // Update the tool in filteredTools array if it exists
        if let index = filteredTools.firstIndex(where: { $0.id == updatedTool.id }) {
            filteredTools[index] = updatedTool
        }

        // Apply filtering and sorting to ensure consistency
        applyFiltersAndSort()
    }

    /// Sorts tools based on the current sort option.
    /// - Parameter tools: The array of tools to sort.
    /// - Returns: Sorted array of tools.
    private func sortTools(tools: [Tool]) -> [Tool] {
        switch sortOption {
        case .nameAsc:
            return tools.sorted { $0.name < $1.name }
        case .nameDesc:
            return tools.sorted { $0.name > $1.name }
        case .durationAsc:
            return tools.sorted { $0.estimatedDuration < $1.estimatedDuration }
        case .durationDesc:
            return tools.sorted { $0.estimatedDuration > $1.estimatedDuration }
        case .popularityDesc:
            return tools.sorted { $0.usageCount > $1.usageCount }
        }
    }
}