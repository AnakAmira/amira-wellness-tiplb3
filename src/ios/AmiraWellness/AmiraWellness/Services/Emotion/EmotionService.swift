import Foundation // standard library
import Combine // Reactive programming for asynchronous operations

// Internal imports
import EmotionalState // Core data model for emotional states
import EmotionType // Enumeration of emotion types
import CheckInContext // Contexts in which emotional check-ins occur
import EmotionalTrend // Model for representing emotional trends over time
import EmotionalTrendRequest // Request parameters for trend analysis
import EmotionalTrendResponse // Response data from trend analysis
import APIClient // Network communication for emotional data operations
import APIRouter // API endpoint definitions for emotional data
import APIError // Error handling for API operations
import EmotionAnalysisService // Analysis of emotional data for insights and trends
import SecureStorageService // Secure storage of emotional data locally
import Logger // Logging service operations and errors

/// Enum defining possible errors that can occur during emotion service operations
enum EmotionServiceError: Error {
    case invalidEmotionalState
    case storageError
    case networkError
    case analysisError
    case notFound
}

/// Service responsible for managing emotional data operations in the application
class EmotionService {
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient // API client for network requests
    private let storageService: SecureStorageService // Secure storage service for local data persistence
    private let analysisService: EmotionAnalysisService // Service for analyzing emotional data
    private let emotionalStateSubject = PassthroughSubject<EmotionalState, Never>() // Subject for publishing emotional states
    private var cancellables: Set<AnyCancellable> = [] // Set to hold Combine cancellables
    private let localStorageKey = "emotional_states" // Key for storing emotional states in local storage
    
    // MARK: - Initialization
    
    /// Initializes the EmotionService with dependencies
    /// - Parameters:
    ///   - apiClient: Optional APIClient for network requests
    ///   - storageService: Optional SecureStorageService for local data persistence
    ///   - analysisService: Optional EmotionAnalysisService for analyzing emotional data
    init(apiClient: APIClient? = nil, secureStorageService: SecureStorageService? = nil, analysisService: EmotionAnalysisService? = nil) {
        self.apiClient = apiClient ?? APIClient.shared // Store the provided apiClient or use APIClient.shared
        self.storageService = secureStorageService ?? SecureStorageService.shared // Store the provided storageService or use default implementation
        self.analysisService = analysisService ?? EmotionAnalysisService() // Store the provided analysisService or create a new instance
        self.emotionalStateSubject = PassthroughSubject<EmotionalState, Never>() // Initialize emotionalStateSubject for publishing emotional states
        self.cancellables = [] // Initialize cancellables set for storing subscriptions
        // Set localStorageKey to 'emotional_states'
    }
    
    // MARK: - Public Methods
    
    /// Records a new emotional state and saves it to the server
    /// - Parameters:
    ///   - emotionType: The type of emotion
    ///   - intensity: The intensity of the emotion (1-10)
    ///   - context: The context in which the emotional state is recorded
    ///   - notes: Optional notes about the emotional state
    ///   - relatedJournalId: Optional ID of the related journal entry
    ///   - relatedToolId: Optional ID of the related tool
    ///   - completion: Completion handler with the result
    func recordEmotionalState(emotionType: EmotionType, intensity: Int, context: CheckInContext, notes: String? = nil, relatedJournalId: UUID? = nil, relatedToolId: UUID? = nil, completion: @escaping (Result<EmotionalState, EmotionServiceError>) -> Void) {
        // Create a new EmotionalState with the provided parameters
        let emotionalState = EmotionalState(emotionType: emotionType, intensity: intensity, context: context, notes: notes, relatedJournalId: relatedJournalId, relatedToolId: relatedToolId)
        
        // Validate the emotional state using isValid()
        guard emotionalState.isValid() else {
            Logger.shared.error("Invalid emotional state", category: .emotions)
            completion(.failure(.invalidEmotionalState)) // If invalid, return invalidEmotionalState error
            return
        }
        
        // Create API request using APIRouter.recordEmotionalState
        let endpoint = APIRouter.recordEmotionalState(emotionType: emotionType.rawValue, intensity: intensity, notes: notes, context: context.rawValue)
        
        // Send request using apiClient.request
        apiClient.request(endpoint: endpoint) { (result: Result<EmotionalState, APIError>) in
            switch result {
            case .success(let recordedState):
                // Save the emotional state locally
                self.saveEmotionalStateLocally(emotionalState: recordedState)
                
                // Publish the new emotional state to emotionalStateSubject
                self.emotionalStateSubject.send(recordedState)
                
                // Call completion handler with success result
                completion(.success(recordedState))
                
                Logger.shared.info("Successfully recorded emotional state", category: .emotions)
                
            case .failure(let error):
                // Call completion handler with appropriate error
                Logger.shared.error("Failed to record emotional state: \(error)", category: .emotions)
                completion(.failure(.networkError))
            }
        }
    }
    
