//
// OnboardingUITests.swift
// AmiraWellnessUITests
//
// UI tests for the onboarding flow in the Amira Wellness app,
// verifying that users can successfully navigate through the introduction screens.
//

import XCTest // XCTest framework version: standard library
import ../Screens/OnboardingScreen
import ../Screens/HomeScreen
import ../Helpers/UITestHelpers

class OnboardingUITests: XCTestCase {
    // Application under test
    var app: XCUIApplication!
    
    // Page objects
    var onboardingScreen: OnboardingScreen!
    var homeScreen: HomeScreen!
    
    override func setUp() {
        super.setUp()
        
        // Initialize the application
        app = XCUIApplication()
        
        // Configure the app for UI testing
        app.launchArguments = ["--uitesting", "--showOnboarding"]
        
        // Initialize page objects
        onboardingScreen = OnboardingScreen(app: app)
        homeScreen = HomeScreen(app: app)
    }
    
    override func tearDown() {
        // Terminate the app if it's running
        if app.state == .runningForeground {
            app.terminate()
        }
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testOnboardingScreenAppears() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Take a screenshot for reference
        takeScreenshot(self, name: "onboarding_welcome_screen")
        
        // Verify initial state
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .welcome), "First page should be welcome page")
        XCTAssertTrue(onboardingScreen.isSkipButtonVisible(), "Skip button should be visible on first page")
        XCTAssertFalse(onboardingScreen.isBackButtonVisible(), "Back button should not be visible on first page")
    }
    
    func testOnboardingNextButtonNavigation() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Verify initial page
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .welcome), "Should start on welcome page")
        
        // Navigate forward
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should be able to tap Next button")
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .privacy), "Should navigate to privacy page")
        XCTAssertTrue(onboardingScreen.isBackButtonVisible(), "Back button should be visible after navigating forward")
        
        // Continue navigation
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should be able to tap Next button")
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .voiceJournaling), "Should navigate to voice journaling page")
        
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should be able to tap Next button")
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .emotionalCheckins), "Should navigate to emotional checkins page")
        
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should be able to tap Next button")
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .toolLibrary), "Should navigate to tool library page")
        
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should be able to tap Next button")
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .final), "Should navigate to final page")
        
        // Verify final page state
        XCTAssertTrue(onboardingScreen.isGetStartedButtonVisible(), "Get Started button should be visible on final page")
        XCTAssertFalse(onboardingScreen.isSkipButtonVisible(), "Skip button should not be visible on final page")
    }
    
    func testOnboardingBackButtonNavigation() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Navigate to privacy page
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should be able to tap Next button")
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .privacy), "Should navigate to privacy page")
        
        // Verify back button is visible
        XCTAssertTrue(onboardingScreen.isBackButtonVisible(), "Back button should be visible")
        
        // Navigate back to welcome page
        XCTAssertTrue(onboardingScreen.tapBackButton(), "Should be able to tap Back button")
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .welcome), "Should navigate back to welcome page")
        
        // Verify back button is not visible on first page
        XCTAssertFalse(onboardingScreen.isBackButtonVisible(), "Back button should not be visible on first page")
    }
    
    func testOnboardingSwipeNavigation() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Verify initial page
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .welcome), "Should start on welcome page")
        
        // Swipe to navigate forward
        onboardingScreen.swipeToNextPage()
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .privacy), "Should navigate to privacy page after swipe")
        
        // Swipe to navigate forward again
        onboardingScreen.swipeToNextPage()
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .voiceJournaling), "Should navigate to voice journaling page after swipe")
        
        // Swipe to navigate backward
        onboardingScreen.swipeToPreviousPage()
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .privacy), "Should navigate back to privacy page after swipe")
    }
    
    func testOnboardingSkip() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Skip onboarding
        XCTAssertTrue(onboardingScreen.tapSkipButton(), "Should be able to tap Skip button")
        
        // Verify we're taken to the home screen
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear after skipping onboarding")
    }
    
    func testCompleteOnboarding() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Navigate through all pages
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to privacy page")
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to voice journaling page")
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to emotional checkins page")
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to tool library page")
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to final page")
        
        // Verify we're on the final page
        XCTAssertTrue(onboardingScreen.verifyCurrentPage(page: .final), "Should be on final page")
        
        // Complete onboarding
        XCTAssertTrue(onboardingScreen.tapGetStartedButton(), "Should be able to tap Get Started button")
        
        // Verify we're taken to the home screen
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear after completing onboarding")
    }
    
    func testOnboardingPageContent() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Verify welcome page content
        XCTAssertTrue(onboardingScreen.verifyPageTitle(expectedTitle: "Bienvenido a Amira Wellness"), "Welcome page should have correct title")
        XCTAssertTrue(onboardingScreen.verifyPageDescription(expectedText: "Tu espacio seguro"), "Welcome page should have correct description")
        
        // Navigate to privacy page and verify content
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to privacy page")
        XCTAssertTrue(onboardingScreen.verifyPageTitle(expectedTitle: "Tu privacidad es nuestra prioridad"), "Privacy page should have correct title")
        XCTAssertTrue(onboardingScreen.verifyPageDescription(expectedText: "encriptación"), "Privacy page should have correct description")
        
        // Navigate to voice journaling page and verify content
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to voice journaling page")
        XCTAssertTrue(onboardingScreen.verifyPageTitle(expectedTitle: "Diario de voz"), "Voice journaling page should have correct title")
        XCTAssertTrue(onboardingScreen.verifyPageDescription(expectedText: "Expresa tus emociones"), "Voice journaling page should have correct description")
        
        // Navigate to emotional checkins page and verify content
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to emotional checkins page")
        XCTAssertTrue(onboardingScreen.verifyPageTitle(expectedTitle: "Check-ins emocionales"), "Emotional checkins page should have correct title")
        XCTAssertTrue(onboardingScreen.verifyPageDescription(expectedText: "Registra tu estado emocional"), "Emotional checkins page should have correct description")
        
        // Navigate to tool library page and verify content
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to tool library page")
        XCTAssertTrue(onboardingScreen.verifyPageTitle(expectedTitle: "Biblioteca de herramientas"), "Tool library page should have correct title")
        XCTAssertTrue(onboardingScreen.verifyPageDescription(expectedText: "herramientas para mejorar"), "Tool library page should have correct description")
        
        // Navigate to final page and verify content
        XCTAssertTrue(onboardingScreen.tapNextButton(), "Should navigate to final page")
        XCTAssertTrue(onboardingScreen.verifyPageTitle(expectedTitle: "Estás listo para comenzar"), "Final page should have correct title")
        XCTAssertTrue(onboardingScreen.verifyPageDescription(expectedText: "Comienza tu viaje"), "Final page should have correct description")
    }
    
    func testOnboardingHelperMethods() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Use the helper method to complete onboarding
        XCTAssertTrue(onboardingScreen.completeOnboarding(), "Should be able to complete onboarding with helper method")
        
        // Verify we're taken to the home screen
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear after completing onboarding")
        
        // Terminate and relaunch with onboarding enabled
        app.terminate()
        app.launch()
        
        // Verify onboarding screen appears again
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Use the helper method to skip onboarding
        XCTAssertTrue(onboardingScreen.skipOnboarding(), "Should be able to skip onboarding with helper method")
        
        // Verify we're taken to the home screen
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear after skipping onboarding")
    }
    
    func testOnboardingDoesNotAppearOnSubsequentLaunch() {
        // Launch the app
        app.launch()
        
        // Verify onboarding screen appears
        XCTAssertTrue(onboardingScreen.waitForOnboardingScreen(), "Onboarding screen should appear")
        
        // Complete onboarding flow
        XCTAssertTrue(onboardingScreen.completeOnboarding(), "Should be able to complete onboarding")
        
        // Verify we're taken to the home screen
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear after completing onboarding")
        
        // Terminate the app
        app.terminate()
        
        // Remove the "showOnboarding" flag to simulate normal launch
        app.launchArguments = ["--uitesting"]
        
        // Relaunch the app
        app.launch()
        
        // Verify we're taken directly to the home screen without showing onboarding
        XCTAssertTrue(homeScreen.waitForHomeScreen(), "Home screen should appear directly without onboarding")
    }
}