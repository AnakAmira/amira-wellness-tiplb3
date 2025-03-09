//
// ToolLibraryUITests.swift
// AmiraWellnessUITests
//
// UI test suite for the Tool Library feature of the Amira Wellness application.
// Tests browsing tool categories, searching for tools, filtering and sorting tools,
// favoriting tools, and navigating to tool details.
//

import XCTest

class ToolLibraryUITests: XCTestCase {
    // MARK: - Properties
    
    var app: XCUIApplication!
    var toolLibraryScreen: ToolLibraryScreen!
    var homeScreen: HomeScreen!
    var loginScreen: LoginScreen!
    var testUserEmail: String!
    var testUserPassword: String!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize the app and configure it for testing
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        // Set up test credentials
        testUserEmail = "test@example.com"
        testUserPassword = "Password123!"
        
        // Initialize screen objects
        toolLibraryScreen = ToolLibraryScreen(app: app)
        homeScreen = HomeScreen(app: app)
        loginScreen = LoginScreen(app: app)
    }
    
    override func tearDown() {
        // Terminate the app if running
        if app.state == .runningForeground {
            app.terminate()
        }
        
        super.tearDown()
    }
    
    // MARK: - Test Methods
    
    /// Tests that the Tool Library screen appears when navigating from the home screen
    func testToolLibraryScreenAppears() {
        // Launch the app and login
        launchAppAndLogin(app, email: testUserEmail, password: testUserPassword)
        
        // Navigate to the tool library
        XCTAssertTrue(homeScreen.tapFavoritesButton(), "Failed to tap the favorites button")
        
        // Verify the tool library screen appears
        XCTAssertTrue(toolLibraryScreen.waitForToolLibraryScreen(), "Tool library screen did not appear")
        
        // Take a screenshot
        takeScreenshot(self, name: "Tool Library Screen")
    }
    
    /// Tests navigation between tool categories
    func testCategoryNavigation() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Get the number of categories
        let categoryCount = toolLibraryScreen.getCategoryCount()
        XCTAssertGreaterThan(categoryCount, 1, "There should be multiple categories available")
        
        // Select the Breathing category
        XCTAssertTrue(toolLibraryScreen.selectCategory(categoryName: "Respiración"), "Failed to select Breathing category")
        
        // Verify that breathing tools are displayed
        XCTAssertTrue(toolLibraryScreen.isToolVisible(toolName: "Respiración 4-7-8"), "Breathing tool not visible after category selection")
        
        // Select the Meditation category
        XCTAssertTrue(toolLibraryScreen.selectCategory(categoryName: "Meditación"), "Failed to select Meditation category")
        
        // Verify that meditation tools are displayed
        XCTAssertTrue(toolLibraryScreen.isToolVisible(toolName: "Meditación para la ansiedad"), "Meditation tool not visible after category selection")
    }
    
    /// Tests searching for tools by name
    func testToolSearch() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Get initial count of visible tools
        let initialToolCount = toolLibraryScreen.getToolCount()
        XCTAssertGreaterThan(initialToolCount, 0, "There should be tools visible initially")
        
        // Search for a specific tool
        XCTAssertTrue(toolLibraryScreen.searchForTool(searchText: "Respiración 4-7-8"), "Failed to search for tool")
        
        // Verify search results are filtered
        let searchResultCount = toolLibraryScreen.getToolCount()
        XCTAssertLessThanOrEqual(searchResultCount, initialToolCount, "Search should filter the results")
        XCTAssertTrue(toolLibraryScreen.isToolVisible(toolName: "Respiración 4-7-8"), "Search result should contain the searched tool")
        
        // Clear search
        XCTAssertTrue(toolLibraryScreen.clearSearch(), "Failed to clear search")
        
        // Verify all tools are displayed again
        let afterClearCount = toolLibraryScreen.getToolCount()
        XCTAssertEqual(afterClearCount, initialToolCount, "After clearing search, all tools should be displayed again")
    }
    
    /// Tests selecting a tool and navigating to its detail screen
    func testToolSelection() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Select a specific tool
        XCTAssertTrue(toolLibraryScreen.selectTool(toolName: "Respiración 4-7-8"), "Failed to select tool")
        
        // Verify tool detail screen appears
        // Look for elements that would be present on a tool detail screen
        let toolDetailTitle = app.staticTexts["Respiración 4-7-8"]
        XCTAssertTrue(toolDetailTitle.waitForExistence(timeout: TimeoutDuration.standard), "Tool detail screen did not appear")
        
        // Navigate back
        let backButton = app.navigationBars.firstMatch.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button not found")
        XCTAssertTrue(backButton.tap(), "Failed to tap back button")
        
        // Verify back on tool library screen
        XCTAssertTrue(toolLibraryScreen.waitForToolLibraryScreen(), "Did not return to tool library screen")
    }
    
    /// Tests favoriting and unfavoriting tools
    func testToolFavoriting() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Select a tool to favorite
        let toolName = "Respiración 4-7-8"
        
        // Toggle favorite status for the tool
        XCTAssertTrue(toolLibraryScreen.toggleFavoriteForTool(toolName: toolName), "Failed to toggle favorite status")
        
        // Show only favorites
        XCTAssertTrue(toolLibraryScreen.toggleFavoritesFilter(), "Failed to toggle favorites filter")
        
        // Verify the tool is in favorites
        XCTAssertTrue(toolLibraryScreen.isToolVisible(toolName: toolName), "Favorited tool should be visible in favorites")
        
        // Toggle favorite status again to unfavorite
        XCTAssertTrue(toolLibraryScreen.toggleFavoriteForTool(toolName: toolName), "Failed to toggle favorite status")
        
        // Verify the tool is no longer in favorites
        XCTAssertFalse(toolLibraryScreen.isToolVisible(toolName: toolName), "Unfavorited tool should not be visible in favorites")
        
        // Toggle favorites filter back
        XCTAssertTrue(toolLibraryScreen.toggleFavoritesFilter(), "Failed to toggle favorites filter")
    }
    
    /// Tests filtering tools using different filter options
    func testFilterOptions() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Get initial count of visible tools
        let initialToolCount = toolLibraryScreen.getToolCount()
        
        // Select a filter option
        XCTAssertTrue(toolLibraryScreen.selectFilterOption(filterOption: "Duración: Corta"), "Failed to select duration filter")
        
        // Verify tools are filtered
        let filteredCount = toolLibraryScreen.getToolCount()
        XCTAssertLessThanOrEqual(filteredCount, initialToolCount, "Filter should reduce the number of visible tools")
        
        // Select another filter option
        XCTAssertTrue(toolLibraryScreen.selectFilterOption(filterOption: "Nivel: Principiante"), "Failed to select level filter")
        
        // Verify tools are updated based on the new filter
        let newFilteredCount = toolLibraryScreen.getToolCount()
        XCTAssertLessThanOrEqual(newFilteredCount, initialToolCount, "New filter should affect the number of visible tools")
    }
    
    /// Tests sorting tools using different sort options
    func testSortOptions() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Sort alphabetically
        XCTAssertTrue(toolLibraryScreen.selectSortOption(sortOption: "Alfabético"), "Failed to select alphabetical sort")
        
        // Verify sorting (would need to check order of elements, which is complex in XCTest)
        // For now, we just verify that the sort operation completes without error
        let toolCount = toolLibraryScreen.getToolCount()
        XCTAssertGreaterThan(toolCount, 0, "Tools should be visible after sorting")
        
        // Sort by most used
        XCTAssertTrue(toolLibraryScreen.selectSortOption(sortOption: "Más usados"), "Failed to select most used sort")
        
        // Verify sorting (again, just checking the operation completes)
        let newToolCount = toolLibraryScreen.getToolCount()
        XCTAssertGreaterThan(newToolCount, 0, "Tools should be visible after sorting")
    }
    
    /// Tests filtering tools by emotion
    func testEmotionFiltering() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Get initial count of visible tools
        let initialToolCount = toolLibraryScreen.getToolCount()
        
        // Select emotion filter
        XCTAssertTrue(toolLibraryScreen.selectEmotionFilter(emotionName: "Ansiedad"), "Failed to select anxiety emotion filter")
        
        // Verify tools for anxiety are displayed
        let filteredCount = toolLibraryScreen.getToolCount()
        XCTAssertLessThanOrEqual(filteredCount, initialToolCount, "Emotion filter should reduce the number of visible tools")
        XCTAssertTrue(toolLibraryScreen.isToolVisible(toolName: "Meditación para la ansiedad"), "Anxiety tool should be visible after filter")
        
        // Select another emotion filter
        XCTAssertTrue(toolLibraryScreen.selectEmotionFilter(emotionName: "Calma"), "Failed to select calm emotion filter")
        
        // Verify tools are updated based on the new emotion
        let newFilteredCount = toolLibraryScreen.getToolCount()
        XCTAssertLessThanOrEqual(newFilteredCount, initialToolCount, "New emotion filter should affect the number of visible tools")
        
        // Clear emotion filter
        XCTAssertTrue(toolLibraryScreen.clearEmotionFilter(), "Failed to clear emotion filter")
        
        // Verify all tools are displayed again
        let afterClearCount = toolLibraryScreen.getToolCount()
        XCTAssertEqual(afterClearCount, initialToolCount, "After clearing emotion filter, all tools should be displayed again")
    }
    
    /// Tests the pull-to-refresh functionality in the Tool Library
    func testPullToRefresh() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Perform pull-to-refresh
        XCTAssertTrue(toolLibraryScreen.refreshToolLibrary(), "Failed to refresh tool library")
        
        // Verify refresh was successful (no error state)
        XCTAssertFalse(toolLibraryScreen.isErrorStateVisible(), "Error state should not be visible after refresh")
        XCTAssertGreaterThan(toolLibraryScreen.getToolCount(), 0, "Tools should be visible after refresh")
    }
    
    /// Tests handling of empty state when no tools match the current filters
    func testEmptyStateHandling() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Search for a non-existent tool
        XCTAssertTrue(toolLibraryScreen.searchForTool(searchText: "xyzabc"), "Failed to search for non-existent tool")
        
        // Verify empty state is displayed
        XCTAssertTrue(toolLibraryScreen.isEmptyStateVisible(), "Empty state should be visible when no tools match search")
        
        // Clear search
        XCTAssertTrue(toolLibraryScreen.clearSearch(), "Failed to clear search")
        
        // Verify tools are displayed again
        XCTAssertFalse(toolLibraryScreen.isEmptyStateVisible(), "Empty state should not be visible after clearing search")
        XCTAssertGreaterThan(toolLibraryScreen.getToolCount(), 0, "Tools should be visible after clearing search")
    }
    
    /// Tests handling of error state when loading tools fails
    func testErrorStateHandling() {
        // Launch app with network error simulation
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--simulateNetworkError"]
        app.launch()
        
        // Login
        XCTAssertTrue(loginScreen.login(email: testUserEmail, password: testUserPassword), "Failed to login")
        
        // Navigate to tool library
        XCTAssertTrue(homeScreen.tapFavoritesButton(), "Failed to tap favorites button")
        
        // Verify error state is displayed
        XCTAssertTrue(toolLibraryScreen.isErrorStateVisible(), "Error state should be visible when network error occurs")
        
        // Tap retry button
        XCTAssertTrue(toolLibraryScreen.retryAfterError(), "Failed to tap retry button")
        
        // Verify app attempts to reload (may still show error if network error persists)
        // For this test, we just verify the retry action completes
    }
    
    /// Tests selecting a category and then a tool within that category
    func testCategoryAndToolSelection() {
        // Launch app and navigate to tool library
        XCTAssertTrue(launchAppAndNavigateToToolLibrary(), "Failed to navigate to tool library")
        
        // Select category and tool in one operation
        XCTAssertTrue(toolLibraryScreen.selectToolWithCategoryAndName(categoryName: "Respiración", toolName: "Respiración 4-7-8"), "Failed to select tool with category and name")
        
        // Verify tool detail screen appears
        let toolDetailTitle = app.staticTexts["Respiración 4-7-8"]
        XCTAssertTrue(toolDetailTitle.waitForExistence(timeout: TimeoutDuration.standard), "Tool detail screen did not appear")
        
        // Navigate back
        let backButton = app.navigationBars.firstMatch.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button not found")
        XCTAssertTrue(backButton.tap(), "Failed to tap back button")
        
        // Verify back on tool library screen
        XCTAssertTrue(toolLibraryScreen.waitForToolLibraryScreen(), "Did not return to tool library screen")
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to launch the app and navigate to the Tool Library screen
    private func launchAppAndNavigateToToolLibrary() -> Bool {
        // Launch the app and login
        app.launch()
        
        // Login with test user credentials
        guard loginScreen.login(email: testUserEmail, password: testUserPassword) else {
            return false
        }
        
        // Navigate to the tool library
        guard homeScreen.tapFavoritesButton() else {
            return false
        }
        
        // Wait for the tool library screen to appear
        return toolLibraryScreen.waitForToolLibraryScreen()
    }
}