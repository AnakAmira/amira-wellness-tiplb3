import XCTest // Latest - Apple's testing framework
import Combine // Latest - For testing asynchronous operations and publishers

@testable import AmiraWellness // The module being tested

// Internal imports - Ensure all imports are used
import HomeViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Home/HomeViewModel.swift
import Journal // src/ios/AmiraWellness/AmiraWellness/Models/Journal.swift
import EmotionalState // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import TestData // src/ios/AmiraWellness/AmiraWellnessTests/Helpers/TestData.swift
import MockJournalService // src/ios/AmiraWellness/AmiraWellnessTests/Mocks/MockJournalService.swift
import MockEmotionService // src/ios/AmiraWellness/AmiraWellnessTests/Mocks/MockEmotionService.swift
import MockToolService // src/ios/AmiraWellness/AmiraWellnessTests/Mocks/MockToolService.swift
import MockProgressService // src/ios/AmiraWellness/AmiraWellnessTests/Mocks/MockProgressService.swift

/// A mock implementation of the HomeNavigationProtocol for testing navigation actions
class MockHomeNavigationDelegate: HomeNavigationProtocol {
    /// Indicates whether navigateToEmotionalCheckin was called
    var navigateToEmotionalCheckinCalled: Bool = false
    /// Indicates whether navigateToRecordJournal was called
    var navigateToRecordJournalCalled: Bool = false
    /// Stores the last journal ID passed to navigateToJournalDetail
    var lastJournalDetailId: UUID?
    /// Stores the last tool ID passed to navigateToToolDetail
    var lastToolDetailId: UUID?

    /// Initializes the MockHomeNavigationDelegate with default values
    init() {
        navigateToEmotionalCheckinCalled = false
        navigateToRecordJournalCalled = false
        lastJournalDetailId = nil
        lastToolDetailId = nil
    }

    /// Resets all tracking properties to their initial state
    func reset() {
        navigateToEmotionalCheckinCalled = false
        navigateToRecordJournalCalled = false
        lastJournalDetailId = nil
        lastToolDetailId = nil
    }

    /// Mock implementation of navigateToEmotionalCheckin
    func navigateToEmotionalCheckin() {
        navigateToEmotionalCheckinCalled = true
    }

    /// Mock implementation of navigateToJournalDetail
    /// - Parameter journalId: The ID of the journal to navigate to
    func navigateToJournalDetail(journalId: UUID) {
        lastJournalDetailId = journalId
    }

    /// Mock implementation of navigateToToolDetail
    /// - Parameter toolId: The ID of the tool to navigate to
    func navigateToToolDetail(toolId: UUID) {
        lastToolDetailId = toolId
    }
    
    /// Mock implementation of navigateToRecordJournal
    func navigateToRecordJournal() {
        navigateToRecordJournalCalled = true
    }
}

/// Test suite for the HomeViewModel class
class HomeViewModelTests: XCTestCase {
    /// The view model being tested
    var viewModel: HomeViewModel!
    /// Mock implementation of JournalService
    var mockJournalService: MockJournalService!
    /// Mock implementation of EmotionService
    var mockEmotionService: MockEmotionService!
    /// Mock implementation of ToolService
    var mockToolService: MockToolService!
    /// Mock implementation of ProgressService
    var mockProgressService: MockProgressService!
    /// Mock implementation of HomeNavigationProtocol
    var mockNavigationDelegate: MockHomeNavigationDelegate!
    /// Set to hold Combine subscriptions
    var cancellables = Set<AnyCancellable>()

    /// Default initializer
    override init() {
        super.init()
    }

    /// Set up method called before each test
    override func setUp() {
        super.setUp()
        mockJournalService = MockJournalService.shared
        mockEmotionService = MockEmotionService()
        mockToolService = MockToolService.shared
        mockProgressService = MockProgressService()
        mockNavigationDelegate = MockHomeNavigationDelegate()
        mockJournalService.reset()
        mockEmotionService.reset()
        mockToolService.reset()
        mockProgressService.reset()
        cancellables = Set<AnyCancellable>()
        viewModel = HomeViewModel(journalService: mockJournalService, emotionService: mockEmotionService, toolService: mockToolService, progressService: mockProgressService)
        viewModel.navigationDelegate = mockNavigationDelegate
    }

    /// Tear down method called after each test
    override func tearDown() {
        viewModel = nil
        mockJournalService.reset()
        mockEmotionService.reset()
        mockToolService.reset()
        mockProgressService.reset()
        super.tearDown()
    }

    /// Test that the view model initializes with the correct default state
    func testInitialState() {
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertTrue(viewModel.userName.isEmpty)
        XCTAssertTrue(viewModel.recentJournals.isEmpty)
        XCTAssertTrue(viewModel.recentEmotionalCheckins.isEmpty)
        XCTAssertTrue(viewModel.recommendedTools.isEmpty)
        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertEqual(viewModel.nextMilestone, 0)
        XCTAssertEqual(viewModel.streakProgress, 0.0)
        XCTAssertNil(viewModel.currentEmotionalState)
    }

