import Foundation // Foundation - Latest - Access to core Foundation types
import Combine // Combine - Latest - Reactive programming for handling asynchronous operations

// Internal imports
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift - Access user profile data model
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift - Handle authentication-related operations like profile fetching and logout
import JournalService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/JournalService.swift - Access journal data for statistics
import EmotionService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionService.swift - Access emotional check-in data for statistics
import ProgressService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/ProgressService.swift - Access progress data for statistics
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift - Make API requests for data export
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift - Define API endpoints for profile operations
import APIError // src/ios/AmiraWellness/AmiraWellness/Models/APIError.swift - Handle API errors in profile operations
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift - Log profile-related operations

/// Enum defining possible errors that can occur during profile operations
enum ProfileError: Error, Identifiable {
    case networkError
    case authenticationError
    case dataExportError
    case deleteAccountError
    case unknown
    
    var id: String {
        return UUID().uuidString
    }
}

/// A view model that manages the user profile data and operations
@available(iOS 14.0, *)
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Published property to hold the user profile data
    @Published var userProfile: User?
    
    /// Published property to track loading state
    @Published var isLoading: Bool = false
    
    /// Published property to hold any error that occurs
    @Published var error: ProfileError?
    
    /// Published property to track the progress of data export
    @Published var exportProgress: Double = 0.0
    
    /// Published property to hold the URL of the exported data file
    @Published var exportURL: URL?
    
    // MARK: - Private Properties
    
    /// Private property to store the AuthService instance
    private let authService: AuthService
    
    /// Private property to store the JournalService instance
    private let journalService: JournalService
    
    /// Private property to store the EmotionService instance
    private let emotionService: EmotionService
    
    /// Private property to store the ProgressService instance
    private let progressService: ProgressService
    
    /// Private property to store the APIClient instance
    private let apiClient: APIClient
    
    /// Private property to store Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
     /// Private property to store the journal count
    private var journalCount: Int = 0

    /// Private property to store the checkin count
    private var checkinCount: Int = 0

    /// Private property to store the tool usage count
    private var toolUsageCount: Int = 0
    
    // MARK: - Initialization
    
    /// Initializes the ProfileViewModel with dependencies
    /// - Parameters:
    ///   - authService: The AuthService instance to use
    ///   - journalService: The JournalService instance to use
    ///   - emotionService: The EmotionService instance to use
    ///   - progressService: The ProgressService instance to use
    ///   - apiClient: The APIClient instance to use
    init(authService: AuthService = AuthService.shared,
         journalService: JournalService = JournalService.shared,
         emotionService: EmotionService = EmotionService.shared,
         progressService: ProgressService = ProgressService.shared,
         apiClient: APIClient = APIClient.shared) {
        self.authService = authService // Store the provided authService
        self.journalService = journalService // Store the provided journalService
        self.emotionService = emotionService // Store the provided emotionService
        self.progressService = progressService // Store the provided progressService
        self.apiClient = apiClient // Store the provided apiClient
        fetchUserProfile() // Call fetchUserProfile() to load initial data
    }
    
    // MARK: - Public Methods
    
    /// Fetches the user profile data from the authentication service
    func fetchUserProfile() {
        isLoading = true // Set isLoading to true
        
        if let cachedUser = authService.getCurrentUser() { // Check if there's a cached user from authService.getCurrentUser()
            userProfile = cachedUser // If cached user exists, set userProfile to cached user
        }
        
        authService.getUserProfile { [weak self] result in // Call authService.getUserProfile to get fresh data
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.userProfile = user // On success, update userProfile with fresh data
                case .failure(let error):
                    self.error = self.mapAuthErrorToProfileError(error: error) // On failure, set error to appropriate ProfileError
                }
                self.isLoading = false // Set isLoading to false
                self.fetchUsageStatistics() // Fetch usage statistics in the background
                Logger.shared.debug("Profile fetched", category: .authentication) // Log the profile fetch operation
            }
        }
    }

    /// Fetches the user profile data using async/await
    @available(iOS 15.0, *)
    func fetchUserProfileAsync() async throws -> User {
        isLoading = true // Set isLoading to true
        do {
            let user = try await authService.getUserProfileAsync() // Try to get user profile from authService.getUserProfileAsync()
            userProfile = user // Set userProfile to the retrieved user
            isLoading = false // Set isLoading to false
            fetchUsageStatistics() // Fetch usage statistics in the background
            Logger.shared.debug("Profile fetched", category: .authentication) // Log the profile fetch operation
            return user // Return the user profile
        } catch {
            isLoading = false // If an error occurs, set isLoading to false
            self.error = self.mapAuthErrorToProfileError(error: error as? AuthError) // Set error to appropriate ProfileError
            Logger.shared.error("Profile fetch failed: \(error)", category: .authentication) // Log the profile fetch operation
            throw error // Throw the error
        }
    }
    
    /// Logs out the current user
    /// - Parameter completion: A closure to be called when the logout is complete
    func logout(completion: @escaping (Result<Void, ProfileError>) -> Void) {
        isLoading = true // Set isLoading to true
        
        authService.logout { [weak self] result in // Call authService.logout
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.userProfile = nil // On success, set userProfile to nil
                    completion(.success(())) // Call completion with success
                case .failure(let error):
                    self.error = self.mapAuthErrorToProfileError(error: error) // On failure, set error to appropriate ProfileError
                    completion(.failure(self.error!)) // Call completion with error
                }
                self.isLoading = false // Set isLoading to false
                Logger.shared.debug("Logged out", category: .authentication) // Log the logout operation
            }
        }
    }

    /// Logs out the current user using async/await
    @available(iOS 15.0, *)
    func logoutAsync() async throws {
        isLoading = true // Set isLoading to true
        do {
            try await authService.logoutAsync() // Try to logout using authService.logoutAsync()
            userProfile = nil // Set userProfile to nil
            isLoading = false // Set isLoading to false
            Logger.shared.debug("Logged out", category: .authentication) // Log the logout operation
        } catch {
            isLoading = false // If an error occurs, set isLoading to false
            self.error = self.mapAuthErrorToProfileError(error: error as? AuthError) // Set error to appropriate ProfileError
            Logger.shared.error("Logout failed: \(error)", category: .authentication) // Log the logout operation
            throw error // Throw the error
        }
    }
    
    /// Exports the user's data to a file
    /// - Parameter completion: A closure to be called when the data export is complete
    func exportUserData(completion: @escaping (Result<URL, ProfileError>) -> Void) {
        isLoading = true // Set isLoading to true
        exportProgress = 0.0 // Set exportProgress to 0.0
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory // Create a temporary directory for the export file
        let destinationURL = tempDir.appendingPathComponent("AmiraWellnessDataExport.json") // Create a destination URL in the temporary directory
        
        let dataTypes = ["journals", "emotions", "tools"] // Create an array of data types to export
        
        apiClient.downloadFile(endpoint: .exportData(dataTypes: dataTypes), destination: destinationURL) { [weak self] result in // Call apiClient.downloadFile with APIRouter.exportData
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let fileURL):
                    self.exportURL = fileURL // On success, set exportURL to the downloaded file URL
                    completion(.success(fileURL)) // Call completion with success and the file URL
                case .failure:
                    self.error = .dataExportError // On failure, set error to ProfileError.dataExportError
                    completion(.failure(.dataExportError)) // Call completion with error
                }
                self.isLoading = false // Set isLoading to false
                Logger.shared.debug("Data exported", category: .authentication) // Log the data export operation
            }
        } progressHandler: { progress in // Track download progress by updating exportProgress
            DispatchQueue.main.async {
                self.exportProgress = progress.fractionCompleted // Update exportProgress
            }
        }
    }

    /// Exports the user's data using async/await
    @available(iOS 15.0, *)
    func exportUserDataAsync() async throws -> URL {
        isLoading = true // Set isLoading to true
        exportProgress = 0.0 // Set exportProgress to 0.0
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory // Create a temporary directory for the export file
        let destinationURL = tempDir.appendingPathComponent("AmiraWellnessDataExport.json") // Create a destination URL in the temporary directory
        
        let dataTypes = ["journals", "emotions", "tools"] // Create an array of data types to export
        
        do {
            let fileURL = try await apiClient.downloadFileAsync(endpoint: .exportData(dataTypes: dataTypes), destination: destinationURL) { progress in // Try to download file using apiClient.downloadFileAsync
                DispatchQueue.main.async {
                    self.exportProgress = progress.fractionCompleted // Track download progress by updating exportProgress
                }
            }
            exportURL = fileURL // Set exportURL to the downloaded file URL
            isLoading = false // Set isLoading to false
            Logger.shared.debug("Data exported", category: .authentication) // Log the data export operation
            return fileURL // Return the file URL
        } catch {
            isLoading = false // If an error occurs, set isLoading to false
            self.error = .dataExportError // Set error to ProfileError.dataExportError
            Logger.shared.error("Data export failed: \(error)", category: .authentication) // Log the data export operation
            throw error // Throw the error
        }
    }
    
    /// Deletes the user's account
    /// - Parameters:
    ///   - password: The user's password for confirmation
    ///   - completion: A closure to be called when the account deletion is complete
    func deleteAccount(password: String, completion: @escaping (Result<Void, ProfileError>) -> Void) {
        isLoading = true // Set isLoading to true
        
        apiClient.requestEmpty(endpoint: .deleteAccount) { [weak self] result in // Call apiClient.requestEmpty with APIRouter.deleteAccount
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.authService.logout { _ in } // On success, call authService.logout
                    self.userProfile = nil // Set userProfile to nil
                    completion(.success(())) // Call completion with success
                case .failure(let error):
                    self.error = self.mapAuthErrorToProfileError(error: error) // On failure, set error to ProfileError.deleteAccountError
                    completion(.failure(.deleteAccountError)) // Call completion with error
                }
                self.isLoading = false // Set isLoading to false
                Logger.shared.debug("Account deleted", category: .authentication) // Log the account deletion operation
            }
        }
    }

    /// Deletes the user's account using async/await
    @available(iOS 15.0, *)
    func deleteAccountAsync(password: String) async throws {
        isLoading = true // Set isLoading to true
        do {
            try await apiClient.requestEmptyAsync(endpoint: .deleteAccount) // Try to delete account using apiClient.requestEmptyAsync
            try await authService.logoutAsync() // Try to logout using authService.logoutAsync()
            userProfile = nil // Set userProfile to nil
            isLoading = false // Set isLoading to false
            Logger.shared.debug("Account deleted", category: .authentication) // Log the account deletion operation
        } catch {
            isLoading = false // If an error occurs, set isLoading to false
            self.error = self.mapAuthErrorToProfileError(error: error as? AuthError) // Set error to ProfileError.deleteAccountError
            Logger.shared.error("Account deletion failed: \(error)", category: .authentication) // Log the account deletion operation
            throw error // Throw the error
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetches usage statistics for the user
    private func fetchUsageStatistics() {
        journalService.getJournals { [weak self] result in // Call journalService.getJournals to get journal count
            guard let self = self else { return }
            
            switch result {
            case .success(let journals):
                self.journalCount = journals.count // On success, store journal count
            case .failure(let error):
                Logger.shared.error("Failed to fetch journal count: \(error)", category: .authentication)
            }
            
            self.emotionService.getEmotionalHistory { result in // Call emotionService.getEmotionalHistory to get check-in count
                guard let self = self else { return }
                
                switch result {
                case .success(let checkins):
                    self.checkinCount = checkins.count // On success, store check-in count
                case .failure(let error):
                    Logger.shared.error("Failed to fetch checkin count: \(error)", category: .authentication)
                }
                
                self.toolUsageCount = 0 // Calculate tool usage count from available data
                
                Logger.shared.debug("Usage statistics fetched", category: .authentication) // Log the statistics fetch operation
            }
        }
    }
    
    private func mapAuthErrorToProfileError(error: Error?) -> ProfileError {
        if let authError = error as? AuthError {
            switch authError {
            case .networkError:
                return .networkError
            case .invalidCredentials, .accountDisabled, .emailNotVerified, .biometricAuthFailed:
                return .authenticationError
            default:
                return .unknown
            }
        } else {
            return .unknown
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the count of user's journal entries
    func getJournalCount() -> Int {
        return journalCount // Return the stored journalCount
    }
    
    /// Returns the count of user's emotional check-ins
    func getCheckinCount() -> Int {
        return checkinCount // Return the stored checkinCount
    }
    
    /// Returns the count of user's tool usages
    func getToolUsageCount() -> Int {
        return toolUsageCount // Return the stored toolUsageCount
    }
    
    /// Returns the user's current streak
    func getCurrentStreak() -> Int {
        return progressService.getCurrentStreak() // Return progressService.getCurrentStreak()
    }
    
    /// Returns the user's longest streak
    func getLongestStreak() -> Int {
        return progressService.getLongestStreak() // Return progressService.getLongestStreak()
    }
    
    /// Returns the count of user's earned achievements
    func getAchievementCount() -> Int {
        return progressService.getEarnedAchievements().count // Return progressService.getEarnedAchievements().count
    }
    
    /// Returns a formatted string of when the user joined
    func getMemberSince() -> String {
        guard let userProfile = userProfile else { // Check if userProfile exists
            return "" // Otherwise, return an empty string
        }
        return userProfile.formattedJoinDate() // If it exists, return userProfile.formattedJoinDate()
    }
    
    /// Checks if the user has a premium subscription
    func isPremiumUser() -> Bool {
        guard let userProfile = userProfile else { // Check if userProfile exists
            return false // Otherwise, return false
        }
        return userProfile.isPremium() // If it exists, return userProfile.isPremium()
    }
    
    /// Clears any current error
    func clearError() {
        error = nil // Set error to nil
    }
}