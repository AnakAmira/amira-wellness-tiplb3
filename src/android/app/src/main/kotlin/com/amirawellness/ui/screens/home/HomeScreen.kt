package com.amirawellness.ui.screens.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.amirawellness.R
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.Tool
import com.amirawellness.ui.components.cards.JournalCard
import com.amirawellness.ui.components.cards.ToolCard
import com.amirawellness.ui.components.inputs.EmotionSelector
import com.amirawellness.ui.components.loading.ErrorView
import com.amirawellness.ui.components.loading.FullScreenLoading
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState
import kotlinx.coroutines.launch

/**
 * Main composable function for the home screen that displays the dashboard with user information,
 * emotional check-in prompt, recent activities, recommended tools, and streak information.
 *
 * @param navController NavController for screen transitions
 * @param modifier Modifier for customization
 */
@Composable
fun HomeScreen(
    navController: NavController,
    modifier: Modifier = Modifier
) {
    // Get HomeViewModel instance using hiltViewModel()
    val viewModel: HomeViewModel = hiltViewModel()

    // Create NavActions instance with the provided navController
    val navActions = remember(navController) { NavActions(navController) }

    // Collect uiState from viewModel as state
    val uiState by viewModel.uiState.collectAsState()

    // Create a coroutine scope using rememberCoroutineScope()
    val coroutineScope = rememberCoroutineScope()

    // Create a SwipeRefreshState for pull-to-refresh functionality
    val swipeRefreshState = rememberSwipeRefreshState(isRefreshing = uiState.isLoading)

    // Set up the main Scaffold with topBar and content
    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = { HomeTopBar() }
    ) { paddingValues ->
        // SwipeRefresh component for pull-to-refresh functionality
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = { viewModel.refreshData() },
            modifier = Modifier.padding(paddingValues)
        ) {
            // Display loading indicator when isLoading is true
            if (uiState.isLoading) {
                FullScreenLoading(isLoading = true) {
                    // Empty content when loading
                }
            }
            // Display error view when error is not null
            else if (uiState.error != null) {
                ErrorView(
                    message = stringResource(id = R.string.error_generic_title),
                    description = uiState.error,
                    onAction = { viewModel.loadHomeData() }
                )
            }
            // Display the main content when data is loaded
            else {
                HomeContent(
                    uiState = uiState,
                    navActions = navActions,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}

/**
 * Composable function that displays the main content of the home screen
 *
 * @param uiState The UI state for the home screen
 * @param navActions Navigation actions for screen transitions
 * @param modifier Modifier for customization
 */
@Composable
private fun HomeContent(
    uiState: HomeUiState,
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // Create a LazyColumn for scrollable content
    LazyColumn(
        modifier = modifier,
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Display user greeting section with user's name
        item {
            UserGreetingSection(
                userName = uiState.user?.email ?: stringResource(id = R.string.text_default_user_name)
            )
        }

        // Display emotional check-in prompt section
        item {
            EmotionalCheckInPrompt(
                lastEmotionalState = uiState.lastEmotionalState,
                onCheckInClick = { navActions.navigateToEmotionalCheckin("home") }
            )
        }

        // Display recent activities section with journal entries
        item {
            RecentActivitiesSection(
                journals = uiState.recentJournals,
                onJournalClick = { journalId -> navActions.navigateToJournalDetail(journalId) },
                onCreateJournalClick = { navActions.navigateToRecordJournal() }
            )
        }

        // Display recommended tools section
        item {
            RecommendedToolsSection(
                tools = uiState.recommendedTools,
                onToolClick = { toolId -> navActions.navigateToToolDetail(toolId) }
            )
        }

        // Display streak information section
        item {
            StreakSection(
                streakInfo = uiState.streakInfo,
                onViewProgressClick = { navActions.navigateToProgressDashboard() }
            )
        }
    }
}

/**
 * Composable function that displays a personalized greeting to the user
 *
 * @param userName The name of the user
 * @param modifier Modifier for customization
 */
@Composable
private fun UserGreetingSection(
    userName: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        Text(
            text = stringResource(id = R.string.text_greeting_time_based),
            style = MaterialTheme.typography.h5,
            color = TextPrimary
        )
        Text(
            text = userName,
            style = MaterialTheme.typography.h4,
            color = TextPrimary
        )
    }
}

/**
 * Composable function that displays a prompt for emotional check-in
 *
 * @param lastEmotionalState The last recorded emotional state
 * @param onCheckInClick Callback for when the check-in button is clicked
 * @param modifier Modifier for customization
 */
@Composable
private fun EmotionalCheckInPrompt(
    lastEmotionalState: com.amirawellness.data.models.EmotionalState?,
    onCheckInClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        backgroundColor = Surface,
        elevation = 0.dp,
        shape = MaterialTheme.shapes.medium
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = stringResource(id = R.string.text_how_are_you_feeling),
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )
            if (lastEmotionalState != null) {
                Text(
                    text = stringResource(id = R.string.text_last_checkin, lastEmotionalState.emotionType, lastEmotionalState.createdAt),
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            PrimaryButton(
                text = stringResource(id = R.string.action_check_in),
                onClick = onCheckInClick
            )
        }
    }
}

