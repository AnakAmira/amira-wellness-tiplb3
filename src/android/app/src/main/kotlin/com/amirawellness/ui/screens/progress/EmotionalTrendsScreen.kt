package com.amirawellness.ui.screens.progress

import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout version: 1.5.0
import androidx.compose.foundation.lazy.LazyColumn // androidx.compose.foundation version: 1.5.0
import androidx.compose.foundation.lazy.items // androidx.compose.foundation version: 1.5.0
import androidx.compose.material.* // androidx.compose.material version: 1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime version: 1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime version: 1.5.0
import androidx.compose.runtime.getValue // androidx.compose.runtime version: 1.5.0
import androidx.compose.runtime.remember // androidx.compose.runtime version: 1.5.0
import androidx.compose.runtime.mutableStateOf // androidx.compose.runtime version: 1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose version: 1.0.0
import androidx.navigation.NavController // androidx.navigation version: 2.7.0
import androidx.navigation.compose.rememberNavController // androidx.navigation.compose version: 2.7.0
import com.google.accompanist.swiperefresh.SwipeRefresh // com.google.accompanist.swiperefresh version: 0.30.1
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState // com.google.accompanist.swiperefresh version: 0.30.1
import com.amirawellness.R // Reference to the R class for resources
import com.amirawellness.ui.components.charts.EmotionTrendChartWithLegend // src/android/app/src/main/kotlin/com/amirawellness/ui/components/charts/EmotionTrendChart.kt
import com.amirawellness.ui.components.loading.LoadingIndicator // src/android/app/src/main/kotlin/com/amirawellness/ui/components/loading/LoadingIndicator.kt
import com.amirawellness.ui.components.feedback.ErrorView // src/android/app/src/main/kotlin/com/amirawellness/ui/components/feedback/ErrorView.kt
import com.amirawellness.ui.components.feedback.EmptyStateView // src/android/app/src/main/kotlin/com/amirawellness/ui/components/feedback/EmptyStateView.kt
import com.amirawellness.ui.navigation.NavActions // src/android/app/src/main/kotlin/com/amirawellness/ui/navigation/NavActions.kt
import com.amirawellness.data.models.EmotionalTrend // src/android/app/src/main/kotlin/com/amirawellness/data/models/EmotionalTrend.kt
import com.amirawellness.data.models.TrendDataPoint // src/android/app/src/main/kotlin/com/amirawellness/data/models/EmotionalTrend.kt
import com.amirawellness.data.models.EmotionalInsight // src/android/app/src/main/kotlin/com/amirawellness/data/models/EmotionalTrend.kt
import com.amirawellness.data.models.PeriodType // src/android/app/src/main/kotlin/com/amirawellness/data/models/EmotionalTrend.kt
import com.amirawellness.core.constants.AppConstants.EmotionType // src/android/app/src/main/kotlin/com/amirawellness/core/constants/AppConstants.kt

/**
 * Main composable function for the Emotional Trends screen
 *
 * @param navController NavController for screen navigation
 */