    /// Records a new emotional state using async/await
    /// - Parameters:
    ///   - emotionType: The type of emotion
    ///   - intensity: The intensity of the emotion (1-10)
    ///   - context: The context in which the emotional state is recorded
    ///   - notes: Optional notes about the emotional state
    ///   - relatedJournalId: Optional ID of the related journal entry
    ///   - relatedToolId: Optional ID of the related tool
    /// - Returns: The recorded emotional state or throws an error
    @available(iOS 15.0, *)
    func recordEmotionalStateAsync(emotionType: EmotionType, intensity: Int, context: CheckInContext, notes: String? = nil, relatedJournalId: UUID? = nil, relatedToolId: UUID? = nil) async throws -> EmotionalState {
        // Create a new EmotionalState with the provided parameters
        let emotionalState = EmotionalState(emotionType: emotionType, intensity: intensity, context: context, notes: notes, relatedJournalId: relatedJournalId, relatedToolId: relatedToolId)
        
        // Validate the emotional state using isValid()
        guard emotionalState.isValid() else {
            Logger.shared.error("Invalid emotional state", category: .emotions)
            throw EmotionServiceError.invalidEmotionalState // If invalid, throw invalidEmotionalState error
        }
        
        // Create API request using APIRouter.recordEmotionalState
        let endpoint = APIRouter.recordEmotionalState(emotionType: emotionType.rawValue, intensity: intensity, notes: notes, context: context.rawValue)
        
        do {
            // Send request using apiClient.requestAsync
            let recordedState = try await apiClient.requestAsync(endpoint: endpoint) as EmotionalState
            
            // Save the emotional state locally
            self.saveEmotionalStateLocally(emotionalState: recordedState)
            
            // Publish the new emotional state to emotionalStateSubject
            self.emotionalStateSubject.send(recordedState)
            
            Logger.shared.info("Successfully recorded emotional state", category: .emotions)
            
            // Return the emotional state
            return recordedState
        } catch {
            // Throw appropriate error
            Logger.shared.error("Failed to record emotional state: \(error)", category: .emotions)
            throw EmotionServiceError.networkError
        }
    }
    
    /// Retrieves the user's emotional history with optional filtering
    /// - Parameters:
    ///   - startDate: Optional start date for filtering
    ///   - endDate: Optional end date for filtering
    ///   - page: Optional page number for pagination
    ///   - pageSize: Optional page size for pagination
    ///   - completion: Completion handler with the result
    func getEmotionalHistory(startDate: Date? = nil, endDate: Date? = nil, page: Int? = nil, pageSize: Int? = nil, completion: @escaping (Result<[EmotionalState], EmotionServiceError>) -> Void) {
        // Create API request using APIRouter.getEmotionalHistory
        let endpoint = APIRouter.getEmotionalHistory(startDate: startDate, endDate: endDate, page: page, pageSize: pageSize)
        
        // Send request using apiClient.requestPaginated
        apiClient.requestPaginated(endpoint: endpoint) { (result: Result<PaginatedAPIResponse<EmotionalState>, APIError>) in
            switch result {
            case .success(let paginatedResponse):
                // Parse the response data into EmotionalState objects
                let emotionalStates = paginatedResponse.items
                
                // Save the emotional states locally for offline access
                // TODO: Implement local caching strategy
                
                // Call completion handler with success result
                completion(.success(emotionalStates))
                
                Logger.shared.info("Successfully retrieved emotional history", category: .emotions)
                
            case .failure(let error):
                // Attempt to load cached data from local storage
                if let cachedStates = self.loadEmotionalStatesLocally() {
                    // If cached data exists, return it with completion handler
                    completion(.success(cachedStates))
                    Logger.shared.info("Retrieved emotional history from local cache", category: .emotions)
                } else {
                    // Otherwise, call completion handler with appropriate error
                    Logger.shared.error("Failed to retrieve emotional history: \(error)", category: .emotions)
                    completion(.failure(.networkError))
                }
            }
        }
    }
    
