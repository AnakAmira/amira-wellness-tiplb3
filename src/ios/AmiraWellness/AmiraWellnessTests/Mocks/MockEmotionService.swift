import Foundation // standard library
import Combine // Reactive programming for asynchronous operations

// Internal imports
import EmotionalState // Core data model for emotional states
import EmotionType // Enumeration of emotion types
import CheckInContext // Contexts in which emotional check-ins occur
import EmotionalTrend // Model for representing emotional trends over time
import EmotionalTrendRequest // Request parameters for trend analysis
import EmotionalTrendResponse // Response data from trend analysis
import EmotionalInsight // Insights derived from emotional data analysis
import EmotionServiceError // Error types for emotion service operations

/// A mock implementation of the EmotionService for unit testing
class MockEmotionService {
    
    /// Mock response for recordEmotionalState method
    var recordEmotionalStateResult: Result<EmotionalState, EmotionServiceError>?
    
    /// Mock response for getEmotionalHistory method
    var getEmotionalHistoryResult: Result<[EmotionalState], EmotionServiceError>?
    
    /// Mock response for getEmotionalTrends method
    var getEmotionalTrendsResult: Result<EmotionalTrendResponse, EmotionServiceError>?
    
    /// Mock response for analyzeEmotionalShift method
    var analyzeEmotionalShiftResult: Result<(emotionChanged: Bool, intensityChange: Int, insights: [EmotionalInsight]), EmotionServiceError>?
    
    /// Array to store recorded emotional states
    var recordedEmotionalStates: [EmotionalState] = []
    
    /// Counter for recordEmotionalState calls
    var recordEmotionalStateCallCount: Int = 0
    
    /// Counter for getEmotionalHistory calls
    var getEmotionalHistoryCallCount: Int = 0
    
    /// Counter for getEmotionalTrends calls
    var getEmotionalTrendsCallCount: Int = 0
    
    /// Counter for analyzeEmotionalShift calls
    var analyzeEmotionalShiftCallCount: Int = 0
    
    /// Last recorded emotion type
    var lastRecordedEmotionType: EmotionType?
    
    /// Last recorded intensity
    var lastRecordedIntensity: Int?
    
    /// Last recorded context
    var lastRecordedContext: CheckInContext?
    
    /// Last requested period type
    var lastRequestedPeriodType: TrendPeriodType?
    
    /// Last requested start date
    var lastRequestedStartDate: Date?
    
    /// Last requested end date
    var lastRequestedEndDate: Date?
    
    /// Last requested emotion types
    var lastRequestedEmotionTypes: [EmotionType]?
    
    /// Last analyzed pre-emotional state
    var lastAnalyzedPreState: EmotionalState?
    
    /// Last analyzed post-emotional state
    var lastAnalyzedPostState: EmotionalState?
    
    /// Subject for publishing emotional states
    private let emotionalStateSubject = PassthroughSubject<EmotionalState, Never>()
    
    /// Subject for publishing emotional insights
    private let insightSubject = PassthroughSubject<EmotionalInsight, Never>()
    
    /// Initializes the MockEmotionService with default values
    init() {
        recordedEmotionalStates = []
        recordEmotionalStateCallCount = 0
        getEmotionalHistoryCallCount = 0
        getEmotionalTrendsCallCount = 0
        analyzeEmotionalShiftCallCount = 0
    }
    
    /// Resets all mock responses and counters
    func reset() {
        recordEmotionalStateResult = nil
        getEmotionalHistoryResult = nil
        getEmotionalTrendsResult = nil
        analyzeEmotionalShiftResult = nil
        recordedEmotionalStates = []
        recordEmotionalStateCallCount = 0
        getEmotionalHistoryCallCount = 0
        getEmotionalTrendsCallCount = 0
        analyzeEmotionalShiftCallCount = 0
        lastRecordedEmotionType = nil
        lastRecordedIntensity = nil
        lastRecordedContext = nil
        lastRequestedPeriodType = nil
        lastRequestedStartDate = nil
        lastRequestedEndDate = nil
        lastRequestedEmotionTypes = nil
        lastAnalyzedPreState = nil
        lastAnalyzedPostState = nil
    }
    
