import Foundation // iOS SDK
import Combine // iOS SDK
import UserNotifications // iOS SDK

// Internal imports
import NotificationManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/NotificationManager.swift
import NotificationConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/NotificationConstants.swift
import Notification // src/ios/AmiraWellness/AmiraWellness/Models/Notification.swift
import NotificationType // src/ios/AmiraWellness/AmiraWellness/Models/Notification.swift
import NotificationPreferences // src/ios/AmiraWellness/AmiraWellness/Models/Notification.swift
import AchievementService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/AchievementService.swift
import StreakService // src/ios/AmiraWellness/AmiraWellness/Services/Progress/StreakService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift

/// Key for storing notification history
let NotificationHistoryStorageKey = "notification_history"
/// Key for storing notification preferences
let NotificationPreferencesStorageKey = "notification_preferences"

/// A service that manages notifications in the Amira Wellness application
final class NotificationService {
    /// A service that manages notifications in the Amira Wellness application

    // MARK: - Private Properties

    /// The low-level notification manager
    private let notificationManager: NotificationManager

    /// The storage service for persisting data
    private let storageService: StorageService

    /// The achievement service for accessing achievement data
    private let achievementService: AchievementService

    /// The streak service for accessing streak data
    private let streakService: StreakService

    /// The history of notifications
    private var notificationHistory: [Notification] = []

    /// The user's notification preferences
    private var notificationPreferences: NotificationPreferences

    /// Subject for publishing notification history updates
    private let notificationHistorySubject = CurrentValueSubject<[Notification], Never>([])

    // MARK: - Public Properties

    /// Publisher for notification history updates
    public var notificationHistoryPublisher: AnyPublisher<[Notification], Never> {
        return notificationHistorySubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    /// Initializes the NotificationService with dependencies
    /// - Parameters:
    ///   - notificationManager: The notification manager to use (optional, defaults to shared instance)
    ///   - storageService: The storage service to use (optional, defaults to shared instance)
    ///   - achievementService: The achievement service to use (optional, creates a new instance if nil)
    ///   - streakService: The streak service to use (optional, creates a new instance if nil)
    init(notificationManager: NotificationManager? = nil, storageService: StorageService? = nil, achievementService: AchievementService? = nil, StreakService streakService: StreakService? = nil) {
        // Store the provided notificationManager or use the shared instance
        self.notificationManager = notificationManager ?? NotificationManager.shared

        // Store the provided storageService or use the shared instance
        self.storageService = storageService ?? StorageService.shared

        // Store the provided achievementService or create a new instance
        self.achievementService = achievementService ?? AchievementService(apiClient: APIClient.shared)

        // Store the provided streakService or create a new instance
        self.streakService = streakService ?? StreakService(apiClient: APIClient.shared)

        // Initialize notificationHistory as an empty array
        self.notificationHistory = []

        // Initialize notificationPreferences with default values
        self.notificationPreferences = NotificationPreferences.defaultPreferences

        // Initialize notificationHistorySubject as a CurrentValueSubject with an empty array
        self.notificationHistorySubject = CurrentValueSubject<[Notification], Never>([])

        // Initialize notificationHistoryPublisher as a derived publisher from notificationHistorySubject
        // (This is already done in the property declaration)

        // Load notification history and preferences from storage
        loadNotificationHistory()
        loadNotificationPreferences()

        // Set up notification observers for achievements and streaks
        setupNotificationObservers()
    }

    // MARK: - Public Methods

    /// Requests permission to send notifications to the user
    /// - Parameter completion: A closure to be called when the permission is granted or denied
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        // Call notificationManager.requestAuthorization
        notificationManager.requestAuthorization { granted, error in
            // Handle the result and call the completion handler
            if let error = error {
                Logger.shared.error("Failed to request notification permissions", error: error, category: .general)
                completion(false)
            } else {
                Logger.shared.debug("Notification permissions granted: \(granted)", category: .general)
                completion(granted)
            }
        }
    }