/**
 * Composable function that displays recent journal entries
 *
 * @param journals List of recent journal entries
 * @param onJournalClick Callback for when a journal is clicked
 * @param onCreateJournalClick Callback for when the create journal button is clicked
 * @param modifier Modifier for customization
 */
@Composable
private fun RecentActivitiesSection(
    journals: List<Journal>,
    onJournalClick: (String) -> Unit,
    onCreateJournalClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        SectionHeader(
            title = stringResource(id = R.string.text_recent_activities),
            actionText = stringResource(id = R.string.action_see_all),
            onActionClick = {}
        )

        if (journals.isEmpty()) {
            Text(
                text = stringResource(id = R.string.text_no_recent_journals),
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(16.dp)
            )
        } else {
            journals.forEach { journal ->
                JournalCard(
                    journal = journal,
                    onClick = { onJournalClick(journal.id) },
                    onPlayClick = { /*TODO*/ },
                    onFavoriteClick = { /*TODO*/ }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }

        PrimaryButton(
            text = stringResource(id = R.string.action_create_new_journal),
            onClick = onCreateJournalClick
        )
    }
}

/**
 * Composable function that displays recommended tools based on emotional state
 *
 * @param tools List of recommended tools
 * @param onToolClick Callback for when a tool is clicked
 * @param modifier Modifier for customization
 */
@Composable
private fun RecommendedToolsSection(
    tools: List<Tool>,
    onToolClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        SectionHeader(
            title = stringResource(id = R.string.text_recommended_tools)
        )

        if (tools.isEmpty()) {
            Text(
                text = stringResource(id = R.string.text_no_recommended_tools),
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(16.dp)
            )
        } else {
            tools.forEach { tool ->
                ToolCard(
                    tool = tool,
                    onClick = { onToolClick(tool.id) },
                    onFavoriteClick = { /*TODO*/ }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

/**
 * Composable function that displays the user's current streak information
 *
 * @param streakInfo The streak information
 * @param onViewProgressClick Callback for when the view progress button is clicked
 * @param modifier Modifier for customization
 */
@Composable
private fun StreakSection(
    streakInfo: com.amirawellness.data.models.StreakInfo?,
    onViewProgressClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        backgroundColor = Surface,
        elevation = 0.dp,
        shape = MaterialTheme.shapes.medium
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = stringResource(id = R.string.text_your_streak),
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )

            if (streakInfo == null) {
                Text(
                    text = stringResource(id = R.string.text_start_a_streak),
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(16.dp)
                )
            } else {
                Text(
                    text = stringResource(id = R.string.text_current_streak, streakInfo.currentStreak),
                    style = MaterialTheme.typography.body1,
                    color = TextPrimary
                )
                LinearProgressIndicator(
                    progress = streakInfo.progressToNextMilestone,
                    color = Primary,
                    backgroundColor = Surface
                )
                Text(
                    text = stringResource(id = R.string.text_next_milestone, streakInfo.nextMilestone),
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
            }

            Spacer(modifier = Modifier.height(8.dp))
            PrimaryButton(
                text = stringResource(id = R.string.action_view_progress),
                onClick = onViewProgressClick
            )
        }
    }
}

/**
 * Composable function that displays a section header with optional action
 *
 * @param title The title of the section
 * @param actionText The text for the action button
 * @param onActionClick Callback for when the action button is clicked
 * @param modifier Modifier for customization
 */
@Composable
private fun SectionHeader(
    title: String,
    actionText: String? = null,
    onActionClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.h5,
            color = TextPrimary
        )
        if (actionText != null && onActionClick != null) {
            TextButton(onClick = { onActionClick() }) {
                Text(
                    text = actionText,
                    style = MaterialTheme.typography.button,
                    color = Primary
                )
            }
        }
    }
}

/**
 * Composable function that displays the top app bar for the home screen
 *
 * @param modifier Modifier for customization
 */
@Composable
private fun HomeTopBar(modifier: Modifier = Modifier) {
    TopAppBar(
        title = {
            Text(text = stringResource(id = R.string.app_name))
        },
        backgroundColor = Surface,
        contentColor = TextPrimary,
        elevation = 0.dp
    )
}