    /// Mock implementation of the recordEmotionalState method
    /// - Parameters:
    ///   - emotionType: The emotion type
    ///   - intensity: The intensity
    ///   - context: The context
    ///   - notes: Optional notes
    ///   - relatedJournalId: Optional journal ID
    ///   - relatedToolId: Optional tool ID
    ///   - completion: Completion handler
    func recordEmotionalState(emotionType: EmotionType, intensity: Int, context: CheckInContext, notes: String? = nil, relatedJournalId: UUID? = nil, relatedToolId: UUID? = nil, completion: @escaping (Result<EmotionalState, EmotionServiceError>) -> Void) {
        recordEmotionalStateCallCount += 1
        lastRecordedEmotionType = emotionType
        lastRecordedIntensity = intensity
        lastRecordedContext = context
        
        if let result = recordEmotionalStateResult {
            completion(result)
        } else {
            let newEmotionalState = EmotionalState(emotionType: emotionType, intensity: intensity, context: context, notes: notes, relatedJournalId: relatedJournalId, relatedToolId: relatedToolId)
            recordedEmotionalStates.append(newEmotionalState)
            emotionalStateSubject.send(newEmotionalState)
            completion(.success(newEmotionalState))
        }
    }
    
    /// Mock implementation of the recordEmotionalStateAsync method
    /// - Parameters:
    ///   - emotionType: The emotion type
    ///   - intensity: The intensity
    ///   - context: The context
    ///   - notes: Optional notes
    ///   - relatedJournalId: Optional journal ID
    ///   - relatedToolId: Optional tool ID
    /// - Returns: The recorded emotional state
    @available(iOS 15.0, *)
    func recordEmotionalStateAsync(emotionType: EmotionType, intensity: Int, context: CheckInContext, notes: String? = nil, relatedJournalId: UUID? = nil, relatedToolId: UUID? = nil) async throws -> EmotionalState {
        recordEmotionalStateCallCount += 1
        lastRecordedEmotionType = emotionType
        lastRecordedIntensity = intensity
        lastRecordedContext = context
        
        if let result = recordEmotionalStateResult {
            switch result {
            case .success(let emotionalState):
                return emotionalState
            case .failure(let error):
                throw error
            }
        } else {
            let newEmotionalState = EmotionalState(emotionType: emotionType, intensity: intensity, context: context, notes: notes, relatedJournalId: relatedJournalId, relatedToolId: relatedToolId)
            recordedEmotionalStates.append(newEmotionalState)
            emotionalStateSubject.send(newEmotionalState)
            return newEmotionalState
        }
    }
    
    /// Mock implementation of the getEmotionalHistory method
    /// - Parameters:
    ///   - startDate: Optional start date
    ///   - endDate: Optional end date
    ///   - page: Optional page number
    ///   - pageSize: Optional page size
    ///   - completion: Completion handler
    func getEmotionalHistory(startDate: Date? = nil, endDate: Date? = nil, page: Int? = nil, pageSize: Int? = nil, completion: @escaping (Result<[EmotionalState], EmotionServiceError>) -> Void) {
        getEmotionalHistoryCallCount += 1
        lastRequestedStartDate = startDate
        lastRequestedEndDate = endDate
        
        if let result = getEmotionalHistoryResult {
            completion(result)
        } else {
            completion(.success(recordedEmotionalStates))
        }
    }
    
    /// Mock implementation of the getEmotionalHistoryAsync method
    /// - Parameters:
    ///   - startDate: Optional start date
    ///   - endDate: Optional end date
    ///   - page: Optional page number
    ///   - pageSize: Optional page size
    /// - Returns: Array of emotional states
    @available(iOS 15.0, *)
    func getEmotionalHistoryAsync(startDate: Date? = nil, endDate: Date? = nil, page: Int? = nil, pageSize: Int? = nil) async throws -> [EmotionalState] {
        getEmotionalHistoryCallCount += 1
        lastRequestedStartDate = startDate
        lastRequestedEndDate = endDate
        
        if let result = getEmotionalHistoryResult {
            switch result {
            case .success(let emotionalStates):
                return emotionalStates
            case .failure(let error):
                throw error
            }
        } else {
            return recordedEmotionalStates
        }
    }
    
