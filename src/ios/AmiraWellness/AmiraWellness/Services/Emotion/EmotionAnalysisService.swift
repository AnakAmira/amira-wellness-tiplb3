# src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionAnalysisService.swift
import Foundation // Foundation
import Combine // Combine

// Internal imports
import EmotionalState // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import EmotionalTrend // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift

/// Enum representing possible errors during emotion analysis operations
enum EmotionAnalysisError: Error {
    case invalidInput
    case insufficientData
    case analysisFailure
    case patternDetectionFailure
}

/// Service responsible for analyzing emotional data to provide insights and detect patterns
class EmotionAnalysisService {
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient?
    private let insightSubject = PassthroughSubject<EmotionalInsight, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private let minimumDataPointsForAnalysis: Int = 5
    
    // MARK: - Initialization
    
    /// Initializes the EmotionAnalysisService with dependencies
    /// - Parameters:
    ///   - apiClient: Optional APIClient for network requests
    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
        self.insightSubject = PassthroughSubject<EmotionalInsight, Never>()
        self.cancellables = []
        self.minimumDataPointsForAnalysis = 5
    }
    
    // MARK: - Public Methods
    
    /// Analyzes the shift between pre and post emotional states
    /// - Parameters:
    ///   - preState: The emotional state before an event
    ///   - postState: The emotional state after an event
    /// - Returns: A tuple containing a boolean indicating if the emotion changed, the intensity change, and an array of insights
    func analyzeEmotionalShift(preState: EmotionalState, postState: EmotionalState) -> (emotionChanged: Bool, intensityChange: Int, insights: [EmotionalInsight]) {
        // Validate that both states have valid contexts (pre/post journaling)
        guard preState.context == .preJournaling && postState.context == .postJournaling else {
            Logger.shared.error("Invalid emotional state context for shift analysis", category: .emotions)
            return (false, 0, [])
        }
        
        // Use compareWith method to get basic emotion change and intensity difference
        let (emotionChanged, intensityChange) = preState.compareWith(postState)
        
        // Analyze the emotional category shift (positive/negative/neutral)
        let preCategory = preState.emotionType.category()
        let postCategory = postState.emotionType.category()
        
        // Generate insights based on the emotional shift
        var insights: [EmotionalInsight] = []
        
        // Create improvement insight if shifted to more positive state
        if postCategory == .positive && preCategory != .positive {
            let improvementInsight = EmotionalInsight(
                type: .improvement,
                description: "Has experimentado una mejora en tu estado emocional después de la actividad.",
                relatedEmotions: [preState.emotionType, postState.emotionType],
                confidence: 0.7,
                recommendedActions: ["Continúa practicando esta actividad regularmente."]
            )
            insights.append(improvementInsight)
        }
        
        // If significant intensity change, create insight about intensity change
        if abs(intensityChange) > 3 {
            let intensityInsight = EmotionalInsight(
                type: .pattern,
                description: "Hubo un cambio significativo en la intensidad de tus emociones.",
                relatedEmotions: [preState.emotionType, postState.emotionType],
                confidence: 0.6,
                recommendedActions: ["Presta atención a los factores que influyen en la intensidad de tus emociones."]
            )
            insights.append(intensityInsight)
        }
        
        // If emotion type changed, create insight about emotional transition
        if emotionChanged {
            let transitionInsight = EmotionalInsight(
                type: .pattern,
                description: "Hubo una transición notable entre tus emociones.",
                relatedEmotions: [preState.emotionType, postState.emotionType],
                confidence: 0.5,
                recommendedActions: ["Reflexiona sobre las razones detrás de este cambio emocional."]
            )
            insights.append(transitionInsight)
        }
        
        return (emotionChanged, intensityChange, insights)
    }
    
    /// Generates emotional trends from a collection of emotional states
    /// - Parameters:
    ///   - emotionalStates: An array of EmotionalState objects
    ///   - periodType: The time period for trend analysis
    /// - Returns: An array of EmotionalTrend objects
    func generateTrends(emotionalStates: [EmotionalState], periodType: TrendPeriodType) -> [EmotionalTrend] {
        // Check if there are enough data points for analysis
        guard emotionalStates.count >= minimumDataPointsForAnalysis else {
            Logger.shared.warning("Insufficient data points for trend analysis", category: .emotions)
            return []
        }
        
        // Group emotional states by emotion type
        let groupedEmotions = Dictionary(grouping: emotionalStates, by: { $0.emotionType })
        
        var trends: [EmotionalTrend] = []
        
        // For each emotion type, create data points with date and intensity
        for (emotionType, states) in groupedEmotions {
            let dataPoints: [TrendDataPoint] = states.map { TrendDataPoint(date: $0.createdAt, value: $0.intensity, context: $0.context.rawValue) }
            
            // Calculate average intensity for each emotion type
            let totalIntensity = dataPoints.reduce(0) { $0 + $1.value }
            let averageIntensity = Double(totalIntensity) / Double(dataPoints.count)
            
            // Determine trend direction (increasing/decreasing/stable/fluctuating)
            let overallTrend = calculateTrendDirection(dataPoints: dataPoints)
            
            // Find peak intensity and date for each emotion type
            let peakDataPoint = dataPoints.max(by: { $0.value < $1.value })
            let peakIntensity = Double(peakDataPoint?.value ?? 0)
            let peakDate = peakDataPoint?.date ?? Date()
            
            // Count occurrences of each emotion type
            let occurrenceCount = states.count
            
            // Create EmotionalTrend objects for each emotion type
            let trend = EmotionalTrend(
                emotionType: emotionType,
                dataPoints: dataPoints,
                overallTrend: overallTrend,
                averageIntensity: averageIntensity,
                peakIntensity: peakIntensity,
                peakDate: peakDate,
                occurrenceCount: occurrenceCount
            )
            
            trends.append(trend)
        }
        
        // Sort trends by occurrence count (most frequent first)
        trends.sort { $0.occurrenceCount > $1.occurrenceCount }
        
        return trends
    }
    
    /// Detects patterns in emotional data and generates insights
    /// - Parameter emotionalStates: An array of EmotionalState objects
    /// - Returns: An array of insights derived from patterns
    func detectPatterns(emotionalStates: [EmotionalState]) -> [EmotionalInsight] {
        // Check if there are enough data points for analysis
        guard emotionalStates.count >= minimumDataPointsForAnalysis else {
            Logger.shared.warning("Insufficient data points for pattern detection", category: .emotions)
            return []
        }
        
        var insights: [EmotionalInsight] = []
        
        // Analyze time-of-day patterns (morning/afternoon/evening)
        let timeInsights = detectTimePatterns(emotionalStates: emotionalStates)
        insights.append(contentsOf: timeInsights)
        
        // Analyze notes to detect potential emotional triggers
        let triggerInsights = detectEmotionalTriggers(emotionalStates: emotionalStates)
        insights.append(contentsOf: triggerInsights)
        
        // Analyze emotional balance (positive vs. negative emotions)
        // Identify most frequent and most intense emotions
        
        // Calculate confidence levels for each insight
        // Generate recommended actions for each insight
        
        // Publish significant insights to insightSubject
        for insight in insights {
            publishInsight(insight: insight)
        }
        
        return insights
    }
    
    /// Performs comprehensive analysis on emotional history data
    /// - Parameter emotionalStates: An array of EmotionalState objects
    /// - Returns: A tuple containing arrays of trends and insights
    func analyzeEmotionalHistory(emotionalStates: [EmotionalState]) -> (trends: [EmotionalTrend], insights: [EmotionalInsight]) {
        // Check if there are enough data points for analysis
        guard emotionalStates.count >= minimumDataPointsForAnalysis else {
            Logger.shared.warning("Insufficient data points for emotional history analysis", category: .emotions)
            return ([], [])
        }
        
        // Generate trends using generateTrends method with monthly period
        let trends = generateTrends(emotionalStates: emotionalStates, periodType: .monthly)
        
        // Detect patterns using detectPatterns method
        let insights = detectPatterns(emotionalStates: emotionalStates)
        
        // Analyze emotional balance (positive vs. negative emotions)
        // Identify most frequent and most intense emotions
        // Generate additional insights based on overall emotional health
        
        return (trends, insights)
    }
    
    /// Returns a publisher that emits emotional insights
    /// - Returns: A publisher for emotional insights
    func getInsightPublisher() -> AnyPublisher<EmotionalInsight, Never> {
        return insightSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculates the direction of a trend from data points
    /// - Parameter dataPoints: An array of TrendDataPoint objects
    /// - Returns: The direction of the trend
    private func calculateTrendDirection(dataPoints: [TrendDataPoint]) -> TrendDirection {
        // Sort data points by date
        let sortedDataPoints = dataPoints.sorted { $0.date < $1.date }
        
        // If fewer than 3 points, return .stable
        guard sortedDataPoints.count >= 3 else {
            return .stable
        }
        
        // Calculate linear regression slope
        let n = sortedDataPoints.count
        let sumX = sortedDataPoints.enumerated().reduce(0.0) { $0 + Double($1.offset) }
        let sumY = sortedDataPoints.reduce(0.0) { $0 + Double($1.value) }
        let sumXY = sortedDataPoints.enumerated().reduce(0.0) { $0 + Double($1.offset) * Double($1.value) }
        let sumX2 = sortedDataPoints.enumerated().reduce(0.0) { $0 + pow(Double($1.offset), 2) }
        
        let slope = (Double(n) * sumXY - sumX * sumY) / (Double(n) * sumX2 - pow(sumX, 2))
        
        // Calculate variance to detect fluctuation
        let mean = sumY / Double(n)
        let variance = sortedDataPoints.reduce(0.0) { $0 + pow(Double($1.value) - mean, 2) } / Double(n)
        
        // If variance is high, return .fluctuating
        if variance > 5 { // Adjust threshold as needed
            return .fluctuating
        }
        
        // If slope is positive above threshold, return .increasing
        if slope > 0.5 { // Adjust threshold as needed
            return .increasing
        }
        
        // If slope is negative below threshold, return .decreasing
        if slope < -0.5 { // Adjust threshold as needed
            return .decreasing
        }
        
        return .stable
    }
    
    /// Generates insights based on emotional shift
    /// - Parameters:
    ///   - preState: The emotional state before an event
    ///   - postState: The emotional state after an event
    ///   - emotionChanged: A boolean indicating if the emotion changed
    ///   - intensityChange: The change in intensity
    /// - Returns: An array of insights based on the shift
    private func generateInsightForShift(preState: EmotionalState, postState: EmotionalState, emotionChanged: Bool, intensityChange: Int) -> [EmotionalInsight] {
        var insights: [EmotionalInsight] = []
        
        // Determine if shift is positive (toward positive emotions or lower intensity of negative)
        let preCategory = preState.emotionType.category()
        let postCategory = postState.emotionType.category()
        let isPositiveShift = (postCategory == .positive && preCategory != .positive) || (preCategory == .negative && intensityChange < 0)
        
        // If positive shift, create improvement insight
        if isPositiveShift {
            let improvementInsight = EmotionalInsight(
                type: .improvement,
                description: "Has experimentado una mejora en tu estado emocional después de la actividad.",
                relatedEmotions: [preState.emotionType, postState.emotionType],
                confidence: 0.7,
                recommendedActions: ["Continúa practicando esta actividad regularmente."]
            )
            insights.append(improvementInsight)
        }
        
        // If significant intensity change, create insight about intensity change
        if abs(intensityChange) > 3 {
            let intensityInsight = EmotionalInsight(
                type: .pattern,
                description: "Hubo un cambio significativo en la intensidad de tus emociones.",
                relatedEmotions: [preState.emotionType, postState.emotionType],
                confidence: 0.6,
                recommendedActions: ["Presta atención a los factores que influyen en la intensidad de tus emociones."]
            )
            insights.append(intensityInsight)
        }
        
        // If emotion type changed, create insight about emotional transition
        if emotionChanged {
            let transitionInsight = EmotionalInsight(
                type: .pattern,
                description: "Hubo una transición notable entre tus emociones.",
                relatedEmotions: [preState.emotionType, postState.emotionType],
                confidence: 0.5,
                recommendedActions: ["Reflexiona sobre las razones detrás de este cambio emocional."]
            )
            insights.append(transitionInsight)
        }
        
        return insights
    }
    
    /// Detects patterns related to time of day or day of week
    /// - Parameter emotionalStates: An array of EmotionalState objects
    /// - Returns: An array of time-based pattern insights
    private func detectTimePatterns(emotionalStates: [EmotionalState]) -> [EmotionalInsight] {
        var insights: [EmotionalInsight] = []
        
        // Group emotional states by time of day (morning/afternoon/evening)
        let calendar = Calendar.current
        let morning = emotionalStates.filter { calendar.component(.hour, from: $0.createdAt) >= 6 && calendar.component(.hour, from: $0.createdAt) < 12 }
        let afternoon = emotionalStates.filter { calendar.component(.hour, from: $0.createdAt) >= 12 && calendar.component(.hour, from: $0.createdAt) < 18 }
        let evening = emotionalStates.filter { calendar.component(.hour, from: $0.createdAt) >= 18 && calendar.component(.hour, from: $0.createdAt) < 22 }
        let night = emotionalStates.filter { calendar.component(.hour, from: $0.createdAt) >= 22 || calendar.component(.hour, from: $0.createdAt) < 6 }
        
        // Group emotional states by day of week
        let weekdays = emotionalStates.filter { calendar.component(.weekday, from: $0.createdAt) >= 2 && calendar.component(.weekday, from: $0.createdAt) <= 6 }
        let weekends = emotionalStates.filter { calendar.component(.weekday, from: $0.createdAt) == 1 || calendar.component(.weekday, from: $0.createdAt) == 7 }
        
        // Calculate average intensity for each time period
        let avgMorningIntensity = Double(morning.reduce(0) { $0 + $1.intensity }) / Double(morning.count)
        let avgAfternoonIntensity = Double(afternoon.reduce(0) { $0 + $1.intensity }) / Double(afternoon.count)
        let avgEveningIntensity = Double(evening.reduce(0) { $0 + $1.intensity }) / Double(evening.count)
        let avgNightIntensity = Double(night.reduce(0) { $0 + $1.intensity }) / Double(night.count)
        
        let avgWeekdayIntensity = Double(weekdays.reduce(0) { $0 + $1.intensity }) / Double(weekdays.count)
        let avgWeekendIntensity = Double(weekends.reduce(0) { $0 + $1.intensity }) / Double(weekends.count)
        
        // Identify time periods with consistently higher negative emotions
        if avgMorningIntensity > 6 {
            let insight = EmotionalInsight(
                type: .pattern,
                description: "Tus emociones tienden a ser más intensas por las mañanas.",
                relatedEmotions: EmotionType.allCases,
                confidence: 0.6,
                recommendedActions: ["Intenta comenzar el día con una actividad relajante."]
            )
            insights.append(insight)
        }
        
        // Identify time periods with consistently higher positive emotions
        if avgEveningIntensity < 4 {
            let insight = EmotionalInsight(
                type: .pattern,
                description: "Tus emociones tienden a ser más tranquilas por las noches.",
                relatedEmotions: EmotionType.allCases,
                confidence: 0.6,
                recommendedActions: ["Aprovecha este tiempo para relajarte y prepararte para dormir."]
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    /// Analyzes notes to detect potential emotional triggers
    /// - Parameter emotionalStates: An array of EmotionalState objects
    /// - Returns: An array of trigger-based insights
    private func detectEmotionalTriggers(emotionalStates: [EmotionalState]) -> [EmotionalInsight] {
        var insights: [EmotionalInsight] = []
        
        // Filter states with notes
        let statesWithNotes = emotionalStates.filter { $0.notes != nil && !$0.notes!.isEmpty }
        
        // Perform basic natural language processing on notes
        // Identify common keywords associated with specific emotions
        // Group by emotion type and analyze common themes in notes
        
        // Generate trigger insights for consistent patterns
        if statesWithNotes.count > 5 {
            let insight = EmotionalInsight(
                type: .trigger,
                description: "Has identificado posibles desencadenantes emocionales en tus notas.",
                relatedEmotions: EmotionType.allCases,
                confidence: 0.5,
                recommendedActions: ["Presta atención a estos desencadenantes y busca formas de manejarlos."]
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    /// Publishes a significant insight to subscribers
    /// - Parameter insight: The insight to publish
    private func publishInsight(insight: EmotionalInsight) {
        // Check if insight confidence is above threshold
        guard insight.confidence > 0.4 else {
            return
        }
        
        // Publish to insightSubject
        insightSubject.send(insight)
        
        // Log the published insight
        Logger.shared.log("Published insight: \(insight.description)", category: .emotions)
    }
}