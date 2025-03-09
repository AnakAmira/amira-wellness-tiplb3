package com.amirawellness.ui.screens.progress

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.CircularProgressIndicator
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Scaffold
import androidx.compose.material.Tab
import androidx.compose.material.TabRow
import androidx.compose.material.Text
import androidx.compose.material.TopAppBar
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Timeline
import androidx.compose.material.pullrefresh.PullRefreshIndicator
import androidx.compose.material.pullrefresh.pullRefresh
import androidx.compose.material.pullrefresh.rememberPullRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.amirawellness.data.models.EmotionalInsight
import com.amirawellness.data.models.PeriodType
import com.amirawellness.data.models.TrendDataPoint
import com.amirawellness.ui.components.cards.AchievementCard
import com.amirawellness.ui.components.charts.ActivityBarChart
import com.amirawellness.ui.components.charts.EmotionTrendChartWithLegend
import com.amirawellness.ui.components.charts.StreakChart
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Background
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import java.time.DayOfWeek
import kotlinx.coroutines.launch

/**
 * Main composable function for the Progress Dashboard screen
 *
 * @param navActions Navigation actions for screen transitions
 * @param modifier Modifier for styling and layout
 */
@Composable
fun ProgressDashboardScreen(
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // LD1: Get ViewModel instance using hiltViewModel()
    val viewModel: ProgressDashboardViewModel = hiltViewModel()

    // LD1: Collect UI state from ViewModel using collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    // LD1: Create a coroutine scope using rememberCoroutineScope()
    val coroutineScope = rememberCoroutineScope()

    // LD1: Create a pull-to-refresh state for refreshing data
    val pullRefreshState = rememberPullRefreshState(
        refreshing = uiState is ProgressUiState.Loading,
        onRefresh = { viewModel.refreshData() }
    )

    // LD1: Create a Scaffold with TopAppBar showing 'Mi Progreso' title
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "Mi Progreso", color = TextPrimary) },
                backgroundColor = Background,
                navigationIcon = {
                    IconButton(onClick = { navActions.navigateBack() }) {
                        Icon(Icons.Filled.ArrowBack, "Back", tint = TextPrimary)
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.refreshData() }) {
                        Icon(Icons.Filled.Refresh, "Refresh", tint = TextPrimary)
                    }
                }
            )
        },
        modifier = modifier.fillMaxSize()
    ) { paddingValues ->
        // LD1: Implement pull-to-refresh functionality for the content
        Box(modifier = Modifier.pullRefresh(pullRefreshState)) {
            // LD1: Handle different UI states (Loading, Success, Error)
            when (uiState) {
                is ProgressUiState.Loading -> {
                    // LD1: For Loading state, show CircularProgressIndicator
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center),
                        color = Primary
                    )
                }
                is ProgressUiState.Error -> {
                    // LD1: For Error state, show error message with retry button
                    ErrorContent(
                        message = (uiState as ProgressUiState.Error).message,
                        onRetry = { viewModel.refreshData() },
                        modifier = Modifier.padding(paddingValues)
                    )
                }
                is ProgressUiState.Success -> {
                    // LD1: For Success state, render the dashboard content
                    ProgressDashboardContent(
                        data = (uiState as ProgressUiState.Success).data,
                        viewModel = viewModel,
                        navActions = navActions,
                        modifier = Modifier.padding(paddingValues)
                    )
                }
            }
            // LD1: Add PullRefreshIndicator to show refresh status
            PullRefreshIndicator(
                refreshing = uiState is ProgressUiState.Loading,
                state = pullRefreshState,
                modifier = Modifier.align(Alignment.TopCenter),
                contentColor = Primary
            )
        }
    }
}

/**
 * Composable function that renders the main content of the Progress Dashboard when data is loaded successfully
 *
 * @param data The loaded progress data
 * @param viewModel The ProgressDashboardViewModel instance
 * @param navActions Navigation actions for screen transitions
 * @param modifier Modifier for styling and layout
 */
