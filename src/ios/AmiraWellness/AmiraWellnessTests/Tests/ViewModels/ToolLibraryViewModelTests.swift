import XCTest // Version: Latest
import Combine // Version: Latest

// Internal imports
import ToolLibraryViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryViewModel.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import MockToolService // src/ios/AmiraWellness/AmiraWellnessTests/Mocks/MockToolService.swift
import TestData // src/ios/AmiraWellness/AmiraWellnessTests/Helpers/TestData.swift
import ToolServiceError // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift

/// Mock implementation of ToolNavigationDelegate for testing
class MockToolNavigationDelegate: ToolNavigationDelegate {
    var navigatedToToolId: String? = nil
    var navigatedToCategory: ToolCategory? = nil
    
    func navigateToToolDetail(toolId: String) {
        navigatedToToolId = toolId
    }
    
    func navigateToCategory(category: ToolCategory) {
        navigatedToCategory = category
    }
}

/// Test suite for the ToolLibraryViewModel class
class ToolLibraryViewModelTests: XCTestCase {
    
    /// The view model under test
    var viewModel: ToolLibraryViewModel!
    
    /// Mock tool service for injecting test data
    var mockToolService: MockToolService!
    
    /// Mock navigation delegate for testing navigation actions
    var mockNavigationDelegate: MockToolNavigationDelegate!
    
    /// Array of mock tools for testing
    var testTools: [Tool]!
    
    /// Array of mock favorite tools for testing
    var testFavoriteTools: [Tool]!
    
    /// Array of mock recommended tools for testing
    var testRecommendedTools: [Tool]!
    
    /// Array of mock tool categories for testing
    var testCategories: [ToolCategory]!
    
    /// Set to store Combine cancellables for managing subscriptions
    var cancellables: Set<AnyCancellable>!
    
    /// Set up the test environment before each test
    override func setUp() {
        super.setUp()
        
        // Initialize mockToolService with MockToolService.shared
        mockToolService = MockToolService.shared
        
        // Reset the mock tool service
        mockToolService.reset()
        
        // Initialize mockNavigationDelegate as a new MockToolNavigationDelegate()
        mockNavigationDelegate = MockToolNavigationDelegate()
        
        // Initialize testTools with an array of mock tools
        testTools = TestData.mockToolArray(count: 5)
        
        // Initialize testFavoriteTools with a subset of testTools marked as favorites
        testFavoriteTools = testTools.filter { $0.isFavorite }
        
        // Initialize testRecommendedTools with tools for anxiety
        testRecommendedTools = testTools.filter { $0.targetEmotions.contains(.anxiety) }
        
        // Initialize testCategories with ToolCategory.allCases
        testCategories = ToolCategory.allCases
        
        // Set up mock service with test data
        mockToolService.setMockCategoriesResult(result: .success(testCategories))
        mockToolService.setMockToolsResult(result: .success(testTools))
        mockToolService.setMockFavoritesResult(result: .success(testFavoriteTools))
        mockToolService.setMockRecommendedTools(emotionType: .anxiety, tools: testRecommendedTools)
        
        // Initialize viewModel with mockToolService and mockNavigationDelegate
        viewModel = ToolLibraryViewModel(toolService: mockToolService, navigationDelegate: mockNavigationDelegate)
        
        // Initialize cancellables as an empty set
        cancellables = Set<AnyCancellable>()
    }
    
    /// Clean up after each test
    override func tearDown() {
        // Set viewModel to nil
        viewModel = nil
        
        // Reset mockToolService
        mockToolService.reset()
        
        super.tearDown()
    }
    
    /// Test that the view model initializes with correct default values
    func testInitialization() {
        // Assert that viewModel.categories is empty
        XCTAssertTrue(viewModel.categories.isEmpty)
        
        // Assert that viewModel.allTools is empty
        XCTAssertTrue(viewModel.allTools.isEmpty)
        
        // Assert that viewModel.filteredTools is empty
        XCTAssertTrue(viewModel.filteredTools.isEmpty)
        
        // Assert that viewModel.favoriteTools is empty
        XCTAssertTrue(viewModel.favoriteTools.isEmpty)
        
        // Assert that viewModel.recommendedTools is empty
        XCTAssertTrue(viewModel.recommendedTools.isEmpty)
        
        // Assert that viewModel.searchQuery is empty
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        
        // Assert that viewModel.isLoading is true
        XCTAssertTrue(viewModel.isLoading)
        
        // Assert that viewModel.isRefreshing is false
        XCTAssertFalse(viewModel.isRefreshing)
        
        // Assert that viewModel.errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
        
        // Assert that viewModel.showingFavorites is false
        XCTAssertFalse(viewModel.showingFavorites)
        
        // Assert that viewModel.selectedCategory is nil
        XCTAssertNil(viewModel.selectedCategory)
        
        // Assert that viewModel.selectedEmotion is nil
        XCTAssertNil(viewModel.selectedEmotion)
        
        // Assert that viewModel.filterOption is .all
        XCTAssertEqual(viewModel.filterOption, .all)
        
        // Assert that viewModel.sortOption is .nameAsc
        XCTAssertEqual(viewModel.sortOption, .nameAsc)
    }
    
