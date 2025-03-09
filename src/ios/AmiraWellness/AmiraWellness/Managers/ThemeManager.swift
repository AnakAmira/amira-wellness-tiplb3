//
//  ThemeManager.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import SwiftUI // iOS SDK
import Combine // Latest
import UIKit // Latest

/// Enum representing the available theme modes in the application
enum ThemeMode: String, CaseIterable {
    case system
    case light
    case dark
}

/// Notification name constants for theme-related events
enum ThemeNotification {
    static let themeChanged = Notification.Name("ThemeChanged")
}

/// A singleton manager class that handles the application's theme settings,
/// including light/dark mode preferences, color scheme management, and theme-related user preferences.
/// It provides a centralized interface for accessing and modifying the app's visual appearance.
class ThemeManager {
    /// Shared instance of ThemeManager (singleton)
    static let shared = ThemeManager()
    
    /// UserDefaultsManager for storing and retrieving theme preferences
    private let userDefaultsManager: UserDefaultsManager
    
    /// Publisher for theme mode changes
    private let themeSubject: CurrentValueSubject<ThemeMode, Never>
    
    /// Current theme mode setting
    private var currentTheme: ThemeMode = .system
    
    /// Flag indicating whether high contrast mode is enabled
    private var isHighContrastEnabled: Bool = false
    
    /// Text size multiplier for dynamic type (range: 0.8-1.5)
    private var textSizeMultiplier: Double = 1.0
    
    /// Set to store Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Private initializer for singleton pattern
    private init() {
        self.userDefaultsManager = UserDefaultsManager.shared
        self.themeSubject = CurrentValueSubject<ThemeMode, Never>(.system)
        
        // Load saved preferences
        loadSavedPreferences()
        
        // Setup observers for system appearance changes
        setupAppearanceObserver()
        
        Logger.shared.debug("ThemeManager initialized with theme: \(currentTheme.rawValue), highContrast: \(isHighContrastEnabled), textSize: \(textSizeMultiplier)")
    }
    
    /// Initializes the theme manager and loads saved preferences
    func initialize() {
        // Load saved preferences
        loadSavedPreferences()
        
        // Apply initial theme settings
        applyTheme()
        
        // Setup observers for system appearance changes
        setupAppearanceObserver()
        
        Logger.shared.info("ThemeManager initialization complete")
    }
    
    /// Returns a publisher that emits theme mode changes
    /// - Returns: A publisher for theme mode changes
    func themePublisher() -> AnyPublisher<ThemeMode, Never> {
        return themeSubject.eraseToAnyPublisher()
    }
    
    /// Returns the current theme mode
    /// - Returns: Current theme mode
    func getCurrentTheme() -> ThemeMode {
        return currentTheme
    }
    
    /// Sets the application theme mode
    /// - Parameter themeMode: The theme mode to set
    func setTheme(_ themeMode: ThemeMode) {
        currentTheme = themeMode
        
        // Save theme preference
        userDefaultsManager.setString(
            themeMode.rawValue,
            forKey: AppConstants.UserDefaults.userPreferences + ".themeMode"
        )
        
        // Publish new theme
        themeSubject.send(themeMode)
        
        // Post notification for theme change
        NotificationCenter.default.post(name: ThemeNotification.themeChanged, object: nil)
        
        // Apply theme changes to UI
        applyTheme()
        
        Logger.shared.info("Theme changed to \(themeMode.rawValue)")
    }
    
    /// Toggles high contrast mode
    func toggleHighContrast() {
        isHighContrastEnabled = !isHighContrastEnabled
        
        // Save high contrast preference
        userDefaultsManager.setBool(
            isHighContrastEnabled,
            forKey: AppConstants.UserDefaults.userPreferences + ".highContrastEnabled"
        )
        
        // Apply high contrast changes
        applyTheme()
        
        // Post notification for theme change
        NotificationCenter.default.post(name: ThemeNotification.themeChanged, object: nil)
        
        Logger.shared.info("High contrast mode \(isHighContrastEnabled ? "enabled" : "disabled")")
    }
    
    /// Sets high contrast mode to a specific value
    /// - Parameter enabled: Whether high contrast mode should be enabled
    func setHighContrast(_ enabled: Bool) {
        isHighContrastEnabled = enabled
        
        // Save high contrast preference
        userDefaultsManager.setBool(
            isHighContrastEnabled,
            forKey: AppConstants.UserDefaults.userPreferences + ".highContrastEnabled"
        )
        
        // Apply high contrast changes
        applyTheme()
        
        // Post notification for theme change
        NotificationCenter.default.post(name: ThemeNotification.themeChanged, object: nil)
        
        Logger.shared.info("High contrast mode set to \(isHighContrastEnabled ? "enabled" : "disabled")")
    }
    
