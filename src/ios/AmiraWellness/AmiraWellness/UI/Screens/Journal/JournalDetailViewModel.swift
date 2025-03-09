//
//  JournalDetailViewModel.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // iOS SDK
import Combine // iOS SDK
import SwiftUI // iOS SDK

/// A view model that manages the state and business logic for the Journal Detail screen
@MainActor
class JournalDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The UUID of the journal entry being displayed
    let journalId: UUID
    
    /// The journal entry being displayed
    @Published var journal: Journal?
    
    /// The emotional shift between pre and post journaling states
    @Published var emotionalShift: EmotionalShift?
    
    /// Indicates if the journal data is currently being loaded
    @Published var isLoading: Bool = false
    
    /// An error message to display to the user if loading fails
    @Published var errorMessage: String?
    
    /// The current playback state of the audio
    @Published var playbackState: PlaybackState = .idle
    
    /// The current playback position in seconds
    @Published var currentPosition: TimeInterval = 0
    
    /// The total duration of the audio in seconds
    @Published var duration: TimeInterval = 0
    
    /// The playback progress as a value between 0.0 and 1.0
    @Published var playbackProgress: Double = 0.0
    
    /// Indicates if the journal is currently being exported
    @Published var isExporting: Bool = false
    
    /// The URL of the exported journal file
    @Published var exportURL: URL?
    
    /// Indicates if the delete confirmation dialog is being displayed
    @Published var showDeleteConfirmation: Bool = false
    
    /// Indicates if the export password prompt is being displayed
    @Published var showExportPasswordPrompt: Bool = false
    
    /// The password entered by the user for exporting the journal
    @Published var exportPassword = ""
    
    // MARK: - Private Properties
    
    /// Service for managing journal entries and audio playback
    private let journalService: JournalService = JournalService.shared
    
    /// Service for audio playback functionality
    private let playbackService: AudioPlaybackService = AudioPlaybackService.shared
    
    /// Service for encrypting journal data for export
    private let encryptionService: EncryptionService = EncryptionService.shared
    
    /// Service for providing haptic feedback during user interactions
    private let hapticManager: HapticManager = HapticManager.shared
    
    /// Set of Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with a journal ID and loads the journal data
    /// - Parameter journalId: The UUID of the journal entry to load
    init(journalId: UUID) {
        // Store the journalId parameter
        self.journalId = journalId
        
        // Initialize journalService with JournalService.shared
        // Initialize playbackService with AudioPlaybackService.shared
        // Initialize encryptionService with EncryptionService.shared
        // Initialize hapticManager with HapticManager.shared
        // Initialize cancellables as an empty Set
        // Set isLoading to true
        // Set journal to nil
        // Set emotionalShift to nil
        // Set errorMessage to nil
        // Set playbackState to .idle
        // Set currentPosition to 0
        // Set duration to 0
        // Set playbackProgress to 0
        // Set isExporting to false
        // Set exportURL to nil
        // Set showDeleteConfirmation to false
        // Set showExportPasswordPrompt to false
        // Set exportPassword to an empty string
        
        // Subscribe to playbackService.playbackStatePublisher
        playbackService.playbackStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handlePlaybackStateChange(state: state)
            }
            .store(in: &cancellables)
        
        // Subscribe to playbackService.playbackProgressPublisher
        playbackService.playbackProgressPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] position in
                self?.handlePlaybackProgress(position: position)
            }
            .store(in: &cancellables)
        
        // Load the journal data using loadJournal()
        loadJournal()
    }
    
    // MARK: - Public Methods
    
    /// Loads the journal data from the journal service
    private func loadJournal() {
        // Set isLoading to true
        isLoading = true
        
        // Call journalService.getJournal with journalId
        journalService.getJournal(journalId: journalId)
            .sink(receiveCompletion: { [weak self] completion in
                // On failure, set errorMessage and isLoading to false
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                    Logger.shared.error("Failed to load journal: \(error)", category: .userInterface)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] journal in
                // On success, store the journal and extract the emotional shift
                self?.journal = journal
                self?.emotionalShift = journal.getEmotionalShift()
                self?.isLoading = false
                Logger.shared.debug("Journal loaded successfully", category: .userInterface)
            })
            .store(in: &cancellables)
    }
    
    /// Prepares the audio for playback
    func preparePlayback() {
        // Check if journal is loaded, return if not
        guard let journal = journal else {
            Logger.shared.error("Cannot prepare playback: Journal not loaded", category: .audio)
            return
        }
        
        // Set playbackState to .preparing
        playbackState = .preparing
        
        // Call journalService.playJournal with journalId
        journalService.playJournal(journalId: journal.id)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage and playbackState to .failed
                    self?.errorMessage = error.localizedDescription
                    self?.playbackState = .failed
                    Logger.shared.error("Failed to prepare playback: \(error)", category: .audio)
                case .finished:
                    // On success, update duration from playbackService.getDuration()
                    self?.duration = self?.playbackService.getDuration() ?? 0
                    Logger.shared.debug("Playback prepared successfully", category: .audio)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
    }
    
    /// Toggles between play and pause states
    func togglePlayback() {
        // Check if journal is loaded, return if not
        guard journal != nil else {
            Logger.shared.error("Cannot toggle playback: Journal not loaded", category: .audio)
            return
        }
        
        // If playbackState is .playing, call pausePlayback()
        if playbackState == .playing {
            pausePlayback()
        }
        // If playbackState is .paused, call resumePlayback()
        else if playbackState == .paused {
            resumePlayback()
        }
        // If playbackState is .stopped or .completed, call startPlayback()
        else if playbackState == .stopped || playbackState == .completed {
            startPlayback()
        }
        // If playbackState is .idle, call preparePlayback() then startPlayback()
        else if playbackState == .idle {
            preparePlayback()
            startPlayback()
        }
        
        // Generate haptic feedback for the action
        hapticManager.generateFeedback(.medium)
        
        // Log the playback toggle action
        Logger.shared.logUserAction("Toggled playback to \(playbackState)", file: #file, line: #line, function: #function)
    }
    
    /// Starts audio playback
    private func startPlayback() {
        // Check if journal is loaded, return if not
        guard let journal = journal else {
            Logger.shared.error("Cannot start playback: Journal not loaded", category: .audio)
            return
        }
        
        // Call journalService.playJournal with journalId
        journalService.playJournal(journalId: journal.id)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage and playbackState to .failed
                    self?.errorMessage = error.localizedDescription
                    self?.playbackState = .failed
                    Logger.shared.error("Failed to start playback: \(error)", category: .audio)
                case .finished:
                    // On success, update playbackState to .playing
                    self?.playbackState = .playing
                    Logger.shared.debug("Playback started successfully", category: .audio)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
    }
    
    /// Pauses audio playback
    private func pausePlayback() {
        // Call journalService.pausePlayback()
        journalService.pausePlayback()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage
                    self?.errorMessage = error.localizedDescription
                    Logger.shared.error("Failed to pause playback: \(error)", category: .audio)
                case .finished:
                    // On success, update playbackState to .paused
                    self?.playbackState = .paused
                    Logger.shared.debug("Playback paused successfully", category: .audio)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
    }
    
    /// Resumes paused audio playback
    private func resumePlayback() {
        // Call journalService.resumePlayback()
        journalService.resumePlayback()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage
                    self?.errorMessage = error.localizedDescription
                    Logger.shared.error("Failed to resume playback: \(error)", category: .audio)
                case .finished:
                    // On success, update playbackState to .playing
                    self?.playbackState = .playing
                    Logger.shared.debug("Playback resumed successfully", category: .audio)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
    }
    
    /// Stops audio playback
    func stopPlayback() {
        // Call journalService.stopPlayback()
        journalService.stopPlayback()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage
                    self?.errorMessage = error.localizedDescription
                    Logger.shared.error("Failed to stop playback: \(error)", category: .audio)
                case .finished:
                    // On success, update playbackState to .stopped and reset currentPosition
                    self?.playbackState = .stopped
                    self?.currentPosition = 0
                    Logger.shared.debug("Playback stopped successfully", category: .audio)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
    }
    
    /// Seeks to a specific position in the audio
    /// - Parameter position: The position in seconds to seek to
    func seekTo(position: TimeInterval) {
        // Call playbackService.seekTo with position
        playbackService.seekTo(position: position)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage
                    self?.errorMessage = error.localizedDescription
                    Logger.shared.error("Failed to seek to position: \(error)", category: .audio)
                case .finished:
                    // On success, update currentPosition
                    self?.currentPosition = position
                    Logger.shared.debug("Seeked to position successfully", category: .audio)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
    }
    
    /// Toggles the favorite status of the journal
    func toggleFavorite() {
        // Check if journal is loaded, return if not
        guard let journal = journal else {
            Logger.shared.error("Cannot toggle favorite: Journal not loaded", category: .userInterface)
            return
        }
        
        // Call journalService.toggleFavorite with journalId
        journalService.toggleFavorite(journalId: journal.id)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage
                    self?.errorMessage = error.localizedDescription
                    Logger.shared.error("Failed to toggle favorite: \(error)", category: .userInterface)
                case .finished:
                    // On success, update the journal property
                    self?.journal?.isFavorite.toggle()
                    Logger.shared.debug("Toggled favorite successfully", category: .userInterface)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
        
        // Generate haptic feedback for the action
        hapticManager.generateFeedback(.light)
    }
    
    /// Shows the delete confirmation dialog
    func deleteJournal() {
        // Set showDeleteConfirmation to true
        showDeleteConfirmation = true
        
        // Generate haptic feedback for the action
        hapticManager.generateFeedback(.warning)
    }
    
    /// Confirms and performs journal deletion
    func confirmDelete() {
        // Set showDeleteConfirmation to false
        showDeleteConfirmation = false
        
        // Check if journal is loaded, return if not
        guard let journal = journal else {
            Logger.shared.error("Cannot confirm delete: Journal not loaded", category: .userInterface)
            return
        }
        
        // Stop playback if active
        if playbackState == .playing || playbackState == .paused {
            stopPlayback()
        }
        
        // Call journalService.deleteJournal with journalId
        journalService.deleteJournal(journalId: journal.id)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage
                    self?.errorMessage = error.localizedDescription
                    Logger.shared.error("Failed to delete journal: \(error)", category: .userInterface)
                case .finished:
                    // On success, set journal to nil and notify caller via NotificationCenter
                    self?.journal = nil
                    NotificationCenter.default.post(name: .journalDeleted, object: nil, userInfo: ["journalId": journal.id])
                    Logger.shared.debug("Journal deleted successfully", category: .userInterface)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
        
        // Generate haptic feedback for the action
        hapticManager.generateFeedback(.success)
    }
    
    /// Cancels the delete operation
    func cancelDelete() {
        // Set showDeleteConfirmation to false
        showDeleteConfirmation = false
    }
    
    /// Shows the export password prompt
    func exportJournal() {
        // Set showExportPasswordPrompt to true
        showExportPasswordPrompt = true
        
        // Generate haptic feedback for the action
        hapticManager.generateFeedback(.light)
    }
    
    /// Confirms and performs journal export with password protection
    func confirmExport() {
        // Set showExportPasswordPrompt to false
        showExportPasswordPrompt = false
        
        // Check if journal is loaded, return if not
        guard let journal = journal else {
            Logger.shared.error("Cannot confirm export: Journal not loaded", category: .userInterface)
            return
        }
        
        // Check if exportPassword meets minimum requirements, set errorMessage and return if not
        if exportPassword.count < 8 {
            errorMessage = "Password must be at least 8 characters long"
            return
        }
        
        // Set isExporting to true
        isExporting = true
        
        // Create a temporary file URL for export
        let tempFilename = "\(journal.id)-exported.m4a"
        guard let tempExportURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(tempFilename) else {
            errorMessage = "Could not create temporary file URL"
            isExporting = false
            return
        }
        
        // Call journalService.exportJournal with journalId and destination URL
        journalService.exportJournal(journalId: journal.id, destinationURL: tempExportURL)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage and isExporting to false
                    self?.errorMessage = error.localizedDescription
                    self?.isExporting = false
                    Logger.shared.error("Failed to export journal: \(error)", category: .userInterface)
                case .finished:
                    // On success, encrypt the exported file with the password
                    self?.encryptExportedFile(fileURL: tempExportURL)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
        
        // Generate haptic feedback for the action
        hapticManager.generateFeedback(.success)
    }
    
    /// Cancels the export operation
    func cancelExport() {
        // Set showExportPasswordPrompt to false
        showExportPasswordPrompt = false
        
        // Set exportPassword to an empty string
        exportPassword = ""
    }
    
    /// Clears the export URL after sharing
    func clearExportURL() {
        // Set exportURL to nil
        exportURL = nil
        
        // Delete the temporary exported file if it exists
        if let tempExportURL = exportURL, FileManager.default.fileExists(atPath: tempExportURL.path) {
            do {
                try FileManager.default.removeItem(at: tempExportURL)
                Logger.shared.debug("Deleted temporary exported file", category: .userInterface)
            } catch {
                Logger.shared.error("Failed to delete temporary exported file: \(error)", category: .userInterface)
            }
        }
    }
    
    /// Formats a time interval as MM:SS
    /// - Parameter interval: The time interval to format
    /// - Returns: A formatted time string
    func formatTimeInterval(interval: TimeInterval) -> String {
        // Calculate minutes and seconds from the interval
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        // Format as MM:SS
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Gets the icon name for an emotion type
    /// - Parameter emotionType: The emotion type
    /// - Returns: The icon name for the emotion
    func getEmotionIcon(emotionType: EmotionType) -> String {
        // Map the emotion type to a corresponding icon name
        switch emotionType {
        case .joy:
            return "face.smiling"
        case .sadness:
            return "face.sad"
        case .anger:
            return "exclamationmark.triangle"
        case .fear:
            return "eye.slash"
        default:
            return "face.smiling" // Default icon
        }
    }
    
    /// Gets the localized name for an emotion type
    /// - Parameter emotionType: The emotion type
    /// - Returns: The localized name for the emotion
    func getEmotionName(emotionType: EmotionType) -> String {
        // Return emotionType.displayName()
        return emotionType.displayName()
    }
    
    /// Generates a description of the emotional shift
    func getEmotionalShiftDescription() -> String {
        // Check if emotionalShift is nil, return empty string if so
        guard let emotionalShift = emotionalShift else {
            return ""
        }
        
        // Generate a description based on the shift direction (positive, negative, neutral)
        if emotionalShift.isPositive() {
            return "Positive shift"
        } else if emotionalShift.isNegative() {
            return "Negative shift"
        } else {
            return "No significant shift"
        }
        
        // Include the emotion types and intensity change
        // Return the formatted description
    }
    
    // MARK: - Private Methods
    
    /// Handles playback state changes from the service
    private func handlePlaybackStateChange(state: PlaybackState) {
        // Update playbackState property
        playbackState = state
        
        // Handle specific state transitions (e.g., completed, failed)
        switch state {
        case .completed:
            Logger.shared.debug("Playback completed", category: .audio)
        case .failed:
            Logger.shared.error("Playback failed", category: .audio)
        default:
            break
        }
        
        // Log the state change
        Logger.shared.debug("Playback state changed to \(state)", category: .audio)
    }
    
    /// Handles playback progress updates from the service
    private func handlePlaybackProgress(position: TimeInterval) {
        // Update currentPosition property
        currentPosition = position
        
        // Calculate and update playbackProgress (0.0-1.0)
        if duration > 0 {
            playbackProgress = Double(position / duration)
        } else {
            playbackProgress = 0.0
        }
        
        // Log the progress update for debugging
        Logger.shared.debug("Playback progress updated to \(position)", category: .audio)
    }
    
    /// Encrypts the exported file with the password
    private func encryptExportedFile(fileURL: URL) {
        // Check if journal is loaded, return if not
        guard let journal = journal else {
            Logger.shared.error("Cannot encrypt exported file: Journal not loaded", category: .userInterface)
            return
        }
        
        // Call encryptionService.encryptWithPassword with fileURL and exportPassword
        encryptionService.encryptWithPassword(data: Data(), password: exportPassword)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // On failure, set errorMessage and isExporting to false
                    self?.errorMessage = error.localizedDescription
                    self?.isExporting = false
                    Logger.shared.error("Failed to encrypt exported file: \(error)", category: .userInterface)
                case .finished:
                    // On success, set exportURL to the encrypted file URL
                    self?.exportURL = fileURL
                    self?.isExporting = false
                    Logger.shared.debug("Exported file encrypted successfully", category: .userInterface)
                }
            }, receiveValue: { _ in
                // No value to receive
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Deinitialization
    
    /// Cleanup when the view model is deallocated
    deinit {
        // Stop playback if active
        stopPlayback()
        
        // Cancel all subscriptions in cancellables
        cancellables.forEach { $0.cancel() }
        
        // Log the deinitialization
        Logger.shared.debug("JournalDetailViewModel deinitialized", category: .userInterface)
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let journalDeleted = Notification.Name("journalDeleted")
}