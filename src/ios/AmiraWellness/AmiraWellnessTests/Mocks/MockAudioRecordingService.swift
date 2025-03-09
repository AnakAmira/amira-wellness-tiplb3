import Foundation // Latest
import Combine // Latest
import AudioRecordingService // To access the real service's types and interfaces for mocking
import AudioMetadata // For creating mock audio metadata in tests

/// A mock implementation of AudioRecordingService for testing purposes
class MockAudioRecordingService {
    // MARK: - Singleton
    static let shared = MockAudioRecordingService()
    
    // MARK: - Properties
    private var state: RecordingState = .idle
    private var mockRecordingURL: URL?
    private var mockDuration: TimeInterval = 0
    private var statePublisher = PassthroughSubject<RecordingState, Never>()
    private var levelPublisher = PassthroughSubject<Float, Never>()
    private var durationPublisher = PassthroughSubject<TimeInterval, Never>()
    private var errorPublisher = PassthroughSubject<AudioRecordingError, Never>()
    private var mockLevelTimer: Timer?
    private var mockDurationTimer: Timer?
    private var recordingStartTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var currentRecordingId: UUID?
    
    // Test control properties
    var shouldSucceed = true
    var error: AudioRecordingError?
    
    // Method call tracking
    var startRecordingCalled = false
    var pauseRecordingCalled = false
    var resumeRecordingCalled = false
    var stopRecordingCalled = false
    var cancelRecordingCalled = false
    var saveRecordingCalled = false
    var getRecordingMetadataCalled = false
    
    // Mock data
    var mockEncryptionIv = "0123456789abcdef0123456789abcdef"
    var mockMetadata: AudioMetadata
    
    // MARK: - Initialization
    private init() {
        // Create a temporary URL for mock recordings
        let temporaryDirectory = FileManager.default.temporaryDirectory
        mockRecordingURL = temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        
        // Initialize mock metadata
        mockMetadata = AudioMetadata(
            fileFormat: "m4a",
            fileSizeBytes: 1024 * 1024, // 1MB
            sampleRate: 44100,
            bitRate: 128000,
            channels: 1,
            checksum: UUID().uuidString
        )
    }
    
    // MARK: - Public Methods
    
    /// Resets the mock to its initial state
    func reset() {
        state = .idle
        shouldSucceed = true
        error = nil
        startRecordingCalled = false
        pauseRecordingCalled = false
        resumeRecordingCalled = false
        stopRecordingCalled = false
        cancelRecordingCalled = false
        saveRecordingCalled = false
        getRecordingMetadataCalled = false
        mockDuration = 0
        pausedDuration = 0
        recordingStartTime = nil
        currentRecordingId = nil
        stopMockTimers()
    }
    
    /// Simulates starting a new audio recording session
    func startRecording(recordingId: UUID) -> Result<Void, AudioRecordingError> {
        startRecordingCalled = true
        
        if !shouldSucceed {
            return .failure(error ?? .hardwareError)
        }
        
        if state != .idle {
            return .failure(.recordingInProgress)
        }
        
        currentRecordingId = recordingId
        state = .recording
        statePublisher.send(state)
        recordingStartTime = Date()
        
        setupMockLevelTimer()
        setupMockDurationTimer()
        
        return .success(())
    }
    
    /// Simulates pausing an ongoing recording
    func pauseRecording() -> Result<Void, AudioRecordingError> {
        pauseRecordingCalled = true
        
        if !shouldSucceed {
            return .failure(error ?? .hardwareError)
        }
        
        if state != .recording {
            return .failure(.noRecordingInProgress)
        }
        
        if let startTime = recordingStartTime {
            pausedDuration += Date().timeIntervalSince(startTime)
        }
        
        stopMockTimers()
        
        state = .paused
        statePublisher.send(state)
        
        return .success(())
    }
    
    /// Simulates resuming a paused recording
    func resumeRecording() -> Result<Void, AudioRecordingError> {
        resumeRecordingCalled = true
        
        if !shouldSucceed {
            return .failure(error ?? .hardwareError)
        }
        
        if state != .paused {
            return .failure(.invalidRecordingState)
        }
        
        state = .recording
        statePublisher.send(state)
        recordingStartTime = Date()
        
        setupMockLevelTimer()
        setupMockDurationTimer()
        
        return .success(())
    }
    
