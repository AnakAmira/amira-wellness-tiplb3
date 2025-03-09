import Foundation // Latest
import Combine // Latest

// Internal imports
import StreakService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/StreakService.swift
import AchievementService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/AchievementService.swift
import EmotionService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionService.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import APIError // src/ios/AmiraWellness/AmiraWellness/Models/APIError.swift
import EmotionalTrend // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import EmotionalTrendResponse // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import TrendPeriodType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import Achievement // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import AchievementType // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import Streak // src/ios/AmiraWellness/AmiraWellness/Models/Streak.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// Enum defining possible errors that can occur during progress service operations
enum ProgressServiceError: Error {
    case networkError
    case dataError
    case analysisError
    case invalidRequest
}

/// A structure representing an insight about the user's progress
struct ProgressInsight: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let type: ProgressInsightType
    let relevance: Double
    let actionableSteps: [String]
    let relatedToolIds: [String]?
    
    /// Initializes a ProgressInsight with the provided parameters
    /// - Parameters:
    ///   - id: A unique identifier for the insight
    ///   - title: A brief title for the insight
    ///   - description: A detailed description of the insight
    ///   - type: The type of progress insight
    ///   - relevance: A value indicating the relevance of the insight
    ///   - actionableSteps: An array of actionable steps related to the insight
    ///   - relatedToolIds: An optional array of tool identifiers related to the insight
    init(id: String, title: String, description: String, type: ProgressInsightType, relevance: Double, actionableSteps: [String], relatedToolIds: [String]? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.relevance = relevance
        self.actionableSteps = actionableSteps
        self.relatedToolIds = relatedToolIds
    }
}

/// An enumeration of different progress insight types
enum ProgressInsightType: String, Codable, CaseIterable {
    case streak
    case achievement
    case emotional
    case activity
    case recommendation
}

/// A structure that encapsulates various progress metrics for the user
struct ProgressSummary {
    let currentStreak: Int
    let longestStreak: Int
    let achievementProgress: Double
    let achievementsEarned: Int
    let totalAchievements: Int
    let recentTrends: [EmotionalTrend]?
    let nextMilestone: Int
    let milestoneProgress: Double
    let isStreakActive: Bool
    
    /// Initializes a ProgressSummary with the provided parameters
    /// - Parameters:
    ///   - currentStreak: The user's current streak
    ///   - longestStreak: The user's longest streak
    ///   - achievementProgress: The user's achievement progress
    ///   - achievementsEarned: The number of achievements earned by the user
    ///   - totalAchievements: The total number of achievements available
    ///   - recentTrends: The user's recent emotional trends
    ///   - nextMilestone: The next streak milestone to achieve
    ///   - milestoneProgress: The progress towards the next streak milestone
    ///   - isStreakActive: A boolean indicating whether the streak is active
    init(currentStreak: Int, longestStreak: Int, achievementProgress: Double, achievementsEarned: Int, totalAchievements: Int, recentTrends: [EmotionalTrend]?, nextMilestone: Int, milestoneProgress: Double, isStreakActive: Bool) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.achievementProgress = achievementProgress
        self.achievementsEarned = achievementsEarned
        self.totalAchievements = totalAchievements
        self.recentTrends = recentTrends
        self.nextMilestone = nextMilestone
        self.milestoneProgress = milestoneProgress
        self.isStreakActive = isStreakActive
    }
}

/// A service that coordinates progress tracking functionality in the Amira Wellness application
final class ProgressService {
    
    // MARK: - Private Properties
    
    private let streakService: StreakService
    private let achievementService: AchievementService
    private let emotionService: EmotionService
    private let apiClient: APIClient
    private var cancellables: Set<AnyCancellable> = []
    private let progressSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Public Properties
    
    public var progressPublisher: AnyPublisher<Void, Never>
    
    // MARK: - Initialization
    
