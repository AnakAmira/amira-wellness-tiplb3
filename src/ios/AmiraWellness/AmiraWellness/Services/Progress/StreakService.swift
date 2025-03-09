# src/ios/AmiraWellness/AmiraWellness/Services/Progress/StreakService.swift
import Foundation // Latest
import Combine // Latest

// Internal imports
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import Streak // src/ios/AmiraWellness/AmiraWellness/Models/Streak.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import APIError // src/ios/AmiraWellness/AmiraWellness/Models/APIError.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import StorageDataType // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import StorageSensitivity // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift

/// Key for caching streak information
let StreakStorageKey = "cached_streak_info"

/// A service that manages user streaks in the Amira Wellness application
final class StreakService {
    /// A service that manages user streaks in the Amira Wellness application
    
    // MARK: - Private Properties
    
    /// The API client used to make network requests
    private let apiClient: APIClient
    
    /// The storage service used to cache streak data locally
    private let storageService: StorageService
    
    /// The cached streak information
    private var cachedStreak: Streak?
    
    /// Subject for publishing streak updates
    private var streakSubject = CurrentValueSubject<Streak?, Never>(nil)
    
    // MARK: - Public Properties
    
    /// Publisher for streak updates
    public var streakPublisher: AnyPublisher<Streak?, Never> {
        return streakSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initializes the StreakService with dependencies
    /// - Parameters:
    ///   - apiClient: The APIClient to use for network requests
    ///   - storageService: The StorageService to use for caching data
    init(apiClient: APIClient, storageService: StorageService? = nil) {
        // Store the provided apiClient
        self.apiClient = apiClient
        
        // Store the provided storageService or use the shared instance
        self.storageService = storageService ?? StorageService.shared
        
        // Initialize cachedStreak as nil
        self.cachedStreak = nil
        
        // Initialize streakSubject as a CurrentValueSubject with nil
        self.streakSubject = CurrentValueSubject<Streak?, Never>(nil)
        
        // Initialize streakPublisher as a derived publisher from streakSubject
        self.streakPublisher = streakSubject.eraseToAnyPublisher()
        
        // Load cached streak data from storage
        loadCachedStreak()
    }
    
    // MARK: - Public Methods
    
    /// Fetches the user's streak information from the API
    /// - Parameter completion: A closure to be called when the streak information is fetched
    func getStreakInfo(completion: @escaping (Result<Streak, APIError>) -> Void) {
        // Make API request to fetch streak info using APIRouter.getStreakInfo
        apiClient.request(endpoint: .getStreakInfo) { [weak self] (result: Result<Streak, APIError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let streak):
                // Update cachedStreak with the fetched streak data
                self.cachedStreak = streak
                
                // Save streak to storage for offline access
                self.saveCachedStreak()
                
                // Publish the updated streak through streakSubject
                self.streakSubject.send(streak)
                
                // Call completion with the result
                completion(.success(streak))
                
            case .failure(let error):
                // Log the error
                Logger.shared.error("Failed to fetch streak info: \(error.localizedDescription)", error: error, category: .sync)
                
                // Call completion with the result
                completion(.failure(error))
            }
        }
    }
    
    /// Fetches the user's streak information from the API using async/await
    /// - Returns: User streak information
    @available(iOS 15.0, *)
    func getStreakInfo() async throws -> Streak {
        // Make API request to fetch streak info using APIRouter.getStreakInfo with async/await
        let streak = try await apiClient.requestAsync(endpoint: .getStreakInfo) as Streak
        
        // Update cachedStreak with the fetched streak data
        self.cachedStreak = streak
        
        // Save streak to storage for offline access
        self.saveCachedStreak()
        
        // Publish the updated streak through streakSubject
        self.streakSubject.send(streak)
        
        // Return the fetched streak data
        return streak
    }
    
    /// Returns the cached streak information without making an API request
    /// - Returns: Cached streak information or nil if not available
    func getCachedStreakInfo() -> Streak? {
        // Return the cachedStreak value
        return cachedStreak
    }
    
    /// Updates the user's streak with a new activity date
    /// - Parameters:
    ///   - activityDate: The date of the new activity
    ///   - completion: A closure to be called when the streak is updated
    func updateStreak(activityDate: Date, completion: ((Bool) -> Void)? = nil) {
        // Check if cachedStreak exists
        guard var streak = cachedStreak else {
            // If nil, create a new Streak with default values
            let newStreak = Streak(userId: UUID(), currentStreak: 0, longestStreak: 0, lastActivityDate: nil, activityDates: [], totalDaysActive: 0, hasGracePeriodUsed: false)
            cachedStreak = newStreak
            updateStreakInternal(streak: newStreak, activityDate: activityDate, completion: completion)
            return
        }
        updateStreakInternal(streak: streak, activityDate: activityDate, completion: completion)
    }
    
    /// Updates the user's streak with a new activity date using async/await
    /// - Parameter activityDate: The date of the new activity
    /// - Returns: True if streak increased, false otherwise
    @available(iOS 15.0, *)
    func updateStreak(activityDate: Date) async -> Bool {
        // Check if cachedStreak exists
        guard var streak = cachedStreak else {
            // If nil, create a new Streak with default values
            let newStreak = Streak(userId: UUID(), currentStreak: 0, longestStreak: 0, lastActivityDate: nil, activityDates: [], totalDaysActive: 0, hasGracePeriodUsed: false)
            cachedStreak = newStreak
            return await updateStreakInternalAsync(streak: newStreak, activityDate: activityDate)
        }
        return await updateStreakInternalAsync(streak: streak, activityDate: activityDate)
    }
    
