//
// SettingsScreen.swift
// AmiraWellnessUITests
//
// Page object class for the Settings screen in UI tests, implementing the Page Object pattern
// to encapsulate interactions with the Settings screen in the Amira Wellness app.
//

import XCTest

/// Page object representing the Settings screen in UI tests
class SettingsScreen: BaseScreen {
    // MARK: - UI Elements
    
    // Navigation
    let settingsNavigationBar: XCUIElement
    
    // Sections
    let accountSection: XCUIElement
    let preferencesSection: XCUIElement
    let notificationsSection: XCUIElement
    let securitySection: XCUIElement
    let helpAndSupportSection: XCUIElement
    
    // Preferences
    let themePickerButton: XCUIElement
    let languagePickerButton: XCUIElement
    
    // Notifications
    let notificationsToggle: XCUIElement
    let notificationSettingsButton: XCUIElement
    
    // Security
    let biometricAuthToggle: XCUIElement
    let privacySettingsButton: XCUIElement
    
    // Help & Support
    let helpCenterButton: XCUIElement
    let contactSupportButton: XCUIElement
    let privacyPolicyButton: XCUIElement
    let termsOfServiceButton: XCUIElement
    
    // Logout
    let logoutButton: XCUIElement
    let logoutConfirmButton: XCUIElement
    let logoutCancelButton: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new SettingsScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    init(app: XCUIApplication) {
        // Initialize UI elements
        settingsNavigationBar = app.navigationBars["Configuración"]
        
        // Sections
        accountSection = app.staticTexts["Cuenta"].firstMatch
        preferencesSection = app.staticTexts["Preferencias"].firstMatch
        notificationsSection = app.staticTexts["Notificaciones"].firstMatch
        securitySection = app.staticTexts["Privacidad y seguridad"].firstMatch
        helpAndSupportSection = app.staticTexts["Ayuda y soporte"].firstMatch
        
        // Preferences
        themePickerButton = app.buttons["Tema"].firstMatch
        languagePickerButton = app.buttons["Idioma"].firstMatch
        
        // Notifications
        notificationsToggle = app.switches["Activar notificaciones"].firstMatch
        notificationSettingsButton = app.buttons["Configuración de notificaciones"].firstMatch
        
        // Security
        biometricAuthToggle = app.switches["Autenticación biométrica"].firstMatch
        privacySettingsButton = app.buttons["Gestión de datos"].firstMatch
        
        // Help & Support
        helpCenterButton = app.buttons["Centro de ayuda"].firstMatch
        contactSupportButton = app.buttons["Contactar soporte"].firstMatch
        privacyPolicyButton = app.buttons["Política de privacidad"].firstMatch
        termsOfServiceButton = app.buttons["Términos de servicio"].firstMatch
        
        // Logout
        logoutButton = app.buttons["Cerrar sesión"].firstMatch
        logoutConfirmButton = app.buttons["Confirmar"].firstMatch
        logoutCancelButton = app.buttons["Cancelar"].firstMatch
        
        // Initialize base class
        super.init(app: app)
        
        // Set the root element for the screen
        self.rootElement = settingsNavigationBar
    }
    
    // MARK: - Screen Verification
    
