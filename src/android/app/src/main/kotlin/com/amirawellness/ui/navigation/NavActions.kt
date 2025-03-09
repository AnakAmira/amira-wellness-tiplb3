package com.amirawellness.ui.navigation

import androidx.navigation.NavController

/**
 * Provides navigation action methods for the Amira Wellness application.
 * This class encapsulates navigation logic and provides type-safe methods 
 * for navigating between different screens in the application.
 */
class NavActions(private val navController: NavController) {

    /**
     * Navigate to the splash screen.
     */
    fun navigateToSplash() {
        navController.navigate(Screen.Splash.route) {
            popUpTo(navController.graph.startDestinationId) { inclusive = true }
        }
    }

    /**
     * Navigate to the onboarding screen.
     */
    fun navigateToOnboarding() {
        navController.navigate(Screen.Onboarding.route) {
            popUpTo(navController.graph.startDestinationId) { inclusive = true }
        }
    }

    /**
     * Navigate to the login screen.
     */
    fun navigateToLogin() {
        navController.navigate(Screen.Login.route) {
            popUpTo(navController.graph.startDestinationId) { inclusive = true }
        }
    }

    /**
     * Navigate to the registration screen.
     */
    fun navigateToRegister() {
        navController.navigate(Screen.Register.route)
    }

    /**
     * Navigate to the forgot password screen.
     */
    fun navigateToForgotPassword() {
        navController.navigate(Screen.ForgotPassword.route)
    }

    /**
     * Navigate to the main screen with bottom navigation.
     */
    fun navigateToMain() {
        navController.navigate(Screen.Main.route) {
            popUpTo(navController.graph.startDestinationId) { inclusive = true }
        }
    }

    /**
     * Navigate to the home dashboard screen.
     */
    fun navigateToHome() {
        navController.navigate(Screen.Home.route)
    }

    /**
     * Navigate to the journal list screen.
     */
    fun navigateToJournalList() {
        navController.navigate(Screen.JournalList.route)
    }

    /**
     * Navigate to the journal detail screen.
     *
     * @param journalId The ID of the journal to display
     */
    fun navigateToJournalDetail(journalId: String) {
        navController.navigate(Screen.JournalDetail.createRoute(journalId))
    }

    /**
     * Navigate to the record journal screen.
     */
    fun navigateToRecordJournal() {
        navController.navigate(Screen.RecordJournal.route)
    }

    /**
     * Navigate to the emotional check-in screen.
     *
     * @param source The source context (e.g., "pre_journal", "post_journal", "standalone")
     */
    fun navigateToEmotionalCheckin(source: String) {
        navController.navigate(Screen.EmotionalCheckin.createRoute(source))
    }

    /**
     * Navigate to the emotional check-in result screen.
     */
    fun navigateToEmotionalCheckinResult() {
        navController.navigate(Screen.EmotionalCheckinResult.route)
    }

    /**
     * Navigate to the tool library screen.
     */
    fun navigateToToolLibrary() {
        navController.navigate(Screen.ToolLibrary.route)
    }

    /**
     * Navigate to the tool category screen.
     *
     * @param categoryId The ID of the category to display
     */
    fun navigateToToolCategory(categoryId: String) {
        navController.navigate(Screen.ToolCategory.createRoute(categoryId))
    }

    /**
     * Navigate to the tool detail screen.
     *
     * @param toolId The ID of the tool to display
     */
    fun navigateToToolDetail(toolId: String) {
        navController.navigate(Screen.ToolDetail.createRoute(toolId))
    }

    /**
     * Navigate to the tool in progress screen.
     *
     * @param toolId The ID of the tool in progress
     */
    fun navigateToToolInProgress(toolId: String) {
        navController.navigate(Screen.ToolInProgress.createRoute(toolId))
    }

    /**
     * Navigate to the tool completion screen.
     *
     * @param toolId The ID of the completed tool
     */
    fun navigateToToolCompletion(toolId: String) {
        navController.navigate(Screen.ToolCompletion.createRoute(toolId))
    }

    /**
     * Navigate to the favorites screen.
     */
    fun navigateToFavorites() {
        navController.navigate(Screen.Favorites.route)
    }

    /**
     * Navigate to the progress dashboard screen.
     */
    fun navigateToProgressDashboard() {
        navController.navigate(Screen.ProgressDashboard.route)
    }

    /**
     * Navigate to the achievements screen.
     */
    fun navigateToAchievements() {
        navController.navigate(Screen.Achievements.route)
    }

    /**
     * Navigate to the emotional trends screen.
     */
    fun navigateToEmotionalTrends() {
        navController.navigate(Screen.EmotionalTrends.route)
    }

    /**
     * Navigate to the profile screen.
     */
    fun navigateToProfile() {
        navController.navigate(Screen.Profile.route)
    }

    /**
     * Navigate to the settings screen.
     */
    fun navigateToSettings() {
        navController.navigate(Screen.Settings.route)
    }

    /**
     * Navigate to the notification settings screen.
     */
    fun navigateToNotificationSettings() {
        navController.navigate(Screen.NotificationSettings.route)
    }

    /**
     * Navigate to the privacy settings screen.
     */
    fun navigateToPrivacySettings() {
        navController.navigate(Screen.PrivacySettings.route)
    }

    /**
     * Navigate to the data export screen.
     */
    fun navigateToDataExport() {
        navController.navigate(Screen.DataExport.route)
    }

    /**
     * Navigate back to the previous screen.
     *
     * @return True if navigation was successful, false otherwise
     */
    fun navigateBack(): Boolean {
        return navController.popBackStack()
    }

    /**
     * Navigate back to a specific route in the back stack.
     *
     * @param route The route to navigate back to
     * @param inclusive Whether the destination specified by route should also be popped
     * @return True if navigation was successful, false otherwise
     */
    fun navigateBackToRoute(route: String, inclusive: Boolean = false): Boolean {
        return navController.popBackStack(route, inclusive)
    }
}