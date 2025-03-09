import Foundation // Latest
import Combine // Latest
import SwiftUI // Latest

// Internal imports
import Achievement // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import AchievementService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/AchievementService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// A view model that provides data and business logic for the Achievements screen
@MainActor
class AchievementsViewModel: ObservableObject {
    
    /// Indicates if the data is currently loading
    @Published var isLoading: Bool = true
    
    /// Stores any error message that occurs during data loading
    @Published var errorMessage: String = ""
    
    /// Stores the full list of achievements
    @Published var achievements: [Achievement] = []
    
    /// Stores the filtered list of achievements based on selected category and earned status
    @Published var filteredAchievements: [Achievement] = []
    
    /// Stores the currently selected achievement category for filtering
    @Published var selectedCategory: AchievementCategory? = nil
    
    /// Indicates whether to show only earned achievements
    @Published var showEarnedOnly: Bool = false
    
    /// Stores the overall achievement progress as a percentage
    @Published var achievementProgress: Double = 0.0
    
    /// Service for accessing achievement data
    private let achievementService: AchievementService
    
    /// Set to store Combine subscriptions for proper lifecycle management
    private var cancellables = Set<AnyCancellable>()
    
    /// Initializes the AchievementsViewModel with dependencies
    /// - Parameter achievementService: Optional AchievementService instance for data access
    init(achievementService: AchievementService? = nil) {
        // Store the provided achievementService or create a new instance
        self.achievementService = achievementService ?? AchievementService()
        
        // Set up subscription to achievementService.achievementsPublisher
        setupSubscriptions()
        
        // Call loadAchievements() to initialize the view model data
        loadAchievements()
    }
    
    /// Loads achievement data and initializes the view model
    func loadAchievements() {
        // Set isLoading to true
        isLoading = true
        
        // Clear any previous error message
        errorMessage = ""
        
        // Get initial achievements from achievementService.getCachedAchievements()
        let cachedAchievements = achievementService.getCachedAchievements()
        
        // Update achievements property with the retrieved data
        achievements = cachedAchievements
        
        // Apply current filters to update filteredAchievements
        applyFilters()
        
        // Update achievementProgress from achievementService.getAchievementProgress()
        achievementProgress = achievementService.getAchievementProgress()
        
        // Set isLoading to false
        isLoading = false
        
        // Log the data loading operation
        Logger.shared.debug("Achievements data loaded", category: .progress)
    }
    
    /// Refreshes achievement data from the server
    func refreshAchievements() {
        // Set isLoading to true
        isLoading = true
        
        // Clear any previous error message
        errorMessage = ""
        
        // Call achievementService.refreshAchievements()
        achievementService.refreshAchievements()
        
        // Set isLoading to false when complete
        isLoading = false
        
        // Log the refresh operation
        Logger.shared.debug("Achievements data refreshed", category: .progress)
    }
    
    /// Filters achievements by the selected category
    /// - Parameter category: The AchievementCategory to filter by, or nil to show all
    func selectCategory(category: AchievementCategory?) {
        // Update selectedCategory to the provided category
        selectedCategory = category
        
        // Apply filters to update filteredAchievements
        applyFilters()
        
        // Log the category selection
        Logger.shared.debug("Selected category: \(category?.rawValue ?? "All")", category: .progress)
    }
    
    /// Toggles the filter to show only earned achievements
    func toggleEarnedOnly() {
        // Toggle the showEarnedOnly boolean value
        showEarnedOnly.toggle()
        
        // Apply filters to update filteredAchievements
        applyFilters()
        
        // Log the filter change
        Logger.shared.debug("Show earned only toggled: \(showEarnedOnly)", category: .progress)
    }
    
    /// Applies the current filters to the achievements list
    private func applyFilters() {
        // Start with the full achievements array
        var filtered = achievements
        
        // If selectedCategory is not nil, filter by that category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // If showEarnedOnly is true, filter to show only earned achievements
        if showEarnedOnly {
            filtered = filtered.filter { $0.isEarned() }
        }
        
        // Update filteredAchievements with the filtered results
        filteredAchievements = filtered
        
        // Log the filter application
        Logger.shared.debug("Applied filters, \(filteredAchievements.count) achievements after filtering", category: .progress)
    }
    
    /// Groups achievements by their category
    /// - Returns: A dictionary of achievements grouped by category
    func getAchievementsByCategory() -> [AchievementCategory: [Achievement]] {
        // Create a dictionary to hold the grouped achievements
        var groupedAchievements: [AchievementCategory: [Achievement]] = [:]
        
        // Group the filteredAchievements by their category property
        for category in AchievementCategory.allCases {
            groupedAchievements[category] = filteredAchievements.filter { $0.category == category }
        }
        
        // Return the grouped dictionary
        return groupedAchievements
    }
    
    /// Returns a formatted string representation of achievement progress
    /// - Returns: Formatted progress percentage
    func getFormattedProgress() -> String {
        // Format achievementProgress as a percentage string
        let progressPercentage = Int(achievementProgress * 100)
        
        // Return the formatted string with % symbol
        return "\(progressPercentage)%"
    }
    
    /// Returns the count of earned achievements
    /// - Returns: Number of earned achievements
    func getEarnedCount() -> Int {
        // Filter achievements to count only those where isEarned() returns true
        let earnedAchievements = achievements.filter { $0.isEarned() }
        
        // Return the count of earned achievements
        return earnedAchievements.count
    }
    
    /// Returns the total count of achievements
    /// - Returns: Total number of achievements
    func getTotalCount() -> Int {
        // Return the count of all achievements
        return achievements.count
    }
    
    /// Returns achievements that are not yet earned but visible to the user
    /// - Returns: Array of upcoming achievements
    func getUpcomingAchievements() -> [Achievement] {
        // Filter achievements to include those that are not earned but not hidden
        let upcoming = achievements.filter { !$0.isEarned() && !$0.isHidden }
        
        // Sort by progress percentage in descending order
        let sorted = upcoming.sorted { $0.progress > $1.progress }
        
        // Return the filtered and sorted array
        return sorted
    }
    
    /// Sets up Combine subscriptions to react to data changes
    private func setupSubscriptions() {
        // Subscribe to achievementService.achievementsPublisher
        achievementService.achievementsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedAchievements in
                guard let self = self else { return }
                
                // Update the achievements property
                self.achievements = updatedAchievements
                
                // Apply current filters to update filteredAchievements
                self.applyFilters()
                
                // Update achievementProgress
                self.achievementProgress = self.achievementService.getAchievementProgress()
            }
            .store(in: &cancellables)
    }
}