    /// Waits for the Settings screen to be displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the Settings screen was displayed within the timeout
    func waitForSettingsScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForScreen(timeout: timeout)
    }
    
    // MARK: - Interactions
    
    /// Selects a theme mode from the theme picker
    /// - Parameter themeMode: The theme mode to select (e.g., "Claro", "Oscuro", "Sistema")
    /// - Returns: Whether the theme mode was successfully selected
    func selectThemeMode(_ themeMode: String) -> Bool {
        guard tapElement(themePickerButton) else {
            return false
        }
        
        // Find and tap the theme option button
        if let themeOptionButton = findElementByText(themeMode, elementType: .button) {
            if !tapElement(themeOptionButton) {
                return false
            }
            
            // Wait for the picker to disappear
            return waitForElementToDisappear(themeOptionButton)
        }
        
        return false
    }
    
    /// Toggles the notifications switch
    /// - Returns: Whether the notifications toggle was successfully switched
    func toggleNotifications() -> Bool {
        return tapElement(notificationsToggle)
    }
    
    /// Navigates to the notification settings screen
    /// - Returns: Whether navigation was successful
    func navigateToNotificationSettings() -> Bool {
        guard tapElement(notificationSettingsButton) else {
            return false
        }
        
        // Wait for notification settings screen to appear
        let notificationSettingsTitle = app.navigationBars["Notificaciones"].firstMatch
        return waitForElementToAppear(notificationSettingsTitle)
    }
    
    /// Toggles the biometric authentication switch if available
    /// - Returns: Whether the biometric auth toggle was successfully switched
    func toggleBiometricAuth() -> Bool {
        guard biometricAuthToggle.exists else {
            return false
        }
        
        return tapElement(biometricAuthToggle)
    }
    
    /// Navigates to the privacy settings screen
    /// - Returns: Whether navigation was successful
    func navigateToPrivacySettings() -> Bool {
        guard tapElement(privacySettingsButton) else {
            return false
        }
        
        // Wait for privacy settings screen to appear
        let privacySettingsTitle = app.navigationBars["Gestión de datos"].firstMatch
        return waitForElementToAppear(privacySettingsTitle)
    }
    
    /// Selects a language from the language picker
    /// - Parameter language: The language to select (e.g., "Español", "English")
    /// - Returns: Whether the language was successfully selected
    func selectLanguage(_ language: String) -> Bool {
        guard tapElement(languagePickerButton) else {
            return false
        }
        
        // Find and tap the language option button
        if let languageOptionButton = findElementByText(language, elementType: .button) {
            if !tapElement(languageOptionButton) {
                return false
            }
            
            // Handle any confirmation dialog if it appears
            let confirmButton = app.buttons["Confirmar"].firstMatch
            if confirmButton.exists {
                tapElement(confirmButton)
            }
            
            // Wait for the picker to disappear
            return waitForElementToDisappear(languageOptionButton)
        }
        
        return false
    }
    
    /// Taps on the help center button
    /// - Returns: Whether the help center button was successfully tapped
    func tapHelpCenter() -> Bool {
        return tapElement(helpCenterButton)
    }
    
    /// Taps on the contact support button
    /// - Returns: Whether the contact support button was successfully tapped
    func tapContactSupport() -> Bool {
        return tapElement(contactSupportButton)
    }
    
    /// Taps on the privacy policy button
    /// - Returns: Whether the privacy policy button was successfully tapped
    func tapPrivacyPolicy() -> Bool {
        return tapElement(privacyPolicyButton)
    }
    
    /// Taps on the terms of service button
    /// - Returns: Whether the terms of service button was successfully tapped
    func tapTermsOfService() -> Bool {
        return tapElement(termsOfServiceButton)
    }
    
    /// Taps on the logout button
    /// - Returns: Whether the logout button was successfully tapped and confirmation dialog appeared
    func tapLogout() -> Bool {
        guard tapElement(logoutButton) else {
            return false
        }
        
        // Wait for the logout confirmation dialog
        return waitForElementToAppear(logoutConfirmButton)
    }
    
    /// Confirms logout in the confirmation dialog
    /// - Returns: Whether the logout was successfully confirmed
    func confirmLogout() -> Bool {
        return tapElement(logoutConfirmButton)
    }
    
    /// Cancels logout in the confirmation dialog
    /// - Returns: Whether the logout was successfully canceled
    func cancelLogout() -> Bool {
        guard tapElement(logoutCancelButton) else {
            return false
        }
        
        // Wait for the confirmation dialog to disappear
        return waitForElementToDisappear(logoutConfirmButton)
    }
    
    /// Checks if logout was completed successfully
    /// - Returns: Whether the logout was completed successfully
    func logoutComplete() -> Bool {
        // Check if the login screen is displayed (looking for login button or title)
        let loginButton = app.buttons["Iniciar Sesión"].firstMatch
        let loginTitle = app.staticTexts["Iniciar Sesión"].firstMatch
        
        return waitForElementToAppear(loginButton) || waitForElementToAppear(loginTitle)
    }
    
    // MARK: - Verification Methods
    
    /// Verifies the currently selected theme mode
    /// - Parameter expectedThemeMode: The expected theme mode value
    /// - Returns: Whether the theme mode matches the expected value
    func verifyThemeMode(_ expectedThemeMode: String) -> Bool {
        // Find the theme picker value (it might be displayed as part of the button or as a child element)
        if let themeValueElement = findElementByText(expectedThemeMode) {
            return verifyElementExists(themeValueElement)
        }
        
        // Alternative: check if the button contains the expected value
        return verifyElementContainsText(themePickerButton, expectedText: expectedThemeMode)
    }
    
    /// Verifies whether notifications are enabled
    /// - Parameter expected: The expected state of notifications
    /// - Returns: Whether the notifications state matches the expected value
    func verifyNotificationsEnabled(_ expected: Bool) -> Bool {
        guard notificationsToggle.exists else {
            return false
        }
        
        // Get toggle value (might be "1"/"0" or "true"/"false" depending on the implementation)
        let value = notificationsToggle.value as? String
        let isOn = value == "1" || value == "true"
        
        return isOn == expected
    }
    
    /// Verifies whether biometric authentication is enabled
    /// - Parameter expected: The expected state of biometric authentication
    /// - Returns: Whether the biometric auth state matches the expected value
    func verifyBiometricAuthEnabled(_ expected: Bool) -> Bool {
        guard biometricAuthToggle.exists else {
            return false
        }
        
        // Get toggle value (might be "1"/"0" or "true"/"false" depending on the implementation)
        let value = biometricAuthToggle.value as? String
        let isOn = value == "1" || value == "true"
        
        return isOn == expected
    }
    
    /// Verifies the currently selected language
    /// - Parameter expectedLanguage: The expected language value
    /// - Returns: Whether the language matches the expected value
    func verifySelectedLanguage(_ expectedLanguage: String) -> Bool {
        // Find the language picker value (it might be displayed as part of the button or as a child element)
        if let languageValueElement = findElementByText(expectedLanguage) {
            return verifyElementExists(languageValueElement)
        }
        
        // Alternative: check if the button contains the expected value
        return verifyElementContainsText(languagePickerButton, expectedText: expectedLanguage)
    }
    
    /// Checks if biometric authentication is available on the device
    /// - Returns: Whether biometric authentication is available
    func isBiometricAuthAvailable() -> Bool {
        return biometricAuthToggle.exists
    }
}