    /// Checks the current notification permission status
    /// - Parameter completion: A closure to be called with the current authorization status
    func checkNotificationPermissions(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        // Call notificationManager.checkAuthorizationStatus
        notificationManager.checkAuthorizationStatus { status in
            // Call the completion handler with the result
            completion(status)
        }
    }

    /// Schedules daily reminder notifications based on user preferences
    func scheduleDailyReminders() {
        // Check if daily reminders are enabled in preferences
        guard notificationPreferences.dailyRemindersEnabled else {
            Logger.shared.debug("Daily reminders are disabled", category: .general)
            return
        }

        // Cancel any existing daily reminders
        cancelAllNotifications()

        // Get reminder time and days from preferences
        let hour = notificationPreferences.reminderHour
        let minute = notificationPreferences.reminderMinute
        let weekdays = notificationPreferences.reminderDays

        // Create reminder title and content
        let (title, body) = generateDailyReminderContent()

        // Call notificationManager.scheduleDailyReminder with the parameters
        notificationManager.scheduleDailyReminder(hour: hour, minute: minute, weekdays: weekdays, title: title, body: body, userInfo: [
            NotificationConstants.UserInfo.notificationType: NotificationType.dailyReminder.rawValue
        ])

        // Log the scheduled reminders
        Logger.shared.debug("Scheduled daily reminders for \(weekdays.count) days", category: .general)
    }

    /// Schedules a reminder notification for maintaining streak
    func scheduleStreakReminder() {
        // Check if streak reminders are enabled in preferences
        guard notificationPreferences.streakRemindersEnabled else {
            Logger.shared.debug("Streak reminders are disabled", category: .general)
            return
        }

        // Check if streak is active using streakService
        guard streakService.isStreakActive() else {
            Logger.shared.debug("Streak is not active, not scheduling streak reminder", category: .general)
            return
        }

        // If enabled and streak is active, create a reminder for later today
        let currentStreak = streakService.getCurrentStreak()
        let (title, body) = generateStreakReminderContent(currentStreak: currentStreak)

        // Create a reminder for later today
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: Date())
        components.hour = 20 // 8 PM
        components.minute = 0

        guard let deliveryDate = calendar.date(from: components) else {
            Logger.shared.error("Failed to create delivery date for streak reminder", category: .general)
            return
        }

        // Call notificationManager.scheduleLocalNotification with the parameters
        notificationManager.scheduleLocalNotification(title: title, body: body, date: deliveryDate, categoryIdentifier: NotificationType.streakReminder.categoryIdentifier, userInfo: [
            NotificationConstants.UserInfo.notificationType: NotificationType.streakReminder.rawValue
        ])