@Composable
fun EmotionalTrendsScreen(navController: NavController) {

    // Obtain the EmotionalTrendsViewModel instance using hiltViewModel()
    val viewModel: EmotionalTrendsViewModel = hiltViewModel()

    // Create NavActions instance with the provided navController
    val navActions = remember { NavActions(navController) }

    // Collect uiState and selectedPeriodType from the ViewModel as Compose State
    val uiState by viewModel.uiState.collectAsState()
    val selectedPeriodType by viewModel.selectedPeriodType.collectAsState()

    // Create a SwipeRefreshState for pull-to-refresh functionality
    val swipeRefreshState = rememberSwipeRefreshState(uiState is EmotionalTrendsViewModel.EmotionalTrendsUiState.Loading)

    // Create a Scaffold with a TopAppBar containing a title and back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(id = R.string.emotional_trends_title),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navActions.navigateBack() }) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = stringResource(id = R.string.back)
                        )
                    }
                }
            )
        }
    ) { paddingValues ->

        // Implement SwipeRefresh for pull-to-refresh functionality
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = { viewModel.refreshData() },
            modifier = Modifier.padding(paddingValues)
        ) {

            // Handle different UI states (Loading, Success, Error) with appropriate components
            when (uiState) {
                is EmotionalTrendsViewModel.EmotionalTrendsUiState.Loading -> {
                    // For Loading state, show LoadingIndicator
                    LoadingIndicator(modifier = Modifier.fillMaxSize())
                }
                is EmotionalTrendsViewModel.EmotionalTrendsUiState.Error -> {
                    // For Error state, show ErrorView with retry button
                    val errorMessage = (uiState as EmotionalTrendsViewModel.EmotionalTrendsUiState.Error).message
                    ErrorView(
                        message = errorMessage,
                        actionText = stringResource(id = R.string.retry),
                        onAction = { viewModel.refreshData() },
                        modifier = Modifier.fillMaxSize()
                    )
                }
                is EmotionalTrendsViewModel.EmotionalTrendsUiState.Success -> {
                    // Get the success state
                    val successState = uiState as EmotionalTrendsViewModel.EmotionalTrendsUiState.Success

                    // Check if the data is empty
                    if (successState.trends.isEmpty()) {
                        // For Success state with empty data, show EmptyStateView
                        EmptyStateView(
                            message = stringResource(id = R.string.no_emotional_data),
                            modifier = Modifier.fillMaxSize()
                        )
                    } else {
                        // For Success state with data, show the emotional trends content
                        val frequentEmotions = viewModel.getMostFrequentEmotions()
                        EmotionalTrendsContent(
                            viewModel = viewModel,
                            selectedPeriodType = selectedPeriodType,
                            frequentEmotions = frequentEmotions,
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }
            }
        }
    }
}

/**
 * Composable function that displays the main content of the Emotional Trends screen when data is available
 *
 * @param viewModel ViewModel for managing the emotional trends screen state and data
 * @param selectedPeriodType Currently selected period type for trend analysis
 * @param frequentEmotions List of most frequent emotions with their counts
 * @param modifier Modifier for styling and layout
 */
