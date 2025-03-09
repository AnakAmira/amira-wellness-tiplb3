# src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolInProgressViewModel.swift
import Foundation // Version: standard library
import Combine // Version: standard library
import SwiftUI // Version: iOS SDK

// Internal imports
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolStep // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolContentType // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import EmotionalState // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import ToolServiceError // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import EmotionService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionService.swift
import AudioPlaybackService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/AudioPlaybackService.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import Haptics // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Haptics.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// A view model that manages the state and business logic for the tool in progress screen
@MainActor
@ObservableObject
class ToolInProgressViewModel {
    
    // MARK: - Published Properties
    
    /// The tool being used
    @Published var tool: Tool
    /// Indicates if the tool is currently loading
    @Published var isLoading: Bool = true
    /// Indicates if the tool is currently paused
    @Published var isPaused: Bool = false
    /// Indicates if the tool is completed
    @Published var isCompleted: Bool = false
    /// Indicates if an error occurred
    @Published var showError: Bool = false
    /// The error message to display
    @Published var errorMessage: String = ""
    /// The index of the current step in a guided exercise
    @Published var currentStepIndex: Int = 0
    /// The current step in a guided exercise
    @Published var currentStep: ToolStep? = nil
    /// The progress of the tool execution (0.0 to 1.0)
    @Published var progress: Double = 0.0
    /// The remaining seconds for the current step or tool
    @Published var remainingSeconds: Int = 0
    /// The formatted time remaining in MM:SS format
    @Published var formattedTimeRemaining: String = "00:00"
    /// Indicates if the view should navigate to the completion screen
    @Published var navigateToCompletion: Bool = false
    /// Indicates if the confirmation dialog for exiting the tool should be shown
    @Published var showConfirmExit: Bool = false
    
    // MARK: - Private Properties
    
    /// The steps for a guided exercise tool
    private var steps: [ToolStep]? = nil
    /// Timer for tracking tool execution progress
    private var timer: Timer? = nil
    /// The start time of the tool execution
    private var startTime: Date = Date()
    /// The total duration of the tool in seconds
    private var totalDuration: Int = 0
    /// The elapsed time in seconds
    private var elapsedTime: Int = 0
    /// Indicates if audio is currently playing
    private var isAudioPlaying: Bool = false
    /// The emotional state before starting the tool
    private var preToolEmotionalState: EmotionalState? = nil
    
    // MARK: - Services
    
    /// Service for tracking tool usage
    private var toolService: ToolService = ToolService.shared
    /// Service for recording pre-tool emotional state
    private var emotionService: EmotionService? = nil
    /// Service for audio playback
    private var audioService: AudioPlaybackService = AudioPlaybackService.shared
    /// Service for accessing stored media files
    private var storageService: StorageService = StorageService.shared
    /// Service for haptic feedback
    private var haptics: Haptics = Haptics.shared
    /// Service for logging
    private var logger: Logger = Logger.shared
    
