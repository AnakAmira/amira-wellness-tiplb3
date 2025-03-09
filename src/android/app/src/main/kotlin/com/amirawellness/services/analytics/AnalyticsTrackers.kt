package com.amirawellness.services.analytics

/**
 * Standardized constants for analytics tracking in the Amira Wellness application.
 * This file provides a centralized location for all analytics event names, parameter keys,
 * user properties, screen names, and feature names to ensure consistent tracking
 * across the application while maintaining a privacy-focused approach.
 */

/**
 * Standardized event names for analytics tracking.
 * These event names should be used consistently throughout the application
 * to ensure accurate and consistent analytics data collection without tracking
 * personally identifiable information.
 */
enum class EventName {
    APP_OPEN,
    APP_CLOSE,
    SCREEN_VIEW,
    FEATURE_USED,
    USER_SIGNUP,
    USER_LOGIN,
    USER_LOGOUT,
    JOURNAL_RECORDING_START,
    JOURNAL_RECORDING_COMPLETE,
    JOURNAL_RECORDING_CANCEL,
    EMOTIONAL_CHECK_IN,
    TOOL_VIEW,
    TOOL_COMPLETE,
    TOOL_FAVORITE,
    TOOL_UNFAVORITE,
    ACHIEVEMENT_EARNED,
    STREAK_UPDATED,
    SETTINGS_CHANGED,
    NOTIFICATION_RECEIVED,
    NOTIFICATION_OPENED,
    ERROR_OCCURRED
}

/**
 * Standardized user properties for analytics segmentation.
 * These properties help analyze user behavior patterns while maintaining privacy
 * by avoiding the collection of personally identifiable information.
 * Used for segmentation in analytics reports to measure engagement and trends.
 */
enum class UserProperty {
    SUBSCRIPTION_TIER,
    LANGUAGE_PREFERENCE,
    DAYS_SINCE_INSTALL,
    DAYS_ACTIVE,
    CURRENT_STREAK,
    LONGEST_STREAK,
    JOURNAL_COUNT,
    CHECKIN_COUNT,
    TOOL_USAGE_COUNT,
    ACHIEVEMENT_COUNT,
    NOTIFICATIONS_ENABLED,
    THEME_PREFERENCE
}

/**
 * Standardized parameter keys for analytics events.
 * These keys should be used when adding additional data to analytics events
 * to maintain consistency in reporting and support business metrics tracking.
 * All parameters should avoid including sensitive or personally identifiable information.
 */
enum class ParameterKey {
    SCREEN_NAME,
    SCREEN_CLASS,
    FEATURE_NAME,
    DURATION_SECONDS,
    EMOTION_TYPE,
    EMOTION_INTENSITY,
    EMOTION_CONTEXT,
    EMOTION_BEFORE,
    EMOTION_AFTER,
    TOOL_ID,
    TOOL_CATEGORY,
    ACHIEVEMENT_ID,
    ACHIEVEMENT_NAME,
    STREAK_DAYS,
    IS_NEW_RECORD,
    SETTING_NAME,
    SETTING_VALUE,
    ERROR_CODE,
    ERROR_MESSAGE,
    ERROR_CONTEXT,
    NOTIFICATION_TYPE,
    NOTIFICATION_ID
}

/**
 * Standardized screen names for screen view tracking.
 * These names should be used when tracking screen views to ensure
 * consistent navigation reporting and measure feature discovery.
 * Supports the tracking of user journeys through the application.
 */
enum class ScreenName {
    ONBOARDING,
    LOGIN,
    REGISTER,
    FORGOT_PASSWORD,
    HOME,
    JOURNAL_LIST,
    JOURNAL_DETAIL,
    RECORD_JOURNAL,
    EMOTIONAL_CHECKIN,
    EMOTIONAL_CHECKIN_RESULT,
    TOOL_LIBRARY,
    TOOL_CATEGORY,
    TOOL_DETAIL,
    TOOL_IN_PROGRESS,
    TOOL_COMPLETION,
    FAVORITES,
    PROGRESS_DASHBOARD,
    ACHIEVEMENTS,
    EMOTIONAL_TRENDS,
    PROFILE,
    SETTINGS,
    NOTIFICATION_SETTINGS,
    PRIVACY_SETTINGS,
    DATA_EXPORT
}

/**
 * Standardized feature names for feature usage tracking.
 * These names should be used when tracking feature engagement to measure
 * adoption and usage patterns of core functionality.
 * Supports the product goal of 70% of users completing at least 3 voice
 * journaling sessions per week and other engagement metrics.
 */
enum class FeatureName {
    VOICE_JOURNALING,
    EMOTIONAL_CHECKIN,
    BREATHING_EXERCISE,
    MEDITATION,
    JOURNALING_PROMPT,
    SOMATIC_EXERCISE,
    GRATITUDE_EXERCISE,
    PROGRESS_TRACKING,
    STREAK_TRACKING,
    ACHIEVEMENTS,
    EMOTIONAL_TRENDS,
    TOOL_FAVORITES,
    DATA_EXPORT,
    SETTINGS
}