        // Log the scheduled streak reminder
        Logger.shared.debug("Scheduled streak reminder for later today", category: .general)
    }

    /// Schedules a notification for a newly earned achievement
    /// - Parameter achievement: The achievement to schedule a notification for
    func scheduleAchievementNotification(achievement: Achievement) {
        // Check if achievement notifications are enabled in preferences
        guard notificationPreferences.achievementsEnabled else {
            Logger.shared.debug("Achievement notifications are disabled", category: .general)
            return
        }

        // If enabled, create notification title and content based on achievement
        let title = "¡Nuevo logro desbloqueado!" // New achievement unlocked!
        let body = achievement.name

        // Create a Notification object with achievement details
        let notification = Notification(id: UUID().uuidString, notificationType: .achievement, title: title, content: body, timestamp: Date(), relatedEntityType: "achievement", relatedEntityId: achievement.id.uuidString)

        // Call notificationManager.scheduleLocalNotification with immediate delivery
        notificationManager.scheduleLocalNotification(title: title, body: body, date: Date(), categoryIdentifier: NotificationType.achievement.categoryIdentifier, userInfo: notification.toUserInfo())

        // Add notification to history and update storage
        addNotificationToHistory(notification: notification)

        // Log the scheduled achievement notification
        Logger.shared.debug("Scheduled achievement notification for \(achievement.name)", category: .general)
    }

    /// Schedules an affirmation notification
    /// - Parameter affirmationText: The text of the affirmation
    /// - Parameter deliveryDate: The date and time to deliver the affirmation (optional, defaults to tomorrow morning)
    func scheduleAffirmation(affirmationText: String, deliveryDate: Date? = nil) {
        // Check if affirmation notifications are enabled in preferences
        guard notificationPreferences.affirmationsEnabled else {
            Logger.shared.debug("Affirmation notifications are disabled", category: .general)
            return
        }

        // If enabled, create notification title and content with affirmation text
        let (title, body) = generateAffirmationContent(affirmationText: affirmationText)

        // Use provided delivery date or create one for tomorrow morning
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.hour = 8 // 8 AM
        components.minute = 0

        guard let deliveryDate = deliveryDate ?? calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!) else {
            Logger.shared.error("Failed to create delivery date for affirmation", category: .general)
            return
        }

        // Create a Notification object with affirmation details
        let notification = Notification(id: UUID().uuidString, notificationType: .affirmation, title: title, content: body, timestamp: Date())

        // Call notificationManager.scheduleLocalNotification with the parameters
        notificationManager.scheduleLocalNotification(title: title, body: body, date: deliveryDate, categoryIdentifier: NotificationType.affirmation.categoryIdentifier, userInfo: notification.toUserInfo())

        // Add notification to history and update storage
        addNotificationToHistory(notification: notification)

        // Log the scheduled affirmation
        Logger.shared.debug("Scheduled affirmation notification for \(deliveryDate)", category: .general)
    }

    /// Cancels a specific notification by ID
    /// - Parameter notificationId: The ID of the notification to cancel
    func cancelNotification(notificationId: String) {
        // Call notificationManager.cancelNotification with the ID
        notificationManager.cancelNotification(notificationId)

        // Remove notification from history if present
        notificationHistory.removeAll { $0.id == notificationId }

        // Update notification history storage
        saveNotificationHistory()

        // Log the cancellation
        Logger.shared.debug("Cancelled notification with ID: \(notificationId)", category: .general)
    }

    /// Cancels all pending notifications
    func cancelAllNotifications() {
        // Call notificationManager.cancelAllNotifications
        notificationManager.cancelAllNotifications()

        // Log the cancellation of all notifications
        Logger.shared.debug("Cancelled all notifications", category: .general)
    }

    /// Returns the history of notifications
    /// - Returns: Array of notification objects
    func getNotificationHistory() -> [Notification] {
        // Return the notificationHistory array
        return notificationHistory
    }

    /// Clears the notification history
    func clearNotificationHistory() {
        // Clear the notificationHistory array
        notificationHistory.removeAll()

        // Update notification history storage
        saveNotificationHistory()

        // Publish the updated history through notificationHistorySubject
        notificationHistorySubject.send(notificationHistory)

        // Log the history clearance
        Logger.shared.debug("Cleared notification history", category: .general)
    }

    /// Returns the current notification preferences
    /// - Returns: Current notification preferences
    func getNotificationPreferences() -> NotificationPreferences {
        // Return the notificationPreferences object
        return notificationPreferences
    }

    /// Updates notification preferences
    /// - Parameter preferences: The new notification preferences
    func updateNotificationPreferences(preferences: NotificationPreferences) {
        // Update notificationPreferences with the provided preferences
        notificationPreferences = preferences

        // Save preferences to storage
        saveNotificationPreferences()

        // Update notification manager settings
        // (This might involve rescheduling notifications based on new preferences)
        scheduleDailyReminders()
        scheduleStreakReminder()

        // Log the preference update
        Logger.shared.debug("Updated notification preferences", category: .general)
    }

    /// Handles user response to a notification
    /// - Parameters:
    ///   - response: The user's response to the notification
    ///   - completionHandler: Closure to call when handling is complete
    func handleNotificationResponse(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        // Extract notification content and user info
        let userInfo = response.notification.request.content.userInfo
        guard let notificationId = userInfo[NotificationConstants.UserInfo.notificationId] as? String,
              let notificationTypeString = userInfo[NotificationConstants.UserInfo.notificationType] as? String,
              let notificationType = NotificationType(rawValue: notificationTypeString) else {
            Logger.shared.error("Invalid notification user info", category: .general)
            completionHandler()
            return
        }

        // Determine notification type from user info
        Logger.shared.debug("Handling notification response for type: \(notificationType)", category: .general)

        // Process response based on notification type and action identifier
        switch notificationType {
        case .dailyReminder:
            // Handle daily reminder
            Logger.shared.debug("Processing daily reminder notification", category: .general)
            break
        case .streakReminder:
            // Handle streak reminder
            Logger.shared.debug("Processing streak reminder notification", category: .general)
            break
        case .achievement:
            // Handle achievement notification
            Logger.shared.debug("Processing achievement notification", category: .general)
            break
        case .affirmation:
            // Handle affirmation notification
            Logger.shared.debug("Processing affirmation notification", category: .general)
            break
        case .wellnessTip:
            // Handle wellness tip notification
            Logger.shared.debug("Processing wellness tip notification", category: .general)
            break
        case .appUpdate:
            // Handle app update notification
            Logger.shared.debug("Processing app update notification", category: .general)
            break
        }

        // Mark notification as read in history if found
        if let index = notificationHistory.firstIndex(where: { $0.id == notificationId }) {
            notificationHistory[index].markAsRead()
            saveNotificationHistory()
        }

        // Call completionHandler when processing is complete
        completionHandler()
    }

    // MARK: - Private Methods

    /// Loads notification history from storage
    private func loadNotificationHistory() {
        // Retrieve notification history from storageService
        let result: Result<[Notification], StorageError> = storageService.retrieveCodable(forKey: NotificationHistoryStorageKey, dataType: .preferences, sensitivity: .nonsensitive)

        switch result {
        case .success(let history):
            // If successful, update notificationHistory with retrieved data
            notificationHistory = history

            // Publish the loaded history through notificationHistorySubject
            notificationHistorySubject.send(notificationHistory)

            Logger.shared.debug("Loaded notification history from storage", category: .general)

        case .failure(let error):
            // Log any errors that occur during retrieval
            Logger.shared.error("Failed to load notification history from storage: \(error)", category: .general)
        }
    }

    /// Saves notification history to storage
    private func saveNotificationHistory() {
        // Store notificationHistory in storageService
        let result = storageService.storeCodable(notificationHistory, forKey: NotificationHistoryStorageKey, dataType: .preferences, sensitivity: .nonsensitive)

        switch result {
        case .success:
            Logger.shared.debug("Saved notification history to storage", category: .general)

        case .failure(let error):
            // Log any errors that occur during storage
            Logger.shared.error("Failed to save notification history to storage: \(error)", category: .general)
        }
    }

    /// Loads notification preferences from storage
    private func loadNotificationPreferences() {
        // Retrieve notification preferences from storageService
        let result: Result<NotificationPreferences, StorageError> = storageService.retrieveCodable(forKey: NotificationPreferencesStorageKey, dataType: .preferences, sensitivity: .nonsensitive)

        switch result {
        case .success(let preferences):
            // If successful, update notificationPreferences with retrieved data
            notificationPreferences = preferences

            Logger.shared.debug("Loaded notification preferences from storage", category: .general)

        case .failure(let error):
            // If not found, use default preferences
            notificationPreferences = NotificationPreferences.defaultPreferences
            Logger.shared.debug("No notification preferences found, using default preferences", category: .general)
            
            // Log any errors that occur during retrieval
            Logger.shared.error("Failed to load notification preferences from storage: \(error)", category: .general)
        }
    }

    /// Saves notification preferences to storage
    private func saveNotificationPreferences() {
        // Store notificationPreferences in storageService
        let result = storageService.storeCodable(notificationPreferences, forKey: NotificationPreferencesStorageKey, dataType: .preferences, sensitivity: .nonsensitive)

        switch result {
        case .success:
            Logger.shared.debug("Saved notification preferences to storage", category: .general)

        case .failure(let error):
            // Log any errors that occur during storage
            Logger.shared.error("Failed to save notification preferences to storage: \(error)", category: .general)
        }
    }

    /// Sets up observers for achievement and streak notifications
    private func setupNotificationObservers() {
        // Register for StreakMilestoneReached notifications
        NotificationCenter.default.addObserver(forName: StreakMilestoneReached.notificationName, object: nil, queue: .main) { notification in
            // Handle streak milestone notifications by scheduling appropriate notifications
            guard let milestone = notification.userInfo?[StreakMilestoneReached.milestoneKey] as? Int else {
                Logger.shared.error("Invalid milestone in streak notification", category: .general)
                return
            }

            guard let streak = notification.userInfo?[StreakMilestoneReached.streakKey] as? Int else {
                Logger.shared.error("Invalid streak in streak notification", category: .general)
                return
            }

            // Schedule a notification for the streak milestone
            let title = "¡Racha de \(milestone) días!" // \(milestone)-day streak!
            let body = "¡Felicidades por alcanzar una racha de \(milestone) días!" // Congratulations on reaching a \(milestone)-day streak!

            // Create a Notification object with streak milestone details
            let notification = Notification(id: UUID().uuidString, notificationType: .streakReminder, title: title, content: body, timestamp: Date())

            // Call notificationManager.scheduleLocalNotification with the parameters
            self.notificationManager.scheduleLocalNotification(title: title, body: body, date: Date(), categoryIdentifier: NotificationType.streakReminder.categoryIdentifier, userInfo: notification.toUserInfo())

            // Add notification to history and update storage
            self.addNotificationToHistory(notification: notification)
        }

        // Register for achievement-related notifications
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AchievementEarned"), object: nil, queue: .main) { notification in
            // Handle achievement notifications by scheduling appropriate notifications
            guard let achievement = notification.object as? Achievement else {
                Logger.shared.error("Invalid achievement in notification", category: .general)
                return
            }

            // Schedule a notification for the achievement
            self.scheduleAchievementNotification(achievement: achievement)
        }
    }

    /// Adds a notification to the history
    /// - Parameter notification: The notification to add
    private func addNotificationToHistory(notification: Notification) {
        // Add notification to notificationHistory array
        notificationHistory.append(notification)

        // Limit history size if it exceeds maximum
        if notificationHistory.count > 50 {
            notificationHistory.removeFirst()
        }

        // Save updated history to storage
        saveNotificationHistory()

        // Publish the updated history through notificationHistorySubject
        notificationHistorySubject.send(notificationHistory)
    }

    /// Generates content for daily reminder notifications
    /// - Returns: Tuple containing title and body text
    private func generateDailyReminderContent() -> (String, String) {
        // Create an array of possible reminder messages
        let messages = [
            "¿Listo para un momento de bienestar?", // Ready for a moment of wellness?
            "¿Qué tal un poco de autocuidado hoy?", // How about some self-care today?
            "Es hora de priorizar tu bienestar emocional", // It's time to prioritize your emotional wellness
            "¿Listo para registrar tus emociones hoy?" // Ready to log your emotions today?
        ]

        // Randomly select a message from the array
        let randomIndex = Int.random(in: 0..<messages.count)
        let body = messages[randomIndex]

        // Return title and body text for the notification
        return ("Recordatorio diario", body) // Daily reminder
    }

    /// Generates content for streak reminder notifications
    /// - Parameter currentStreak: The current streak count
    /// - Returns: Tuple containing title and body text
    private func generateStreakReminderContent(currentStreak: Int) -> (String, String) {
        // Create title text mentioning the current streak
        let title = "¡Sigue con tu racha!" // Keep your streak going!

        // Create body text encouraging the user to maintain their streak
        let body = "¡Llevas \(currentStreak) días seguidos! No te detengas ahora." // You've been going for \(currentStreak) days straight! Don't stop now.

        // Return title and body text for the notification
        return (title, body)
    }

    /// Generates content for affirmation notifications
    /// - Parameter affirmationText: The text of the affirmation
    /// - Returns: Tuple containing title and body text
    private func generateAffirmationContent(affirmationText: String) -> (String, String) {
        // Create a standard title for affirmations
        let title = "Afirmación diaria" // Daily affirmation

        // Use the provided affirmation text as the body
        let body = affirmationText

        // Return title and body text for the notification
        return (title, body)
    }
}