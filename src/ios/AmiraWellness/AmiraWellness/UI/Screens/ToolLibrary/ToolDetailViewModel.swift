# src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolDetailViewModel.swift
import Foundation // Version: standard library
import Combine // Version: standard library
import SwiftUI // Version: iOS SDK

// Internal imports
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import ToolServiceError // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import AudioPlaybackService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/AudioPlaybackService.swift
import Haptics // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Haptics.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift

/// A view model that manages the state and business logic for the tool detail screen
@MainActor
@ObservableObject
class ToolDetailViewModel {
    /// The tool being displayed
    @Published var tool: Tool?
    /// Indicates if the tool details are currently loading
    @Published var isLoading: Bool = false
    /// Indicates if an error occurred while loading the tool details
    @Published var showError: Bool = false
    /// The error message to display if an error occurred
    @Published var errorMessage: String = ""
    /// Indicates if the audio preview is currently playing
    @Published var isPlaying: Bool = false
    /// Indicates if the user should navigate to the tool in progress screen
    @Published var navigateToToolInProgress: Bool = false
    /// Indicates if a confirmation dialog should be shown
    @Published var showConfirmation: Bool = false
    /// The message to display in the confirmation dialog
    @Published var confirmationMessage: String = ""

    /// Tool service for data operations
    private let toolService: ToolService
    /// Audio playback service for playing audio previews
    private let audioService: AudioPlaybackService
    /// Storage service for retrieving media files
    private let storageService: StorageService
    /// Haptics for providing user feedback
    private let haptics: Haptics
    /// Logger for debugging and error tracking
    private let logger: Logger

    /// Set of Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    /// The ID of the tool being displayed
    private var toolId: String

    /// Initializes the ToolDetailViewModel with dependencies
    /// - Parameters:
    ///   - toolId: The ID of the tool to display
    ///   - toolService: Tool service for data operations (optional, defaults to shared instance)
    ///   - audioService: Audio playback service for playing audio previews (optional, defaults to shared instance)
    ///   - storageService: Storage service for retrieving media files (optional, defaults to shared instance)
    ///   - haptics: Haptics for providing user feedback (optional, defaults to shared instance)
    ///   - logger: Logger for debugging and error tracking (optional, defaults to shared instance)
    init(
        toolId: String,
        toolService: ToolService? = nil,
        audioService: AudioPlaybackService? = nil,
        storageService: StorageService? = nil,
        haptics: Haptics? = nil,
        logger: Logger? = nil
    ) {
        // Store the provided toolId
        self.toolId = toolId
        // Initialize isLoading to true
        self.isLoading = true
        // Initialize showError to false
        self.showError = false
        // Initialize errorMessage with empty string
        self.errorMessage = ""
        // Initialize isPlaying to false
        self.isPlaying = false
        // Initialize navigateToToolInProgress to false
        self.navigateToToolInProgress = false
        // Initialize showConfirmation to false
        self.showConfirmation = false
        // Initialize confirmationMessage with empty string
        self.confirmationMessage = ""
        // Store the provided toolService or use ToolService.shared
        self.toolService = toolService ?? ToolService.shared
        // Store the provided audioService or use AudioPlaybackService.shared
        self.audioService = audioService ?? AudioPlaybackService.shared
        // Store the provided storageService or use StorageService.shared
        self.storageService = storageService ?? StorageService.shared
        // Store the provided haptics or use Haptics.shared
        self.haptics = haptics ?? Haptics.shared
        // Store the provided logger or use Logger.shared
        self.logger = logger ?? Logger.shared
        // Initialize cancellables as an empty Set
        self.cancellables = Set<AnyCancellable>()
    }

