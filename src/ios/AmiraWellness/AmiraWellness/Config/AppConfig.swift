//
//  AppConfig.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation

/// A singleton class that provides centralized access to application configuration settings
class AppConfig {
    /// Shared instance for singleton access
    static let shared = AppConfig()
    
    // MARK: - Private Properties
    
    private var currentEnvironment: EnvironmentConfig.Environment
    private var apiBaseURL: String
    private var s3BucketName: String
    private var awsRegion: String
    private var apiVersion: String
    private var accessTokenExpirationMinutes: Int
    private var refreshTokenExpirationDays: Int
    private var encryptionKeyIdentifier: String
    private var useAWSKMS: Bool
    private var rateLimitPerMinute: Int
    private var logLevel: String
    private var defaultLanguage: String
    private var featureFlags: [String: Bool]
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern that loads configuration based on the current environment
    private init() {
        // Initialize with default values
        currentEnvironment = .production // Default, will be updated immediately
        apiBaseURL = ""
        s3BucketName = ""
        awsRegion = ""
        apiVersion = ""
        accessTokenExpirationMinutes = 0
        refreshTokenExpirationDays = 0
        encryptionKeyIdentifier = ""
        useAWSKMS = false
        rateLimitPerMinute = 0
        logLevel = ""
        defaultLanguage = ""
        featureFlags = [:]
        
        // Load configuration
        loadConfiguration()
    }
    
    /// Loads configuration settings based on the current environment
    private func loadConfiguration() {
        // Detect the current environment
        currentEnvironment = EnvironmentConfig.getCurrentEnvironment()
        
        // Set core API and infrastructure properties
        apiBaseURL = EnvironmentConfig.getAPIBaseURL(environment: currentEnvironment)
        s3BucketName = EnvironmentConfig.getS3BucketName(environment: currentEnvironment)
        awsRegion = EnvironmentConfig.getAWSRegion(environment: currentEnvironment)
        
        // Load environment-specific configuration values
        apiVersion = EnvironmentConfig.getAPIVersion(environment: currentEnvironment)
        accessTokenExpirationMinutes = EnvironmentConfig.getAccessTokenExpirationMinutes(environment: currentEnvironment)
        refreshTokenExpirationDays = EnvironmentConfig.getRefreshTokenExpirationDays(environment: currentEnvironment)
        encryptionKeyIdentifier = EnvironmentConfig.getEncryptionKeyIdentifier(environment: currentEnvironment)
        useAWSKMS = EnvironmentConfig.shouldUseAWSKMS(environment: currentEnvironment)
        rateLimitPerMinute = EnvironmentConfig.getRateLimitPerMinute(environment: currentEnvironment)
        logLevel = EnvironmentConfig.getLogLevel(environment: currentEnvironment)
        
        // Set application defaults
        defaultLanguage = AppConstants.App.defaultLanguage
        
        // Initialize feature flags based on environment
        featureFlags = AppConstants.FeatureFlags.defaultFeatureStates
        
        // Apply environment-specific overrides to feature flags
        switch currentEnvironment {
        case .development:
            // Enable all development features
            featureFlags[AppConstants.FeatureFlags.debugLogging] = true
            featureFlags[AppConstants.FeatureFlags.advancedAnalytics] = true
        case .staging:
            // Enable staging test features
            featureFlags[AppConstants.FeatureFlags.debugLogging] = true
        case .production:
            // Production uses the conservative defaults
            break
        }
        
        // Apply any overrides from UserDefaults for testing purposes
        if let savedOverrides = UserDefaults.standard.dictionary(forKey: AppConstants.UserDefaults.featureOverrides) as? [String: Bool] {
            for (key, value) in savedOverrides {
                featureFlags[key] = value
            }
        }
    }
    
    // MARK: - Environment Information
    
    /// Returns the current environment (development, staging, or production)
    ///
    /// - Returns: The current environment
    func getEnvironment() -> EnvironmentConfig.Environment {
        return currentEnvironment
    }
    
    // MARK: - API Configuration
    
    /// Returns the base URL for API requests
    ///
    /// - Returns: The API base URL for the current environment
    func getAPIBaseURL() -> String {
        return apiBaseURL
    }
    
    /// Returns the S3 bucket name for audio storage
    ///
    /// - Returns: The S3 bucket name for the current environment
    func getS3BucketName() -> String {
        return s3BucketName
    }
    
    /// Returns the AWS region for services
    ///
    /// - Returns: The AWS region for the current environment
    func getAWSRegion() -> String {
        return awsRegion
    }
    
    /// Returns the API version to use for requests
    ///
    /// - Returns: The API version string
    func getAPIVersion() -> String {
        return apiVersion
    }
    
    // MARK: - Authentication Configuration
    
    /// Returns the expiration time for access tokens in minutes
    ///
    /// - Returns: Access token expiration in minutes
    func getAccessTokenExpiration() -> Int {
        return accessTokenExpirationMinutes
    }
    
