import Foundation // standard library
import Combine // Reactive programming for asynchronous operations
import SwiftUI // Access to UI state objects and bindings

// Internal imports
import EmotionalState // Core data model for emotional states
import EmotionType // Enumeration of emotion types
import CheckInContext // Contexts in which emotional check-ins occur
import EmotionService // Service for recording and managing emotional states
import EmotionServiceError // Error types for emotion service operations
import Logger // Logging for debugging and error tracking

/// ViewModel that manages the state and business logic for the emotional check-in screen
@MainActor
@ObservableObject
class EmotionalCheckinViewModel {
    
    // MARK: - Private Properties
    
    /// Emotion service for recording emotional states
    private let emotionService: EmotionService
    
    /// Context in which the check-in is performed
    private let context: CheckInContext
    
    /// Optional ID of the related journal entry
    private let relatedJournalId: UUID?
    
    /// Optional ID of the related tool
    private let relatedToolId: UUID?
    
    /// Set to store Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    /// Currently selected emotion type
    @Published var selectedEmotion: EmotionType = .joy
    
    /// Intensity value for the selected emotion (1-10)
    @Published var intensity: Int = 5
    
    /// Optional notes about the emotional state
    @Published var notes: String = ""
    
    /// Indicates if the view is loading data
    @Published var isLoading: Bool = false
    
    /// Indicates if an error occurred
    @Published var showError: Bool = false
    
    /// Error message to display
    @Published var errorMessage: String = ""
    
    /// Indicates if navigation to the result screen should occur
    @Published var navigateToResult: Bool = false
    
    /// The recorded emotional state
    @Published var recordedState: EmotionalState? = nil
    
    // MARK: - Initialization
    
    /// Initializes the EmotionalCheckinViewModel with dependencies and context
    /// - Parameters:
    ///   - emotionService: Emotion service for recording emotional states
    ///   - context: Context in which the check-in is performed (defaults to .standalone)
    ///   - relatedJournalId: Optional ID of the related journal entry (defaults to nil)
    ///   - relatedToolId: Optional ID of the related tool (defaults to nil)
    init(emotionService: EmotionService, context: CheckInContext = .standalone, relatedJournalId: UUID? = nil, relatedToolId: UUID? = nil) {
        // Store the provided emotionService
        self.emotionService = emotionService
        
        // Store the provided context (defaults to .standalone)
        self.context = context
        
        // Store the provided relatedJournalId (defaults to nil)
        self.relatedJournalId = relatedJournalId
        
        // Store the provided relatedToolId (defaults to nil)
        self.relatedToolId = relatedToolId
        
        // Initialize cancellables set for storing subscriptions
        self.cancellables = []
        
        // Initialize selectedEmotion to EmotionType.joy
        self.selectedEmotion = .joy
        
        // Initialize intensity to 5 (middle value)
        self.intensity = 5
        
        // Initialize notes to empty string
        self.notes = ""
        
        // Initialize isLoading to false
        self.isLoading = false
        
        // Initialize showError to false
        self.showError = false
        
        // Initialize errorMessage to empty string
        self.errorMessage = ""
        
        // Initialize navigateToResult to false
        self.navigateToResult = false
        
        // Initialize recordedState to nil
        self.recordedState = nil
    }
    
    // MARK: - Public Methods
    
    /// Updates the selected emotion type
    /// - Parameter emotion: The new emotion type
    func selectEmotion(emotion: EmotionType) {
        // Set selectedEmotion to the provided emotion
        self.selectedEmotion = emotion
        
        // Log the selected emotion
        Logger.shared.log("Selected emotion: \(emotion)", category: .userInterface)
    }
    
    /// Updates the intensity value
    /// - Parameter value: The new intensity value
    func updateIntensity(value: Int) {
        // Validate that value is between 1 and 10
        guard value >= 1 && value <= 10 else {
            return
        }
        
        // Set intensity to the provided value
        self.intensity = value
        
        // Log the updated intensity
        Logger.shared.log("Updated intensity: \(value)", category: .userInterface)
    }
    
    /// Updates the optional notes
    /// - Parameter text: The new notes text
    func updateNotes(text: String) {
        // Set notes to the provided text
        self.notes = text
        
        // Log the updated notes
        Logger.shared.log("Updated notes: \(text)", category: .userInterface)
    }
    
