import Foundation // iOS SDK
import Combine // iOS SDK
import SwiftUI // iOS SDK
import UIKit // iOS SDK

// Internal imports
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import ThemeManager // src/ios/AmiraWellness/AmiraWellness/Managers/ThemeManager.swift
import BiometricAuthManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/BiometricAuthManager.swift
import UserDefaultsManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/UserDefaultsManager.swift
import NotificationManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/NotificationManager.swift
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift

/// A view model that manages the settings functionality for the Amira Wellness application
@available(iOS 14.0, *)
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The user's email address
    @Published var userEmail: String = ""
    
    /// The selected theme mode
    @Published var selectedThemeMode: ThemeMode = .system {
        didSet {
            updateThemeMode()
        }
    }
    
    /// Whether notifications are enabled
    @Published var isNotificationsEnabled: Bool = false {
        didSet {
            toggleNotifications()
        }
    }
    
    /// Whether biometric authentication is available on the device
    @Published var isBiometricAuthAvailable: Bool = false
    
    /// Whether biometric authentication is enabled
    @Published var isBiometricAuthEnabled: Bool = false {
        didSet {
            toggleBiometricAuth()
        }
    }
    
    /// The selected language
    @Published var selectedLanguage: String = AppConstants.App.defaultLanguage {
        didSet {
            updateLanguage()
        }
    }
    
    /// Whether the user is currently logging out
    @Published var isLoggingOut: Bool = false
    
    /// Whether to show the logout confirmation dialog
    @Published var showLogoutConfirmation: Bool = false
    
    /// Whether to show an error alert
    @Published var showErrorAlert: Bool = false
    
    /// The error message to display
    @Published var errorMessage: String = ""
    
    // MARK: - Private Properties
    
    /// Theme manager for handling theme settings
    private let themeManager: ThemeManager
    
    /// Biometric authentication manager for handling biometric authentication
    private let biometricAuthManager: BiometricAuthManager
    
    /// User defaults manager for handling user preferences
    private let userDefaultsManager: UserDefaultsManager
    
    /// Notification manager for handling notification settings
    private let notificationManager: NotificationManager
    
    /// Authentication service for handling authentication operations
    private let authService: AuthService
    
    /// Set to store Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the settings view model with dependencies
    /// - Parameters:
    ///   - themeManager: Theme manager for handling theme settings
    ///   - biometricAuthManager: Biometric authentication manager for handling biometric authentication
    ///   - userDefaultsManager: User defaults manager for handling user preferences
    ///   - notificationManager: Notification manager for handling notification settings
    ///   - authService: Authentication service for handling authentication operations
    init(
        themeManager: ThemeManager = ThemeManager.shared,
        biometricAuthManager: BiometricAuthManager = BiometricAuthManager.shared,
        userDefaultsManager: UserDefaultsManager = UserDefaultsManager.shared,
        notificationManager: NotificationManager = NotificationManager.shared,
        authService: AuthService = AuthService.shared
    ) {
        self.themeManager = themeManager
        self.biometricAuthManager = biometricAuthManager
        self.userDefaultsManager = userDefaultsManager
        self.notificationManager = notificationManager
        self.authService = authService
        
        self.cancellables = Set<AnyCancellable>()
        
        self.userEmail = ""
        self.selectedThemeMode = themeManager.getCurrentTheme()
        self.isNotificationsEnabled = notificationManager.isNotificationsEnabled
        self.isBiometricAuthAvailable = biometricAuthManager.canAuthenticate()
        self.isBiometricAuthEnabled = authService.isBiometricLoginEnabled()
        self.selectedLanguage = userDefaultsManager.getString(forKey: AppConstants.UserDefaults.selectedLanguage, defaultValue: AppConstants.App.defaultLanguage)
        self.isLoggingOut = false
        self.showLogoutConfirmation = false
        self.showErrorAlert = false
        self.errorMessage = ""
    }
    
    // MARK: - Public Methods
    
    /// Called when the settings view appears
    func onAppear() {
        // Load user email from current user
        if let user = authService.getCurrentUser() {
            userEmail = user.email
        }
        
        // Check biometric authentication availability
        isBiometricAuthAvailable = biometricAuthManager.canAuthenticate()
        
        // Check if biometric authentication is enabled
        isBiometricAuthEnabled = authService.isBiometricLoginEnabled()
        
        // Load current theme mode
        selectedThemeMode = themeManager.getCurrentTheme()
        
        // Load notification settings
        isNotificationsEnabled = notificationManager.isNotificationsEnabled
        
        // Load selected language
        selectedLanguage = userDefaultsManager.getString(forKey: AppConstants.UserDefaults.selectedLanguage, defaultValue: AppConstants.App.defaultLanguage)
        
        Logger.debug("Settings screen appeared")
    }
    
    /// Updates the application theme mode
    func updateThemeMode() {
        themeManager.setTheme(selectedThemeMode)
        Logger.debug("Theme mode changed to \(selectedThemeMode)")
    }
    
    /// Toggles notification settings
    func toggleNotifications() {
        notificationManager.toggleNotifications()
        isNotificationsEnabled = notificationManager.isNotificationsEnabled
        Logger.debug("Notifications toggled to \(isNotificationsEnabled)")
    }
    
    /// Toggles biometric authentication
    func toggleBiometricAuth() {
        authService.enableBiometricLogin(enable: isBiometricAuthEnabled) { result in
            switch result {
            case .success:
                Logger.debug("Biometric authentication toggled to \(isBiometricAuthEnabled)")
            case .failure(let error):
                Logger.error("Failed to toggle biometric authentication: \(error)")
            }
        }
    }
    
    /// Updates the application language
    func updateLanguage() {
        userDefaultsManager.setString(selectedLanguage, forKey: AppConstants.UserDefaults.selectedLanguage)
        NotificationCenter.default.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        Logger.debug("Language changed to \(selectedLanguage)")
    }
    
    /// Opens the help center website
    func openHelpCenter() {
        guard let url = URL(string: AppConstants.App.helpCenterURL) else {
            Logger.error("Invalid help center URL")
            return
        }
        UIApplication.shared.open(url)
        Logger.debug("Opened help center")
    }
    
    /// Opens email client to contact support
    func contactSupport() {
        guard let url = URL(string: "mailto:\(AppConstants.App.supportEmail)") else {
            Logger.error("Invalid support email address")
            return
        }
        UIApplication.shared.open(url)
        Logger.debug("Attempted to contact support")
    }
    
    /// Opens the privacy policy website
    func openPrivacyPolicy() {
        guard let url = URL(string: AppConstants.App.privacyPolicyURL) else {
            Logger.error("Invalid privacy policy URL")
            return
        }
        UIApplication.shared.open(url)
        Logger.debug("Opened privacy policy")
    }
    
    /// Opens the terms of service website
    func openTermsOfService() {
        guard let url = URL(string: AppConstants.App.termsOfServiceURL) else {
            Logger.error("Invalid terms of service URL")
            return
        }
        UIApplication.shared.open(url)
        Logger.debug("Opened terms of service")
    }
    
    /// Shows logout confirmation dialog
    func confirmLogout() {
        showLogoutConfirmation = true
        Logger.debug("Logout confirmation shown")
    }
    
    /// Logs out the current user
    func logout() {
        isLoggingOut = true
        authService.logout { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                NotificationCenter.default.post(name: Notification.Name("LogoutCompleted"), object: nil)
                Logger.debug("Logout successful")
            case .failure(let error):
                errorMessage = "Logout failed: \(error.localizedDescription)"
                showErrorAlert = true
                Logger.error("Logout failed: \(error)")
            }
            
            isLoggingOut = false
            showLogoutConfirmation = false
        }
    }
    
    /// Gets the list of available languages
    func getAvailableLanguages() -> [String] {
        return ["es", "en"]
    }
    
    /// Gets the display name for a language code
    /// - Parameter languageCode: The language code
    /// - Returns: Localized language name
    func getLanguageDisplayName(languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        let displayName = locale.localizedString(forIdentifier: languageCode) ?? languageCode
        return displayName.capitalized
    }
    
    /// Prepares for navigation to notification settings
    func navigateToNotificationSettings() {
        Logger.debug("Navigating to notification settings")
    }
    
    /// Prepares for navigation to privacy settings
    func navigateToPrivacySettings() {
        Logger.debug("Navigating to privacy settings")
    }
}