    /// Test that loadData method correctly loads data from the service
    func testLoadData() {
        // Create an expectation for data loading
        let expectation = XCTestExpectation(description: "Data loaded")
        
        // Call viewModel.loadData()
        viewModel.loadData()
        
        // Wait for expectation with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert that mockToolService.getMethodCallCount("getToolCategories") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "getToolCategories"), 1)
        
        // Assert that mockToolService.getMethodCallCount("getTools") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "getTools"), 1)
        
        // Assert that mockToolService.getMethodCallCount("getFavoriteTools") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "getFavoriteTools"), 1)
        
        // Assert that mockToolService.getMethodCallCount("getRecommendedTools") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "getRecommendedTools"), 1)
        
        // Assert that viewModel.categories equals testCategories
        XCTAssertEqual(viewModel.categories, testCategories)
        
        // Assert that viewModel.filteredTools equals testTools sorted by name
        XCTAssertEqual(viewModel.filteredTools, testTools.sorted { $0.name < $1.name })
        
        // Assert that viewModel.favoriteTools equals testFavoriteTools
        XCTAssertEqual(viewModel.favoriteTools, testFavoriteTools)
        
        // Assert that viewModel.isLoading is false
        XCTAssertFalse(viewModel.isLoading)
        
        // Assert that viewModel.errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test that loadData handles errors correctly
    func testLoadDataWithError() {
        // Set mockToolService to return an error for getTools
        mockToolService.setMockToolsResult(result: .failure(.networkError))
        
        // Create an expectation for data loading
        let expectation = XCTestExpectation(description: "Data loaded with error")
        
        // Call viewModel.loadData()
        viewModel.loadData()
        
        // Wait for expectation with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert that viewModel.errorMessage is not nil
        XCTAssertNotNil(viewModel.errorMessage)
        
        // Assert that viewModel.isLoading is false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Test that refreshData method correctly refreshes data from the service
    func testRefreshData() {
        // Create an expectation for data refreshing
        let expectation = XCTestExpectation(description: "Data refreshed")
        
        // Call viewModel.refreshData()
        viewModel.refreshData()
        
        // Wait for expectation with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert that mockToolService.getMethodCallCount("refreshToolData") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "refreshToolData"), 1)
        
        // Assert that viewModel.isRefreshing is false
        XCTAssertFalse(viewModel.isRefreshing)
        
        // Assert that viewModel.errorMessage is nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test that refreshData handles errors correctly
    func testRefreshDataWithError() {
        // Set mockToolService to return an error for refreshToolData
        mockToolService.setMockRefreshResult(result: .failure(.networkError))
        
        // Create an expectation for data refreshing
        let expectation = XCTestExpectation(description: "Data refreshed with error")
        
        // Call viewModel.refreshData()
        viewModel.refreshData()
        
        // Wait for expectation with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert that viewModel.errorMessage is not nil
        XCTAssertNotNil(viewModel.errorMessage)
        
        // Assert that viewModel.isRefreshing is false
        XCTAssertFalse(viewModel.isRefreshing)
    }
    
    /// Test that selectCategory correctly filters tools by category
    func testSelectCategory() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Call viewModel.selectCategory(ToolCategory.breathing)
        viewModel.selectCategory(category: ToolCategory.breathing)
        
        // Assert that viewModel.selectedCategory is ToolCategory.breathing
        XCTAssertEqual(viewModel.selectedCategory, ToolCategory.breathing)
        
        // Assert that viewModel.selectedEmotion is nil
        XCTAssertNil(viewModel.selectedEmotion)
        
        // Assert that viewModel.filteredTools only contains tools with category .breathing
        XCTAssertTrue(viewModel.filteredTools.allSatisfy { $0.category == .breathing })
        
        // Call viewModel.selectCategory(nil)
        viewModel.selectCategory(category: nil)
        
        // Assert that viewModel.selectedCategory is nil
        XCTAssertNil(viewModel.selectedCategory)
        
        // Assert that viewModel.filteredTools contains all tools
        XCTAssertEqual(viewModel.filteredTools.count, testTools.count)
    }
    
    /// Test that selectEmotion correctly loads recommended tools for an emotion
    func testSelectEmotion() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Call viewModel.selectEmotion(EmotionType.anxiety)
        viewModel.selectEmotion(emotion: .anxiety)
        
        // Assert that viewModel.selectedEmotion is EmotionType.anxiety
        XCTAssertEqual(viewModel.selectedEmotion, .anxiety)
        
        // Assert that viewModel.selectedCategory is nil
        XCTAssertNil(viewModel.selectedCategory)
        
        // Assert that viewModel.filteredTools equals testRecommendedTools
        XCTAssertEqual(viewModel.filteredTools, testRecommendedTools)
        
        // Call viewModel.selectEmotion(nil)
        viewModel.selectEmotion(emotion: nil)
        
        // Assert that viewModel.selectedEmotion is nil
        XCTAssertNil(viewModel.selectedEmotion)
        
        // Assert that viewModel.filteredTools contains all tools
        XCTAssertEqual(viewModel.filteredTools.count, testTools.count)
    }
    
    /// Test that toggleFavorite correctly toggles a tool's favorite status
    func testToggleFavorite() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Get a tool that is not a favorite
        guard let tool = viewModel.filteredTools.first(where: { !$0.isFavorite }) else {
            XCTFail("No non-favorite tool found")
            return
        }
        
        // Create an expectation for favorite toggling
        let toggleExpectation = XCTestExpectation(description: "Favorite toggled")
        
        // Call viewModel.toggleFavorite(tool)
        viewModel.toggleFavorite(tool: tool)
        
        // Wait for expectation with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            toggleExpectation.fulfill()
        }
        wait(for: [toggleExpectation], timeout: 1.0)
        
