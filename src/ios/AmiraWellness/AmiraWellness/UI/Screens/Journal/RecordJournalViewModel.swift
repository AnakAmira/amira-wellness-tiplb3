# src/ios/AmiraWellness/AmiraWellness/UI/Screens/Journal/RecordJournalViewModel.swift
import Foundation // standard library
import Combine // Reactive programming for handling asynchronous events
import SwiftUI // UI framework for building the recording interface

// Internal imports
import Journal // Core data model for voice journal entries
import EmotionalState // Model for tracking emotional states before and after journaling
import EmotionType // Enumeration of emotion types for selection in UI
import CheckInContext // Defines contexts for emotional check-ins
import JournalService // Service for managing journal recordings and data
import AudioRecordingService // Service for audio recording functionality
import RecordingState // States of the recording process
import EmotionService // Service for managing emotional data
import HapticManager // Provides haptic feedback during recording operations
import Logger // Logging service for recording events and errors

/// Enum defining the different view states for the voice journal recording screen
enum RecordJournalViewState {
    case preCheckIn
    case recording
    case postCheckIn
    case saving
    case completed
    case error
}

/// ViewModel for the voice journal recording screen, managing the recording process and emotional check-ins
@MainActor
@ObservableObject
class RecordJournalViewModel {
    // MARK: - Private Properties

    private let journalService: JournalService
    private let recordingService: AudioRecordingService
    private let emotionService: EmotionService
    private let hapticManager: HapticManager

    @Published var viewState: RecordJournalViewState = .preCheckIn
    @Published var selectedEmotionType: EmotionType?
    @Published var emotionIntensity: Int = 5
    @Published var notes: String = ""
    @Published var journalTitle: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false
    @Published var isProcessing: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var completedJournal: Journal?

    private var currentJournalId: UUID?
    private var preRecordingState: EmotionalState?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initializes the RecordJournalViewModel with dependencies
    /// - Parameters:
    ///   - journalService: Optional JournalService instance
    ///   - recordingService: Optional AudioRecordingService instance
    ///   - emotionService: Optional EmotionService instance
    ///   - hapticManager: Optional HapticManager instance
    init(journalService: JournalService? = nil, recordingService: AudioRecordingService? = nil, emotionService: EmotionService? = nil, hapticManager: HapticManager? = nil) {
        self.journalService = journalService ?? JournalService.shared
        self.recordingService = recordingService ?? AudioRecordingService.shared
        self.emotionService = emotionService ?? EmotionService()
        self.hapticManager = hapticManager ?? HapticManager.shared

        self.viewState = .preCheckIn
        self.emotionIntensity = 5
        self.notes = ""
        self.journalTitle = ""
        self.audioLevel = 0.0
        self.recordingDuration = 0.0
        self.isRecording = false
        self.isPaused = false
        self.isProcessing = false
        self.showError = false
        self.cancellables = Set<AnyCancellable>()

        subscribeToRecordingService()
    }

    // MARK: - Public Methods

    /// Sets up subscriptions to recording service publishers
    private func subscribeToRecordingService() {
        recordingService.recordingStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isRecording = state == .recording
                self?.isPaused = state == .paused
                self?.isProcessing = state == .processing
            }
            .store(in: &cancellables)

