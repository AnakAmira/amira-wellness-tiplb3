import XCTest // Apple's testing framework
import Combine // Reactive programming for asynchronous operations

// Internal imports
import EmotionalCheckinViewModel // The view model class being tested
import EmotionalState // Core data model for emotional states
import EmotionType // Enumeration of emotion types
import CheckInContext // Contexts in which emotional check-ins occur
import EmotionServiceError // Error types for emotion service operations
import MockEmotionService // Mock implementation of EmotionService for testing
import TestData // Provides mock data for testing

/// Test suite for the EmotionalCheckinViewModel class
class EmotionalCheckinViewModelTests: XCTestCase {
    
    /// Instance of the EmotionalCheckinViewModel to be tested
    var viewModel: EmotionalCheckinViewModel!
    
    /// Mock implementation of the EmotionService for testing
    var mockEmotionService: MockEmotionService!
    
    /// Set to store Combine cancellables
    var cancellables = Set<AnyCancellable>()
    
    /// Default constructor for the test class
    override init() {
        super.init()
    }
    
    /// Set up method called before each test
    override func setUp() {
        super.setUp()
        
        // Initialize mockEmotionService
        mockEmotionService = MockEmotionService()
        
        // Initialize viewModel with mockEmotionService and standalone context
        viewModel = EmotionalCheckinViewModel(emotionService: mockEmotionService, context: .standalone)
        
        // Initialize cancellables set for storing subscriptions
        cancellables = Set<AnyCancellable>()
    }
    
    /// Tear down method called after each test
    override func tearDown() {
        // Set viewModel to nil
        viewModel = nil
        
        // Set mockEmotionService to nil
        mockEmotionService = nil
        
        // Clear cancellables set
        cancellables = Set<AnyCancellable>()
        
        super.tearDown()
    }
    
    /// Tests that the view model initializes with the correct default values
    func testInitialState() {
        // Assert that selectedEmotion is .joy
        XCTAssertEqual(viewModel.selectedEmotion, .joy)
        
        // Assert that intensity is 5
        XCTAssertEqual(viewModel.intensity, 5)
        
        // Assert that notes is empty
        XCTAssertTrue(viewModel.notes.isEmpty)
        
        // Assert that isLoading is false
        XCTAssertFalse(viewModel.isLoading)
        
        // Assert that showError is false
        XCTAssertFalse(viewModel.showError)
        
        // Assert that errorMessage is empty
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
        
        // Assert that navigateToResult is false
        XCTAssertFalse(viewModel.navigateToResult)
        
        // Assert that recordedState is nil
        XCTAssertNil(viewModel.recordedState)
    }
    
    /// Tests that the selectEmotion method updates the selectedEmotion property
    func testSelectEmotion() {
        // Call viewModel.selectEmotion with .sadness
        viewModel.selectEmotion(emotion: .sadness)
        
        // Assert that selectedEmotion is now .sadness
        XCTAssertEqual(viewModel.selectedEmotion, .sadness)
        
        // Call viewModel.selectEmotion with .anxiety
        viewModel.selectEmotion(emotion: .anxiety)
        
        // Assert that selectedEmotion is now .anxiety
        XCTAssertEqual(viewModel.selectedEmotion, .anxiety)
    }
    
    /// Tests that the updateIntensity method updates the intensity property
    func testUpdateIntensity() {
        // Call viewModel.updateIntensity with 8
        viewModel.updateIntensity(value: 8)
        
        // Assert that intensity is now 8
        XCTAssertEqual(viewModel.intensity, 8)
        
        // Call viewModel.updateIntensity with 3
        viewModel.updateIntensity(value: 3)
        
        // Assert that intensity is now 3
        XCTAssertEqual(viewModel.intensity, 3)
    }
    
    /// Tests that the updateIntensity method handles invalid values correctly
    func testUpdateIntensityWithInvalidValues() {
        // Call viewModel.updateIntensity with 0
        viewModel.updateIntensity(value: 0)
        
        // Assert that intensity remains at default value (5)
        XCTAssertEqual(viewModel.intensity, 5)
        
        // Call viewModel.updateIntensity with 11
        viewModel.updateIntensity(value: 11)
        
        // Assert that intensity remains at default value (5)
        XCTAssertEqual(viewModel.intensity, 5)
    }
    