    /// Returns whether high contrast mode is enabled
    /// - Returns: True if high contrast is enabled, false otherwise
    func isHighContrast() -> Bool {
        return isHighContrastEnabled
    }
    
    /// Sets the text size multiplier for dynamic type
    /// - Parameter multiplier: The multiplier value (should be between 0.8 and 1.5)
    func setTextSizeMultiplier(_ multiplier: Double) {
        // Ensure multiplier is within acceptable range
        let validMultiplier = max(0.8, min(multiplier, 1.5))
        textSizeMultiplier = validMultiplier
        
        // Save text size preference
        userDefaultsManager.setDouble(
            textSizeMultiplier,
            forKey: AppConstants.UserDefaults.userPreferences + ".textSizeMultiplier"
        )
        
        // Apply text size changes
        applyTheme()
        
        // Post notification for theme change
        NotificationCenter.default.post(name: ThemeNotification.themeChanged, object: nil)
        
        Logger.shared.info("Text size multiplier set to \(textSizeMultiplier)")
    }
    
    /// Returns the current text size multiplier
    /// - Returns: Current text size multiplier
    func getTextSizeMultiplier() -> Double {
        return textSizeMultiplier
    }
    
    /// Returns whether dark mode is currently active
    /// - Returns: True if dark mode is active, false otherwise
    func isDarkMode() -> Bool {
        switch currentTheme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            // Check system appearance
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    /// Returns the appropriate color for the current theme
    /// - Parameters:
    ///   - lightModeColor: The color to use in light mode
    ///   - darkModeColor: The color to use in dark mode
    /// - Returns: The appropriate color for the current theme
    func getColor(_ lightModeColor: Color, _ darkModeColor: Color) -> Color {
        return isDarkMode() ? darkModeColor : lightModeColor
    }
    
    /// Returns the primary color for the current theme
    /// - Returns: Primary color for current theme
    func getPrimaryColor() -> Color {
        return getColor(ColorConstants.primary, ColorConstants.primaryDark)
    }
    
    /// Returns the background color for the current theme
    /// - Returns: Background color for current theme
    func getBackgroundColor() -> Color {
        return getColor(ColorConstants.background, ColorConstants.backgroundDark)
    }
    
    // MARK: - Private Methods
    
    /// Applies the current theme settings to the UI
    private func applyTheme() {
        // Apply theme mode changes to UIKit elements if needed
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = isDarkMode() ? .dark : .light
        }
        
        // Apply high contrast settings if enabled
        if isHighContrastEnabled {
            // In a real implementation, this would adjust contrast settings
            // For example, using more extreme colors or increasing text contrast
        }
        
        // Apply text size multiplier to dynamic type settings
        // In a real implementation, this would adjust the content size category
        // or use the multiplier in custom text rendering
        
        Logger.shared.debug("Applied theme: mode=\(currentTheme.rawValue), highContrast=\(isHighContrastEnabled), textSize=\(textSizeMultiplier)")
    }
    
    /// Sets up observers for system appearance changes
    private func setupAppearanceObserver() {
        // Observe trait collection changes for system appearance
        NotificationCenter.default.publisher(for: UITraitCollection.didChangeNotification)
            .sink { [weak self] _ in
                guard let self = self, self.currentTheme == .system else { return }
                
                // System appearance changed and we're in system mode,
                // so we need to update the UI
                self.applyTheme()
                
                // Post notification for theme change
                NotificationCenter.default.post(name: ThemeNotification.themeChanged, object: nil)
                
                Logger.shared.debug("System appearance changed, updated theme")
            }
            .store(in: &cancellables)
        
        Logger.shared.debug("Set up system appearance observer")
    }
    
    /// Loads saved theme preferences from UserDefaults
    private func loadSavedPreferences() {
        // Load theme mode
        let themeModeString = userDefaultsManager.getString(
            forKey: AppConstants.UserDefaults.userPreferences + ".themeMode",
            defaultValue: ThemeMode.system.rawValue
        )
        
        // Convert string to ThemeMode enum or default to system
        if let themeMode = ThemeMode(rawValue: themeModeString) {
            self.currentTheme = themeMode
        } else {
            self.currentTheme = .system
        }
        
        // Update theme subject with current theme
        self.themeSubject.send(self.currentTheme)
        
        // Load high contrast setting
        self.isHighContrastEnabled = userDefaultsManager.getBool(
            forKey: AppConstants.UserDefaults.userPreferences + ".highContrastEnabled",
            defaultValue: false
        )
        
        // Load text size multiplier
        self.textSizeMultiplier = userDefaultsManager.getDouble(
            forKey: AppConstants.UserDefaults.userPreferences + ".textSizeMultiplier",
            defaultValue: 1.0
        )
        
        Logger.shared.debug("Loaded saved preferences: theme=\(currentTheme.rawValue), highContrast=\(isHighContrastEnabled), textSize=\(textSizeMultiplier)")
    }
}