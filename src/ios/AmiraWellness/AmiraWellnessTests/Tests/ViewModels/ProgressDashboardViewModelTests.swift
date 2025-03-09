import XCTest // Framework for unit testing
import Combine // For testing asynchronous operations and publishers
import Foundation // Access to core Foundation types

// Internal imports
@testable import AmiraWellness // The module being tested
import EmotionalTrend // Model for emotional trend data
import TrendDirection // Enum for trend direction
import TrendPeriodType // Enum for trend period types
import TrendDataPoint // Model for trend data points
import EmotionType // Enum for emotion types
import Achievement // Model for user achievements
import AchievementCategory // Enum for achievement categories
import MockProgressService // Mock implementation of ProgressService

/// Test case class for testing the ProgressDashboardViewModel
class ProgressDashboardViewModelTests: XCTestCase {
    
    /// The view model being tested
    var viewModel: ProgressDashboardViewModel!
    
    /// Mock implementation of ProgressService
    var mockProgressService: MockProgressService!
    
    /// A set to hold Combine cancellables
    var cancellables: Set<AnyCancellable>!
    
    /// Set up method called before each test
    override func setUp() {
        super.setUp()
        // Initialize mockProgressService
        mockProgressService = MockProgressService()
        // Initialize viewModel with mockProgressService
        viewModel = ProgressDashboardViewModel(progressService: mockProgressService)
        // Initialize cancellables as empty Set
        cancellables = Set<AnyCancellable>()
    }
    
    /// Tear down method called after each test
    override func tearDown() {
        // Set viewModel to nil
        viewModel = nil
        // Set mockProgressService to nil
        mockProgressService = nil
        // Set cancellables to nil
        cancellables = nil
        super.tearDown()
    }
    
    /// Test that the view model initializes with the correct default state
    func testInitialState() {
        // Assert that viewModel.isLoading is true
        XCTAssertTrue(viewModel.isLoading)
        // Assert that viewModel.errorMessage is empty
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
        // Assert that viewModel.emotionalTrends is empty
        XCTAssertTrue(viewModel.emotionalTrends.isEmpty)
        // Assert that viewModel.dominantEmotions is empty
        XCTAssertTrue(viewModel.dominantEmotions.isEmpty)
        // Assert that viewModel.currentStreak is 0
        XCTAssertEqual(viewModel.currentStreak, 0)
        // Assert that viewModel.longestStreak is 0
        XCTAssertEqual(viewModel.longestStreak, 0)
        // Assert that viewModel.nextMilestone is 0
        XCTAssertEqual(viewModel.nextMilestone, 0)
        // Assert that viewModel.streakProgress is 0.0
        XCTAssertEqual(viewModel.streakProgress, 0.0)
        // Assert that viewModel.earnedAchievements is empty
        XCTAssertTrue(viewModel.earnedAchievements.isEmpty)
        // Assert that viewModel.upcomingAchievements is empty
        XCTAssertTrue(viewModel.upcomingAchievements.isEmpty)
        // Assert that viewModel.activitySummary is empty
        XCTAssertTrue(viewModel.activitySummary.isEmpty)
        // Assert that viewModel.selectedPeriodType is .weekly
        XCTAssertEqual(viewModel.selectedPeriodType, .weekly)
    }
    
