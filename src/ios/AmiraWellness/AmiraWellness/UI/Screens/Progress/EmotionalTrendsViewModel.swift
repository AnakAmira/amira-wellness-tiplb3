import Foundation // For basic data types and Date operations
import Combine // For Combine framework features
import SwiftUI // For ObservableObject and Published property wrappers

// Internal imports for data models, services, and utilities
import EmotionalTrend // Core data model for emotional trends
import EmotionalTrendResponse // Response data structure from trend analysis
import EmotionalInsight // Insights derived from emotional trend analysis
import TrendPeriodType // Time periods for trend analysis
import EmotionType // Emotion types for filtering and display
import ProgressService // Service for accessing progress and trend data
import Logger // Logging service for debugging and error tracking
import Haptics // Haptic feedback for user interactions

/// ViewModel for the Emotional Trends screen that manages the state and business logic for visualizing emotional patterns over time
@MainActor
@ObservableObject
class EmotionalTrendsViewModel {
    
    // MARK: - Private Properties
    
    private let progressService: ProgressService // Service for fetching emotional trends
    
    // MARK: - Published Properties
    
    @Published var trends: [EmotionalTrend] = [] // Array of emotional trends to display
    @Published var insights: [EmotionalInsight] = [] // Array of insights related to the trends
    @Published var selectedPeriod: TrendPeriodType = .weekly // Currently selected time period for trend analysis
    @Published var selectedEmotionTypes: [EmotionType] = [] // Array of selected emotion types for filtering
    @Published var isLoading: Bool = false // Indicates if the data is currently being loaded
    @Published var errorMessage: String? // Error message to display if loading fails
    @Published var selectedTrend: EmotionalTrend? // The currently selected trend for detailed viewing
    @Published var startDate: Date // Start date for the current trend period
    @Published var endDate: Date // End date for the current trend period
    
    private var cancellables: Set<AnyCancellable> = [] // Set to hold Combine cancellables
    
    // MARK: - Initialization
    
    /// Initializes the EmotionalTrendsViewModel with dependencies
    /// - Parameter progressService: Optional ProgressService for fetching emotional trends
    init(progressService: ProgressService? = nil) {
        // Store the provided progressService or create a new instance
        self.progressService = progressService ?? ProgressService()
        // Initialize trends as an empty array
        self.trends = []
        // Initialize insights as an empty array
        self.insights = []
        // Set selectedPeriod to .weekly by default
        self.selectedPeriod = .weekly
        // Initialize selectedEmotionTypes as an empty array (all emotions)
        self.selectedEmotionTypes = []
        // Set isLoading to false
        self.isLoading = false
        // Set errorMessage to nil
        self.errorMessage = nil
        // Set selectedTrend to nil
        self.selectedTrend = nil
        // Initialize date range from selectedPeriod.defaultRange()
        (self.startDate, self.endDate) = selectedPeriod.defaultRange()
        // Initialize cancellables set for storing subscriptions
        self.cancellables = []
    }
    
    // MARK: - Public Methods
    
    /// Loads emotional trend data for the selected period and emotion types
    func loadTrends() {
        // Set isLoading to true
        isLoading = true
        // Clear any previous error message
        errorMessage = nil
        
        // Call progressService.getEmotionalTrends with selectedPeriod
        progressService.getEmotionalTrends(periodType: selectedPeriod, startDate: startDate, endDate: endDate) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let trendResponse):
                // Update trends and insights properties
                self.trends = trendResponse.trends
                self.insights = trendResponse.insights
                
                // Filter trends by selectedEmotionTypes if not empty
                if !self.selectedEmotionTypes.isEmpty {
                    self.applyEmotionTypeFilters()
                }
                
                // Sort trends by averageIntensity or occurrence count
                self.trends.sort { $0.averageIntensity > $1.averageIntensity }
                
                // Set isLoading to false
                self.isLoading = false
                