    /// Internal helper function to update the streak
    private func updateStreakInternal(streak: Streak, activityDate: Date, completion: ((Bool) -> Void)? = nil) {
        // Call updateStreak on the streak object with the activity date
        var mutableStreak = streak
        let streakIncreased = mutableStreak.updateStreak(activityDate: activityDate)
        cachedStreak = mutableStreak
        
        // If streak increased, check for milestone achievement
        if streakIncreased {
            let previousStreak = streak.currentStreak
            let currentStreak = mutableStreak.currentStreak
            let _ = checkForMilestone(previousStreak: previousStreak, currentStreak: currentStreak)
        }
        
        // Save updated streak to storage
        saveCachedStreak()
        
        // Publish the updated streak through streakSubject
        streakSubject.send(cachedStreak)
        
        // Call completion with the result (true if streak increased)
        completion?(streakIncreased)
    }
    
    /// Internal helper function to update the streak using async/await
    @available(iOS 15.0, *)
    private func updateStreakInternalAsync(streak: Streak, activityDate: Date) async -> Bool {
        // Call updateStreak on the streak object with the activity date
        var mutableStreak = streak
        let streakIncreased = mutableStreak.updateStreak(activityDate: activityDate)
        cachedStreak = mutableStreak
        
        // If streak increased, check for milestone achievement
        if streakIncreased {
            let previousStreak = streak.currentStreak
            let currentStreak = mutableStreak.currentStreak
            let _ = checkForMilestone(previousStreak: previousStreak, currentStreak: currentStreak)
        }
        
        // Save updated streak to storage
        saveCachedStreak()
        
        // Publish the updated streak through streakSubject
        streakSubject.send(cachedStreak)
        
        // Return true if streak increased, false otherwise
        return streakIncreased
    }
    
    /// Returns the current streak count
    /// - Returns: Current streak count
    func getCurrentStreak() -> Int {
        // Return cachedStreak?.currentStreak ?? 0
        return cachedStreak?.currentStreak ?? 0
    }
    
    /// Returns the longest streak count achieved by the user
    /// - Returns: Longest streak count
    func getLongestStreak() -> Int {
        // Return cachedStreak?.longestStreak ?? 0
        return cachedStreak?.longestStreak ?? 0
    }
    
    /// Returns the next streak milestone to achieve
    /// - Returns: Days needed for next milestone
    func getNextMilestone() -> Int {
        // Return cachedStreak?.getNextMilestone() ?? 0
        return cachedStreak?.getNextMilestone() ?? 0
    }
    
    /// Returns the progress percentage towards the next milestone
    /// - Returns: Progress percentage (0.0-1.0)
    func getProgressToNextMilestone() -> Double {
        // Return cachedStreak?.progressToNextMilestone() ?? 0.0
        return cachedStreak?.progressToNextMilestone() ?? 0.0
    }
    
    /// Determines if the user's streak is currently active
    /// - Returns: True if streak is active, false otherwise
    func isStreakActive() -> Bool {
        // Return cachedStreak?.isActive() ?? false
        return cachedStreak?.isActive() ?? false
    }
    
    /// Forces a refresh of streak information from the API
    func refreshStreakInfo() {
        // Call getStreakInfo with a completion handler that logs any errors
        getStreakInfo { result in
            switch result {
            case .success:
                Logger.shared.debug("Successfully refreshed streak info from API", category: .sync)
            case .failure(let error):
                Logger.shared.error("Failed to refresh streak info from API: \(error.localizedDescription)", error: error, category: .sync)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Checks if a streak milestone has been reached and posts a notification if so
    /// - Parameters:
    ///   - previousStreak: The streak count before the update
    ///   - currentStreak: The current streak count
    /// - Returns: True if milestone reached, false otherwise
    private func checkForMilestone(previousStreak: Int, currentStreak: Int) -> Bool {
        // Get the array of streak milestones
        let milestones = streakMilestones.sorted()
        
        // Check if currentStreak matches any milestone
        guard let milestone = milestones.first(where: { $0 == currentStreak }) else {
            return false
        }
        
        // Check if previousStreak was less than the milestone (to ensure it's newly reached)
        guard previousStreak < milestone else {
            return false
        }
        
        // Post notification with milestone and streak information
        NotificationCenter.default.post(name: StreakMilestoneReached.notificationName, object: nil, userInfo: [
            StreakMilestoneReached.milestoneKey: milestone,
            StreakMilestoneReached.streakKey: currentStreak
        ])
        
        return true
    }
    
    /// Loads streak data from local storage
    private func loadCachedStreak() {
        // Attempt to retrieve streak data from storageService using the StreakStorageKey
        let result: Result<Streak, StorageError> = storageService.retrieveCodable(forKey: StreakStorageKey, dataType: .progress, sensitivity: .nonsensitive)
        
        switch result {
        case .success(let streak):
            // Update cachedStreak with the retrieved data
            cachedStreak = streak
            
            // Publish the loaded streak through streakSubject
            streakSubject.send(streak)
            
            Logger.shared.debug("Successfully loaded streak from cache", category: .sync)
            
        case .failure(let error):
            // Log any errors that occur during retrieval
            Logger.shared.error("Failed to load streak from cache: \(error)", category: .sync)
        }
    }
    
    /// Saves streak data to local storage
    private func saveCachedStreak() {
        // Check if cachedStreak exists
        guard let streak = cachedStreak else {
            return
        }
        
        // Store cachedStreak in storageService using the StreakStorageKey
        let result = storageService.storeCodable(streak, forKey: StreakStorageKey, dataType: .progress, sensitivity: .nonsensitive)
        
        switch result {
        case .success:
            Logger.shared.debug("Successfully saved streak to cache", category: .sync)
            
        case .failure(let error):
            // Log any errors that occur during storage
            Logger.shared.error("Failed to save streak to cache: \(error)", category: .sync)
        }
    }
}