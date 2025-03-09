# src/ios/AmiraWellness/AmiraWellness/UI/Screens/Home/HomeViewModel.swift
import Foundation // Latest
import Combine // Latest
import SwiftUI // Latest

// Internal imports
import Journal // src/ios/AmiraWellness/AmiraWellness/Models/Journal.swift
import EmotionalState // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import JournalService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/JournalService.swift
import EmotionService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionService.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import ProgressService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/ProgressService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// Protocol defining navigation actions for the Home screen
protocol HomeNavigationProtocol: AnyObject {
    /// Navigates to the emotional check-in screen
    func navigateToEmotionalCheckin()
    /// Navigates to the journal detail screen for a specific journal
    /// - Parameter journalId: The ID of the journal to navigate to
    func navigateToJournalDetail(journalId: UUID)
    /// Navigates to the tool detail screen for a specific tool
    /// - Parameter toolId: The ID of the tool to navigate to
    func navigateToToolDetail(toolId: UUID)
    /// Navigates to the record journal screen
    func navigateToRecordJournal()
}

/// ViewModel for the home screen of the Amira Wellness application
class HomeViewModel: ObservableObject {
    /// Indicates if the data is currently loading
    @Published var isLoading: Bool = true
    /// The user's name to display in the greeting
    @Published var userName: String = ""
    /// The user's recent journal entries
    @Published var recentJournals: [Journal] = []
    /// The user's recent emotional check-ins
    @Published var recentEmotionalCheckins: [EmotionalState] = []
    /// Tools recommended for the user
    @Published var recommendedTools: [Tool] = []
    /// The user's current streak
    @Published var currentStreak: Int = 0
    /// The next streak milestone to achieve
    @Published var nextMilestone: Int = 0
    /// The progress towards the next streak milestone
    @Published var streakProgress: Double = 0.0
    /// The user's current emotional state
    @Published var currentEmotionalState: EmotionalState? = nil
    
    /// Service for retrieving journal entries
    private let journalService: JournalService
    /// Service for retrieving emotional states
    private let emotionService: EmotionService
    /// Service for retrieving recommended tools
    private let toolService: ToolService
    /// Service for retrieving streak information
    private let progressService: ProgressService
    /// Logging service for debugging and error tracking
    private let logger: Logger
    /// Set to hold Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    /// Delegate for handling navigation actions
    weak var navigationDelegate: HomeNavigationProtocol?
    
    /// Initializes the HomeViewModel with dependencies
    /// - Parameters:
    ///   - journalService: Optional JournalService for retrieving journal entries
    ///   - emotionService: Optional EmotionService for retrieving emotional states
    ///   - toolService: Optional ToolService for retrieving recommended tools
    ///   - progressService: Optional ProgressService for retrieving streak information
    init(journalService: JournalService? = nil, emotionService: EmotionService? = nil, toolService: ToolService? = nil, progressService: ProgressService? = nil) {
        // Store the provided journalService or use JournalService.shared
        self.journalService = journalService ?? JournalService.shared
        // Store the provided emotionService or create a new instance
        self.emotionService = emotionService ?? EmotionService()
        // Store the provided toolService or use ToolService.shared
        self.toolService = toolService ?? ToolService.shared
        // Store the provided progressService or create a new instance
        self.progressService = progressService ?? ProgressService()
        // Initialize logger with Logger.shared
        self.logger = Logger.shared
        // Set up subscriptions to various publishers
        setupSubscriptions()
        // Load initial data
        refreshData()
    }
    
    /// Refreshes all data displayed on the home screen
    func refreshData() {
        // Set isLoading to true
        isLoading = true
        
        // Load recent journals
        loadRecentJournals()
        
        // Load recent emotional check-ins
        loadRecentEmotionalCheckins()
        
        // Load recommended tools based on current emotional state
        loadRecommendedTools()
        
        // Load streak information
        loadStreakInfo()
        
        // Record user activity for visiting the home screen
        recordHomeVisit()
        
        // Set isLoading to false when all data is loaded
        // Use Combine to ensure all data is loaded before setting isLoading to false
        Publishers.Zip4(
            journalService.getToolsLoadedPublisher(),
            emotionService.getInsightPublisher(),
            toolService.getCategoriesLoadedPublisher(),
            progressService.progressPublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.isLoading = false
        }
        .store(in: &cancellables)
        
        // Log the refresh operation
        logger.debug("Home screen data refreshed")
    }
    
