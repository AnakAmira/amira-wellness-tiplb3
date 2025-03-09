# src/ios/AmiraWellness/AmiraWellness/UI/Screens/EmotionalCheckin/EmotionalCheckinResultViewModel.swift
import Foundation // standard library
import Combine // standard library
import SwiftUI // iOS SDK

// Internal imports
import EmotionalState // Core data model for emotional states
import EmotionType // Enumeration of emotion types
import EmotionCategory // Enumeration of emotion categories
import EmotionalInsight // Model for emotional insights derived from analysis
import Tool // Model for emotional regulation tools
import EmotionService // Service for analyzing emotional states and shifts
import EmotionServiceError // Error types for emotion service operations
import ToolService // Service for retrieving tool recommendations
import ToolServiceError // Error types for tool service operations
import Logger // Logging for debugging and error tracking

/// ViewModel that manages the state and business logic for the emotional check-in result screen
@MainActor
@ObservableObject
class EmotionalCheckinResultViewModel {
    
    // MARK: - Private Properties
    
    private let emotionService: EmotionService
    private let toolService: ToolService
    private let currentState: EmotionalState
    private let previousState: EmotionalState?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    @Published var recommendedTools: [Tool] = []
    @Published var emotionChanged: Bool = false
    @Published var intensityChange: Int = 0
    @Published var insights: [EmotionalInsight] = []
    @Published var isLoading: Bool = true
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Initialization
    
    /// Initializes the EmotionalCheckinResultViewModel with the current emotional state and optional previous state
    /// - Parameters:
    ///   - currentState: The current emotional state
    ///   - previousState: The previous emotional state (optional)
    ///   - emotionService: The emotion service (optional)
    ///   - toolService: The tool service (optional)
    init(currentState: EmotionalState,
         previousState: EmotionalState? = nil,
         emotionService: EmotionService? = nil,
         toolService: ToolService? = nil) {
        // Store the provided currentState
        self.currentState = currentState
        // Store the provided previousState (defaults to nil)
        self.previousState = previousState
        // Store the provided emotionService or create a new instance
        self.emotionService = emotionService ?? EmotionService()
        // Store the provided toolService or use ToolService.shared
        self.toolService = toolService ?? ToolService.shared
        // Initialize cancellables set for storing subscriptions
        self.cancellables = Set<AnyCancellable>()
        // Initialize recommendedTools to an empty array
        self.recommendedTools = []
        // Initialize emotionChanged to false
        self.emotionChanged = false
        // Initialize intensityChange to 0
        self.intensityChange = 0
        // Initialize insights to an empty array
        self.insights = []
        // Initialize isLoading to true
        self.isLoading = true
        // Initialize showError to false
        self.showError = false
        // Initialize errorMessage to empty string
        self.errorMessage = ""
        // Call loadData() to fetch recommendations and analyze emotional shift
        loadData()
    }
    
    // MARK: - Data Loading Methods
    
    /// Loads recommendations and analyzes emotional shift
    func loadData() {
        // Set isLoading to true
        isLoading = true
        
        // If previousState exists, analyze emotional shift
        if previousState != nil {
            analyzeEmotionalShift()
        }
        
        // Load recommended tools based on current emotional state
        loadRecommendedTools()
        
        // Set isLoading to false when all operations complete
        isLoading = false
    }
    
    /// Loads data using async/await
    @available(iOS 15.0, *)
    func loadDataAsync() async {
        // Set isLoading to true
        isLoading = true
        
        // Create a task group to run operations in parallel
        await withTaskGroup(of: Void.self) { group in
            // If previousState exists, analyze emotional shift using analyzeEmotionalShiftAsync
            if let previousState = previousState {
                group.addTask {
                    do {
                        _ = try await self.analyzeEmotionalShiftAsync(preState: previousState, postState: self.currentState)
                    } catch {
                        // Handle errors by setting errorMessage and showError
                        self.errorMessage = "Failed to analyze emotional shift: \(error.localizedDescription)"
                        self.showError = true
                        Logger.shared.error("Failed to analyze emotional shift: \(error.localizedDescription)", category: .emotions)
                    }
                }
            }
            
            // Load recommended tools using getRecommendedToolsAsync
            group.addTask {
                do {
                    self.recommendedTools = try await self.toolService.getRecommendedToolsAsync(emotionType: self.currentState.emotionType)
                } catch {
                    // Handle errors by setting errorMessage and showError
                    self.errorMessage = "Failed to load recommended tools: \(error.localizedDescription)"
                    self.showError = true
                    Logger.shared.error("Failed to load recommended tools: \(error.localizedDescription)", category: .database)
                }
            }
        }
        
        // Set isLoading to false when all operations complete
        isLoading = false
    }
    
    /// Analyzes the shift between previous and current emotional states
    private func analyzeEmotionalShift() {
        // Guard that previousState exists
        guard let previousState = previousState else {
            return
        }
        
        // Call emotionService.analyzeEmotionalShift with previous and current states
        emotionService.analyzeEmotionalShift(preState: previousState, postState: currentState) { result in
            switch result {
            case .success(let analysis):
                // On success, update emotionChanged, intensityChange, and insights properties
                self.emotionChanged = analysis.emotionChanged
                self.intensityChange = analysis.intensityChange
                self.insights = analysis.insights
                Logger.shared.info("Successfully analyzed emotional shift", category: .emotions)
            case .failure(let error):
                // On failure, set errorMessage and showError
                self.errorMessage = "Failed to analyze emotional shift: \(error.localizedDescription)"
                self.showError = true
                Logger.shared.error("Failed to analyze emotional shift: \(error.localizedDescription)", category: .emotions)
            }
        }
    }
    