    /// Records the emotional state and navigates to the result screen
    func submitEmotionalState() {
        // Set isLoading to true
        self.isLoading = true
        
        // Create a new EmotionalState with the current values
        let emotionalState = EmotionalState(
            emotionType: selectedEmotion,
            intensity: intensity,
            context: context,
            notes: notes,
            relatedJournalId: relatedJournalId,
            relatedToolId: relatedToolId
        )
        
        // Call emotionService.recordEmotionalState with the created state
        emotionService.recordEmotionalState(emotionType: selectedEmotion, intensity: intensity, context: context, notes: notes, relatedJournalId: relatedJournalId, relatedToolId: relatedToolId) { [weak self] result in
            guard let self = self else { return }
            
            // Set isLoading to false when complete
            defer {
                Task { @MainActor in
                    self.isLoading = false
                }
            }
            
            switch result {
            case .success(let recordedState):
                // On success, store the recorded state in recordedState
                Task { @MainActor in
                    self.recordedState = recordedState
                    
                    // Set navigateToResult to true to trigger navigation
                    self.navigateToResult = true
                }
                
                // Log the submission result
                Logger.shared.log("Successfully submitted emotional state", category: .userInterface)
                
            case .failure(let error):
                // On failure, set errorMessage and showError
                Task { @MainActor in
                    self.errorMessage = "Failed to record emotional state: \(error)"
                    self.showError = true
                }
                
                // Log the submission result
                Logger.shared.error("Failed to submit emotional state: \(error)", category: .userInterface)
            }
        }
    }
    
    /// Records the emotional state using async/await
    @available(iOS 15.0, *)
    func submitEmotionalStateAsync() async throws -> EmotionalState {
        // Set isLoading to true
        self.isLoading = true
        
        // Create a new EmotionalState with the current values
        let emotionalState = EmotionalState(
            emotionType: selectedEmotion,
            intensity: intensity,
            context: context,
            notes: notes,
            relatedJournalId: relatedJournalId,
            relatedToolId: relatedToolId
        )
        
        // Call emotionService.recordEmotionalStateAsync with the created state
        do {
            let recordedState = try await emotionService.recordEmotionalStateAsync(emotionType: selectedEmotion, intensity: intensity, context: context, notes: notes, relatedJournalId: relatedJournalId, relatedToolId: relatedToolId)
            
            // Store the result in recordedState
            self.recordedState = recordedState
            
            // Set isLoading to false
            self.isLoading = false
            
            // Log the submission result
            Logger.shared.log("Successfully submitted emotional state", category: .userInterface)
            
            // Return the recorded state
            return recordedState
        } catch {
            // Handle errors by setting errorMessage and showError
            self.errorMessage = "Failed to record emotional state: \(error)"
            self.showError = true
            
            // Set isLoading to false
            self.isLoading = false
            
            // Log the submission result
            Logger.shared.error("Failed to submit emotional state: \(error)", category: .userInterface)
            
            throw error
        }
    }
    
    /// Dismisses the error message
    func dismissError() {
        // Set showError to false
        self.showError = false
        
        // Set errorMessage to empty string
        self.errorMessage = ""
    }
    
    /// Resets the view model state to default values
    func resetState() {
        // Set selectedEmotion to EmotionType.joy
        self.selectedEmotion = .joy
        
        // Set intensity to 5
        self.intensity = 5
        
        // Set notes to empty string
        self.notes = ""
        
        // Set isLoading to false
        self.isLoading = false
        
        // Set showError to false
        self.showError = false
        
        // Set errorMessage to empty string
        self.errorMessage = ""
        
        // Set navigateToResult to false
        self.navigateToResult = false
        
        // Set recordedState to nil
        self.recordedState = nil
    }
    
    /// Validates that the current emotional state is valid
    /// - Returns: True if the state is valid, false otherwise
    func validateEmotionalState() -> Bool {
        // Check that intensity is between 1 and 10
        guard intensity >= 1 && intensity <= 10 else {
            return false
        }
        
        // Return true if valid, false otherwise
        return true
    }
}