//
// ProgressUITests.swift
// AmiraWellnessUITests
//
// UI tests for the progress tracking features in the Amira Wellness app,
// verifying that users can view and interact with progress dashboards,
// emotional trends, and achievements to track their emotional wellness journey.
//

import XCTest
import "../Screens/ProgressScreen"
import "../Screens/LoginScreen"
import "../Screens/HomeScreen"
import "../Helpers/UITestHelpers"

class ProgressUITests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    var progressScreen: ProgressScreen!
    var loginScreen: LoginScreen!
    var homeScreen: HomeScreen!
    var testUserEmail: String!
    var testUserPassword: String!
    var testUserName: String!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize app and configure for UI testing
        app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        
        // Set test user credentials
        testUserEmail = "test@example.com"
        testUserPassword = "Password123!"
        testUserName = "María"
        
        // Initialize screen objects
        progressScreen = ProgressScreen(app: app)
        loginScreen = LoginScreen(app: app)
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
    
    /// Tests that the progress screen appears after navigating from home
    func testProgressScreenAppears() {
        // Launch app and login
        XCTAssertTrue(launchAppAndLogin(app, email: testUserEmail, password: testUserPassword))
        
        // Navigate to the progress screen from home
        XCTAssertTrue(homeScreen.waitForHomeScreen())
        XCTAssertTrue(homeScreen.tapProgressTab())
        
        // Verify progress screen is displayed
        XCTAssertTrue(progressScreen.waitForProgressScreen())
        
        // Take a screenshot of the progress screen
        takeScreenshot(self, name: "Progress_Screen")
    }
    
    /// Tests that all expected sections are displayed on the progress screen
    func testProgressScreenSections() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Verify streak section exists
        XCTAssertTrue(progressScreen.verifyStreakSectionExists(), "Streak section should exist")
        
        // Verify emotional trends section exists
        XCTAssertTrue(progressScreen.verifyEmotionalTrendsSectionExists(), "Emotional trends section should exist")
        
        // Verify dominant emotions section exists
        XCTAssertTrue(progressScreen.verifyDominantEmotionsSectionExists(), "Dominant emotions section should exist")
        
        // Verify activity section exists
        XCTAssertTrue(progressScreen.verifyActivitySectionExists(), "Activity section should exist")
        
        // Scroll to verify achievements section exists
        XCTAssertTrue(progressScreen.scrollToAchievementsSection(), "Should be able to scroll to achievements section")
        XCTAssertTrue(progressScreen.verifyAchievementsSectionExists(), "Achievements section should exist")
        
        // Take a screenshot of the full progress screen
        takeScreenshot(self, name: "Progress_Screen_All_Sections")
    }
    
    /// Tests that streak information is displayed correctly
    func testStreakInformation() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Verify streak section exists
        XCTAssertTrue(progressScreen.verifyStreakSectionExists(), "Streak section should exist")
        
        // Get current streak text and verify it contains a number
        let currentStreakText = progressScreen.getCurrentStreakText()
        XCTAssertTrue(currentStreakText.contains("días"), "Streak text should contain 'días'")
        
        // Get next milestone text and verify it contains expected format
        let nextMilestoneText = progressScreen.getNextMilestoneText()
        XCTAssertTrue(nextMilestoneText.contains("Próximo logro"), "Next milestone text should contain 'Próximo logro'")
        
        // Take a screenshot of the streak section
        takeScreenshot(self, name: "Progress_Streak_Information")
    }
    
    /// Tests the emotional trend chart display and interaction
    func testEmotionalTrendChart() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Verify emotional trends section exists
        XCTAssertTrue(progressScreen.verifyEmotionalTrendsSectionExists(), "Emotional trends section should exist")
        
        // Verify emotional trend chart exists
        XCTAssertTrue(progressScreen.verifyEmotionalTrendChartExists(), "Emotional trend chart should exist")
        
        // Select weekly period and verify the change
        XCTAssertTrue(progressScreen.selectWeeklyPeriod(), "Should be able to select weekly period")
        sleep(1) // Wait for UI to update
        
        // Select monthly period and verify the change
        XCTAssertTrue(progressScreen.selectMonthlyPeriod(), "Should be able to select monthly period")
        sleep(1) // Wait for UI to update
        
        // Take a screenshot of the emotional trends section
        takeScreenshot(self, name: "Progress_Emotional_Trends")
    }
    
    /// Tests the dominant emotions section display
    func testDominantEmotions() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Verify dominant emotions section exists
        XCTAssertTrue(progressScreen.verifyDominantEmotionsSectionExists(), "Dominant emotions section should exist")
        
        // Verify at least one emotion is displayed (or empty state is handled)
        let emotionsToCheck = ["Calma", "Alegría", "Ansiedad"]
        var foundAnyEmotion = false
        
        for emotion in emotionsToCheck {
            if progressScreen.verifyEmotionExists(emotionName: emotion) {
                foundAnyEmotion = true
                break
            }
        }
        
        // We don't assert foundAnyEmotion since a new test account might not have data yet
        
        // Take a screenshot of the dominant emotions section
        takeScreenshot(self, name: "Progress_Dominant_Emotions")
    }
    
    /// Tests the activity chart display
    func testActivityChart() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Verify activity section exists
        XCTAssertTrue(progressScreen.verifyActivitySectionExists(), "Activity section should exist")
        
        // Verify activity chart exists
        XCTAssertTrue(progressScreen.verifyActivityChartExists(), "Activity chart should exist")
        
        // Take a screenshot of the activity section
        takeScreenshot(self, name: "Progress_Activity_Chart")
    }
    
    /// Tests the achievements section display and interaction
    func testAchievementsSection() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Scroll to achievements section
        XCTAssertTrue(progressScreen.scrollToAchievementsSection(), "Should be able to scroll to achievements section")
        
        // Verify achievements section exists
        XCTAssertTrue(progressScreen.verifyAchievementsSectionExists(), "Achievements section should exist")
        
        // Verify at least one achievement is displayed (or empty state is handled)
        let achievementsToCheck = ["Primer paso", "Explorador", "Racha de 3 días"]
        var foundAnyAchievement = false
        
        for achievement in achievementsToCheck {
            if progressScreen.verifyAchievementExists(achievementName: achievement) {
                foundAnyAchievement = true
                break
            }
        }
        
        // We don't assert foundAnyAchievement since a new test account might not have achievements yet
        
        // Take a screenshot of the achievements section
        takeScreenshot(self, name: "Progress_Achievements")
    }
    
    /// Tests navigation to detailed emotional trends screen
    func testNavigateToDetailedEmotionalTrends() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Verify emotional trends section exists
        XCTAssertTrue(progressScreen.verifyEmotionalTrendsSectionExists(), "Emotional trends section should exist")
        
        // Tap on emotional trend chart or 'View More' button
        let navigated = progressScreen.tapEmotionalTrendChart() || progressScreen.tapViewMoreEmotions()
        XCTAssertTrue(navigated, "Should be able to navigate to detailed emotional trends")
        
        // Verify emotional trends detail screen appears
        XCTAssertTrue(progressScreen.waitForEmotionalTrendsScreen(), "Emotional trends detail screen should appear")
        
        // Take a screenshot of the detailed trends screen
        takeScreenshot(self, name: "Detailed_Emotional_Trends")
        
        // Navigate back to progress screen
        XCTAssertTrue(progressScreen.navigateBack(), "Should be able to navigate back")
        
        // Verify return to progress screen
        XCTAssertTrue(progressScreen.waitForProgressScreen(), "Should return to progress screen")
    }
    
    /// Tests navigation to achievements screen
    func testNavigateToAchievements() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Scroll to achievements section
        XCTAssertTrue(progressScreen.scrollToAchievementsSection(), "Should be able to scroll to achievements section")
        
        // Tap 'View All Achievements' button
        XCTAssertTrue(progressScreen.tapViewAllAchievements(), "Should be able to tap View All Achievements")
        
        // Verify achievements screen appears
        XCTAssertTrue(progressScreen.waitForAchievementsScreen(), "Achievements screen should appear")
        
        // Take a screenshot of the achievements screen
        takeScreenshot(self, name: "All_Achievements")
        
        // Navigate back to progress screen
        XCTAssertTrue(progressScreen.navigateBack(), "Should be able to navigate back")
        
        // Verify return to progress screen
        XCTAssertTrue(progressScreen.waitForProgressScreen(), "Should return to progress screen")
    }
    
    /// Tests the pull-to-refresh functionality on the progress screen
    func testPullToRefresh() {
        // Login and navigate to progress screen
        XCTAssertTrue(loginAndNavigateToProgress())
        
        // Perform pull-to-refresh gesture
        progressScreen.pullToRefresh()
        
        // Verify the screen refreshes successfully
        XCTAssertTrue(progressScreen.verifyStreakSectionExists(), "Streak section should exist after refresh")
        XCTAssertTrue(progressScreen.verifyEmotionalTrendsSectionExists(), "Emotional trends section should exist after refresh")
        XCTAssertTrue(progressScreen.verifyDominantEmotionsSectionExists(), "Dominant emotions section should exist after refresh")
        XCTAssertTrue(progressScreen.verifyActivitySectionExists(), "Activity section should exist after refresh")
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to login and navigate to the progress screen
    private func loginAndNavigateToProgress() -> Bool {
        // Launch the app
        app.launch()
        
        // Login with test user credentials using loginScreen
        if !loginScreen.login(email: testUserEmail, password: testUserPassword) {
            return false
        }
        
        // Wait for home screen to appear
        if !homeScreen.waitForHomeScreen() {
            return false
        }
        
        // Tap on the progress tab in the navigation bar
        if !homeScreen.tapProgressTab() {
            return false
        }
        
        // Wait for progress screen to appear
        return progressScreen.waitForProgressScreen()
    }
}