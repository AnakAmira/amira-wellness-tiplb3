//
// JournalUITests.swift
// AmiraWellnessUITests
//
// UI tests for the voice journaling functionality in the Amira Wellness app, verifying the complete journaling flow including emotional check-ins, recording, playback, and management features.
//

import XCTest

class JournalUITests: XCTestCase {
    // MARK: - Properties
    
    var app: XCUIApplication!
    var loginScreen: LoginScreen!
    var onboardingScreen: OnboardingScreen!
    var homeScreen: HomeScreen!
    var journalScreen: JournalScreen!
    
    // Test user credentials
    let testEmail = "test@example.com"
    let testPassword = "password123"
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        // Initialize the app
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
        
        // Initialize screen objects
        loginScreen = LoginScreen(app: app)
        onboardingScreen = OnboardingScreen(app: app)
        homeScreen = HomeScreen(app: app)
        journalScreen = JournalScreen(app: app)
        
        // Handle onboarding if needed
        handleOnboardingIfNeeded()
        
        // Log in if needed
        loginIfNeeded()
    }
    
    override func tearDown() {
        super.tearDown()
        app.terminate()
    }
    
    // MARK: - Helper Methods
    
    func handleOnboardingIfNeeded() {
        if onboardingScreen.waitForOnboardingScreen(timeout: TimeoutDuration.short) {
            onboardingScreen.skipOnboarding()
        }
    }
    
    func loginIfNeeded() {
        if loginScreen.waitForLoginScreen(timeout: TimeoutDuration.short) {
            loginScreen.login(email: testEmail, password: testPassword)
        }
        
        homeScreen.waitForHomeScreen()
    }
    
    func ensureJournalExists() {
        // Check if journal list is empty
        if !journalScreen.isJournalListDisplayed() {
            // If empty, create a new journal with default values
            journalScreen.createNewJournal()
        }
        // Verify journal creation was successful
        XCTAssertTrue(journalScreen.isJournalListDisplayed(), "Journal list should be displayed")
    }
    
    // MARK: - Test Cases
    
    func testCreateJournal() {
        // Verify home screen is displayed
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        
        // Get initial journal count from home screen
        let initialJournalCount = homeScreen.getRecentJournalCount()
        
        // Tap create button on home screen
        homeScreen.tapCreateButton()
        
        // Verify pre-recording emotional check-in is displayed and complete it
        XCTAssertTrue(journalScreen.completePreCheckIn(emotion: "Calma", intensity: 7, notes: "Feeling relaxed"), "Should complete pre-recording check-in")
        
        // Verify recording view is displayed
        XCTAssertTrue(journalScreen.isRecordingViewDisplayed(), "Recording view should be displayed")
        
        // Wait for 5 seconds to simulate recording
        sleep(5)
        
        // Tap stop button to end recording
        XCTAssertTrue(journalScreen.tapStopButton(), "Should be able to stop recording")
        
        // Complete post-recording check-in
        XCTAssertTrue(journalScreen.completePostCheckIn(
            emotion: "Alegría", 
            intensity: 8, 
            title: "Test Journal", 
            notes: "Feeling better after recording"
        ), "Should complete post-recording check-in")
        
        // Verify journal list is displayed
        XCTAssertTrue(journalScreen.isJournalListDisplayed(), "Journal list should be displayed")
        
        // Verify journal count has increased by 1
        XCTAssertTrue(journalScreen.verifyJournalCount(initialJournalCount + 1), "Journal count should have increased by 1")
    }
    
    func testViewJournalDetails() {
        // Ensure at least one journal exists by creating one if needed
        ensureJournalExists()
        
        // Tap on the first journal in the list
        XCTAssertTrue(journalScreen.tapJournalAtIndex(0), "Should be able to tap the first journal")
        
        // Verify journal detail view is displayed
        XCTAssertTrue(journalScreen.isJournalDetailDisplayed(), "Journal detail view should be displayed")
        
        // Verify emotional shift section is displayed
        XCTAssertTrue(journalScreen.verifyEmotionalShiftDisplayed(), "Emotional shift should be displayed")
        
        // Take a screenshot of the journal details
        takeScreenshot(self, name: "JournalDetails")
        
        // Tap play button to test audio playback
        XCTAssertTrue(journalScreen.tapPlayButton(), "Should be able to play the journal audio")
        
        // Wait for a few seconds to verify playback
        sleep(3)
    }
    
    func testFavoriteJournal() {
        // Ensure at least one journal exists by creating one if needed
        ensureJournalExists()
        
        // Tap on the first journal in the list
        XCTAssertTrue(journalScreen.tapJournalAtIndex(0), "Should be able to tap the first journal")
        
        // Verify journal detail view is displayed
        XCTAssertTrue(journalScreen.isJournalDetailDisplayed(), "Journal detail view should be displayed")
        
        // Tap favorite button
        XCTAssertTrue(journalScreen.tapFavoriteButton(), "Should be able to favorite the journal")
        
        // Navigate back to journal list
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // Verify the journal is marked as favorite
        // Note: Future enhancement - Add method to JournalScreen to verify favorite status
    }
    
    func testDeleteJournal() {
        // Create a new journal for deletion
        journalScreen.createNewJournal()
        
        // Get initial journal count
        let initialCount = 1
        
        // Tap on the first journal in the list
        XCTAssertTrue(journalScreen.tapJournalAtIndex(0), "Should be able to tap the first journal")
        
        // Verify journal detail view is displayed
        XCTAssertTrue(journalScreen.isJournalDetailDisplayed(), "Journal detail view should be displayed")
        
        // Tap delete button
        XCTAssertTrue(journalScreen.tapDeleteButton(), "Should be able to tap delete button")
        
        // Confirm deletion
        XCTAssertTrue(journalScreen.confirmDelete(), "Should be able to confirm deletion")
        
        // Verify journal list is displayed
        XCTAssertTrue(journalScreen.isJournalListDisplayed(), "Journal list should be displayed after deletion")
        
        // Verify journal count has decreased by 1
        XCTAssertTrue(journalScreen.verifyJournalCount(initialCount - 1), "Journal count should have decreased by 1")
    }
    
    func testJournalFromHomeScreen() {
        // Ensure at least one journal exists by creating one if needed
        ensureJournalExists()
        
        // Navigate to home screen
        homeScreen.waitForHomeScreen()
        
        // Verify recent journal count is greater than 0
        XCTAssertGreaterThan(homeScreen.getRecentJournalCount(), 0, "Recent journal count should be greater than 0")
        
        // Tap on the first recent journal card
        XCTAssertTrue(homeScreen.tapRecentJournalCard(index: 0), "Should be able to tap on a recent journal")
        
        // Verify journal detail view is displayed
        XCTAssertTrue(journalScreen.isJournalDetailDisplayed(), "Journal detail view should be displayed")
    }
    
    func testCreateJournalWithMicrophonePermission() {
        // Verify home screen is displayed
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should be displayed")
        
        // Tap create button on home screen
        homeScreen.tapCreateButton()
        
        // Complete pre-recording check-in
        XCTAssertTrue(journalScreen.completePreCheckIn(emotion: "Calma", intensity: 7), "Should complete pre-recording check-in")
        
        // Handle microphone permission alert if it appears by allowing access
        handleSystemPermissionAlert(allow: true)
        
        // Verify recording view is displayed
        XCTAssertTrue(journalScreen.isRecordingViewDisplayed(), "Recording view should be displayed")
        
        // Wait for 5 seconds to simulate recording
        sleep(5)
        
        // Tap stop button to end recording
        XCTAssertTrue(journalScreen.tapStopButton(), "Should be able to stop recording")
        
        // Complete post-recording check-in
        XCTAssertTrue(journalScreen.completePostCheckIn(
            emotion: "Alegría", 
            intensity: 8, 
            title: "Test Permission Journal"
        ), "Should complete post-recording check-in")
        
        // Verify journal list is displayed
        XCTAssertTrue(journalScreen.isJournalListDisplayed(), "Journal list should be displayed")
    }
}