    /// Retrieves the user's emotional history using async/await
    /// - Parameters:
    ///   - startDate: Optional start date for filtering
    ///   - endDate: Optional end date for filtering
    ///   - page: Optional page number for pagination
    ///   - pageSize: Optional page size for pagination
    /// - Returns: Array of emotional states or throws an error
    @available(iOS 15.0, *)
    func getEmotionalHistoryAsync(startDate: Date? = nil, endDate: Date? = nil, page: Int? = nil, pageSize: Int? = nil) async throws -> [EmotionalState] {
        // Create API request using APIRouter.getEmotionalHistory
        let endpoint = APIRouter.getEmotionalHistory(startDate: startDate, endDate: endDate, page: page, pageSize: pageSize)
        
        do {
            // Send request using apiClient.requestPaginatedAsync
            let paginatedResponse = try await apiClient.requestPaginatedAsync(endpoint: endpoint) as PaginatedAPIResponse<EmotionalState>
            
            // Parse the response data into EmotionalState objects
            let emotionalStates = paginatedResponse.items
            
            // Save the emotional states locally for offline access
            // TODO: Implement local caching strategy
            
            Logger.shared.info("Successfully retrieved emotional history", category: .emotions)
            
            // Return the array of emotional states
            return emotionalStates
        } catch {
            // Attempt to load cached data from local storage
            if let cachedStates = self.loadEmotionalStatesLocally() {
                // If cached data exists, return it
                Logger.shared.info("Retrieved emotional history from local cache", category: .emotions)
                return cachedStates
            } else {
                // Otherwise, throw appropriate error
                Logger.shared.error("Failed to retrieve emotional history: \(error)", category: .emotions)
                throw EmotionServiceError.networkError
            }
        }
    }
    
    /// Retrieves emotional trends for the specified time period
    /// - Parameters:
    ///   - periodType: The time period for trend analysis
    ///   - startDate: Optional start date for filtering
    ///   - endDate: Optional end date for filtering
    ///   - emotionTypes: Optional array of emotion types to include in the analysis
    ///   - completion: Completion handler with the result
    func getEmotionalTrends(periodType: TrendPeriodType, startDate: Date? = nil, endDate: Date? = nil, emotionTypes: [EmotionType]? = nil, completion: @escaping (Result<EmotionalTrendResponse, EmotionServiceError>) -> Void) {
        // Create EmotionalTrendRequest with the provided parameters
        guard let startDate = startDate, let endDate = endDate else {
            Logger.shared.error("Start date or end date is nil", category: .emotions)
            completion(.failure(.invalidRequest))
            return
        }
        let request = EmotionalTrendRequest(periodType: periodType, startDate: startDate, endDate: endDate, emotionTypes: emotionTypes)
        
        // Validate the request using isValid()
        guard request.isValid() else {
            Logger.shared.error("Invalid emotional trend request", category: .emotions)
            completion(.failure(.invalidRequest)) // If invalid, return invalidRequest error
            return
        }
        
        // Create API request using APIRouter.getEmotionalTrends
        let endpoint = APIRouter.getEmotionalTrends(startDate: request.startDate, endDate: request.endDate)
        
        // Send request using apiClient.request
        apiClient.request(endpoint: endpoint) { (result: Result<EmotionalTrendResponse, APIError>) in
            switch result {
            case .success(let trendResponse):
                // Call completion handler with success result
                completion(.success(trendResponse))
                Logger.shared.info("Successfully retrieved emotional trends", category: .emotions)
                
            case .failure(let error):
                // Attempt to generate trends locally using analysisService
                if let localTrends = self.generateLocalTrends(periodType: periodType, startDate: startDate, endDate: endDate, emotionTypes: emotionTypes) {
                    // If local generation succeeds, return the result with completion handler
                    completion(.success(localTrends))
                    Logger.shared.info("Retrieved emotional trends from local generation", category: .emotions)
                } else {
                    // Otherwise, call completion handler with appropriate error
                    Logger.shared.error("Failed to retrieve emotional trends: \(error)", category: .emotions)
                    completion(.failure(.networkError))
                }
            }
        }
    }
    