    /// Set to hold Combine cancellables
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    
    /// Initializes the ToolInProgressViewModel with dependencies
    /// - Parameters:
    ///   - tool: The tool to be executed
    ///   - preToolEmotionalState: The emotional state before starting the tool
    ///   - toolService: The service for tracking tool usage (optional, defaults to shared instance)
    ///   - emotionService: The service for recording pre-tool emotional state (optional)
    ///   - audioService: The service for audio playback (optional, defaults to shared instance)
    ///   - storageService: The service for accessing stored media files (optional, defaults to shared instance)
    ///   - haptics: The service for haptic feedback (optional, defaults to shared instance)
    ///   - logger: The service for logging (optional, defaults to shared instance)
    init(tool: Tool,
         preToolEmotionalState: EmotionalState? = nil,
         toolService: ToolService? = nil,
         emotionService: EmotionService? = nil,
         audioService: AudioPlaybackService? = nil,
         storageService: StorageService? = nil,
         haptics: Haptics? = nil,
         logger: Logger? = nil) {
        
        // Store the provided tool
        self.tool = tool
        
        // Store the provided preToolEmotionalState if available
        self.preToolEmotionalState = preToolEmotionalState
        
        // Initialize isLoading to true
        self.isLoading = true
        
        // Initialize isPaused to false
        self.isPaused = false
        
        // Initialize isCompleted to false
        self.isCompleted = false
        
        // Initialize showError to false
        self.showError = false
        
        // Initialize errorMessage with empty string
        self.errorMessage = ""
        
        // Initialize currentStepIndex to 0
        self.currentStepIndex = 0
        
        // Initialize progress to 0.0
        self.progress = 0.0
        
        // Initialize remainingSeconds to 0
        self.remainingSeconds = 0
        
        // Initialize formattedTimeRemaining to "00:00"
        self.formattedTimeRemaining = "00:00"
        
        // Initialize navigateToCompletion to false
        self.navigateToCompletion = false
        
        // Initialize showConfirmExit to false
        self.showConfirmExit = false
        
        // Initialize steps from tool.content.steps if available
        self.steps = tool.content.steps
        
        // Initialize startTime to current date
        self.startTime = Date()
        
        // Calculate totalDuration based on tool type and steps
        self.totalDuration = steps?.reduce(0) { $0 + $1.durationSeconds } ?? tool.estimatedDuration * 60
        
        // Initialize elapsedTime to 0
        self.elapsedTime = 0
        
        // Initialize isAudioPlaying to false
        self.isAudioPlaying = false
        
        // Store the provided toolService or use ToolService.shared
        self.toolService = toolService ?? ToolService.shared
        
        // Store the provided emotionService if available
        self.emotionService = emotionService
        
        // Store the provided audioService or use AudioPlaybackService.shared
        self.audioService = audioService ?? AudioPlaybackService.shared
        
        // Store the provided storageService or use StorageService.shared
        self.storageService = storageService ?? StorageService.shared
        
        // Store the provided haptics or use Haptics.shared
        self.haptics = haptics ?? Haptics.shared
        
        // Store the provided logger or use Logger.shared
        self.logger = logger ?? Logger.shared
        
        // Initialize cancellables as an empty Set
        self.cancellables = []
        
        // Log the tool start with tool name
        self.logger.log( "Tool started: \(tool.name)", category: .userInterface)
    }
    
    // MARK: - Tool Execution Control
    
    /// Starts the tool execution and timer
    func startTool() {
        // Set isLoading to false
        isLoading = false
        
        // Set startTime to current date
        startTime = Date()
        
        // If tool has steps, set currentStep to first step
        if let steps = steps, !steps.isEmpty {
            currentStep = steps.first
        }
        
        // If tool has audio content, prepare audio playback
        if tool.hasMediaContent(), let mediaUrl = tool.content.mediaUrl {
            prepareAudio(mediaUrl: mediaUrl)
        }
        
        // Start the timer based on tool type
        startTimer()
        
        // If audio content exists, start audio playback
        if isAudioPlaying {
            _ = audioService.startPlayback()
        }
        
        // Provide haptic feedback
        haptics.play(.medium)
        
        // Log the tool start action
        logger.log("Tool execution started", category: .userInterface)
    }
    
    /// Pauses the tool execution and timer
    func pauseTool() {
        // Set isPaused to true
        isPaused = true
        
        // Invalidate the timer
        timer?.invalidate()
        
        // If audio is playing, pause audio playback
        if isAudioPlaying {
            _ = audioService.pausePlayback()
        }
        
        // Provide haptic feedback
        haptics.play(.light)
        
        // Log the tool pause action
        logger.log("Tool execution paused", category: .userInterface)
    }
    
    /// Resumes the tool execution and timer
    func resumeTool() {
        // Set isPaused to false
        isPaused = false
        
        // Restart the timer
        startTimer()
        
        // If audio was playing, resume audio playback
        if isAudioPlaying {
            _ = audioService.resumePlayback()
        }
        
        // Provide haptic feedback
        haptics.play(.light)
        
        // Log the tool resume action
        logger.log("Tool execution resumed", category: .userInterface)
    }
    
    /// Stops the tool execution and navigates to completion
    func stopTool() {
        // Invalidate the timer
        timer?.invalidate()
        
        // Stop any audio playback
        _ = audioService.stopPlayback()
        
        // Calculate total elapsed time
        let elapsedTimeInterval = Date().timeIntervalSince(startTime)
        elapsedTime = Int(elapsedTimeInterval)
        
        // Track tool usage with toolService
        trackToolUsage()
        
        // Set isCompleted to true
        isCompleted = true
        
        // Set navigateToCompletion to true
        navigateToCompletion = true
        
        // Provide haptic feedback
        haptics.play(.success)
        
        // Log the tool completion with duration
        logger.log("Tool execution completed in \(elapsedTime) seconds", category: .userInterface)
    }
    
