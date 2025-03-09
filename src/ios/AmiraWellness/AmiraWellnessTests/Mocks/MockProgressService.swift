import Foundation
import Combine

// Internal imports
import ProgressService
import EmotionalTrend
import Achievement

/// A mock implementation of the ProgressService for unit testing
class MockProgressService: ProgressService {
    
    // MARK: - Mock Properties
    
    /// Mock response for refreshProgressData method
    var refreshProgressDataResult: Result<Void, ProgressServiceError>?
    
    /// Mock response for recordActivity method
    var recordActivityResult: Result<Bool, ProgressServiceError>?
    
    /// Mock response for getProgressSummary method
    var getProgressSummaryResult: Result<ProgressSummary, ProgressServiceError>?
    
    /// Mock response for getWeeklyActivityData method
    var getWeeklyActivityDataResult: Result<[Date: Int], ProgressServiceError>?
    
    /// Mock response for getEmotionalTrends method
    var getEmotionalTrendsResult: Result<EmotionalTrendResponse, ProgressServiceError>?
    
    /// Mock response for getProgressInsights method
    var getProgressInsightsResult: Result<[ProgressInsight], ProgressServiceError>?
    
    /// Counter for refreshProgressData calls
    var refreshProgressDataCallCount: Int = 0
    
    /// Counter for recordActivity calls
    var recordActivityCallCount: Int = 0
    
    /// Counter for getProgressSummary calls
    var getProgressSummaryCallCount: Int = 0
    
    /// Counter for getWeeklyActivityData calls
    var getWeeklyActivityDataCallCount: Int = 0
    
    /// Counter for getEmotionalTrends calls
    var getEmotionalTrendsCallCount: Int = 0
    
    /// Counter for getProgressInsights calls
    var getProgressInsightsCallCount: Int = 0
    
    /// Last recorded activity date
    var lastRecordedActivityDate: Date?
    
    /// Last requested period type
    var lastRequestedPeriodType: TrendPeriodType?
    
    /// Mock value for current streak
    var currentStreakValue: Int = 5
    
    /// Mock value for longest streak
    var longestStreakValue: Int = 10
    
    /// Mock value for achievement progress
    var achievementProgressValue: Double = 0.4
    
    /// Mock value for achievements earned
    var achievementsEarnedValue: Int = 3
    
    /// Mock value for total achievements
    var totalAchievementsValue: Int = 12
    
    /// Mock value for next milestone
    var nextMilestoneValue: Int = 7
    
    /// Mock value for milestone progress
    var milestoneProgressValue: Double = 0.7
    
    /// Mock value for is streak active
    var isStreakActiveValue: Bool = true
    
    /// Mock value for earned achievements
    var earnedAchievements: [Achievement] = []
    
    private let progressSubject = PassthroughSubject<Void, Never>()
    public var progressPublisher: AnyPublisher<Void, Never>
    
    /// Initializes the MockProgressService with default values
    override init() {
        refreshProgressDataCallCount = 0
        recordActivityCallCount = 0
        getProgressSummaryCallCount = 0
        getWeeklyActivityDataCallCount = 0
        getEmotionalTrendsCallCount = 0
        getProgressInsightsCallCount = 0
        currentStreakValue = 5
        longestStreakValue = 10
        achievementProgressValue = 0.4
        achievementsEarnedValue = 3
        totalAchievementsValue = 12
        nextMilestoneValue = 7
        milestoneProgressValue = 0.7
        isStreakActiveValue = true
        earnedAchievements = []
        progressSubject = PassthroughSubject<Void, Never>()
        progressPublisher = progressSubject.eraseToAnyPublisher()
    }
    