    /// Mock implementation of the getEmotionalTrends method
    /// - Parameters:
    ///   - periodType: The period type
    ///   - startDate: Optional start date
    ///   - endDate: Optional end date
    ///   - emotionTypes: Optional emotion types
    ///   - completion: Completion handler
    func getEmotionalTrends(periodType: TrendPeriodType, startDate: Date? = nil, endDate: Date? = nil, emotionTypes: [EmotionType]? = nil, completion: @escaping (Result<EmotionalTrendResponse, EmotionServiceError>) -> Void) {
        getEmotionalTrendsCallCount += 1
        lastRequestedPeriodType = periodType
        lastRequestedStartDate = startDate
        lastRequestedEndDate = endDate
        lastRequestedEmotionTypes = emotionTypes
        
        if let result = getEmotionalTrendsResult {
            completion(result)
        } else {
            let defaultResponse = EmotionalTrendResponse(trends: [], insights: [])
            completion(.success(defaultResponse))
        }
    }
    
    /// Mock implementation of the getEmotionalTrendsAsync method
    /// - Parameters:
    ///   - periodType: The period type
    ///   - startDate: Optional start date
    ///   - endDate: Optional end date
    ///   - emotionTypes: Optional emotion types
    /// - Returns: Trend analysis response
    @available(iOS 15.0, *)
    func getEmotionalTrendsAsync(periodType: TrendPeriodType, startDate: Date? = nil, endDate: Date? = nil, emotionTypes: [EmotionType]? = nil) async throws -> EmotionalTrendResponse {
        getEmotionalTrendsCallCount += 1
        lastRequestedPeriodType = periodType
        lastRequestedStartDate = startDate
        lastRequestedEndDate = endDate
        lastRequestedEmotionTypes = emotionTypes
        
        if let result = getEmotionalTrendsResult {
            switch result {
            case .success(let trendResponse):
                return trendResponse
            case .failure(let error):
                throw error
            }
        } else {
            let defaultResponse = EmotionalTrendResponse(trends: [], insights: [])
            return defaultResponse
        }
    }
    
    /// Mock implementation of the analyzeEmotionalShift method
    /// - Parameters:
    ///   - preState: The pre-emotional state
    ///   - postState: The post-emotional state
    ///   - completion: Completion handler
    func analyzeEmotionalShift(preState: EmotionalState, postState: EmotionalState, completion: @escaping (Result<(emotionChanged: Bool, intensityChange: Int, insights: [EmotionalInsight]), EmotionServiceError>) -> Void) {
        analyzeEmotionalShiftCallCount += 1
        lastAnalyzedPreState = preState
        lastAnalyzedPostState = postState
        
        if let result = analyzeEmotionalShiftResult {
            completion(result)
        } else {
            let defaultResult = (emotionChanged: true, intensityChange: 2, insights: [])
            completion(.success(defaultResult))
        }
    }
    
    /// Mock implementation of the analyzeEmotionalShiftAsync method
    /// - Parameters:
    ///   - preState: The pre-emotional state
    ///   - postState: The post-emotional state
    /// - Returns: Analysis results
    @available(iOS 15.0, *)
    func analyzeEmotionalShiftAsync(preState: EmotionalState, postState: EmotionalState) async throws -> (emotionChanged: Bool, intensityChange: Int, insights: [EmotionalInsight]) {
        analyzeEmotionalShiftCallCount += 1
        lastAnalyzedPreState = preState
        lastAnalyzedPostState = postState
        
        if let result = analyzeEmotionalShiftResult {
            switch result {
            case .success(let shiftResult):
                return shiftResult
            case .failure(let error):
                throw error
            }
        } else {
            let defaultResult = (emotionChanged: true, intensityChange: 2, insights: [])
            return defaultResult
        }
    }
    
    /// Mock implementation of the getEmotionalStatePublisher method
    /// - Returns: Publisher for emotional states
    func getEmotionalStatePublisher() -> AnyPublisher<EmotionalState, Never> {
        return emotionalStateSubject.eraseToAnyPublisher()
    }
    
    /// Mock implementation of the getInsightPublisher method
    /// - Returns: Publisher for emotional insights
    func getInsightPublisher() -> AnyPublisher<EmotionalInsight, Never> {
        return insightSubject.eraseToAnyPublisher()
    }
    
    /// Publishes a mock emotional state to subscribers
    /// - Parameter emotionalState: The emotional state to publish
    func publishMockEmotionalState(emotionalState: EmotionalState) {
        emotionalStateSubject.send(emotionalState)
    }
    
    /// Publishes a mock emotional insight to subscribers
    /// - Parameter insight: The emotional insight to publish
    func publishMockInsight(insight: EmotionalInsight) {
        insightSubject.send(insight)
    }
}