    /// Loads the tool details from the service
    func loadTool() {
        // Set isLoading to true
        isLoading = true

        // Call toolService.getTool with toolId
        toolService.getTool(id: toolId) { [weak self] result in
            guard let self = self else { return }
            // On success, set tool property and isLoading to false
            switch result {
            case .success(let tool):
                self.tool = tool
                self.isLoading = false
            // On failure, set errorMessage, showError to true, and isLoading to false
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
            // Log the result of the operation
            self.logger.log(self.tool != nil ? "Tool loaded successfully" : "Tool load failed", category: .userInterface)
        }
    }

    /// Toggles the favorite status of the tool
    func toggleFavorite() {
        // Check if tool exists
        guard let tool = tool else {
            logger.error("Cannot toggle favorite: Tool is nil", category: .userInterface)
            return
        }

        // Call toolService.toggleFavorite with the current tool
        toolService.toggleFavorite(tool: tool) { [weak self] result in
            guard let self = self else { return }
            // On success, update the tool property with the returned tool
            switch result {
            case .success(let updatedTool):
                self.tool = updatedTool
            // On failure, set errorMessage and showError to true
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            // Provide haptic feedback on success
            if self.tool != nil {
                self.haptics.generateFeedback(.light)
            }
            // Log the result of the operation
            self.logger.log(self.tool?.isFavorite == true ? "Tool favorited" : "Tool unfavorited", category: .userInterface)
        }
    }

    /// Initiates the tool usage flow
    func startTool() {
        // Check if tool exists
        guard let tool = tool else {
            logger.error("Cannot start tool: Tool is nil", category: .userInterface)
            return
        }

        // Stop any playing audio preview
        if isPlaying {
            let _ = stopPreview()
        }

        // Set navigateToToolInProgress to true
        navigateToToolInProgress = true

        // Provide haptic feedback
        haptics.generateFeedback(.medium)

        // Log the tool start action
        logger.logUserAction("Started tool: \(tool.name)")
    }

    /// Plays a preview of the tool's audio content
    func playPreview() {
        // Check if tool exists and has media content
        guard let tool = tool, tool.hasMediaContent() else {
            logger.error("Cannot play preview: Tool is nil or has no media content", category: .userInterface)
            return
        }

        // If already playing, call stopPreview()
        if isPlaying {
            let _ = stopPreview()
            return
        }

        // Retrieve the media URL from storageService
        guard let mediaUrl = tool.content.mediaUrl else {
            logger.error("Cannot play preview: Media URL is nil", category: .userInterface)
            return
        }

        // Prepare the audio for playback using audioService
        if let audioURLResult = storageService.retrieveFileURL(fileName: mediaUrl, dataType: .audio, sensitivity: .sensitive).success {
            let _ = audioService.prepareForPlayback(fileURL: audioURLResult, encryptionIv: "test", journalId: UUID())
        }

        // Start audio playback
        let _ = audioService.startPlayback()

        // Set isPlaying to true
        isPlaying = true

        // Provide haptic feedback
        haptics.generateFeedback(.light)

        // Log the preview start action
        logger.logUserAction("Started audio preview for tool: \(tool.name)")
    }

    /// Stops the audio preview playback
    func stopPreview() {
        // Check if isPlaying is true
        guard isPlaying else {
            logger.warning("Cannot stop preview: Audio is not playing", category: .userInterface)
            return
        }

        // Stop audio playback using audioService
        let _ = audioService.stopPlayback()

        // Set isPlaying to false
        isPlaying = false

        // Provide haptic feedback
        haptics.generateFeedback(.light)

        // Log the preview stop action
        logger.logUserAction("Stopped audio preview")
    }

    /// Prepares to share a link to the tool
    func shareToolLink() {
        // Check if tool exists
        guard let tool = tool else {
            logger.error("Cannot share tool: Tool is nil", category: .userInterface)
            return
        }

        // Set confirmationMessage to sharing confirmation text
        confirmationMessage = "Compartir enlace a \(tool.name)"

        // Set showConfirmation to true
        showConfirmation = true

        // Log the share action
        logger.logUserAction("Sharing tool: \(tool.name)")
    }

    /// Dismisses the error message
    func dismissError() {
        // Set showError to false
        showError = false

        // Set errorMessage to empty string
        errorMessage = ""
    }

    /// Confirms the pending action (like sharing)
    func confirmAction() {
        // Check if tool exists
        guard let tool = tool else {
            logger.error("Cannot confirm action: Tool is nil", category: .userInterface)
            return
        }

        // Generate a shareable link for the tool
        let shareableLink = "https://amirawellness.com/tools/\(tool.id)"

        // Prepare the share activity
        let activityViewController = UIActivityViewController(activityItems: [shareableLink], applicationActivities: nil)

        // Present the share activity
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)

        // Set showConfirmation to false
        showConfirmation = false

        // Log the confirmed action
        logger.logUserAction("Confirmed sharing tool: \(tool.name)")
    }

    /// Dismisses the confirmation dialog
    func dismissConfirmation() {
        // Set showConfirmation to false
        showConfirmation = false

        // Set confirmationMessage to empty string
        confirmationMessage = ""
    }

    /// Cleanup when the view disappears
    func onDisappear() {
        // Stop any playing audio preview
        if isPlaying {
            let _ = stopPreview()
        }

        // Cancel any pending operations
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Log the view disappearance
        logger.logUserAction("Tool detail view disappeared")
    }
}