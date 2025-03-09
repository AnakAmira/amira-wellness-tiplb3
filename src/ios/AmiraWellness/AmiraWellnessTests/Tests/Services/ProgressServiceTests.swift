# src/ios/AmiraWellness/AmiraWellnessTests/Tests/Services/ProgressServiceTests.swift
import XCTest // Latest
import Combine // Latest

// Internal imports
@testable import AmiraWellness // src/ios/AmiraWellness/AmiraWellness/Services/Progress/ProgressService.swift
import MockAPIClient // src/ios/AmiraWellness/AmiraWellnessTests/Mocks/MockAPIClient.swift

/// A mock implementation of the StreakService for testing
class MockStreakService: StreakService {
    var getStreakInfoCalled = false
    var updateStreakCalled = false
    var mockStreak: Streak?
    var mockCurrentStreak: Int = 0
    var mockLongestStreak: Int = 0
    var mockNextMilestone: Int = 7
    var mockMilestoneProgress: Double = 0.0
    var mockIsStreakActive: Bool = false
    var mockStreakPublisher = CurrentValueSubject<Streak?, Never>(nil)
    var mockError: APIError?

    /// Initializes the MockStreakService with default values
    override init(apiClient: APIClient? = nil, storageService: StorageService? = nil) {
        super.init(apiClient: apiClient ?? MockAPIClient.shared, storageService: storageService)
        getStreakInfoCalled = false
        updateStreakCalled = false
        mockStreak = nil
        mockCurrentStreak = 0
        mockLongestStreak = 0
        mockNextMilestone = 7
        mockMilestoneProgress = 0.0
        mockIsStreakActive = false
        mockStreakPublisher = CurrentValueSubject<Streak?, Never>(nil)
        mockError = nil
    }

    /// Mock implementation of getStreakInfo
    override func getStreakInfo(completion: @escaping (Result<Streak, APIError>) -> Void) {
        getStreakInfoCalled = true
        if let mockError = mockError {
            completion(.failure(mockError))
        } else if let mockStreak = mockStreak {
            completion(.success(mockStreak))
        } else {
            let defaultStreak = Streak(userId: UUID(), currentStreak: 5, longestStreak: 10, activityDates: [Date()])
            completion(.success(defaultStreak))
        }
    }

    /// Mock implementation of async getStreakInfo
    @available(iOS 15.0, *)
    override func getStreakInfo() async throws -> Streak {
        getStreakInfoCalled = true
        if let mockError = mockError {
            throw mockError
        } else if let mockStreak = mockStreak {
            return mockStreak
        } else {
            return Streak(userId: UUID(), currentStreak: 5, longestStreak: 10, activityDates: [Date()])
        }
    }
    
    /// Mock implementation of getCachedStreakInfo
    override func getCachedStreakInfo() -> Streak? {
        return mockStreak
    }

    /// Mock implementation of updateStreak
    override func updateStreak(activityDate: Date, completion: ((Bool) -> Void)? = nil) {
        updateStreakCalled = true
        if let mockError = mockError {
            completion?(false)
        } else {
            completion?(true)
            mockStreak?.activityDates.append(activityDate)
        }
    }

    /// Mock implementation of async updateStreak
    @available(iOS 15.0, *)
    override func updateStreak(activityDate: Date) async -> Bool {
        updateStreakCalled = true
        if let mockError = mockError {
            return false
        } else {
            mockStreak?.activityDates.append(activityDate)
            return true
        }
    }

    /// Mock implementation of getCurrentStreak
    override func getCurrentStreak() -> Int {
        return mockCurrentStreak
    }

    /// Mock implementation of getLongestStreak
    override func getLongestStreak() -> Int {
        return mockLongestStreak
    }

    /// Mock implementation of getNextMilestone
    override func getNextMilestone() -> Int {
        return mockNextMilestone
    }

    /// Mock implementation of getProgressToNextMilestone
    override func getProgressToNextMilestone() -> Double {
        return mockMilestoneProgress
    }

    /// Mock implementation of isStreakActive
    override func isStreakActive() -> Bool {
        return mockIsStreakActive
    }
}

/// A mock implementation of the AchievementService for testing
class MockAchievementService: AchievementService {
    var getAchievementsCalled = false
    var mockAchievements: [Achievement] = []
    var mockAchievementProgress: Double = 0.0
    var mockAchievementsPublisher = CurrentValueSubject<[Achievement], Never>([])
    var mockError: APIError?

