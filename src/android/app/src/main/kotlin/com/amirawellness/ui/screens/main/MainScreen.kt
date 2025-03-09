package com.amirawellness.ui.screens.main

import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout:1.5.0
import androidx.compose.material.* // androidx.compose.material:1.5.0
import androidx.compose.material.icons.Icons // androidx.compose.material.icons:1.5.0
import androidx.compose.material.icons.filled.Home // androidx.compose.material.icons.filled:1.5.0
import androidx.compose.material.icons.filled.Book // androidx.compose.material.icons.filled:1.5.0
import androidx.compose.material.icons.filled.Spa // androidx.compose.material.icons.filled:1.5.0
import androidx.compose.material.icons.filled.InsertChart // androidx.compose.material.icons.filled:1.5.0
import androidx.compose.material.icons.filled.Person // androidx.compose.material.icons.filled:1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.getValue // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.mutableStateOf // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.remember // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.setValue // androidx.compose.runtime:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui:1.5.0
import androidx.navigation.NavController // androidx.navigation:2.7.0
import androidx.navigation.NavDestination // androidx.navigation:2.7.0
import androidx.navigation.NavGraph // androidx.navigation:2.7.0
import androidx.navigation.compose.currentBackStackEntryAsState // androidx.navigation.compose:2.7.0
import com.amirawellness.R
import com.amirawellness.ui.navigation.Screen // Screen sealed class
import com.amirawellness.ui.navigation.NavActions // NavActions class
import com.amirawellness.ui.screens.home.HomeScreen // HomeScreen composable
import com.amirawellness.ui.screens.journal.JournalListScreen // JournalListScreen composable
import com.amirawellness.ui.screens.tools.ToolLibraryScreen // ToolLibraryScreen composable
import com.amirawellness.ui.screens.progress.ProgressDashboardScreen // ProgressDashboardScreen composable
import com.amirawellness.ui.screens.profile.ProfileScreen // ProfileScreen composable
import com.amirawellness.ui.theme.AmiraWellnessTheme // AmiraWellnessTheme composable
import com.amirawellness.ui.theme.Primary // Primary color
import com.amirawellness.ui.theme.Surface // Surface color

/**
 * Main composable function that implements the bottom navigation and hosts the primary screens of the application
 * @param navController NavController
 * @param navActions NavActions
 * @param modifier Modifier
 */
@Composable
fun MainScreen(
    navController: NavController,
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // LD1: Get the current back stack entry from the NavController
    val navBackStackEntry by navController.currentBackStackEntryAsState()

    // LD1: Extract the current route from the back stack entry
    val currentRoute = navBackStackEntry?.destination?.route

    // LD1: Create a Scaffold with a BottomNavigation component
    Scaffold(
        modifier = modifier.fillMaxSize(),
        bottomBar = {
            BottomNavigation(
                backgroundColor = Surface,
                contentColor = Primary
            ) {
                // LD1: Define navigation items for Home, Journal, Tools, Progress, and Profile
                val navigationItems = listOf(
                    BottomNavigationItem(
                        route = Screen.Home.route,
                        title = stringResource(id = R.string.title_home),
                        icon = Icons.Filled.Home
                    ),
                    BottomNavigationItem(
                        route = Screen.JournalList.route,
                        title = stringResource(id = R.string.title_journal),
                        icon = Icons.Filled.Book
                    ),
                    BottomNavigationItem(
                        route = Screen.ToolLibrary.route,
                        title = stringResource(id = R.string.title_tools),
                        icon = Icons.Filled.Spa
                    ),
                    BottomNavigationItem(
                        route = Screen.ProgressDashboard.route,
                        title = stringResource(id = R.string.title_progress),
                        icon = Icons.Filled.InsertChart
                    ),
                    BottomNavigationItem(
                        route = Screen.Profile.route,
                        title = stringResource(id = R.string.title_profile),
                        icon = Icons.Filled.Person
                    )
                )

                // LD1: Set up the BottomNavigation with the navigation items
                navigationItems.forEach { item ->
                    BottomNavigationItem(
                        icon = {
                            Icon(item.icon, contentDescription = item.title)
                        },
                        label = { Text(item.title) },
                        selected = currentRoute == item.route,
                        onClick = {
                            // LD1: Implement selection handling for bottom navigation items
                            navActions.run {
                                when (item.route) {
                                    Screen.Home.route -> navigateToHome()
                                    Screen.JournalList.route -> navigateToJournalList()
                                    Screen.ToolLibrary.route -> navigateToToolLibrary()
                                    Screen.ProgressDashboard.route -> navigateToProgressDashboard()
                                    Screen.Profile.route -> navigateToProfile()
                                }
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        // LD1: Create a content area that displays the appropriate screen based on the current route
        BottomNavigationContent(
            currentRoute = currentRoute,
            navController = navController,
            navActions = navActions,
            modifier = Modifier.padding(innerPadding)
        )
    }
}

/**
 * Composable function that displays the appropriate screen based on the current route
 * @param currentRoute String?
 * @param navController NavController
 * @param navActions NavActions
 * @param modifier Modifier
 */
@Composable
private fun BottomNavigationContent(
    currentRoute: String?,
    navController: NavController,
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Box container for the content
    Box(modifier = modifier.fillMaxSize()) {
        // LD1: Check the current route and display the appropriate screen
        when (currentRoute) {
            Screen.Home.route -> {
                // LD1: For Home route, display HomeScreen
                HomeScreen(navController = navController)
            }
            Screen.JournalList.route -> {
                // LD1: For JournalList route, display JournalListScreen
                JournalListScreen(navController = navController)
            }
            Screen.ToolLibrary.route -> {
                // LD1: For ToolLibrary route, display ToolLibraryScreen
                ToolLibraryScreen(navController = navController)
            }
            Screen.ProgressDashboard.route -> {
                // LD1: For ProgressDashboard route, display ProgressDashboardScreen
                ProgressDashboardScreen(navActions = navActions)
            }
            Screen.Profile.route -> {
                // LD1: For Profile route, display ProfileScreen
                ProfileScreen()
            }
        }
    }
}

/**
 * Data class that represents an item in the bottom navigation
 * @param route String
 * @param title String
 * @param icon ImageVector
 */
data class BottomNavigationItem(
    val route: String,
    val title: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
)