//
// BaseScreen.swift
// AmiraWellnessUITests
//
// Base class for screen objects in UI tests, implementing the Page Object pattern 
// to provide common functionality for interacting with UI elements, waiting for conditions,
// and verifying states across all screens in the Amira Wellness app.
//

import XCTest

/// Base class for all screen objects in UI tests, providing common functionality
class BaseScreen {
    // MARK: - Properties
    
    /// The application under test
    let app: XCUIApplication
    
    /// The root element that identifies this screen (to be set by subclasses)
    var rootElement: XCUIElement!
    
    // MARK: - Initialization
    
    /// Initializes a new BaseScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    init(app: XCUIApplication) {
        self.app = app
        // rootElement should be set by subclasses
    }
    
    // MARK: - Screen Navigation
    
    /// Waits for the screen to be displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the screen was displayed within the timeout
    func waitForScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        // If rootElement is not set, assume the screen is already displayed
        guard rootElement != nil else {
            return true
        }
        
        return waitForElement(rootElement, timeout: timeout)
    }
    
    // MARK: - Element Interaction
    
    /// Waits for an element to appear on the screen
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: The maximum time to wait for the element
    /// - Returns: Whether the element appeared within the timeout
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElement(element, timeout: timeout)
    }
    
    /// Waits for an element to disappear from the screen
    /// - Parameters:
    ///   - element: The element to wait for disappearance
    ///   - timeout: The maximum time to wait for the element to disappear
    /// - Returns: Whether the element disappeared within the timeout
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElementToDisappear(element, timeout: timeout)
    }
    
    /// Taps on an element after waiting for it to be hittable
    /// - Parameters:
    ///   - element: The element to tap
    ///   - timeout: The maximum time to wait for the element
    /// - Returns: Whether the element was successfully tapped
    func tapElement(_ element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(element, timeout: timeout)
    }
    
    /// Enters text into an element after waiting for it to be hittable
    /// - Parameters:
    ///   - element: The element to enter text into
    ///   - text: The text to enter
    ///   - timeout: The maximum time to wait for the element
    /// - Returns: Whether the text was successfully entered
    func enterText(_ element: XCUIElement, text: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return enterText(element, text: text, timeout: timeout)
    }
    
    /// Scrolls to make an element visible
    /// - Parameters:
    ///   - scrollView: The scroll view to scroll
    ///   - element: The element to scroll to
    ///   - timeout: The maximum time to wait for the element
    /// - Returns: Whether the element was found and scrolled to
    func scrollToElement(_ scrollView: XCUIElement, element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return scrollToElement(scrollView, element: element, timeout: timeout)
    }
    
    /// Dismisses the keyboard if it is currently displayed
    /// - Returns: Whether the keyboard was successfully dismissed
    func dismissKeyboard() -> Bool {
        return dismissKeyboard(app)
    }
    
    // MARK: - Verification Methods
    
    /// Verifies that an element exists on the screen
    /// - Parameters:
    ///   - element: The element to verify
    ///   - timeout: The maximum time to wait for the element
    /// - Returns: Whether the element exists
    func verifyElementExists(_ element: XCUIElement, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElement(element, timeout: timeout)
    }
    
    /// Verifies that an element has the expected text
    /// - Parameters:
    ///   - element: The element to check
    ///   - expectedText: The expected text
    ///   - timeout: The maximum time to wait for the element
    /// - Returns: Whether the element has the expected text
    func verifyElementHasText(_ element: XCUIElement, expectedText: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        guard waitForElement(element, timeout: timeout) else {
            return false
        }
        
        // Check if element has the expected text (label or value)
        if let value = element.value as? String {
            return value == expectedText
        } else if let label = element.label as String? {
            return label == expectedText
        }
        
        return false
    }
    
    /// Verifies that an element contains the expected text
    /// - Parameters:
    ///   - element: The element to check
    ///   - expectedText: The text that should be contained
    ///   - timeout: The maximum time to wait for the element
    /// - Returns: Whether the element contains the expected text
    func verifyElementContainsText(_ element: XCUIElement, expectedText: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        guard waitForElement(element, timeout: timeout) else {
            return false
        }
        
        // Check if element contains the expected text (label or value)
        if let value = element.value as? String {
            return value.contains(expectedText)
        } else if let label = element.label as String? {
            return label.contains(expectedText)
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    /// Takes a screenshot with a descriptive name
    /// - Parameters:
    ///   - testCase: The test case to attach the screenshot to
    ///   - name: The descriptive name for the screenshot
    func takeScreenshot(_ testCase: XCTestCase, name: String) {
        takeScreenshot(testCase, name: name)
    }
    
    /// Performs a swipe up gesture on an element
    /// - Parameter element: The element to swipe on
    func swipeUp(_ element: XCUIElement) {
        element.swipeUp()
    }
    
    /// Performs a swipe down gesture on an element
    /// - Parameter element: The element to swipe on
    func swipeDown(_ element: XCUIElement) {
        element.swipeDown()
    }
    
    /// Performs a swipe left gesture on an element
    /// - Parameter element: The element to swipe on
    func swipeLeft(_ element: XCUIElement) {
        element.swipeLeft()
    }
    
    /// Performs a swipe right gesture on an element
    /// - Parameter element: The element to swipe on
    func swipeRight(_ element: XCUIElement) {
        element.swipeRight()
    }
    
    /// Waits for loading indicators to disappear
    /// - Parameter timeout: The maximum time to wait for loading to complete
    /// - Returns: Whether loading completed within the timeout
    func waitForLoadingToComplete(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
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
    
    /// Checks if an element is currently visible on screen
    /// - Parameter element: The element to check for visibility
    /// - Returns: Whether the element is visible
    func isElementVisible(_ element: XCUIElement) -> Bool {
        return isElementVisible(element)
    }
    
    /// Finds an element containing the specified text
    /// - Parameters:
    ///   - text: The text to search for
    ///   - elementType: The type of element to find
    /// - Returns: The found element or nil if not found
    func findElementByText(_ text: String, elementType: XCUIElement.ElementType = .any) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)
        let elements = app.descendants(matching: elementType).matching(predicate)
        return elements.count > 0 ? elements.element(boundBy: 0) : nil
    }
    
    /// Finds an element with the exact specified text
    /// - Parameters:
    ///   - text: The exact text to search for
    ///   - elementType: The type of element to find
    /// - Returns: The found element or nil if not found
    func findElementByExactText(_ text: String, elementType: XCUIElement.ElementType = .any) -> XCUIElement? {
        let predicate = NSPredicate(format: "label == %@ OR value == %@", text, text)
        let elements = app.descendants(matching: elementType).matching(predicate)
        return elements.count > 0 ? elements.element(boundBy: 0) : nil
    }
    
    /// Handles a system alert by tapping a button with the specified label
    /// - Parameter buttonLabel: The label of the button to tap
    /// - Returns: Whether an alert was handled
    func handleSystemAlert(buttonLabel: String = "Allow") -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        
        if springboard.alerts.count > 0 {
            let alert = springboard.alerts.element(boundBy: 0)
            
            if alert.buttons[buttonLabel].exists {
                alert.buttons[buttonLabel].tap()
                return true
            }
        }
        
        return false
    }
}