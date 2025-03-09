//
//  AppConstants.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // iOS SDK

/// Application-wide constants for the Amira Wellness app
struct AppConstants {
    
    /// Application metadata and basic information
    struct App {
        /// The name of the application
        static let name = "Amira Wellness"
        
        /// The bundle identifier of the application
        static let bundleIdentifier = "com.amirawellness.app"
        
        /// The version of the application
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        /// The build number of the application
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        /// The minimum iOS version required to run the app
        static let minimumOSVersion = "14.0"
        
        /// Support email address for user inquiries
        static let supportEmail = "support@amirawellness.com"
        
        /// URL to the privacy policy
        static let privacyPolicyURL = "https://www.amirawellness.com/privacy"
        
        /// URL to the terms of service
        static let termsOfServiceURL = "https://www.amirawellness.com/terms"
        
        /// URL to the App Store listing
        static let appStoreURL = "https://apps.apple.com/app/amirawellness"
        
        /// Default language for the application (Spanish)
        static let defaultLanguage = "es"
    }
    
    /// Security-related constants for encryption and authentication
    struct Security {
        /// Encryption algorithm used for end-to-end encryption
        static let encryptionAlgorithm = "AES-256-GCM"
        
        /// Key size in bits for encryption
        static let keySize = 256
        
        /// Service name for Keychain access
        static let keychainServiceName = "com.amirawellness.keychain"
        
        /// Access group for shared Keychain items
        static let keychainAccessGroup = "group.com.amirawellness"
        
        /// Minimum password length for user accounts
        static let passwordMinLength = 10
        
        /// Whether passwords require at least one special character
        static let passwordRequiresSpecialCharacter = true
        
        /// Whether passwords require at least one number
        static let passwordRequiresNumber = true
        
        /// Whether passwords require at least one uppercase letter
        static let passwordRequiresUppercase = true
        
        /// Session timeout in minutes
        static let sessionTimeoutMinutes = 30
        
        /// Key identifier for encryption keys in the Keychain
        static let encryptionKeyIdentifier = "com.amirawellness.encryptionKey"
        
        /// Reason displayed to user for biometric authentication
        static let biometricAuthenticationReason = "Unlock Amira Wellness to access your secure voice journals and emotional data"
        
        /// Whether certificate pinning is enabled for network requests
        static let certificatePinningEnabled = true
    }
    
    /// Audio recording and playback configuration constants
    struct Audio {
        /// Maximum recording duration in seconds
        static let maxRecordingDurationSeconds = 600 // 10 minutes
        
        /// Audio format used for recordings
        static let audioFormat = "aac"
        
        /// Sample rate for audio recordings in Hz
        static let sampleRate: Float = 44100.0
        
        /// Bit rate for audio recordings in bits per second
        static let bitRate = 128000
        
        /// Number of audio channels (mono = 1, stereo = 2)
        static let channels = 1
        
        /// File extension for audio recordings
        static let audioFileExtension = "m4a"
        
        /// Directory name for local audio storage
        static let localAudioDirectory = "VoiceJournals"
        
        /// Maximum file size for audio recordings in bytes
        static let maxFileSize = 50 * 1024 * 1024 // 50 MB
        
        /// Compression quality for audio recordings (0.0 to 1.0)
        static let compressionQuality: Float = 0.8
        
        /// Audio session category
        static let audioSessionCategory = "AVAudioSessionCategoryPlayAndRecord"
        
        /// Audio session mode
        static let audioSessionMode = "AVAudioSessionModeDefault"
    }
    
    /// Emotional check-in related constants
    struct Emotion {
        /// Minimum value for emotion intensity scale
        static let intensityMin = 1
        
        /// Maximum value for emotion intensity scale
        static let intensityMax = 10
        
        /// Default value for emotion intensity
        static let intensityDefault = 5
        
        /// Maximum length for emotional check-in notes
        static let maxNotesLength = 500
        
        /// Default emotion type
        static let defaultEmotionType = "neutral"
        
        /// Threshold for meaningful emotion change (difference in intensity)
        static let emotionChangeThreshold = 2
    }
    
    /// Storage and caching related constants
    struct Storage {
        /// Maximum cache size in bytes
        static let maxCacheSize = 200 * 1024 * 1024 // 200 MB
        
        /// Cache time-to-live in days
        static let cacheTTLDays = 7
        
        /// Maximum storage limit for offline data in bytes
        static let offlineStorageLimit = 500 * 1024 * 1024 // 500 MB
        
        /// Batch size for data synchronization
        static let syncBatchSize = 50
        
        /// JPEG compression quality for images (0.0 to 1.0)
        static let imageCompressionQuality: Float = 0.7
        
        /// Maximum dimension for images (width or height)
        static let maxImageDimension = 1024
    }
    
    /// Feature flag keys and default states for feature toggling
    struct FeatureFlags {
        /// Feature flag for biometric authentication
        static let biometricAuthentication = "feature_biometric_auth"
        
        /// Feature flag for offline mode
        static let offlineMode = "feature_offline_mode"
        
        /// Feature flag for data export functionality
        static let dataExport = "feature_data_export"
        
        /// Feature flag for advanced analytics
        static let advancedAnalytics = "feature_advanced_analytics"
        
        /// Feature flag for tool recommendations
        static let toolRecommendations = "feature_tool_recommendations"
        
        /// Feature flag for journal sharing functionality
        static let journalSharing = "feature_journal_sharing"
        
        /// Feature flag for debug logging
        static let debugLogging = "feature_debug_logging"
        
        /// Default states for feature flags
        static let defaultFeatureStates: [String: Bool] = [
            biometricAuthentication: true,
            offlineMode: true,
            dataExport: true,
            advancedAnalytics: false,
            toolRecommendations: true,
            journalSharing: false,
            debugLogging: false
        ]
    }
    
    /// UserDefaults keys for persistent app settings
    struct UserDefaults {
        /// Key for tracking if user has completed onboarding
        static let hasCompletedOnboarding = "has_completed_onboarding"
        
        /// Key for user's selected language
        static let selectedLanguage = "selected_language"
        
        /// Key for timestamp of last successful sync
        static let lastSyncTimestamp = "last_sync_timestamp"
        
        /// Key for user's notification settings
        static let notificationSettings = "notification_settings"
        
        /// Key for user's general preferences
        static let userPreferences = "user_preferences"
        
        /// Key for feature flag overrides
        static let featureOverrides = "feature_overrides"
        
        /// Key for last used emotion type
        static let lastUsedEmotionType = "last_used_emotion_type"
        
        /// Key for tracking app open count
        static let appOpenCount = "app_open_count"
        
        /// Key for tracking the last app version prompted for review
        static let lastVersionPromptedForReview = "last_version_prompted_for_review"
    }
    
    /// Keychain keys for secure storage of sensitive information
    struct Keychain {
        /// Key for storing the user's access token
        static let accessToken = "access_token"
        
        /// Key for storing the user's refresh token
        static let refreshToken = "refresh_token"
        
        /// Key for storing the user's ID
        static let userId = "user_id"
        
        /// Key for storing the encryption key
        static let encryptionKey = "encryption_key"
        
        /// Key for storing whether biometric authentication is enabled
        static let biometricEnabled = "biometric_enabled"
        
        /// Key for storing the device ID
        static let deviceId = "device_id"
    }
}