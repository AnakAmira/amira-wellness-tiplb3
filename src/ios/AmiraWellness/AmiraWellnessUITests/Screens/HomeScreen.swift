//
// HomeScreen.swift
// AmiraWellnessUITests
//
// Screen object representing the home screen in UI tests, implementing the Page Object pattern
// to encapsulate home screen UI interactions and verifications for the Amira Wellness app.
//

import XCTest

class HomeScreen: BaseScreen {
    // MARK: - Properties
    
    // UI Elements
    let greetingText: XCUIElement
    let emotionalCheckinButton: XCUIElement
    let currentEmotionalStateCard: XCUIElement
    let recentActivitiesSection: XCUIElement
    let recentJournalCards: XCUIElementQuery
    let recentEmotionCards: XCUIElementQuery
    let recommendedToolsSection: XCUIElement
    let toolCards: XCUIElementQuery
    let streakSection: XCUIElement
    let streakText: XCUIElement
    let streakChart: XCUIElement
    let nextMilestoneText: XCUIElement
    let homeTabButton: XCUIElement
    let favoritesTabButton: XCUIElement
    let createTabButton: XCUIElement
    let profileTabButton: XCUIElement
    let settingsTabButton: XCUIElement
    let scrollView: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new HomeScreen object with the application instance
    /// - Parameter app: The XCUIApplication instance
    override init(app: XCUIApplication) {
        // Initialize UI elements
        self.greetingText = app.staticTexts["greetingText"]
        self.emotionalCheckinButton = app.buttons["emotionalCheckinButton"]
        self.currentEmotionalStateCard = app.otherElements["currentEmotionalStateCard"]
        self.recentActivitiesSection = app.otherElements["recentActivitiesSection"]
        self.recentJournalCards = app.scrollViews["recentJournalScrollView"].otherElements.matching(identifier: "journalCard")
        self.recentEmotionCards = app.scrollViews["recentEmotionScrollView"].otherElements.matching(identifier: "emotionCard")
        self.recommendedToolsSection = app.otherElements["recommendedToolsSection"]
        self.toolCards = app.scrollViews["recommendedToolsScrollView"].otherElements.matching(identifier: "toolCard")
        self.streakSection = app.otherElements["streakSection"]
        self.streakText = app.staticTexts["streakText"]
        self.streakChart = app.otherElements["streakChart"]
        self.nextMilestoneText = app.staticTexts["nextMilestoneText"]
        self.homeTabButton = app.tabBars.buttons["Home"]
        self.favoritesTabButton = app.tabBars.buttons["Favorites"]
        self.createTabButton = app.tabBars.buttons["Create"]
        self.profileTabButton = app.tabBars.buttons["Profile"]
        self.settingsTabButton = app.tabBars.buttons["Settings"]
        self.scrollView = app.scrollViews["homeScrollView"]
        
        super.init(app: app)
        
        // Set the root element for the screen
        self.rootElement = app.otherElements["homeScreenView"]
    }
    
    // MARK: - Screen Interactions
    
    /// Waits for the home screen to be displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the home screen was displayed within the timeout
    func waitForHomeScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let result = waitForScreen(timeout: timeout)
        
        // Wait for content to load
        if result {
            return waitForLoadingToComplete(timeout: timeout)
        }
        