    /// Tests that the updateNotes method updates the notes property
    func testUpdateNotes() {
        // Call viewModel.updateNotes with 'Test notes'
        viewModel.updateNotes(text: "Test notes")
        
        // Assert that notes is now 'Test notes'
        XCTAssertEqual(viewModel.notes, "Test notes")
        
        // Call viewModel.updateNotes with empty string
        viewModel.updateNotes(text: "")
        
        // Assert that notes is now empty
        XCTAssertTrue(viewModel.notes.isEmpty)
    }
    
    /// Tests that submitEmotionalState successfully records an emotional state
    func testSubmitEmotionalStateSuccess() {
        // Set up mockEmotionService to return success
        mockEmotionService.recordEmotionalStateResult = .success(TestData.mockEmotionalState())
        
        // Create expectation for navigateToResult to become true
        let expectation = XCTestExpectation(description: "navigateToResult becomes true")
        
        // Subscribe to navigateToResult publisher
        viewModel.$navigateToResult
            .dropFirst() // Drop the initial value
            .sink { value in
                if value {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Call viewModel.submitEmotionalState()
        viewModel.submitEmotionalState()
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
        
        // Assert that navigateToResult is true
        XCTAssertTrue(viewModel.navigateToResult)
        
        // Assert that recordedState is not nil
        XCTAssertNotNil(viewModel.recordedState)
        
        // Assert that isLoading is false
        XCTAssertFalse(viewModel.isLoading)
        
        // Assert that mockEmotionService.recordEmotionalStateCallCount is 1
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1)
        
        // Assert that mockEmotionService.lastRecordedEmotionType matches viewModel.selectedEmotion
        XCTAssertEqual(mockEmotionService.lastRecordedEmotionType, viewModel.selectedEmotion)
        
        // Assert that mockEmotionService.lastRecordedIntensity matches viewModel.intensity
        XCTAssertEqual(mockEmotionService.lastRecordedIntensity, viewModel.intensity)
    }
    
    /// Tests that submitEmotionalState handles errors correctly
    func testSubmitEmotionalStateFailure() {
        // Set up mockEmotionService to return an error
        mockEmotionService.recordEmotionalStateResult = .failure(.networkError)
        
        // Create expectation for showError to become true
        let expectation = XCTestExpectation(description: "showError becomes true")
        
        // Subscribe to showError publisher
        viewModel.$showError
            .dropFirst() // Drop the initial value
            .sink { value in
                if value {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Call viewModel.submitEmotionalState()
        viewModel.submitEmotionalState()
        
        // Wait for expectations with timeout
        wait(for: [expectation], timeout: 1.0)
        
        // Assert that showError is true
        XCTAssertTrue(viewModel.showError)
        
        // Assert that errorMessage is not empty
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        
        // Assert that navigateToResult is false
        XCTAssertFalse(viewModel.navigateToResult)
        
        // Assert that isLoading is false
        XCTAssertFalse(viewModel.isLoading)
        
        // Assert that mockEmotionService.recordEmotionalStateCallCount is 1
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1)
    }
    
    /// Tests the async version of submitEmotionalState
    @available(iOS 15.0, *)
    func testSubmitEmotionalStateAsync() async {
        // Set up mockEmotionService to return success
        mockEmotionService.recordEmotionalStateResult = .success(TestData.mockEmotionalState())
        
        // Create expectation for async operation
        let expectation = XCTestExpectation(description: "Async operation completes")
        
        // Call await viewModel.submitEmotionalStateAsync()
        do {
            _ = try await viewModel.submitEmotionalStateAsync()
            expectation.fulfill()
        } catch {
            XCTFail("Async operation failed with error: \(error)")
        }
        
        // Wait for expectations with timeout
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Assert that navigateToResult is true
        XCTAssertTrue(viewModel.navigateToResult)
        
        // Assert that recordedState is not nil
        XCTAssertNotNil(viewModel.recordedState)
        
        // Assert that isLoading is false
        XCTAssertFalse(viewModel.isLoading)
        
        // Assert that mockEmotionService.recordEmotionalStateCallCount is 1
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1)
    }
    
    /// Tests error handling in the async version of submitEmotionalState
    @available(iOS 15.0, *)
    func testSubmitEmotionalStateAsyncFailure() async {
        // Set up mockEmotionService to return an error
        mockEmotionService.recordEmotionalStateResult = .failure(.networkError)
        
        // Create expectation for async operation
        let expectation = XCTestExpectation(description: "Async operation completes")
        
        // Call await viewModel.submitEmotionalStateAsync() in a do-catch block
        do {
            _ = try await viewModel.submitEmotionalStateAsync()
            XCTFail("Async operation should have thrown an error")
        } catch {
            // Expect an error to be thrown
            expectation.fulfill()
        }
        
        // Wait for expectations with timeout
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Assert that showError is true
        XCTAssertTrue(viewModel.showError)
        
        // Assert that errorMessage is not empty
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        
        // Assert that isLoading is false
        XCTAssertFalse(viewModel.isLoading)
        
        // Assert that mockEmotionService.recordEmotionalStateCallCount is 1
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1)
    }
    