    /// Restarts the tool from the beginning
    func restartTool() {
        // Invalidate the timer
        timer?.invalidate()
        
        // Stop any audio playback
        _ = audioService.stopPlayback()
        
        // Reset currentStepIndex to 0
        currentStepIndex = 0
        
        // Reset progress to 0.0
        progress = 0.0
        
        // Reset elapsedTime to 0
        elapsedTime = 0
        
        // Set startTime to current date
        startTime = Date()
        
        // If tool has steps, set currentStep to first step
        if let steps = steps, !steps.isEmpty {
            currentStep = steps.first
        }
        
        // Start the timer based on tool type
        startTimer()
        
        // If audio content exists, restart audio playback
        if isAudioPlaying {
            _ = audioService.startPlayback()
        }
        
        // Set isPaused to false
        isPaused = false
        
        // Provide haptic feedback
        haptics.play(.medium)
        
        // Log the tool restart action
        logger.log("Tool execution restarted", category: .userInterface)
    }
    
    // MARK: - Step Navigation
    
    /// Advances to the next step in a guided exercise
    func nextStep() {
        // Check if steps exist and there is a next step available
        guard let steps = steps, currentStepIndex < steps.count - 1 else {
            return
        }
        
        // Increment currentStepIndex
        currentStepIndex += 1
        
        // Update currentStep to the new step
        currentStep = steps[currentStepIndex]
        
        // Reset step-specific timer
        elapsedTime = 0
        
        // If step has audio content, prepare and play it
        if let mediaUrl = currentStep?.mediaUrl {
            prepareAudio(mediaUrl: mediaUrl)
        }
        
        // Provide haptic feedback
        haptics.play(.light)
        
        // Log the step transition
        logger.log("Moved to next step: \(currentStep?.title ?? "Unknown")", category: .userInterface)
    }
    
    /// Returns to the previous step in a guided exercise
    func previousStep() {
        // Check if steps exist and there is a previous step available
        guard let steps = steps, currentStepIndex > 0 else {
            return
        }
        
        // Decrement currentStepIndex
        currentStepIndex -= 1
        
        // Update currentStep to the new step
        currentStep = steps[currentStepIndex]
        
        // Reset step-specific timer
        elapsedTime = 0
        
        // If step has audio content, prepare and play it
        if let mediaUrl = currentStep?.mediaUrl {
            prepareAudio(mediaUrl: mediaUrl)
        }
        
        // Provide haptic feedback
        haptics.play(.light)
        
        // Log the step transition
        logger.log("Moved to previous step: \(currentStep?.title ?? "Unknown")", category: .userInterface)
    }
    
    // MARK: - Timer Management
    