    /// Simulates stopping and finalizing the current recording
    func stopRecording() -> Result<Void, AudioRecordingError> {
        stopRecordingCalled = true
        
        if !shouldSucceed {
            return .failure(error ?? .hardwareError)
        }
        
        if state != .recording && state != .paused {
            return .failure(.noRecordingInProgress)
        }
        
        state = .stopping
        statePublisher.send(state)
        
        stopMockTimers()
        
        // Calculate final duration
        if let startTime = recordingStartTime {
            mockDuration = pausedDuration + Date().timeIntervalSince(startTime)
        } else {
            mockDuration = pausedDuration
        }
        
        state = .completed
        statePublisher.send(state)
        
        return .success(())
    }
    
    /// Simulates canceling and discarding the current recording
    func cancelRecording() -> Result<Void, AudioRecordingError> {
        cancelRecordingCalled = true
        
        if !shouldSucceed {
            return .failure(error ?? .hardwareError)
        }
        
        if state != .recording && state != .paused && state != .processing {
            return .failure(.invalidRecordingState)
        }
        
        stopMockTimers()
        
        // Reset recording state
        pausedDuration = 0
        recordingStartTime = nil
        currentRecordingId = nil
        
        state = .idle
        statePublisher.send(state)
        
        return .success(())
    }
    
    /// Simulates saving the recorded audio file with encryption
    func saveRecording(journalId: UUID) -> Result<(URL, String), AudioRecordingError> {
        saveRecordingCalled = true
        
        if !shouldSucceed {
            return .failure(error ?? .encryptionError)
        }
        
        if state != .completed {
            return .failure(.invalidRecordingState)
        }
        
        state = .idle
        statePublisher.send(state)
        
        guard let url = mockRecordingURL else {
            return .failure(.fileSystemError)
        }
        
        return .success((url, mockEncryptionIv))
    }
    
    /// Gets the current recording state
    func getRecordingState() -> RecordingState {
        return state
    }
    
    /// Gets the current recording duration in seconds
    func getRecordingDuration() -> TimeInterval {
        switch state {
        case .recording, .paused, .stopping, .processing, .completed:
            if state == .paused {
                return pausedDuration
            } else if state == .completed {
                return mockDuration
            } else if let startTime = recordingStartTime {
                return pausedDuration + Date().timeIntervalSince(startTime)
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    /// Gets metadata about the completed recording
    func getRecordingMetadata() -> Result<AudioMetadata, AudioRecordingError> {
        getRecordingMetadataCalled = true
        
        if !shouldSucceed {
            return .failure(error ?? .fileSystemError)
        }
        
        if state != .completed && state != .processing {
            return .failure(.invalidRecordingState)
        }
        
        return .success(mockMetadata)
    }
    
    /// Checks if recording is currently in progress
    func isRecording() -> Bool {
        return state == .recording
    }
    
    /// Checks if recording is currently paused
    func isPaused() -> Bool {
        return state == .paused
    }
    
    /// Cleans up resources and resets recording state
    func cleanup() {
        stopMockTimers()
        pausedDuration = 0
        recordingStartTime = nil
        currentRecordingId = nil
        state = .idle
        statePublisher.send(state)
    }
    
    /// Publisher for recording state updates
    func recordingStatePublisher() -> AnyPublisher<RecordingState, Never> {
        return statePublisher.eraseToAnyPublisher()
    }
    
    /// Publisher for audio level updates during recording
    func audioLevelPublisher() -> AnyPublisher<Float, Never> {
        return levelPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher for recording duration updates
    func durationPublisher() -> AnyPublisher<TimeInterval, Never> {
        return durationPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher for recording error events
    func errorPublisher() -> AnyPublisher<AudioRecordingError, Never> {
        return errorPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Sets up timer for simulating audio levels
    private func setupMockLevelTimer() {
        mockLevelTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(updateMockAudioLevel),
            userInfo: nil,
            repeats: true
        )
    }
    
    /// Sets up timer for simulating recording duration
    private func setupMockDurationTimer() {
        mockDurationTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(updateMockDuration),
            userInfo: nil,
            repeats: true
        )
    }
    
    /// Stops the mock level and duration timers
    private func stopMockTimers() {
        mockLevelTimer?.invalidate()
        mockLevelTimer = nil
        mockDurationTimer?.invalidate()
        mockDurationTimer = nil
    }
    
    /// Updates and publishes simulated audio recording level
    @objc private func updateMockAudioLevel() {
        // Generate random audio level between 0.1 and 0.9
        let level = Float.random(in: 0.1...0.9)
        levelPublisher.send(level)
    }
    
    /// Updates and publishes simulated recording duration
    @objc private func updateMockDuration() {
        if let startTime = recordingStartTime {
            let currentDuration = pausedDuration + Date().timeIntervalSince(startTime)
            durationPublisher.send(currentDuration)
        }
    }
}