    /// Test that loadData successfully loads all required data
    func testLoadDataSuccess() {
        // Set up mock emotional trends data
        let mockTrends = createMockEmotionalTrends()
        // Set up mock achievements data
        let mockAchievements = createMockAchievements()
        // Set up mock streak data in mockProgressService
        mockProgressService.currentStreakValue = 7
        mockProgressService.longestStreakValue = 14
        mockProgressService.nextMilestoneValue = 30
        mockProgressService.milestoneProgressValue = 0.5
        mockProgressService.earnedAchievements = mockAchievements
        // Set mockProgressService.refreshProgressDataResult to success
        mockProgressService.refreshProgressDataResult = .success(())
        // Set mockProgressService.getEmotionalTrendsResult to success with mock trends
        mockProgressService.getEmotionalTrendsResult = .success(EmotionalTrendResponse(trends: mockTrends, insights: []))
        
        // Call viewModel.loadData()
        let expectation = XCTestExpectation(description: "Load data expectation")
        viewModel.loadData()
        
        // Wait for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assert that viewModel.isLoading is false
            XCTAssertFalse(self.viewModel.isLoading)
            // Assert that viewModel.errorMessage is empty
            XCTAssertTrue(self.viewModel.errorMessage.isEmpty)
            // Assert that viewModel.emotionalTrends contains the mock trends
            XCTAssertEqual(self.viewModel.emotionalTrends, mockTrends)
            // Assert that viewModel.dominantEmotions is populated correctly
            XCTAssertFalse(self.viewModel.dominantEmotions.isEmpty)
            // Assert that viewModel.currentStreak matches the mock value
            XCTAssertEqual(self.viewModel.currentStreak, 7)
            // Assert that viewModel.longestStreak matches the mock value
            XCTAssertEqual(self.viewModel.longestStreak, 14)
            // Assert that viewModel.nextMilestone matches the mock value
            XCTAssertEqual(self.viewModel.nextMilestone, 30)
            // Assert that viewModel.streakProgress matches the mock value
            XCTAssertEqual(self.viewModel.streakProgress, 0.5)
            // Assert that viewModel.earnedAchievements contains the mock achievements
            XCTAssertEqual(self.viewModel.earnedAchievements, mockAchievements)
            // Assert that refreshProgressDataCallCount is 1
            XCTAssertEqual(self.mockProgressService.refreshProgressDataCallCount, 1)
            // Assert that getEmotionalTrendsCallCount is 1
            XCTAssertEqual(self.mockProgressService.getEmotionalTrendsCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Test that loadData handles errors correctly
    func testLoadDataFailure() {
        // Set mockProgressService.refreshProgressDataResult to failure with networkError
        mockProgressService.refreshProgressDataResult = .failure(.networkError)
        
        // Call viewModel.loadData()
        let expectation = XCTestExpectation(description: "Load data failure expectation")
        viewModel.loadData()
        
        // Wait for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assert that viewModel.isLoading is false
            XCTAssertFalse(self.viewModel.isLoading)
            // Assert that viewModel.errorMessage is not empty
            XCTAssertFalse(self.viewModel.errorMessage.isEmpty)
            // Assert that viewModel.errorMessage contains appropriate error message
            XCTAssertTrue(self.viewModel.errorMessage.contains("Failed to load progress data"))
            // Assert that refreshProgressDataCallCount is 1
            XCTAssertEqual(self.mockProgressService.refreshProgressDataCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Test that refreshData reloads all data
    func testRefreshData() {
        // Call viewModel.refreshData()
        let expectation = XCTestExpectation(description: "Refresh data expectation")
        viewModel.refreshData()
        
        // Wait for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assert that refreshProgressDataCallCount is 1
            XCTAssertEqual(self.mockProgressService.refreshProgressDataCallCount, 1)
            // Assert that getEmotionalTrendsCallCount is 1
            XCTAssertEqual(self.mockProgressService.getEmotionalTrendsCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Test that changing the period type loads new trend data
    func testChangePeriodType() {
        // Call viewModel.changePeriodType(.monthly)
        let expectation = XCTestExpectation(description: "Change period type expectation")
        viewModel.changePeriodType(newPeriodType: .monthly)
        
        // Wait for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assert that viewModel.selectedPeriodType is .monthly
            XCTAssertEqual(self.viewModel.selectedPeriodType, .monthly)
            // Assert that getEmotionalTrendsCallCount is 1
            XCTAssertEqual(self.mockProgressService.getEmotionalTrendsCallCount, 1)
            // Assert that lastRequestedPeriodType is .monthly
            XCTAssertEqual(self.mockProgressService.lastRequestedPeriodType, .monthly)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Test that getFormattedStreak returns the correct string
    func testGetFormattedStreak() {
        // Set mockProgressService.currentStreakValue to 7
        mockProgressService.currentStreakValue = 7
        // Set viewModel.currentStreak to 7
        viewModel.currentStreak = 7
        // Assert that viewModel.getFormattedStreak() returns "7 días"
        XCTAssertEqual(viewModel.getFormattedStreak(), "7 días")
    }
    
    /// Test that getFormattedNextMilestone returns the correct string
    func testGetFormattedNextMilestone() {
        // Set viewModel.nextMilestone to 14
        viewModel.nextMilestone = 14
        // Assert that viewModel.getFormattedNextMilestone() returns "Próximo logro: 14 días"
        XCTAssertEqual(viewModel.getFormattedNextMilestone(), "Próximo logro: 14 días")
        
        // Set viewModel.nextMilestone to 0
        viewModel.nextMilestone = 0
        // Assert that viewModel.getFormattedNextMilestone() returns appropriate message for all milestones achieved
        XCTAssertEqual(viewModel.getFormattedNextMilestone(), "¡Has alcanzado todos los logros!")
    }
    
    /// Test that getAchievementsByCategory correctly groups achievements
    func testGetAchievementsByCategory() {
        // Create mock achievements with different categories
        let mockAchievements = createMockAchievements()
        
        // Call viewModel.getAchievementsByCategory with mock achievements
        let groupedAchievements = viewModel.getAchievementsByCategory(achievements: mockAchievements)
        
        // Assert that the result contains the correct categories as keys
        XCTAssertEqual(groupedAchievements.count, 3)
        XCTAssertNotNil(groupedAchievements[.streak])
        XCTAssertNotNil(groupedAchievements[.journaling])
        XCTAssertNotNil(groupedAchievements[.emotionalAwareness])
        
        // Assert that each category contains the correct number of achievements
        XCTAssertEqual(groupedAchievements[.streak]?.count, 1)
        XCTAssertEqual(groupedAchievements[.journaling]?.count, 1)
        XCTAssertEqual(groupedAchievements[.emotionalAwareness]?.count, 1)
    }
    
    /// Test that getDominantEmotionText formats the emotion text correctly
    func testGetDominantEmotionText() {
        // Call viewModel.getDominantEmotionText with .joy and 0.45
        let emotionText = viewModel.getDominantEmotionText(emotion: .joy, percentage: 45.0)
        // Assert that the result contains the emotion name and percentage
        XCTAssertEqual(emotionText, "Alegría - 45.0%")
    }
    
    /// Test that loadEmotionalTrends handles errors correctly
    func testLoadEmotionalTrendsFailure() {
        // Set mockProgressService.getEmotionalTrendsResult to failure with dataError
        mockProgressService.getEmotionalTrendsResult = .failure(.dataError)
        
        // Call viewModel.loadData()
        let expectation = XCTestExpectation(description: "Load emotional trends failure expectation")
        viewModel.loadData()
        
        // Wait for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assert that viewModel.isLoading is false
            XCTAssertFalse(self.viewModel.isLoading)
            // Assert that viewModel.errorMessage is not empty
            XCTAssertFalse(self.viewModel.errorMessage.isEmpty)
            // Assert that viewModel.errorMessage contains appropriate error message
            XCTAssertTrue(self.viewModel.errorMessage.contains("Failed to load emotional trends"))
            // Assert that getEmotionalTrendsCallCount is 1
            XCTAssertEqual(self.mockProgressService.getEmotionalTrendsCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Test that dominant emotions are correctly calculated from trends
    func testDominantEmotionsCalculation() {
        // Create mock emotional trends with different emotion types and intensities
        let mockTrends = [
            EmotionalTrend(emotionType: .joy, dataPoints: [], overallTrend: .stable, averageIntensity: 8.0, peakIntensity: 9.0, peakDate: Date(), occurrenceCount: 5),
            EmotionalTrend(emotionType: .anxiety, dataPoints: [], overallTrend: .increasing, averageIntensity: 6.0, peakIntensity: 7.0, peakDate: Date(), occurrenceCount: 3),
            EmotionalTrend(emotionType: .calm, dataPoints: [], overallTrend: .decreasing, averageIntensity: 7.0, peakIntensity: 8.0, peakDate: Date(), occurrenceCount: 4)
        ]
        
        // Set up mockProgressService to return these trends
        mockProgressService.getEmotionalTrendsResult = .success(EmotionalTrendResponse(trends: mockTrends, insights: []))
        
        // Call viewModel.loadData()
        let expectation = XCTestExpectation(description: "Dominant emotions calculation expectation")
        viewModel.loadData()
        
        // Wait for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assert that viewModel.dominantEmotions contains the correct emotions
            XCTAssertEqual(self.viewModel.dominantEmotions.count, 3)
            XCTAssertEqual(self.viewModel.dominantEmotions[0].0, .joy)
            XCTAssertEqual(self.viewModel.dominantEmotions[1].0, .calm)
            XCTAssertEqual(self.viewModel.dominantEmotions[2].0, .anxiety)
            
            // Assert that the emotions are sorted by frequency/intensity
            XCTAssertGreaterThan(self.viewModel.dominantEmotions[0].1, self.viewModel.dominantEmotions[1].1)
            XCTAssertGreaterThan(self.viewModel.dominantEmotions[1].1, self.viewModel.dominantEmotions[2].1)
            
            // Assert that the percentages sum to approximately 1.0
            let totalPercentage = self.viewModel.dominantEmotions.reduce(0.0) { $0 + $1.1 }
            XCTAssertEqual(totalPercentage, 21.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to create mock emotional trends for testing
    private func createMockEmotionalTrends() -> [EmotionalTrend] {
        // Create data points for joy trend
        let joyDataPoints = [
            TrendDataPoint(date: Date(), value: 8),
            TrendDataPoint(date: Date().addingTimeInterval(-86400), value: 6)
        ]
        
        // Create data points for anxiety trend
        let anxietyDataPoints = [
            TrendDataPoint(date: Date(), value: 7),
            TrendDataPoint(date: Date().addingTimeInterval(-86400), value: 9)
        ]
        
        // Create data points for calm trend
        let calmDataPoints = [
            TrendDataPoint(date: Date(), value: 5),
            TrendDataPoint(date: Date().addingTimeInterval(-86400), value: 7)
        ]
        
        // Create EmotionalTrend objects with the data points
        let joyTrend = EmotionalTrend(emotionType: .joy, dataPoints: joyDataPoints, overallTrend: .increasing, averageIntensity: 7.0, peakIntensity: 8.0, peakDate: Date(), occurrenceCount: 2)
        let anxietyTrend = EmotionalTrend(emotionType: .anxiety, dataPoints: anxietyDataPoints, overallTrend: .decreasing, averageIntensity: 8.0, peakIntensity: 9.0, peakDate: Date(), occurrenceCount: 2)
        let calmTrend = EmotionalTrend(emotionType: .calm, dataPoints: calmDataPoints, overallTrend: .stable, averageIntensity: 6.0, peakIntensity: 7.0, peakDate: Date(), occurrenceCount: 2)
        
        // Return array of created trends
        return [joyTrend, anxietyTrend, calmTrend]
    }
    
    /// Helper method to create mock achievements for testing
    private func createMockAchievements() -> [Achievement] {
        // Create streak achievement
        let streakAchievement = Achievement(id: UUID(), type: .streak3Days, category: .streak, name: "3-Day Streak", description: "Used the app for 3 consecutive days", iconUrl: "streak_icon", points: 100, isHidden: false, earnedDate: Date())
        
        // Create journaling achievement
        let journalingAchievement = Achievement(id: UUID(), type: .journals5, category: .journaling, name: "5 Journals", description: "Created 5 voice journals", iconUrl: "journal_icon", points: 150, isHidden: false, earnedDate: Date())
        
        // Create emotional awareness achievement
        let emotionalAwarenessAchievement = Achievement(id: UUID(), type: .emotionalCheckins10, category: .emotionalAwareness, name: "10 Check-ins", description: "Completed 10 emotional check-ins", iconUrl: "checkin_icon", points: 120, isHidden: false, earnedDate: Date())
        
        // Return array of created achievements
        return [streakAchievement, journalingAchievement, emotionalAwarenessAchievement]
    }
}