//
// LoginScreen.swift
// AmiraWellnessUITests
//
// A page object class for the login screen in UI tests, implementing the Page Object pattern
// to encapsulate interactions with the login screen UI elements and provide a clean API
// for authentication tests.
//

import XCTest

/// Enum representing the types of social login options available
enum SocialLoginType {
    case google
    case apple
    case facebook
}

/// Page object representing the login screen in UI tests
class LoginScreen: BaseScreen {
    // MARK: - UI Elements
    
    let emailTextField: XCUIElement
    let passwordTextField: XCUIElement
    let loginButton: XCUIElement
    let forgotPasswordButton: XCUIElement
    let createAccountButton: XCUIElement
    let rememberMeToggle: XCUIElement
    let biometricLoginButton: XCUIElement
    let googleLoginButton: XCUIElement
    let appleLoginButton: XCUIElement
    let facebookLoginButton: XCUIElement
    let errorMessageText: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new LoginScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    override init(app: XCUIApplication) {
        // Call super.init(app)
        super.init(app: app)
        
        // Initialize rootElement to app.otherElements["loginScreenView"]
        rootElement = app.otherElements["loginScreenView"]
        
        // Initialize UI element references using app.textFields, app.secureTextFields, and app.buttons with appropriate accessibility identifiers
        emailTextField = app.textFields["emailTextField"]
        passwordTextField = app.secureTextFields["passwordTextField"]
        loginButton = app.buttons["loginButton"]
        forgotPasswordButton = app.buttons["forgotPasswordButton"]
        createAccountButton = app.buttons["createAccountButton"]
        rememberMeToggle = app.switches["rememberMeToggle"]
        biometricLoginButton = app.buttons["biometricLoginButton"]
        googleLoginButton = app.buttons["googleLoginButton"]
        appleLoginButton = app.buttons["appleLoginButton"]
        facebookLoginButton = app.buttons["facebookLoginButton"]
        errorMessageText = app.staticTexts["errorMessageText"]
    }
    
    // MARK: - Screen Navigation
    
    /// Waits for the login screen to be displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the login screen was displayed within the timeout
    func waitForLoginScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        // Call waitForScreen(timeout) to wait for the root element
        guard waitForScreen(timeout: timeout) else {
            return false
        }
        
