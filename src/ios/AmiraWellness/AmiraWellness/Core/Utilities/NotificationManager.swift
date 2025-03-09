//
//  NotificationManager.swift
//  AmiraWellness
//
//  Created for Amira Wellness iOS application
//

import Foundation // iOS SDK
import UserNotifications // iOS SDK
import UIKit // iOS SDK

/// Defines the possible authorization states for notifications
enum NotificationAuthorizationStatus {
    case authorized
    case denied
    case notDetermined
    case provisional
    case ephemeral
}

/// A singleton manager class that provides low-level notification functionality
class NotificationManager {
    /// Shared instance of NotificationManager (singleton)
    static let shared = NotificationManager()
    
    /// Reference to the current UNUserNotificationCenter
    private let notificationCenter: UNUserNotificationCenter
    
    /// The set of notification categories registered with the system
    private var notificationCategories: Set<UNNotificationCategory>
    
    /// Tracks if the app is registered for remote notifications
    private var isRegisteredForRemoteNotifications: Bool
    
    /// Private initializer for singleton pattern
    private init() {
        notificationCenter = UNUserNotificationCenter.current()
        isRegisteredForRemoteNotifications = false
        notificationCategories = []
        setupNotificationCategories()
    }
    
    /// Sets up notification categories and actions
    private func setupNotificationCategories() {
        // Daily reminder category
        let snoozeAction = UNNotificationAction(
            identifier: NotificationConstants.Actions.snooze,
            title: "Snooze",
            options: .foreground
        )
        
        let completeAction = UNNotificationAction(
            identifier: NotificationConstants.Actions.complete,
            title: "Complete",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: NotificationConstants.Actions.dismiss,
            title: "Dismiss",
            options: .destructive
        )
        
        let dailyReminderCategory = UNNotificationCategory(
            identifier: NotificationConstants.Categories.dailyReminder,
            actions: [snoozeAction, completeAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Streak reminder category
        let streakReminderCategory = UNNotificationCategory(
            identifier: NotificationConstants.Categories.streakReminder,
            actions: [completeAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Achievement category
        let viewDetailsAction = UNNotificationAction(
            identifier: NotificationConstants.Actions.viewDetails,
            title: "View Details",
            options: .foreground
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: NotificationConstants.Categories.achievement,
            actions: [viewDetailsAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Affirmation category
        let affirmationCategory = UNNotificationCategory(
            identifier: NotificationConstants.Categories.affirmation,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Wellness tip category
        let wellnessTipCategory = UNNotificationCategory(
            identifier: NotificationConstants.Categories.wellnessTip,
            actions: [viewDetailsAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // App update category
        let openAction = UNNotificationAction(
            identifier: NotificationConstants.Actions.open,
            title: "Open",
            options: .foreground
        )
        
        let appUpdateCategory = UNNotificationCategory(
            identifier: NotificationConstants.Categories.appUpdate,
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Store all categories
        notificationCategories = [
            dailyReminderCategory,
            streakReminderCategory,
            achievementCategory,
            affirmationCategory,
            wellnessTipCategory,
            appUpdateCategory
        ]
        
        // Register categories with the notification center
        notificationCenter.setNotificationCategories(notificationCategories)
        
        Logger.shared.debug("Notification categories registered", category: .general)
    }
    
    /// Requests notification permissions from the user
    /// - Parameter completion: Closure called with the result of the authorization request
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) { granted, error in
            if let error = error {
                Logger.shared.error("Failed to request notification authorization", error: error, category: .general)
            } else {
                Logger.shared.info("Notification authorization request result: \(granted)", category: .general)
            }
            
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }
    
    /// Checks the current notification authorization status
    /// - Parameter completion: Closure called with the current authorization status
    func checkAuthorizationStatus(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            var status: NotificationAuthorizationStatus
            
            switch settings.authorizationStatus {
            case .authorized:
                status = .authorized
            case .denied:
                status = .denied
            case .notDetermined:
                status = .notDetermined
            case .provisional:
                status = .provisional
            case .ephemeral:
                status = .ephemeral
            @unknown default:
                status = .notDetermined
            }
            
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    /// Registers the device for remote notifications
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            self.isRegisteredForRemoteNotifications = true
            Logger.shared.debug("Registered for remote notifications", category: .general)
        }
    }
    
    /// Schedules a local notification
    /// - Parameters:
    ///   - title: The title of the notification
    ///   - body: The body text of the notification
    ///   - date: The date when the notification should be delivered
    ///   - categoryIdentifier: The category identifier for the notification
    ///   - userInfo: Optional additional information to include with the notification
    ///   - identifier: Optional unique identifier for the notification (generated if nil)
    func scheduleLocalNotification(
        title: String,
        body: String,
        date: Date,
        categoryIdentifier: String,
        userInfo: [String: Any]? = nil,
        identifier: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let notificationIdentifier = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to schedule local notification", error: error, category: .general)
            } else {
                Logger.shared.info("Local notification scheduled for \(date)", category: .general)
            }
        }
    }
    
    /// Schedules a daily reminder notification
    /// - Parameters:
    ///   - hour: The hour of the day (0-23)
    ///   - minute: The minute of the hour (0-59)
    ///   - weekdays: Array of weekdays when the reminder should trigger (1 = Sunday, 7 = Saturday)
    ///   - title: The title of the notification
    ///   - body: The body text of the notification
    ///   - userInfo: Optional additional information to include with the notification
    func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        weekdays: [Int],
        title: String,
        body: String,
        userInfo: [String: Any]? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationConstants.Categories.dailyReminder
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        // Schedule a notification for each selected weekday
        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = weekday
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(NotificationConstants.Categories.dailyReminder)_\(weekday)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    Logger.shared.error("Failed to schedule daily reminder for weekday \(weekday)", error: error, category: .general)
                } else {
                    Logger.shared.info("Daily reminder scheduled for weekday \(weekday) at \(hour):\(minute)", category: .general)
                }
            }
        }
    }
    
    /// Cancels a specific notification
    /// - Parameter identifier: The identifier of the notification to cancel
    func cancelNotification(_ identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        Logger.shared.debug("Cancelled notification with identifier: \(identifier)", category: .general)
    }
    
    /// Cancels all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        Logger.shared.debug("Cancelled all pending notifications", category: .general)
    }
    
    /// Gets all pending notification requests
    /// - Parameter completion: Closure called with an array of pending notification requests
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    /// Gets all delivered notifications
    /// - Parameter completion: Closure called with an array of delivered notifications
    func getDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        notificationCenter.getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications)
            }
        }
    }
    
    /// Removes delivered notifications
    /// - Parameter identifiers: An array of notification identifiers to remove
    func removeDeliveredNotifications(_ identifiers: [String]) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
        Logger.shared.debug("Removed delivered notifications with identifiers: \(identifiers)", category: .general)
    }
    
    /// Removes all delivered notifications
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        Logger.shared.debug("Removed all delivered notifications", category: .general)
    }
    
    /// Updates the application badge count
    /// - Parameter count: The new badge count value
    func updateBadgeCount(count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            Logger.shared.debug("Updated application badge count to \(count)", category: .general)
        }
    }
    
    /// Handles a user's response to a notification
    /// - Parameters:
    ///   - response: The user's response to the notification
    ///   - completionHandler: Closure to call when handling is complete
    func handleNotificationResponse(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        Logger.shared.debug("Handling notification response for category: \(categoryIdentifier)", category: .general)
        
        // Process based on the action the user took
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // The user opened the notification
            Logger.shared.debug("User opened notification", category: .general)
            
        case NotificationConstants.Actions.snooze:
            // Handle snooze action
            Logger.shared.debug("User snoozed notification", category: .general)
            
        case NotificationConstants.Actions.complete:
            // Handle complete action
            Logger.shared.debug("User completed notification", category: .general)
            
        case NotificationConstants.Actions.viewDetails:
            // Handle view details action
            Logger.shared.debug("User viewed notification details", category: .general)
            
        case NotificationConstants.Actions.dismiss, UNNotificationDismissActionIdentifier:
            // Handle dismiss action
            Logger.shared.debug("User dismissed notification", category: .general)
            
        default:
            Logger.shared.debug("Unknown notification action: \(response.actionIdentifier)", category: .general)
        }
        
        // Process based on notification category
        switch categoryIdentifier {
        case NotificationConstants.Categories.dailyReminder:
            // Handle daily reminder
            Logger.shared.debug("Processing daily reminder notification", category: .general)
            
        case NotificationConstants.Categories.streakReminder:
            // Handle streak reminder
            Logger.shared.debug("Processing streak reminder notification", category: .general)
            
        case NotificationConstants.Categories.achievement:
            // Handle achievement notification
            Logger.shared.debug("Processing achievement notification", category: .general)
            
        case NotificationConstants.Categories.affirmation:
            // Handle affirmation notification
            Logger.shared.debug("Processing affirmation notification", category: .general)
            
        case NotificationConstants.Categories.wellnessTip:
            // Handle wellness tip notification
            Logger.shared.debug("Processing wellness tip notification", category: .general)
            
        case NotificationConstants.Categories.appUpdate:
            // Handle app update notification
            Logger.shared.debug("Processing app update notification", category: .general)
            
        default:
            Logger.shared.debug("Unknown notification category: \(categoryIdentifier)", category: .general)
        }
        
        completionHandler()
    }
    
    /// Handles a notification that will be presented while the app is in foreground
    /// - Parameters:
    ///   - notification: The notification to be presented
    ///   - completionHandler: Closure to call with presentation options
    func handleWillPresentNotification(notification: UNNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        let categoryIdentifier = notification.request.content.categoryIdentifier
        
        Logger.shared.debug("Handling will present notification for category: \(categoryIdentifier)", category: .general)
        
        // Determine presentation options based on notification type
        var presentationOptions: UNNotificationPresentationOptions = []
        
        // iOS 14+ notification presentation options
        if #available(iOS 14.0, *) {
            presentationOptions = [.banner, .sound, .badge, .list]
        } else {
            // iOS < 14 notification presentation options
            presentationOptions = [.alert, .sound, .badge]
        }
        
        completionHandler(presentationOptions)
    }
    
    /// Sets the delegate for the notification center
    /// - Parameter delegate: The object that will serve as the notification center delegate
    func setNotificationDelegate(delegate: UNUserNotificationCenterDelegate) {
        notificationCenter.delegate = delegate
        Logger.shared.debug("Set notification center delegate", category: .general)
    }
    
    /// Checks if a specific notification type is enabled
    /// - Parameter notificationType: The type of notification to check
    /// - Returns: True if the notification type is enabled, false otherwise
    func isNotificationEnabled(_ notificationType: String) -> Bool {
        return UserDefaultsManager.shared.getBool(forKey: "notification_enabled_\(notificationType)", defaultValue: getDefaultEnabledState(for: notificationType))
    }
    
    /// Sets whether a specific notification type is enabled
    /// - Parameters:
    ///   - notificationType: The type of notification to set
    ///   - enabled: Whether the notification type should be enabled
    func setNotificationEnabled(_ notificationType: String, enabled: Bool) {
        UserDefaultsManager.shared.setBool(enabled, forKey: "notification_enabled_\(notificationType)")
        Logger.shared.debug("Set notification type \(notificationType) enabled: \(enabled)", category: .general)
    }
    
    /// Gets the current notification settings
    /// - Returns: A dictionary containing notification settings
    func getNotificationSettings() -> [String: Any] {
        let dailyRemindersEnabled = isNotificationEnabled(NotificationConstants.Categories.dailyReminder)
        let streakRemindersEnabled = isNotificationEnabled(NotificationConstants.Categories.streakReminder)
        let achievementsEnabled = isNotificationEnabled(NotificationConstants.Categories.achievement)
        let affirmationsEnabled = isNotificationEnabled(NotificationConstants.Categories.affirmation)
        let wellnessTipsEnabled = isNotificationEnabled(NotificationConstants.Categories.wellnessTip)
        let appUpdatesEnabled = isNotificationEnabled(NotificationConstants.Categories.appUpdate)
        
        let reminderHour = UserDefaultsManager.shared.getInt(forKey: "notification_reminder_hour", defaultValue: NotificationConstants.DefaultSettings.defaultReminderHour)
        let reminderMinute = UserDefaultsManager.shared.getInt(forKey: "notification_reminder_minute", defaultValue: NotificationConstants.DefaultSettings.defaultReminderMinute)
        let reminderDays = UserDefaultsManager.shared.getArray(forKey: "notification_reminder_days", defaultValue: NotificationConstants.DefaultSettings.defaultReminderDays as [Any])
        
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
    
    /// Saves notification settings
    /// - Parameter settings: A dictionary containing notification settings
    func saveNotificationSettings(_ settings: [String: Any]) {
        if let dailyRemindersEnabled = settings["dailyRemindersEnabled"] as? Bool {
            setNotificationEnabled(NotificationConstants.Categories.dailyReminder, enabled: dailyRemindersEnabled)
        }
        
        if let streakRemindersEnabled = settings["streakRemindersEnabled"] as? Bool {
            setNotificationEnabled(NotificationConstants.Categories.streakReminder, enabled: streakRemindersEnabled)
        }
        
        if let achievementsEnabled = settings["achievementsEnabled"] as? Bool {
            setNotificationEnabled(NotificationConstants.Categories.achievement, enabled: achievementsEnabled)
        }
        
        if let affirmationsEnabled = settings["affirmationsEnabled"] as? Bool {
            setNotificationEnabled(NotificationConstants.Categories.affirmation, enabled: affirmationsEnabled)
        }
        
        if let wellnessTipsEnabled = settings["wellnessTipsEnabled"] as? Bool {
            setNotificationEnabled(NotificationConstants.Categories.wellnessTip, enabled: wellnessTipsEnabled)
        }
        
        if let appUpdatesEnabled = settings["appUpdatesEnabled"] as? Bool {
            setNotificationEnabled(NotificationConstants.Categories.appUpdate, enabled: appUpdatesEnabled)
        }
        
        if let reminderHour = settings["reminderHour"] as? Int {
            UserDefaultsManager.shared.setInt(reminderHour, forKey: "notification_reminder_hour")
        }
        
        if let reminderMinute = settings["reminderMinute"] as? Int {
            UserDefaultsManager.shared.setInt(reminderMinute, forKey: "notification_reminder_minute")
        }
        
        if let reminderDays = settings["reminderDays"] as? [Int] {
            UserDefaultsManager.shared.setArray(reminderDays, forKey: "notification_reminder_days")
        }
        
        Logger.shared.debug("Saved notification settings", category: .general)
    }
    
    /// Gets the default enabled state for a notification type
    /// - Parameter notificationType: The notification type
    /// - Returns: The default enabled state for the notification type
    private func getDefaultEnabledState(for notificationType: String) -> Bool {
        switch notificationType {
        case NotificationConstants.Categories.dailyReminder:
            return NotificationConstants.DefaultSettings.dailyRemindersEnabled
        case NotificationConstants.Categories.streakReminder:
            return NotificationConstants.DefaultSettings.streakRemindersEnabled
        case NotificationConstants.Categories.achievement:
            return NotificationConstants.DefaultSettings.achievementsEnabled
        case NotificationConstants.Categories.affirmation:
            return NotificationConstants.DefaultSettings.affirmationsEnabled
        case NotificationConstants.Categories.wellnessTip:
            return NotificationConstants.DefaultSettings.wellnessTipsEnabled
        case NotificationConstants.Categories.appUpdate:
            return NotificationConstants.DefaultSettings.appUpdatesEnabled
        default:
            return false
        }
    }
}