    /// Initializes the ProgressService with dependencies
    /// - Parameters:
    ///   - streakService: The StreakService to use for streak tracking
    ///   - achievementService: The AchievementService to use for achievement management
    ///   - emotionService: The EmotionService to use for emotional trend analysis
    ///   - apiClient: The APIClient to use for network requests
    init(streakService: StreakService? = nil, achievementService: AchievementService? = nil, emotionService: EmotionService? = nil, apiClient: APIClient? = nil) {
        // Store the provided streakService or create a new instance
        self.streakService = streakService ?? StreakService(apiClient: apiClient ?? APIClient.shared, storageService: nil)
        // Store the provided achievementService or create a new instance
        self.achievementService = achievementService ?? AchievementService(apiClient: apiClient ?? APIClient.shared, storageService: nil)
        // Store the provided emotionService or create a new instance
        self.emotionService = emotionService ?? EmotionService(apiClient: apiClient ?? APIClient.shared, secureStorageService: nil, analysisService: nil)
        // Store the provided apiClient or use APIClient.shared
        self.apiClient = apiClient ?? APIClient.shared
        // Initialize cancellables set for storing subscriptions
        self.cancellables = []
        // Initialize progressSubject for publishing progress updates
        self.progressSubject = PassthroughSubject<Void, Never>()
        // Initialize progressPublisher as a derived publisher from progressSubject
        self.progressPublisher = progressSubject.eraseToAnyPublisher()
        // Set up subscriptions to streak and achievement publishers
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes all progress-related data from the server
    /// - Parameter completion: A closure to be called when the refresh is complete
    func refreshProgressData(completion: @escaping (Result<Void, ProgressServiceError>) -> Void) {
        // Create a dispatch group to coordinate multiple async operations
        let dispatchGroup = DispatchGroup()
        
        // Enter the dispatch group for each async operation
        dispatchGroup.enter()
        streakService.getStreakInfo { result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success:
                break
            case .failure(let error):
                Logger.shared.error("Failed to refresh streak data: \(error)", category: .progress)
                completion(.failure(.networkError))
            }
        }
        
        dispatchGroup.enter()
        achievementService.getAchievements { result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success:
                break
            case .failure(let error):
                Logger.shared.error("Failed to refresh achievement data: \(error)", category: .progress)
                completion(.failure(.networkError))
            }
        }
        