    /// Returns the expiration time for refresh tokens in days
    ///
    /// - Returns: Refresh token expiration in days
    func getRefreshTokenExpiration() -> Int {
        return refreshTokenExpirationDays
    }
    
    // MARK: - Security Configuration
    
    /// Returns the identifier for encryption keys
    ///
    /// - Returns: The encryption key identifier
    func getEncryptionKeyIdentifier() -> String {
        return encryptionKeyIdentifier
    }
    
    /// Returns whether to use AWS KMS for key management
    ///
    /// - Returns: True if AWS KMS should be used
    func shouldUseAWSKMS() -> Bool {
        return useAWSKMS
    }
    
    // MARK: - Performance Configuration
    
    /// Returns the API rate limit per minute
    ///
    /// - Returns: The rate limit per minute
    func getRateLimitPerMinute() -> Int {
        return rateLimitPerMinute
    }
    
    // MARK: - Logging Configuration
    
    /// Returns the logging level for the application
    ///
    /// - Returns: The log level (debug, info, warning, error)
    func getLogLevel() -> String {
        return logLevel
    }
    
    // MARK: - Localization Configuration
    
    /// Returns the default language for the application
    ///
    /// - Returns: The default language code (e.g., 'es')
    func getDefaultLanguage() -> String {
        return defaultLanguage
    }
    
    // MARK: - Feature Flag Management
    
    /// Checks if a specific feature is enabled
    ///
    /// - Parameter featureKey: The key identifying the feature
    /// - Returns: True if the feature is enabled
    func isFeatureEnabled(_ featureKey: String) -> Bool {
        return featureFlags[featureKey] ?? false
    }
    
    /// Returns all feature flags and their status
    ///
    /// - Returns: Dictionary of feature flags and their enabled status
    func getAllFeatureFlags() -> [String: Bool] {
        return featureFlags
    }
    
    /// Overrides a feature flag for testing purposes
    ///
    /// - Parameters:
    ///   - featureKey: The key identifying the feature
    ///   - enabled: Whether the feature should be enabled
    func overrideFeatureFlag(featureKey: String, enabled: Bool) {
        // Only allow overrides in development and staging environments
        guard currentEnvironment != .production else {
            print("Feature flag overrides are not allowed in production")
            return
        }
        
        featureFlags[featureKey] = enabled
        
        // Save the override to UserDefaults for persistence
        var savedOverrides = UserDefaults.standard.dictionary(forKey: AppConstants.UserDefaults.featureOverrides) as? [String: Bool] ?? [:]
        savedOverrides[featureKey] = enabled
        UserDefaults.standard.set(savedOverrides, forKey: AppConstants.UserDefaults.featureOverrides)
    }
    
    /// Resets all feature flag overrides to their default values
    func resetFeatureOverrides() {
        // Reset to default values based on environment
        featureFlags = AppConstants.FeatureFlags.defaultFeatureStates
        
        // Apply environment-specific overrides
        switch currentEnvironment {
        case .development:
            featureFlags[AppConstants.FeatureFlags.debugLogging] = true
            featureFlags[AppConstants.FeatureFlags.advancedAnalytics] = true
        case .staging:
            featureFlags[AppConstants.FeatureFlags.debugLogging] = true
        case .production:
            break
        }
        
        // Clear overrides from UserDefaults
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaults.featureOverrides)
    }
    
    // MARK: - Specialized Configuration
    
    /// Returns audio recording configuration settings
    ///
    /// - Returns: Audio configuration settings
    func getAudioConfiguration() -> AudioConfiguration {
        return AudioConfiguration(
            maxRecordingDurationSeconds: AppConstants.Audio.maxRecordingDurationSeconds,
            audioFormat: AppConstants.Audio.audioFormat,
            sampleRate: AppConstants.Audio.sampleRate,
            bitRate: AppConstants.Audio.bitRate,
            channels: AppConstants.Audio.channels,
            audioFileExtension: AppConstants.Audio.audioFileExtension,
            localAudioDirectory: AppConstants.Audio.localAudioDirectory,
            maxFileSize: AppConstants.Audio.maxFileSize
        )
    }
    
    /// Returns security configuration settings
    ///
    /// - Returns: Security configuration settings
    func getSecurityConfiguration() -> SecurityConfiguration {
        return SecurityConfiguration(
            encryptionAlgorithm: AppConstants.Security.encryptionAlgorithm,
            keySize: AppConstants.Security.keySize,
            keychainServiceName: AppConstants.Security.keychainServiceName,
            keychainAccessGroup: AppConstants.Security.keychainAccessGroup,
            passwordMinLength: AppConstants.Security.passwordMinLength,
            passwordRequiresSpecialCharacter: AppConstants.Security.passwordRequiresSpecialCharacter,
            passwordRequiresNumber: AppConstants.Security.passwordRequiresNumber,
            passwordRequiresUppercase: AppConstants.Security.passwordRequiresUppercase,
            sessionTimeoutMinutes: AppConstants.Security.sessionTimeoutMinutes,
            useAWSKMS: useAWSKMS,
            encryptionKeyIdentifier: encryptionKeyIdentifier
        )
    }
    
    // MARK: - Configuration Management
    
    /// Reloads configuration settings from the environment
    func reloadConfiguration() {
        // Store the old environment for comparison
        let oldEnvironment = currentEnvironment
        
        // Reload all configuration
        loadConfiguration()
        
        // Notify observers if environment changed
        if oldEnvironment != currentEnvironment {
            NotificationCenter.default.post(name: NSNotification.Name("AppConfigurationChanged"), object: self, userInfo: [
                "oldEnvironment": oldEnvironment,
                "newEnvironment": currentEnvironment
            ])
        }
    }
}