    /// Loads the user's recent journal entries
    private func loadRecentJournals() {
        // Call journalService.getJournals to retrieve journals
        journalService.getJournals { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let journals):
                // On success, sort journals by creation date (newest first)
                let sortedJournals = journals.sorted { $0.createdAt > $1.createdAt }
                // Limit to the most recent 3 journals
                recentJournals = Array(sortedJournals.prefix(3))
                // Log the journal loading operation
                logger.debug("Recent journals loaded successfully")
            case .failure(let error):
                // On failure, log the error
                logger.error("Failed to load recent journals: \(error)")
            }
        }
    }
    
    /// Loads the user's recent emotional check-ins
    private func loadRecentEmotionalCheckins() {
        // Call emotionService.getEmotionalHistory to retrieve check-ins
        emotionService.getEmotionalHistory { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let checkins):
                // On success, sort check-ins by creation date (newest first)
                let sortedCheckins = checkins.sorted { $0.createdAt > $1.createdAt }
                // Filter out check-ins associated with journals to avoid duplication
                let filteredCheckins = sortedCheckins.filter { $0.relatedJournalId == nil }
                // Limit to the most recent 3 check-ins
                recentEmotionalCheckins = Array(filteredCheckins.prefix(3))
                // Update currentEmotionalState with the most recent check-in if available
                currentEmotionalState = recentEmotionalCheckins.first
                // Log the emotional check-in loading operation
                logger.debug("Recent emotional check-ins loaded successfully")
            case .failure(let error):
                // On failure, log the error
                logger.error("Failed to load recent emotional check-ins: \(error)")
            }
        }
    }
    
    /// Loads tools recommended based on the user's current emotional state
    private func loadRecommendedTools() {
        // Check if currentEmotionalState exists
        guard let currentEmotionalState = currentEmotionalState else {
            // If no current emotional state, load general recommendations
            toolService.getTools { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let tools):
                    // Limit to 4 recommended tools
                    recommendedTools = Array(tools.prefix(4))
                    // Log the tool recommendation loading operation
                    logger.debug("General tool recommendations loaded successfully")
                case .failure(let error):
                    // On failure, log the error
                    logger.error("Failed to load general tool recommendations: \(error)")
                }
            }
            return
        }
        
        // If exists, call toolService.getRecommendedTools with the current emotion type
        toolService.getRecommendedTools(emotionType: currentEmotionalState.emotionType) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let tools):
                // Limit to 4 recommended tools
                recommendedTools = Array(tools.prefix(4))
                // Log the tool recommendation loading operation
                logger.debug("Tool recommendations loaded successfully based on emotional state")
            case .failure(let error):
                // On failure, log the error
                logger.error("Failed to load tool recommendations based on emotional state: \(error)")
            }
        }
    }
    
    /// Loads the user's streak information
    private func loadStreakInfo() {
        // Get current streak from progressService.getCurrentStreak
        currentStreak = progressService.getCurrentStreak()
        // Get next milestone from progressService.getNextMilestone
        nextMilestone = progressService.getNextMilestone()
        // Get progress to next milestone from progressService.getProgressToNextMilestone
        streakProgress = progressService.getProgressToNextMilestone()
        // Log the streak info loading operation
        logger.debug("Streak information loaded successfully")
    }
    
    /// Records the user's visit to the home screen as an activity
    private func recordHomeVisit() {
        // Call progressService.recordActivity with current date
        progressService.recordActivity { result in
            switch result {
            case .success:
                // Log the result of the activity recording
                self.logger.debug("Home visit recorded successfully")
            case .failure(let error):
                // If recording fails, log the error
                self.logger.error("Failed to record home visit: \(error)")
            }
        }
    }
    
    /// Sets up Combine subscriptions to various publishers
    private func setupSubscriptions() {
        // Subscribe to journalService.journalCreatedPublisher
        journalService.journalCreatedPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When journalCreatedPublisher emits, refresh recent journals
                self?.loadRecentJournals()
            }
            .store(in: &cancellables)
        
        // Subscribe to journalService.journalUpdatedPublisher
        journalService.journalUpdatedPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When journalUpdatedPublisher emits, refresh recent journals
                self?.loadRecentJournals()
            }
            .store(in: &cancellables)
        
        // Subscribe to journalService.journalDeletedPublisher
        journalService.journalDeletedPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When journalDeletedPublisher emits, refresh recent journals
                self?.loadRecentJournals()
            }
            .store(in: &cancellables)
        
        // Subscribe to emotionService.getEmotionalStatePublisher
        emotionService.getEmotionalStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When getEmotionalStatePublisher emits, refresh recent emotional check-ins
                self?.loadRecentEmotionalCheckins()
            }
            .store(in: &cancellables)
        
        // Subscribe to toolService.getToolUpdatedPublisher
        toolService.getToolUpdatedPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When getToolUpdatedPublisher emits, refresh recommended tools
                self?.loadRecommendedTools()
            }
            .store(in: &cancellables)
        
        // Subscribe to progressService.progressPublisher
        progressService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When progressPublisher emits, refresh streak information
                self?.loadStreakInfo()
            }
            .store(in: &cancellables)
    }
    
    /// Navigates to the emotional check-in screen
    func navigateToEmotionalCheckin() {
        // Check if navigationDelegate exists
        guard let navigationDelegate = navigationDelegate else {
            return
        }
        // Call navigationDelegate?.navigateToEmotionalCheckin()
        navigationDelegate.navigateToEmotionalCheckin()
        // Log the navigation action
        logger.debug("Navigating to emotional check-in screen")
    }
    
    /// Navigates to the journal detail screen for a specific journal
    /// - Parameter journalId: The ID of the journal to navigate to
    func navigateToJournalDetail(journalId: UUID) {
        // Check if navigationDelegate exists
        guard let navigationDelegate = navigationDelegate else {
            return
        }
        // Call navigationDelegate?.navigateToJournalDetail(journalId: journalId)
        navigationDelegate.navigateToJournalDetail(journalId: journalId)
        // Log the navigation action
        logger.debug("Navigating to journal detail screen for journal ID: \(journalId)")
    }
    
    /// Navigates to the tool detail screen for a specific tool
    /// - Parameter toolId: The ID of the tool to navigate to
    func navigateToToolDetail(toolId: UUID) {
        // Check if navigationDelegate exists
        guard let navigationDelegate = navigationDelegate else {
            return
        }
        // Call navigationDelegate?.navigateToToolDetail(toolId: toolId)
        navigationDelegate.navigateToToolDetail(toolId: toolId)
        // Log the navigation action
        logger.debug("Navigating to tool detail screen for tool ID: \(toolId)")
    }
    
    /// Navigates to the record journal screen
    func navigateToRecordJournal() {
        // Check if navigationDelegate exists
        guard let navigationDelegate = navigationDelegate else {
            return
        }
        // Call navigationDelegate?.navigateToRecordJournal()
        navigationDelegate.navigateToRecordJournal()
        // Log the navigation action
        logger.debug("Navigating to record journal screen")
    }
}