//
//  AudioPlaybackService.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import AVFoundation // Latest
import Combine // Latest

/// Errors that can occur during audio playback operations
enum AudioPlaybackError: Error {
    /// The audio file could not be found
    case fileNotFound
    /// Failed to decrypt the encrypted audio file
    case decryptionFailed
    /// The audio player failed to play the file
    case playbackFailed
    /// The operation cannot be performed in the current playback state
    case invalidPlaybackState
    /// An error occurred with the audio session
    case audioSessionError
    /// An error occurred during file system operations
    case fileSystemError
}

/// Represents the current state of audio playback
enum PlaybackState {
    /// No playback activity
    case idle
    /// Preparing audio for playback (decrypting, loading)
    case preparing
    /// Audio is currently playing
    case playing
    /// Playback is paused
    case paused
    /// Playback is stopped
    case stopped
    /// Playback has completed
    case completed
    /// Playback has failed
    case failed
}

/// A singleton service that manages audio playback for voice journaling
final class AudioPlaybackService: NSObject, AVAudioPlayerDelegate {
    
    // MARK: - Public Properties
    
    /// Shared instance of the AudioPlaybackService
    static let shared = AudioPlaybackService()
    
    // MARK: - Private Properties
    
    /// The audio player for playback
    private var audioPlayer: AVAudioPlayer?
    
    /// The audio session for configuring playback behavior
    private let audioSession = AVAudioSession.sharedInstance()
    
    /// The URL of the current audio file being played
    private var currentAudioFileURL: URL?
    
    /// The URL of the decrypted audio file for playback
    private var decryptedFileURL: URL?
    
    /// The current state of the playback process
    private var state: PlaybackState = .idle
    
    /// Service for decrypting encrypted audio files
    private let encryptionService = EncryptionService.shared
    
    /// Service for accessing and managing stored files
    private let storageService = StorageService.shared
    
    /// Service for providing haptic feedback during playback
    private let hapticManager = HapticManager.shared
    
    /// Publisher for broadcasting playback state changes
    private let statePublisher = PassthroughSubject<PlaybackState, Never>()
    
    /// Publisher for broadcasting playback progress updates
    private let progressPublisher = PassthroughSubject<TimeInterval, Never>()
    
    /// Publisher for broadcasting playback errors
    private let errorPublisher = PassthroughSubject<AudioPlaybackError, Never>()
    
    /// Timer for tracking and publishing playback progress
    private var progressTimer: Timer?
    
    /// ID of the currently playing journal entry
    private var currentJournalId: UUID?
    
    /// Set of cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private override init() {
        super.init()
        
        // Set up notification observers for audio session interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Prepares an audio file for playback by decrypting it if necessary
    /// - Parameters:
    ///   - fileURL: The URL of the encrypted audio file
    ///   - encryptionIv: The initialization vector used for encryption
    ///   - journalId: The unique identifier of the journal entry
    /// - Returns: The URL of the decrypted file ready for playback, or an error
    func prepareForPlayback(fileURL: URL, encryptionIv: String, journalId: UUID) -> Result<URL, AudioPlaybackError> {
        // Check if we're in a valid state for preparation
        guard state == .idle || state == .stopped else {
            Logger.shared.error("Cannot prepare for playback in current state: \(state)", category: .audio)
            return .failure(.invalidPlaybackState)
        }
        
        // Update state to preparing
        state = .preparing
        statePublisher.send(state)
        
        // Check if file exists
        guard storageService.fileExists(atPath: fileURL) else {
            Logger.shared.error("Audio file not found at path: \(fileURL.path)", category: .audio)
            state = .failed
            statePublisher.send(state)
            return .failure(.fileNotFound)
        }
        
        // Generate a temporary file URL for the decrypted audio
        let decryptedURL = createTemporaryURL(journalId: journalId)
        
        // Decrypt the audio file
        let decryptResult = encryptionService.decryptFile(
            fileURL: fileURL,
            destinationURL: decryptedURL,
            keyIdentifier: KeyType.journalKey.rawValue,
            iv: encryptionIv
        )
        
        guard case .success = decryptResult else {
            Logger.shared.error("Failed to decrypt audio file", category: .audio)
            state = .failed
            statePublisher.send(state)
            errorPublisher.send(.decryptionFailed)
            return .failure(.decryptionFailed)
        }
        
        // Store references to the decrypted file and journal ID
        self.decryptedFileURL = decryptedURL
        self.currentJournalId = journalId
        
        // Configure audio session for playback
        let sessionResult = configureAudioSession()
        guard case .success = sessionResult else {
            Logger.shared.error("Failed to configure audio session", category: .audio)
            if case let .failure(error) = sessionResult {
                return .failure(error)
            }
            return .failure(.audioSessionError)
        }
        
        // Initialize the audio player with the decrypted file
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: decryptedURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        } catch {
            Logger.shared.error("Failed to initialize audio player", error: error, category: .audio)
            state = .failed
            statePublisher.send(state)
            errorPublisher.send(.playbackFailed)
            return .failure(.playbackFailed)
        }
        