    /// Resets all mock responses and counters
    func reset() {
        refreshProgressDataResult = nil
        recordActivityResult = nil
        getProgressSummaryResult = nil
        getWeeklyActivityDataResult = nil
        getEmotionalTrendsResult = nil
        getProgressInsightsResult = nil
        refreshProgressDataCallCount = 0
        recordActivityCallCount = 0
        getProgressSummaryCallCount = 0
        getWeeklyActivityDataCallCount = 0
        getEmotionalTrendsCallCount = 0
        getProgressInsightsCallCount = 0
        lastRecordedActivityDate = nil
        lastRequestedPeriodType = nil
        currentStreakValue = 5
        longestStreakValue = 10
        achievementProgressValue = 0.4
        achievementsEarnedValue = 3
        totalAchievementsValue = 12
        nextMilestoneValue = 7
        milestoneProgressValue = 0.7
        isStreakActiveValue = true
        earnedAchievements.removeAll()
    }
    
    /// Mock implementation of the refreshProgressData method
    override func refreshProgressData(completion: @escaping (Result<Void, ProgressServiceError>) -> Void) {
        refreshProgressDataCallCount += 1
        if let result = refreshProgressDataResult {
            completion(result)
        } else {
            completion(.success(()))
        }
        progressSubject.send()
    }
    
