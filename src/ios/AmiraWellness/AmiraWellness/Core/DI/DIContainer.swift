# src/ios/AmiraWellness/AmiraWellness/Core/DI/DIContainer.swift
import Foundation // Latest
// Internal imports
import ServiceFactory // src/ios/AmiraWellness/AmiraWellness/Core/DI/ServiceFactory.swift
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import EncryptionService // src/ios/AmiraWellness/AmiraWellness/Services/Encryption/EncryptionService.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import JournalService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/JournalService.swift
import EmotionService // src/ios/AmiraWellness/AmiraWellness/Services/Emotion/EmotionService.swift
import ToolService // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift
import ProgressService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/ProgressService.swift
import NotificationService // src/ios/AmiraWellness/AmiraWellness/Services/Notification/NotificationService.swift
import AudioRecordingService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/AudioRecordingService.swift
import AudioPlaybackService // src/ios/AmiraWellness/AmiraWellness/Services/Journal/AudioPlaybackService.swift

/// A container that manages service instances and their dependencies throughout the application
class DIContainer {
    /// Shared instance of DIContainer for singleton access
    static let shared = DIContainer()

    /// Factory for creating service instances with proper dependencies
    private let serviceFactory: ServiceFactory

    /// Authentication service instance
    private var authService: AuthService?

    /// Encryption service instance
    private var encryptionService: EncryptionService?

    /// Storage service instance
    private var storageService: StorageService?

    /// Journal service instance
    private var journalService: JournalService?

    /// Emotion service instance
    private var emotionService: EmotionService?

    /// Tool service instance
    private var toolService: ToolService?

    /// Progress service instance
    private var progressService: ProgressService?

    /// Notification service instance
    private var notificationService: NotificationService?

    /// Audio recording service instance
    private var audioRecordingService: AudioRecordingService?

    /// Audio playback service instance
    private var audioPlaybackService: AudioPlaybackService?

    /// Private initializer for singleton pattern
    private init() {
        // Initialize serviceFactory with a new ServiceFactory instance
        serviceFactory = ServiceFactory()
        // Initialize all service properties to nil
        authService = nil
        encryptionService = nil
        storageService = nil
        journalService = nil
        emotionService = nil
        toolService = nil
        progressService = nil
        notificationService = nil
        audioRecordingService = nil
        audioPlaybackService = nil
    }

    /// Returns the authentication service instance, creating it if needed
    /// - Returns: Authentication service instance
    func getAuthService() -> AuthService {
        // Check if authService is nil
        if authService == nil {
            // If nil, create it using serviceFactory.createAuthService()
            authService = serviceFactory.createAuthService()
        }
        // Return the authService instance
        return authService!
    }

    /// Returns the encryption service instance, creating it if needed
    /// - Returns: Encryption service instance
    func getEncryptionService() -> EncryptionService {
        // Check if encryptionService is nil
        if encryptionService == nil {
            // If nil, create it using serviceFactory.createEncryptionService()
            encryptionService = serviceFactory.createEncryptionService()
        }
        // Return the encryptionService instance
        return encryptionService!
    }

    /// Returns the storage service instance, creating it if needed
    /// - Returns: Storage service instance
    func getStorageService() -> StorageService {
        // Check if storageService is nil
        if storageService == nil {
            // If nil, create it using serviceFactory.createStorageService()
            storageService = serviceFactory.createStorageService()
        }
        // Return the storageService instance
        return storageService!
    }

    /// Returns the journal service instance, creating it if needed
    /// - Returns: Journal service instance
    func getJournalService() -> JournalService {
        // Check if journalService is nil
        if journalService == nil {
            // If nil, create it using serviceFactory.createJournalService()
            journalService = serviceFactory.createJournalService()
        }
        // Return the journalService instance
        return journalService!
    }

    /// Returns the emotion service instance, creating it if needed
    /// - Returns: Emotion service instance
    func getEmotionService() -> EmotionService {
        // Check if emotionService is nil
        if emotionService == nil {
            // If nil, create it using serviceFactory.createEmotionService()
            emotionService = serviceFactory.createEmotionService()
        }
        // Return the emotionService instance
        return emotionService!
    }

