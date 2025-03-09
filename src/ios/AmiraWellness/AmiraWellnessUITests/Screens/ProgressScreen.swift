//
// ProgressScreen.swift
// AmiraWellnessUITests
//
// Screen object for interacting with the Progress screens in UI tests
//

import XCTest

/// Screen object for interacting with the Progress screens in UI tests
class ProgressScreen: BaseScreen {
    // MARK: - UI Elements
    
    let progressNavigationBar: XCUIElement
    let streakSection: XCUIElement
    let emotionalTrendsSection: XCUIElement
    let dominantEmotionsSection: XCUIElement
    let activitySection: XCUIElement
    let achievementsSection: XCUIElement
    let emotionalTrendChart: XCUIElement
    let activityChart: XCUIElement
    let weeklyPeriodButton: XCUIElement
    let monthlyPeriodButton: XCUIElement
    let viewAllAchievementsButton: XCUIElement
    let viewMoreEmotionsButton: XCUIElement
    let currentStreakLabel: XCUIElement
    let nextMilestoneLabel: XCUIElement
    let progressScrollView: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new ProgressScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    init(app: XCUIApplication) {
        // Initialize UI elements
        progressNavigationBar = app.navigationBars["Mi Progreso"]
        streakSection = app.staticTexts["Racha actual"].firstMatch.ancestors(matching: .other).element(boundBy: 0)
        emotionalTrendsSection = app.staticTexts["Tendencias emocionales"].firstMatch.ancestors(matching: .other).element(boundBy: 0)
        dominantEmotionsSection = app.staticTexts["Emociones más frecuentes"].firstMatch.ancestors(matching: .other).element(boundBy: 0)
        activitySection = app.staticTexts["Actividad semanal"].firstMatch.ancestors(matching: .other).element(boundBy: 0)
        achievementsSection = app.staticTexts["Logros"].firstMatch.ancestors(matching: .other).element(boundBy: 0)
        emotionalTrendChart = app.otherElements["EmotionalTrendChart"].firstMatch
        activityChart = app.otherElements["ActivityBarChart"].firstMatch
        weeklyPeriodButton = app.buttons["Semanal"].firstMatch
        monthlyPeriodButton = app.buttons["Mensual"].firstMatch
        viewAllAchievementsButton = app.buttons["Ver todos"].firstMatch
        viewMoreEmotionsButton = app.buttons["Ver más"].firstMatch
        currentStreakLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'días'")).firstMatch
        nextMilestoneLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Próximo logro'")).firstMatch
        progressScrollView = app.scrollViews.firstMatch
        
        super.init(app: app)
        rootElement = progressNavigationBar
    }
    
    // MARK: - Screen Verification Methods
    