    /// Tests that the dismissError method resets error state
    func testDismissError() {
        // Set viewModel.showError to true
        viewModel.showError = true
        
        // Set viewModel.errorMessage to 'Test error'
        viewModel.errorMessage = "Test error"
        
        // Call viewModel.dismissError()
        viewModel.dismissError()
        
        // Assert that showError is false
        XCTAssertFalse(viewModel.showError)
        
        // Assert that errorMessage is empty
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
    }
    
    /// Tests that the resetState method resets all state properties
    func testResetState() {
        // Modify all state properties
        viewModel.selectEmotion(emotion: .sadness)
        viewModel.updateIntensity(value: 8)
        viewModel.updateNotes(text: "Test notes")
        viewModel.showError = true
        viewModel.errorMessage = "Test error"
        viewModel.navigateToResult = true
        viewModel.recordedState = TestData.mockEmotionalState()
        
        // Call viewModel.resetState()
        viewModel.resetState()
        
        // Assert that all properties are reset to their default values
        XCTAssertEqual(viewModel.selectedEmotion, .joy)
        XCTAssertEqual(viewModel.intensity, 5)
        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showError)
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
        XCTAssertFalse(viewModel.navigateToResult)
        XCTAssertNil(viewModel.recordedState)
    }
    
    /// Tests that the context is correctly propagated to the emotional state
    func testContextPropagation() {
        // Create a new viewModel with preJournaling context
        let preJournalingViewModel = EmotionalCheckinViewModel(emotionService: mockEmotionService, context: .preJournaling)
        
        // Set up mockEmotionService to return success
        mockEmotionService.recordEmotionalStateResult = .success(TestData.mockEmotionalState())
        
        // Call viewModel.submitEmotionalState()
        preJournalingViewModel.submitEmotionalState()
        
        // Assert that mockEmotionService.lastRecordedContext is .preJournaling
        XCTAssertEqual(mockEmotionService.lastRecordedContext, .preJournaling)
        
        // Create another viewModel with postJournaling context
        let postJournalingViewModel = EmotionalCheckinViewModel(emotionService: mockEmotionService, context: .postJournaling)
        
        // Call viewModel.submitEmotionalState()
        postJournalingViewModel.submitEmotionalState()
        
        // Assert that mockEmotionService.lastRecordedContext is .postJournaling
        XCTAssertEqual(mockEmotionService.lastRecordedContext, .postJournaling)
    }

    /// Tests that related IDs are correctly propagated to the emotional state
    func testRelatedIdPropagation() {
        // Create a UUID for testing
        let testUUID = UUID()

        // Create a new viewModel with preJournaling context and the test UUID as relatedJournalId
        let preJournalingViewModel = EmotionalCheckinViewModel(emotionService: mockEmotionService, context: .preJournaling, relatedJournalId: testUUID)

        // Set up mockEmotionService to return success
        mockEmotionService.recordEmotionalStateResult = .success(TestData.mockEmotionalState())

        // Call viewModel.submitEmotionalState()
        preJournalingViewModel.submitEmotionalState()

        // Assert that the recorded state has the correct relatedJournalId
        XCTAssertEqual(preJournalingViewModel.recordedState?.relatedJournalId, testUUID)
    }
}