    /// Initializes the MockAchievementService with default values
    override init(apiClient: APIClient? = nil, storageService: StorageService? = nil) {
        super.init(apiClient: apiClient ?? MockAPIClient.shared, storageService: storageService)
        getAchievementsCalled = false
        mockAchievements = []
        mockAchievementProgress = 0.0
        mockAchievementsPublisher = CurrentValueSubject<[Achievement], Never>([])
        mockError = nil
    }

    /// Mock implementation of getAchievements
    override func getAchievements(completion: @escaping (Result<AchievementResponse, APIError>) -> Void) {
        getAchievementsCalled = true
        if let mockError = mockError {
            completion(.failure(mockError))
        } else {
            let achievementResponse = AchievementResponse(achievements: mockAchievements, totalEarned: 1, totalAvailable: 3)
            completion(.success(achievementResponse))
        }
    }

    /// Mock implementation of async getAchievements
    @available(iOS 15.0, *)
    override func getAchievements() async throws -> AchievementResponse {
        getAchievementsCalled = true
        if let mockError = mockError {
            throw mockError
        } else {
            return AchievementResponse(achievements: mockAchievements, totalEarned: 1, totalAvailable: 3)
        }
    }

    /// Mock implementation of getEarnedAchievements
    override func getEarnedAchievements() -> [Achievement] {
        return mockAchievements.filter { $0.isEarned() }
    }

    /// Mock implementation of getAchievementProgress
    override func getAchievementProgress() -> Double {
        return mockAchievementProgress
    }

    /// Mock implementation of hasEarnedAchievement
    override func hasEarnedAchievement(type: AchievementType) -> Bool {
        if let achievement = mockAchievements.first(where: { $0.type == type }) {
            return achievement.isEarned()
        }
        return false
    }
}

/// A mock implementation of the EmotionService for testing
class MockEmotionService: EmotionService {
    var getEmotionalTrendsCalled = false
    var mockTrendResponse: EmotionalTrendResponse?
    var mockInsightPublisher = PassthroughSubject<EmotionalInsight, Never>()
    var mockError: EmotionServiceError?

    /// Initializes the MockEmotionService with default values
    override init(apiClient: APIClient? = nil, secureStorageService: SecureStorageService? = nil, analysisService: EmotionAnalysisService? = nil) {
        super.init(apiClient: apiClient, secureStorageService: secureStorageService, analysisService: analysisService)
        getEmotionalTrendsCalled = false
        mockTrendResponse = nil
        mockInsightPublisher = PassthroughSubject<EmotionalInsight, Never>()
        mockError = nil
    }

    /// Mock implementation of getEmotionalTrends
    override func getEmotionalTrends(periodType: TrendPeriodType, startDate: Date? = nil, endDate: Date? = nil, emotionTypes: [EmotionType]? = nil, completion: @escaping (Result<EmotionalTrendResponse, EmotionServiceError>) -> Void) {
        getEmotionalTrendsCalled = true
        if let mockError = mockError {
            completion(.failure(mockError))
        } else if let mockTrendResponse = mockTrendResponse {
            completion(.success(mockTrendResponse))
        } else {
            let defaultTrendResponse = EmotionalTrendResponse(trends: [], insights: [])
            completion(.success(defaultTrendResponse))
        }
    }

    /// Mock implementation of async getEmotionalTrends
    @available(iOS 15.0, *)
    override func getEmotionalTrendsAsync(periodType: TrendPeriodType, startDate: Date? = nil, endDate: Date? = nil, emotionTypes: [EmotionType]? = nil) async throws -> EmotionalTrendResponse {
        getEmotionalTrendsCalled = true
        if let mockError = mockError {
            throw mockError
        } else if let mockTrendResponse = mockTrendResponse {
            return mockTrendResponse
        } else {
            return EmotionalTrendResponse(trends: [], insights: [])
        }
    }
    
    /// Mock implementation of getInsightPublisher
    override func getInsightPublisher() -> AnyPublisher<EmotionalInsight, Never> {
        return mockInsightPublisher.eraseToAnyPublisher()
    }
}