    /// Waits for the progress screen to be displayed
    /// - Parameter timeout: The maximum time to wait for the screen to be displayed
    /// - Returns: Whether the progress screen was displayed within the timeout
    func waitForProgressScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForScreen(timeout: timeout)
    }
    
    /// Verifies that the streak section exists on the screen
    /// - Parameter timeout: The maximum time to wait for the section to exist
    /// - Returns: Whether the streak section exists
    func verifyStreakSectionExists(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementExists(streakSection, timeout: timeout)
    }
    
    /// Verifies that the emotional trends section exists on the screen
    /// - Parameter timeout: The maximum time to wait for the section to exist
    /// - Returns: Whether the emotional trends section exists
    func verifyEmotionalTrendsSectionExists(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementExists(emotionalTrendsSection, timeout: timeout)
    }
    
    /// Verifies that the dominant emotions section exists on the screen
    /// - Parameter timeout: The maximum time to wait for the section to exist
    /// - Returns: Whether the dominant emotions section exists
    func verifyDominantEmotionsSectionExists(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementExists(dominantEmotionsSection, timeout: timeout)
    }
    
    /// Verifies that the activity section exists on the screen
    /// - Parameter timeout: The maximum time to wait for the section to exist
    /// - Returns: Whether the activity section exists
    func verifyActivitySectionExists(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementExists(activitySection, timeout: timeout)
    }
    
    /// Verifies that the achievements section exists on the screen
    /// - Parameter timeout: The maximum time to wait for the section to exist
    /// - Returns: Whether the achievements section exists
    func verifyAchievementsSectionExists(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementExists(achievementsSection, timeout: timeout)
    }
    
    /// Gets the text of the current streak label
    /// - Parameter timeout: The maximum time to wait for the label to exist
    /// - Returns: The text of the current streak label
    func getCurrentStreakText(timeout: TimeInterval = TimeoutDuration.standard) -> String {
        _ = waitForElement(currentStreakLabel, timeout: timeout)
        return currentStreakLabel.label
    }
    
    /// Gets the text of the next milestone label
    /// - Parameter timeout: The maximum time to wait for the label to exist
    /// - Returns: The text of the next milestone label
    func getNextMilestoneText(timeout: TimeInterval = TimeoutDuration.standard) -> String {
        _ = waitForElement(nextMilestoneLabel, timeout: timeout)
        return nextMilestoneLabel.label
    }
    
    /// Selects the weekly period for emotional trends
    /// - Parameter timeout: The maximum time to wait for the button to be tappable
    /// - Returns: Whether the weekly period was successfully selected
    func selectWeeklyPeriod(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(weeklyPeriodButton, timeout: timeout)
    }
    
    /// Selects the monthly period for emotional trends
    /// - Parameter timeout: The maximum time to wait for the button to be tappable
    /// - Returns: Whether the monthly period was successfully selected
    func selectMonthlyPeriod(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(monthlyPeriodButton, timeout: timeout)
    }
    
    /// Taps the 'View All Achievements' button
    /// - Parameter timeout: The maximum time to wait for the button to be tappable
    /// - Returns: Whether the button was successfully tapped
    func tapViewAllAchievements(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(viewAllAchievementsButton, timeout: timeout)
    }
    
    /// Taps the 'View More Emotions' button
    /// - Parameter timeout: The maximum time to wait for the button to be tappable
    /// - Returns: Whether the button was successfully tapped
    func tapViewMoreEmotions(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(viewMoreEmotionsButton, timeout: timeout)
    }
    
    /// Taps on the emotional trend chart to navigate to detailed view
    /// - Parameter timeout: The maximum time to wait for the chart to be tappable
    /// - Returns: Whether the chart was successfully tapped
    func tapEmotionalTrendChart(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return tapElement(emotionalTrendChart, timeout: timeout)
    }
    
    /// Scrolls to the achievements section
    /// - Parameter timeout: The maximum time to wait for the section to be found
    /// - Returns: Whether the achievements section was found and scrolled to
    func scrollToAchievementsSection(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return scrollToElement(progressScrollView, element: achievementsSection, timeout: timeout)
    }
    
    /// Verifies that the emotional trend chart exists on the screen
    /// - Parameter timeout: The maximum time to wait for the chart to exist
    /// - Returns: Whether the emotional trend chart exists
    func verifyEmotionalTrendChartExists(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementExists(emotionalTrendChart, timeout: timeout)
    }
    
    /// Verifies that the activity chart exists on the screen
    /// - Parameter timeout: The maximum time to wait for the chart to exist
    /// - Returns: Whether the activity chart exists
    func verifyActivityChartExists(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return verifyElementExists(activityChart, timeout: timeout)
    }
    
    /// Performs a pull-to-refresh gesture on the progress screen
    func pullToRefresh() {
        swipeDown(progressScrollView)
    }
    
    /// Verifies that the streak value contains the expected number
    /// - Parameters:
    ///   - expectedValue: The expected streak value
    ///   - timeout: The maximum time to wait for the streak label to exist
    /// - Returns: Whether the streak value contains the expected number
    func verifyStreakValue(expectedValue: Int, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let streakText = getCurrentStreakText(timeout: timeout)
        return streakText.contains("\(expectedValue)")
    }
    
    /// Verifies that a specific emotion exists in the dominant emotions section
    /// - Parameters:
    ///   - emotionName: The name of the emotion to look for
    ///   - timeout: The maximum time to wait
    /// - Returns: Whether the emotion exists
    func verifyEmotionExists(emotionName: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", emotionName)
        let emotions = dominantEmotionsSection.staticTexts.matching(predicate)
        return emotions.count > 0
    }
    
    /// Verifies that a specific achievement exists in the achievements section
    /// - Parameters:
    ///   - achievementName: The name of the achievement to look for
    ///   - timeout: The maximum time to wait
    /// - Returns: Whether the achievement exists
    func verifyAchievementExists(achievementName: String, timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        _ = scrollToAchievementsSection(timeout: timeout)
        
        let predicate = NSPredicate(format: "label CONTAINS %@", achievementName)
        let achievements = achievementsSection.staticTexts.matching(predicate)
        return achievements.count > 0
    }
    
    /// Waits for the achievements screen to be displayed after navigation
    /// - Parameter timeout: The maximum time to wait for the screen to be displayed
    /// - Returns: Whether the achievements screen was displayed within the timeout
    func waitForAchievementsScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let achievementsNavBar = app.navigationBars["Mis Logros"]
        return waitForElement(achievementsNavBar, timeout: timeout)
    }
    
    /// Waits for the emotional trends screen to be displayed after navigation
    /// - Parameter timeout: The maximum time to wait for the screen to be displayed
    /// - Returns: Whether the emotional trends screen was displayed within the timeout
    func waitForEmotionalTrendsScreen(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let trendsNavBar = app.navigationBars["Tendencias Emocionales"]
        return waitForElement(trendsNavBar, timeout: timeout)
    }
    
    /// Navigates back to the previous screen
    /// - Parameter timeout: The maximum time to wait for the back button to be tappable
    /// - Returns: Whether navigation was successful
    func navigateBack(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        return tapElement(backButton, timeout: timeout)
    }
}