        dispatchGroup.enter()
        emotionService.getEmotionalTrends(periodType: .weekly) { result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success:
                break
            case .failure(let error):
                Logger.shared.error("Failed to refresh emotional trends: \(error)", category: .progress)
                completion(.failure(.networkError))
            }
        }
        
        // When all operations complete, call completion handler
        dispatchGroup.notify(queue: .main) {
            completion(.success(()))
        }
    }
    
    /// Refreshes all progress-related data using async/await
    @available(iOS 15.0, *)
    func refreshProgressDataAsync() async throws {
        async let streakResult = streakService.getStreakInfo()
        async let achievementResult = achievementService.getAchievements()
        async let emotionResult = emotionService.getEmotionalTrendsAsync(periodType: .weekly)
        
        do {
            _ = try await (streakResult, achievementResult, emotionResult)
        } catch {
            Logger.shared.error("Failed to refresh progress data: \(error)", category: .progress)
            throw ProgressServiceError.networkError
        }
    }
    
    /// Records a user activity to update streaks and progress
    /// - Parameter activityDate: The date of the activity
    /// - Parameter completion: A closure to be called when the activity is recorded
    func recordActivity(activityDate: Date? = nil, completion: ((Result<Bool, ProgressServiceError>) -> Void)? = nil) {
        let activityDate = activityDate ?? Date()
        streakService.updateStreak(activityDate: activityDate) { streakIncreased in
            if streakIncreased {
                completion?(.success(true))
            } else {
                completion?(.success(false))
            }
        }
    }
    
    /// Records a user activity using async/await
    @available(iOS 15.0, *)
    func recordActivityAsync(activityDate: Date? = nil) async throws -> Bool {
        let activityDate = activityDate ?? Date()
        return await streakService.updateStreak(activityDate: activityDate)
    }
    
    /// Retrieves a summary of the user's progress
    /// - Parameter completion: A closure to be called when the progress summary is retrieved
    func getProgressSummary(completion: @escaping (Result<ProgressSummary, ProgressServiceError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var achievementProgress: Double = 0.0
        var achievementsEarned: Int = 0
        var totalAchievements: Int = 0
        var recentTrends: [EmotionalTrend]? = nil
        var nextMilestone: Int = 0
        var milestoneProgress: Double = 0.0
        var isStreakActive: Bool = false
        
        dispatchGroup.enter()
        streakService.getStreakInfo { result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let streak):
                currentStreak = streak.currentStreak
                longestStreak = streak.longestStreak
                isStreakActive = streak.isActive()
            case .failure(let error):
                Logger.shared.error("Failed to get streak info: \(error)", category: .progress)
            }
        }
        
        dispatchGroup.enter()
        achievementService.getAchievements { result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let achievementResponse):
                achievementProgress = Double(achievementResponse.totalEarned) / Double(achievementResponse.totalAvailable)
                achievementsEarned = achievementResponse.totalEarned
                totalAchievements = achievementResponse.totalAvailable
            case .failure(let error):
                Logger.shared.error("Failed to get achievement data: \(error)", category: .progress)
            }
        }
        
        dispatchGroup.enter()
        emotionService.getEmotionalTrends(periodType: .weekly) { result in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let trendResponse):
                recentTrends = trendResponse.trends
            case .failure(let error):
                Logger.shared.error("Failed to get emotional trends: \(error)", category: .progress)
            }
        }
        
        dispatchGroup.enter()
        nextMilestone = streakService.getNextMilestone()
        milestoneProgress = streakService.getProgressToNextMilestone()
        dispatchGroup.leave()
        
        dispatchGroup.notify(queue: .main) {
            let progressSummary = ProgressSummary(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                achievementProgress: achievementProgress,
                achievementsEarned: achievementsEarned,
                totalAchievements: totalAchievements,
                recentTrends: recentTrends,
                nextMilestone: nextMilestone,
                milestoneProgress: milestoneProgress,
                isStreakActive: isStreakActive
            )
            completion(.success(progressSummary))
        }
    }
    
    /// Retrieves a summary of the user's progress using async/await
    @available(iOS 15.0, *)
    func getProgressSummaryAsync() async throws -> ProgressSummary {
        async let currentStreak = streakService.getCurrentStreak()
        async let longestStreak = streakService.getLongestStreak()
        async let achievementProgress = achievementService.getAchievementProgress()
        async let achievementsEarned = achievementService.getEarnedAchievements().count
        async let totalAchievements = achievementService.getCachedAchievements().count
        async let recentTrends = emotionService.getEmotionalTrendsAsync(periodType: .weekly).trends
        async let nextMilestone = streakService.getNextMilestone()
        async let milestoneProgress = streakService.getProgressToNextMilestone()
        async let isStreakActive = streakService.isStreakActive()
        
        do {
            let progressSummary = ProgressSummary(
                currentStreak: try await currentStreak,
                longestStreak: try await longestStreak,
                achievementProgress: try await achievementProgress,
                achievementsEarned: try await achievementsEarned,
                totalAchievements: try await totalAchievements,
                recentTrends: try await recentTrends,
                nextMilestone: try await nextMilestone,
                milestoneProgress: try await milestoneProgress,
                isStreakActive: try await isStreakActive
            )
            return progressSummary
        } catch {
            Logger.shared.error("Failed to get progress summary: \(error)", category: .progress)
            throw ProgressServiceError.dataError
        }
    }
    
    /// Retrieves activity data for the past week
    /// - Parameter completion: A closure to be called when the activity data is retrieved
    func getWeeklyActivityData(completion: @escaping (Result<[Date: Int], ProgressServiceError>) -> Void) {
        let streakInfo = streakService.getCachedStreakInfo()
        
        guard let streakInfo = streakInfo else {
            completion(.failure(.dataError))
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        
        var activityData: [Date: Int] = [:]
        
        for date in streakInfo.activityDates {
            if date >= lastWeek && date <= today {
                let day = calendar.startOfDay(for: date)
                activityData[day, default: 0] += 1
            }
        }
        
        completion(.success(activityData))
    }
    
    /// Retrieves activity data for the past week using async/await
    @available(iOS 15.0, *)
    func getWeeklyActivityDataAsync() async throws -> [Date: Int] {
        let streakInfo = streakService.getCachedStreakInfo()
        
        guard let streakInfo = streakInfo else {
            throw ProgressServiceError.dataError
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        
        var activityData: [Date: Int] = [:]
        
        for date in streakInfo.activityDates {
            if date >= lastWeek && date <= today {
                let day = calendar.startOfDay(for: date)
                activityData[day, default: 0] += 1
            }
        }
        
        return activityData
    }
    
    /// Retrieves emotional trends for the specified period
    /// - Parameters:
    ///   - periodType: The time period for trend analysis
    ///   - completion: A closure to be called when the emotional trends are retrieved
    func getEmotionalTrends(periodType: TrendPeriodType, completion: @escaping (Result<EmotionalTrendResponse, ProgressServiceError>) -> Void) {
        let (startDate, endDate) = periodType.defaultRange()
        emotionService.getEmotionalTrends(periodType: periodType, startDate: startDate, endDate: endDate) { result in
            switch result {
            case .success(let trends):
                completion(.success(trends))
            case .failure(let error):
                switch error {
                case .invalidEmotionalState:
                    completion(.failure(.invalidRequest))
                default:
                    completion(.failure(.networkError))
                }
            }
        }
    }
    
    /// Retrieves emotional trends using async/await
    @available(iOS 15.0, *)
    func getEmotionalTrendsAsync(periodType: TrendPeriodType) async throws -> EmotionalTrendResponse {
        let (startDate, endDate) = periodType.defaultRange()
        do {
            return try await emotionService.getEmotionalTrendsAsync(periodType: periodType, startDate: startDate, endDate: endDate)
        } catch {
            if let emotionError = error as? EmotionServiceError {
                switch emotionError {
                case .invalidEmotionalState:
                    throw ProgressServiceError.invalidRequest
                default:
                    throw ProgressServiceError.networkError
                }
            } else {
                throw ProgressServiceError.networkError
            }
        }
    }
    
    /// Retrieves insights about the user's progress
    /// - Parameter completion: A closure to be called when the progress insights are retrieved
    func getProgressInsights(completion: @escaping (Result<[ProgressInsight], ProgressServiceError>) -> Void) {
        apiClient.request(endpoint: .getProgressInsights) { (result: Result<[ProgressInsight], APIError>) in
            switch result {
            case .success(let insights):
                completion(.success(insights))
            case .failure(let error):
                Logger.shared.error("Failed to get progress insights from API: \(error)", category: .progress)
                let localInsights = self.generateLocalInsights()
                completion(.success(localInsights))
            }
        }
    }
    
    /// Retrieves progress insights using async/await
    @available(iOS 15.0, *)
    func getProgressInsightsAsync() async throws -> [ProgressInsight] {
        do {
            let insights = try await apiClient.requestAsync(endpoint: .getProgressInsights) as [ProgressInsight]
            return insights
        } catch {
            Logger.shared.error("Failed to get progress insights from API: \(error)", category: .progress)
            let localInsights = self.generateLocalInsights()
            return localInsights
        }
    }
    
    /// Returns the current streak count
    func getCurrentStreak() -> Int {
        return streakService.getCurrentStreak()
    }
    
    /// Returns the longest streak count achieved by the user
    func getLongestStreak() -> Int {
        return streakService.getLongestStreak()
    }
    
    /// Returns the next streak milestone to achieve
    func getNextMilestone() -> Int {
        return streakService.getNextMilestone()
    }
    
    /// Returns the progress percentage towards the next milestone
    func getProgressToNextMilestone() -> Double {
        return streakService.getProgressToNextMilestone()
    }
    
    /// Determines if the user's streak is currently active
    func isStreakActive() -> Bool {
        return streakService.isStreakActive()
    }
    
    /// Returns the overall achievement progress percentage
    func getAchievementProgress() -> Double {
        return achievementService.getAchievementProgress()
    }
    
    /// Returns only the achievements that have been earned by the user
    func getEarnedAchievements() -> [Achievement] {
        return achievementService.getEarnedAchievements()
    }
    
    /// Checks if a specific achievement type has been earned
    func hasEarnedAchievement(type: AchievementType) -> Bool {
        return achievementService.hasEarnedAchievement(type: type)
    }
    
    // MARK: - Private Methods
    
    /// Generates progress insights locally when network is unavailable
    private func generateLocalInsights() -> [ProgressInsight] {
        var insights: [ProgressInsight] = []
        
        let currentStreak = streakService.getCurrentStreak()
        let achievementProgress = achievementService.getAchievementProgress()
        
        // Generate streak-related insights
        if currentStreak > 0 {
            let streakInsight = ProgressInsight(
                id: UUID().uuidString,
                title: "¡Sigue as\u{ed} con tu racha!",
                description: "Has mantenido una racha de \(currentStreak) d\u{ed}as. \u{a1}Sigue as\u{ed} para desbloquear nuevos logros!",
                type: .streak,
                relevance: 0.8,
                actionableSteps: ["Contin\u{fa}a usando la app diariamente."]
            )
            insights.append(streakInsight)
        }
        
        // Generate achievement-related insights
        if achievementProgress > 0 {
            let achievementInsight = ProgressInsight(
                id: UUID().uuidString,
                title: "Progreso en tus logros",
                description: "Has completado el \(Int(achievementProgress * 100))% de tus logros. \u{a1}Sigue explorando para desbloquear m\u{e1}s!",
                type: .achievement,
                relevance: 0.7,
                actionableSteps: ["Explora nuevas herramientas y actividades."]
            )
            insights.append(achievementInsight)
        }
        
        // Generate emotional trend insights (if data is available)
        // Add more sophisticated logic here based on emotional data
        
        return insights
    }
    
    /// Sets up Combine subscriptions to monitor progress-related events
    private func setupSubscriptions() {
        streakService.streakPublisher
            .sink { [weak self] _ in
                self?.progressSubject.send()
            }
            .store(in: &cancellables)
        
        achievementService.achievementsPublisher
            .sink { [weak self] _ in
                self?.progressSubject.send()
            }
            .store(in: &cancellables)
        
        emotionService.getInsightPublisher()
            .sink { [weak self] _ in
                self?.progressSubject.send()
            }
            .store(in: &cancellables)
    }
}