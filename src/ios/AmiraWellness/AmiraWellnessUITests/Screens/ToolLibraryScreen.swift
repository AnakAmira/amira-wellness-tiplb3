//
// ToolLibraryScreen.swift
// AmiraWellnessUITests
//
// Screen object for UI testing the Tool Library feature of the Amira Wellness application.
// Implements the Page Object pattern to encapsulate interactions with the Tool Library screen.
//

import XCTest

/// Screen object for interacting with the Tool Library screen in UI tests
class ToolLibraryScreen: BaseScreen {
    // MARK: - Properties
    
    /// The title of the Tool Library screen
    let toolLibraryTitle: XCUIElement
    
    /// The search bar for searching tools
    let searchBar: XCUIElement
    
    /// The scroll view containing tool categories
    let categoriesScrollView: XCUIElement
    
    /// The grid/list of tools
    let toolsGrid: XCUIElement
    
    /// The button to open filter options
    let filterButton: XCUIElement
    
    /// The button to open sort options
    let sortButton: XCUIElement
    
    /// The toggle to show only favorite tools
    let favoritesToggle: XCUIElement
    
    /// The button to filter tools by emotion
    let emotionFilterButton: XCUIElement
    
    /// The view displayed when no tools match the current filters
    let emptyStateView: XCUIElement
    
    /// The view displayed when an error occurs loading tools
    let errorStateView: XCUIElement
    
    /// The button to retry after an error
    let retryButton: XCUIElement
    
    /// The activity indicator shown during loading
    let loadingIndicator: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new ToolLibraryScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    init(app: XCUIApplication) {
        super.init(app: app)
        
        rootElement = app.otherElements["toolLibraryScreen"]
        toolLibraryTitle = app.staticTexts["Herramientas"]
        searchBar = app.searchFields["Buscar herramientas"]
        categoriesScrollView = app.scrollViews["categoriesScrollView"]
        toolsGrid = app.scrollViews["toolsGrid"]
        filterButton = app.buttons["filterButton"]
        sortButton = app.buttons["sortButton"]
        favoritesToggle = app.buttons["favoritesToggle"]
        emotionFilterButton = app.buttons["emotionFilterButton"]
        emptyStateView = app.otherElements["emptyStateView"]
        errorStateView = app.otherElements["errorStateView"]
        retryButton = app.buttons["retryButton"]
        loadingIndicator = app.activityIndicators["loadingIndicator"]
    }
    
    // MARK: - Screen Navigation
    