    /// Returns the tool service instance, creating it if needed
    /// - Returns: Tool service instance
    func getToolService() -> ToolService {
        // Check if toolService is nil
        if toolService == nil {
            // If nil, create it using serviceFactory.createToolService()
            toolService = serviceFactory.createToolService()
        }
        // Return the toolService instance
        return toolService!
    }

    /// Returns the progress service instance, creating it if needed
    /// - Returns: Progress service instance
    func getProgressService() -> ProgressService {
        // Check if progressService is nil
        if progressService == nil {
            // If nil, create it using serviceFactory.createProgressService()
            progressService = serviceFactory.createProgressService()
        }
        // Return the progressService instance
        return progressService!
    }

    /// Returns the notification service instance, creating it if needed
    /// - Returns: Notification service instance
    func getNotificationService() -> NotificationService {
        // Check if notificationService is nil
        if notificationService == nil {
            // If nil, create it using serviceFactory.createNotificationService()
            notificationService = serviceFactory.createNotificationService()
        }
        // Return the notificationService instance
        return notificationService!
    }
    
    /// Returns the audio recording service instance, creating it if needed
    /// - Returns: Audio recording service instance
    func getAudioRecordingService() -> AudioRecordingService {
        // Check if audioRecordingService is nil
        if audioRecordingService == nil {
            // If nil, create it using serviceFactory.createAudioRecordingService()
            audioRecordingService = serviceFactory.createAudioRecordingService()
        }
        // Return the audioRecordingService instance
        return audioRecordingService!
    }
    
    /// Returns the audio playback service instance, creating it if needed
    /// - Returns: Audio playback service instance
    func getAudioPlaybackService() -> AudioPlaybackService {
        // Check if audioPlaybackService is nil
        if audioPlaybackService == nil {
            // If nil, create it using serviceFactory.createAudioPlaybackService()
            audioPlaybackService = serviceFactory.createAudioPlaybackService()
        }
        // Return the audioPlaybackService instance
        return audioPlaybackService!
    }

    /// Resets all service instances, forcing them to be recreated on next access
    func reset() {
        // Set all service properties to nil
        authService = nil
        encryptionService = nil
        storageService = nil
        journalService = nil
        emotionService = nil
        toolService = nil
        progressService = nil
        notificationService = nil
        audioRecordingService = nil
        audioPlaybackService = nil
        // Create a new ServiceFactory instance
        _ = ServiceFactory()
    }
    
    /// Registers a mock service for testing purposes
    /// - Parameters:
    ///   - service: The mock service instance
    ///   - serviceType: The type of service to mock
    func registerMockService(service: Any, serviceType: String) {
        // Check serviceType to determine which service to mock
        switch serviceType {
        case "AuthService":
            // Cast service to AuthService and assign to authService
            authService = service as? AuthService
        case "EncryptionService":
            // Cast service to EncryptionService and assign to encryptionService
            encryptionService = service as? EncryptionService
        case "StorageService":
            // Cast service to StorageService and assign to storageService
            storageService = service as? StorageService
        case "JournalService":
            // Cast service to JournalService and assign to journalService
            journalService = service as? JournalService
        case "EmotionService":
            // Cast service to EmotionService and assign to emotionService
            emotionService = service as? EmotionService
        case "ToolService":
            // Cast service to ToolService and assign to toolService
            toolService = service as? ToolService
        case "ProgressService":
            // Cast service to ProgressService and assign to progressService
            progressService = service as? ProgressService
        case "NotificationService":
            // Cast service to NotificationService and assign to notificationService
            notificationService = service as? NotificationService
        case "AudioRecordingService":
            // Cast service to AudioRecordingService and assign to audioRecordingService
            audioRecordingService = service as? AudioRecordingService
        case "AudioPlaybackService":
            // Cast service to AudioPlaybackService and assign to audioPlaybackService
            audioPlaybackService = service as? AudioPlaybackService
        default:
            // Handle unknown service type
            print("Unknown service type: \(serviceType)")
        }
    }
}