        recordingService.audioLevelPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)

        recordingService.durationPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                self?.recordingDuration = duration
            }
            .store(in: &cancellables)

        recordingService.errorPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleError(error: error, context: "AudioRecordingService")
            }
            .store(in: &cancellables)
    }

    /// Submits the pre-recording emotional state and starts recording
    func submitPreRecordingEmotionalState() {
        guard let selectedEmotionType = selectedEmotionType else {
            errorMessage = "Please select an emotion."
            showError = true
            return
        }

        let emotionalState = EmotionalState(emotionType: selectedEmotionType, intensity: emotionIntensity, context: .preJournaling, notes: notes)

        emotionService.recordEmotionalState(emotionType: selectedEmotionType, intensity: emotionIntensity, context: .preJournaling, notes: notes) { [weak self] result in
            switch result {
            case .success(let recordedState):
                self?.preRecordingState = recordedState
                self?.journalService.startRecording(emotionalState: recordedState) { result in
                    switch result {
                    case .success(let journalId):
                        self?.currentJournalId = journalId
                        self?.viewState = .recording
                        self?.hapticManager.generateFeedback(.success)
                        Logger.shared.log("Started recording with journal ID: \(journalId)", category: .audio)
                    case .failure(let error):
                        self?.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                        self?.showError = true
                        self?.viewState = .error
                        self?.hapticManager.generateFeedback(.error)
                        Logger.shared.error("Failed to start recording: \(error)", category: .audio)
                    }
                }
            case .failure(let error):
                self?.errorMessage = "Failed to record pre-recording emotional state: \(error.localizedDescription)"
                self?.showError = true
                self?.hapticManager.generateFeedback(.error)
                Logger.shared.error("Failed to record pre-recording emotional state: \(error)", category: .emotions)
            }
        }
    }

    /// Toggles between paused and recording states
    func toggleRecording() {
        if isPaused {
            journalService.resumeRecording { [weak self] result in
                switch result {
                case .success:
                    self?.hapticManager.generateFeedback(.light)
                    Logger.shared.log("Resumed recording", category: .audio)
                case .failure(let error):
                    self?.errorMessage = "Failed to resume recording: \(error.localizedDescription)"
                    self?.showError = true
                    self?.hapticManager.generateFeedback(.error)
                    Logger.shared.error("Failed to resume recording: \(error)", category: .audio)
                }
            }
        } else {
            journalService.pauseRecording { [weak self] result in
                switch result {
                case .success:
                    self?.hapticManager.generateFeedback(.light)
                    Logger.shared.log("Paused recording", category: .audio)
                case .failure(let error):
                    self?.errorMessage = "Failed to pause recording: \(error.localizedDescription)"
                    self?.showError = true
                    self?.hapticManager.generateFeedback(.error)
                    Logger.shared.error("Failed to pause recording: \(error)", category: .audio)
                }
            }
        }
    }

    /// Stops the current recording and transitions to post-recording check-in
    func stopRecording() {
        journalService.stopRecording { [weak self] result in
            switch result {
            case .success:
                self?.viewState = .postCheckIn
                self?.selectedEmotionType = nil
                self?.notes = ""
                self?.hapticManager.generateFeedback(.success)
                Logger.shared.log("Stopped recording", category: .audio)
            case .failure(let error):
                self?.errorMessage = "Failed to stop recording: \(error.localizedDescription)"
                self?.showError = true
                self?.viewState = .error
                self?.hapticManager.generateFeedback(.error)
                Logger.shared.error("Failed to stop recording: \(error)", category: .audio)
            }
        }
    }

    /// Cancels and discards the current recording
    func cancelRecording() {
        journalService.cancelRecording { [weak self] result in
            switch result {
            case .success:
                self?.viewState = .preCheckIn
                self?.resetViewModel()
                self?.hapticManager.generateFeedback(.warning)
                Logger.shared.log("Cancelled recording", category: .audio)
            case .failure(let error):
                self?.errorMessage = "Failed to cancel recording: \(error.localizedDescription)"
                self?.showError = true
                self?.hapticManager.generateFeedback(.error)
                Logger.shared.error("Failed to cancel recording: \(error)", category: .audio)
            }
        }
    }

    /// Submits the post-recording emotional state and saves the journal
    func submitPostRecordingEmotionalState() {
        guard let selectedEmotionType = selectedEmotionType else {
            errorMessage = "Please select an emotion."
            showError = true
            return
        }

        let emotionalState = EmotionalState(emotionType: selectedEmotionType, intensity: emotionIntensity, context: .postJournaling, notes: notes)

        emotionService.recordEmotionalState(emotionType: selectedEmotionType, intensity: emotionIntensity, context: .postJournaling, notes: notes) { [weak self] result in
            switch result {
            case .success(let recordedState):
                self?.viewState = .saving
                guard let journalId = self?.currentJournalId else {
                    self?.errorMessage = "Journal ID is missing."
                    self?.showError = true
                    self?.viewState = .error
                    self?.hapticManager.generateFeedback(.error)
                    Logger.shared.error("Journal ID is missing", category: .audio)
                    return
                }
                self?.journalService.saveJournal(journalId: journalId, journalTitle: self?.journalTitle ?? "", emotionalState: recordedState) { result in
                    switch result {
                    case .success(let journal):
                        self?.completedJournal = journal
                        self?.viewState = .completed
                        self?.hapticManager.generateFeedback(.success)
                        Logger.shared.log("Saved journal", category: .audio)
                    case .failure(let error):
                        self?.errorMessage = "Failed to save journal: \(error.localizedDescription)"
                        self?.showError = true
                        self?.viewState = .error
                        self?.hapticManager.generateFeedback(.error)
                        Logger.shared.error("Failed to save journal: \(error)", category: .audio)
                    }
                }
            case .failure(let error):
                self?.errorMessage = "Failed to record post-recording emotional state: \(error.localizedDescription)"
                self?.showError = true
                self?.hapticManager.generateFeedback(.error)
                Logger.shared.error("Failed to record post-recording emotional state: \(error)", category: .emotions)
            }
        }
    }

    /// Resets the view model to its initial state
    func resetViewModel() {
        viewState = .preCheckIn
        selectedEmotionType = nil
        emotionIntensity = 5
        notes = ""
        journalTitle = ""
        audioLevel = 0.0
        recordingDuration = 0.0
        isRecording = false
        isPaused = false
        isProcessing = false
        showError = false
        errorMessage = nil
        currentJournalId = nil
        preRecordingState = nil
        Logger.shared.log("ViewModel reset", category: .audio)
    }

    /// Formats the recording duration as a string (MM:SS)
    func formatDuration() -> String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Generates a summary of the emotional shift between pre and post recording
    func getEmotionalShiftSummary() -> String? {
        guard let completedJournal = completedJournal,
              let shift = completedJournal.getEmotionalShift() else {
            return nil
        }

        let preEmotion = shift.preEmotionalState.emotionType.displayName()
        let preIntensity = shift.preEmotionalState.intensity
        let postEmotion = shift.postEmotionalState.emotionType.displayName()
        let postIntensity = shift.postEmotionalState.intensity

        return "Shift: \(preEmotion) (\(preIntensity)) -> \(postEmotion) (\(postIntensity))"
    }

    // MARK: - Private Methods

    /// Handles errors that occur during the recording process
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: The context in which the error occurred
    private func handleError(error: Error, context: String) {
        Logger.shared.error("Error in \(context): \(error.localizedDescription)", category: .audio)
        errorMessage = "An error occurred: \(error.localizedDescription)"
        showError = true
        viewState = .error
        hapticManager.generateFeedback(.error)
    }
}