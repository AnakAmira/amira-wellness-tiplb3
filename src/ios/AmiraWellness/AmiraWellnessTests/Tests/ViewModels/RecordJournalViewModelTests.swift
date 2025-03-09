import XCTest // Apple's testing framework
import Combine // Reactive programming for handling asynchronous events

@testable import AmiraWellness // Import the main application module
import Journal // Core data model for voice journal entries
import EmotionalState // Model for tracking emotional states before and after journaling
import EmotionType // Enumeration of emotion types for selection in UI
import CheckInContext // Defines contexts for emotional check-ins
import RecordJournalViewModel // The view model class being tested
import RecordJournalViewState // Enum representing the possible states of the recording screen
import MockJournalService // Mock implementation of JournalService for testing
import MockAudioRecordingService // Mock implementation of AudioRecordingService for testing
import MockEmotionService // Mock implementation of EmotionService for testing
import TestData // Provides mock data for testing

/// Test suite for the RecordJournalViewModel class
class RecordJournalViewModelTests: XCTestCase {
    
    /// The view model instance being tested
    var viewModel: RecordJournalViewModel!
    
    /// Mock implementation of JournalService
    var mockJournalService: MockJournalService!
    
    /// Mock implementation of AudioRecordingService
    var mockAudioService: MockAudioRecordingService!
    
    /// Mock implementation of EmotionService
    var mockEmotionService: MockEmotionService!
    
    /// A set to hold Combine cancellables for managing subscriptions
    var cancellables = Set<AnyCancellable>()
    
    /// Set up test environment before each test
    override func setUp() {
        super.setUp()
        
        // Initialize mock services
        mockJournalService = MockJournalService()
        mockAudioService = MockAudioRecordingService.shared
        mockEmotionService = MockEmotionService()
        
        // Reset cancellables
        cancellables = Set<AnyCancellable>()
        
        // Create viewModel with mock services
        viewModel = RecordJournalViewModel(journalService: mockJournalService, recordingService: mockAudioService, emotionService: mockEmotionService)
        
        // Configure default success responses for mock services
        mockEmotionService.recordEmotionalStateResult = .success(TestData.mockEmotionalState())
        mockJournalService.startRecordingResult = { completion in
            completion(.success(UUID()))
        }
    }
    
    /// Clean up test environment after each test
    override func tearDown() {
        // Reset all mock services
        mockJournalService.reset()
        mockAudioService.reset()
        mockEmotionService.reset()
        
        // Set viewModel to nil
        viewModel = nil
        
        super.tearDown()
    }
    
    /// Test that the view model initializes with the correct state
    func testInitialState() {
        XCTAssertEqual(viewModel.viewState, .preCheckIn, "Initial viewState should be .preCheckIn")
        XCTAssertNil(viewModel.selectedEmotionType, "Initial selectedEmotionType should be nil")
        XCTAssertEqual(viewModel.emotionIntensity, 5, "Initial emotionIntensity should be 5")
        XCTAssertEqual(viewModel.notes, "", "Initial notes should be empty string")
        XCTAssertEqual(viewModel.journalTitle, "", "Initial journalTitle should be empty string")
        XCTAssertFalse(viewModel.isRecording, "Initial isRecording should be false")
        XCTAssertFalse(viewModel.isPaused, "Initial isPaused should be false")
    }
    