    /// Retrieves emotional trends using async/await
    /// - Parameters:
    ///   - periodType: The time period for trend analysis
    ///   - startDate: Optional start date for filtering
    ///   - endDate: Optional end date for filtering
    ///   - emotionTypes: Optional array of emotion types to include in the analysis
    /// - Returns: Trend analysis response or throws an error
    @available(iOS 15.0, *)
    func getEmotionalTrendsAsync(periodType: TrendPeriodType, startDate: Date? = nil, endDate: Date? = nil, emotionTypes: [EmotionType]? = nil) async throws -> EmotionalTrendResponse {
        // Create EmotionalTrendRequest with the provided parameters
        guard let startDate = startDate, let endDate = endDate else {
            Logger.shared.error("Start date or end date is nil", category: .emotions)
            throw EmotionServiceError.invalidRequest
        }
        let request = EmotionalTrendRequest(periodType: periodType, startDate: startDate, endDate: endDate, emotionTypes: emotionTypes)
        
        // Validate the request using isValid()
        guard request.isValid() else {
            Logger.shared.error("Invalid emotional trend request", category: .emotions)
            throw EmotionServiceError.invalidRequest // If invalid, throw invalidRequest error
        }
        
        // Create API request using APIRouter.getEmotionalTrends
        let endpoint = APIRouter.getEmotionalTrends(startDate: request.startDate, endDate: request.endDate)
        
        do {
            // Send request using apiClient.requestAsync
            let trendResponse = try await apiClient.requestAsync(endpoint: endpoint) as EmotionalTrendResponse
            
            Logger.shared.info("Successfully retrieved emotional trends", category: .emotions)
            
            // Return the trend response
            return trendResponse
        } catch {
            // Attempt to generate trends locally using analysisService
            if let localTrends = self.generateLocalTrends(periodType: periodType, startDate: startDate, endDate: endDate, emotionTypes: emotionTypes) {
                // If local generation succeeds, return the result
                Logger.shared.info("Retrieved emotional trends from local generation", category: .emotions)
                return localTrends
            } else {
                // Otherwise, throw appropriate error
                Logger.shared.error("Failed to retrieve emotional trends: \(error)", category: .emotions)
                throw EmotionServiceError.networkError
            }
        }
    }
    
    /// Analyzes the shift between pre and post emotional states
    /// - Parameters:
    ///   - preState: The emotional state before an event
    ///   - postState: The emotional state after an event
    ///   - completion: Completion handler with the analysis results
    func analyzeEmotionalShift(preState: EmotionalState, postState: EmotionalState, completion: @escaping (Result<(emotionChanged: Bool, intensityChange: Int, insights: [EmotionalInsight]), EmotionServiceError>) -> Void) {
        // Validate that preState context is preJournaling
        guard preState.context == .preJournaling else {
            Logger.shared.error("Invalid pre-emotional state context", category: .emotions)
            completion(.failure(.invalidEmotionalState)) // If contexts are invalid, return invalidEmotionalState error
            return
        }
        
        // Validate that postState context is postJournaling
        guard postState.context == .postJournaling else {
            Logger.shared.error("Invalid post-emotional state context", category: .emotions)
            completion(.failure(.invalidEmotionalState)) // If contexts are invalid, return invalidEmotionalState error
            return
        }
        
        // Use analysisService.analyzeEmotionalShift to analyze the shift
        let (emotionChanged, intensityChange, insights) = analysisService.analyzeEmotionalShift(preState: preState, postState: postState)
        
        // Call completion handler with the analysis results
        completion(.success((emotionChanged: emotionChanged, intensityChange: intensityChange, insights: insights)))
        
        Logger.shared.info("Successfully analyzed emotional shift", category: .emotions)
    }
    
    /// Analyzes the shift between pre and post emotional states using async/await
    /// - Parameters:
    ///   - preState: The emotional state before an event
    ///   - postState: The emotional state after an event
    /// - Returns: Analysis results or throws an error
    @available(iOS 15.0, *)
    func analyzeEmotionalShiftAsync(preState: EmotionalState, postState: EmotionalState) async throws -> (emotionChanged: Bool, intensityChange: Int, insights: [EmotionalInsight]) {
        // Validate that preState context is preJournaling
        guard preState.context == .preJournaling else {
            Logger.shared.error("Invalid pre-emotional state context", category: .emotions)
            throw EmotionServiceError.invalidEmotionalState // If contexts are invalid, throw invalidEmotionalState error
        }
        
        // Validate that postState context is postJournaling
        guard postState.context == .postJournaling else {
            Logger.shared.error("Invalid post-emotional state context", category: .emotions)
            throw EmotionServiceError.invalidEmotionalState // If contexts are invalid, throw invalidEmotionalState error
        }
        
        // Use analysisService.analyzeEmotionalShift to analyze the shift
        let (emotionChanged, intensityChange, insights) = analysisService.analyzeEmotionalShift(preState: preState, postState: postState)
        
        Logger.shared.info("Successfully analyzed emotional shift", category: .emotions)
        
        // Return the analysis results
        return (emotionChanged: emotionChanged, intensityChange: intensityChange, insights: insights)
    }
    