        return result
    }
    
    /// Verifies that the user greeting is displayed with the expected name
    /// - Parameter userName: The user's name that should be in the greeting
    /// - Returns: Whether the greeting contains the user's name
    func verifyUserGreeting(userName: String) -> Bool {
        guard verifyElementExists(greetingText, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        return verifyElementContainsText(greetingText, expectedText: "Hola, \(userName)", timeout: TimeoutDuration.standard)
    }
    
    /// Taps the emotional check-in button
    /// - Returns: Whether the button was successfully tapped
    func tapEmotionalCheckinButton() -> Bool {
        return tapElement(emotionalCheckinButton, timeout: TimeoutDuration.standard)
    }
    
    /// Checks if the current emotional state card is displayed
    /// - Returns: Whether the emotional state card is displayed
    func isCurrentEmotionalStateDisplayed() -> Bool {
        return verifyElementExists(currentEmotionalStateCard, timeout: TimeoutDuration.short)
    }
    
    /// Verifies that the current emotional state displays the expected emotion
    /// - Parameter emotionType: The expected emotion type
    /// - Returns: Whether the emotional state matches the expected type
    func verifyCurrentEmotionalState(emotionType: String) -> Bool {
        guard verifyElementExists(currentEmotionalStateCard, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        return verifyElementContainsText(currentEmotionalStateCard, expectedText: emotionType, timeout: TimeoutDuration.standard)
    }
    
    /// Gets the count of recent journal cards displayed
    /// - Returns: The number of journal cards
    func getRecentJournalCount() -> Int {
        return recentJournalCards.count
    }
    
    /// Gets the count of recent emotion check-in cards displayed
    /// - Returns: The number of emotion check-in cards
    func getRecentEmotionCheckinsCount() -> Int {
        return recentEmotionCards.count
    }
    
    /// Taps a recent journal card at the specified index
    /// - Parameter index: The index of the card to tap
    /// - Returns: Whether the card was successfully tapped
    func tapRecentJournalCard(index: Int) -> Bool {
        guard index < recentJournalCards.count else {
            return false
        }
        
        let card = recentJournalCards.element(boundBy: index)
        guard scrollToElement(scrollView, element: card, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        return tapElement(card, timeout: TimeoutDuration.standard)
    }
    
    /// Taps a recent emotion check-in card at the specified index
    /// - Parameter index: The index of the card to tap
    /// - Returns: Whether the card was successfully tapped
    func tapRecentEmotionCard(index: Int) -> Bool {
        guard index < recentEmotionCards.count else {
            return false
        }
        
        let card = recentEmotionCards.element(boundBy: index)
        guard scrollToElement(scrollView, element: card, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        return tapElement(card, timeout: TimeoutDuration.standard)
    }
    
    /// Gets the count of recommended tool cards displayed
    /// - Returns: The number of tool cards
    func getRecommendedToolsCount() -> Int {
        return toolCards.count
    }
    
    /// Taps a recommended tool card at the specified index
    /// - Parameter index: The index of the card to tap
    /// - Returns: Whether the card was successfully tapped
    func tapRecommendedToolCard(index: Int) -> Bool {
        guard index < toolCards.count else {
            return false
        }
        
        let card = toolCards.element(boundBy: index)
        guard scrollToElement(scrollView, element: card, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        return tapElement(card, timeout: TimeoutDuration.standard)
    }
    
    /// Scrolls to the streak section
    /// - Returns: Whether the streak section was found and scrolled to
    func scrollToStreakSection() -> Bool {
        return scrollToElement(scrollView, element: streakSection, timeout: TimeoutDuration.standard)
    }
    
    /// Verifies that the streak count displays the expected value
    /// - Parameter expectedCount: The expected streak count
    /// - Returns: Whether the streak count matches the expected value
    func verifyStreakCount(expectedCount: Int) -> Bool {
        guard scrollToStreakSection() else {
            return false
        }
        
        guard verifyElementExists(streakText, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        return verifyElementContainsText(streakText, expectedText: String(expectedCount), timeout: TimeoutDuration.standard)
    }
    
    /// Verifies that the next milestone displays the expected value
    /// - Parameter expectedMilestone: The expected milestone value
    /// - Returns: Whether the next milestone matches the expected value
    func verifyNextMilestone(expectedMilestone: Int) -> Bool {
        guard scrollToStreakSection() else {
            return false
        }
        
        guard verifyElementExists(nextMilestoneText, timeout: TimeoutDuration.standard) else {
            return false
        }
        
        return verifyElementContainsText(nextMilestoneText, expectedText: String(expectedMilestone), timeout: TimeoutDuration.standard)
    }
    
    /// Performs a pull-to-refresh gesture on the home screen
    /// - Returns: Whether the refresh was successful
    func pullToRefresh() -> Bool {
        // Start point near the top of the scroll view
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        
        // Perform drag from top to bottom
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Wait for refresh to complete
        return waitForLoadingToComplete(timeout: TimeoutDuration.standard)
    }
    
    /// Taps the create button in the tab bar to initiate recording a journal
    /// - Returns: Whether the button was successfully tapped
    func tapCreateButton() -> Bool {
        return tapElement(createTabButton, timeout: TimeoutDuration.standard)
    }
    
    /// Taps the favorites button in the tab bar
    /// - Returns: Whether the button was successfully tapped
    func tapFavoritesButton() -> Bool {
        return tapElement(favoritesTabButton, timeout: TimeoutDuration.standard)
    }
    
    /// Taps the profile button in the tab bar
    /// - Returns: Whether the button was successfully tapped
    func tapProfileButton() -> Bool {
        return tapElement(profileTabButton, timeout: TimeoutDuration.standard)
    }
    
    /// Taps the settings button in the tab bar
    /// - Returns: Whether the button was successfully tapped
    func tapSettingsButton() -> Bool {
        return tapElement(settingsTabButton, timeout: TimeoutDuration.standard)
    }
    
    /// Checks if the recent activities section is empty
    /// - Returns: Whether the recent activities section is empty
    func isRecentActivitiesSectionEmpty() -> Bool {
        return getRecentJournalCount() == 0 && getRecentEmotionCheckinsCount() == 0
    }
    
    /// Checks if the recommended tools section is empty
    /// - Returns: Whether the recommended tools section is empty
    func isRecommendedToolsSectionEmpty() -> Bool {
        return getRecommendedToolsCount() == 0
    }
    
    /// Scrolls to the recent activities section
    /// - Returns: Whether the section was found and scrolled to
    func scrollToRecentActivitiesSection() -> Bool {
        return scrollToElement(scrollView, element: recentActivitiesSection, timeout: TimeoutDuration.standard)
    }
    
    /// Scrolls to the recommended tools section
    /// - Returns: Whether the section was found and scrolled to
    func scrollToRecommendedToolsSection() -> Bool {
        return scrollToElement(scrollView, element: recommendedToolsSection, timeout: TimeoutDuration.standard)
    }
}