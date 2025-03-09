package com.amirawellness.core.constants

import android.app.NotificationManager // android latest

/**
 * Defines constants related to notifications in the Amira Wellness application.
 * This file serves as a central reference for all notification-related constants
 * used throughout the application.
 */
object NotificationConstants {

    /**
     * Constants for different types of notifications supported by the application.
     */
    object NOTIFICATION_TYPES {
        const val DAILY_REMINDER = "daily_reminder"
        const val STREAK_REMINDER = "streak_reminder"
        const val ACHIEVEMENT = "achievement"
        const val AFFIRMATION = "affirmation"
        const val WELLNESS_TIP = "wellness_tip"
        const val JOURNAL_REMINDER = "journal_reminder"
        const val EMOTIONAL_CHECKIN_REMINDER = "emotional_checkin_reminder"
        const val TOOL_RECOMMENDATION = "tool_recommendation"
        const val APP_UPDATE = "app_update"
    }

    /**
     * Notification channel definitions for Android O+ devices.
     */
    object CHANNELS {
        /**
         * Channel for daily reminders and check-in notifications.
         */
        object REMINDERS {
            const val ID = "reminders_channel"
            const val NAME = "Reminders"
            const val DESCRIPTION = "Daily reminders and check-in notifications"
            const val IMPORTANCE = NotificationManager.IMPORTANCE_HIGH
        }

        /**
         * Channel for achievement and streak notifications.
         */
        object ACHIEVEMENTS {
            const val ID = "achievements_channel"
            const val NAME = "Achievements"
            const val DESCRIPTION = "Achievement and streak notifications"
            const val IMPORTANCE = NotificationManager.IMPORTANCE_DEFAULT
        }

        /**
         * Channel for daily affirmations and wellness tips.
         */
        object AFFIRMATIONS {
            const val ID = "affirmations_channel"
            const val NAME = "Affirmations"
            const val DESCRIPTION = "Daily affirmations and wellness tips"
            const val IMPORTANCE = NotificationManager.IMPORTANCE_DEFAULT
        }

        /**
         * Channel for tool recommendations.
         */
        object RECOMMENDATIONS {
            const val ID = "recommendations_channel"
            const val NAME = "Recommendations"
            const val DESCRIPTION = "Tool recommendations based on your emotional state"
            const val IMPORTANCE = NotificationManager.IMPORTANCE_LOW
        }

        /**
         * Channel for app updates and system notifications.
         */
        object UPDATES {
            const val ID = "updates_channel"
            const val NAME = "Updates"
            const val DESCRIPTION = "App updates and system notifications"
            const val IMPORTANCE = NotificationManager.IMPORTANCE_LOW
        }
    }

    /**
     * Base notification IDs for different notification types.
     */
    object NOTIFICATION_IDS {
        const val DAILY_REMINDER_ID = 1000
        const val STREAK_REMINDER_ID = 2000
        const val ACHIEVEMENT_ID = 3000
        const val AFFIRMATION_ID = 4000
        const val WELLNESS_TIP_ID = 5000
        const val JOURNAL_REMINDER_ID = 6000
        const val EMOTIONAL_CHECKIN_ID = 7000
        const val TOOL_RECOMMENDATION_ID = 8000
        const val APP_UPDATE_ID = 9000
    }

    /**
     * Action identifiers for notification interactions.
     */
    object ACTIONS {
        const val ACTION_DISMISS = "com.amirawellness.action.DISMISS"
        const val ACTION_JOURNAL = "com.amirawellness.action.JOURNAL"
        const val ACTION_CHECKIN = "com.amirawellness.action.CHECKIN"
        const val ACTION_VIEW_TOOL = "com.amirawellness.action.VIEW_TOOL"
        const val ACTION_VIEW_ACHIEVEMENT = "com.amirawellness.action.VIEW_ACHIEVEMENT"
        const val ACTION_VIEW_STREAK = "com.amirawellness.action.VIEW_STREAK"
        const val ACTION_SNOOZE = "com.amirawellness.action.SNOOZE"
        const val ACTION_MARK_AS_READ = "com.amirawellness.action.MARK_AS_READ"
    }

    /**
     * Keys for extras passed in notification intents.
     */
    object EXTRA_KEYS {
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_NOTIFICATION_TYPE = "notification_type"
        const val EXTRA_ENTITY_TYPE = "entity_type"
        const val EXTRA_ENTITY_ID = "entity_id"
        const val EXTRA_DEEP_LINK = "deep_link"
        const val EXTRA_SNOOZE_DURATION = "snooze_duration"
    }

    /**
     * Entity types that can be referenced in notifications.
     */
    object ENTITY_TYPES {
        const val JOURNAL = "journal"
        const val EMOTIONAL_CHECKIN = "emotional_checkin"
        const val TOOL = "tool"
        const val ACHIEVEMENT = "achievement"
        const val STREAK = "streak"
        const val USER = "user"
    }

    /**
     * Default notification settings.
     */
    object DEFAULT_SETTINGS {
        const val DEFAULT_REMINDER_HOUR = 9
        const val DEFAULT_REMINDER_MINUTE = 0
        const val DEFAULT_AFFIRMATION_HOUR = 8
        const val DEFAULT_AFFIRMATION_MINUTE = 0
        const val DEFAULT_STREAK_REMINDER_HOUR = 20
        const val DEFAULT_STREAK_REMINDER_MINUTE = 0
        val DEFAULT_REMINDER_DAYS = setOf("1", "2", "3", "4", "5", "6", "7")
        const val DEFAULT_SNOOZE_DURATION_MINUTES = 30
        const val MAX_NOTIFICATION_COUNT = 50
    }

    /**
     * Tags for WorkManager workers.
     */
    object WORKER_TAGS {
        const val NOTIFICATION_WORKER_TAG = "notification_worker"
        const val DAILY_REMINDER_WORKER_TAG = "daily_reminder_worker"
        const val STREAK_REMINDER_WORKER_TAG = "streak_reminder_worker"
        const val AFFIRMATION_WORKER_TAG = "affirmation_worker"
        const val WELLNESS_TIP_WORKER_TAG = "wellness_tip_worker"
        const val ONE_TIME_NOTIFICATION_WORKER_TAG = "one_time_notification_worker"
    }
}