    /// Test successful submission of pre-recording emotional state
    func testSubmitPreRecordingEmotionalState_Success() {
        // Given
        viewModel.selectedEmotionType = .joy
        viewModel.emotionIntensity = 8
        viewModel.notes = "Test notes"
        
        // When
        viewModel.submitPreRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1, "recordEmotionalState should be called once")
        XCTAssertEqual(mockJournalService.startRecordingCallCount, 1, "startRecording should be called once")
        XCTAssertEqual(mockEmotionService.lastRecordedEmotionType, .joy, "Last recorded emotion type should be .joy")
        XCTAssertEqual(mockEmotionService.lastRecordedIntensity, 8, "Last recorded intensity should be 8")
        XCTAssertEqual(mockEmotionService.lastRecordedContext, .preJournaling, "Last recorded context should be .preJournaling")
        XCTAssertEqual(viewModel.viewState, .recording, "viewState should be .recording")
    }
    
    /// Test pre-recording submission with no emotion selected
    func testSubmitPreRecordingEmotionalState_NoEmotionSelected() {
        // Given
        viewModel.selectedEmotionType = nil
        
        // When
        viewModel.submitPreRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 0, "recordEmotionalState should not be called")
        XCTAssertEqual(mockJournalService.startRecordingCallCount, 0, "startRecording should not be called")
        XCTAssertEqual(viewModel.viewState, .preCheckIn, "viewState should still be .preCheckIn")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertTrue(viewModel.errorMessage?.contains("Please select an emotion.") ?? false, "errorMessage should contain text about selecting an emotion")
    }
    
    /// Test pre-recording submission when emotion service fails
    func testSubmitPreRecordingEmotionalState_EmotionServiceFailure() {
        // Given
        viewModel.selectedEmotionType = .joy
        mockEmotionService.recordEmotionalStateResult = .failure(.invalidEmotionalState)
        
        // When
        viewModel.submitPreRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1, "recordEmotionalState should be called once")
        XCTAssertEqual(mockJournalService.startRecordingCallCount, 0, "startRecording should not be called")
        XCTAssertEqual(viewModel.viewState, .error, "viewState should be .error")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should not be empty")
    }
    
    /// Test pre-recording submission when journal service fails
    func testSubmitPreRecordingEmotionalState_JournalServiceFailure() {
        // Given
        viewModel.selectedEmotionType = .joy
        mockJournalService.startRecordingResult = { completion in
            completion(.failure(.recordingFailed))
        }
        
        // When
        viewModel.submitPreRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1, "recordEmotionalState should be called once")
        XCTAssertEqual(mockJournalService.startRecordingCallCount, 1, "startRecording should be called once")
        XCTAssertEqual(viewModel.viewState, .error, "viewState should be .error")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should not be empty")
    }
    
    /// Test pausing an active recording
    func testToggleRecording_Pause() {
        // Given
        viewModel.viewState = .recording
        mockJournalService.pauseRecordingResult = { completion in
            completion(.success(()))
        }
        
        // When
        viewModel.toggleRecording()
        
        // Then
        XCTAssertEqual(mockJournalService.pauseRecordingCallCount, 1, "pauseRecording should be called once")
        XCTAssertTrue(viewModel.isPaused, "isPaused should be true")
    }
    
    /// Test resuming a paused recording
    func testToggleRecording_Resume() {
        // Given
        viewModel.viewState = .recording
        viewModel.isPaused = true
        mockJournalService.resumeRecordingResult = { completion in
            completion(.success(()))
        }
        
        // When
        viewModel.toggleRecording()
        
        // Then
        XCTAssertEqual(mockJournalService.resumeRecordingCallCount, 1, "resumeRecording should be called once")
        XCTAssertFalse(viewModel.isPaused, "isPaused should be false")
        XCTAssertTrue(viewModel.isRecording, "isRecording should be true")
    }
    
    /// Test failure when pausing a recording
    func testToggleRecording_PauseFailure() {
        // Given
        viewModel.viewState = .recording
        mockJournalService.pauseRecordingResult = { completion in
            completion(.failure(.recordingFailed))
        }
        
        // When
        viewModel.toggleRecording()
        
        // Then
        XCTAssertEqual(mockJournalService.pauseRecordingCallCount, 1, "pauseRecording should be called once")
        XCTAssertEqual(viewModel.viewState, .error, "viewState should be .error")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should not be empty")
    }
    
    /// Test successfully stopping a recording
    func testStopRecording_Success() {
        // Given
        viewModel.viewState = .recording
        mockJournalService.stopRecordingResult = { completion in
            completion(.success(()))
        }
        
        // When
        viewModel.stopRecording()
        
        // Then
        XCTAssertEqual(mockJournalService.stopRecordingCallCount, 1, "stopRecording should be called once")
        XCTAssertEqual(viewModel.viewState, .postCheckIn, "viewState should be .postCheckIn")
        XCTAssertNil(viewModel.selectedEmotionType, "selectedEmotionType should be nil")
        XCTAssertEqual(viewModel.notes, "", "notes should be empty string")
    }
    
    /// Test failure when stopping a recording
    func testStopRecording_Failure() {
        // Given
        viewModel.viewState = .recording
        mockJournalService.stopRecordingResult = { completion in
            completion(.failure(.recordingFailed))
        }
        
        // When
        viewModel.stopRecording()
        
        // Then
        XCTAssertEqual(mockJournalService.stopRecordingCallCount, 1, "stopRecording should be called once")
        XCTAssertEqual(viewModel.viewState, .error, "viewState should be .error")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should not be empty")
    }
    
    /// Test successfully canceling a recording
    func testCancelRecording_Success() {
        // Given
        viewModel.viewState = .recording
        mockJournalService.cancelRecordingResult = { completion in
            completion(.success(()))
        }
        
        // When
        viewModel.cancelRecording()
        
        // Then
        XCTAssertEqual(mockJournalService.cancelRecordingCallCount, 1, "cancelRecording should be called once")
        XCTAssertEqual(viewModel.viewState, .preCheckIn, "viewState should be .preCheckIn")
        XCTAssertFalse(viewModel.isRecording, "isRecording should be false")
        XCTAssertFalse(viewModel.isPaused, "isPaused should be false")
    }
    
    /// Test failure when canceling a recording
    func testCancelRecording_Failure() {
        // Given
        viewModel.viewState = .recording
        mockJournalService.cancelRecordingResult = { completion in
            completion(.failure(.recordingFailed))
        }
        
        // When
        viewModel.cancelRecording()
        
        // Then
        XCTAssertEqual(mockJournalService.cancelRecordingCallCount, 1, "cancelRecording should be called once")
        XCTAssertEqual(viewModel.viewState, .error, "viewState should be .error")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should not be empty")
    }
    
    /// Test successful submission of post-recording emotional state
    func testSubmitPostRecordingEmotionalState_Success() {
        // Given
        viewModel.viewState = .postCheckIn
        viewModel.selectedEmotionType = .calm
        viewModel.emotionIntensity = 9
        viewModel.notes = "Post recording notes"
        viewModel.journalTitle = "Test Journal"
        
        // When
        viewModel.submitPostRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1, "recordEmotionalState should be called once")
        XCTAssertEqual(mockJournalService.saveJournalCallCount, 1, "saveJournal should be called once")
        XCTAssertEqual(mockEmotionService.lastRecordedEmotionType, .calm, "Last recorded emotion type should be .calm")
        XCTAssertEqual(mockEmotionService.lastRecordedIntensity, 9, "Last recorded intensity should be 9")
        XCTAssertEqual(mockEmotionService.lastRecordedContext, .postJournaling, "Last recorded context should be .postJournaling")
        XCTAssertEqual(viewModel.viewState, .completed, "viewState should be .completed")
        XCTAssertNotNil(viewModel.completedJournal, "completedJournal should not be nil")
        XCTAssertEqual(viewModel.completedJournal?.title, "Test Journal", "Journal title should be 'Test Journal'")
    }
    
    /// Test post-recording submission with no emotion selected
    func testSubmitPostRecordingEmotionalState_NoEmotionSelected() {
        // Given
        viewModel.viewState = .postCheckIn
        viewModel.selectedEmotionType = nil
        
        // When
        viewModel.submitPostRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 0, "recordEmotionalState should not be called")
        XCTAssertEqual(mockJournalService.saveJournalCallCount, 0, "saveJournal should not be called")
        XCTAssertEqual(viewModel.viewState, .postCheckIn, "viewState should still be .postCheckIn")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertTrue(viewModel.errorMessage?.contains("Please select an emotion.") ?? false, "errorMessage should contain text about selecting an emotion")
    }
    
    /// Test post-recording submission when emotion service fails
    func testSubmitPostRecordingEmotionalState_EmotionServiceFailure() {
        // Given
        viewModel.viewState = .postCheckIn
        viewModel.selectedEmotionType = .calm
        mockEmotionService.recordEmotionalStateResult = .failure(.invalidEmotionalState)
        
        // When
        viewModel.submitPostRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1, "recordEmotionalState should be called once")
        XCTAssertEqual(mockJournalService.saveJournalCallCount, 0, "saveJournal should not be called")
        XCTAssertEqual(viewModel.viewState, .error, "viewState should be .error")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should not be empty")
    }
    
    /// Test post-recording submission when journal service fails
    func testSubmitPostRecordingEmotionalState_JournalServiceFailure() {
        // Given
        viewModel.viewState = .postCheckIn
        viewModel.selectedEmotionType = .calm
        mockJournalService.saveJournalResult = { completion in
            completion(.failure(.savingFailed))
        }
        
        // When
        viewModel.submitPostRecordingEmotionalState()
        
        // Then
        XCTAssertEqual(mockEmotionService.recordEmotionalStateCallCount, 1, "recordEmotionalState should be called once")
        XCTAssertEqual(mockJournalService.saveJournalCallCount, 1, "saveJournal should be called once")
        XCTAssertEqual(viewModel.viewState, .error, "viewState should be .error")
        XCTAssertTrue(viewModel.showError, "showError should be true")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should not be empty")
    }
    
    /// Test resetting the view model to initial state
    func testResetViewModel() {
        // Given
        viewModel.viewState = .completed
        viewModel.selectedEmotionType = .calm
        viewModel.emotionIntensity = 9
        viewModel.notes = "Post recording notes"
        viewModel.journalTitle = "Test Journal"
        viewModel.isRecording = true
        viewModel.isPaused = true
        viewModel.completedJournal = TestData.mockJournal()
        
        // When
        viewModel.resetViewModel()
        
        // Then
        XCTAssertEqual(viewModel.viewState, .preCheckIn, "viewState should be .preCheckIn")
        XCTAssertNil(viewModel.selectedEmotionType, "selectedEmotionType should be nil")
        XCTAssertEqual(viewModel.emotionIntensity, 5, "emotionIntensity should be 5")
        XCTAssertEqual(viewModel.notes, "", "notes should be empty string")
        XCTAssertEqual(viewModel.journalTitle, "", "journalTitle should be empty string")
        XCTAssertFalse(viewModel.isRecording, "isRecording should be false")
        XCTAssertFalse(viewModel.isPaused, "isPaused should be false")
        XCTAssertNil(viewModel.completedJournal, "completedJournal should be nil")
    }
    
    /// Test formatting of recording duration
    func testFormatDuration() {
        // Given
        viewModel.recordingDuration = 65 // 1 minute, 5 seconds
        
        // When
        let formattedDuration = viewModel.formatDuration()
        
        // Then
        XCTAssertEqual(formattedDuration, "01:05", "Formatted duration should be '01:05'")
        
        // Given
        viewModel.recordingDuration = 3725 // 1 hour, 2 minutes, 5 seconds
        
        // When
        let formattedDuration2 = viewModel.formatDuration()
        
        // Then
        XCTAssertEqual(formattedDuration2, "01:02:05", "Formatted duration should be '01:02:05'")
    }
    
    /// Test generation of emotional shift summary
    func testGetEmotionalShiftSummary() {
        // Given
        let preEmotionalState = TestData.mockEmotionalState(emotionType: .joy, intensity: 4, context: .preJournaling)
        let postEmotionalState = TestData.mockEmotionalState(emotionType: .calm, intensity: 7, context: .postJournaling)
        let mockJournal = TestData.mockJournal().withUpdatedEmotionalState(postState: postEmotionalState)
        viewModel.completedJournal = mockJournal
        
        // When
        let summary = viewModel.getEmotionalShiftSummary()
        
        // Then
        XCTAssertNotNil(summary, "Emotional shift summary should not be nil")
    }
    
    /// Test emotional shift summary when no journal is completed
    func testGetEmotionalShiftSummary_NoCompletedJournal() {
        // Given
        viewModel.completedJournal = nil
        
        // When
        let summary = viewModel.getEmotionalShiftSummary()
        
        // Then
        XCTAssertNil(summary, "Emotional shift summary should be nil when no journal is completed")
    }
    
    /// Test that view model properties update correctly via publishers
    @MainActor
    func testPublisherUpdates() {
        // Create expectations for property changes
        let viewStateExpectation = XCTestExpectation(description: "viewState should update")
        let isRecordingExpectation = XCTestExpectation(description: "isRecording should update")
        let isPausedExpectation = XCTestExpectation(description: "isPaused should update")
        
        // Subscribe to viewModel.$viewState publisher
        viewModel.$viewState
            .dropFirst() // Drop the initial value
            .sink { value in
                XCTAssertEqual(value, .paused, "viewState should be .paused")
                viewStateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Subscribe to viewModel.$isRecording publisher
        viewModel.$isRecording
            .dropFirst() // Drop the initial value
            .sink { value in
                XCTAssertFalse(value, "isRecording should be false")
                isRecordingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Subscribe to viewModel.$isPaused publisher
        viewModel.$isPaused
            .dropFirst() // Drop the initial value
            .sink { value in
                XCTAssertTrue(value, "isPaused should be true")
                isPausedExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Set up viewModel in recording state
        viewModel.viewState = .recording
        
        // Configure mockJournalService.pauseRecordingResult to return success
        mockJournalService.pauseRecordingResult = { completion in
            completion(.success(()))
        }
        
        // Call viewModel.toggleRecording() to pause
        viewModel.toggleRecording()
        
        // Wait for expectations to be fulfilled
        wait(for: [viewStateExpectation, isRecordingExpectation, isPausedExpectation], timeout: 1.0)
    }
}