@Composable
fun ProgressDashboardContent(
    data: ProgressData,
    viewModel: ProgressDashboardViewModel,
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // LD1: Create a LazyColumn for scrollable content
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 16.dp)
    ) {
        // LD1: Add StreakSection showing streak information
        item {
            StreakSection(data = data, modifier = Modifier.padding(horizontal = 16.dp))
        }

        // LD1: Add EmotionalTrendsSection showing emotional trends
        item {
            EmotionalTrendsSection(data = data, viewModel = viewModel, navActions = navActions, modifier = Modifier.padding(horizontal = 16.dp))
        }

        // LD1: Add AchievementsSection showing recent achievements
        item {
            AchievementsSection(viewModel = viewModel, navActions = navActions, modifier = Modifier.padding(horizontal = 16.dp))
        }

        // LD1: Add ActivitySection showing activity statistics
        item {
            ActivitySection(data = data, modifier = Modifier.padding(horizontal = 16.dp))
        }

        // LD1: Add InsightsSection showing emotional insights
        item {
            InsightsSection(insights = data.insights, modifier = Modifier.padding(horizontal = 16.dp))
        }

        // LD1: Apply proper spacing between sections
        item {
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

/**
 * Composable function that renders the streak information section
 *
 * @param data The loaded progress data
 * @param modifier Modifier for styling and layout
 */
@Composable
fun StreakSection(
    data: ProgressData,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Card container with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp,
        backgroundColor = Surface
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Add section title 'Racha actual'
            SectionTitle(title = "Racha actual")

            // LD1: Render StreakChart component with streak data
            StreakChart(streakInfo = data.streakInfo)

            // LD1: Show current streak and longest streak information
            Text(
                text = "Racha actual: ${data.streakInfo.currentStreak} d\u00edas",
                style = MaterialTheme.typography.body2,
                color = TextSecondary
            )
            Text(
                text = "Racha m\u00e1s larga: ${data.streakInfo.longestStreak} d\u00edas",
                style = MaterialTheme.typography.body2,
                color = TextSecondary
            )

            // LD1: Show progress towards next milestone
            Text(
                text = "Pr\u00f3ximo logro: ${data.streakInfo.nextMilestone} d\u00edas",
                style = MaterialTheme.typography.body2,
                color = TextSecondary
            )
        }
    }
}

/**
 * Composable function that renders the emotional trends section with period selection
 *
 * @param data The loaded progress data
 * @param viewModel The ProgressDashboardViewModel instance
 * @param navActions Navigation actions for screen transitions
 * @param modifier Modifier for styling and layout
 */
@Composable
fun EmotionalTrendsSection(
    data: ProgressData,
    viewModel: ProgressDashboardViewModel,
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Card container with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp,
        backgroundColor = Surface
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Add section title 'Tendencias emocionales'
            SectionTitle(title = "Tendencias emocionales")

            // LD1: Add TabRow for period selection (WEEK/MONTH)
            val selectedPeriod by viewModel.selectedPeriod.collectAsState()
            PeriodSelector(
                selectedPeriod = selectedPeriod,
                onPeriodSelected = { viewModel.setPeriodType(it) }
            )

            // LD1: Collect selected period from ViewModel
            val emotionalTrends = data.emotionalTrends

            if (emotionalTrends.isNotEmpty()) {
                // LD1: Render EmotionTrendChartWithLegend for the primary emotion trend
                EmotionTrendChartWithLegend(trend = emotionalTrends.first())

                // LD1: Add 'Ver m\u00e1s' button that navigates to detailed trends screen
                SeeAllButton(text = "Ver m\u00e1s", onClick = { navActions.navigateToEmotionalTrends() })
            } else {
                // LD1: Handle empty state when no emotional data is available
                Text(
                    text = "No hay datos emocionales disponibles.",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary,
                    modifier = Modifier.padding(vertical = 16.dp)
                )
            }
        }
    }
}

/**
 * Composable function that renders the achievements section
 *
 * @param viewModel The ProgressDashboardViewModel instance
 * @param navActions Navigation actions for screen transitions
 * @param modifier Modifier for styling and layout
 */
