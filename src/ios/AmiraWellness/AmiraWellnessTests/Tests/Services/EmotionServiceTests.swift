import XCTest // Swift testing framework
import Combine // Reactive programming for asynchronous operations

@testable import AmiraWellness // Import the module to be tested

/// Test suite for the EmotionService class
class EmotionServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    /// System under test
    var sut: EmotionService!
    
    /// Mock API client for testing network interactions
    var mockAPIClient: MockAPIClient!
    
    /// Mock storage service for testing data persistence
    var mockStorageService: MockStorageService!
    
    /// Mock analysis service for testing data analysis
    var mockAnalysisService: EmotionAnalysisService!
    
    /// Set to hold Combine cancellables
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and TearDown
    
    /// Set up test environment before each test
    override func setUp() {
        super.setUp() // Call super.setUp()
        mockAPIClient = MockAPIClient.shared // Initialize mockAPIClient with MockAPIClient.shared
        mockAPIClient.reset() // Reset mockAPIClient to clear previous test data
        mockStorageService = MockStorageService.shared // Initialize mockStorageService with MockStorageService.shared
        mockStorageService.reset() // Reset mockStorageService to clear previous test data
        mockAnalysisService = EmotionAnalysisService() // Initialize mockAnalysisService with EmotionAnalysisService()
        sut = EmotionService(apiClient: mockAPIClient, secureStorageService: mockStorageService, analysisService: mockAnalysisService) // Initialize sut (system under test) with EmotionService using mocks
        cancellables = [] // Initialize cancellables as empty Set<AnyCancellable>
    }
    
    /// Clean up test environment after each test
    override func tearDown() {
        cancellables.forEach { $0.cancel() } // Cancel all subscriptions in cancellables
        sut = nil // Set sut to nil
        super.tearDown() // Call super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test recording a valid emotional state successfully
    func testRecordEmotionalState_ValidState_Success() {
        // Create a mock emotional state response
        let mockEmotionalState = EmotionalState(emotionType: .joy, intensity: 7, context: .standalone)
        
        // Set up mockAPIClient to return success with the mock response
        mockAPIClient.setMockResponse(endpoint: .recordEmotionalState(emotionType: "joy", intensity: 7, notes: nil, context: "standalone"), result: .success(mockEmotionalState))
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Record emotional state success")
        
        // Call sut.recordEmotionalState with valid parameters
        sut.recordEmotionalState(emotionType: .joy, intensity: 7, context: .standalone) { result in
            // Verify the result is successful and contains the expected emotional state
            switch result {
            case .success(let state):
                XCTAssertEqual(state, mockEmotionalState, "The returned state should match the mock state")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got failure: \(error)")
            }
        }
        
        // Verify the API request was made with the correct endpoint
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .recordEmotionalState(emotionType: "joy", intensity: 7, notes: nil, context: "standalone")), 1, "API request should have been made")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test recording an invalid emotional state returns an error
    func testRecordEmotionalState_InvalidState_ReturnsError() {
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Record emotional state failure due to invalid state")
        
        // Call sut.recordEmotionalState with invalid intensity (0)
        sut.recordEmotionalState(emotionType: .joy, intensity: 0, context: .standalone) { result in
            // Verify the result is a failure with invalidEmotionalState error
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure(let error):
                XCTAssertEqual(error, EmotionServiceError.invalidEmotionalState, "Expected invalidEmotionalState error")
                expectation.fulfill()
            }
        }
        
        // Verify no API request was made
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .recordEmotionalState(emotionType: "joy", intensity: 0, notes: nil, context: "standalone")), 0, "API request should not have been made")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test recording emotional state with network error returns appropriate error
    func testRecordEmotionalState_NetworkError_ReturnsError() {
        // Set up mockAPIClient to return a network error
        mockAPIClient.setMockResponse(endpoint: .recordEmotionalState(emotionType: "joy", intensity: 7, notes: nil, context: "standalone"), result: .failure(.networkError(message: "Simulated network error")))
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Record emotional state failure due to network error")
        
        // Call sut.recordEmotionalState with valid parameters
        sut.recordEmotionalState(emotionType: .joy, intensity: 7, context: .standalone) { result in
            // Verify the result is a failure with networkError
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure(let error):
                XCTAssertEqual(error, EmotionServiceError.networkError, "Expected networkError")
                expectation.fulfill()
            }
        }
        
        // Verify the API request was attempted
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .recordEmotionalState(emotionType: "joy", intensity: 7, notes: nil, context: "standalone")), 1, "API request should have been made")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that recording an emotional state publishes to subscribers
    func testRecordEmotionalState_PublishesState() {
        // Create a mock emotional state response
        let mockEmotionalState = EmotionalState(emotionType: .joy, intensity: 7, context: .standalone)
        
        // Set up mockAPIClient to return success with the mock response
        mockAPIClient.setMockResponse(endpoint: .recordEmotionalState(emotionType: "joy", intensity: 7, notes: nil, context: "standalone"), result: .success(mockEmotionalState))
        
        // Create an expectation for the publisher
        let expectation = XCTestExpectation(description: "Emotional state published")
        
        // Subscribe to the emotional state publisher
        sut.getEmotionalStatePublisher()
            .sink { receivedState in
                // Verify the published state matches the expected state
                XCTAssertEqual(receivedState, mockEmotionalState, "Published state should match the mock state")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call sut.recordEmotionalState with valid parameters
        sut.recordEmotionalState(emotionType: .joy, intensity: 7, context: .standalone) { _ in }
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test retrieving emotional history successfully
    func testGetEmotionalHistory_Success() {
        // Create mock emotional states array
        let mockEmotionalStates = [
            EmotionalState(emotionType: .joy, intensity: 7, context: .standalone),
            EmotionalState(emotionType: .sadness, intensity: 3, context: .preJournaling)
        ]
        
        // Set up mockAPIClient to return success with the mock states
        mockAPIClient.setMockResponse(endpoint: .getEmotionalHistory(startDate: nil, endDate: nil, page: nil, pageSize: nil), result: .success(mockEmotionalStates))
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Get emotional history success")
        
        // Call sut.getEmotionalHistory with date range parameters
        sut.getEmotionalHistory(startDate: Date(), endDate: Date()) { result in
            // Verify the result is successful and contains the expected states
            switch result {
            case .success(let states):
                XCTAssertEqual(states, mockEmotionalStates, "The returned states should match the mock states")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got failure: \(error)")
            }
        }
        
        // Verify the API request was made with the correct endpoint
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getEmotionalHistory(startDate: Date(), endDate: Date(), page: nil, pageSize: nil)), 1, "API request should have been made")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test retrieving emotional history falls back to local storage on network error
    func testGetEmotionalHistory_NetworkError_FallbackToLocalStorage() {
        // Create mock emotional states array
        let mockEmotionalStates = [
            EmotionalState(emotionType: .joy, intensity: 7, context: .standalone),
            EmotionalState(emotionType: .sadness, intensity: 3, context: .preJournaling)
        ]
        
        // Set up mockAPIClient to return a network error
        mockAPIClient.setMockResponse(endpoint: .getEmotionalHistory(startDate: Date(), endDate: Date(), page: nil, pageSize: nil), result: .failure(.networkError(message: "Simulated network error")))
        
        // Set up mockStorageService to return the mock states
        mockStorageService.setMockData(mockEmotionalStates, forKey: "emotional_states", dataType: .emotions)
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Get emotional history success from local storage")
        
        // Call sut.getEmotionalHistory with date range parameters
        sut.getEmotionalHistory(startDate: Date(), endDate: Date()) { result in
            // Verify the result is successful and contains the expected states from local storage
            switch result {
            case .success(let states):
                XCTAssertEqual(states, mockEmotionalStates, "The returned states should match the mock states from local storage")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got failure: \(error)")
            }
        }
        
        // Verify the API request was attempted
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getEmotionalHistory(startDate: Date(), endDate: Date(), page: nil, pageSize: nil)), 1, "API request should have been made")
        
        // Verify the storage service was accessed
        XCTAssertEqual(mockStorageService.getOperationCount(forKey: "emotional_states", dataType: .emotions), 1, "Storage service should have been accessed")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test retrieving emotional history returns error when both network and storage fail
    func testGetEmotionalHistory_NetworkAndStorageError_ReturnsError() {
        // Set up mockAPIClient to return a network error
        mockAPIClient.setMockResponse(endpoint: .getEmotionalHistory(startDate: Date(), endDate: Date(), page: nil, pageSize: nil), result: .failure(.networkError(message: "Simulated network error")))
        
        // Set up mockStorageService to return a storage error
        mockStorageService.simulateError(.fileNotFound)
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Get emotional history failure due to network and storage error")
        
        // Call sut.getEmotionalHistory with date range parameters
        sut.getEmotionalHistory(startDate: Date(), endDate: Date()) { result in
            // Verify the result is a failure with appropriate error
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure(let error):
                XCTAssertEqual(error, EmotionServiceError.networkError, "Expected networkError")
                expectation.fulfill()
            }
        }
        
        // Verify both API and storage were attempted
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getEmotionalHistory(startDate: Date(), endDate: Date(), page: nil, pageSize: nil)), 1, "API request should have been made")
        XCTAssertEqual(mockStorageService.getOperationCount(forKey: "emotional_states", dataType: .emotions), 1, "Storage service should have been accessed")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test retrieving emotional trends successfully
    func testGetEmotionalTrends_Success() {
        // Create mock emotional trends and insights
        let mockEmotionalTrends = [
            EmotionalTrend(emotionType: .joy, dataPoints: [], overallTrend: .stable, averageIntensity: 7.0, peakIntensity: 9.0, peakDate: Date(), occurrenceCount: 5),
            EmotionalTrend(emotionType: .sadness, dataPoints: [], overallTrend: .decreasing, averageIntensity: 3.0, peakIntensity: 5.0, peakDate: Date(), occurrenceCount: 3)
        ]
        let mockEmotionalInsights = [
            EmotionalInsight(type: .pattern, description: "You tend to feel more joyful in the mornings", relatedEmotions: [.joy], confidence: 0.8, recommendedActions: ["Start your day with a positive activity"]),
            EmotionalInsight(type: .improvement, description: "Your sadness levels have decreased over the past week", relatedEmotions: [.sadness], confidence: 0.7, recommendedActions: ["Continue practicing self-care activities"])
        ]
        
        // Create mock trend response with the trends and insights
        let mockTrendResponse = EmotionalTrendResponse(trends: mockEmotionalTrends, insights: mockEmotionalInsights)
        
        // Set up mockAPIClient to return success with the mock response
        mockAPIClient.setMockResponse(endpoint: .getEmotionalTrends(startDate: Date(), endDate: Date()), result: .success(mockTrendResponse))
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Get emotional trends success")
        
        // Call sut.getEmotionalTrends with period type and date range
        sut.getEmotionalTrends(periodType: .daily, startDate: Date(), endDate: Date()) { result in
            // Verify the result is successful and contains the expected trends and insights
            switch result {
            case .success(let trendResponse):
                XCTAssertEqual(trendResponse.trends, mockEmotionalTrends, "The returned trends should match the mock trends")
                XCTAssertEqual(trendResponse.insights, mockEmotionalInsights, "The returned insights should match the mock insights")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got failure: \(error)")
            }
        }
        
        // Verify the API request was made with the correct endpoint
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getEmotionalTrends(startDate: Date(), endDate: Date())), 1, "API request should have been made")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test retrieving emotional trends generates local trends on network error
    func testGetEmotionalTrends_NetworkError_GeneratesLocalTrends() {
        // Create mock emotional states for local processing
        let mockEmotionalStates = [
            EmotionalState(emotionType: .joy, intensity: 7, context: .standalone, createdAt: Date()),
            EmotionalState(emotionType: .sadness, intensity: 3, context: .preJournaling, createdAt: Date())
        ]
        
        // Set up mockAPIClient to return a network error
        mockAPIClient.setMockResponse(endpoint: .getEmotionalTrends(startDate: Date(), endDate: Date()), result: .failure(.networkError(message: "Simulated network error")))
        
        // Set up mockStorageService to return the mock states
        mockStorageService.setMockData(mockEmotionalStates, forKey: "emotional_states", dataType: .emotions)
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Get emotional trends success from local generation")
        
        // Call sut.getEmotionalTrends with period type and date range
        sut.getEmotionalTrends(periodType: .daily, startDate: Date(), endDate: Date()) { result in
            // Verify the result is successful and contains locally generated trends
            switch result {
            case .success(let trendResponse):
                XCTAssertFalse(trendResponse.trends.isEmpty, "Expected locally generated trends")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got failure: \(error)")
            }
        }
        
        // Verify the API request was attempted
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getEmotionalTrends(startDate: Date(), endDate: Date())), 1, "API request should have been made")
        
        // Verify the storage service was accessed
        XCTAssertEqual(mockStorageService.getOperationCount(forKey: "emotional_states", dataType: .emotions), 1, "Storage service should have been accessed")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test retrieving emotional trends with invalid request returns error
    func testGetEmotionalTrends_InvalidRequest_ReturnsError() {
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Get emotional trends failure due to invalid request")
        
        // Call sut.getEmotionalTrends with invalid date range (end before start)
        sut.getEmotionalTrends(periodType: .daily, startDate: Date().addingTimeInterval(100), endDate: Date()) { result in
            // Verify the result is a failure with invalidEmotionalState error
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure(let error):
                XCTAssertEqual(error, EmotionServiceError.invalidRequest, "Expected invalidEmotionalState error")
                expectation.fulfill()
            }
        }
        
        // Verify no API request was made
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getEmotionalTrends(startDate: Date().addingTimeInterval(100), endDate: Date())), 0, "API request should not have been made")
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test analyzing emotional shift between pre and post states successfully
    func testAnalyzeEmotionalShift_Success() {
        // Create pre-journaling emotional state
        let preState = EmotionalState(emotionType: .anxiety, intensity: 7, context: .preJournaling)
        
        // Create post-journaling emotional state
        let postState = EmotionalState(emotionType: .calm, intensity: 3, context: .postJournaling)
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Analyze emotional shift success")
        
        // Call sut.analyzeEmotionalShift with the pre and post states
        sut.analyzeEmotionalShift(preState: preState, postState: postState) { result in
            // Verify the result is successful and contains expected analysis data
            switch result {
            case .success(let analysis):
                XCTAssertTrue(analysis.emotionChanged, "Emotion should have changed")
                XCTAssertEqual(analysis.intensityChange, -4, "Intensity change should be -4")
                XCTAssertFalse(analysis.insights.isEmpty, "Insights should be generated")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got failure: \(error)")
            }
        }
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test analyzing emotional shift with invalid contexts returns error
    func testAnalyzeEmotionalShift_InvalidContext_ReturnsError() {
        // Create emotional state with standalone context (not pre-journaling)
        let preState = EmotionalState(emotionType: .anxiety, intensity: 7, context: .standalone)
        
        // Create post-journaling emotional state
        let postState = EmotionalState(emotionType: .calm, intensity: 3, context: .postJournaling)
        
        // Create an expectation for async testing
        let expectation = XCTestExpectation(description: "Analyze emotional shift failure due to invalid context")
        
        // Call sut.analyzeEmotionalShift with the invalid context states
        sut.analyzeEmotionalShift(preState: preState, postState: postState) { result in
            // Verify the result is a failure with invalidEmotionalState error
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure(let error):
                XCTAssertEqual(error, EmotionServiceError.invalidEmotionalState, "Expected invalidEmotionalState error")
                expectation.fulfill()
            }
        }
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that the emotional state publisher emits states correctly
    func testGetEmotionalStatePublisher_PublishesStates() {
        // Create mock emotional states
        let mockEmotionalState1 = EmotionalState(emotionType: .joy, intensity: 7, context: .standalone)
        let mockEmotionalState2 = EmotionalState(emotionType: .sadness, intensity: 3, context: .preJournaling)
        
        // Set up mockAPIClient to return success with the mock states
        mockAPIClient.setMockResponse(endpoint: .recordEmotionalState(emotionType: "joy", intensity: 7, notes: nil, context: "standalone"), result: .success(mockEmotionalState1))
        mockAPIClient.setMockResponse(endpoint: .recordEmotionalState(emotionType: "sadness", intensity: 3, notes: nil, context: "preJournaling"), result: .success(mockEmotionalState2))
        
        // Create expectations for the publisher
        let expectation1 = XCTestExpectation(description: "Emotional state 1 published")
        let expectation2 = XCTestExpectation(description: "Emotional state 2 published")
        
        var receivedStates: [EmotionalState] = []
        
        // Subscribe to the emotional state publisher
        sut.getEmotionalStatePublisher()
            .sink { receivedState in
                receivedStates.append(receivedState)
                
                if receivedStates.count == 1 {
                    // Verify the first published state matches the expected state
                    XCTAssertEqual(receivedStates[0], mockEmotionalState1, "Published state 1 should match the mock state")
                    expectation1.fulfill()
                } else if receivedStates.count == 2 {
                    // Verify the second published state matches the expected state
                    XCTAssertEqual(receivedStates[1], mockEmotionalState2, "Published state 2 should match the mock state")
                    expectation2.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Record multiple emotional states
        sut.recordEmotionalState(emotionType: .joy, intensity: 7, context: .standalone) { _ in }
        sut.recordEmotionalState(emotionType: .sadness, intensity: 3, context: .preJournaling) { _ in }
        
        // Wait for expectations with timeout
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
    
    /// Test that the insight publisher emits insights correctly
    func testGetInsightPublisher_PublishesInsights() {
        // Create mock emotional insights
        let mockEmotionalInsight1 = EmotionalInsight(type: .pattern, description: "You tend to feel more joyful in the mornings", relatedEmotions: [.joy], confidence: 0.8, recommendedActions: ["Start your day with a positive activity"])
        let mockEmotionalInsight2 = EmotionalInsight(type: .improvement, description: "Your sadness levels have decreased over the past week", relatedEmotions: [.sadness], confidence: 0.7, recommendedActions: ["Continue practicing self-care activities"])
        
        // Create expectations for the publisher
        let expectation1 = XCTestExpectation(description: "Emotional insight 1 published")
        let expectation2 = XCTestExpectation(description: "Emotional insight 2 published")
        
        var receivedInsights: [EmotionalInsight] = []
        
        // Subscribe to the insight publisher
        sut.getInsightPublisher()
            .sink { receivedInsight in
                receivedInsights.append(receivedInsight)
                
                if receivedInsights.count == 1 {
                    // Verify the first published insight matches the expected insight
                    XCTAssertEqual(receivedInsights[0], mockEmotionalInsight1, "Published insight 1 should match the mock insight")
                    expectation1.fulfill()
                } else if receivedInsights.count == 2 {
                    // Verify the second published insight matches the expected insight
                    XCTAssertEqual(receivedInsights[1], mockEmotionalInsight2, "Published insight 2 should match the mock insight")
                    expectation2.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger insight generation through emotional analysis
        let preState = EmotionalState(emotionType: .anxiety, intensity: 7, context: .preJournaling)
        let postState = EmotionalState(emotionType: .calm, intensity: 3, context: .postJournaling)
        sut.analyzeEmotionalShift(preState: preState, postState: postState) { _ in }
        
        // Wait for expectations with timeout
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
}