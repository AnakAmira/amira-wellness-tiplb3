package com.amirawellness.ui.navigation

import androidx.compose.runtime.Composable // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.remember // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:ui:1.5.0
import androidx.navigation.NavController // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.NavGraphBuilder // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.NavHostController // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.NavType // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.compose.NavHost // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.compose.composable // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.compose.rememberNavController // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.navArgument // androidx.navigation:navigation-compose:2.7.0
import com.amirawellness.ui.navigation.Screen // src/android/app/src/main/kotlin/com/amirawellness/ui/navigation/Screen.kt
import com.amirawellness.ui.navigation.NavActions // src/android/app/src/main/kotlin/com/amirawellness/ui/navigation/NavActions.kt
import com.amirawellness.ui.screens.onboarding.OnboardingScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/onboarding/OnboardingScreen.kt
import com.amirawellness.ui.screens.auth.LoginScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/auth/LoginScreen.kt
import com.amirawellness.ui.screens.auth.RegisterScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/auth/RegisterScreen.kt
import com.amirawellness.ui.screens.auth.ForgotPasswordScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/auth/ForgotPasswordScreen.kt
import com.amirawellness.ui.screens.main.MainScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/main/MainScreen.kt
import com.amirawellness.ui.screens.journal.JournalDetailScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/journal/JournalDetailScreen.kt
import com.amirawellness.ui.screens.journal.RecordJournalScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/journal/RecordJournalScreen.kt
import com.amirawellness.ui.screens.emotions.EmotionalCheckinScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/emotions/EmotionalCheckinScreen.kt
import com.amirawellness.ui.screens.emotions.EmotionalCheckinResultScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/emotions/EmotionalCheckinResultScreen.kt
import com.amirawellness.ui.screens.tools.ToolLibraryScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/tools/ToolLibraryScreen.kt
import com.amirawellness.ui.screens.tools.ToolCategoryScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/tools/ToolCategoryScreen.kt
import com.amirawellness.ui.screens.tools.ToolDetailScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/tools/ToolDetailScreen.kt
import com.amirawellness.ui.screens.tools.ToolInProgressScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/tools/ToolInProgressScreen.kt
import com.amirawellness.ui.screens.tools.ToolCompletionScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/tools/ToolCompletionScreen.kt
import com.amirawellness.ui.screens.tools.FavoritesScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/tools/FavoritesScreen.kt
import com.amirawellness.ui.screens.progress.AchievementsScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/progress/AchievementsScreen.kt
import com.amirawellness.ui.screens.progress.EmotionalTrendsScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/progress/EmotionalTrendsScreen.kt
import com.amirawellness.ui.screens.settings.SettingsScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/settings/SettingsScreen.kt
import com.amirawellness.ui.screens.settings.NotificationSettingsScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/settings/NotificationSettingsScreen.kt
import com.amirawellness.ui.screens.settings.PrivacySettingsScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/settings/PrivacySettingsScreen.kt
import com.amirawellness.ui.screens.settings.DataExportScreen // src/android/app/src/main/kotlin/com/amirawellness/ui/screens/settings/DataExportScreen.kt

/**
 * Main composable function that sets up the navigation host for the entire application
 * @param navController NavHostController
 * @param startDestination String
 * @param modifier Modifier
 */
@Composable
fun AmiraNavHost(
    navController: NavHostController = rememberNavController(),
    startDestination: String,
    modifier: Modifier = Modifier
) {
    // LD1: Create a NavHost with the provided navController and startDestination
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        // LD1: Create and remember NavActions for this NavHost
        val navActions = rememberNavActions(navController)

        // LD1: Add authentication-related navigation destinations
        addAuthNavigation(navActions)

        // LD1: Add journal-related navigation destinations
        addJournalNavigation(navActions)

        // LD1: Add emotion-related navigation destinations
        addEmotionNavigation(navActions)

        // LD1: Add tool-related navigation destinations
        addToolNavigation(navActions)

        // LD1: Add progress-related navigation destinations
        addProgressNavigation(navActions)

        // LD1: Add settings-related navigation destinations
        addSettingsNavigation(navActions)

        // LD1: Define composable destination for OnboardingScreen
        composable(Screen.Onboarding.route) {
            OnboardingScreen()
        }
    }
}

/**
 * Composable function that creates and remembers NavActions for the provided NavController
 * @param navController NavController
 * @return NavActions instance for navigation
 */
@Composable
fun rememberNavActions(navController: NavController): NavActions {
    // LD1: Create a NavActions instance with the provided navController
    val navActions = remember { NavActions(navController) }
    // LD2: Use remember to ensure the NavActions instance survives recompositions
    return navActions
}

/**
 * Extension function for NavGraphBuilder that adds authentication-related navigation destinations
 * @param navActions NavActions
 */
fun NavGraphBuilder.addAuthNavigation(navActions: NavActions) {
    // LD1: Add composable for Login screen with LoginScreen composable
    composable(Screen.Login.route) {
        LoginScreen()
    }

    // LD1: Add composable for Register screen with RegisterScreen composable
    composable(Screen.Register.route) {
        RegisterScreen()
    }

    // LD1: Add composable for ForgotPassword screen with ForgotPasswordScreen composable
    composable(Screen.ForgotPassword.route) {
        ForgotPasswordScreen()
    }
}

/**
 * Extension function for NavGraphBuilder that adds journal-related navigation destinations
 * @param navActions NavActions
 */