    /// Returns a publisher that emits emotional states as they are recorded
    /// - Returns: Publisher for emotional states
    func getEmotionalStatePublisher() -> AnyPublisher<EmotionalState, Never> {
        return emotionalStateSubject.eraseToAnyPublisher()
    }
    
    /// Returns a publisher that emits emotional insights
    /// - Returns: Publisher for emotional insights
    func getInsightPublisher() -> AnyPublisher<EmotionalInsight, Never> {
        return analysisService.getInsightPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Saves an emotional state to local secure storage
    /// - Parameter emotionalState: The emotional state to save
    /// - Returns: Success or failure of the save operation
    private func saveEmotionalStateLocally(emotionalState: EmotionalState) -> Bool {
        // Load existing emotional states from storage
        guard var emotionalStates = loadEmotionalStatesLocally() else {
            // If no existing states, create a new array
            let newArray = [emotionalState]
            
            // Save the updated array to secure storage
            let result = storageService.storeCodable(newArray, forKey: localStorageKey, dataType: .emotions, sensitivity: .sensitive)
            
            switch result {
            case .success():
                Logger.shared.info("Successfully saved new emotional state locally", category: .emotions)
                return true
            case .failure(let error):
                Logger.shared.error("Failed to save new emotional state locally: \(error)", category: .emotions)
                return false
            }
        }
        
        // Add the new emotional state to the array
        emotionalStates.append(emotionalState)
        
        // Save the updated array to secure storage
        let result = storageService.storeCodable(emotionalStates, forKey: localStorageKey, dataType: .emotions, sensitivity: .sensitive)
        
        switch result {
        case .success():
            Logger.shared.info("Successfully saved emotional state locally", category: .emotions)
            return true
        case .failure(let error):
            Logger.shared.error("Failed to save emotional state locally: \(error)", category: .emotions)
            return false
        }
    }
    
    /// Loads emotional states from local secure storage
    /// - Returns: Array of emotional states or nil if not found
    private func loadEmotionalStatesLocally() -> [EmotionalState]? {
        // Attempt to load emotional states from secure storage
        let result: Result<[EmotionalState], StorageError> = storageService.retrieveCodable(forKey: localStorageKey, dataType: .emotions, sensitivity: .sensitive)
        
        switch result {
        case .success(let emotionalStates):
            Logger.shared.info("Successfully loaded emotional states from local storage", category: .emotions)
            return emotionalStates
        case .failure(let error):
            Logger.shared.error("Failed to load emotional states from local storage: \(error)", category: .emotions)
            return nil
        }
    }
    
    /// Generates emotional trends locally when network is unavailable
    /// - Parameters:
    ///   - periodType: The time period for trend analysis
    ///   - startDate: The start date for filtering
    ///   - endDate: The end date for filtering
    ///   - emotionTypes: Optional array of emotion types to include in the analysis
    /// - Returns: Generated trend response or nil if generation fails
    private func generateLocalTrends(periodType: TrendPeriodType, startDate: Date, endDate: Date, emotionTypes: [EmotionType]? = nil) -> EmotionalTrendResponse? {
        // Load emotional states from local storage
        guard let emotionalStates = loadEmotionalStatesLocally() else {
            Logger.shared.warning("No local emotional states found", category: .emotions)
            return nil // If no states are found, return nil
        }
        
        // Filter states by date range
        let filteredStates = emotionalStates.filter { $0.createdAt >= startDate && $0.createdAt <= endDate }
        
        // If emotionTypes is provided, filter by emotion types
        let emotionFilteredStates = emotionTypes != nil ? filteredStates.filter { emotionTypes!.contains($0.emotionType) } : filteredStates
        
        // Use analysisService.generateTrends to create trends
        let trends = analysisService.generateTrends(emotionalStates: emotionFilteredStates, periodType: periodType)
        
        // Use analysisService.detectPatterns to generate insights
        let insights = analysisService.detectPatterns(emotionalStates: emotionFilteredStates)
        
        // Create and return EmotionalTrendResponse with trends and insights
        let trendResponse = EmotionalTrendResponse(trends: trends, insights: insights)
        
        Logger.shared.info("Successfully generated local emotional trends", category: .emotions)
        
        return trendResponse
    }
}