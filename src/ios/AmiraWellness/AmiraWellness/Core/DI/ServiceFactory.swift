# src/ios/AmiraWellness/AmiraWellness/Core/DI/ServiceFactory.swift
import Foundation // Latest
import Combine // Latest

// Internal imports
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import RequestInterceptor // src/ios/AmiraWellness/AmiraWellness/Services/Network/RequestInterceptor.swift
import NetworkMonitor // src/ios/AmiraWellness/AmiraWellness/Services/Network/NetworkMonitor.swift
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import EncryptionService // src/ios/AmiraWellness/AmiraWellness/Services/Encryption/EncryptionService.swift
import KeyManagementService // src/ios/AmiraWellness/AmiraWellness/Services/Encryption/KeyManagementService.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import SecureStorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/SecureStorageService.swift
import JournalService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/JournalService.swift
import EmotionService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionService.swift
import EmotionAnalysisService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionAnalysisService.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import ToolCacheService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolCacheService.swift
import ProgressService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/ProgressService.swift
import StreakService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/StreakService.swift
import AchievementService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/AchievementService.swift
import NotificationService // src/ios/AmiraWellness/AmiraWellness/Services/Notification/NotificationService.swift
import AudioRecordingService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/AudioRecordingService.swift
import AudioPlaybackService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/AudioPlaybackService.swift

/// A factory class responsible for creating service instances with proper dependencies
class ServiceFactory {
    /// Private property to hold the APIClient instance
    private let apiClient: APIClient
    /// Private property to hold the RequestInterceptor instance
    private let requestInterceptor: RequestInterceptor
    /// Private property to hold the NetworkMonitor instance
    private let networkMonitor: NetworkMonitor

    /// Initializes the ServiceFactory with default dependencies
    init() {
        // Initialize networkMonitor with NetworkMonitor.shared
        networkMonitor = NetworkMonitor.shared
        // Initialize requestInterceptor with a new RequestInterceptor instance
        requestInterceptor = RequestInterceptor()
        // Initialize apiClient with a new APIClient instance using requestInterceptor and networkMonitor
        apiClient = APIClient()
    }

    /// Creates and configures an authentication service instance
    /// - Returns: Configured authentication service
    func createAuthService() -> AuthService {
        // Create a new AuthServiceImpl instance with apiClient
        let authService = AuthService()
        // Return the created service instance
        return authService
    }

    /// Creates and configures an encryption service instance
    /// - Returns: Configured encryption service
    func createEncryptionService() -> EncryptionService {
        // Create a new EncryptionServiceImpl instance with KeyManagementService.shared
        let encryptionService = EncryptionService()
        // Return the created service instance
        return encryptionService
    }

    /// Creates and configures a storage service instance
    /// - Returns: Configured storage service
    func createStorageService() -> StorageService {
        // Get encryption service using createEncryptionService()
        let encryptionService = createEncryptionService()
        // Create a new StorageServiceImpl instance with SecureStorageService.shared and encryption service
        let storageService = StorageService()
        // Return the created service instance
        return storageService
    }

    /// Creates and configures a journal service instance
    /// - Returns: Configured journal service
    func createJournalService() -> JournalService {
        // Get storage service using createStorageService()
        let storageService = createStorageService()
        // Get encryption service using createEncryptionService()
        let encryptionService = createEncryptionService()
        // Create a new JournalServiceImpl instance with apiClient, storage service, and encryption service
        let journalService = JournalService()
        // Return the created service instance
        return journalService
    }

    /// Creates and configures an emotion service instance
    /// - Returns: Configured emotion service
    func createEmotionService() -> EmotionService {
        // Create a new EmotionServiceImpl instance with apiClient and EmotionAnalysisService.shared
        let emotionService = EmotionService()
        // Return the created service instance
        return emotionService
    }

    /// Creates and configures a tool service instance
    /// - Returns: Configured tool service
    func createToolService() -> ToolService {
        // Get storage service using createStorageService()
        let storageService = createStorageService()
        // Create a new ToolServiceImpl instance with apiClient, storage service, and ToolCacheService.shared
        let toolService = ToolService()
        // Return the created service instance
        return toolService
    }

    /// Creates and configures a progress service instance
    /// - Returns: Configured progress service
    func createProgressService() -> ProgressService {
        // Create a new ProgressServiceImpl instance with apiClient, StreakService.shared, and AchievementService.shared
        let progressService = ProgressService()
        // Return the created service instance
        return progressService
    }

    /// Creates and configures a notification service instance
    /// - Returns: Configured notification service
    func createNotificationService() -> NotificationService {
        // Create a new NotificationServiceImpl instance
        let notificationService = NotificationService()
        // Return the created service instance
        return notificationService
    }
    
    /// Creates and configures an audio recording service instance
    /// - Returns: Configured audio recording service
    func createAudioRecordingService() -> AudioRecordingService {
        // Get encryption service using createEncryptionService()
        let encryptionService = createEncryptionService()
        // Create a new AudioRecordingServiceImpl instance with encryption service
        let audioRecordingService = AudioRecordingService()
        // Return the created service instance
        return audioRecordingService
    }
    
    /// Creates and configures an audio playback service instance
    /// - Returns: Configured audio playback service
    func createAudioPlaybackService() -> AudioPlaybackService {
        // Get encryption service using createEncryptionService()
        let encryptionService = createEncryptionService()
        // Create a new AudioPlaybackServiceImpl instance with encryption service
        let audioPlaybackService = AudioPlaybackService()
        // Return the created service instance
        return audioPlaybackService
    }

    /// Configures the factory to use mock services for testing
    /// - Parameters:
    ///   - mockApiClient: Optional mock APIClient
    ///   - mockRequestInterceptor: Optional mock RequestInterceptor
    ///   - mockNetworkMonitor: Optional mock NetworkMonitor
    func configureWithMocks(mockApiClient: APIClient? = nil, mockRequestInterceptor: RequestInterceptor? = nil, mockNetworkMonitor: NetworkMonitor? = nil) {
        // If mockApiClient is provided, replace apiClient with it
        if let mockApiClient = mockApiClient {
            apiClient = mockApiClient
        }
        // If mockRequestInterceptor is provided, replace requestInterceptor with it
        if let mockRequestInterceptor = mockRequestInterceptor {
            requestInterceptor = mockRequestInterceptor
        }
        // If mockNetworkMonitor is provided, replace networkMonitor with it
        if let mockNetworkMonitor = mockNetworkMonitor {
            networkMonitor = mockNetworkMonitor
        }
    }
}