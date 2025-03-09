//
//  NotificationConstants.swift
//  AmiraWellness
//
//  Created for Amira Wellness iOS application
//

import Foundation // iOS SDK

/// Constants related to notifications in the Amira Wellness application
struct NotificationConstants {
    
    /// Notification category identifiers for different types of notifications
    struct Categories {
        static let dailyReminder = "daily_reminder"
        static let streakReminder = "streak_reminder"
        static let achievement = "achievement"
        static let affirmation = "affirmation"
        static let wellnessTip = "wellness_tip"
        static let appUpdate = "app_update"
    }
    
    /// Notification action identifiers for user interactions with notifications
    struct Actions {
        static let open = "open_action"
        static let dismiss = "dismiss_action"
        static let snooze = "snooze_action"
        static let complete = "complete_action"
        static let viewDetails = "view_details_action"
    }
    
    /// Keys for notification user info dictionary
    struct UserInfo {
        static let notificationId = "notification_id"
        static let notificationType = "notification_type"
        static let relatedEntityType = "related_entity_type"
        static let relatedEntityId = "related_entity_id"
        static let deepLink = "deep_link"
        static let timestamp = "timestamp"
    }
    
    /// Default notification settings for the application
    struct DefaultSettings {
        static let dailyRemindersEnabled = true
        static let streakRemindersEnabled = true
        static let achievementsEnabled = true
        static let affirmationsEnabled = true
        static let wellnessTipsEnabled = false
        static let appUpdatesEnabled = true
        static let defaultReminderHour = 10
        static let defaultReminderMinute = 0
        static let defaultReminderDays = [1, 2, 3, 4, 5, 6, 7]
    }
}