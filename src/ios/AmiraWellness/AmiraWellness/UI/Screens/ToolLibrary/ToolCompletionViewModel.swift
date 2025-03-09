import Foundation // Version: standard library
import Combine // Version: standard library
import SwiftUI // Version: standard library

// Internal imports
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import EmotionalState // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import CheckInContext // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import EmotionService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// View model that manages the state and business logic for the tool completion screen
@MainActor
@ObservableObject
class ToolCompletionViewModel {
    
    /// Indicates whether to show the emotional check-in screen
    @Published var showEmotionalCheckIn: Bool = false
    
    /// Indicates whether to show the tool recommendations screen
    @Published var showRecommendations: Bool = false
    
    /// Indicates whether the view model is currently loading data
    @Published var isLoading: Bool = false
    
    /// Indicates whether an error occurred
    @Published var showError: Bool = false
    
    /// The error message to display
    @Published var errorMessage: String? = nil
    
    /// Indicates whether the emotional shift has been analyzed
    @Published var emotionalShiftAnalyzed: Bool = false
    
    /// Indicates whether the emotion has changed after tool usage
    @Published var emotionChanged: Bool = false
    
    /// The change in intensity after tool usage
    @Published var intensityChange: Int = 0
    
    /// The emotional insights generated after tool usage
    @Published var emotionalInsights: [String] = []
    
    /// The recommended tools based on the user's emotional state
    @Published var recommendedTools: [Tool] = []
    
    /// Indicates whether to navigate to the home screen
    @Published var navigateToHome: Bool = false
    
    /// Indicates whether to navigate to a specific tool
    @Published var navigateToTool: Bool = false
    
    /// The selected tool to navigate to
    @Published var selectedTool: Tool? = nil
    
    /// The tool that was completed
    private let completedTool: Tool
    
    /// The duration of the tool usage in seconds
    private let usageDuration: Int
    
    /// The emotional state before using the tool (optional)
    private let preToolEmotionalState: EmotionalState?
    
    /// The emotional state after using the tool (optional)
    private var postToolEmotionalState: EmotionalState?
    
    /// Service for managing tools
    private let toolService: ToolService
    
    /// Service for managing emotional states
    private let emotionService: EmotionService
    
    /// Logging service
    private let logger: Logger
    
    /// Set to hold Combine cancellables
    private var cancellables: Set<AnyCancellable> = []
    
    /// Initializes the view model with the completed tool, usage duration, and optional pre-tool emotional state
    /// - Parameters:
    ///   - completedTool: The tool that was completed
    ///   - usageDuration: The duration of the tool usage in seconds
    ///   - preToolEmotionalState: The emotional state before using the tool (optional)
    ///   - toolService: The tool service to use (optional, defaults to shared instance)
    ///   - emotionService: The emotion service to use (optional, defaults to shared instance)
    init(completedTool: Tool, usageDuration: Int, preToolEmotionalState: EmotionalState? = nil, toolService: ToolService? = nil, emotionService: EmotionService? = nil) {
        self.completedTool = completedTool
        self.usageDuration = usageDuration
        self.preToolEmotionalState = preToolEmotionalState
        self.toolService = toolService ?? ToolService.shared
        self.emotionService = emotionService ?? EmotionService()
        self.logger = Logger.shared
        
        self.cancellables = []
        
        self.showEmotionalCheckIn = true
        self.showRecommendations = false
        self.isLoading = false
        self.showError = false
        self.errorMessage = nil
        self.emotionalShiftAnalyzed = false
        self.emotionChanged = false
        self.intensityChange = 0
        self.emotionalInsights = []
        self.recommendedTools = []
        self.navigateToHome = false
        self.navigateToTool = false
        self.selectedTool = nil
        
        trackToolUsage()
    }
    
    /// Records the tool usage with the tool service
    private func trackToolUsage() {
        isLoading = true
        toolService.trackToolUsage(tool: completedTool, durationSeconds: usageDuration) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                logger.log( "Successfully tracked tool usage", category: .userInterface)
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
                logger.error("Failed to track tool usage: \(error)", category: .userInterface)
            }
            isLoading = false
        }
    }
    
    /// Records the post-tool emotional state and analyzes the emotional shift
    /// - Parameter emotionalState: The emotional state after using the tool
    func recordEmotionalState(emotionalState: EmotionalState) {
        isLoading = true
        postToolEmotionalState = emotionalState
        emotionService.recordEmotionalState(emotionType: emotionalState.emotionType, intensity: emotionalState.intensity, context: .toolUsage, notes: emotionalState.notes, relatedToolId: completedTool.id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                if let preToolEmotionalState = preToolEmotionalState {
                    analyzeEmotionalShift()
                } else {
                    loadRecommendedTools()
                }
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
                logger.error("Failed to record emotional state: \(error)", category: .userInterface)
            }
            showEmotionalCheckIn = false
            showRecommendations = true
            isLoading = false
        }
    }
    
    /// Analyzes the emotional shift between pre and post tool usage
    private func analyzeEmotionalShift() {
        guard let preToolEmotionalState = preToolEmotionalState, let postToolEmotionalState = postToolEmotionalState else {
            return
        }
        emotionService.analyzeEmotionalShift(preState: preToolEmotionalState, postState: postToolEmotionalState) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let analysis):
                emotionalShiftAnalyzed = true
                emotionChanged = analysis.emotionChanged
                intensityChange = analysis.intensityChange
                emotionalInsights = analysis.insights.map { $0.description }
                loadRecommendedTools()
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
                logger.error("Failed to analyze emotional shift: \(error)", category: .userInterface)
                loadRecommendedTools() // Load recommendations even if analysis fails
            }
        }
    }
    
    /// Loads recommended tools based on the post-tool emotional state
    private func loadRecommendedTools() {
        isLoading = true
        
        // Determine the emotion type to use for recommendations
        let emotionType = postToolEmotionalState?.emotionType ?? completedTool.targetEmotions.first ?? .joy
        
        toolService.getRecommendedTools(emotionType: emotionType, limit: 3) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let tools):
                // Filter out the completed tool from recommendations
                recommendedTools = tools.filter { $0.id != completedTool.id }
                logger.log("Successfully loaded recommended tools", category: .userInterface)
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
                logger.error("Failed to load recommended tools: \(error)", category: .userInterface)
            }
            isLoading = false
            showEmotionalCheckIn = false
            showRecommendations = true
        }
    }
    
    /// Skips the emotional check-in and proceeds to recommendations
    func skipEmotionalCheckIn() {
        showEmotionalCheckIn = false
        loadRecommendedTools()
        logger.log("User skipped emotional check-in", category: .userInterface)
    }
    
    /// Selects a recommended tool for navigation
    /// - Parameter tool: The tool to navigate to
    func selectRecommendedTool(tool: Tool) {
        selectedTool = tool
        navigateToTool = true
        logger.log("Selected recommended tool: \(tool.name)", category: .userInterface)
    }
    
    /// Triggers navigation to the home screen
    func navigateToHomeScreen() {
        navigateToHome = true
        logger.log("Navigating to home screen", category: .userInterface)
    }
    
    /// Dismisses the error alert
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}