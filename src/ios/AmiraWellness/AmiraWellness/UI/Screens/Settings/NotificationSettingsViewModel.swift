import Foundation // iOS SDK
import Combine // iOS SDK
import SwiftUI // iOS SDK

// Internal imports
import NotificationService // src/ios/AmiraWellness/AmiraWellness/Services/Notification/NotificationService.swift
import NotificationAuthorizationStatus // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/NotificationManager.swift
import NotificationPreferences // src/ios/AmiraWellness/AmiraWellness/Models/Notification.swift
import NotificationConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/NotificationConstants.swift
import UIApplication // src/ios/AmiraWellness/AmiraWellness/Core/Extensions/UIApplication+Extensions.swift

/// A view model that manages notification settings for the Amira Wellness application
@available(iOS 14.0, *)
class NotificationSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates if the view model is currently loading data
    @Published var isLoading: Bool = false
    
    /// Stores the error message to display to the user
    @Published var errorMessage: String = ""
    
    /// Controls the visibility of the error alert
    @Published var showError: Bool = false
    
    /// Indicates if notifications are enabled for the app
    @Published var notificationsEnabled: Bool = false
    
    /// Stores the current notification authorization status
    @Published var authorizationStatus: NotificationAuthorizationStatus = .notDetermined
    
    /// Indicates if daily reminder notifications are enabled
    @Published var dailyRemindersEnabled: Bool = false
    
    /// Indicates if streak reminder notifications are enabled
    @Published var streakRemindersEnabled: Bool = false
    
    /// Indicates if achievement notifications are enabled
    @Published var achievementsEnabled: Bool = false
    
    /// Indicates if affirmation notifications are enabled
    @Published var affirmationsEnabled: Bool = false
    
    /// Indicates if wellness tip notifications are enabled
    @Published var wellnessTipsEnabled: Bool = false
    
    /// Indicates if app update notifications are enabled
    @Published var appUpdatesEnabled: Bool = false
    
    /// Stores the hour for daily reminder notifications
    @Published var reminderHour: Int = 10
    
    /// Stores the minute for daily reminder notifications
    @Published var reminderMinute: Int = 0
    
    /// Stores the selected days of the week for daily reminder notifications
    @Published var selectedDays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    
    /// Controls the visibility of the permission alert
    @Published var showPermissionAlert: Bool = false
    
    // MARK: - Private Properties
    
    /// The notification service used to manage notifications
    private let notificationService: NotificationService
    
    /// A set to store Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the notification settings view model with dependencies
    /// - Parameter notificationService: The notification service to use
    init(notificationService: NotificationService) {
        self.notificationService = notificationService
        loadNotificationSettings()
    }
    
    // MARK: - Public Methods
    
    /// Loads the current notification settings from the notification service
    func loadNotificationSettings() {
        isLoading = true
        
        notificationService.checkNotificationPermissions { [weak self] status in
            guard let self = self else { return }
            
            self.authorizationStatus = status
            self.notificationsEnabled = status == .authorized
            
            let preferences = self.notificationService.getNotificationPreferences()
            self.dailyRemindersEnabled = preferences.dailyRemindersEnabled
            self.streakRemindersEnabled = preferences.streakRemindersEnabled
            self.achievementsEnabled = preferences.achievementsEnabled
            self.affirmationsEnabled = preferences.affirmationsEnabled
            self.wellnessTipsEnabled = preferences.wellnessTipsEnabled
            self.appUpdatesEnabled = preferences.appUpdatesEnabled
            self.reminderHour = preferences.reminderHour
            self.reminderMinute = preferences.reminderMinute
            self.selectedDays = preferences.reminderDays
            
            self.isLoading = false
        }
    }
    
    /// Requests notification permissions from the user
    func requestNotificationPermissions() {
        isLoading = true
        
        notificationService.requestNotificationPermissions { [weak self] granted in
            guard let self = self else { return }
            
            self.authorizationStatus = granted ? .authorized : .denied
            self.notificationsEnabled = granted
            self.isLoading = false
            
            if !granted {
                self.showPermissionAlert = true
            }
        }
    }
    
    /// Saves the current notification settings
    func saveNotificationSettings() {
        isLoading = true
        
        let preferences = NotificationPreferences(
            dailyRemindersEnabled: dailyRemindersEnabled,
            streakRemindersEnabled: streakRemindersEnabled,
            achievementsEnabled: achievementsEnabled,
            affirmationsEnabled: affirmationsEnabled,
            wellnessTipsEnabled: wellnessTipsEnabled,
            appUpdatesEnabled: appUpdatesEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            reminderDays: selectedDays
        )
        
        notificationService.updateNotificationPreferences(preferences: preferences)
        notificationService.scheduleDailyReminders()
        
        isLoading = false
    }
    
    /// Resets notification settings to default values
    func resetToDefaults() {
        let defaultPreferences = NotificationPreferences.defaultPreferences
        
        dailyRemindersEnabled = defaultPreferences.dailyRemindersEnabled
        streakRemindersEnabled = defaultPreferences.streakRemindersEnabled
        achievementsEnabled = defaultPreferences.achievementsEnabled
        affirmationsEnabled = defaultPreferences.affirmationsEnabled
        wellnessTipsEnabled = defaultPreferences.wellnessTipsEnabled
        appUpdatesEnabled = defaultPreferences.appUpdatesEnabled
        reminderHour = defaultPreferences.reminderHour
        reminderMinute = defaultPreferences.reminderMinute
        selectedDays = defaultPreferences.reminderDays
        
        saveNotificationSettings()
    }
    
    /// Opens the system settings app to the notification settings page
    func openSystemSettings() {
        UIApplication.openAppSettings { success in
            if success {
                print("Opened settings successfully")
            } else {
                print("Failed to open settings")
            }
        }
    }
    
    /// Returns a formatted string representation of the current reminder time
    func getFormattedTime() -> String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else {
            return "Invalid Time"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Returns the localized name for a day of the week
    /// - Parameter day: The day of the week (1-7, Sunday is 1)
    /// - Returns: The localized day name
    func getDayName(day: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.weekdaySymbols = formatter.shortWeekdaySymbols
        
        guard day >= 1 && day <= 7 else {
            return ""
        }
        
        return formatter.weekdaySymbols[day - 1]
    }
    
    /// Toggles the selection state of a day in the selectedDays array
    /// - Parameter day: The day to toggle
    func toggleDay(day: Int) {
        if isDaySelected(day: day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
        }
        
        // Ensure at least one day is selected
        if selectedDays.isEmpty {
            selectedDays.append(day)
        }
    }
    
    /// Checks if a specific day is selected in the selectedDays array
    /// - Parameter day: The day to check
    /// - Returns: True if the day is selected, false otherwise
    func isDaySelected(day: Int) -> Bool {
        return selectedDays.contains(day)
    }
    
    // MARK: - Private Methods
    
    /// Handles errors by setting the error message and showing the error alert
    /// - Parameter error: The error to handle
    private func handleError(error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
    }
}