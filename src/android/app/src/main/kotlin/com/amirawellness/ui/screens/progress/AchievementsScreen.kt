package com.amirawellness.ui.screens.progress

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import androidx.compose.ui.graphics.Color
import com.amirawellness.R
import com.amirawellness.data.models.Achievement
import com.amirawellness.data.models.AchievementCategory
import com.amirawellness.ui.components.cards.AchievementCard
import com.amirawellness.ui.components.loading.LoadingIndicator
import com.amirawellness.ui.components.feedback.EmptyStateView
import com.amirawellness.ui.components.feedback.GenericErrorView
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Surface
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState

/**
 * Main composable function that displays the achievements screen with filtering and different sections
 *
 * @param navController NavController for handling navigation
 */
@Composable
fun AchievementsScreen(navController: NavController) {
    // LD1: Get ViewModel instance using hiltViewModel()
    val viewModel: AchievementsViewModel = hiltViewModel()

    // LD1: Create NavActions instance with the provided NavController
    val navActions = remember { NavActions(navController) }

    // LD1: Collect uiState and selectedCategory from ViewModel as State
    val uiState by viewModel.uiState.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()

    // LD1: Create SwipeRefresh state for pull-to-refresh functionality
    val swipeRefreshState = rememberSwipeRefreshState(isRefreshing = uiState is AchievementsUiState.Loading)

    // LD1: Create Scaffold with TopAppBar containing title and back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.achievements_title)) },
                backgroundColor = Surface,
                navigationIcon = {
                    IconButton(onClick = { navActions.navigateBack() }) {
                        Icon(Icons.Filled.ArrowBack, stringResource(id = R.string.back))
                    }
                }
            )
        }
    ) { paddingValues ->
        // LD1: Handle different UI states (Loading, Success, Error)
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = {
                // LD1: Implement pull-to-refresh functionality to reload achievements
                viewModel.refreshAchievements()
            },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (uiState) {
                is AchievementsUiState.Loading -> {
                    // LD1: For Loading state, show LoadingIndicator
                    LoadingIndicator(modifier = Modifier.fillMaxSize())
                }
                is AchievementsUiState.Error -> {
                    // LD1: For Error state, show GenericErrorView with retry action
                    GenericErrorView(
                        onRetry = { viewModel.loadAchievements() },
                        modifier = Modifier.fillMaxSize()
                    )
                }
                is AchievementsUiState.Success -> {
                    // LD1: For Success state, show achievement content with category filters and sections
                    AchievementsContent(
                        viewModel = viewModel,
                        selectedCategory = selectedCategory,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        }
    }
}

/**
 * Composable function that displays the main content of the achievements screen when data is loaded successfully
 *
 * @param viewModel ViewModel for managing the achievements screen state and data
 * @param selectedCategory Currently selected achievement category for filtering
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun AchievementsContent(
    viewModel: AchievementsViewModel,
    selectedCategory: AchievementCategory?,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column to contain all content
    Column(
        modifier = modifier.padding(16.dp)
    ) {
        // LD1: Add CategoryFilterChips component for category filtering
        CategoryFilterChips(
            selectedCategory = selectedCategory,
            onCategorySelected = { category -> viewModel.setSelectedCategory(category) },
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Get earned, in-progress, and upcoming achievements from ViewModel
        val earnedAchievements = remember(viewModel.uiState, selectedCategory) {
            viewModel.getEarnedAchievements()
        }
        val inProgressAchievements = remember(viewModel.uiState, selectedCategory) {
            viewModel.getInProgressAchievements()
        }
        val upcomingAchievements = remember(viewModel.uiState, selectedCategory) {
            viewModel.getUpcomingAchievements()
        }

        // LD1: Add AchievementSection for earned achievements if any exist
        if (earnedAchievements.isNotEmpty()) {
            AchievementSection(
                title = stringResource(id = R.string.earned_achievements),
                achievements = earnedAchievements,
                onAchievementClick = { achievement ->
                    // TODO: Implement achievement detail dialog
                },
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        // LD1: Add AchievementSection for in-progress achievements if any exist
        if (inProgressAchievements.isNotEmpty()) {
            AchievementSection(
                title = stringResource(id = R.string.in_progress_achievements),
                achievements = inProgressAchievements,
                onAchievementClick = { achievement ->
                    // TODO: Implement achievement detail dialog
                },
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        // LD1: Add AchievementSection for upcoming achievements if any exist
        if (upcomingAchievements.isNotEmpty()) {
            AchievementSection(
                title = stringResource(id = R.string.upcoming_achievements),
                achievements = upcomingAchievements,
                onAchievementClick = { achievement ->
                    // TODO: Implement achievement detail dialog
                },
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        // LD1: If no achievements in any section, show EmptyStateView
        if (earnedAchievements.isEmpty() && inProgressAchievements.isEmpty() && upcomingAchievements.isEmpty()) {
            EmptyStateView(
                message = stringResource(id = R.string.no_achievements_available),
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

/**
 * Composable function that displays horizontally scrollable filter chips for achievement categories
 *
 * @param selectedCategory Currently selected achievement category
 * @param onCategorySelected Callback function for when a category is selected
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun CategoryFilterChips(
    selectedCategory: AchievementCategory?,
    onCategorySelected: (AchievementCategory?) -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a horizontally scrollable row for filter chips
    LazyRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // LD1: Add an 'All' filter chip that clears category selection
        item {
            Chip(
                selected = selectedCategory == null,
                onClick = { onCategorySelected(null) },
                label = { Text(stringResource(id = R.string.all)) }
            )
        }

        // LD1: Add filter chips for each AchievementCategory enum value
        items(AchievementCategory.values()) { category ->
            // LD1: Highlight the currently selected category chip
            Chip(
                selected = selectedCategory == category,
                onClick = { onCategorySelected(category) },
                label = { Text(stringResource(id = category.nameResId())) }
            )
        }
    }
}

/**
 * Composable function that displays a section of achievements with a title and list of achievement cards
 *
 * @param title Title of the achievement section
 * @param achievements List of achievements to display in the section
 * @param onAchievementClick Callback function for when an achievement card is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun AchievementSection(
    title: String,
    achievements: List<Achievement>,
    onAchievementClick: (Achievement) -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column for the section
    Column(modifier = modifier) {
        // LD1: Display section title with appropriate typography
        Text(
            text = title,
            style = MaterialTheme.typography.h6,
            color = Primary,
            textAlign = TextAlign.Start,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        // LD1: Create a LazyColumn for the list of achievements
        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // LD1: For each achievement, display an AchievementCard
            items(achievements) { achievement ->
                AchievementCard(
                    achievement = achievement,
                    onClick = {
                        // LD1: Handle click events on achievement cards
                        onAchievementClick(achievement)
                    }
                )
            }
        }
    }
}

/**
 * Composable function that displays a dialog with detailed information about an achievement
 *
 * @param achievement Achievement to display details for
 * @param onDismiss Callback function for when the dialog is dismissed
 */
@Composable
private fun AchievementDetailDialog(
    achievement: Achievement,
    onDismiss: () -> Unit
) {
    // TODO: Implement AchievementDetailDialog composable
}

// Extension function to get the string resource ID for AchievementCategory
@Composable
private fun AchievementCategory.nameResId(): Int {
    return when (this) {
        AchievementCategory.STREAK -> R.string.streak
        AchievementCategory.JOURNALING -> R.string.journaling
        AchievementCategory.EMOTIONAL_AWARENESS -> R.string.emotional_awareness
        AchievementCategory.TOOL_USAGE -> R.string.tool_usage
        AchievementCategory.MILESTONE -> R.string.milestone
    }
}