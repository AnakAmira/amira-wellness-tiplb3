//
// UITestHelpers.swift
// AmiraWellnessUITests
//
// Helper utilities for UI testing in the Amira Wellness app,
// providing common functions for element interaction, waiting, and test setup.
//

import XCTest // XCTest framework version: standard library

// MARK: - Timeout Constants

/// Standard timeout durations for UI testing operations
enum TimeoutDuration {
    /// Short timeout for quick operations (5 seconds)
    static let short: TimeInterval = 5.0
    /// Standard timeout for most operations (10 seconds)
    static let standard: TimeInterval = 10.0
    /// Long timeout for slow operations (30 seconds)
    static let long: TimeInterval = 30.0
}

// MARK: - Element Interaction Helpers

/**
 Waits for an element to exist and be hittable with a timeout
 
 - Parameters:
   - element: The XCUIElement to wait for
   - timeout: The maximum time to wait for the element
 - Returns: Whether the element became hittable within the timeout
 */
func waitForElement(_ element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
    let predicate = NSPredicate(format: "exists == true AND hittable == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    return result == .completed
}

/**
 Waits for an element to disappear with a timeout
 
 - Parameters:
   - element: The XCUIElement to wait for disappearance
   - timeout: The maximum time to wait for the element to disappear
 - Returns: Whether the element disappeared within the timeout
 */
func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    return result == .completed
}

/**
 Taps on an element after waiting for it to be hittable
 
 - Parameters:
   - element: The XCUIElement to tap
   - timeout: The maximum time to wait for the element
 - Returns: Whether the element was successfully tapped
 */
func tapElement(_ element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
    guard waitForElement(element, timeout: timeout) else {
        return false
    }
    
    element.tap()
    return true
}

/**
 Enters text into an element after waiting for it to be hittable
 
 - Parameters:
   - element: The XCUIElement to enter text into
   - text: The text to enter
   - timeout: The maximum time to wait for the element
 - Returns: Whether the text was successfully entered
 */
func enterText(_ element: XCUIElement, text: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
    guard waitForElement(element, timeout: timeout) else {
        return false
    }
    
    element.tap()
    element.typeText(text)
    return true
}

/**
 Scrolls a scroll view to make an element visible
 
 - Parameters:
   - scrollView: The scroll view to scroll
   - element: The element to scroll to
   - timeout: The maximum time to wait for the element
 - Returns: Whether the element was found and scrolled to
 */
