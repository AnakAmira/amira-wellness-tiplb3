package com.amirawellness.config

import android.content.Context // android version: latest
import android.os.Build // android version: latest
import android.util.Log // android version: latest
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.config.Environment
import com.amirawellness.config.EnvironmentConfig
import com.amirawellness.config.EnvironmentConfigProvider

/**
 * Main configuration class that provides application-wide settings and feature flags
 * for the Amira Wellness application. This singleton class centralizes configuration
 * management and serves as a single source of truth for app settings.
 * 
 * It handles:
 * - Feature flags management
 * - Device compatibility checks
 * - Environment-specific configurations
 * - Audio recording settings
 * - Privacy and encryption settings
 */
class AppConfig private constructor() {
    private val TAG = "AppConfig"
    private var applicationContext: Context? = null
    
    // Application identification
    val appName = AppConstants.APP_NAME
    val appVersion = AppConstants.VERSION_NAME
    val defaultLanguage = AppConstants.DEFAULT_LANGUAGE
    
    // Feature flags
    val isEncryptionEnabled: Boolean
    val isOfflineModeEnabled: Boolean
    val isAnalyticsEnabled: Boolean
    val isCrashReportingEnabled: Boolean
    val isDebugLoggingEnabled: Boolean
    
    // Device compatibility
    val minSupportedAndroidVersion = Build.VERSION_CODES.O // Android 8.0
    val recommendedAndroidVersion = Build.VERSION_CODES.R // Android 11
    
    // Audio recording settings
    val audioSampleRate = AppConstants.AUDIO_SETTINGS.SAMPLE_RATE
    val audioBitrate = AppConstants.AUDIO_SETTINGS.BIT_RATE
    val audioChannels = AppConstants.AUDIO_SETTINGS.CHANNELS
    val maxRecordingDurationSeconds = AppConstants.AUDIO_SETTINGS.MAX_RECORDING_DURATION_MS / 1000
    val minRecordingDurationSeconds = AppConstants.AUDIO_SETTINGS.MIN_RECORDING_DURATION_MS / 1000
    
    init {
        val environmentConfig = EnvironmentConfigProvider.getInstance()
        
        // Configure feature flags based on environment
        isEncryptionEnabled = environmentConfig.encryptionEnabled
        isAnalyticsEnabled = environmentConfig.analyticsEnabled
        isCrashReportingEnabled = environmentConfig.crashReportingEnabled
        isDebugLoggingEnabled = environmentConfig.loggingEnabled
        
        // Default to enabled for offline mode in all environments
        isOfflineModeEnabled = true
        
        Log.d(TAG, "AppConfig initialized with app version: $appVersion")
    }
    
    /**
     * Initializes the AppConfig with application context.
     *
     * @param context Application context used for device-specific checks
     */
    fun initialize(context: Context) {
        this.applicationContext = context.applicationContext
        Log.d(TAG, "AppConfig initialized with context for $appName $appVersion")
        // Perform any context-dependent initialization here
    }
    
    /**
     * Checks if the current device meets minimum requirements for the application.
     * Requirements include:
     * - Android OS version at or above minSupportedAndroidVersion
     * - Device has a microphone for voice journaling
     *
     * @return True if device is supported, false otherwise
     */
    fun isDeviceSupported(): Boolean {
        // Check SDK version
        val sdkVersionSupported = Build.VERSION.SDK_INT >= minSupportedAndroidVersion
        
        // Check for microphone availability (critical for voice journaling)
        val hasMicrophone = applicationContext?.packageManager?.hasSystemFeature(
            android.content.pm.PackageManager.FEATURE_MICROPHONE
        ) ?: false
        
        return sdkVersionSupported && hasMicrophone
    }
    