fun NavGraphBuilder.addJournalNavigation(navActions: NavActions) {
    // LD1: Add composable for JournalDetail screen with JournalDetailScreen composable and journalId parameter
    composable(
        route = Screen.JournalDetail.route,
        arguments = listOf(navArgument(Screen.JournalDetail.JOURNAL_ID_KEY) { type = NavType.StringType })
    ) { backStackEntry ->
        val journalId = backStackEntry.arguments?.getString(Screen.JournalDetail.JOURNAL_ID_KEY)
        journalId?.let {
            JournalDetailScreen(navController = navActions.navController, journalId = it)
        }
    }

    // LD1: Add composable for RecordJournal screen with RecordJournalScreen composable
    composable(Screen.RecordJournal.route) {
        RecordJournalScreen(navController = navActions.navController, userId = "testUserId")
    }
}

/**
 * Extension function for NavGraphBuilder that adds emotion-related navigation destinations
 * @param navActions NavActions
 */
fun NavGraphBuilder.addEmotionNavigation(navActions: NavActions) {
    // LD1: Add composable for EmotionalCheckin screen with EmotionalCheckinScreen composable and source parameter
    composable(
        route = Screen.EmotionalCheckin.route,
        arguments = listOf(navArgument(Screen.EmotionalCheckin.SOURCE_KEY) { type = NavType.StringType })
    ) { backStackEntry ->
        val source = backStackEntry.arguments?.getString(Screen.EmotionalCheckin.SOURCE_KEY)
        source?.let {
            EmotionalCheckinScreen(navController = navActions.navController, source = it)
        }
    }

    // LD1: Add composable for EmotionalCheckinResult screen with EmotionalCheckinResultScreen composable
    composable(Screen.EmotionalCheckinResult.route) {
        EmotionalCheckinResultScreen(navActions = navActions, emotionalState = EmotionalState())
    }
}

/**
 * Extension function for NavGraphBuilder that adds tool-related navigation destinations
 * @param navActions NavActions
 */
fun NavGraphBuilder.addToolNavigation(navActions: NavActions) {
    // LD1: Add composable for ToolLibrary screen with ToolLibraryScreen composable
    composable(Screen.ToolLibrary.route) {
        ToolLibraryScreen(navController = navActions.navController)
    }

    // LD1: Add composable for ToolCategory screen with ToolCategoryScreen composable and categoryId parameter
    composable(
        route = Screen.ToolCategory.route,
        arguments = listOf(navArgument(Screen.ToolCategory.CATEGORY_ID_KEY) { type = NavType.StringType })
    ) { backStackEntry ->
        val categoryId = backStackEntry.arguments?.getString(Screen.ToolCategory.CATEGORY_ID_KEY)
        categoryId?.let {
            ToolCategoryScreen(navActions = navActions)
        }
    }

    // LD1: Add composable for ToolDetail screen with ToolDetailScreen composable and toolId parameter
    composable(
        route = Screen.ToolDetail.route,
        arguments = listOf(navArgument(Screen.ToolDetail.TOOL_ID_KEY) { type = NavType.StringType })
    ) { backStackEntry ->
        val toolId = backStackEntry.arguments?.getString(Screen.ToolDetail.TOOL_ID_KEY)
        toolId?.let {
            ToolDetailScreen(toolId = it)
        }
    }

    // LD1: Add composable for ToolInProgress screen with ToolInProgressScreen composable and toolId parameter
    composable(
        route = Screen.ToolInProgress.route,
        arguments = listOf(navArgument(Screen.ToolInProgress.TOOL_ID_KEY) { type = NavType.StringType })
    ) { backStackEntry ->
        val toolId = backStackEntry.arguments?.getString(Screen.ToolInProgress.TOOL_ID_KEY)
        ToolInProgressScreen(navBackStackEntry = backStackEntry)
    }

    // LD1: Add composable for ToolCompletion screen with ToolCompletionScreen composable and toolId parameter
    composable(
        route = Screen.ToolCompletion.route,
        arguments = listOf(navArgument(Screen.ToolCompletion.TOOL_ID_KEY) { type = NavType.StringType })
    ) { backStackEntry ->
        val toolId = backStackEntry.arguments?.getString(Screen.ToolCompletion.TOOL_ID_KEY)
        toolId?.let {
            ToolCompletionScreen(navController = navActions.navController, toolId = it, durationSeconds = 0)
        }
    }

    // LD1: Add composable for Favorites screen with FavoritesScreen composable
    composable(Screen.Favorites.route) {
        FavoritesScreen(navController = navActions.navController)
    }
}

/**
 * Extension function for NavGraphBuilder that adds progress-related navigation destinations
 * @param navActions NavActions
 */
fun NavGraphBuilder.addProgressNavigation(navActions: NavActions) {
    // LD1: Add composable for Achievements screen with AchievementsScreen composable
    composable(Screen.Achievements.route) {
        AchievementsScreen(navController = navActions.navController)
    }

    // LD1: Add composable for EmotionalTrends screen with EmotionalTrendsScreen composable
    composable(Screen.EmotionalTrends.route) {
        EmotionalTrendsScreen(navController = navActions.navController)
    }
}

/**
 * Extension function for NavGraphBuilder that adds settings-related navigation destinations
 * @param navActions NavActions
 */
fun NavGraphBuilder.addSettingsNavigation(navActions: NavActions) {
    // LD1: Add composable for Settings screen with SettingsScreen composable
    composable(Screen.Settings.route) {
        SettingsScreen(navController = navActions.navController)
    }

    // LD1: Add composable for NotificationSettings screen with NotificationSettingsScreen composable
    composable(Screen.NotificationSettings.route) {
        NotificationSettingsScreen(navController = navActions.navController)
    }

    // LD1: Add composable for PrivacySettings screen with PrivacySettingsScreen composable
    composable(Screen.PrivacySettings.route) {
        PrivacySettingsScreen(navController = navActions.navController)
    }

    // LD1: Add composable for DataExport screen with DataExportScreen composable
    composable(Screen.DataExport.route) {
        DataExportScreen(navActions = navActions)
    }
}