# src/ios/AmiraWellness/AmiraWellness/Services/Progress/AchievementService.swift
import Foundation // Latest
import Combine // Latest

// Internal imports
import Achievement // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import APIError // src/ios/AmiraWellness/AmiraWellness/Models/APIError.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// Key for caching achievements in storage
let AchievementsStorageKey = "cached_achievements"

/// A service that manages user achievements in the Amira Wellness application
class AchievementService {
    
    // MARK: - Private Properties
    
    /// API client for fetching achievement data
    private let apiClient: APIClient
    
    /// Storage service for caching achievement data
    private let storageService: StorageService
    
    /// Cached array of achievements
    private var cachedAchievements: [Achievement] = []
    
    /// Subject for publishing achievement updates
    private var achievementsSubject = CurrentValueSubject<[Achievement], Never>([])
    
    // MARK: - Public Properties
    
    /// Publisher for achievement updates
    public var achievementsPublisher: AnyPublisher<[Achievement], Never> {
        return achievementsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initializes the AchievementService with dependencies
    /// - Parameters:
    ///   - apiClient: APIClient for network requests
    ///   - storageService: StorageService for caching data
    init(apiClient: APIClient, storageService: StorageService? = nil) {
        // Store the provided apiClient
        self.apiClient = apiClient
        
        // Store the provided storageService or use the shared instance
        self.storageService = storageService ?? StorageService.shared
        
        // Initialize cachedAchievements as an empty array
        self.cachedAchievements = []
        
        // Initialize achievementsSubject as a CurrentValueSubject with an empty array
        self.achievementsSubject = CurrentValueSubject<[Achievement], Never>([])
        
        // Initialize achievementsPublisher as a derived publisher from achievementsSubject
        // (This is already done in the property declaration)
        
        // Load cached achievements from storage
        loadCachedAchievements()
    }
    
    // MARK: - Public Methods
    
    /// Fetches the user's achievements from the API
    /// - Parameter completion: Completion handler with the result
    func getAchievements(completion: @escaping (Result<AchievementResponse, APIError>) -> Void) {
        // Make API request to fetch achievements using APIRouter.getAchievements
        apiClient.request(endpoint: .getAchievements) { [weak self] (result: Result<AchievementResponse, APIError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let achievementResponse):
                // If successful, update cachedAchievements with the fetched achievement data
                self.cachedAchievements = achievementResponse.achievements
                
                // Save achievements to storage for offline access
                self.saveCachedAchievements()
                
                // Publish the updated achievements through achievementsSubject
                self.achievementsSubject.send(self.cachedAchievements)
                
                // Call completion with the result
                completion(.success(achievementResponse))
                
            case .failure(let error):
                // Call completion with the result
                completion(.failure(error))
            }
        }
    }

    /// Fetches the user's achievements from the API using async/await
    /// - Returns: User achievements information
    @available(iOS 15.0, *)
    func getAchievements() async throws -> AchievementResponse {
        // Make API request to fetch achievements using APIRouter.getAchievements with async/await
        let achievementResponse = try await apiClient.requestAsync(endpoint: .getAchievements) as AchievementResponse
        
        // Update cachedAchievements with the fetched achievement data
        self.cachedAchievements = achievementResponse.achievements
        
        // Save achievements to storage for offline access
        self.saveCachedAchievements()
        
        // Publish the updated achievements through achievementsSubject
        self.achievementsSubject.send(self.cachedAchievements)
        
        // Return the fetched achievement data
        return achievementResponse
    }
    
    /// Returns the cached achievements without making an API request
    /// - Returns: Array of cached achievements
    func getCachedAchievements() -> [Achievement] {
        // Return the cachedAchievements array
        return cachedAchievements
    }
    
    /// Returns only the achievements that have been earned by the user
    /// - Returns: Array of earned achievements
    func getEarnedAchievements() -> [Achievement] {
        // Filter cachedAchievements to include only those where isEarned() returns true
        let earnedAchievements = cachedAchievements.filter { $0.isEarned() }
        
        // Return the filtered array of earned achievements
        return earnedAchievements
    }
    