    /**
     * Returns audio recording settings as a map for easy access.
     * These settings are used for voice journaling functionality.
     *
     * @return Map containing audio recording settings
     */
    fun getAudioRecordingSettings(): Map<String, Any> {
        return mapOf(
            "sampleRate" to audioSampleRate,
            "bitrate" to audioBitrate,
            "channels" to audioChannels,
            "format" to AppConstants.AUDIO_SETTINGS.AUDIO_FORMAT,
            "maxDurationSeconds" to maxRecordingDurationSeconds,
            "minDurationSeconds" to minRecordingDurationSeconds,
            "fileExtension" to AppConstants.AUDIO_SETTINGS.AUDIO_EXTENSION,
            "encryptedFileExtension" to AppConstants.AUDIO_SETTINGS.ENCRYPTED_AUDIO_EXTENSION,
            "waveformUpdateIntervalMs" to AppConstants.AUDIO_SETTINGS.WAVEFORM_UPDATE_INTERVAL_MS
        )
    }
    
    /**
     * Returns a map of feature flags indicating which features are enabled.
     * These flags can be used to conditionally enable or disable features
     * throughout the application.
     *
     * @return Map of feature flags and their enabled status
     */
    fun getFeatureFlags(): Map<String, Boolean> {
        return mapOf(
            "encryption" to isEncryptionEnabled,
            "offlineMode" to isOfflineModeEnabled,
            "analytics" to isAnalyticsEnabled,
            "crashReporting" to isCrashReportingEnabled,
            "debugLogging" to isDebugLoggingEnabled,
            "biometricEncryption" to AppConstants.ENCRYPTION_SETTINGS.BIOMETRIC_ENCRYPTION_ENABLED,
            "autoSync" to AppConstants.SYNC_SETTINGS.AUTO_SYNC_ENABLED,
            "backgroundSync" to AppConstants.SYNC_SETTINGS.BACKGROUND_SYNC_ENABLED,
            "hapticFeedback" to AppConstants.UI_SETTINGS.HAPTIC_FEEDBACK_ENABLED,
            "userMetrics" to AppConstants.ANALYTICS_SETTINGS.USER_METRICS_ENABLED,
            "performanceMonitoring" to AppConstants.ANALYTICS_SETTINGS.PERFORMANCE_MONITORING_ENABLED,
            "exportEncryption" to AppConstants.ENCRYPTION_SETTINGS.EXPORT_ENCRYPTION_ENABLED
        )
    }
    
    /**
     * Determines if debug information should be shown in the UI.
     * Debug information is only shown in non-production environments
     * and when debug logging is enabled.
     *
     * @return True if debug info should be shown, false otherwise
     */
    fun shouldShowDebugInfo(): Boolean {
        val environmentConfig = EnvironmentConfigProvider.getInstance()
        return (environmentConfig.getEnvironment() == Environment.DEVELOPMENT || 
                environmentConfig.getEnvironment() == Environment.STAGING) &&
               isDebugLoggingEnabled
    }
    
    /**
     * Returns information about the current device.
     * This is useful for debugging and support purposes.
     *
     * @return Map containing device information
     */
    fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT.toString(),
            "supportStatus" to if (isDeviceSupported()) "Supported" else "Unsupported",
            "language" to defaultLanguage,
            "appVersion" to appVersion
        )
    }
}

/**
 * Singleton provider for AppConfig that ensures only one instance exists.
 * This object is responsible for initializing and providing access to the
 * AppConfig instance throughout the application.
 */
object AppConfigProvider {
    private var instance: AppConfig? = null
    
    /**
     * Initializes the AppConfig singleton with application context.
     * This must be called before any attempts to access the AppConfig instance.
     *
     * @param context Application context used for initialization
     */
    fun initialize(context: Context) {
        if (instance == null) {
            instance = AppConfig()
            instance?.initialize(context)
            Log.d("AppConfigProvider", "AppConfig initialized")
        }
    }
    
    /**
     * Returns the singleton instance of AppConfig.
     *
     * @return The singleton AppConfig instance
     * @throws IllegalStateException if AppConfig has not been initialized
     */
    fun getInstance(): AppConfig {
        return instance ?: throw IllegalStateException(
            "AppConfig must be initialized before use. Call AppConfigProvider.initialize(context) first."
        )
    }
    
    /**
     * Resets the singleton instance for testing purposes.
     * This method should only be used in test environments.
     */
    fun resetForTesting() {
        instance = null
        Log.d("AppConfigProvider", "AppConfig reset for testing")
    }
}