        // Verify that key elements like emailTextField and loginButton exist
        return verifyElementExists(emailTextField) && verifyElementExists(loginButton)
    }
    
    // MARK: - Form Interaction
    
    /// Enters an email address in the email text field
    /// - Parameter email: The email address to enter
    /// - Returns: Whether the email was successfully entered
    func enterEmail(_ email: String) -> Bool {
        return enterText(emailTextField, text: email, timeout: TimeoutDuration.standard)
    }
    
    /// Enters a password in the password text field
    /// - Parameter password: The password to enter
    /// - Returns: Whether the password was successfully entered
    func enterPassword(_ password: String) -> Bool {
        return enterText(passwordTextField, text: password, timeout: TimeoutDuration.standard)
    }
    
    /// Taps the login button
    /// - Returns: Whether the button was successfully tapped
    func tapLoginButton() -> Bool {
        return tapElement(loginButton, timeout: TimeoutDuration.standard)
    }
    
    /// Toggles the remember me switch
    /// - Parameter enable: Whether to enable or disable the switch
    /// - Returns: Whether the toggle was successfully changed
    func toggleRememberMe(enable: Bool = true) -> Bool {
        // Check current state of rememberMeToggle
        if let value = rememberMeToggle.value as? String {
            let isOn = value == "1"
            
            // If current state doesn't match desired state, tap the toggle
            if isOn != enable {
                return tapElement(rememberMeToggle, timeout: TimeoutDuration.standard)
            }
            
            // Already in desired state
            return true
        }
        
        return false
    }
    
    /// Taps the forgot password button
    /// - Returns: Whether the button was successfully tapped
    func tapForgotPasswordButton() -> Bool {
        return tapElement(forgotPasswordButton, timeout: TimeoutDuration.standard)
    }
    
    /// Taps the create account button
    /// - Returns: Whether the button was successfully tapped
    func tapCreateAccountButton() -> Bool {
        return tapElement(createAccountButton, timeout: TimeoutDuration.standard)
    }
    
    /// Taps the biometric login button if available
    /// - Returns: Whether the button was successfully tapped
    func tapBiometricLoginButton() -> Bool {
        // Check if biometricLoginButton exists and is enabled
        guard biometricLoginButton.exists && biometricLoginButton.isEnabled else {
            return false
        }
        
        // If available, call tapElement(biometricLoginButton, TimeoutDuration.standard)
        let result = tapElement(biometricLoginButton, timeout: TimeoutDuration.standard)
        
        // Handle system biometric prompt if it appears
        handleSystemPermissionAlert(allow: true)
        
        return result
    }
    
    /// Checks if biometric login is available
    /// - Returns: Whether biometric login is available
    func isBiometricLoginAvailable() -> Bool {
        // Check if biometricLoginButton exists and is enabled
        return biometricLoginButton.exists && biometricLoginButton.isEnabled
    }
    
    /// Taps a social login button (Google, Apple, or Facebook)
    /// - Parameter type: The type of social login to use
    /// - Returns: Whether the button was successfully tapped
    func tapSocialLoginButton(type: SocialLoginType) -> Bool {
        // Switch on the social login type
        var button: XCUIElement
        
        switch type {
        case .google:
            // For .google, tap googleLoginButton
            button = googleLoginButton
        case .apple:
            // For .apple, tap appleLoginButton
            button = appleLoginButton
        case .facebook:
            // For .facebook, tap facebookLoginButton
            button = facebookLoginButton
        }
        
        let result = tapElement(button, timeout: TimeoutDuration.standard)
        
        // Handle any system dialogs that appear
        handleSystemPermissionAlert(allow: true)
        
        return result
    }
    
    /// Performs a complete login flow with the provided credentials
    /// - Parameters:
    ///   - email: The email address to use
    ///   - password: The password to use
    ///   - rememberMe: Whether to enable remember me
    /// - Returns: Whether the login was successful
    func login(email: String, password: String, rememberMe: Bool = false) -> Bool {
        // Call enterEmail(email)
        guard enterEmail(email) else {
            return false
        }
        
        // Call enterPassword(password)
        guard enterPassword(password) else {
            return false
        }
        
        // If rememberMe is true, call toggleRememberMe(true)
        if rememberMe {
            guard toggleRememberMe(enable: true) else {
                return false
            }
        }
        
        // Call tapLoginButton()
        guard tapLoginButton() else {
            return false
        }
        
        // Wait for either home screen to appear or error message
        let homeScreenIndicator = app.tabBars.firstMatch
        
        // Check for error message
        if waitForElementToAppear(errorMessageText, timeout: TimeoutDuration.standard) {
            // Error message appeared - login failed
            return false
        }
        
        // Return true if login was successful, false otherwise
        return waitForElementToAppear(homeScreenIndicator, timeout: TimeoutDuration.standard)
    }
    
    /// Verifies that an error message is displayed with the expected text
    /// - Parameters:
    ///   - expectedText: The expected text of the error message
    ///   - exactMatch: Whether to check for an exact match or contains
    /// - Returns: Whether the error message matches expectations
    func verifyErrorMessage(expectedText: String = "", exactMatch: Bool = false) -> Bool {
        // Wait for errorMessageText to appear
        guard waitForElementToAppear(errorMessageText, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        // If expectedText is empty, just verify error message exists
        if expectedText.isEmpty {
            return true
        }
        
        // If exactMatch is true, verify error message exactly matches expectedText
        if exactMatch {
            return verifyElementHasText(errorMessageText, expectedText: expectedText)
        } else {
            // If exactMatch is false, verify error message contains expectedText
            return verifyElementContainsText(errorMessageText, expectedText: expectedText)
        }
    }
    
    /// Clears the email and password fields
    func clearFields() {
        // Tap emailTextField and clear its content
        if emailTextField.exists {
            emailTextField.tap()
            
            // Clear text using the textField methods
            if let stringValue = emailTextField.value as? String {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
                emailTextField.typeText(deleteString)
            }
        }
        
        // Tap passwordTextField and clear its content
        if passwordTextField.exists {
            passwordTextField.tap()
            
            // Clear text using the textField methods
            if let stringValue = passwordTextField.value as? String {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
                passwordTextField.typeText(deleteString)
            }
        }
    }
}