    /// Returns achievements that are visible to the user (earned or not hidden)
    /// - Returns: Array of visible achievements
    func getUnlockedAchievements() -> [Achievement] {
        // Filter cachedAchievements to include those that are earned or not hidden
        let unlockedAchievements = cachedAchievements.filter { $0.isEarned() || !$0.isHidden }
        
        // Return the filtered array of visible achievements
        return unlockedAchievements
    }
    
    /// Returns achievements filtered by category
    /// - Parameter category: AchievementCategory to filter by
    /// - Returns: Array of achievements in the specified category
    func getAchievementsByCategory(category: AchievementCategory) -> [Achievement] {
        // Filter cachedAchievements by the specified category
        let filteredAchievements = cachedAchievements.filter { $0.category == category }
        
        // Return the filtered array of achievements
        return filteredAchievements
    }
    
    /// Returns achievements related to streak milestones
    /// - Returns: Array of streak-related achievements
    func getStreakAchievements() -> [Achievement] {
        // Call getAchievementsByCategory with .streak category
        let streakAchievements = getAchievementsByCategory(category: .streak)
        
        // Return the filtered array of streak achievements
        return streakAchievements
    }
    
    /// Returns the overall achievement progress percentage
    /// - Returns: Progress percentage (0.0-1.0)
    func getAchievementProgress() -> Double {
        // Count the number of earned achievements
        let earnedCount = getEarnedAchievements().count
        
        // Calculate the percentage based on total available achievements
        guard !cachedAchievements.isEmpty else { return 0.0 }
        let progress = Double(earnedCount) / Double(cachedAchievements.count)
        
        // Return the progress percentage
        return progress
    }
    
    /// Checks if a specific achievement type has been earned
    /// - Parameter type: AchievementType to check
    /// - Returns: True if achievement has been earned, false otherwise
    func hasEarnedAchievement(type: AchievementType) -> Bool {
        // Find the achievement with the specified type in cachedAchievements
        if let achievement = cachedAchievements.first(where: { $0.type == type }) {
            // Check if the achievement exists and is earned
            return achievement.isEarned()
        }
        
        // Return false if achievement is not found or not earned
        return false
    }
    
    /// Forces a refresh of achievements from the API
    func refreshAchievements() {
        // Call getAchievements with a completion handler that logs any errors
        getAchievements { result in
            switch result {
            case .success:
                Logger.shared.debug("Achievements refreshed successfully", category: .progress)
            case .failure(let error):
                Logger.shared.error("Failed to refresh achievements: \(error)", category: .progress)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads achievement data from local storage
    private func loadCachedAchievements() {
        // Attempt to retrieve achievement data from storageService using the AchievementsStorageKey
        let result: Result<[Achievement], StorageError> = storageService.retrieveCodable(forKey: AchievementsStorageKey, dataType: .progress, sensitivity: .nonsensitive)
        
        switch result {
        case .success(let achievements):
            // If successful, update cachedAchievements with the retrieved data
            cachedAchievements = achievements
            
            // Publish the loaded achievements through achievementsSubject
            achievementsSubject.send(achievements)
            
            Logger.shared.debug("Loaded achievements from cache", category: .progress)
            
        case .failure(let error):
            // Log any errors that occur during retrieval
            Logger.shared.error("Failed to load achievements from cache: \(error)", category: .progress)
        }
    }
    
    /// Saves achievement data to local storage
    private func saveCachedAchievements() {
        // Store cachedAchievements in storageService using the AchievementsStorageKey
        let result = storageService.storeCodable(cachedAchievements, forKey: AchievementsStorageKey, dataType: .progress, sensitivity: .nonsensitive)
        
        switch result {
        case .success:
            Logger.shared.debug("Saved achievements to cache", category: .progress)
        case .failure(let error):
            // Log any errors that occur during storage
            Logger.shared.error("Failed to save achievements to cache: \(error)", category: .progress)
        }
    }
}