package com.amirawellness.config

import android.content.Context // android version: latest
import android.util.Log // android version: latest
import com.amirawellness.BuildConfig // com.amirawellness version: latest
import com.amirawellness.core.constants.AppConstants

/**
 * Enum defining the possible environment types for the application.
 */
enum class Environment {
    DEVELOPMENT,
    STAGING,
    PRODUCTION
}

/**
 * Main configuration class that provides environment-specific settings.
 * This class is designed as a singleton with private constructor to ensure
 * only one instance exists throughout the application lifecycle.
 */
class EnvironmentConfig private constructor() {
    private val TAG = "EnvironmentConfig"
    private var applicationContext: Context? = null
    private val currentEnvironment: Environment
    
    // Environment-specific configuration properties
    val apiBaseUrl: String
    val analyticsEnabled: Boolean
    val loggingEnabled: Boolean
    val encryptionEnabled: Boolean
    val certificatePinningEnabled: Boolean
    val crashReportingEnabled: Boolean
    val strictModeEnabled: Boolean

    init {
        // Determine current environment based on build type
        currentEnvironment = when (BuildConfig.BUILD_TYPE.lowercase()) {
            "debug" -> Environment.DEVELOPMENT
            "release" -> Environment.PRODUCTION
            "staging" -> Environment.STAGING
            else -> Environment.DEVELOPMENT
        }
        
        // Initialize properties with environment-specific values
        apiBaseUrl = getApiBaseUrl()
        
        // Configure feature flags based on environment
        analyticsEnabled = when (currentEnvironment) {
            Environment.DEVELOPMENT -> false
            Environment.STAGING -> true
            Environment.PRODUCTION -> true
        }
        
        loggingEnabled = when (currentEnvironment) {
            Environment.DEVELOPMENT -> AppConstants.DEBUG_LOGGING_ENABLED
            Environment.STAGING -> true
            Environment.PRODUCTION -> false
        }
        
        encryptionEnabled = when (currentEnvironment) {
            Environment.DEVELOPMENT -> AppConstants.ENCRYPTION_ENABLED
            Environment.STAGING -> true
            Environment.PRODUCTION -> true
        }
        
        certificatePinningEnabled = when (currentEnvironment) {
            Environment.DEVELOPMENT -> false
            Environment.STAGING -> true
            Environment.PRODUCTION -> true
        }
        
        crashReportingEnabled = when (currentEnvironment) {
            Environment.DEVELOPMENT -> false
            Environment.STAGING -> true
            Environment.PRODUCTION -> true
        }
        
        strictModeEnabled = when (currentEnvironment) {
            Environment.DEVELOPMENT -> true
            Environment.STAGING -> false
            Environment.PRODUCTION -> false
        }
        
        Log.d(TAG, "Initialized with environment: $currentEnvironment")
    }
    
    /**
     * Initializes the EnvironmentConfig with application context.
     *
     * @param context Application context used for environment-specific configurations
     */
    fun initialize(context: Context) {
        this.applicationContext = context.applicationContext
        Log.d(TAG, "Initialized context for environment: $currentEnvironment")
        // Perform any context-dependent initialization here
    }
    
    /**
     * Returns the base URL for API requests based on current environment.
     *
     * @return The environment-specific API base URL
     */
    fun getApiBaseUrl(): String {
        return when (currentEnvironment) {
            Environment.DEVELOPMENT -> "https://dev-api.amirawellness.com"
            Environment.STAGING -> "https://staging-api.amirawellness.com"
            Environment.PRODUCTION -> "https://api.amirawellness.com"
        }
    }
    
    /**
     * Returns the current environment.
     *
     * @return The current environment enum value
     */
    fun getEnvironment(): Environment {
        return currentEnvironment
    }
    
    /**
     * Checks if the current environment is DEVELOPMENT.
     *
     * @return True if current environment is DEVELOPMENT, false otherwise
     */
    fun isDevelopmentEnvironment(): Boolean {
        return currentEnvironment == Environment.DEVELOPMENT
    }
    
    /**
     * Checks if the current environment is STAGING.
     *
     * @return True if current environment is STAGING, false otherwise
     */
    fun isStagingEnvironment(): Boolean {
        return currentEnvironment == Environment.STAGING
    }
    
    /**
     * Checks if the current environment is PRODUCTION.
     *
     * @return True if current environment is PRODUCTION, false otherwise
     */
    fun isProductionEnvironment(): Boolean {
        return currentEnvironment == Environment.PRODUCTION
    }
    
    /**
     * Returns the appropriate log level for the current environment.
     *
     * @return Android Log level constant (e.g., Log.VERBOSE, Log.DEBUG)
     */
    fun getLogLevel(): Int {
        return when (currentEnvironment) {
            Environment.DEVELOPMENT -> Log.VERBOSE
            Environment.STAGING -> Log.DEBUG
            Environment.PRODUCTION -> Log.INFO
        }
    }
    
    /**
     * Determines if debug menu should be shown in the UI.
     *
     * @return True if debug menu should be shown, false otherwise
     */
    fun shouldShowDebugMenu(): Boolean {
        return currentEnvironment == Environment.DEVELOPMENT
    }
    
    /**
     * Returns a banner text to display in non-production environments.
     *
     * @return Banner text for non-production environments, null for production
     */
    fun getEnvironmentBanner(): String? {
        return when (currentEnvironment) {
            Environment.DEVELOPMENT -> "DEVELOPMENT"
            Environment.STAGING -> "STAGING"
            Environment.PRODUCTION -> null
        }
    }
}

/**
 * Singleton provider for EnvironmentConfig that ensures only one instance exists.
 * This object is responsible for initializing and providing access to the
 * EnvironmentConfig instance throughout the application.
 */
object EnvironmentConfigProvider {
    private var instance: EnvironmentConfig? = null
    
    /**
     * Initializes the EnvironmentConfig singleton with application context.
     *
     * @param context Application context used for initialization
     */
    fun initialize(context: Context) {
        if (instance == null) {
            instance = EnvironmentConfig()
            instance?.initialize(context)
            Log.d("EnvironmentConfigProvider", "EnvironmentConfig initialized")
        }
    }
    
    /**
     * Returns the singleton instance of EnvironmentConfig.
     *
     * @return The singleton EnvironmentConfig instance
     * @throws IllegalStateException if EnvironmentConfig has not been initialized
     */
    fun getInstance(): EnvironmentConfig {
        return instance ?: throw IllegalStateException(
            "EnvironmentConfig must be initialized before use. Call EnvironmentConfigProvider.initialize(context) first."
        )
    }
    
    /**
     * Resets the singleton instance for testing purposes.
     * This method should only be used in test environments.
     */
    fun resetForTesting() {
        instance = null
        Log.d("EnvironmentConfigProvider", "EnvironmentConfig reset for testing")
    }
}