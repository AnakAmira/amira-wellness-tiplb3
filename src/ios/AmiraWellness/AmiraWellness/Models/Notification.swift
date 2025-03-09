//
//  Notification.swift
//  AmiraWellness
//
//  Created for Amira Wellness iOS application
//

import Foundation // iOS SDK

/// Enumeration of different notification types supported by the application
enum NotificationType: String, Codable, CaseIterable {
    case dailyReminder
    case streakReminder
    case achievement
    case affirmation
    case wellnessTip
    case appUpdate
    
    /// Returns the corresponding notification category identifier
    var categoryIdentifier: String {
        switch self {
        case .dailyReminder:
            return NotificationConstants.Categories.dailyReminder
        case .streakReminder:
            return NotificationConstants.Categories.streakReminder
        case .achievement:
            return NotificationConstants.Categories.achievement
        case .affirmation:
            return NotificationConstants.Categories.affirmation
        case .wellnessTip:
            return NotificationConstants.Categories.wellnessTip
        case .appUpdate:
            return NotificationConstants.Categories.appUpdate
        }
    }
}

/// Structure representing user preferences for notifications
struct NotificationPreferences: Codable, Equatable {
    var dailyRemindersEnabled: Bool
    var streakRemindersEnabled: Bool
    var achievementsEnabled: Bool
    var affirmationsEnabled: Bool
    var wellnessTipsEnabled: Bool
    var appUpdatesEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var reminderDays: [Int]
    
    /// Initializes notification preferences with provided values
    init(
        dailyRemindersEnabled: Bool,
        streakRemindersEnabled: Bool,
        achievementsEnabled: Bool,
        affirmationsEnabled: Bool,
        wellnessTipsEnabled: Bool,
        appUpdatesEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        reminderDays: [Int]
    ) {
        self.dailyRemindersEnabled = dailyRemindersEnabled
        self.streakRemindersEnabled = streakRemindersEnabled
        self.achievementsEnabled = achievementsEnabled
        self.affirmationsEnabled = affirmationsEnabled
        self.wellnessTipsEnabled = wellnessTipsEnabled
        self.appUpdatesEnabled = appUpdatesEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderDays = reminderDays
    }
    
    /// Returns default notification preferences
    static var defaultPreferences: NotificationPreferences {
        return NotificationPreferences(
            dailyRemindersEnabled: NotificationConstants.DefaultSettings.dailyRemindersEnabled,
            streakRemindersEnabled: NotificationConstants.DefaultSettings.streakRemindersEnabled,
            achievementsEnabled: NotificationConstants.DefaultSettings.achievementsEnabled,
            affirmationsEnabled: NotificationConstants.DefaultSettings.affirmationsEnabled,
            wellnessTipsEnabled: NotificationConstants.DefaultSettings.wellnessTipsEnabled,
            appUpdatesEnabled: NotificationConstants.DefaultSettings.appUpdatesEnabled,
            reminderHour: NotificationConstants.DefaultSettings.defaultReminderHour,
            reminderMinute: NotificationConstants.DefaultSettings.defaultReminderMinute,
            reminderDays: NotificationConstants.DefaultSettings.defaultReminderDays
        )
    }
    
    /// Converts preferences to a dictionary for API requests
    func toDictionary() -> [String: Any] {
        return [
            "dailyRemindersEnabled": dailyRemindersEnabled,
            "streakRemindersEnabled": streakRemindersEnabled,
            "achievementsEnabled": achievementsEnabled,
            "affirmationsEnabled": affirmationsEnabled,
            "wellnessTipsEnabled": wellnessTipsEnabled,
            "appUpdatesEnabled": appUpdatesEnabled,
            "reminderHour": reminderHour,
            "reminderMinute": reminderMinute,
            "reminderDays": reminderDays
        ]
    }
}

/// A class representing a notification received by the user
class Notification {
    let id: String
    let notificationType: NotificationType
    let title: String
    let content: String
    let timestamp: Date
    let relatedEntityType: String?
    let relatedEntityId: String?
    var isRead: Bool
    let deepLink: URL?
    let userInfo: [String: Any]?
    
    /// Initializes a new notification instance
    init(
        id: String,
        notificationType: NotificationType,
        title: String,
        content: String,
        timestamp: Date,
        relatedEntityType: String? = nil,
        relatedEntityId: String? = nil,
        isRead: Bool = false,
        deepLink: URL? = nil,
        userInfo: [String: Any]? = nil
    ) {
        self.id = id
        self.notificationType = notificationType
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.relatedEntityType = relatedEntityType
        self.relatedEntityId = relatedEntityId
        self.isRead = isRead
        self.deepLink = deepLink
        self.userInfo = userInfo
    }
    
    /// Marks the notification as read
    func markAsRead() {
        isRead = true
    }
    
    /// Converts the notification to a dictionary for use in local notifications
    func toUserInfo() -> [String: Any] {
        var info: [String: Any] = [
            NotificationConstants.UserInfo.notificationId: id,
            NotificationConstants.UserInfo.notificationType: notificationType.rawValue,
            NotificationConstants.UserInfo.timestamp: timestamp.timeIntervalSince1970
        ]
        
        if let relatedEntityType = relatedEntityType {
            info[NotificationConstants.UserInfo.relatedEntityType] = relatedEntityType
        }
        
        if let relatedEntityId = relatedEntityId {
            info[NotificationConstants.UserInfo.relatedEntityId] = relatedEntityId
        }
        
        if let deepLink = deepLink {
            info[NotificationConstants.UserInfo.deepLink] = deepLink.absoluteString
        }
        
        // Add any custom userInfo
        if let userInfo = userInfo {
            for (key, value) in userInfo {
                info[key] = value
            }
        }
        
        return info
    }
}