    /// Mock implementation of the refreshProgressDataAsync method
    @available(iOS 15.0, *)
    override func refreshProgressDataAsync() async throws {
        refreshProgressDataCallCount += 1
        if let result = refreshProgressDataResult {
            switch result {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        } else {
            return
        }
        progressSubject.send()
    }
    
    /// Mock implementation of the recordActivity method
    override func recordActivity(activityDate: Date? = nil, completion: ((Result<Bool, ProgressServiceError>) -> Void)? = nil) {
        recordActivityCallCount += 1
        lastRecordedActivityDate = activityDate
        if let result = recordActivityResult {
            completion?(result)
        } else {
            completion?(.success(true))
        }
        progressSubject.send()
    }
    
    /// Mock implementation of the recordActivityAsync method
    @available(iOS 15.0, *)
    override func recordActivityAsync(activityDate: Date? = nil) async throws -> Bool {
        recordActivityCallCount += 1
        lastRecordedActivityDate = activityDate
        if let result = recordActivityResult {
            switch result {
            case .success(let success):
                return success
            case .failure(let error):
                throw error
            }
        } else {
            return true
        }
        progressSubject.send()
    }
    
    /// Mock implementation of the getProgressSummary method
    override func getProgressSummary(completion: @escaping (Result<ProgressSummary, ProgressServiceError>) -> Void) {
        getProgressSummaryCallCount += 1
        if let result = getProgressSummaryResult {
            completion(result)
        } else {
            let summary = createDefaultProgressSummary()
            completion(.success(summary))
        }
    }
    
    /// Mock implementation of the getProgressSummaryAsync method
    @available(iOS 15.0, *)
    override func getProgressSummaryAsync() async throws -> ProgressSummary {
        getProgressSummaryCallCount += 1
        if let result = getProgressSummaryResult {
            switch result {
            case .success(let summary):
                return summary
            case .failure(let error):
                throw error
            }
        } else {
            return createDefaultProgressSummary()
        }
    }
    
    /// Mock implementation of the getWeeklyActivityData method
    override func getWeeklyActivityData(completion: @escaping (Result<[Date: Int], ProgressServiceError>) -> Void) {
        getWeeklyActivityDataCallCount += 1
        if let result = getWeeklyActivityDataResult {
            completion(result)
        } else {
            let activityData = createDefaultActivityData()
            completion(.success(activityData))
        }
    }
    
    /// Mock implementation of the getWeeklyActivityDataAsync method
    @available(iOS 15.0, *)
    override func getWeeklyActivityDataAsync() async throws -> [Date: Int] {
        getWeeklyActivityDataCallCount += 1
        if let result = getWeeklyActivityDataResult {
            switch result {
            case .success(let activityData):
                return activityData
            case .failure(let error):
                throw error
            }
        } else {
            return createDefaultActivityData()
        }
    }
    
    /// Mock implementation of the getEmotionalTrends method
    override func getEmotionalTrends(periodType: TrendPeriodType, completion: @escaping (Result<EmotionalTrendResponse, ProgressServiceError>) -> Void) {
        getEmotionalTrendsCallCount += 1
        lastRequestedPeriodType = periodType
        if let result = getEmotionalTrendsResult {
            completion(result)
        } else {
            let trendResponse = EmotionalTrendResponse(trends: [], insights: [])
            completion(.success(trendResponse))
        }
    }
    
    /// Mock implementation of the getEmotionalTrendsAsync method
    @available(iOS 15.0, *)
    override func getEmotionalTrendsAsync(periodType: TrendPeriodType) async throws -> EmotionalTrendResponse {
        getEmotionalTrendsCallCount += 1
        lastRequestedPeriodType = periodType
        if let result = getEmotionalTrendsResult {
            switch result {
            case .success(let trendResponse):
                return trendResponse
            case .failure(let error):
                throw error
            }
        } else {
            return EmotionalTrendResponse(trends: [], insights: [])
        }
    }
    
    /// Mock implementation of the getProgressInsights method
    override func getProgressInsights(completion: @escaping (Result<[ProgressInsight], ProgressServiceError>) -> Void) {
        getProgressInsightsCallCount += 1
        if let result = getProgressInsightsResult {
            completion(result)
        } else {
            let insights = createDefaultInsights()
            completion(.success(insights))
        }
    }
    
    /// Mock implementation of the getProgressInsightsAsync method
    @available(iOS 15.0, *)
    override func getProgressInsightsAsync() async throws -> [ProgressInsight] {
        getProgressInsightsCallCount += 1
        if let result = getProgressInsightsResult {
            switch result {
            case .success(let insights):
                return insights
            case .failure(let error):
                throw error
            }
        } else {
            return createDefaultInsights()
        }
    }
    
    override func getCurrentStreak() -> Int {
        return currentStreakValue
    }
    
    override func getLongestStreak() -> Int {
        return longestStreakValue
    }
    
    override func getNextMilestone() -> Int {
        return nextMilestoneValue
    }
    
    override func getProgressToNextMilestone() -> Double {
        return milestoneProgressValue
    }
    
    override func isStreakActive() -> Bool {
        return isStreakActiveValue
    }
    
    override func getAchievementProgress() -> Double {
        return achievementProgressValue
    }
    
    override func getEarnedAchievements() -> [Achievement] {
        return earnedAchievements
    }
    
    override func hasEarnedAchievement(type: AchievementType) -> Bool {
        return earnedAchievements.contains { $0.type == type }
    }
    
    func publishProgressUpdate(update: Void) {
        progressSubject.send()
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultProgressSummary() -> ProgressSummary {
        return ProgressSummary(
            currentStreak: currentStreakValue,
            longestStreak: longestStreakValue,
            achievementProgress: achievementProgressValue,
            achievementsEarned: achievementsEarnedValue,
            totalAchievements: totalAchievementsValue,
            recentTrends: nil,
            nextMilestone: nextMilestoneValue,
            milestoneProgress: milestoneProgressValue,
            isStreakActive: isStreakActiveValue
        )
    }
    
    private func createDefaultActivityData() -> [Date: Int] {
        var activityData: [Date: Int] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                activityData[date] = Int.random(in: 0...5)
            }
        }
        return activityData
    }
    
    private func createDefaultInsights() -> [ProgressInsight] {
        return [
            ProgressInsight(
                id: UUID().uuidString,
                title: "Keep up the great work!",
                description: "You're doing great. Keep using the app daily.",
                type: .streak,
                relevance: 0.7,
                actionableSteps: ["Continue using the app daily."]
            ),
            ProgressInsight(
                id: UUID().uuidString,
                title: "Explore new tools",
                description: "Try exploring new tools to enhance your emotional wellness.",
                type: .recommendation,
                relevance: 0.6,
                actionableSteps: ["Explore new tools and activities."]
            )
        ]
    }
}