/// Unit tests for the ProgressService class
class ProgressServiceTests: XCTestCase {
    var progressService: ProgressService!
    var mockStreakService: MockStreakService!
    var mockAchievementService: MockAchievementService!
    var mockEmotionService: MockEmotionService!
    var mockAPIClient: MockAPIClient!
    var cancellables: Set<AnyCancellable>!

    /// Set up the test environment before each test
    override func setUp() {
        super.setUp()
        mockStreakService = MockStreakService()
        mockAchievementService = MockAchievementService()
        mockEmotionService = MockEmotionService()
        mockAPIClient = MockAPIClient.shared
        mockAPIClient.reset()
        cancellables = Set<AnyCancellable>()
        progressService = ProgressService(streakService: mockStreakService, achievementService: mockAchievementService, emotionService: mockEmotionService, apiClient: mockAPIClient)
    }

    /// Clean up the test environment after each test
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        super.tearDown()
    }

    /// Test that refreshProgressData successfully refreshes all progress data
    func testRefreshProgressData_Success() {
        // Set up mock streak data
        mockStreakService.mockStreak = Streak(userId: UUID(), currentStreak: 5, longestStreak: 10, activityDates: [Date()])

        // Set up mock achievement data
        mockAchievementService.mockAchievements = [Achievement(id: UUID(), type: .firstStep, category: .milestone, name: "First Step", description: "Complete your first check-in", iconUrl: "", points: 10, isHidden: false)]

        // Set up mock emotional trend data
        mockEmotionService.mockTrendResponse = EmotionalTrendResponse(trends: [], insights: [])

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Refresh progress data")

        // Call progressService.refreshProgressData with a completion handler
        progressService.refreshProgressData { result in
            // Verify that all service methods were called
            XCTAssertTrue(self.mockStreakService.getStreakInfoCalled)
            XCTAssertTrue(self.mockAchievementService.getAchievementsCalled)
            XCTAssertTrue(self.mockEmotionService.getEmotionalTrendsCalled)

            // Verify that the completion handler was called with success
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Expected success, but received failure: \(error)")
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that refreshProgressData handles streak service errors
    func testRefreshProgressData_StreakError() {
        // Set up mock streak service to return an error
        mockStreakService.mockError = APIError.networkError(message: "Failed to fetch streak data")

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Refresh progress data with streak error")

        // Call progressService.refreshProgressData with a completion handler
        progressService.refreshProgressData { result in
            // Verify that the completion handler was called with an error
            switch result {
            case .success:
                XCTFail("Expected failure, but received success")
            case .failure(let error):
                XCTAssertEqual(error, ProgressServiceError.networkError)
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that refreshProgressDataAsync successfully refreshes all progress data
    @available(iOS 15.0, *)
    func testRefreshProgressDataAsync_Success() async {
        // Set up mock streak data
        mockStreakService.mockStreak = Streak(userId: UUID(), currentStreak: 5, longestStreak: 10, activityDates: [Date()])

        // Set up mock achievement data
        mockAchievementService.mockAchievements = [Achievement(id: UUID(), type: .firstStep, category: .milestone, name: "First Step", description: "Complete your first check-in", iconUrl: "", points: 10, isHidden: false)]

        // Set up mock emotional trend data
        mockEmotionService.mockTrendResponse = EmotionalTrendResponse(trends: [], insights: [])

        // Create an async task
        do {
            // Call progressService.refreshProgressDataAsync()
            try await progressService.refreshProgressDataAsync()

            // Verify that all service methods were called
            XCTAssertTrue(mockStreakService.getStreakInfoCalled)
            XCTAssertTrue(mockAchievementService.getAchievementsCalled)
            XCTAssertTrue(mockEmotionService.getEmotionalTrendsCalled)
        } catch {
            XCTFail("Expected success, but received error: \(error)")
        }
    }

    /// Test that recordActivity successfully records a user activity
    func testRecordActivity_Success() {
        // Set up mock streak service to return success
        mockStreakService.mockError = nil

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Record activity")

        // Call progressService.recordActivity with a completion handler
        progressService.recordActivity { result in
            // Verify that updateStreak was called on the streak service
            XCTAssertTrue(self.mockStreakService.updateStreakCalled)

            // Verify that the completion handler was called with success
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Expected success, but received failure: \(error)")
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that recordActivity handles errors
    func testRecordActivity_Error() {
        // Set up mock streak service to return an error
        mockStreakService.mockError = APIError.networkError(message: "Failed to update streak")

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Record activity with error")

        // Call progressService.recordActivity with a completion handler
        progressService.recordActivity { result in
            // Verify that the completion handler was called with an error
            switch result {
            case .success:
                XCTFail("Expected failure, but received success")
            case .failure(let error):
                XCTAssertEqual(error, ProgressServiceError.networkError)
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that recordActivityAsync successfully records a user activity
    @available(iOS 15.0, *)
    func testRecordActivityAsync_Success() async {
        // Set up mock streak service to return success
        mockStreakService.mockError = nil

        // Create an async task
        do {
            // Call progressService.recordActivityAsync()
            let success = try await progressService.recordActivityAsync()

            // Verify that updateStreak was called on the streak service
            XCTAssertTrue(mockStreakService.updateStreakCalled)

            // Verify that the function returned true
            XCTAssertTrue(success)
        } catch {
            XCTFail("Expected success, but received error: \(error)")
        }
    }

    /// Test that getProgressSummary returns a valid progress summary
    func testGetProgressSummary_Success() {
        // Set up mock streak data
        mockStreakService.mockCurrentStreak = 5
        mockStreakService.mockLongestStreak = 10
        mockStreakService.mockIsStreakActive = true

        // Set up mock achievement data
        mockAchievementService.mockAchievementProgress = 0.5
        mockAchievementService.mockAchievements = [Achievement(id: UUID(), type: .firstStep, category: .milestone, name: "First Step", description: "Complete your first check-in", iconUrl: "", points: 10, isHidden: false)]

        // Set up mock emotional trend data
        mockEmotionService.mockTrendResponse = EmotionalTrendResponse(trends: [], insights: [])

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Get progress summary")

        // Call progressService.getProgressSummary with a completion handler
        progressService.getProgressSummary { result in
            // Verify that the completion handler was called with a valid ProgressSummary
            switch result {
            case .success(let summary):
                // Verify that the summary contains the expected values
                XCTAssertEqual(summary.currentStreak, 5)
                XCTAssertEqual(summary.longestStreak, 10)
                XCTAssertEqual(summary.achievementProgress, 0.5)
                XCTAssertEqual(summary.achievementsEarned, 1)
                XCTAssertEqual(summary.totalAchievements, 3)
                XCTAssertEqual(summary.isStreakActive, true)

            case .failure(let error):
                XCTFail("Expected success, but received failure: \(error)")
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that getProgressSummaryAsync returns a valid progress summary
    @available(iOS 15.0, *)
    func testGetProgressSummaryAsync_Success() async {
        // Set up mock streak data
        mockStreakService.mockCurrentStreak = 5
        mockStreakService.mockLongestStreak = 10
        mockStreakService.mockIsStreakActive = true

        // Set up mock achievement data
        mockAchievementService.mockAchievementProgress = 0.5
        mockAchievementService.mockAchievements = [Achievement(id: UUID(), type: .firstStep, category: .milestone, name: "First Step", description: "Complete your first check-in", iconUrl: "", points: 10, isHidden: false)]

        // Set up mock emotional trend data
        mockEmotionService.mockTrendResponse = EmotionalTrendResponse(trends: [], insights: [])

        // Create an async task
        do {
            // Call progressService.getProgressSummaryAsync()
            let summary = try await progressService.getProgressSummaryAsync()

            // Verify that the function returned a valid ProgressSummary
            XCTAssertEqual(summary.currentStreak, 5)
            XCTAssertEqual(summary.longestStreak, 10)
            XCTAssertEqual(summary.achievementProgress, 0.5)
            XCTAssertEqual(summary.achievementsEarned, 1)
            XCTAssertEqual(summary.totalAchievements, 3)
            XCTAssertEqual(summary.isStreakActive, true)
        } catch {
            XCTFail("Expected success, but received error: \(error)")
        }
    }

    /// Test that getWeeklyActivityData returns valid activity data
    func testGetWeeklyActivityData_Success() {
        // Set up mock streak with activity dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        mockStreakService.mockStreak = Streak(userId: UUID(), currentStreak: 3, longestStreak: 3, lastActivityDate: today, activityDates: [today, yesterday, twoDaysAgo])

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Get weekly activity data")

        // Call progressService.getWeeklyActivityData with a completion handler
        progressService.getWeeklyActivityData { result in
            // Verify that the completion handler was called with valid activity data
            switch result {
            case .success(let activityData):
                // Verify that the data contains the expected dates and counts
                XCTAssertEqual(activityData[today], 1)
                XCTAssertEqual(activityData[yesterday], 1)
                XCTAssertEqual(activityData[twoDaysAgo], 1)
            case .failure(let error):
                XCTFail("Expected success, but received failure: \(error)")
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that getWeeklyActivityDataAsync returns valid activity data
    @available(iOS 15.0, *)
    func testGetWeeklyActivityDataAsync_Success() async {
        // Set up mock streak with activity dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        mockStreakService.mockStreak = Streak(userId: UUID(), currentStreak: 3, longestStreak: 3, lastActivityDate: today, activityDates: [today, yesterday, twoDaysAgo])

        // Create an async task
        do {
            // Call progressService.getWeeklyActivityDataAsync()
            let activityData = try await progressService.getWeeklyActivityDataAsync()

            // Verify that the function returned valid activity data
            XCTAssertEqual(activityData[today], 1)
            XCTAssertEqual(activityData[yesterday], 1)
            XCTAssertEqual(activityData[twoDaysAgo], 1)
        } catch {
            XCTFail("Expected success, but received error: \(error)")
        }
    }

    /// Test that getEmotionalTrends returns valid trend data
    func testGetEmotionalTrends_Success() {
        // Set up mock emotional trend data
        mockEmotionService.mockTrendResponse = EmotionalTrendResponse(trends: [], insights: [])

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Get emotional trends")

        // Call progressService.getEmotionalTrends with a completion handler
        progressService.getEmotionalTrends(periodType: .weekly) { result in
            // Verify that getEmotionalTrends was called on the emotion service
            XCTAssertTrue(self.mockEmotionService.getEmotionalTrendsCalled)

            // Verify that the completion handler was called with valid trend data
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Expected success, but received failure: \(error)")
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that getEmotionalTrendsAsync returns valid trend data
    @available(iOS 15.0, *)
    func testGetEmotionalTrendsAsync_Success() async {
        // Set up mock emotional trend data
        mockEmotionService.mockTrendResponse = EmotionalTrendResponse(trends: [], insights: [])

        // Create an async task
        do {
            // Call progressService.getEmotionalTrendsAsync()
            _ = try await progressService.getEmotionalTrendsAsync(periodType: .weekly)

            // Verify that getEmotionalTrendsAsync was called on the emotion service
            XCTAssertTrue(mockEmotionService.getEmotionalTrendsCalled)
        } catch {
            XCTFail("Expected success, but received error: \(error)")
        }
    }

    /// Test that getProgressInsights returns valid insights
    func testGetProgressInsights_Success() {
        // Set up mock API response with insights
        let mockInsights: [ProgressInsight] = [
            ProgressInsight(id: UUID().uuidString, title: "Great Job", description: "Keep it up!", type: .streak, relevance: 0.8, actionableSteps: [])
        ]
        mockAPIClient.setMockResponse(endpoint: .getProgressInsights, result: .success(mockInsights))

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Get progress insights")

        // Call progressService.getProgressInsights with a completion handler
        progressService.getProgressInsights { result in
            // Verify that the API request was made
            XCTAssertEqual(self.mockAPIClient.getRequestCount(endpoint: .getProgressInsights), 1)

            // Verify that the completion handler was called with valid insights
            switch result {
            case .success(let insights):
                XCTAssertEqual(insights.count, 1)
                XCTAssertEqual(insights.first?.title, "Great Job")
            case .failure(let error):
                XCTFail("Expected success, but received failure: \(error)")
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that getProgressInsights falls back to local insights on API error
    func testGetProgressInsights_FallbackToLocal() {
        // Set up mock API error
        mockAPIClient.setMockResponse(endpoint: .getProgressInsights, result: .failure(APIError.networkError(message: "API Unavailable")))

        // Set up mock streak and achievement data for local insights
        mockStreakService.mockCurrentStreak = 5
        mockAchievementService.mockAchievementProgress = 0.5

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Get progress insights with fallback")

        // Call progressService.getProgressInsights with a completion handler
        progressService.getProgressInsights { result in
            // Verify that the API request was made
            XCTAssertEqual(self.mockAPIClient.getRequestCount(endpoint: .getProgressInsights), 1)

            // Verify that the completion handler was called with locally generated insights
            switch result {
            case .success(let insights):
                XCTAssertGreaterThan(insights.count, 0)
            case .failure(let error):
                XCTFail("Expected success, but received failure: \(error)")
            }

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

    /// Test that getProgressInsightsAsync returns valid insights
    @available(iOS 15.0, *)
    func testGetProgressInsightsAsync_Success() async {
        // Set up mock API response with insights
        let mockInsights: [ProgressInsight] = [
            ProgressInsight(id: UUID().uuidString, title: "Great Job", description: "Keep it up!", type: .streak, relevance: 0.8, actionableSteps: [])
        ]
        mockAPIClient.setMockResponse(endpoint: .getProgressInsights, result: .success(mockInsights))

        // Create an async task
        do {
            // Call progressService.getProgressInsightsAsync()
            let insights = try await progressService.getProgressInsightsAsync()

            // Verify that the API request was made
            XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getProgressInsights), 1)

            // Verify that the function returned valid insights
            XCTAssertEqual(insights.count, 1)
            XCTAssertEqual(insights.first?.title, "Great Job")
        } catch {
            XCTFail("Expected success, but received error: \(error)")
        }
    }

    /// Test that delegation methods correctly forward to the appropriate services
    func testDelegationMethods() {
        // Set up mock streak and achievement services with test values
        mockStreakService.mockCurrentStreak = 5
        mockStreakService.mockLongestStreak = 10
        mockStreakService.mockNextMilestone = 7
        mockStreakService.mockMilestoneProgress = 0.75
        mockStreakService.mockIsStreakActive = true
        mockAchievementService.mockAchievementProgress = 0.5
        mockAchievementService.mockAchievements = [
            Achievement(id: UUID(), type: .firstStep, category: .milestone, name: "First Step", description: "Complete your first check-in", iconUrl: "", points: 10, isHidden: false),
            Achievement(id: UUID(), type: .streak7Days, category: .streak, name: "7-Day Streak", description: "Use the app for 7 consecutive days", iconUrl: "", points: 20, isHidden: false)
        ]

        // Call various delegation methods on progressService
        let currentStreak = progressService.getCurrentStreak()
        let longestStreak = progressService.getLongestStreak()
        let nextMilestone = progressService.getNextMilestone()
        let milestoneProgress = progressService.getProgressToNextMilestone()
        let isStreakActive = progressService.isStreakActive()
        let achievementProgress = progressService.getAchievementProgress()
        let earnedAchievements = progressService.getEarnedAchievements()
        let hasFirstStep = progressService.hasEarnedAchievement(type: .firstStep)

        // Verify that each method returns the expected value from the appropriate service
        XCTAssertEqual(currentStreak, 5)
        XCTAssertEqual(longestStreak, 10)
        XCTAssertEqual(nextMilestone, 7)
        XCTAssertEqual(milestoneProgress, 0.75)
        XCTAssertEqual(isStreakActive, true)
        XCTAssertEqual(achievementProgress, 0.5)
        XCTAssertEqual(earnedAchievements.count, 0)
        XCTAssertFalse(hasFirstStep)
    }

    /// Test that the progress publisher emits updates when dependencies publish changes
    func testProgressPublisher() {
        // Create an expectation for the publisher
        let expectation = XCTestExpectation(description: "Progress publisher emits updates")
        expectation.expectedFulfillmentCount = 2

        // Subscribe to progressService.progressPublisher
        progressService.progressPublisher
            .sink { _ in
                // Verify that the progress publisher emits an update
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger an update from the streak publisher
        mockStreakService.mockStreakPublisher.send(Streak(userId: UUID(), currentStreak: 1, longestStreak: 1, activityDates: [Date()]))

        // Trigger an update from the achievements publisher
        mockAchievementService.mockAchievementsPublisher.send([Achievement(id: UUID(), type: .firstStep, category: .milestone, name: "First Step", description: "Complete your first check-in", iconUrl: "", points: 10, isHidden: false)])

        // Wait for the expectations to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
}