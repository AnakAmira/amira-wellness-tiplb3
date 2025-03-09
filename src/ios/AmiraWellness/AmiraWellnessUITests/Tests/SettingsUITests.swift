//
// SettingsUITests.swift
// AmiraWellnessUITests
//
// UI test suite for the Settings functionality in the Amira Wellness application,
// testing theme selection, notification settings, privacy settings, language preferences, and logout functionality.
//

import XCTest

class SettingsUITests: XCTestCase {
    // MARK: - Properties
    
    var app: XCUIApplication!
    var homeScreen: HomeScreen!
    var settingsScreen: SettingsScreen!
    var loginScreen: LoginScreen!
    
    let testEmail: String = "test@example.com"
    let testPassword: String = "Password123!"
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize app and screen objects
        app = XCUIApplication()
        homeScreen = HomeScreen(app: app)
        settingsScreen = SettingsScreen(app: app)
        loginScreen = LoginScreen(app: app)
        
        // Stop tests on first failure
        continueAfterFailure = false
        
        // Launch the app and log in
        _ = UITestHelpers.launchAppAndLogin(app, email: testEmail, password: testPassword)
        
        // Verify the home screen is displayed
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        
        // Navigate to the settings screen
        XCTAssertTrue(homeScreen.tapSettingsButton(), "Should be able to tap settings button")
    }
    
    override func tearDown() {
        super.tearDown()
        app.terminate()
    }
    
    // MARK: - Test Cases
    
    func testSettingsScreenDisplayed() {
        // Verify the settings screen is displayed
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Settings screen should be displayed")
    }
    
    func testThemeSelection() {
        // Select Light theme
        XCTAssertTrue(settingsScreen.selectThemeMode("Claro"), "Should be able to select Light theme")
        XCTAssertTrue(settingsScreen.verifyThemeMode("Claro"), "Theme should be set to Light")
        
        // Select Dark theme
        XCTAssertTrue(settingsScreen.selectThemeMode("Oscuro"), "Should be able to select Dark theme")
        XCTAssertTrue(settingsScreen.verifyThemeMode("Oscuro"), "Theme should be set to Dark")
        
        // Select System theme
        XCTAssertTrue(settingsScreen.selectThemeMode("Sistema"), "Should be able to select System theme")
        XCTAssertTrue(settingsScreen.verifyThemeMode("Sistema"), "Theme should be set to System")
    }
    
    func testNotificationToggle() {
        // Get current notification state
        let initialState = settingsScreen.verifyNotificationsEnabled(true)
        
        // Toggle notifications
        XCTAssertTrue(settingsScreen.toggleNotifications(), "Should be able to toggle notifications")
        
        // Verify the state changed
        XCTAssertTrue(settingsScreen.verifyNotificationsEnabled(!initialState), "Notification state should change")
        
        // Toggle notifications again to restore original state
        XCTAssertTrue(settingsScreen.toggleNotifications(), "Should be able to toggle notifications again")
        
        // Verify the state is back to original
        XCTAssertTrue(settingsScreen.verifyNotificationsEnabled(initialState), "Notification state should be restored")
    }
    
    func testNavigateToNotificationSettings() {
        // Navigate to notification settings
        XCTAssertTrue(settingsScreen.navigateToNotificationSettings(), "Should navigate to notification settings")
        
        // Navigate back to the main settings screen
        if app.navigationBars["Notificaciones"].buttons.firstMatch.exists {
            app.navigationBars["Notificaciones"].buttons.firstMatch.tap()
        }
        
        // Verify we're back at the settings screen
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Should return to settings screen")
    }
    
    func testBiometricAuthToggle() {
        // Skip this test if biometric authentication is not available
        guard settingsScreen.isBiometricAuthAvailable() else {
            throw XCTSkip("Biometric authentication is not available on this device")
        }
        
        // Get current biometric auth state
        let initialState = settingsScreen.verifyBiometricAuthEnabled(true)
        
        // Toggle biometric authentication
        XCTAssertTrue(settingsScreen.toggleBiometricAuth(), "Should be able to toggle biometric auth")
        
        // Verify the state changed
        XCTAssertTrue(settingsScreen.verifyBiometricAuthEnabled(!initialState), "Biometric auth state should change")
        
        // Toggle biometric authentication again to restore original state
        XCTAssertTrue(settingsScreen.toggleBiometricAuth(), "Should be able to toggle biometric auth again")
        
        // Verify the state is back to original
        XCTAssertTrue(settingsScreen.verifyBiometricAuthEnabled(initialState), "Biometric auth state should be restored")
    }
    
    func testNavigateToPrivacySettings() {
        // Navigate to privacy settings
        XCTAssertTrue(settingsScreen.navigateToPrivacySettings(), "Should navigate to privacy settings")
        
        // Navigate back to the main settings screen
        if app.navigationBars["Gestión de datos"].buttons.firstMatch.exists {
            app.navigationBars["Gestión de datos"].buttons.firstMatch.tap()
        }
        
        // Verify we're back at the settings screen
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Should return to settings screen")
    }
    
    func testLanguageSelection() {
        // Get the current language (assuming Spanish is default)
        let currentLanguage = "Español"
        
        // Select a different language
        XCTAssertTrue(settingsScreen.selectLanguage("English"), "Should be able to select English language")
        XCTAssertTrue(settingsScreen.verifySelectedLanguage("English"), "Language should be set to English")
        
        // Select the original language to restore
        XCTAssertTrue(settingsScreen.selectLanguage(currentLanguage), "Should be able to select original language")
        XCTAssertTrue(settingsScreen.verifySelectedLanguage(currentLanguage), "Language should be restored")
    }
    
    func testHelpCenterNavigation() {
        // Tap the help center button
        XCTAssertTrue(settingsScreen.tapHelpCenter(), "Should be able to tap help center button")
        
        // Verify that the help center web view is displayed
        let webViewExists = app.webViews.firstMatch.waitForExistence(timeout: TimeoutDuration.standard)
        XCTAssertTrue(webViewExists, "Help center web view should be displayed")
        
        // Navigate back to the settings screen
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Verify we're back at the settings screen
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Should return to settings screen")
    }
    
    func testContactSupportNavigation() {
        // Tap the contact support button
        XCTAssertTrue(settingsScreen.tapContactSupport(), "Should be able to tap contact support button")
        
        // Check if email composer appeared or a system alert is shown
        let emailComposerExists = app.otherElements["MFMailComposeViewController"].waitForExistence(timeout: TimeoutDuration.short)
        
        if emailComposerExists {
            // If email composer appeared, dismiss it
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
        } else {
            // Handle any system alerts
            _ = UITestHelpers.handleSystemPermissionAlert()
        }
        
        // Navigate back to the settings screen if needed
        if !settingsScreen.waitForSettingsScreen(timeout: TimeoutDuration.short) {
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
        
        // Verify we're back at the settings screen
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Should return to settings screen")
    }
    
    func testPrivacyPolicyNavigation() {
        // Tap the privacy policy button
        XCTAssertTrue(settingsScreen.tapPrivacyPolicy(), "Should be able to tap privacy policy button")
        
        // Verify that the privacy policy web view is displayed
        let webViewExists = app.webViews.firstMatch.waitForExistence(timeout: TimeoutDuration.standard)
        XCTAssertTrue(webViewExists, "Privacy policy web view should be displayed")
        
        // Navigate back to the settings screen
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Verify we're back at the settings screen
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Should return to settings screen")
    }
    
    func testTermsOfServiceNavigation() {
        // Tap the terms of service button
        XCTAssertTrue(settingsScreen.tapTermsOfService(), "Should be able to tap terms of service button")
        
        // Verify that the terms of service web view is displayed
        let webViewExists = app.webViews.firstMatch.waitForExistence(timeout: TimeoutDuration.standard)
        XCTAssertTrue(webViewExists, "Terms of service web view should be displayed")
        
        // Navigate back to the settings screen
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Verify we're back at the settings screen
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Should return to settings screen")
    }
    
    func testLogoutCancellation() {
        // Tap the logout button
        XCTAssertTrue(settingsScreen.tapLogout(), "Should be able to tap logout button")
        
        // Cancel the logout
        XCTAssertTrue(settingsScreen.cancelLogout(), "Should be able to cancel logout")
        
        // Verify we're still on the settings screen
        XCTAssertTrue(settingsScreen.waitForSettingsScreen(), "Should still be on settings screen after cancelling logout")
    }
    
    func testLogoutConfirmation() {
        // Tap the logout button
        XCTAssertTrue(settingsScreen.tapLogout(), "Should be able to tap logout button")
        
        // Confirm the logout
        XCTAssertTrue(settingsScreen.confirmLogout(), "Should be able to confirm logout")
        
        // Verify the login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Should be on login screen after logout")
    }
}