@Composable
fun EmotionalTrendsContent(
    viewModel: EmotionalTrendsViewModel,
    selectedPeriodType: PeriodType,
    frequentEmotions: List<Pair<EmotionType, Int>>,
    modifier: Modifier = Modifier
) {

    // Create a remember state for the selected emotion
    val selectedEmotion = remember { mutableStateOf<EmotionType?>(null) }

    // Create a LazyColumn for scrollable content
    LazyColumn(
        modifier = modifier.padding(16.dp)
    ) {

        // Implement period type selection with Tabs for DAY, WEEK, and MONTH
        item {
            PeriodSelectionTabs(
                selectedPeriodType = selectedPeriodType,
                onPeriodSelected = { periodType -> viewModel.setPeriodType(periodType) },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Add section title for "Most Frequent Emotions"
        item {
            SectionTitle(
                title = stringResource(id = R.string.most_frequent_emotions),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        // Add horizontal row of emotion cards for frequent emotions
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                frequentEmotions.forEach { (emotionType, count) ->
                    EmotionCard(
                        emotionType = emotionType,
                        count = count,
                        isSelected = selectedEmotion.value == emotionType,
                        onClick = { selectedEmotion.value = emotionType },
                        modifier = Modifier.width(120.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        // When an emotion is selected, show its trend chart and insights
        selectedEmotion.value?.let { emotionType ->
            val trend = viewModel.getTrendForEmotion(emotionType)
            trend?.let {
                item {
                    SectionTitle(
                        title = stringResource(id = R.string.emotional_trend_for, emotionType.name),
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }

                // Display EmotionTrendChartWithLegend for the selected emotion
                item {
                    EmotionTrendChartWithLegend(
                        trend = it,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }

                // Display insights related to the selected emotion
                val insights = viewModel.getInsightsForEmotion(emotionType)
                if (insights.isNotEmpty()) {
                    item {
                        SectionTitle(
                            title = stringResource(id = R.string.insights_for, emotionType.name),
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    items(insights) { insight ->
                        InsightCard(
                            insight = insight,
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }
    }
}

/**
 * Composable function that displays tabs for selecting the time period for trend analysis
 *
 * @param selectedPeriodType Currently selected period type
 * @param onPeriodSelected Callback function when a period type is selected
 * @param modifier Modifier for styling and layout
 */
@Composable
fun PeriodSelectionTabs(
    selectedPeriodType: PeriodType,
    onPeriodSelected: (PeriodType) -> Unit,
    modifier: Modifier = Modifier
) {

    // Create a TabRow with tabs for DAY, WEEK, and MONTH period types
    TabRow(
        selectedTabIndex = selectedPeriodType.ordinal,
        modifier = modifier
    ) {

        // Highlight the currently selected period type
        PeriodType.values().forEach { periodType ->
            Tab(
                selected = selectedPeriodType == periodType,
                onClick = { onPeriodSelected(periodType) },
                text = {

                    // Display the localized display name for each period type
                    Text(text = periodType.getDisplayName())
                }
            )
        }
    }
}

/**
 * Composable function that displays a card for an emotion with its frequency count
 *
 * @param emotionType Emotion type to display
 * @param count Frequency count of the emotion
 * @param isSelected Whether the emotion is currently selected
 * @param onClick Callback function when the card is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
fun EmotionCard(
    emotionType: EmotionType,
    count: Int,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {

    // Create a Card with appropriate elevation and shape
    Card(
        modifier = modifier.clickable { onClick() },
        elevation = 4.dp,
        shape = MaterialTheme.shapes.small,
        backgroundColor = if (isSelected) MaterialTheme.colors.secondary else MaterialTheme.colors.surface
    ) {
        Column(
            modifier = Modifier.padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {

            // Display the emotion icon or emoji
            Text(
                text = emotionType.name,
                style = MaterialTheme.typography.body2,
                color = MaterialTheme.colors.onSurface
            )

            // Display the emotion name
            Text(
                text = stringResource(id = R.string.count, count),
                style = MaterialTheme.typography.caption,
                color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
            )
        }
    }
}

/**
 * Composable function that displays a card for an emotional insight
 *
 * @param insight Emotional insight to display
 * @param modifier Modifier for styling and layout
 */
@Composable
fun InsightCard(
    insight: EmotionalInsight,
    modifier: Modifier = Modifier
) {

    // Create a Card with appropriate elevation and shape
    Card(
        modifier = modifier,
        elevation = 2.dp,
        shape = MaterialTheme.shapes.small
    ) {
        Column(
            modifier = Modifier.padding(8.dp)
        ) {

            // Display the insight type as a title
            Text(
                text = insight.type,
                style = MaterialTheme.typography.subtitle2,
                color = MaterialTheme.colors.primary
            )

            // Display the insight description
            Text(
                text = insight.description,
                style = MaterialTheme.typography.body2,
                color = MaterialTheme.colors.onSurface
            )

            // Display the confidence level as a percentage
            Text(
                text = stringResource(id = R.string.confidence, insight.confidence),
                style = MaterialTheme.typography.caption,
                color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
            )

            // If there are recommended actions, display them as a list
            if (insight.recommendedActions.isNotEmpty()) {
                RecommendedActionsList(
                    actions = insight.recommendedActions,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        }
    }
}

/**
 * Composable function that displays a list of recommended actions based on insights
 *
 * @param actions List of recommended actions
 * @param modifier Modifier for styling and layout
 */
@Composable
fun RecommendedActionsList(
    actions: List<String>,
    modifier: Modifier = Modifier
) {

    // Create a Column for the list of actions
    Column(modifier = modifier) {

        // Display a title for the recommendations section
        Text(
            text = stringResource(id = R.string.recommended_actions),
            style = MaterialTheme.typography.subtitle2,
            color = MaterialTheme.colors.primary
        )

        // For each action, display a row with a bullet point and the action text
        actions.forEach { action ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "\u2022", color = MaterialTheme.colors.onSurface)
                Spacer(modifier = Modifier.width(4.dp))
                Text(text = action, color = MaterialTheme.colors.onSurface)
            }
        }
    }
}

/**
 * Composable function that displays a section title with consistent styling
 *
 * @param title Title text to display
 * @param modifier Modifier for styling and layout
 */
@Composable
fun SectionTitle(
    title: String,
    modifier: Modifier = Modifier
) {

    // Create a Text component with the title
    Text(
        text = title,
        style = MaterialTheme.typography.h6,
        color = MaterialTheme.colors.primary,
        modifier = modifier.padding(bottom = 8.dp)
    )
}