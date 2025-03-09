//
// EmotionalCheckinScreen.swift
// AmiraWellnessUITests
//
// Screen object for testing the Emotional Check-in feature in the Amira Wellness app,
// implementing the Page Object pattern for UI test encapsulation.
//

import XCTest

/// Screen object for interacting with the Emotional Check-in screens in UI tests
class EmotionalCheckinScreen: BaseScreen {
    // MARK: - UI Elements
    
    // UI elements for the check-in screen
    let emotionalCheckinTitle: XCUIElement
    let emotionSelector: XCUIElement
    let intensitySlider: XCUIElement
    let notesTextField: XCUIElement
    let continueButton: XCUIElement
    let closeButton: XCUIElement
    
    // UI elements for the results screen
    let resultTitle: XCUIElement
    let recommendedToolsSection: XCUIElement
    let viewAllToolsButton: XCUIElement
    let returnToHomeButton: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new EmotionalCheckinScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    override init(app: XCUIApplication) {
        // Initialize UI elements
        self.emotionalCheckinTitle = app.staticTexts["Check-in emocional"]
        self.emotionSelector = app.otherElements["emotionSelector"]
        self.intensitySlider = app.sliders["intensitySlider"]
        self.notesTextField = app.textFields["notesTextField"]
        self.continueButton = app.buttons["Guardar"]
        self.closeButton = app.buttons["closeButton"]
        
        self.resultTitle = app.staticTexts["Resultados del check-in"]
        self.recommendedToolsSection = app.otherElements["recommendedToolsSection"]
        self.viewAllToolsButton = app.buttons["Ver todas las herramientas"]
        self.returnToHomeButton = app.buttons["Volver al inicio"]
        
        super.init(app: app)
        
        // Set the root element for the screen
        self.rootElement = app.otherElements["emotionalCheckinScreen"]
    }
    
    // MARK: - Screen Interaction Methods
    
    /// Waits for the emotional check-in screen to appear
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the screen appeared within the timeout
    func waitForEmotionalCheckinScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElementToAppear(emotionalCheckinTitle, timeout: timeout)
    }
    
    /// Selects an emotion from the emotion selector
    /// - Parameter emotionName: The name of the emotion to select
    /// - Returns: Whether the emotion was successfully selected
    func selectEmotion(_ emotionName: String) -> Bool {
        let emotionButton = app.buttons[emotionName]
        return tapElement(emotionButton)
    }
    
    /// Adjusts the intensity slider to a specific value
    /// - Parameter normalizedValue: The normalized value (0.0-1.0) to set the slider to
    /// - Returns: Whether the intensity was successfully adjusted
    func adjustIntensity(_ normalizedValue: Double) -> Bool {
        guard waitForElementToAppear(intensitySlider) else {
            return false
        }
        
        intensitySlider.adjust(toNormalizedSliderPosition: normalizedValue)
        return true
    }
    
    /// Enters text in the notes field
    /// - Parameter notes: The text to enter in the notes field
    /// - Returns: Whether the notes were successfully entered
    func enterNotes(_ notes: String) -> Bool {
        return enterText(notesTextField, text: notes)
    }
    
    /// Taps the continue/save button
    /// - Returns: Whether the button was successfully tapped
    func tapContinueButton() -> Bool {
        return tapElement(continueButton)
    }
    
    /// Taps the close button to dismiss the check-in screen
    /// - Returns: Whether the button was successfully tapped
    func tapCloseButton() -> Bool {
        return tapElement(closeButton)
    }
    
    /// Completes an emotional check-in with the specified parameters
    /// - Parameters:
    ///   - emotionName: The name of the emotion to select
    ///   - intensity: The intensity value (0.0-1.0) to set
    ///   - notes: Optional notes to enter
    /// - Returns: Whether the check-in was successfully completed
    func completeEmotionalCheckIn(_ emotionName: String, intensity: Double, notes: String? = nil) -> Bool {
        guard waitForEmotionalCheckinScreen() else {
            return false
        }
        
        guard selectEmotion(emotionName) else {
            return false
        }
        
        guard adjustIntensity(intensity) else {
            return false
        }
        
        if let notes = notes {
            guard enterNotes(notes) else {
                return false
            }
        }
        
        return tapContinueButton()
    }
    
    /// Verifies that the result screen is displayed after completing a check-in
    /// - Parameter timeout: The maximum time to wait for the results screen
    /// - Returns: Whether the result screen is displayed
    func verifyResultScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        guard waitForElementToAppear(resultTitle, timeout: timeout) else {
            return false
        }
        
        return verifyElementExists(recommendedToolsSection)
    }
    
    /// Selects a recommended tool from the results screen
    /// - Parameter toolName: The name of the tool to select
    /// - Returns: Whether the tool was successfully selected
    func selectRecommendedTool(_ toolName: String) -> Bool {
        let toolButton = app.buttons[toolName]
        return tapElement(toolButton)
    }
    
    /// Taps the 'View All Tools' button on the results screen
    /// - Returns: Whether the button was successfully tapped
    func tapViewAllToolsButton() -> Bool {
        return tapElement(viewAllToolsButton)
    }
    
    /// Taps the 'Return to Home' button on the results screen
    /// - Returns: Whether the button was successfully tapped
    func tapReturnToHomeButton() -> Bool {
        return tapElement(returnToHomeButton)
    }
    
    /// Verifies that a specific emotion is selected
    /// - Parameter emotionName: The name of the emotion to verify
    /// - Returns: Whether the emotion is selected
    func verifyEmotionSelected(_ emotionName: String) -> Bool {
        let emotionButton = app.buttons[emotionName]
        guard waitForElementToAppear(emotionButton) else {
            return false
        }
        
        return emotionButton.isSelected
    }
    
    /// Verifies that the intensity slider has a specific value
    /// - Parameters:
    ///   - expectedValue: The expected normalized value (0.0-1.0)
    ///   - tolerance: The acceptable tolerance for the value comparison
    /// - Returns: Whether the intensity value is as expected
    func verifyIntensityValue(_ expectedValue: Double, tolerance: Double = 0.05) -> Bool {
        guard waitForElementToAppear(intensitySlider) else {
            return false
        }
        
        if let value = intensitySlider.value as? Double {
            return abs(value - expectedValue) <= tolerance
        }
        
        return false
    }
    
    /// Verifies that a specific tool is recommended in the results
    /// - Parameters:
    ///   - toolName: The name of the tool to look for
    ///   - timeout: The maximum time to wait for the tool to appear
    /// - Returns: Whether the tool exists in recommendations
    func verifyRecommendedToolExists(_ toolName: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let toolButton = app.buttons[toolName]
        return verifyElementExists(toolButton, timeout: timeout)
    }
}