        // Assert that mockToolService.getMethodCallCount("toggleFavorite") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "toggleFavorite"), 1)
        
        // Find the updated tool in viewModel.filteredTools
        guard let updatedTool = viewModel.filteredTools.first(where: { $0.id == tool.id }) else {
            XCTFail("Updated tool not found in filteredTools")
            return
        }
        
        // Assert that the updated tool's isFavorite is true
        XCTAssertTrue(updatedTool.isFavorite)
    }
    
    /// Test that toggleFavorite handles errors correctly
    func testToggleFavoriteWithError() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Set mockToolService to simulate network error for toggleFavorite
        mockToolService.setNetworkConnected(connected: false)
        
        // Get a tool to toggle
        guard let tool = viewModel.filteredTools.first else {
            XCTFail("No tool found")
            return
        }
        
        // Create an expectation for favorite toggling
        let toggleExpectation = XCTestExpectation(description: "Favorite toggled with error")
        
        // Call viewModel.toggleFavorite(tool)
        viewModel.toggleFavorite(tool: tool)
        
        // Wait for expectation with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            toggleExpectation.fulfill()
        }
        wait(for: [toggleExpectation], timeout: 1.0)
        
        // Assert that viewModel.errorMessage is not nil
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    /// Test that toggleShowFavorites correctly filters to show only favorites
    func testToggleShowFavorites() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Call viewModel.toggleShowFavorites()
        viewModel.toggleShowFavorites()
        
        // Assert that viewModel.showingFavorites is true
        XCTAssertTrue(viewModel.showingFavorites)
        
        // Assert that viewModel.filteredTools equals testFavoriteTools
        XCTAssertEqual(viewModel.filteredTools, testFavoriteTools)
        
        // Call viewModel.toggleShowFavorites() again
        viewModel.toggleShowFavorites()
        
        // Assert that viewModel.showingFavorites is false
        XCTAssertFalse(viewModel.showingFavorites)
        
        // Assert that viewModel.filteredTools contains all tools
        XCTAssertEqual(viewModel.filteredTools.count, testTools.count)
    }
    
    /// Test that setFilterOption correctly applies filtering
    func testSetFilterOption() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Call viewModel.setFilterOption(.newest)
        viewModel.setFilterOption(option: .newest)
        
        // Assert that viewModel.filterOption is .newest
        XCTAssertEqual(viewModel.filterOption, .newest)
        
        // Assert that viewModel.filteredTools are sorted by creation date (newest first)
        XCTAssertEqual(viewModel.filteredTools, testTools.sorted { $0.createdAt > $1.createdAt })
        
        // Call viewModel.setFilterOption(.shortest)
        viewModel.setFilterOption(option: .shortest)
        
        // Assert that viewModel.filterOption is .shortest
        XCTAssertEqual(viewModel.filterOption, .shortest)
        
        // Assert that viewModel.filteredTools are sorted by duration (shortest first)
        XCTAssertEqual(viewModel.filteredTools, testTools.sorted { $0.estimatedDuration < $1.estimatedDuration })
    }
    
    /// Test that setSortOption correctly applies sorting
    func testSetSortOption() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Call viewModel.setSortOption(.nameDesc)
        viewModel.setSortOption(option: .nameDesc)
        
        // Assert that viewModel.sortOption is .nameDesc
        XCTAssertEqual(viewModel.sortOption, .nameDesc)
        
        // Assert that viewModel.filteredTools are sorted by name in descending order
        XCTAssertEqual(viewModel.filteredTools, testTools.sorted { $0.name > $1.name })
        
        // Call viewModel.setSortOption(.popularityDesc)
        viewModel.setSortOption(option: .popularityDesc)
        
        // Assert that viewModel.sortOption is .popularityDesc
        XCTAssertEqual(viewModel.sortOption, .popularityDesc)
        
        // Assert that viewModel.filteredTools are sorted by usage count in descending order
        XCTAssertEqual(viewModel.filteredTools, testTools.sorted { $0.usageCount > $1.usageCount })
    }
    
    /// Test that updateSearchQuery correctly filters tools by name
    func testUpdateSearchQuery() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Set a search query that matches a subset of tools
        let searchQuery = "Breathing"
        
        // Call viewModel.updateSearchQuery("Breathing")
        viewModel.updateSearchQuery(query: searchQuery)
        
        // Assert that viewModel.searchQuery is "Breathing"
        XCTAssertEqual(viewModel.searchQuery, searchQuery)
        
        // Assert that viewModel.filteredTools only contains tools with "Breathing" in the name
        XCTAssertTrue(viewModel.filteredTools.allSatisfy { $0.name.contains(searchQuery) })
        
        // Call viewModel.updateSearchQuery("")
        viewModel.updateSearchQuery(query: "")
        
        // Assert that viewModel.searchQuery is empty
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        
        // Assert that viewModel.filteredTools contains all tools
        XCTAssertEqual(viewModel.filteredTools.count, testTools.count)
    }
    
    /// Test that navigateToToolDetail correctly delegates navigation
    func testNavigateToToolDetail() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Get a tool to navigate to
        guard let tool = viewModel.filteredTools.first else {
            XCTFail("No tool found")
            return
        }
        
        // Call viewModel.navigateToToolDetail(tool)
        viewModel.navigateToToolDetail(tool: tool)
        
        // Assert that mockNavigationDelegate.navigatedToToolId equals tool.id.uuidString
        XCTAssertEqual(mockNavigationDelegate.navigatedToToolId, tool.id.uuidString)
    }
    
    /// Test that navigateToCategoryDetail correctly delegates navigation and filters
    func testNavigateToCategoryDetail() {
        // Load initial data and wait for completion
        let expectation = XCTestExpectation(description: "Data loaded")
        viewModel.loadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Call viewModel.navigateToCategoryDetail(ToolCategory.meditation)
        viewModel.navigateToCategoryDetail(category: ToolCategory.meditation)
        
        // Assert that mockNavigationDelegate.navigatedToCategory is ToolCategory.meditation
        XCTAssertEqual(mockNavigationDelegate.navigatedToCategory, ToolCategory.meditation)
        
        // Assert that viewModel.selectedCategory is ToolCategory.meditation
        XCTAssertEqual(viewModel.selectedCategory, ToolCategory.meditation)
        
        // Assert that viewModel.selectedEmotion is nil
        XCTAssertNil(viewModel.selectedEmotion)
        
        // Assert that viewModel.filteredTools only contains tools with category .meditation
        XCTAssertTrue(viewModel.filteredTools.allSatisfy { $0.category == .meditation })
    }
    
    /// Test that the view model handles offline mode correctly
    func testOfflineMode() {
        // Set mockToolService.isNetworkConnected to false
        mockToolService.setNetworkConnected(connected: false)
        
        // Create an expectation for data loading
        let expectation = XCTestExpectation(description: "Data loaded in offline mode")
        
        // Call viewModel.loadData()
        viewModel.loadData()
        
        // Wait for expectation with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert that viewModel.errorMessage contains a network error message
        XCTAssertTrue(viewModel.errorMessage?.contains("network error") ?? false)
        
        // Assert that viewModel.isLoading is false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    /// Test that the view model correctly subscribes to service publishers
    func testPublisherSubscriptions() {
        // Assert that mockToolService.getMethodCallCount("getToolUpdatedPublisher") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "getToolUpdatedPublisher"), 1)
        
        // Assert that mockToolService.getMethodCallCount("getToolsLoadedPublisher") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "getToolsLoadedPublisher"), 1)
        
        // Assert that mockToolService.getMethodCallCount("getCategoriesLoadedPublisher") is 1
        XCTAssertEqual(mockToolService.getMethodCallCount(methodName: "getCategoriesLoadedPublisher"), 1)
    }
}