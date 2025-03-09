//
// OnboardingScreen.swift
// AmiraWellnessUITests
//
// A page object for UI testing the onboarding flow in the Amira Wellness app,
// providing methods to interact with and verify the onboarding screens.
//

import XCTest

/// Enum representing the different pages in the onboarding flow
enum OnboardingPage: Int {
    case welcome = 0
    case privacy
    case voiceJournaling
    case emotionalCheckins
    case toolLibrary
    case final
}

/// A page object class for UI testing the onboarding flow in the Amira Wellness app
class OnboardingScreen: BaseScreen {
    // MARK: - UI Elements
    
    let nextButton: XCUIElement
    let backButton: XCUIElement
    let skipButton: XCUIElement
    let getStartedButton: XCUIElement
    let pageTitle: XCUIElement
    let pageDescription: XCUIElement
    let pageImage: XCUIElement
    let progressBar: XCUIElement
    let pageContainer: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new OnboardingScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    init(app: XCUIApplication) {
        // Initialize UI elements
        nextButton = app.buttons["nextButton"]
        backButton = app.buttons["backButton"]
        skipButton = app.buttons["skipButton"]
        getStartedButton = app.buttons["getStartedButton"]
        pageTitle = app.staticTexts["pageTitle"]
        pageDescription = app.staticTexts["pageDescription"]
        pageImage = app.images["pageImage"]
        progressBar = app.progressIndicators["progressBar"]
        pageContainer = app.otherElements["pageContainer"]
        
        super.init(app: app)
        
        // Set the root element
        rootElement = app.scrollViews["onboardingScrollView"]
    }
    
    // MARK: - Screen Interaction
    
    /// Waits for the onboarding screen to be displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the screen was displayed within the timeout
    func waitForOnboardingScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForScreen(timeout: timeout)
    }
    
    /// Taps the Next button to advance to the next onboarding page
    /// - Parameter timeout: The maximum time to wait for the button
    /// - Returns: Whether the button was successfully tapped
    func tapNextButton(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(nextButton, timeout: timeout)
    }
    
    /// Taps the Back button to return to the previous onboarding page
    /// - Parameter timeout: The maximum time to wait for the button
    /// - Returns: Whether the button was successfully tapped
    func tapBackButton(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(backButton, timeout: timeout)
    }
    
    /// Taps the Skip button to bypass the onboarding flow
    /// - Parameter timeout: The maximum time to wait for the button
    /// - Returns: Whether the button was successfully tapped
    func tapSkipButton(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(skipButton, timeout: timeout)
    }
    
    /// Taps the Get Started button on the final onboarding page
    /// - Parameter timeout: The maximum time to wait for the button
    /// - Returns: Whether the button was successfully tapped
    func tapGetStartedButton(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(getStartedButton, timeout: timeout)
    }
    
    /// Swipes left to navigate to the next onboarding page
    func swipeToNextPage() {
        swipeLeft(pageContainer)
    }
    
    /// Swipes right to navigate to the previous onboarding page
    func swipeToPreviousPage() {
        swipeRight(pageContainer)
    }
    
    // MARK: - Verification
    
    /// Verifies that the current page is the expected onboarding page
    /// - Parameters:
    ///   - page: The expected onboarding page
    ///   - timeout: The maximum time to wait for verification
    /// - Returns: Whether the current page matches the expected page
    func verifyCurrentPage(page: OnboardingPage, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let expectedTitle = getExpectedTitle(for: page)
        return verifyElementHasText(pageTitle, expectedText: expectedTitle, timeout: timeout)
    }
    
    /// Verifies that the page title matches the expected text
    /// - Parameters:
    ///   - expectedTitle: The expected title text
    ///   - timeout: The maximum time to wait for verification
    /// - Returns: Whether the page title matches the expected text
    func verifyPageTitle(expectedTitle: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementHasText(pageTitle, expectedText: expectedTitle, timeout: timeout)
    }
    
    /// Verifies that the page description contains the expected text
    /// - Parameters:
    ///   - expectedText: The text that should be contained in the description
    ///   - timeout: The maximum time to wait for verification
    /// - Returns: Whether the page description contains the expected text
    func verifyPageDescription(expectedText: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementContainsText(pageDescription, expectedText: expectedText, timeout: timeout)
    }
    
    /// Checks if the Back button is currently visible
    /// - Returns: Whether the Back button is visible
    func isBackButtonVisible() -> Bool {
        return isElementVisible(backButton)
    }
    
    /// Checks if the Skip button is currently visible
    /// - Returns: Whether the Skip button is visible
    func isSkipButtonVisible() -> Bool {
        return isElementVisible(skipButton)
    }
    
    /// Checks if the Get Started button is currently visible
    /// - Returns: Whether the Get Started button is visible
    func isGetStartedButtonVisible() -> Bool {
        return isElementVisible(getStartedButton)
    }
    
    // MARK: - Flow Completion
    
    /// Completes the entire onboarding flow by navigating through all pages
    /// - Returns: Whether the onboarding was successfully completed
    func completeOnboarding() -> Bool {
        // Wait for the onboarding screen to appear
        guard waitForOnboardingScreen() else {
            return false
        }
        
        // Verify we're on the welcome page
        guard verifyCurrentPage(page: .welcome) else {
            return false
        }
        
        // Navigate through all pages
        for _ in 0..<5 { // 5 pages before the final page
            guard tapNextButton() else {
                return false
            }
        }
        
        // On the final page, tap the Get Started button
        return tapGetStartedButton()
    }
    
    /// Skips the onboarding flow by tapping the Skip button
    /// - Returns: Whether the onboarding was successfully skipped
    func skipOnboarding() -> Bool {
        // Wait for the onboarding screen to appear
        guard waitForOnboardingScreen() else {
            return false
        }
        
        // Tap the Skip button
        return tapSkipButton()
    }
    
    // MARK: - Helper Methods
    
    /// Returns the expected title for a specific onboarding page
    /// - Parameter page: The onboarding page
    /// - Returns: The expected title for the specified page
    private func getExpectedTitle(for page: OnboardingPage) -> String {
        switch page {
        case .welcome:
            return "Bienvenido a Amira Wellness"
        case .privacy:
            return "Tu privacidad es nuestra prioridad"
        case .voiceJournaling:
            return "Diario de voz"
        case .emotionalCheckins:
            return "Check-ins emocionales"
        case .toolLibrary:
            return "Biblioteca de herramientas"
        case .final:
            return "Estás listo para comenzar"
        }
    }
    
    /// Returns the expected description for a specific onboarding page
    /// - Parameter page: The onboarding page
    /// - Returns: The expected description for the specified page
    private func getExpectedDescription(for page: OnboardingPage) -> String {
        switch page {
        case .welcome:
            return "Tu espacio seguro para el bienestar emocional"
        case .privacy:
            return "Tus datos están protegidos con encriptación de extremo a extremo"
        case .voiceJournaling:
            return "Expresa tus emociones a través de la grabación de voz"
        case .emotionalCheckins:
            return "Registra tu estado emocional y observa patrones en el tiempo"
        case .toolLibrary:
            return "Accede a herramientas para mejorar tu bienestar emocional"
        case .final:
            return "Comienza tu viaje hacia el bienestar emocional"
        }
    }
}