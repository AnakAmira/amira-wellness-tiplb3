package com.amirawellness.core.constants

/**
 * Constants for shared preferences keys used throughout the Amira Wellness application.
 * This file organizes preference keys into logical groups based on functionality,
 * ensuring consistent access to user preferences, authentication data, application settings,
 * and other persistent data.
 */
object PreferenceConstants {

    /**
     * Names of SharedPreferences files used by the application
     */
    object PREFERENCE_FILES {
        const val USER_PREFS = "user_preferences"
        const val AUTH_PREFS = "auth_preferences"
        const val NOTIFICATION_PREFS = "notification_preferences"
        const val PRIVACY_PREFS = "privacy_preferences"
        const val APP_PREFS = "app_preferences"
        const val JOURNAL_PREFS = "journal_preferences"
        const val TOOL_PREFS = "tool_preferences"
        const val SYNC_PREFS = "sync_preferences"
    }

    /**
     * Keys for user profile and personal preferences
     */
    object USER_PREFERENCES {
        const val USER_ID = "user_id"
        const val USER_NAME = "user_name"
        const val USER_EMAIL = "user_email"
        const val PROFILE_COMPLETED = "profile_completed"
        const val LANGUAGE = "language"
        const val THEME = "theme"
        const val HAPTIC_FEEDBACK = "haptic_feedback"
        const val ONBOARDING_COMPLETED = "onboarding_completed"
        const val LAST_ACTIVE_DATE = "last_active_date"
    }

    /**
     * Keys for authentication and security preferences
     */
    object AUTH_PREFERENCES {
        const val ACCESS_TOKEN = "access_token"
        const val REFRESH_TOKEN = "refresh_token"
        const val TOKEN_EXPIRY = "token_expiry"
        const val IS_LOGGED_IN = "is_logged_in"
        const val BIOMETRIC_ENABLED = "biometric_enabled"
        const val DEVICE_ID = "device_id"
        const val LAST_LOGIN_DATE = "last_login_date"
        const val SESSION_TIMEOUT = "session_timeout"
        const val ENCRYPTION_KEY_SALT = "encryption_key_salt"
    }

    /**
     * Keys for notification settings and preferences
     */
    object NOTIFICATION_PREFERENCES {
        const val DAILY_REMINDERS_ENABLED = "daily_reminders_enabled"
        const val STREAK_REMINDERS_ENABLED = "streak_reminders_enabled"
        const val ACHIEVEMENTS_ENABLED = "achievements_enabled"
        const val AFFIRMATIONS_ENABLED = "affirmations_enabled"
        const val WELLNESS_TIPS_ENABLED = "wellness_tips_enabled"
        const val APP_UPDATES_ENABLED = "app_updates_enabled"
        const val REMINDER_TIME = "reminder_time"
        const val REMINDER_DAYS = "reminder_days"
        const val FCM_TOKEN = "fcm_token"
        const val NOTIFICATION_SOUND = "notification_sound"
        const val NOTIFICATION_VIBRATION = "notification_vibration"
    }

    /**
     * Keys for privacy and data sharing preferences
     */
    object PRIVACY_PREFERENCES {
        const val ANALYTICS_ENABLED = "analytics_enabled"
        const val CRASH_REPORTING_ENABLED = "crash_reporting_enabled"
        const val DATA_COLLECTION_CONSENT = "data_collection_consent"
        const val PERSONALIZED_CONTENT = "personalized_content"
        const val EXPORT_DATA_ENCRYPTION = "export_data_encryption"
        const val PRIVACY_POLICY_ACCEPTED = "privacy_policy_accepted"
        const val PRIVACY_POLICY_VERSION = "privacy_policy_version"
        const val TERMS_ACCEPTED = "terms_accepted"
        const val TERMS_VERSION = "terms_version"
    }

    /**
     * Keys for general application settings and state
     */
    object APP_PREFERENCES {
        const val FIRST_LAUNCH = "first_launch"
        const val LAST_VERSION_CODE = "last_version_code"
        const val LAST_VERSION_NAME = "last_version_name"
        const val LAST_CRASH_TIMESTAMP = "last_crash_timestamp"
        const val CACHE_EXPIRY = "cache_expiry"
        const val DEBUG_MODE = "debug_mode"
        const val LAST_MAINTENANCE_CHECK = "last_maintenance_check"
        const val STORAGE_USAGE_BYTES = "storage_usage_bytes"
        const val RATE_APP_PROMPTED = "rate_app_prompted"
    }

    /**
     * Keys for voice journaling preferences and settings
     */
    object JOURNAL_PREFERENCES {
        const val AUTO_SAVE_ENABLED = "auto_save_enabled"
        const val MAX_RECORDING_DURATION = "max_recording_duration"
        const val AUDIO_QUALITY = "audio_quality"
        const val WAVEFORM_VISUALIZATION = "waveform_visualization"
        const val DEFAULT_JOURNAL_TITLE = "default_journal_title"
        const val LAST_JOURNAL_DATE = "last_journal_date"
        const val JOURNAL_SORT_ORDER = "journal_sort_order"
        const val JOURNAL_FILTER_TYPE = "journal_filter_type"
        const val JOURNAL_COUNT = "journal_count"
    }

    /**
     * Keys for tool library preferences and settings
     */
    object TOOL_PREFERENCES {
        const val FAVORITE_TOOLS = "favorite_tools"
        const val RECENTLY_USED_TOOLS = "recently_used_tools"
        const val TOOL_SORT_ORDER = "tool_sort_order"
        const val TOOL_FILTER_CATEGORY = "tool_filter_category"
        const val TOOL_USAGE_COUNT = "tool_usage_count"
        const val TOOL_COMPLETION_RATE = "tool_completion_rate"
        const val LAST_TOOL_SYNC = "last_tool_sync"
        const val CACHED_TOOL_IDS = "cached_tool_ids"
        const val TOOL_RECOMMENDATIONS_ENABLED = "tool_recommendations_enabled"
    }

    /**
     * Keys for data synchronization preferences and settings
     */
    object SYNC_PREFERENCES {
        const val AUTO_SYNC_ENABLED = "auto_sync_enabled"
        const val SYNC_ON_WIFI_ONLY = "sync_on_wifi_only"
        const val LAST_SYNC_TIMESTAMP = "last_sync_timestamp"
        const val SYNC_INTERVAL = "sync_interval"
        const val PENDING_UPLOADS = "pending_uploads"
        const val SYNC_ERRORS = "sync_errors"
        const val BACKGROUND_SYNC_ENABLED = "background_sync_enabled"
        const val SYNC_NOTIFICATION_ENABLED = "sync_notification_enabled"
        const val DATA_USAGE_LIMIT = "data_usage_limit"
    }
}