func scrollToElement(_ scrollView: XCUIElement, element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
    // Check if element is already visible
    if element.isHittable {
        return true
    }
    
    let startTime = Date()
    var found = false
    
    // Try scrolling down to find the element
    while !found && Date().timeIntervalSince(startTime) < timeout {
        // Check if element is now visible
        if element.exists && element.isHittable {
            found = true
            break
        }
        
        // Swipe up on the scroll view
        scrollView.swipeUp()
        
        // Small delay to allow UI to update
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    // If not found by scrolling down, try scrolling back up
    if !found {
        // Reset to top by scrolling up multiple times
        for _ in 0..<5 {
            scrollView.swipeDown()
        }
        
        // Try scrolling up to find the element
        while !found && Date().timeIntervalSince(startTime) < timeout {
            // Check if element is now visible
            if element.exists && element.isHittable {
                found = true
                break
            }
            
            // Swipe down on the scroll view
            scrollView.swipeDown()
            
            // Small delay to allow UI to update
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    return found
}

/**
 Takes a screenshot with a descriptive name
 
 - Parameters:
   - testCase: The XCTestCase to attach the screenshot to
   - name: The descriptive name for the screenshot
 */
func takeScreenshot(_ testCase: XCTestCase, name: String) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let timestamp = dateFormatter.string(from: Date())
    let screenshotName = "\(timestamp)_\(name)"
    
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = screenshotName
    attachment.lifetime = .keepAlways
    testCase.add(attachment)
}

/**
 Dismisses the keyboard if it is currently displayed
 
 - Parameters:
   - app: The XCUIApplication instance
 - Returns: Whether the keyboard was successfully dismissed
 */
func dismissKeyboard(_ app: XCUIApplication) -> Bool {
    // Check if keyboard is displayed
    guard app.keyboards.element(boundBy: 0).exists else {
        return false
    }
    
    // Try tapping return key if available
    if app.keyboards.buttons["return"].exists {
        app.keyboards.buttons["return"].tap()
        return true
    } else if app.keyboards.buttons["Done"].exists {
        app.keyboards.buttons["Done"].tap()
        return true
    }
    
    // Tap outside the keyboard as a fallback
    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
    
    return !app.keyboards.element(boundBy: 0).exists
}

/**
 Dismisses a system alert if present
 
 - Parameters:
   - app: The XCUIApplication instance
   - buttonLabel: The label of the button to tap on the alert (default: "Allow")
 - Returns: Whether an alert was dismissed
 */
func dismissAlert(_ app: XCUIApplication, buttonLabel: String = "Allow") -> Bool {
    let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.element(boundBy: 0)
    
    if alert.exists {
        if alert.buttons[buttonLabel].exists {
            alert.buttons[buttonLabel].tap()
            return true
        }
    }
    
    return false
}

/**
 Launches the app and performs login with the provided credentials
 
 - Parameters:
   - app: The XCUIApplication instance
   - email: The email to use for login
   - password: The password to use for login
 - Returns: Whether login was successful
 */
func launchAppAndLogin(_ app: XCUIApplication, email: String, password: String) -> Bool {
    app.launch()
    
    // Handle onboarding if presented
    if app.buttons["Comenzar"].exists || app.buttons["Start"].exists {
        if app.buttons["Comenzar"].exists {
            app.buttons["Comenzar"].tap()
        } else {
            app.buttons["Start"].tap()
        }
    }
    
    // Look for login button and tap it if on welcome screen
    if app.buttons["Iniciar Sesión"].exists || app.buttons["Login"].exists {
        if app.buttons["Iniciar Sesión"].exists {
            app.buttons["Iniciar Sesión"].tap()
        } else {
            app.buttons["Login"].tap()
        }
    }
    
    // Wait for login screen
    let emailField = app.textFields.element(matching: .textField, identifier: "email")
    let passwordField = app.secureTextFields.element(matching: .secureTextField, identifier: "password")
    let loginButton = app.buttons["Iniciar Sesión"].exists ? app.buttons["Iniciar Sesión"] : app.buttons["Login"]
    
    guard waitForElement(emailField) else {
        return false
    }
    
    // Enter credentials
    guard enterText(emailField, text: email) else {
        return false
    }
    
    guard enterText(passwordField, text: password) else {
        return false
    }
    
    // Tap login button
    guard tapElement(loginButton) else {
        return false
    }
    
    // Wait for home screen to appear (looking for tab bar or home screen elements)
    let homeIndicator = app.tabBars.firstMatch
    return waitForElement(homeIndicator, timeout: TimeoutDuration.long)
}

/**
 Handles system permission alerts (like microphone, notifications) by allowing or denying
 
 - Parameters:
   - allow: Whether to allow the permission
 - Returns: Whether an alert was handled
 */
func handleSystemPermissionAlert(allow: Bool = true) -> Bool {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    let alertButton = allow ? springboard.buttons["Allow"] : springboard.buttons["Don't Allow"]
    if springboard.alerts.count > 0 && alertButton.exists {
        alertButton.tap()
        return true
    }
    
    return false
}

/**
 Waits for a loading indicator to disappear
 
 - Parameters:
   - app: The XCUIApplication instance
   - timeout: The maximum time to wait for loading to complete
 - Returns: Whether loading completed within the timeout
 */
func waitForLoadingToComplete(_ app: XCUIApplication, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
    // Look for common loading indicators
    let activityIndicator = app.activityIndicators.firstMatch
    let progressIndicator = app.progressIndicators.firstMatch
    let loadingText = app.staticTexts["Loading"].firstMatch
    
    if activityIndicator.exists {
        return waitForElementToDisappear(activityIndicator, timeout: timeout)
    }
    
    if progressIndicator.exists {
        return waitForElementToDisappear(progressIndicator, timeout: timeout)
    }
    
    if loadingText.exists {
        return waitForElementToDisappear(loadingText, timeout: timeout)
    }
    
    // If no loading indicator is visible, we consider loading complete
    return true
}

/**
 Clears the text from a text field
 
 - Parameters:
   - textField: The text field to clear
 - Returns: Whether the text field was cleared successfully
 */
func clearTextField(_ textField: XCUIElement) -> Bool {
    guard waitForElement(textField) else {
        return false
    }
    
    textField.tap()
    
    // Try using keyboard shortcuts to select all text
    textField.press(forDuration: 1.0)
    
    if textField.buttons["Select All"].exists {
        textField.buttons["Select All"].tap()
    }
    
    // Delete the selected text
    textField.typeText(String(XCUIKeyboardKey.delete.rawValue))
    
    return textField.value as? String == "" || textField.value == nil
}

/**
 Checks if an element is currently visible on screen
 
 - Parameters:
   - element: The element to check for visibility
 - Returns: Whether the element is visible
 */
func isElementVisible(_ element: XCUIElement) -> Bool {
    return element.exists && (element.isHittable || !element.frame.isEmpty)
}