    /// Test that refreshData loads all required data from services
    func testRefreshData_LoadsAllData() {
        let mockJournals = TestData.mockJournalArray()
        mockJournalService.getJournalsResult = { completion in
            completion(.success(mockJournals))
        }
        let mockEmotionalState = TestData.mockEmotionalState()
        mockEmotionService.getEmotionalHistoryResult = { completion in
            completion(.success([mockEmotionalState]))
        }
        let mockTools = TestData.mockToolArray()
        mockToolService.mockRecommendedTools[.anxiety] = mockTools
        mockToolService.setMockRecommendedTools(emotionType: .anxiety, tools: mockTools)
        mockProgressService.currentStreakValue = 5
        mockProgressService.nextMilestoneValue = 7
        mockProgressService.milestoneProgressValue = 0.7
        
        let expectation = XCTestExpectation(description: "Data loads successfully")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.mockJournalService.getJournalsCallCount, 1)
            XCTAssertEqual(self.mockEmotionService.getEmotionalHistoryCallCount, 1)
            XCTAssertEqual(self.mockToolService.getMethodCallCount(methodName: "getRecommendedTools"), 1)
            XCTAssertFalse(self.viewModel.recentJournals.isEmpty)
            XCTAssertEqual(self.viewModel.currentStreak, 5)
            XCTAssertEqual(self.viewModel.nextMilestone, 7)
            XCTAssertEqual(self.viewModel.streakProgress, 0.7)
            XCTAssertEqual(self.mockProgressService.recordActivityCallCount, 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that refreshData handles empty data gracefully
    func testRefreshData_HandlesEmptyData() {
        mockJournalService.getJournalsResult = { completion in
            completion(.success([]))
        }
        mockEmotionService.getEmotionalHistoryResult = { completion in
            completion(.success([]))
        }
        mockToolService.mockRecommendedTools[.anxiety] = []
        
        let expectation = XCTestExpectation(description: "Empty data handles successfully")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertTrue(self.viewModel.recentJournals.isEmpty)
            XCTAssertTrue(self.viewModel.recentEmotionalCheckins.isEmpty)
            XCTAssertTrue(self.viewModel.recommendedTools.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that refreshData handles service errors gracefully
    func testRefreshData_HandlesErrors() {
        mockJournalService.getJournalsResult = { completion in
            completion(.failure(.storageError))
        }
        
        let expectation = XCTestExpectation(description: "Error handles successfully")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertTrue(self.viewModel.recentJournals.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that journals are sorted by date and limited to the most recent ones
    func testLoadRecentJournals_SortsAndLimitsJournals() {
        let journal1 = TestData.mockJournal(withPostEmotionalState: true, isFavorite: false)
        let journal2 = TestData.mockJournal(withPostEmotionalState: true, isFavorite: false)
        let journal3 = TestData.mockJournal(withPostEmotionalState: true, isFavorite: false)
        let journal4 = TestData.mockJournal(withPostEmotionalState: true, isFavorite: false)
        let journal5 = TestData.mockJournal(withPostEmotionalState: true, isFavorite: false)
        
        let journals = [journal1, journal2, journal3, journal4, journal5].shuffled()
        mockJournalService.getJournalsResult = { completion in
            completion(.success(journals))
        }
        
        let expectation = XCTestExpectation(description: "Journals are sorted and limited")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.recentJournals.count, 3)
            XCTAssertEqual(self.viewModel.recentJournals, journals.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that emotional check-ins are filtered, sorted, and limited correctly
    func testLoadRecentEmotionalCheckins_FiltersAndSorts() {
        let state1 = TestData.mockEmotionalState()
        let state2 = TestData.mockEmotionalState()
        let state3 = TestData.mockEmotionalState()
        let state4 = TestData.mockEmotionalState()
        let state5 = TestData.mockEmotionalState()
        
        let states = [state1, state2, state3, state4, state5].shuffled()
        mockEmotionService.getEmotionalHistoryResult = { completion in
            completion(.success(states))
        }
        
        let expectation = XCTestExpectation(description: "Emotional check-ins are filtered and sorted")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.recentEmotionalCheckins.count, 3)
            XCTAssertEqual(self.viewModel.recentEmotionalCheckins, states.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3))
            XCTAssertEqual(self.viewModel.currentEmotionalState, states.sorted(by: { $0.createdAt > $1.createdAt }).first)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that recommended tools are loaded based on current emotional state
    func testLoadRecommendedTools_BasedOnCurrentEmotionalState() {
        let anxietyState = TestData.mockEmotionalState(emotionType: .anxiety)
        mockEmotionService.getEmotionalHistoryResult = { completion in
            completion(.success([anxietyState]))
        }
        let anxietyTools = TestData.mockToolArray(count: 3)
        mockToolService.mockRecommendedTools[.anxiety] = anxietyTools
        
        let expectation = XCTestExpectation(description: "Recommended tools are loaded based on emotional state")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.currentEmotionalState?.emotionType, .anxiety)
            XCTAssertEqual(self.viewModel.recommendedTools, anxietyTools)
            XCTAssertEqual(self.mockToolService.getMethodCallCount(methodName: "getRecommendedTools"), 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that general recommendations are loaded when no current emotional state exists
    func testLoadRecommendedTools_WithoutCurrentEmotionalState() {
        mockEmotionService.getEmotionalHistoryResult = { completion in
            completion(.success([]))
        }
        let generalTools = TestData.mockToolArray(count: 3)
        mockToolService.mockRecommendedTools = [:]
        
        let expectation = XCTestExpectation(description: "General recommendations are loaded when no emotional state exists")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(self.viewModel.currentEmotionalState)
            XCTAssertTrue(self.viewModel.recommendedTools.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that streak information is loaded correctly from the progress service
    func testLoadStreakInfo_SetsCorrectValues() {
        mockProgressService.currentStreakValue = 10
        mockProgressService.nextMilestoneValue = 14
        mockProgressService.milestoneProgressValue = 0.6
        
        let expectation = XCTestExpectation(description: "Streak information is loaded correctly")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.currentStreak, 10)
            XCTAssertEqual(self.viewModel.nextMilestone, 14)
            XCTAssertEqual(self.viewModel.streakProgress, 0.6)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that visiting the home screen records an activity in the progress service
    func testRecordHomeVisit_CallsProgressService() {
        let expectation = XCTestExpectation(description: "Home visit is recorded")
        
        viewModel.refreshData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.mockProgressService.recordActivityCallCount, 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that the view model updates when a new journal is created
    func testSetupSubscriptions_JournalCreated() {
        let expectation = XCTestExpectation(description: "View model updates when a new journal is created")
        
        viewModel.refreshData()
        
        let newJournal = TestData.mockJournal()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mockJournalService.journalCreatedSubject.send(newJournal)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertTrue(self.viewModel.recentJournals.contains(newJournal))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that the view model updates when a new emotional state is recorded
    func testSetupSubscriptions_EmotionalStateUpdated() {
        let expectation = XCTestExpectation(description: "View model updates when a new emotional state is recorded")
        
        viewModel.refreshData()
        
        let newState = TestData.mockEmotionalState(emotionType: .joy)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mockEmotionService.publishMockEmotionalState(emotionalState: newState)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertEqual(self.viewModel.currentEmotionalState, newState)
                XCTAssertGreaterThan(self.mockToolService.getMethodCallCount(methodName: "getRecommendedTools"), 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that the view model updates when progress data changes
    func testSetupSubscriptions_ProgressUpdated() {
        let expectation = XCTestExpectation(description: "View model updates when progress data changes")
        
        viewModel.refreshData()
        
        mockProgressService.currentStreakValue = 15
        mockProgressService.nextMilestoneValue = 21
        mockProgressService.milestoneProgressValue = 0.8
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mockProgressService.publishProgressUpdate(update: ())
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertEqual(self.viewModel.currentStreak, 15)
                XCTAssertEqual(self.viewModel.nextMilestone, 21)
                XCTAssertEqual(self.viewModel.streakProgress, 0.8)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that navigateToEmotionalCheckin calls the navigation delegate
    func testNavigateToEmotionalCheckin_CallsDelegate() {
        viewModel.navigateToEmotionalCheckin()
        XCTAssertTrue(mockNavigationDelegate.navigateToEmotionalCheckinCalled)
    }

    /// Test that navigateToJournalDetail calls the navigation delegate with correct ID
    func testNavigateToJournalDetail_CallsDelegate() {
        let testId = UUID()
        viewModel.navigateToJournalDetail(journalId: testId)
        XCTAssertEqual(mockNavigationDelegate.lastJournalDetailId, testId)
    }

    /// Test that navigateToToolDetail calls the navigation delegate with correct ID
    func testNavigateToToolDetail_CallsDelegate() {
        let testId = UUID()
        viewModel.navigateToToolDetail(toolId: testId)
        XCTAssertEqual(mockNavigationDelegate.lastToolDetailId, testId)
    }
    
    /// Test that navigateToRecordJournal calls the navigation delegate
    func testNavigateToRecordJournal_CallsDelegate() {
        viewModel.navigateToRecordJournal()
        XCTAssertTrue(mockNavigationDelegate.navigateToRecordJournalCalled)
    }
}