        // Update state to stopped (ready to play)
        state = .stopped
        statePublisher.send(state)
        
        // Provide haptic feedback that preparation is complete
        hapticManager.generateFeedback(.light)
        
        Logger.shared.info("Audio prepared for playback successfully", category: .audio)
        return .success(decryptedURL)
    }
    
    /// Starts audio playback
    /// - Returns: Success or error result
    func startPlayback() -> Result<Void, AudioPlaybackError> {
        // Check if we're in a valid state to start playback
        guard state == .stopped || state == .completed else {
            Logger.shared.error("Cannot start playback in current state: \(state)", category: .audio)
            return .failure(.invalidPlaybackState)
        }
        
        // Check if audio player is initialized
        guard let player = audioPlayer else {
            Logger.shared.error("Audio player not initialized", category: .audio)
            return .failure(.playbackFailed)
        }
        
        // Start playback
        let playSuccess = player.play()
        if !playSuccess {
            Logger.shared.error("Audio player failed to start playback", category: .audio)
            state = .failed
            statePublisher.send(state)
            errorPublisher.send(.playbackFailed)
            return .failure(.playbackFailed)
        }
        
        // Update state to playing
        state = .playing
        statePublisher.send(state)
        
        // Start progress tracking
        setupProgressTimer()
        
        // Provide haptic feedback
        hapticManager.generateFeedback(.medium)
        
        Logger.shared.info("Audio playback started", category: .audio)
        return .success(())
    }
    
    /// Pauses ongoing audio playback
    /// - Returns: Success or error result
    func pausePlayback() -> Result<Void, AudioPlaybackError> {
        // Check if we're in a valid state to pause
        guard state == .playing else {
            Logger.shared.error("Cannot pause playback in current state: \(state)", category: .audio)
            return .failure(.invalidPlaybackState)
        }
        
        // Check if audio player is initialized
        guard let player = audioPlayer else {
            Logger.shared.error("Audio player not initialized", category: .audio)
            return .failure(.playbackFailed)
        }
        
        // Pause playback
        player.pause()
        
        // Update state to paused
        state = .paused
        statePublisher.send(state)
        
        // Stop progress timer
        stopProgressTimer()
        
        // Provide haptic feedback
        hapticManager.generateFeedback(.light)
        
        Logger.shared.info("Audio playback paused", category: .audio)
        return .success(())
    }
    
    /// Resumes paused audio playback
    /// - Returns: Success or error result
    func resumePlayback() -> Result<Void, AudioPlaybackError> {
        // Check if we're in a valid state to resume
        guard state == .paused else {
            Logger.shared.error("Cannot resume playback in current state: \(state)", category: .audio)
            return .failure(.invalidPlaybackState)
        }
        
        // Check if audio player is initialized
        guard let player = audioPlayer else {
            Logger.shared.error("Audio player not initialized", category: .audio)
            return .failure(.playbackFailed)
        }
        
        // Resume playback
        let playSuccess = player.play()
        if !playSuccess {
            Logger.shared.error("Audio player failed to resume playback", category: .audio)
            state = .failed
            statePublisher.send(state)
            errorPublisher.send(.playbackFailed)
            return .failure(.playbackFailed)
        }
        
        // Update state to playing
        state = .playing
        statePublisher.send(state)
        
        // Start progress tracking
        setupProgressTimer()
        
        // Provide haptic feedback
        hapticManager.generateFeedback(.light)
        
        Logger.shared.info("Audio playback resumed", category: .audio)
        return .success(())
    }
    
    /// Stops audio playback
    /// - Returns: Success or error result
    func stopPlayback() -> Result<Void, AudioPlaybackError> {
        // Check if we're in a valid state to stop
        guard state == .playing || state == .paused else {
            // Not an error if already stopped
            return .success(())
        }
        
        // Check if audio player is initialized
        guard let player = audioPlayer else {
            // Not an error if no player
            return .success(())
        }
        
        // Stop playback and reset position
        player.stop()
        player.currentTime = 0
        
        // Update state to stopped
        state = .stopped
        statePublisher.send(state)
        
        // Stop progress timer
        stopProgressTimer()
        
        // Provide haptic feedback
        hapticManager.generateFeedback(.medium)
        
        Logger.shared.info("Audio playback stopped", category: .audio)
        return .success(())
    }
    
    /// Seeks to a specific position in the audio
    /// - Parameter position: The position in seconds to seek to
    /// - Returns: Success or error result
    func seekTo(position: TimeInterval) -> Result<Void, AudioPlaybackError> {
        // Check if audio player is initialized
        guard let player = audioPlayer else {
            Logger.shared.error("Cannot seek: Audio player not initialized", category: .audio)
            return .failure(.playbackFailed)
        }
        
        // Validate the position is within bounds
        let duration = player.duration
        let validPosition = max(0, min(position, duration))
        
        // Set the playback position
        player.currentTime = validPosition
        
        // Publish the updated position
        progressPublisher.send(validPosition)
        
        Logger.shared.debug("Seeked to position: \(validPosition)", category: .audio)
        return .success(())
    }
    
    /// Gets the current playback position in seconds
    /// - Returns: Current position in seconds
    func getCurrentPosition() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    /// Gets the total duration of the current audio in seconds
    /// - Returns: Total duration in seconds
    func getDuration() -> TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    /// Gets the current playback state
    /// - Returns: Current state of playback
    func getPlaybackState() -> PlaybackState {
        return state
    }
    
    /// Checks if audio is currently playing
    /// - Returns: True if playing, false otherwise
    func isPlaying() -> Bool {
        return state == .playing
    }
    
    /// Checks if audio is currently paused
    /// - Returns: True if paused, false otherwise
    func isPaused() -> Bool {
        return state == .paused
    }
    
    /// Updates and publishes current playback progress
    @objc private func updateProgress() {
        guard let player = audioPlayer, state == .playing else {
            return
        }
        
        let currentTime = player.currentTime
        let duration = player.duration
        
        // Publish current position
        progressPublisher.send(currentTime)
        
        // Check if we're at or near the end of the audio
        if currentTime >= duration - 0.1 {
            handlePlaybackCompletion()
        }
    }
    
    /// Sets up timer for tracking playback progress
    private func setupProgressTimer() {
        // Stop any existing timer
        stopProgressTimer()
        
        // Create a new timer that fires every 0.1 seconds
        progressTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(updateProgress),
            userInfo: nil,
            repeats: true
        )
    }
    
    /// Stops the progress timer
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    /// Configures the audio session for playback
    /// - Returns: Success or error result
    private func configureAudioSession() -> Result<Void, AudioPlaybackError> {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            return .success(())
        } catch {
            Logger.shared.error("Failed to configure audio session", error: error, category: .audio)
            return .failure(.audioSessionError)
        }
    }
    
    /// Creates a temporary URL for decrypted audio
    /// - Parameter journalId: The journal ID for unique filename generation
    /// - Returns: Temporary file URL
    private func createTemporaryURL(journalId: UUID) -> URL {
        let fileName = "\(journalId)_decrypted.\(AppConstants.Audio.audioFileExtension)"
        return storageService.getCacheFileURL(fileName)
    }
    
    /// Handles playback completion
    private func handlePlaybackCompletion() {
        // Update state to completed
        state = .completed
        statePublisher.send(state)
        
        // Stop progress timer
        stopProgressTimer()
        
        // Provide haptic feedback for completion
        hapticManager.generateFeedback(.success)
        
        Logger.shared.info("Audio playback completed", category: .audio)
    }
    
    /// Handles audio session interruptions
    /// - Parameter notification: The interruption notification
    @objc private func audioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            // Interruption began (e.g., phone call)
            if state == .playing {
                // Auto-pause playback
                let _ = pausePlayback()
                Logger.shared.info("Audio playback paused due to interruption", category: .audio)
            }
        } else if type == .ended {
            // Interruption ended
            if state == .paused,
               let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                // Auto-resume playback
                let _ = resumePlayback()
                Logger.shared.info("Audio playback resumed after interruption", category: .audio)
            }
        }
    }
    
    /// Cleans up resources and resets playback state
    func cleanup() {
        // Stop playback if it's active
        if state == .playing || state == .paused {
            let _ = stopPlayback()
        }
        
        // Stop progress timer
        stopProgressTimer()
        
        // Delete temporary decrypted file if it exists
        if let decryptedURL = decryptedFileURL, storageService.fileExists(atPath: decryptedURL) {
            do {
                try FileManager.default.removeItem(at: decryptedURL)
                Logger.shared.debug("Deleted temporary decrypted audio file", category: .audio)
            } catch {
                Logger.shared.error("Failed to delete temporary audio file", error: error, category: .audio)
            }
        }
        
        // Reset state variables
        decryptedFileURL = nil
        currentJournalId = nil
        audioPlayer = nil
        
        // Update state to idle
        state = .idle
        statePublisher.send(state)
        
        Logger.shared.info("Audio playback resources cleaned up", category: .audio)
    }
    
    /// Publisher for playback state updates
    /// - Returns: Publisher emitting playback state changes
    func playbackStatePublisher() -> AnyPublisher<PlaybackState, Never> {
        return statePublisher.eraseToAnyPublisher()
    }
    
    /// Publisher for playback progress updates
    /// - Returns: Publisher emitting playback position values
    func playbackProgressPublisher() -> AnyPublisher<TimeInterval, Never> {
        return progressPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher for playback error events
    /// - Returns: Publisher emitting playback errors
    func playbackErrorPublisher() -> AnyPublisher<AudioPlaybackError, Never> {
        return errorPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            handlePlaybackCompletion()
        } else {
            Logger.shared.error("Audio player did not finish playing successfully", category: .audio)
            state = .failed
            statePublisher.send(state)
            errorPublisher.send(.playbackFailed)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            Logger.shared.error("Audio player decode error occurred", error: error, category: .audio)
        } else {
            Logger.shared.error("Unknown audio player decode error occurred", category: .audio)
        }
        
        state = .failed
        statePublisher.send(state)
        errorPublisher.send(.playbackFailed)
    }
}