/// A structure containing audio recording configuration settings
struct AudioConfiguration {
    let maxRecordingDurationSeconds: Int
    let audioFormat: String
    let sampleRate: Float
    let bitRate: Int
    let channels: Int
    let audioFileExtension: String
    let localAudioDirectory: String
    let maxFileSize: Int
    
    /// Initializes the AudioConfiguration with the provided parameters
    ///
    /// - Parameters:
    ///   - maxRecordingDurationSeconds: Maximum duration for recordings in seconds
    ///   - audioFormat: Format of audio recordings (e.g., "aac")
    ///   - sampleRate: Sample rate for recordings in Hz
    ///   - bitRate: Bit rate for recordings in bits per second
    ///   - channels: Number of audio channels (1 for mono, 2 for stereo)
    ///   - audioFileExtension: File extension for recordings (e.g., "m4a")
    ///   - localAudioDirectory: Directory name for local audio storage
    ///   - maxFileSize: Maximum file size for recordings in bytes
    init(maxRecordingDurationSeconds: Int, audioFormat: String, sampleRate: Float, bitRate: Int, channels: Int, audioFileExtension: String, localAudioDirectory: String, maxFileSize: Int) {
        self.maxRecordingDurationSeconds = maxRecordingDurationSeconds
        self.audioFormat = audioFormat
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.channels = channels
        self.audioFileExtension = audioFileExtension
        self.localAudioDirectory = localAudioDirectory
        self.maxFileSize = maxFileSize
    }
}

/// A structure containing security configuration settings
struct SecurityConfiguration {
    let encryptionAlgorithm: String
    let keySize: Int
    let keychainServiceName: String
    let keychainAccessGroup: String
    let passwordMinLength: Int
    let passwordRequiresSpecialCharacter: Bool
    let passwordRequiresNumber: Bool
    let passwordRequiresUppercase: Bool
    let sessionTimeoutMinutes: Int
    let useAWSKMS: Bool
    let encryptionKeyIdentifier: String
    
    /// Initializes the SecurityConfiguration with the provided parameters
    ///
    /// - Parameters:
    ///   - encryptionAlgorithm: Algorithm used for encryption (e.g., "AES-256-GCM")
    ///   - keySize: Size of encryption keys in bits
    ///   - keychainServiceName: Service name for Keychain access
    ///   - keychainAccessGroup: Access group for shared Keychain items
    ///   - passwordMinLength: Minimum length required for passwords
    ///   - passwordRequiresSpecialCharacter: Whether passwords require special characters
    ///   - passwordRequiresNumber: Whether passwords require numbers
    ///   - passwordRequiresUppercase: Whether passwords require uppercase letters
    ///   - sessionTimeoutMinutes: Time in minutes before sessions time out
    ///   - useAWSKMS: Whether to use AWS KMS for key management
    ///   - encryptionKeyIdentifier: Identifier for encryption keys
    init(encryptionAlgorithm: String, keySize: Int, keychainServiceName: String, keychainAccessGroup: String, passwordMinLength: Int, passwordRequiresSpecialCharacter: Bool, passwordRequiresNumber: Bool, passwordRequiresUppercase: Bool, sessionTimeoutMinutes: Int, useAWSKMS: Bool, encryptionKeyIdentifier: String) {
        self.encryptionAlgorithm = encryptionAlgorithm
        self.keySize = keySize
        self.keychainServiceName = keychainServiceName
        self.keychainAccessGroup = keychainAccessGroup
        self.passwordMinLength = passwordMinLength
        self.passwordRequiresSpecialCharacter = passwordRequiresSpecialCharacter
        self.passwordRequiresNumber = passwordRequiresNumber
        self.passwordRequiresUppercase = passwordRequiresUppercase
        self.sessionTimeoutMinutes = sessionTimeoutMinutes
        self.useAWSKMS = useAWSKMS
        self.encryptionKeyIdentifier = encryptionKeyIdentifier
    }
}