@Composable
fun AchievementsSection(
    viewModel: ProgressDashboardViewModel,
    navActions: NavActions,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Card container with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp,
        backgroundColor = Surface
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Add section title 'Logros'
            SectionTitle(title = "Logros")

            // LD1: Get earned and in-progress achievements from ViewModel
            val earnedAchievements = viewModel.getEarnedAchievements()
            val inProgressAchievements = viewModel.getInProgressAchievements()

            // LD1: Create a LazyRow for horizontal scrolling of achievements
            if (earnedAchievements.isNotEmpty() || inProgressAchievements.isNotEmpty()) {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(earnedAchievements) { achievement ->
                        // LD1: Render AchievementCard for each achievement
                        AchievementCard(achievement = achievement, onClick = { /*TODO*/ })
                    }
                    items(inProgressAchievements) { achievement ->
                        // LD1: Render AchievementCard for each achievement
                        AchievementCard(achievement = achievement, onClick = { /*TODO*/ })
                    }
                }

                // LD1: Add 'Ver todos' button that navigates to achievements screen
                SeeAllButton(text = "Ver todos", onClick = { navActions.navigateToAchievements() })
            } else {
                // LD1: Handle empty state when no achievements are available
                Text(
                    text = "No hay logros disponibles.",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary,
                    modifier = Modifier.padding(vertical = 16.dp)
                )
            }
        }
    }
}

/**
 * Composable function that renders the activity statistics section
 *
 * @param data The loaded progress data
 * @param modifier Modifier for styling and layout
 */
@Composable
fun ActivitySection(
    data: ProgressData,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Card container with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp,
        backgroundColor = Surface
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Add section title 'Actividad semanal'
            SectionTitle(title = "Actividad semanal")

            // LD1: Extract activity data from usageStatistics
            val usageStatistics = data.usageStatistics
            if (usageStatistics.isNotEmpty()) {
                // LD1: Determine most active day of week
                val activityByDay = mapActivityData(usageStatistics)
                val mostActiveDay = getMostActiveDay(activityByDay)

                // LD1: Render ActivityBarChart component
                ActivityBarChart(activityByDay = activityByDay, mostActiveDay = mostActiveDay)

                // LD1: Show additional activity statistics (total sessions, average duration)
                Text(
                    text = "D\u00eda m\u00e1s activo: ${mostActiveDay.name}",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
                Text(
                    text = "Total de sesiones: ${usageStatistics["totalSessions"]}",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
                Text(
                    text = "Duraci\u00f3n promedio: ${usageStatistics["averageDuration"]} minutos",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            } else {
                // LD1: Handle empty state when no activity data is available
                Text(
                    text = "No hay datos de actividad disponibles.",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary,
                    modifier = Modifier.padding(vertical = 16.dp)
                )
            }
        }
    }
}

/**
 * Composable function that renders the emotional insights section
 *
 * @param insights List of emotional insights
 * @param modifier Modifier for styling and layout
 */
@Composable
fun InsightsSection(
    insights: List<EmotionalInsight>,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Card container with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp,
        backgroundColor = Surface
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // LD1: Add section title 'Descubrimientos'
            SectionTitle(title = "Descubrimientos")

            // LD1: Filter insights to show only high-confidence ones
            val highConfidenceInsights = remember(insights) {
                insights.filter { it.confidence > 0.7 }
            }

            // LD1: Create a LazyColumn for insights list
            if (highConfidenceInsights.isNotEmpty()) {
                LazyColumn {
                    items(highConfidenceInsights) { insight ->
                        // LD1: Render each insight with appropriate styling
                        Text(
                            text = insight.description,
                            style = MaterialTheme.typography.body2,
                            color = TextSecondary,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    }
                }
            } else {
                // LD1: Handle empty state when no insights are available
                Text(
                    text = "No hay descubrimientos disponibles.",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary,
                    modifier = Modifier.padding(vertical = 16.dp)
                )
            }
        }
    }
}

/**
 * Reusable composable function for section titles
 *
 * @param title The title text
 * @param modifier Modifier for styling and layout
 */
@Composable
fun SectionTitle(title: String, modifier: Modifier = Modifier) {
    // LD1: Create a Row with appropriate styling
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // LD1: Render Text component with title text
        Text(
            text = title,
            style = MaterialTheme.typography.h6,
            color = TextPrimary
        )
    }
}

