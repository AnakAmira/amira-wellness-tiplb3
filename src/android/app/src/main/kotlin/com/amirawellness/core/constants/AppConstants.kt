package com.amirawellness.core.constants

import android.os.Environment // android version: latest

/**
 * AppConstants
 *
 * Defines application-wide constants for the Amira Wellness Android application.
 * These constants are organized by functional area and used throughout the application
 * to maintain consistency and provide centralized configuration.
 */
object AppConstants {
    // Application identification
    const val APP_NAME = "Amira Wellness"
    const val VERSION_NAME = "1.0.0"
    const val VERSION_CODE = 1
    
    // Global flags
    const val DEBUG_LOGGING_ENABLED = true
    const val ENCRYPTION_ENABLED = true
    const val DEFAULT_LANGUAGE = "es" // Spanish as default language
    
    /**
     * File paths for various application data storage
     */
    object FILE_PATHS {
        const val ROOT_DIRECTORY = "AmiraWellness"
        const val AUDIO_DIRECTORY = "$ROOT_DIRECTORY/Audio"
        const val EXPORT_DIRECTORY = "$ROOT_DIRECTORY/Exports"
        const val CACHE_DIRECTORY = "$ROOT_DIRECTORY/Cache"
        const val LOGS_DIRECTORY = "$ROOT_DIRECTORY/Logs"
        const val TEMP_DIRECTORY = "$ROOT_DIRECTORY/Temp"
        
        /**
         * Returns the absolute path to the app's external storage directory
         */
        fun getExternalStorageDirectory(): String = 
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS).absolutePath + "/" + ROOT_DIRECTORY
    }
    
    /**
     * Settings for audio recording and playback
     */
    object AUDIO_SETTINGS {
        const val AUDIO_FORMAT = "AAC"
        const val SAMPLE_RATE = 44100 // 44.1 kHz
        const val CHANNELS = 1 // Mono
        const val BIT_RATE = 128000 // 128 kbps
        const val MAX_RECORDING_DURATION_MS = 30 * 60 * 1000L // 30 minutes
        const val MIN_RECORDING_DURATION_MS = 3 * 1000L // 3 seconds
        const val WAVEFORM_UPDATE_INTERVAL_MS = 100L // 100ms update for waveform visualization
        const val AUDIO_EXTENSION = ".aac"
        const val ENCRYPTED_AUDIO_EXTENSION = ".eaac" // Extension for encrypted audio files
    }
    
    /**
     * Timeout values for various operations
     */
    object TIMEOUTS {
        const val NETWORK_TIMEOUT_MS = 30000L // 30 seconds
        const val UPLOAD_TIMEOUT_MS = 60000L // 60 seconds
        const val DOWNLOAD_TIMEOUT_MS = 60000L // 60 seconds
        const val CACHE_EXPIRY_MS = 24 * 60 * 60 * 1000L // 24 hours
        const val SESSION_TIMEOUT_MS = 30 * 60 * 1000L // 30 minutes
        const val INACTIVITY_TIMEOUT_MS = 5 * 60 * 1000L // 5 minutes
        const val SPLASH_SCREEN_DURATION_MS = 2000L // 2 seconds
    }
    
    /**
     * Settings for data synchronization
     */
    object SYNC_SETTINGS {
        const val AUTO_SYNC_ENABLED = true
        const val SYNC_INTERVAL_MS = 15 * 60 * 1000L // 15 minutes
        const val SYNC_ON_APP_START = true
        const val SYNC_ON_NETWORK_AVAILABLE = true
        const val MAX_SYNC_RETRY_COUNT = 3
        const val SYNC_RETRY_DELAY_MS = 60 * 1000L // 1 minute
        const val BACKGROUND_SYNC_ENABLED = true
        const val SYNC_NOTIFICATION_ENABLED = false
    }
    
    /**
     * Settings for data encryption
     */
    object ENCRYPTION_SETTINGS {
        const val ALGORITHM = "AES/GCM/NoPadding"
        const val KEY_SIZE = 256
        const val IV_SIZE = 12 // Initialization vector size in bytes
        const val GCM_TAG_LENGTH = 128 // Authentication tag length in bits
        const val KEY_DERIVATION_ALGORITHM = "PBKDF2WithHmacSHA256"
        const val KEY_DERIVATION_ITERATIONS = 10000
        const val SALT_SIZE_BYTES = 16
        const val BIOMETRIC_ENCRYPTION_ENABLED = true
        const val EXPORT_ENCRYPTION_ENABLED = true
    }
    
    /**
     * UI-related constants and settings
     */
    object UI_SETTINGS {
        const val ANIMATION_DURATION_MS = 300L
        const val DEBOUNCE_DELAY_MS = 300L
        const val PAGINATION_PAGE_SIZE = 20
        const val MAX_JOURNAL_TITLE_LENGTH = 100
        const val MAX_EMOTION_NOTE_LENGTH = 500
        const val DEFAULT_THEME = "system" // Options: light, dark, system
        const val HAPTIC_FEEDBACK_ENABLED = true
        const val SHOW_ONBOARDING_ONCE = true
    }
    
    /**
     * Settings for analytics and tracking
     */
    object ANALYTICS_SETTINGS {
        const val ANALYTICS_ENABLED = true
        const val CRASH_REPORTING_ENABLED = true
        const val USER_METRICS_ENABLED = true
        const val PERFORMANCE_MONITORING_ENABLED = true
        const val SESSION_TIMEOUT_SECONDS = 1800 // 30 minutes
        const val MINIMUM_SESSION_DURATION_SECONDS = 10
        const val SAMPLING_RATE = 1.0 // 100% of events are tracked
    }
    
    /**
     * Deep link URI schemes for the application
     */
    object DEEP_LINK_SCHEMES {
        const val APP_SCHEME = "amirawellness"
        const val UNIVERSAL_LINK_DOMAIN = "app.amirawellness.com"
        const val JOURNAL_PATH = "journal"
        const val TOOL_PATH = "tool"
        const val CHECKIN_PATH = "checkin"
        const val ACHIEVEMENT_PATH = "achievement"
        const val SETTINGS_PATH = "settings"
    }
}