    /// Starts the timer based on tool type
    private func startTimer() {
        // Determine timer type based on tool.contentType
        switch tool.contentType {
        case .guidedExercise:
            // For guided exercises, create step-based timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateProgress()
            }
        default:
            // For other types, create overall duration timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateProgress()
            }
        }
        
        // Log the timer start
        logger.log("Timer started", category: .userInterface)
    }
    
    /// Updates the progress and time remaining based on timer ticks
    private func updateProgress() {
        // Increment elapsedTime by 1 second
        elapsedTime += 1
        
        // If using step-based timer, calculate progress within current step
        if tool.contentType == .guidedExercise, let currentStep = currentStep {
            progress = Double(elapsedTime) / Double(currentStep.durationSeconds)
            remainingSeconds = currentStep.durationSeconds - elapsedTime
        } else {
            // If using overall timer, calculate progress across total duration
            progress = Double(elapsedTime) / Double(totalDuration)
            remainingSeconds = totalDuration - elapsedTime
        }
        
        // Update remainingSeconds based on timer type
        
        // Format remainingSeconds into formattedTimeRemaining (MM:SS)
        formattedTimeRemaining = formatTimeRemaining(seconds: remainingSeconds)
        
        // Check if current step or overall tool is complete
        if tool.contentType == .guidedExercise, let currentStep = currentStep, elapsedTime >= currentStep.durationSeconds {
            // If step complete, advance to next step or complete tool
            nextStep()
        } else if elapsedTime >= totalDuration {
            // If tool complete, call stopTool()
            stopTool()
        }
    }
    
    // MARK: - Audio Playback
    
    /// Prepares audio content for playback
    /// - Parameter mediaUrl: The URL of the audio file
    private func prepareAudio(mediaUrl: String) {
        // Retrieve the file URL from storageService
        _ = storageService.retrieveFileURL(fileName: mediaUrl, dataType: .audio, sensitivity: .sensitive)
        
        // Prepare the audio for playback using audioService
        _ = audioService.prepareForPlayback(fileURL: URL(string: mediaUrl)!, encryptionIv: "", journalId: UUID())
        
        // Set isAudioPlaying to true
        isAudioPlaying = true
        
        // Log the audio preparation
        logger.log("Audio prepared for playback", category: .audio)
    }
    
    // MARK: - Data Tracking
    
    /// Tracks the tool usage with the tool service
    private func trackToolUsage() {
        // Call toolService.trackToolUsage with tool and duration
        toolService.trackToolUsage(tool: tool, durationSeconds: elapsedTime) { result in
            switch result {
            case .success:
                // On success, log the successful tracking
                self.logger.log("Tool usage tracked successfully", category: .userInterface)
            case .failure(let error):
                // On failure, set errorMessage and showError to true
                self.errorMessage = "Failed to track tool usage: \(error)"
                self.showError = true
                
                // Log any errors that occur
                self.logger.error("Failed to track tool usage: \(error)", category: .userInterface)
            }
        }
    }
    
    // MARK: - Time Formatting
    
    /// Formats seconds into MM:SS format
    /// - Parameter seconds: The number of seconds to format
    /// - Returns: Formatted time string
    private func formatTimeRemaining(seconds: Int) -> String {
        // Calculate minutes and remaining seconds
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        // Format as MM:SS with leading zeros
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Exit Confirmation
    
    /// Shows confirmation dialog for exiting the tool
    func confirmExit() {
        // Pause the tool execution
        pauseTool()
        
        // Set showConfirmExit to true
        showConfirmExit = true
        
        // Log the exit confirmation request
        logger.log("Exit confirmation requested", category: .userInterface)
    }
    
    /// Cancels the exit confirmation and resumes the tool
    func cancelExit() {
        // Set showConfirmExit to false
        showConfirmExit = false
        
        // Resume the tool execution
        resumeTool()
        
        // Log the exit cancellation
        logger.log("Exit confirmation cancelled", category: .userInterface)
    }
    
    /// Confirms exit and stops the tool without completion
    func confirmExitAndStop() {
        // Set showConfirmExit to false
        showConfirmExit = false
        
        // Invalidate the timer
        timer?.invalidate()
        
        // Stop any audio playback
        _ = audioService.stopPlayback()
        
        // Calculate partial elapsed time
        let elapsedTimeInterval = Date().timeIntervalSince(startTime)
        elapsedTime = Int(elapsedTimeInterval)
        
        // Track partial tool usage with toolService
        toolService.trackToolUsage(tool: tool, durationSeconds: elapsedTime) { result in
            switch result {
            case .success:
                // On success, log the successful tracking
                self.logger.log("Partial tool usage tracked successfully", category: .userInterface)
            case .failure(let error):
                // On failure, set errorMessage and showError to true
                self.errorMessage = "Failed to track partial tool usage: \(error)"
                self.showError = true
                
                // Log any errors that occur
                self.logger.error("Failed to track partial tool usage: \(error)", category: .userInterface)
            }
        }
        
        // Set navigateToCompletion to true with partial completion flag
        navigateToCompletion = true
        
        // Log the early exit with partial duration
        logger.log("Tool execution exited early after \(elapsedTime) seconds", category: .userInterface)
    }
    
    // MARK: - Error Handling
    
    /// Dismisses the error message
    func dismissError() {
        // Set showError to false
        showError = false
        
        // Set errorMessage to empty string
        errorMessage = ""
    }
    
    // MARK: - Lifecycle
    
    /// Cleanup when the view disappears
    func onDisappear() {
        // Invalidate the timer
        timer?.invalidate()
        
        // Stop any audio playback
        _ = audioService.stopPlayback()
        
        // Cancel any pending operations
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Log the view disappearance
        logger.log("Tool in progress view disappeared", category: .userInterface)
    }
}