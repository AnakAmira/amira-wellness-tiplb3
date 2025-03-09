package com.amirawellness.ui.navigation

/**
 * Defines all navigation destinations in the Amira Wellness application.
 * Each screen has a unique route identifier used for navigation.
 * Screens with parameters include helper methods to create parameterized routes.
 */
sealed class Screen(val route: String) {

    /**
     * Splash screen shown at app startup
     */
    object Splash : Screen("splash")

    /**
     * Onboarding screens for first-time users
     */
    object Onboarding : Screen("onboarding")

    /**
     * Login screen for user authentication
     */
    object Login : Screen("login")

    /**
     * Registration screen for new users
     */
    object Register : Screen("register")

    /**
     * Screen for password recovery
     */
    object ForgotPassword : Screen("forgot_password")

    /**
     * Main container screen with bottom navigation
     */
    object Main : Screen("main")

    /**
     * Home dashboard screen showing user's overview and recommendations
     */
    object Home : Screen("home")

    /**
     * List of user's voice journal entries
     */
    object JournalList : Screen("journal_list")

    /**
     * Detail view for a specific voice journal entry
     */
    object JournalDetail : Screen("journal_detail/{journalId}") {
        const val JOURNAL_ID_KEY = "journalId"
        
        /**
         * Creates a route with the specified journal ID
         * 
         * @param journalId The ID of the journal to display
         * @return Route string with the journal ID parameter
         */
        fun createRoute(journalId: String): String {
            return route.replace("{$JOURNAL_ID_KEY}", journalId)
        }
    }

    /**
     * Screen for recording a new voice journal entry
     */
    object RecordJournal : Screen("record_journal")

    /**
     * Screen for logging emotional state
     */
    object EmotionalCheckin : Screen("emotional_checkin/{source}") {
        const val SOURCE_KEY = "source"
        
        /**
         * Creates a route with the specified source context
         * 
         * @param source The source context (e.g., "pre_journal", "post_journal", "standalone")
         * @return Route string with the source parameter
         */
        fun createRoute(source: String): String {
            return route.replace("{$SOURCE_KEY}", source)
        }
    }

    /**
     * Results screen after emotional check-in
     */
    object EmotionalCheckinResult : Screen("emotional_checkin_result")

    /**
     * Main tool library screen with categories
     */
    object ToolLibrary : Screen("tool_library")

    /**
     * Screen showing tools within a specific category
     */
    object ToolCategory : Screen("tool_category/{categoryId}") {
        const val CATEGORY_ID_KEY = "categoryId"
        
        /**
         * Creates a route with the specified category ID
         * 
         * @param categoryId The ID of the category to display
         * @return Route string with the category ID parameter
         */
        fun createRoute(categoryId: String): String {
            return route.replace("{$CATEGORY_ID_KEY}", categoryId)
        }
    }

    /**
     * Detail screen for a specific tool
     */
    object ToolDetail : Screen("tool_detail/{toolId}") {
        const val TOOL_ID_KEY = "toolId"
        
        /**
         * Creates a route with the specified tool ID
         * 
         * @param toolId The ID of the tool to display
         * @return Route string with the tool ID parameter
         */
        fun createRoute(toolId: String): String {
            return route.replace("{$TOOL_ID_KEY}", toolId)
        }
    }

    /**
     * Screen for active tool usage
     */
    object ToolInProgress : Screen("tool_in_progress/{toolId}") {
        const val TOOL_ID_KEY = "toolId"
        
        /**
         * Creates a route with the specified tool ID
         * 
         * @param toolId The ID of the tool in progress
         * @return Route string with the tool ID parameter
         */
        fun createRoute(toolId: String): String {
            return route.replace("{$TOOL_ID_KEY}", toolId)
        }
    }

    /**
     * Completion screen after finishing a tool
     */
    object ToolCompletion : Screen("tool_completion/{toolId}") {
        const val TOOL_ID_KEY = "toolId"
        
        /**
         * Creates a route with the specified tool ID
         * 
         * @param toolId The ID of the completed tool
         * @return Route string with the tool ID parameter
         */
        fun createRoute(toolId: String): String {
            return route.replace("{$TOOL_ID_KEY}", toolId)
        }
    }

    /**
     * Screen showing user's favorite tools
     */
    object Favorites : Screen("favorites")

    /**
     * Progress tracking dashboard
     */
    object ProgressDashboard : Screen("progress_dashboard")

    /**
     * Screen showing user's achievements
     */
    object Achievements : Screen("achievements")

    /**
     * Screen showing emotional trends and patterns
     */
    object EmotionalTrends : Screen("emotional_trends")

    /**
     * User profile screen
     */
    object Profile : Screen("profile")

    /**
     * Application settings screen
     */
    object Settings : Screen("settings")

    /**
     * Screen for notification preferences
     */
    object NotificationSettings : Screen("notification_settings")

    /**
     * Screen for privacy and security settings
     */
    object PrivacySettings : Screen("privacy_settings")

    /**
     * Screen for exporting user data
     */
    object DataExport : Screen("data_export")
}