            case .failure(let error):
                // Set errorMessage with appropriate error
                self.errorMessage = "Failed to load trends: \(error)"
                // Set isLoading to false
                self.isLoading = false
            }
        }
    }
    
    /// Loads emotional trend data using async/await
    @available(iOS 15.0, *)
    func loadTrendsAsync() async {
        // Set isLoading to true
        isLoading = true
        // Clear any previous error message
        errorMessage = nil
        
        do {
            // Try to call progressService.getEmotionalTrendsAsync with selectedPeriod
            let trendResponse = try await progressService.getEmotionalTrendsAsync(periodType: selectedPeriod)
            
            // Update trends and insights properties
            self.trends = trendResponse.trends
            self.insights = trendResponse.insights
            
            // Filter trends by selectedEmotionTypes if not empty
            if !self.selectedEmotionTypes.isEmpty {
                self.applyEmotionTypeFilters()
            }
            
            // Sort trends by averageIntensity or occurrence count
            self.trends.sort { $0.averageIntensity > $1.averageIntensity }
            
            // Set isLoading to false
            self.isLoading = false
        } catch {
            // Set errorMessage with appropriate error
            self.errorMessage = "Failed to load trends: \(error)"
            // Set isLoading to false
            self.isLoading = false
        }
    }
    
    /// Changes the selected time period for trend analysis
    /// - Parameter periodType: The new time period to select
    func changePeriod(periodType: TrendPeriodType) {
        // Set selectedPeriod to the provided periodType
        selectedPeriod = periodType
        // Update startDate and endDate from periodType.defaultRange()
        (startDate, endDate) = periodType.defaultRange()
        // Call loadTrends() to refresh data with new period
        loadTrends()
        // Provide haptic feedback for the change
        Haptics.shared.generateFeedback(.selection)
    }
    
    /// Toggles the inclusion of an emotion type in the filter
    /// - Parameter emotionType: The emotion type to toggle
    func toggleEmotionTypeFilter(emotionType: EmotionType) {
        // Check if emotionType is already in selectedEmotionTypes
        if selectedEmotionTypes.contains(emotionType) {
            // If present, remove it from the array
            selectedEmotionTypes.removeAll { $0 == emotionType }
        } else {
            // If not present, add it to the array
            selectedEmotionTypes.append(emotionType)
        }
        
        // Apply the filter to the current trends
        applyEmotionTypeFilters()
        // Provide haptic feedback for the change
        Haptics.shared.generateFeedback(.selection)
    }
    
    /// Clears all emotion type filters
    func clearEmotionTypeFilters() {
        // Set selectedEmotionTypes to an empty array
        selectedEmotionTypes = []
        // Reload trends with no emotion type filter
        loadTrends()
        // Provide haptic feedback for the change
        Haptics.shared.generateFeedback(.selection)
    }
    
    /// Selects a trend for detailed viewing
    /// - Parameter trend: The trend to select
    func selectTrend(trend: EmotionalTrend?) {
        // Set selectedTrend to the provided trend
        selectedTrend = trend
        // If trend is not nil, provide haptic feedback for selection
        if trend != nil {
            Haptics.shared.generateFeedback(.light)
        }
    }
    
    /// Filters insights related to a specific emotion type
    /// - Parameter emotionType: The emotion type to filter by
    /// - Returns: Array of insights related to the emotion type
    func getInsightsForEmotion(emotionType: EmotionType) -> [EmotionalInsight] {
        // Filter insights array to include only those related to the specified emotionType
        let filteredInsights = insights.filter { $0.relatedEmotions.contains(emotionType) }
        // Sort filtered insights by confidence level (descending)
        return filteredInsights.sorted { $0.confidence > $1.confidence }
    }
    
    /// Returns the top insights based on confidence level
    /// - Parameter limit: The maximum number of insights to return
    /// - Returns: Array of top insights
    func getTopInsights(limit: Int) -> [EmotionalInsight] {
        // Sort insights array by confidence level (descending)
        let sortedInsights = insights.sorted { $0.confidence > $1.confidence }
        // Return the first 'limit' number of insights
        return Array(sortedInsights.prefix(limit))
    }
    
    /// Updates the date range for trend analysis
    /// - Parameters:
    ///   - start: The new start date
    ///   - end: The new end date
    func updateDateRange(start: Date, end: Date) {
        // Validate that start date is before end date
        guard start < end else {
            return
        }
        
        // Set startDate to the provided start date
        startDate = start
        // Set endDate to the provided end date
        endDate = end
        // Call loadTrends() to refresh data with new date range
        loadTrends()
    }
    
    /// Determines the most frequently occurring emotion in the trends
    /// - Returns: The most frequent emotion type or nil if no trends
    func getMostFrequentEmotion() -> EmotionType? {
        // Check if trends array is empty, return nil if so
        guard !trends.isEmpty else {
            return nil
        }
        
        // Group trends by emotionType and count occurrences
        let emotionCounts = Dictionary(grouping: trends, by: { $0.emotionType })
            .mapValues { $0.count }
        
        // Find the emotion type with the highest count
        let mostFrequentEmotion = emotionCounts.max { a, b in a.value < b.value }?.key
        
        // Return the most frequent emotion type
        return mostFrequentEmotion
    }
    
    /// Calculates the average intensity for a specific emotion type
    /// - Parameter emotionType: The emotion type to calculate the average intensity for
    /// - Returns: Average intensity or 0 if no data
    func getAverageIntensityForEmotion(emotionType: EmotionType) -> Double {
        // Filter trends to include only those matching the specified emotionType
        let filteredTrends = trends.filter { $0.emotionType == emotionType }
        
        // If no matching trends, return 0
        guard !filteredTrends.isEmpty else {
            return 0
        }
        
        // Calculate the average of averageIntensity values from matching trends
        let totalIntensity = filteredTrends.reduce(0.0) { $0 + $1.averageIntensity }
        let averageIntensity = totalIntensity / Double(filteredTrends.count)
        
        // Return the calculated average
        return averageIntensity
    }
    
    // MARK: - Private Methods
    
    /// Applies the current emotion type filters to the trends
    private func applyEmotionTypeFilters() {
        // Check if selectedEmotionTypes is empty (no filtering)
        if selectedEmotionTypes.isEmpty {
            // If empty, reload all trends from the original data
            loadTrends()
        } else {
            // If not empty, filter trends to include only those with emotionType in selectedEmotionTypes
            trends = trends.filter { selectedEmotionTypes.contains($0.emotionType) }
        }
    }
}