/**
 * Reusable composable function for 'See All' buttons
 *
 * @param text The button text
 * @param onClick The click action
 * @param modifier Modifier for styling and layout
 */
@Composable
fun SeeAllButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    // LD1: Create a Row with appropriate styling
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.End,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // LD1: Render Text component with button text
        Text(
            text = text,
            style = MaterialTheme.typography.button,
            color = Primary
        )

        // LD1: Add ChevronRight icon
        Icon(
            imageVector = Icons.Filled.ChevronRight,
            contentDescription = "See All",
            tint = Primary
        )
    }
}

/**
 * Composable function that renders error state content
 *
 * @param message The error message
 * @param onRetry The retry action
 * @param modifier Modifier for styling and layout
 */
@Composable
fun ErrorContent(message: String, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    // LD1: Create a Column with center alignment
    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // LD1: Show error icon
        Icon(
            imageVector = Icons.Filled.BarChart,
            contentDescription = "Error",
            tint = Secondary,
            modifier = Modifier.size(48.dp)
        )

        // LD1: Display error message text
        Text(
            text = message,
            style = MaterialTheme.typography.body2,
            color = TextSecondary,
            modifier = Modifier.padding(16.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )

        // LD1: Add retry button
        Button(onClick = onRetry) {
            Text(text = "Reintentar")
        }

        // LD1: Apply appropriate styling and spacing
        Spacer(modifier = Modifier.height(8.dp))
    }
}

/**
 * Composable function for period selection tabs
 *
 * @param selectedPeriod The selected period type
 * @param onPeriodSelected The action to perform when a period is selected
 * @param modifier Modifier for styling and layout
 */
@Composable
fun PeriodSelector(
    selectedPeriod: PeriodType,
    onPeriodSelected: (PeriodType) -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a TabRow with appropriate styling
    TabRow(
        selectedTabIndex = selectedPeriod.ordinal,
        backgroundColor = Surface,
        contentColor = Primary,
        modifier = modifier.fillMaxWidth()
    ) {
        // LD1: Add Tab for WEEK period ('Semana')
        Tab(
            selected = selectedPeriod == PeriodType.WEEK,
            onClick = { onPeriodSelected(PeriodType.WEEK) },
            text = { Text(text = "Semana") }
        )

        // LD1: Add Tab for MONTH period ('Mes')
        Tab(
            selected = selectedPeriod == PeriodType.MONTH,
            onClick = { onPeriodSelected(PeriodType.MONTH) },
            text = { Text(text = "Mes") }
        )
    }
}

/**
 * Helper function to map activity data from the ViewModel to the format needed by ActivityBarChart
 *
 * @param usageStatistics Map containing usage statistics
 * @return Mapped activity data by day of week
 */
fun mapActivityData(usageStatistics: Map<String, Any>): Map<DayOfWeek, Int> {
    // LD1: Extract activity by day data from usageStatistics
    val activityByDayString = usageStatistics["activityByDay"] as? Map<String, Int> ?: emptyMap()

    // LD1: Convert string day names to DayOfWeek enum values
    return activityByDayString.mapKeys { (day, _) ->
        when (day) {
            "MONDAY" -> DayOfWeek.MONDAY
            "TUESDAY" -> DayOfWeek.TUESDAY
            "WEDNESDAY" -> DayOfWeek.WEDNESDAY
            "THURSDAY" -> DayOfWeek.THURSDAY
            "FRIDAY" -> DayOfWeek.FRIDAY
            "SATURDAY" -> DayOfWeek.SATURDAY
            "SUNDAY" -> DayOfWeek.SUNDAY
            else -> DayOfWeek.MONDAY // Default to Monday if the day is not recognized
        }
    }
}

/**
 * Helper function to determine the most active day of the week
 *
 * @param activityByDay Mapped activity data by day of week
 * @return The day with the highest activity count
 */
fun getMostActiveDay(activityByDay: Map<DayOfWeek, Int>): DayOfWeek {
    // LD1: Find the entry with the maximum activity count
    return activityByDay.maxByOrNull { it.value }?.key ?: DayOfWeek.MONDAY
}