# src/android/app/src/main/kotlin/com/amirawellness/ui/screens/emotions/EmotionalCheckinResultScreen.kt
```kotlin
package com.amirawellness.ui.screens.emotions

import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.rememberScrollState // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.verticalScroll // androidx.compose.foundation:1.5.0
import androidx.compose.material.* // androidx.compose.material:1.5.0
import androidx.compose.material.icons.Icons // androidx.compose.material.icons:1.5.0
import androidx.compose.material.icons.filled.ArrowBack // androidx.compose.material.icons.filled:1.5.0
import androidx.compose.runtime.Composable // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.collectAsState // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.remember // androidx.compose.runtime:1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui.res:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui.unit:1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose:1.0.0
import com.amirawellness.R // Internal import
import com.amirawellness.data.models.EmotionalState // Internal import
import com.amirawellness.data.models.EmotionalTrend // Internal import
import com.amirawellness.data.models.Tool // Internal import
import com.amirawellness.ui.components.buttons.PrimaryButton // Internal import
import com.amirawellness.ui.components.cards.EmotionCard // Internal import
import com.amirawellness.ui.components.cards.ToolCard // Internal import
import com.amirawellness.ui.components.charts.EmotionTrendChart // Internal import
import com.amirawellness.ui.components.feedback.ErrorView // Internal import
import com.amirawellness.ui.components.loading.LoadingIndicator // Internal import
import com.amirawellness.ui.navigation.NavActions // Internal import

/**
 * Main composable function for the emotional check-in result screen
 * @param navActions The navigation actions
 * @param emotionalState The emotional state
 */
@Composable
fun EmotionalCheckinResultScreen(
    navActions: NavActions,
    emotionalState: EmotionalState
) {
    // Get the ViewModel using hiltViewModel()
    val viewModel: EmotionalCheckinResultViewModel = hiltViewModel()

    // Set the emotional state in the ViewModel
    remember {
        viewModel.setEmotionalState(emotionalState)
        true // Prevent recomposition on every frame
    }

    // Collect the UI state from the ViewModel
    val uiState = viewModel.uiState.collectAsState()

    // Create a Scaffold with TopAppBar containing a back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.emotional_checkin_result_title)) },
                navigationIcon = {
                    IconButton(onClick = { viewModel.navigateBack(navActions) }) {
                        Icon(Icons.Filled.ArrowBack, stringResource(id = R.string.back))
                    }
                }
            )
        }
    ) { paddingValues ->
        // Create a scrollable Column for the main content
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // Display the current emotional state using EmotionCard
            uiState.value.emotionalState?.let {
                CurrentEmotionSection(
                    emotionalState = it,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }

            // Display insights about the emotional state
            InsightsSection(
                insights = uiState.value.insights,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // Display recommended tools section with loading state handling
            RecommendedToolsSection(
                tools = uiState.value.recommendedTools,
                isLoading = uiState.value.isLoadingTools,
                error = uiState.value.error,
                onToolClick = { toolId -> viewModel.navigateToToolDetail(navActions, toolId) },
                onSeeAllClick = { viewModel.navigateToAllTools(navActions) },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // Display emotional trends section with loading state handling
            EmotionalTrendsSection(
                trends = uiState.value.emotionalTrends,
                isLoading = uiState.value.isLoadingTrends,
                error = uiState.value.error,
                onSeeMoreClick = { viewModel.navigateToEmotionalTrends(navActions) },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }
    }
}

/**
 * Composable function that displays the current emotional state
 * @param emotionalState The emotional state
 * @param modifier The modifier
 */
@Composable
private fun CurrentEmotionSection(
    emotionalState: EmotionalState,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            SectionTitle(title = stringResource(id = R.string.current_emotion_title))
            Spacer(modifier = Modifier.height(8.dp))
            EmotionCard(
                emotionalState = emotionalState,
                onClick = { /*TODO*/ },
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

/**
 * Composable function that displays insights about the emotional state
 * @param insights The insights
 * @param modifier The modifier
 */
@Composable
private fun InsightsSection(
    insights: List<String>,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            SectionTitle(title = stringResource(id = R.string.insights_title))
            Spacer(modifier = Modifier.height(8.dp))
            insights.forEach { insight ->
                Text(text = "• $insight")
            }
        }
    }
}

/**
 * Composable function that displays recommended tools based on emotional state
 * @param tools The tools
 * @param isLoading Whether the tools are loading
 * @param error The error message
 * @param onToolClick The function to call when a tool is clicked
 * @param onSeeAllClick The function to call when the see all button is clicked
 * @param modifier The modifier
 */
@Composable
private fun RecommendedToolsSection(
    tools: List<Tool>,
    isLoading: Boolean,
    error: String?,
    onToolClick: (String) -> Unit,
    onSeeAllClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            SectionTitle(title = stringResource(id = R.string.recommended_tools_title))
            Spacer(modifier = Modifier.height(8.dp))

            if (isLoading) {
                LoadingIndicator()
            } else if (error != null) {
                ErrorView(message = error, onAction = { /*TODO*/ })
            } else if (tools.isNotEmpty()) {
                tools.forEach { tool ->
                    ToolCard(
                        tool = tool,
                        onClick = { onToolClick(tool.id) },
                        onFavoriteClick = { /*TODO*/ },
                        modifier = Modifier.padding(vertical = 4.dp)
                    )
                }
                PrimaryButton(
                    text = stringResource(id = R.string.see_all),
                    onClick = onSeeAllClick,
                    modifier = Modifier.fillMaxWidth()
                )
            } else {
                Text(text = stringResource(id = R.string.no_tools_available))
            }
        }
    }
}

/**
 * Composable function that displays emotional trends
 * @param trends The trends
 * @param isLoading Whether the trends are loading
 * @param error The error message
 * @param onSeeMoreClick The function to call when the see more button is clicked
 * @param modifier The modifier
 */
@Composable
private fun EmotionalTrendsSection(
    trends: List<EmotionalTrend>,
    isLoading: Boolean,
    error: String?,
    onSeeMoreClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            SectionTitle(title = stringResource(id = R.string.emotional_trends_title))
            Spacer(modifier = Modifier.height(8.dp))

            if (isLoading) {
                LoadingIndicator()
            } else if (error != null) {
                ErrorView(message = error, onAction = { /*TODO*/ })
            } else if (trends.isNotEmpty()) {
                EmotionTrendChart(trend = trends[0])
                Text(text = trends[0].getTrendDescription())
                PrimaryButton(
                    text = stringResource(id = R.string.see_more),
                    onClick = onSeeMoreClick,
                    modifier = Modifier.fillMaxWidth()
                )
            } else {
                Text(text = stringResource(id = R.string.no_trends_available))
            }
        }
    }
}

/**
 * Composable function that displays a section title
 * @param title The title
 * @param modifier The modifier
 */
@Composable
private fun SectionTitle(title: String, modifier: Modifier = Modifier) {
    Text(
        text = title,
        style = MaterialTheme.typography.h6,
        modifier = modifier
    )
}