//
// AuthenticationUITests.swift
// AmiraWellnessUITests
//
// UI test suite for authentication functionality in the Amira Wellness app,
// implementing comprehensive tests for login, registration, and error handling scenarios.
//

import XCTest

// Test credentials
let validTestEmail = "test@example.com"
let validTestPassword = "Password123!"
let invalidTestEmail = "invalid-email"
let invalidTestPassword = "short"
let nonExistentEmail = "nonexistent@example.com"

class AuthenticationUITests: XCTestCase {
    // MARK: - Properties
    
    var app: XCUIApplication!
    var loginScreen: LoginScreen!
    var onboardingScreen: OnboardingScreen!
    var homeScreen: HomeScreen!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // Continue from previous error
        continueAfterFailure = false
        
        // Initialize app and set launch arguments to indicate UI testing mode
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        // Initialize screen objects
        loginScreen = LoginScreen(app: app)
        onboardingScreen = OnboardingScreen(app: app)
        homeScreen = HomeScreen(app: app)
        
        // Skip onboarding if it appears
        skipOnboardingIfNeeded()
    }
    
    override func tearDownWithError() throws {
        // Continue from previous error
        continueAfterFailure = false
        
        // Terminate the app
        app.terminate()
    }
    
    // MARK: - Helper Methods
    
    private func skipOnboardingIfNeeded() {
        // Check if onboarding screen is displayed
        if onboardingScreen.waitForOnboardingScreen(timeout: TimeoutDuration.short) {
            // If displayed, skip onboarding
            onboardingScreen.skipOnboarding()
        }
    }
    
    // MARK: - Test Cases
    
    func testSuccessfulLogin() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Enter valid credentials and login
        XCTAssertTrue(loginScreen.enterEmail(validTestEmail), "Should be able to enter email")
        XCTAssertTrue(loginScreen.enterPassword(validTestPassword), "Should be able to enter password")
        XCTAssertTrue(loginScreen.tapLoginButton(), "Should be able to tap login button")
        
        // Verify home screen is displayed after successful login
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed after successful login")
        
        // Verify user greeting contains expected username (derived from email)
        let expectedUsername = validTestEmail.components(separatedBy: "@").first ?? ""
        XCTAssertTrue(homeScreen.verifyUserGreeting(userName: expectedUsername), "User greeting should contain the username")
    }
    
    func testInvalidEmailFormat() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Enter invalid email format and valid password
        XCTAssertTrue(loginScreen.enterEmail(invalidTestEmail), "Should be able to enter invalid email")
        XCTAssertTrue(loginScreen.enterPassword(validTestPassword), "Should be able to enter password")
        XCTAssertTrue(loginScreen.tapLoginButton(), "Should be able to tap login button")
        
        // Verify error message about invalid email format is displayed
        XCTAssertTrue(loginScreen.verifyErrorMessage(expectedText: "email"), "Error message about invalid email should be displayed")
    }
    
    func testInvalidPasswordFormat() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Enter valid email and invalid password format
        XCTAssertTrue(loginScreen.enterEmail(validTestEmail), "Should be able to enter email")
        XCTAssertTrue(loginScreen.enterPassword(invalidTestPassword), "Should be able to enter invalid password")
        XCTAssertTrue(loginScreen.tapLoginButton(), "Should be able to tap login button")
        
        // Verify error message about invalid password format is displayed
        XCTAssertTrue(loginScreen.verifyErrorMessage(expectedText: "password"), "Error message about invalid password should be displayed")
    }
    
    func testNonExistentUser() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Enter non-existent email and valid password
        XCTAssertTrue(loginScreen.enterEmail(nonExistentEmail), "Should be able to enter non-existent email")
        XCTAssertTrue(loginScreen.enterPassword(validTestPassword), "Should be able to enter password")
        XCTAssertTrue(loginScreen.tapLoginButton(), "Should be able to tap login button")
        
        // Verify error message about invalid credentials is displayed
        XCTAssertTrue(loginScreen.verifyErrorMessage(expectedText: "invalid"), "Error message about invalid credentials should be displayed")
    }
    
    func testEmptyCredentials() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Clear fields to ensure they're empty
        loginScreen.clearFields()
        
        // Verify login button is disabled or tap fails
        // First check if the button is enabled
        if loginScreen.loginButton.isEnabled {
            // If it's enabled, tapping should either fail or show validation messages
            loginScreen.tapLoginButton()
            XCTAssertTrue(loginScreen.verifyErrorMessage(), "Validation message should be displayed for empty credentials")
        } else {
            // If it's disabled, that's fine too - login shouldn't be possible with empty fields
            XCTAssertFalse(loginScreen.loginButton.isEnabled, "Login button should be disabled with empty credentials")
        }
    }
    
    func testRememberMeOption() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Enter valid credentials, enable remember me, and login
        XCTAssertTrue(loginScreen.enterEmail(validTestEmail), "Should be able to enter email")
        XCTAssertTrue(loginScreen.enterPassword(validTestPassword), "Should be able to enter password")
        XCTAssertTrue(loginScreen.toggleRememberMe(enable: true), "Should be able to enable remember me")
        XCTAssertTrue(loginScreen.tapLoginButton(), "Should be able to tap login button")
        
        // Verify home screen is displayed
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed after successful login")
        
        // Terminate and relaunch the app
        app.terminate()
        app.launch()
        
        // Skip onboarding if needed
        skipOnboardingIfNeeded()
        
        // Verify login screen is displayed with remembered email
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Get the value of the email field
        let emailFieldValue = loginScreen.emailTextField.value as? String ?? ""
        
        // Verify email field is pre-filled with the remembered email
        XCTAssertEqual(emailFieldValue, validTestEmail, "Email field should be pre-filled with remembered email")
    }
    
    func testBiometricLogin() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Check if biometric login is available
        if loginScreen.isBiometricLoginAvailable() {
            // Tap biometric login button
            XCTAssertTrue(loginScreen.tapBiometricLoginButton(), "Should be able to tap biometric login button")
            
            // System biometric prompt handling is done in the page object
            
            // Verify home screen is displayed after successful login
            XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed after successful biometric login")
        } else {
            // Skip test if biometric login is not available
            throw XCTSkip("Biometric login is not available on this device")
        }
    }
    
    func testNavigationToRegistration() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Tap create account button
        XCTAssertTrue(loginScreen.tapCreateAccountButton(), "Should be able to tap create account button")
        
        // Verify registration screen is displayed
        // Since we don't have a RegistrationScreen page object, we'll look for a UI element that indicates
        // the registration screen is displayed
        let registrationTitle = app.staticTexts["Crear una cuenta"]
        XCTAssertTrue(registrationTitle.waitForExistence(timeout: TimeoutDuration.standard), 
                     "Registration screen should be displayed")
    }
    
    func testNavigationToForgotPassword() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Tap forgot password button
        XCTAssertTrue(loginScreen.tapForgotPasswordButton(), "Should be able to tap forgot password button")
        
        // Verify forgot password screen is displayed
        // Since we don't have a ForgotPasswordScreen page object, we'll look for a UI element that indicates
        // the forgot password screen is displayed
        let forgotPasswordTitle = app.staticTexts["¿Olvidaste tu contraseña?"]
        XCTAssertTrue(forgotPasswordTitle.waitForExistence(timeout: TimeoutDuration.standard), 
                     "Forgot password screen should be displayed")
    }
    
    func testSocialLogin() throws {
        // This test might be skipped in CI environments due to system dialog limitations
        if ProcessInfo.processInfo.environment["CI"] == "true" {
            throw XCTSkip("Social login test skipped in CI environment")
        }
        
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Tap a social login button (Google in this case)
        XCTAssertTrue(loginScreen.tapSocialLoginButton(type: .google), "Should be able to tap social login button")
        
        // Handle system dialogs is done in the page object
        
        // Verify either home screen is displayed or appropriate error is shown
        // Since we can't guarantee successful social login in tests, we'll check for either outcome
        if homeScreen.waitForHomeScreen(timeout: TimeoutDuration.long) {
            // Success case - home screen is displayed
            XCTAssertTrue(true, "Social login succeeded")
        } else if loginScreen.verifyErrorMessage() {
            // Error case - error message is displayed
            XCTAssertTrue(true, "Social login showed appropriate error")
        } else {
            // Neither success nor error - test failed
            XCTFail("Social login neither succeeded nor showed an error")
        }
    }
    
    func testLoginWithDifferentAccounts() throws {
        // This test requires two valid test accounts
        let firstAccount = (email: validTestEmail, password: validTestPassword)
        let secondAccount = (email: "second@example.com", password: "Password456!")
        
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Login with first account
        XCTAssertTrue(loginScreen.login(email: firstAccount.email, password: firstAccount.password), 
                     "Should be able to login with first account")
        
        // Verify home screen is displayed
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed after first login")
        
        // Log out
        // Note: We need to navigate to settings and logout, but we don't have those page objects
        // So we'll restart the app as a workaround
        app.terminate()
        app.launch()
        
        // Skip onboarding if needed
        skipOnboardingIfNeeded()
        
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Login with second account
        XCTAssertTrue(loginScreen.login(email: secondAccount.email, password: secondAccount.password), 
                     "Should be able to login with second account")
        
        // Verify home screen is displayed
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed after second login")
        
        // Verify user greeting contains second account username
        let expectedUsername = secondAccount.email.components(separatedBy: "@").first ?? ""
        XCTAssertTrue(homeScreen.verifyUserGreeting(userName: expectedUsername), 
                     "User greeting should contain the second username")
    }
    
    func testLoginAfterAppRestart() throws {
        // Verify login screen is displayed
        XCTAssertTrue(loginScreen.waitForLoginScreen(), "Login screen should be displayed")
        
        // Login with valid credentials
        XCTAssertTrue(loginScreen.login(email: validTestEmail, password: validTestPassword), 
                     "Should be able to login with valid credentials")
        
        // Verify home screen is displayed
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed after login")
        
        // Terminate and relaunch the app
        app.terminate()
        app.launch()
        
        // Skip onboarding if needed
        skipOnboardingIfNeeded()
        
        // Check if user remains logged in or needs to log in again based on app's session management policy
        if homeScreen.waitForHomeScreen(timeout: TimeoutDuration.short) {
            // User remained logged in - verify home screen is displayed
            XCTAssertTrue(true, "User remained logged in after app restart")
        } else if loginScreen.waitForLoginScreen() {
            // User needs to log in again - verify login screen is displayed
            XCTAssertTrue(true, "User needs to log in again after app restart (expected behavior)")
            
            // Login again
            XCTAssertTrue(loginScreen.login(email: validTestEmail, password: validTestPassword), 
                         "Should be able to login again after app restart")
            
            // Verify home screen is displayed
            XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed after login")
        } else {
            // Neither home screen nor login screen - test failed
            XCTFail("Neither home screen nor login screen was displayed after app restart")
        }
    }
}