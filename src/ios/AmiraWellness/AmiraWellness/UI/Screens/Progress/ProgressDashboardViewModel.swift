import Foundation // Latest
import Combine // Latest
import SwiftUI // Latest

// Internal imports
import ProgressService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/ProgressService.swift
import EmotionalTrend // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import TrendPeriodType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import EmotionalTrendResponse // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import Achievement // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import AchievementCategory // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// A view model that provides data and business logic for the Progress Dashboard screen
class ProgressDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates if the data is currently loading
    @Published var isLoading: Bool = true
    
    /// Stores any error message that occurs during data loading
    @Published var errorMessage: String = ""
    
    /// Stores the emotional trends data
    @Published var emotionalTrends: [EmotionalTrend] = []
    
    /// Stores the dominant emotions with their frequencies
    @Published var dominantEmotions: [(EmotionType, Double)] = []
    
    /// Stores the current streak
    @Published var currentStreak: Int = 0
    
    /// Stores the longest streak
    @Published var longestStreak: Int = 0
    
    /// Stores the next milestone for the streak
    @Published var nextMilestone: Int = 0
    
    /// Stores the progress towards the next milestone
    @Published var streakProgress: Double = 0.0
    
    /// Stores the earned achievements
    @Published var earnedAchievements: [Achievement] = []
    
    /// Stores the upcoming achievements
    @Published var upcomingAchievements: [Achievement] = []
    
    /// Stores the activity summary data
    @Published var activitySummary: [Date: Int] = [:]
    
    /// Stores the selected period type for emotional trend analysis
    @Published var selectedPeriodType: TrendPeriodType = .weekly
    
    // MARK: - Private Properties
    
    /// The progress service used to fetch progress data
    private let progressService: ProgressService
    
    /// A set to hold Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the ProgressDashboardViewModel with dependencies
    /// - Parameter progressService: The progress service to use for fetching progress data
    init(progressService: ProgressService? = nil) {
        // Store the provided progressService or create a new instance
        self.progressService = progressService ?? ProgressService()
        
        // Call loadData() to initialize the view model data
        loadData()
    }
    
    // MARK: - Public Methods
    
    /// Loads all progress data for the dashboard
    func loadData() {
        // Set isLoading to true
        isLoading = true
        
        // Clear any previous error message
        errorMessage = ""
        
        // Call progressService.refreshProgressData
        progressService.refreshProgressData { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // On success, load all required data
                self.loadEmotionalTrends(periodType: self.selectedPeriodType)
                self.loadStreakData()
                self.loadAchievements()
                self.loadActivityData()
                
                // Set isLoading to false when all data is loaded
                self.isLoading = false
                
                // Log the data loading operation
                Logger.shared.debug("Progress data loaded successfully", category: .general)
                
            case .failure(let error):
                // If any error occurs, set errorMessage and isLoading to false
                self.errorMessage = "Failed to load progress data: \(error)"
                self.isLoading = false
                
                // Log the error
                Logger.shared.error("Failed to load progress data: \(error)", category: .general)
            }
        }
    }
    
    /// Refreshes all progress data from the server
    func refreshData() {
        // Call loadData() to refresh all data
        loadData()
        
        // Log the refresh operation
        Logger.shared.debug("Progress data refreshed", category: .general)
    }
    
    /// Loads emotional trend data for the specified period
    /// - Parameter periodType: The period type for emotional trend analysis
    func loadEmotionalTrends(periodType: TrendPeriodType) {
        // Call progressService.getEmotionalTrends with the period type
        progressService.getEmotionalTrends(periodType: periodType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let trendResponse):
                // Update emotionalTrends with the response data
                self.emotionalTrends = trendResponse.trends
                
                // Calculate and update dominantEmotions based on trends
                self.dominantEmotions = self.calculateDominantEmotions(trends: trendResponse.trends)
                
                // Log the operation result
                Logger.shared.debug("Emotional trends loaded successfully for period: \(periodType)", category: .general)
                
            case .failure(let error):
                // Set appropriate error message
                self.errorMessage = "Failed to load emotional trends: \(error)"
                
                // Log the error
                Logger.shared.error("Failed to load emotional trends: \(error)", category: .general)
            }
        }
    }
    
    /// Loads streak-related data for the dashboard
    func loadStreakData() {
        // Get current streak from progressService.getCurrentStreak()
        currentStreak = progressService.getCurrentStreak()
        
        // Get longest streak from progressService.getLongestStreak()
        longestStreak = progressService.getLongestStreak()
        
        // Get next milestone from progressService.getNextMilestone()
        nextMilestone = progressService.getNextMilestone()
        
        // Get streak progress from progressService.getProgressToNextMilestone()
        streakProgress = progressService.getProgressToNextMilestone()
        
        // Log the operation result
        Logger.shared.debug("Streak data loaded successfully", category: .general)
    }
    
    /// Loads achievement data for the dashboard
    func loadAchievements() {
        // Get earned achievements from progressService.getEarnedAchievements()
        earnedAchievements = progressService.getEarnedAchievements()
        
        // Sort earned achievements by earned date (most recent first)
        earnedAchievements.sort { $0.earnedDate ?? Date() > $1.earnedDate ?? Date() }
        
        // Filter and create a list of upcoming achievements
        upcomingAchievements = progressService.getCachedAchievements().filter { $0.earnedDate == nil }
        
        // Log the operation result
        Logger.shared.debug("Achievement data loaded successfully", category: .general)
    }
    
    /// Loads weekly activity data for the dashboard
    func loadActivityData() {
        // Call progressService.getWeeklyActivityData()
        progressService.getWeeklyActivityData { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let activityData):
                // Update activitySummary with the response data
                self.activitySummary = activityData
                
                // Log the operation result
                Logger.shared.debug("Activity data loaded successfully", category: .general)
                
            case .failure(let error):
                // Set appropriate error message
                self.errorMessage = "Failed to load activity data: \(error)"
                
                // Log the error
                Logger.shared.error("Failed to load activity data: \(error)", category: .general)
            }
        }
    }
    
    /// Changes the period type for emotional trend analysis
    /// - Parameter newPeriodType: The new period type to use
    func changePeriodType(newPeriodType: TrendPeriodType) {
        // Update selectedPeriodType to newPeriodType
        selectedPeriodType = newPeriodType
        
        // Call loadEmotionalTrends with the new period type
        loadEmotionalTrends(periodType: newPeriodType)
        
        // Log the period type change
        Logger.shared.debug("Period type changed to: \(newPeriodType)", category: .general)
    }
    
    /// Returns a formatted string representation of the current streak
    /// - Returns: A formatted string representation of the current streak
    func getFormattedStreak() -> String {
        // Format currentStreak as a string with "días" suffix
        return "\(currentStreak) días"
    }
    
    /// Returns a formatted string describing the next streak milestone
    /// - Returns: A formatted string describing the next streak milestone
    func getFormattedNextMilestone() -> String {
        // Check if nextMilestone is greater than 0
        if nextMilestone > 0 {
            // If yes, format a string like "Próximo logro: X días"
            return "Próximo logro: \(nextMilestone) días"
        } else {
            // If no, return a string indicating all milestones achieved
            return "¡Has alcanzado todos los logros!"
        }
    }
    
    /// Groups achievements by their category
    /// - Parameter achievements: An array of Achievement objects
    /// - Returns: A dictionary of achievements grouped by category
    func getAchievementsByCategory(achievements: [Achievement]) -> [AchievementCategory: [Achievement]] {
        // Create an empty dictionary for the result
        var groupedAchievements: [AchievementCategory: [Achievement]] = [:]
        
        // Group the achievements by their category property
        for achievement in achievements {
            if var achievementsForCategory = groupedAchievements[achievement.category] {
                achievementsForCategory.append(achievement)
                groupedAchievements[achievement.category] = achievementsForCategory
            } else {
                groupedAchievements[achievement.category] = [achievement]
            }
        }
        
        // Return the grouped dictionary
        return groupedAchievements
    }
    
    /// Returns a formatted string describing the dominant emotion
    /// - Parameters:
    ///   - emotion: The dominant emotion
    ///   - percentage: The percentage of the emotion
    /// - Returns: A formatted string describing the dominant emotion
    func getDominantEmotionText(emotion: EmotionType, percentage: Double) -> String {
        // Format the percentage as a string with % symbol
        let percentageString = String(format: "%.1f%%", percentage)
        
        // Combine the emotion display name and percentage
        return "\(emotion.displayName()) - \(percentageString)"
    }
    
    // MARK: - Private Methods
    
    /// Calculates the dominant emotions from the emotional trends
    /// - Parameter trends: An array of EmotionalTrend objects
    /// - Returns: An array of tuples containing the dominant emotion and its frequency
    private func calculateDominantEmotions(trends: [EmotionalTrend]) -> [(EmotionType, Double)] {
        // Create a dictionary to store the frequency of each emotion
        var emotionFrequencies: [EmotionType: Double] = [:]
        
        // Iterate over the trends and update the emotion frequencies
        for trend in trends {
            emotionFrequencies[trend.emotionType, default: 0] += trend.averageIntensity
        }
        
        // Sort the emotions by frequency in descending order
        let sortedEmotions = emotionFrequencies.sorted { $0.value > $1.value }
        
        // Convert the sorted emotions to an array of tuples
        let dominantEmotions = sortedEmotions.map { (emotionType, frequency) in
            return (emotionType, frequency)
        }
        
        // Return the array of dominant emotions
        return dominantEmotions
    }
}