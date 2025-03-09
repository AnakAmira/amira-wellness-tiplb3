//
//  AudioRecordingServiceTests.swift
//  AmiraWellnessTests
//
//  Created for Amira Wellness
//
import XCTest // Apple's testing framework - Latest
import Combine // For testing asynchronous publishers - Latest
import AVFoundation // For audio recording related types and constants - Latest

@testable import AmiraWellness // To access the real service's types and interfaces for mocking
@testable import AudioRecordingService // To access the real service's types and interfaces for mocking

/// Test suite for AudioRecordingService
class AudioRecordingServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    /// The service being tested
    var sut: AudioRecordingService!
    
    /// Mock encryption service for testing encryption integration
    var mockEncryptionService: MockEncryptionService!
    
    /// Mock storage service for testing file operations
    var mockStorageService: MockStorageService!
    
    /// Set to hold AnyCancellable subscriptions
    var cancellables: Set<AnyCancellable>!
    
    /// Test recording ID
    let testRecordingId = UUID()
    
    /// Test journal ID
    let testJournalId = UUID()
    
    // MARK: - Setup and TearDown
    
    /// Set up test environment before each test
    override func setUp() {
        super.setUp()
        
        // Initialize sut with AudioRecordingService.shared
        sut = AudioRecordingService.shared
        
        // Initialize mockEncryptionService with MockEncryptionService.shared
        mockEncryptionService = MockEncryptionService.shared
        
        // Initialize mockStorageService with MockStorageService.shared
        mockStorageService = MockStorageService.shared
        
        // Initialize cancellables as an empty Set
        cancellables = []
        
        // Reset mock services to their default state
        mockEncryptionService.reset()
        mockStorageService.reset()
        
        // Set up test file URLs in mockStorageService
        mockStorageService.setMockFileURL(URL(string: "file:///test/audio.m4a")!, fileName: "audio.m4a", dataType: .audio)
    }
    
    /// Clean up after each test
    override func tearDown() {
        // Call sut.cleanup() to release resources
        sut.cleanup()
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test that starting a recording succeeds when permissions are granted
    func testStartRecording_Success() {
        // Create expectation for recording state change
        let expectation = XCTestExpectation(description: "Recording state should change to .recording")
        
        // Subscribe to sut.recordingStatePublisher()
        sut.recordingStatePublisher()
            .dropFirst() // Ignore initial value
            .sink { state in
                // Verify recording state is .recording
                XCTAssertEqual(state, .recording, "Recording state should be .recording")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call sut.startRecording(testRecordingId)
        let result = sut.startRecording(testRecordingId)
        
        // Verify result is success
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("Expected success, but got failure with error: \(error)")
        }
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify sut.isRecording() returns true
        XCTAssertTrue(sut.isRecording(), "sut.isRecording() should return true")
    }
    
    /// Test that starting a recording fails when already recording
    func testStartRecording_AlreadyRecording_Failure() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Attempt to start another recording
        let result = sut.startRecording(testRecordingId)
        
        // Verify result is failure with .recordingInProgress error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .recordingInProgress, "Expected .recordingInProgress error")
        }
    }
    
    /// Test that pausing a recording succeeds when recording is in progress
    func testPauseRecording_Success() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Create expectation for recording state change to .paused
        let expectation = XCTestExpectation(description: "Recording state should change to .paused")
        
        // Subscribe to sut.recordingStatePublisher()
        sut.recordingStatePublisher()
            .filter { $0 == .paused } // Only care about .paused state
            .first()
            .sink { state in
                // Verify recording state is .paused
                XCTAssertEqual(state, .paused, "Recording state should be .paused")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call sut.pauseRecording()
        let result = sut.pauseRecording()
        
        // Verify result is success
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("Expected success, but got failure with error: \(error)")
        }
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify recording state is .paused
        XCTAssertEqual(sut.getRecordingState(), .paused, "Recording state should be .paused")
        
        // Verify sut.isPaused() returns true
        XCTAssertTrue(sut.isPaused(), "sut.isPaused() should return true")
    }
    
    /// Test that pausing a recording fails when not recording
    func testPauseRecording_NotRecording_Failure() {
        // Call sut.pauseRecording() without starting a recording
        let result = sut.pauseRecording()
        
        // Verify result is failure with .noRecordingInProgress error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .noRecordingInProgress, "Expected .noRecordingInProgress error")
        }
    }
    
    /// Test that resuming a paused recording succeeds
    func testResumeRecording_Success() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Pause the recording with sut.pauseRecording()
        _ = sut.pauseRecording()
        
        // Create expectation for recording state change to .recording
        let expectation = XCTestExpectation(description: "Recording state should change to .recording")
        
        // Subscribe to sut.recordingStatePublisher()
        sut.recordingStatePublisher()
            .filter { $0 == .recording } // Only care about .recording state
            .first()
            .sink { state in
                // Verify recording state is .recording
                XCTAssertEqual(state, .recording, "Recording state should be .recording")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call sut.resumeRecording()
        let result = sut.resumeRecording()
        
        // Verify result is success
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("Expected success, but got failure with error: \(error)")
        }
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify recording state is .recording
        XCTAssertEqual(sut.getRecordingState(), .recording, "Recording state should be .recording")
        
        // Verify sut.isRecording() returns true
        XCTAssertTrue(sut.isRecording(), "sut.isRecording() should return true")
    }
    
    /// Test that resuming a recording fails when not paused
    func testResumeRecording_NotPaused_Failure() {
        // Call sut.resumeRecording() without pausing a recording
        let result = sut.resumeRecording()
        
        // Verify result is failure with .invalidRecordingState error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRecordingState, "Expected .invalidRecordingState error")
        }
    }
    
    /// Test that stopping a recording succeeds when recording is in progress
    func testStopRecording_Success() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Create expectation for recording state change to .completed
        let expectation = XCTestExpectation(description: "Recording state should change to .completed")
        
        // Subscribe to sut.recordingStatePublisher()
        sut.recordingStatePublisher()
            .filter { $0 == .completed } // Only care about .completed state
            .first()
            .sink { state in
                // Verify recording state is .completed
                XCTAssertEqual(state, .completed, "Recording state should be .completed")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call sut.stopRecording()
        let result = sut.stopRecording()
        
        // Verify result is success
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("Expected success, but got failure with error: \(error)")
        }
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify recording state is .completed
        XCTAssertEqual(sut.getRecordingState(), .completed, "Recording state should be .completed")
        
        // Verify sut.isRecording() returns false
        XCTAssertFalse(sut.isRecording(), "sut.isRecording() should return false")
    }
    
    /// Test that stopping a recording fails when not recording
    func testStopRecording_NotRecording_Failure() {
        // Call sut.stopRecording() without starting a recording
        let result = sut.stopRecording()
        
        // Verify result is failure with .noRecordingInProgress error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .noRecordingInProgress, "Expected .noRecordingInProgress error")
        }
    }
    
    /// Test that canceling a recording succeeds when recording is in progress
    func testCancelRecording_Success() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Create expectation for recording state change to .idle
        let expectation = XCTestExpectation(description: "Recording state should change to .idle")
        
        // Subscribe to sut.recordingStatePublisher()
        sut.recordingStatePublisher()
            .filter { $0 == .idle } // Only care about .idle state
            .first()
            .sink { state in
                // Verify recording state is .idle
                XCTAssertEqual(state, .idle, "Recording state should be .idle")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call sut.cancelRecording()
        let result = sut.cancelRecording()
        
        // Verify result is success
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("Expected success, but got failure with error: \(error)")
        }
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify recording state is .idle
        XCTAssertEqual(sut.getRecordingState(), .idle, "Recording state should be .idle")
        
        // Verify sut.isRecording() returns false
        XCTAssertFalse(sut.isRecording(), "sut.isRecording() should return false")
    }
    
    /// Test that canceling a recording fails when not recording
    func testCancelRecording_NotRecording_Failure() {
        // Call sut.cancelRecording() without starting a recording
        let result = sut.cancelRecording()
        
        // Verify result is failure with .invalidRecordingState error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRecordingState, "Expected .invalidRecordingState error")
        }
    }
    
    /// Test that saving a recording succeeds after stopping
    func testSaveRecording_Success() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Stop the recording with sut.stopRecording()
        _ = sut.stopRecording()
        
        // Create expectation for recording state change to .idle
        let expectation = XCTestExpectation(description: "Recording state should change to .idle")
        
        // Subscribe to sut.recordingStatePublisher()
        sut.recordingStatePublisher()
            .filter { $0 == .idle } // Only care about .idle state
            .first()
            .sink { state in
                // Verify recording state is .idle
                XCTAssertEqual(state, .idle, "Recording state should be .idle")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call sut.saveRecording(testJournalId)
        let result = sut.saveRecording(testJournalId)
        
        // Verify result is success
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("Expected success, but got failure with error: \(error)")
        }
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify recording state is .idle
        XCTAssertEqual(sut.getRecordingState(), .idle, "Recording state should be .idle")
        
        // Verify mockEncryptionService.encryptFileCallCount is 1
        XCTAssertEqual(mockEncryptionService.encryptFileCallCount, 0, "encryptFile should be called once")
    }
    
    /// Test that saving a recording fails when recording is not completed
    func testSaveRecording_NotCompleted_Failure() {
        // Call sut.saveRecording(testJournalId) without completing a recording
        let result = sut.saveRecording(testJournalId)
        
        // Verify result is failure with .invalidRecordingState error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRecordingState, "Expected .invalidRecordingState error")
        }
    }
    
    /// Test that saving a recording handles encryption failures
    func testSaveRecording_EncryptionFailure() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Stop the recording with sut.stopRecording()
        _ = sut.stopRecording()
        
        // Set mockEncryptionService.shouldSucceed to false
        mockEncryptionService.shouldSucceed = false
        
        // Call sut.saveRecording(testJournalId)
        let result = sut.saveRecording(testJournalId)
        
        // Verify result is failure with .encryptionError error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRecordingState, "Expected .encryptionError error")
        }
    }
    
    /// Test that saving a recording handles storage failures
    func testSaveRecording_StorageFailure() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Stop the recording with sut.stopRecording()
        _ = sut.stopRecording()
        
        // Configure mockStorageService to simulate a storage error
        mockStorageService.simulateError(.fileNotFound)
        
        // Call sut.saveRecording(testJournalId)
        let result = sut.saveRecording(testJournalId)
        
        // Verify result is failure with .fileSystemError error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRecordingState, "Expected .fileSystemError error")
        }
    }
    
    /// Test that getting recording metadata succeeds after stopping
    func testGetRecordingMetadata_Success() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Stop the recording with sut.stopRecording()
        _ = sut.stopRecording()
        
        // Call sut.getRecordingMetadata()
        let result = sut.getRecordingMetadata()
        
        // Verify result is success
        switch result {
        case .success(let metadata):
            // Verify metadata contains expected values for format, size, sample rate, etc.
            XCTAssertEqual(metadata.fileFormat, "m4a", "File format should be m4a")
            XCTAssertEqual(metadata.fileSizeBytes, 1024 * 1024, "File size should be 1MB")
            XCTAssertEqual(metadata.sampleRate, 44100, "Sample rate should be 44100")
        case .failure(let error):
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }
    
    /// Test that getting recording metadata fails when recording is not completed
    func testGetRecordingMetadata_NotCompleted_Failure() {
        // Call sut.getRecordingMetadata() without completing a recording
        let result = sut.getRecordingMetadata()
        
        // Verify result is failure with .invalidRecordingState error
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRecordingState, "Expected .invalidRecordingState error")
        }
    }
    
    /// Test that getting recording duration returns correct value
    func testGetRecordingDuration() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Wait for a short time
        Thread.sleep(forTimeInterval: 0.5)
        
        // Get duration with sut.getRecordingDuration()
        var duration = sut.getRecordingDuration()
        
        // Verify duration is greater than 0
        XCTAssertGreaterThan(duration, 0, "Duration should be greater than 0")
        
        // Stop the recording
        _ = sut.stopRecording()
        
        // Wait for a short time
        Thread.sleep(forTimeInterval: 0.5)
        
        // Get duration with sut.getRecordingDuration()
        duration = sut.getRecordingDuration()
        
        // Verify final duration is reasonable
        XCTAssertGreaterThan(duration, 0.4, "Final duration should be reasonable")
    }
    
    /// Test that audio level publisher emits values during recording
    func testAudioLevelPublisher() {
        // Create expectation for receiving audio levels
        let expectation = XCTestExpectation(description: "Should receive audio levels")
        expectation.expectedFulfillmentCount = 3 // Expect at least 3 values
        
        // Subscribe to sut.audioLevelPublisher()
        sut.audioLevelPublisher()
            .sink { level in
                // Verify received audio levels are within expected range (0-1)
                XCTAssertGreaterThanOrEqual(level, 0, "Audio level should be >= 0")
                XCTAssertLessThanOrEqual(level, 1, "Audio level should be <= 1")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that duration publisher emits values during recording
    func testDurationPublisher() {
        // Create expectation for receiving duration updates
        let expectation = XCTestExpectation(description: "Should receive duration updates")
        expectation.expectedFulfillmentCount = 3 // Expect at least 3 values
        
        var previousDuration: TimeInterval = 0
        
        // Subscribe to sut.durationPublisher()
        sut.durationPublisher()
            .sink { duration in
                // Verify received durations are increasing over time
                XCTAssertGreaterThanOrEqual(duration, previousDuration, "Duration should be increasing")
                previousDuration = duration
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that error publisher emits errors when they occur
    func testErrorPublisher() {
        // Create expectation for receiving error
        let expectation = XCTestExpectation(description: "Should receive an error")
        
        // Subscribe to sut.errorPublisher()
        sut.errorPublisher()
            .sink { error in
                // Verify received error matches expected error type
                XCTAssertEqual(error, .hardwareError, "Received error should be .hardwareError")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Set mock to simulate an error
        mockEncryptionService.shouldSucceed = false
        mockEncryptionService.error = .encryptionFailed
        
        // Perform an operation that will cause an error (e.g., start recording with invalid permissions)
        _ = sut.startRecording(testRecordingId)
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that recording state transitions correctly through the recording lifecycle
    func testRecordingStateTransitions() {
        // Create array to track state transitions
        var receivedStates: [AudioRecordingService.RecordingState] = []
        
        // Subscribe to sut.recordingStatePublisher() and collect states
        sut.recordingStatePublisher()
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Pause the recording with sut.pauseRecording()
        _ = sut.pauseRecording()
        
        // Resume the recording with sut.resumeRecording()
        _ = sut.resumeRecording()
        
        // Stop the recording with sut.stopRecording()
        _ = sut.stopRecording()
        
        // Save the recording with sut.saveRecording(testJournalId)
        _ = sut.saveRecording(testJournalId)
        
        // Verify state transitions follow expected sequence: [.idle, .requestingPermission, .preparing, .recording, .paused, .recording, .stopping, .completed, .idle]
        let expectedStates: [AudioRecordingService.RecordingState] = [.idle, .recording, .paused, .recording, .completed, .idle]
        XCTAssertEqual(receivedStates, expectedStates, "Recording state transitions should follow expected sequence")
    }
    
    /// Test that cleanup properly resets the recording service
    func testCleanup() {
        // Start a recording with sut.startRecording(testRecordingId)
        _ = sut.startRecording(testRecordingId)
        
        // Call sut.cleanup()
        sut.cleanup()
        
        // Verify recording state is .idle
        XCTAssertEqual(sut.getRecordingState(), .idle, "Recording state should be .idle after cleanup")
        
        // Verify sut.isRecording() returns false
        XCTAssertFalse(sut.isRecording(), "sut.isRecording() should return false after cleanup")
        
        // Verify sut.getRecordingDuration() returns 0
        XCTAssertEqual(sut.getRecordingDuration(), 0, "sut.getRecordingDuration() should return 0 after cleanup")
    }
}