    /// Analyzes the shift between previous and current emotional states using async/await
    @available(iOS 15.0, *)
    private func analyzeEmotionalShiftAsync(preState: EmotionalState, postState: EmotionalState) async throws -> Void {
        do {
            let analysis = try await emotionService.analyzeEmotionalShiftAsync(preState: preState, postState: currentState)
            // On success, update emotionChanged, intensityChange, and insights properties
            self.emotionChanged = analysis.emotionChanged
            self.intensityChange = analysis.intensityChange
            self.insights = analysis.insights
            Logger.shared.info("Successfully analyzed emotional shift", category: .emotions)
        } catch {
            // On failure, set errorMessage and showError
            self.errorMessage = "Failed to analyze emotional shift: \(error.localizedDescription)"
            self.showError = true
            Logger.shared.error("Failed to analyze emotional shift: \(error.localizedDescription)", category: .emotions)
        }
    }
    
    /// Loads tools recommended for the current emotional state
    private func loadRecommendedTools() {
        // Call toolService.getRecommendedTools with current emotion type
        toolService.getRecommendedTools(emotionType: currentState.emotionType) { result in
            switch result {
            case .success(let tools):
                // On success, update recommendedTools property
                self.recommendedTools = tools
                Logger.shared.info("Successfully loaded recommended tools", category: .database)
            case .failure(let error):
                // On failure, set errorMessage and showError
                self.errorMessage = "Failed to load recommended tools: \(error.localizedDescription)"
                self.showError = true
                Logger.shared.error("Failed to load recommended tools: \(error.localizedDescription)", category: .database)
            }
        }
    }
    
    // MARK: - UI Helper Methods
    
    /// Returns the localized display name of an emotion type
    func getEmotionDisplayName(emotionType: EmotionType? = nil) -> String {
        // If emotionType is nil, return current state's emotion display name
        // Otherwise, return the provided emotion type's display name
        return (emotionType ?? currentState.emotionType).displayName()
    }
    
    /// Returns the system icon name for an emotion type
    func getEmotionIconName(emotionType: EmotionType? = nil) -> String {
        // If emotionType is nil, use current state's emotion type
        // Map emotion type to appropriate system icon name
        // Return the icon name
        return "face.smiling" // Placeholder
    }
    
    /// Returns the category name for an emotion type
    func getEmotionCategoryName(emotionType: EmotionType? = nil) -> String {
        // If emotionType is nil, use current state's emotion type
        // Get the category of the emotion type
        // Return the category's display name
        return (emotionType ?? currentState.emotionType).category().displayName()
    }
    
    /// Returns a description of the emotional intensity
    func getIntensityDescription(intensityValue: Int? = nil) -> String {
        // If intensityValue is nil, use current state's intensity
        let intensity = intensityValue ?? currentState.intensity
        // Map intensity value to appropriate description (low, moderate, high)
        switch intensity {
        case 1...3:
            return NSLocalizedString("Baja", comment: "Low intensity")
        case 4...7:
            return NSLocalizedString("Moderada", comment: "Moderate intensity")
        case 8...10:
            return NSLocalizedString("Alta", comment: "High intensity")
        default:
            return NSLocalizedString("Desconocida", comment: "Unknown intensity")
        }
    }
    
    /// Returns a description of the emotional shift
    func getEmotionalShiftDescription() -> String {
        // Check if there was an emotion type change or intensity change
        // Generate appropriate description based on the changes
        // Return the localized description
        if emotionChanged {
            return NSLocalizedString("Tu emoción ha cambiado.", comment: "Emotion changed description")
        } else if intensityChange > 0 {
            return NSLocalizedString("Tu intensidad emocional ha aumentado.", comment: "Intensity increased description")
        } else if intensityChange < 0 {
            return NSLocalizedString("Tu intensidad emocional ha disminuido.", comment: "Intensity decreased description")
        } else {
            return NSLocalizedString("No hubo cambios significativos en tu estado emocional.", comment: "No significant changes description")
        }
    }
    
    // MARK: - Action Handling Methods
    
    /// Handles the selection of a recommended tool
    /// - Parameter toolId: The ID of the selected tool
    func selectTool(toolId: String) {
        // Log the selected tool ID
        Logger.shared.logUserAction("Selected tool with ID: \(toolId)")
        
        // Find the tool in recommendedTools by ID
        if let tool = recommendedTools.first(where: { $0.id.uuidString == toolId }) {
            // If found, perform any necessary actions before navigation
            Logger.shared.logUserAction("Navigating to tool: \(tool.name)")
        }
    }
    
    /// Handles dismissal of the result screen
    func dismissResult() {
        // Log the dismissal action
        Logger.shared.logUserAction("Dismissed emotional check-in result screen")
        
        // Perform any necessary cleanup
        
    }
    
    /// Dismisses the error message
    func dismissError() {
        // Set showError to false
        showError = false
        // Set errorMessage to empty string
        errorMessage = ""
    }
}