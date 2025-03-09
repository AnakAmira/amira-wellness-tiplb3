//
// EmotionalCheckinUITests.swift
// AmiraWellnessUITests
//
// UI tests for the Emotional Check-in feature of the Amira Wellness application.
//

import XCTest

class EmotionalCheckinUITests: XCTestCase {
    // MARK: - Properties
    
    var app: XCUIApplication!
    var homeScreen: HomeScreen!
    var emotionalCheckinScreen: EmotionalCheckinScreen!
    var toolLibraryScreen: ToolLibraryScreen!
    var loginScreen: LoginScreen!
    
    let testUserEmail = "test@example.com"
    let testUserPassword = "TestPassword123"
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize app and add test arguments
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        
        // Initialize screen objects
        homeScreen = HomeScreen(app: app)
        emotionalCheckinScreen = EmotionalCheckinScreen(app: app)
        toolLibraryScreen = ToolLibraryScreen(app: app)
        loginScreen = LoginScreen(app: app)
        
        // Launch app and ensure user is logged in
        app.launch()
        ensureUserLoggedIn()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testEmotionalCheckinBasicFlow() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        
        XCTAssertTrue(emotionalCheckinScreen.waitForEmotionalCheckinScreen(), "Emotional check-in screen should be displayed")
        XCTAssertTrue(emotionalCheckinScreen.selectEmotion("Alegría"), "Should be able to select an emotion")
        XCTAssertTrue(emotionalCheckinScreen.adjustIntensity(0.7), "Should be able to adjust intensity")
        XCTAssertTrue(emotionalCheckinScreen.tapContinueButton(), "Should be able to tap continue button")
        
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        XCTAssertTrue(emotionalCheckinScreen.tapReturnToHomeButton(), "Should be able to return to home")
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Should return to home screen")
    }
    
    func testEmotionalCheckinWithNotes() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        
        XCTAssertTrue(emotionalCheckinScreen.waitForEmotionalCheckinScreen(), "Emotional check-in screen should be displayed")
        XCTAssertTrue(emotionalCheckinScreen.selectEmotion("Ansiedad"), "Should be able to select an emotion")
        XCTAssertTrue(emotionalCheckinScreen.adjustIntensity(0.8), "Should be able to adjust intensity")
        XCTAssertTrue(emotionalCheckinScreen.enterNotes("Me siento un poco ansiosa hoy"), "Should be able to enter notes")
        XCTAssertTrue(emotionalCheckinScreen.tapContinueButton(), "Should be able to tap continue button")
        
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        XCTAssertTrue(emotionalCheckinScreen.tapReturnToHomeButton(), "Should be able to return to home")
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Should return to home screen")
    }
    
    func testEmotionalCheckinResultsAndRecommendations() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        
        // Complete an emotional check-in with anxiety
        XCTAssertTrue(performEmotionalCheckin(emotion: "Ansiedad", intensity: 0.8), "Should complete emotional check-in")
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        
        // Verify that anxiety-related tools are recommended
        XCTAssertTrue(emotionalCheckinScreen.verifyRecommendedToolExists("Respiración para ansiedad"), 
                     "Anxiety-related breathing tool should be recommended")
        XCTAssertTrue(emotionalCheckinScreen.verifyRecommendedToolExists("Meditación para ansiedad"), 
                     "Anxiety-related meditation tool should be recommended")
    }
    
    func testNavigationToRecommendedTool() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        
        // Complete an emotional check-in
        XCTAssertTrue(performEmotionalCheckin(emotion: "Ansiedad", intensity: 0.8), "Should complete emotional check-in")
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        
        // Select a recommended tool
        XCTAssertTrue(emotionalCheckinScreen.selectRecommendedTool("Respiración 4-7-8"), "Should select a recommended tool")
        
        // Navigate back to home screen
        // Note: In a real test, you would verify the tool detail screen here
        // but we'll navigate back to home screen for this test
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Should return to results screen")
        XCTAssertTrue(emotionalCheckinScreen.tapReturnToHomeButton(), "Should tap return to home button")
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Should return to home screen")
    }
    
    func testNavigationToToolLibrary() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        
        // Complete an emotional check-in
        XCTAssertTrue(performEmotionalCheckin(emotion: "Calma", intensity: 0.6), "Should complete emotional check-in")
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        
        // Tap the view all tools button
        XCTAssertTrue(emotionalCheckinScreen.tapViewAllToolsButton(), "Should tap view all tools button")
        XCTAssertTrue(toolLibraryScreen.waitForToolLibraryScreen(), "Tool library screen should be displayed")
        
        // Verify a tool is visible in the library
        XCTAssertTrue(toolLibraryScreen.isToolVisible("Respiración 4-7-8"), "Breathing tool should be visible in library")
        
        // Navigate back to home
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Should return to home screen")
    }
    
    func testEmotionalStateUpdatedOnHomeScreen() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        
        // Complete an emotional check-in with a specific emotion
        XCTAssertTrue(performEmotionalCheckin(emotion: "Calma", intensity: 0.7), "Should complete emotional check-in")
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        XCTAssertTrue(emotionalCheckinScreen.tapReturnToHomeButton(), "Should return to home")
        
        // Verify that the emotional state is updated on the home screen
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.verifyCurrentEmotionalState("Calma"), "Home screen should show updated emotional state")
    }
    
    func testMultipleEmotionalCheckins() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        
        // First check-in with joy
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        XCTAssertTrue(performEmotionalCheckin(emotion: "Alegría", intensity: 0.7), "Should complete first emotional check-in")
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        XCTAssertTrue(emotionalCheckinScreen.tapReturnToHomeButton(), "Should return to home")
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.verifyCurrentEmotionalState("Alegría"), "Home screen should show first emotion")
        
        // Second check-in with anxiety
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        XCTAssertTrue(performEmotionalCheckin(emotion: "Ansiedad", intensity: 0.5), "Should complete second emotional check-in")
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
        XCTAssertTrue(emotionalCheckinScreen.tapReturnToHomeButton(), "Should return to home")
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.verifyCurrentEmotionalState("Ansiedad"), "Home screen should show second emotion")
    }
    
    func testEmotionSelectionValidation() {
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        XCTAssertTrue(homeScreen.tapEmotionalCheckinButton(), "Should be able to tap emotional check-in button")
        
        XCTAssertTrue(emotionalCheckinScreen.waitForEmotionalCheckinScreen(), "Emotional check-in screen should be displayed")
        
        // Try to continue without selecting an emotion (button should be disabled)
        XCTAssertFalse(emotionalCheckinScreen.tapContinueButton(), "Continue button should be disabled without emotion selection")
        
        // Now select an emotion and verify it's selected
        XCTAssertTrue(emotionalCheckinScreen.selectEmotion("Alegría"), "Should be able to select an emotion")
        XCTAssertTrue(emotionalCheckinScreen.verifyEmotionSelected("Alegría"), "Emotion should be selected")
        
        // Now the continue button should be enabled
        XCTAssertTrue(emotionalCheckinScreen.adjustIntensity(0.6), "Should be able to adjust intensity")
        XCTAssertTrue(emotionalCheckinScreen.tapContinueButton(), "Continue button should be enabled after emotion selection")
        XCTAssertTrue(emotionalCheckinScreen.verifyResultScreen(), "Results screen should be displayed")
    }
    
    // MARK: - Helper Methods
    
    /// Ensures that a user is logged in before running tests
    private func ensureUserLoggedIn() {
        // Check if already on the home screen
        if homeScreen.waitForHomeScreen(timeout: TimeoutDuration.short) {
            return
        }
        
        // If on login screen, perform login
        if loginScreen.waitForLoginScreen(timeout: TimeoutDuration.short) {
            XCTAssertTrue(loginScreen.login(email: testUserEmail, password: testUserPassword), 
                         "Should be able to log in with test credentials")
            XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear after login")
        } else {
            // Not on home or login screen, try using the helper to launch and login
            XCTAssertTrue(launchAppAndLogin(app, email: testUserEmail, password: testUserPassword), 
                         "Should be able to launch app and log in")
            XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear after login")
        }
    }
    
    /// Performs a complete emotional check-in with the specified parameters
    /// - Parameters:
    ///   - emotion: The emotion to select
    ///   - intensity: The intensity value (0.0-1.0)
    ///   - notes: Optional notes to enter
    /// - Returns: Whether the check-in was completed successfully
    private func performEmotionalCheckin(emotion: String, intensity: Double, notes: String? = nil) -> Bool {
        guard emotionalCheckinScreen.waitForEmotionalCheckinScreen() else {
            return false
        }
        
        guard emotionalCheckinScreen.selectEmotion(emotion) else {
            return false
        }
        
        guard emotionalCheckinScreen.adjustIntensity(intensity) else {
            return false
        }
        
        if let notes = notes {
            guard emotionalCheckinScreen.enterNotes(notes) else {
                return false
            }
        }
        
        return emotionalCheckinScreen.tapContinueButton()
    }
}