    /// Waits for the Tool Library screen to be displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the screen was displayed within the timeout
    func waitForToolLibraryScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let screenAppeared = waitForScreen(timeout: timeout)
        let titleAppeared = verifyElementExists(toolLibraryTitle, timeout: timeout)
        return screenAppeared && titleAppeared
    }
    
    // MARK: - Search Functions
    
    /// Searches for a tool by entering text in the search bar
    /// - Parameter searchText: The text to search for
    /// - Returns: Whether the search was successful
    func searchForTool(searchText: String) -> Bool {
        guard tapElement(searchBar) else {
            return false
        }
        
        guard enterText(searchBar, text: searchText) else {
            return false
        }
        
        // Wait for search results to update
        return waitForLoadingToComplete(timeout: TimeoutDuration.short)
    }
    
    /// Clears the current search text
    /// - Returns: Whether the search was cleared successfully
    func clearSearch() -> Bool {
        guard tapElement(searchBar) else {
            return false
        }
        
        // Look for clear button in the search field and tap it
        let clearButton = searchBar.buttons["Clear text"].firstMatch
        guard tapElement(clearButton) else {
            return false
        }
        
        return waitForLoadingToComplete(timeout: TimeoutDuration.short)
    }
    
    // MARK: - Category and Tool Selection
    
    /// Selects a tool category by name
    /// - Parameter categoryName: The name of the category to select
    /// - Returns: Whether the category was selected successfully
    func selectCategory(categoryName: String) -> Bool {
        // Find the category button by text
        guard let categoryButton = findElementByText(categoryName, elementType: .button) else {
            return false
        }
        
        // Scroll to the category button if needed
        guard scrollToElement(categoriesScrollView, element: categoryButton) else {
            return false
        }
        
        // Tap on the category button
        guard tapElement(categoryButton) else {
            return false
        }
        
        // Wait for tools to update based on category selection
        return waitForLoadingToComplete(timeout: TimeoutDuration.short)
    }
    
    /// Selects a tool by name
    /// - Parameter toolName: The name of the tool to select
    /// - Returns: Whether the tool was selected successfully
    func selectTool(toolName: String) -> Bool {
        // Find the tool card by text
        guard let toolCard = findElementByText(toolName, elementType: .any) else {
            return false
        }
        
        // Scroll to the tool card if needed
        guard scrollToElement(toolsGrid, element: toolCard) else {
            return false
        }
        
        // Tap on the tool card
        return tapElement(toolCard)
    }
    
    /// Selects a tool by first selecting its category and then the tool by name
    /// - Parameters:
    ///   - categoryName: The name of the category
    ///   - toolName: The name of the tool to select
    /// - Returns: Whether the tool was selected successfully
    func selectToolWithCategoryAndName(categoryName: String, toolName: String) -> Bool {
        guard selectCategory(categoryName: categoryName) else {
            return false
        }
        
        return selectTool(toolName: toolName)
    }
    
    // MARK: - Favorites
    
    /// Toggles the favorite status for a tool
    /// - Parameter toolName: The name of the tool to favorite/unfavorite
    /// - Returns: Whether the favorite status was toggled successfully
    func toggleFavoriteForTool(toolName: String) -> Bool {
        // Find the tool card by text
        guard let toolCard = findElementByText(toolName, elementType: .any) else {
            return false
        }
        
        // Scroll to the tool card if needed
        guard scrollToElement(toolsGrid, element: toolCard) else {
            return false
        }
        
        // Find the favorite button within the tool card
        let favoriteButton = toolCard.descendants(matching: .button).matching(NSPredicate(format: "identifier CONTAINS 'favorite'")).firstMatch
        
        // Tap on the favorite button
        return tapElement(favoriteButton)
    }
    
    /// Toggles the favorites filter to show only favorite tools
    /// - Returns: Whether the favorites filter was toggled successfully
    func toggleFavoritesFilter() -> Bool {
        // Tap on the favorites toggle button
        guard tapElement(favoritesToggle) else {
            return false
        }
        
        // Wait for the tools list to update
        return waitForLoadingToComplete(timeout: TimeoutDuration.short)
    }
    
    // MARK: - Filtering and Sorting
    
    /// Opens the filter options sheet
    /// - Returns: Whether the filter options were opened successfully
    func openFilterOptions() -> Bool {
        return tapElement(filterButton)
    }
    
    /// Selects a filter option from the filter sheet
    /// - Parameter filterOption: The name of the filter option to select
    /// - Returns: Whether the filter option was selected successfully
    func selectFilterOption(filterOption: String) -> Bool {
        // Open filter options if not already open
        guard openFilterOptions() else {
            return false
        }
        
        // Find the filter option button by text
        guard let optionButton = findElementByText(filterOption, elementType: .button) else {
            return false
        }
        
        // Tap on the filter option button
        guard tapElement(optionButton) else {
            return false
        }
        
        // Wait for the tools list to update
        return waitForLoadingToComplete(timeout: TimeoutDuration.short)
    }
    
    /// Opens the sort options sheet
    /// - Returns: Whether the sort options were opened successfully
    func openSortOptions() -> Bool {
        return tapElement(sortButton)
    }
    
    /// Selects a sort option from the sort sheet
    /// - Parameter sortOption: The name of the sort option to select
    /// - Returns: Whether the sort option was selected successfully
    func selectSortOption(sortOption: String) -> Bool {
        // Open sort options if not already open
        guard openSortOptions() else {
            return false
        }
        
        // Find the sort option button by text
        guard let optionButton = findElementByText(sortOption, elementType: .button) else {
            return false
        }
        
        // Tap on the sort option button
        guard tapElement(optionButton) else {
            return false
        }
        
        // Wait for the tools list to update
        return waitForLoadingToComplete(timeout: TimeoutDuration.short)
    }
    
    /// Opens the emotion filter options
    /// - Returns: Whether the emotion filter options were opened successfully
    func openEmotionFilter() -> Bool {
        return tapElement(emotionFilterButton)
    }
    
    /// Selects an emotion filter option
    /// - Parameter emotionName: The name of the emotion to filter by
    /// - Returns: Whether the emotion filter was selected successfully
    func selectEmotionFilter(emotionName: String) -> Bool {
        // Open emotion filter options if not already open
        guard openEmotionFilter() else {
            return false
        }
        
        // Find the emotion option button by text
        guard let optionButton = findElementByText(emotionName, elementType: .button) else {
            return false
        }
        
        // Tap on the emotion option button
        guard tapElement(optionButton) else {
            return false
        }
        
        // Wait for the tools list to update
        return waitForLoadingToComplete(timeout: TimeoutDuration.short)
    }
    
    /// Clears the current emotion filter
    /// - Returns: Whether the emotion filter was cleared successfully
    func clearEmotionFilter() -> Bool {
        // Select the "All" option to clear the filter
        return selectEmotionFilter(emotionName: "Todas")
    }
    
    // MARK: - Refresh and Error Handling
    
    /// Performs a pull-to-refresh gesture to refresh the tool library
    /// - Returns: Whether the refresh was triggered successfully
    func refreshToolLibrary() -> Bool {
        // Perform a swipe down gesture on the tools grid
        swipeDown(toolsGrid)
        
        // Wait for the loading indicator to appear and then disappear
        return waitForLoadingToComplete(timeout: TimeoutDuration.standard)
    }
    
    /// Checks if a tool is visible in the current view
    /// - Parameter toolName: The name of the tool to check
    /// - Returns: Whether the tool is visible
    func isToolVisible(toolName: String) -> Bool {
        guard let toolCard = findElementByText(toolName, elementType: .any) else {
            return false
        }
        
        return isElementVisible(toolCard)
    }
    
    /// Checks if a category is visible in the categories scroll view
    /// - Parameter categoryName: The name of the category to check
    /// - Returns: Whether the category is visible
    func isCategoryVisible(categoryName: String) -> Bool {
        guard let categoryButton = findElementByText(categoryName, elementType: .button) else {
            return false
        }
        
        return isElementVisible(categoryButton)
    }
    
    /// Checks if the empty state view is visible
    /// - Returns: Whether the empty state is visible
    func isEmptyStateVisible() -> Bool {
        return isElementVisible(emptyStateView)
    }
    
    /// Checks if the error state view is visible
    /// - Returns: Whether the error state is visible
    func isErrorStateVisible() -> Bool {
        return isElementVisible(errorStateView)
    }
    
    /// Taps the retry button after an error occurs
    /// - Returns: Whether the retry button was tapped successfully
    func retryAfterError() -> Bool {
        guard isErrorStateVisible() else {
            return false
        }
        
        guard tapElement(retryButton) else {
            return false
        }
        
        // Wait for the loading indicator to appear and then disappear
        return waitForLoadingToComplete(timeout: TimeoutDuration.standard)
    }
    
    // MARK: - Utility Methods
    
    /// Gets the count of visible tools in the current view
    /// - Returns: The number of visible tools
    func getToolCount() -> Int {
        return app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS 'toolCard'")).count
    }
    
    /// Gets the count of visible categories in the categories scroll view
    /// - Returns: The number of visible categories
    func getCategoryCount() -> Int {
        return categoriesScrollView.buttons.count
    }
}