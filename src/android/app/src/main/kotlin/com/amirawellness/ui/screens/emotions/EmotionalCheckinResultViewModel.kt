package com.amirawellness.ui.screens.emotions

import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import com.amirawellness.core.utils.LogUtils // Internal import
import com.amirawellness.data.models.EmotionalState // Internal import
import com.amirawellness.data.models.EmotionalTrend // Internal import
import com.amirawellness.data.models.PeriodType // Internal import
import com.amirawellness.data.models.Tool // Internal import
import com.amirawellness.domain.usecases.emotional.GetEmotionalTrendsUseCase // Internal import
import com.amirawellness.domain.usecases.tool.GetRecommendedToolsUseCase // Internal import
import com.amirawellness.ui.navigation.NavActions // Internal import
import dagger.hilt.android.lifecycle.HiltViewModel // dagger-hilt-android-compiler:2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import javax.inject.Inject // javax.inject:javax.inject:1

private const val TAG = "EmotionalCheckinResultViewModel"
private const val MAX_RECOMMENDED_TOOLS = 3

/**
 * ViewModel for managing the UI state and business logic of the emotional check-in result screen
 */
@HiltViewModel
class EmotionalCheckinResultViewModel @Inject constructor(
    private val getRecommendedToolsUseCase: GetRecommendedToolsUseCase,
    private val getEmotionalTrendsUseCase: GetEmotionalTrendsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(EmotionalCheckinResultUiState.initial())

    /**
     * Provides a read-only stream of the UI state
     */
    val uiState: StateFlow<EmotionalCheckinResultUiState> = _uiState.asStateFlow()

    /**
     * Sets the emotional state and loads related data
     *
     * @param emotionalState The emotional state to set
     */
    fun setEmotionalState(emotionalState: EmotionalState) {
        LogUtils.logDebug(TAG, "Setting emotional state: ${emotionalState.emotionType}")
        _uiState.value = _uiState.value.copy(emotionalState = emotionalState)
        loadRecommendedTools()
        loadEmotionalTrends()
    }

    /**
     * Loads recommended tools based on the current emotional state
     */
    private fun loadRecommendedTools() {
        val emotionalState = _uiState.value.emotionalState
        if (emotionalState == null) {
            LogUtils.logDebug(TAG, "Emotional state is null, skipping tool recommendations")
            return
        }

        LogUtils.logDebug(TAG, "Loading recommended tools for emotion: ${emotionalState.emotionType}")
        _uiState.value = _uiState.value.copy(isLoadingTools = true)

        viewModelScope.launch {
            getRecommendedToolsUseCase(emotionalState)
                .onSuccess { tools ->
                    LogUtils.logDebug(TAG, "Successfully loaded ${tools.size} recommended tools")
                    _uiState.value = _uiState.value.copy(
                        recommendedTools = tools.take(MAX_RECOMMENDED_TOOLS),
                        isLoadingTools = false,
                        error = null
                    )
                }
                .onFailure { e ->
                    LogUtils.logError(TAG, "Error loading recommended tools", e)
                    _uiState.value = _uiState.value.copy(
                        recommendedTools = emptyList(),
                        isLoadingTools = false,
                        error = "Failed to load recommended tools"
                    )
                }
        }
    }

    /**
     * Loads emotional trends related to the current emotional state
     */
    private fun loadEmotionalTrends() {
        val emotionalState = _uiState.value.emotionalState
        if (emotionalState == null) {
            LogUtils.logDebug(TAG, "Emotional state is null, skipping emotional trends")
            return
        }

        LogUtils.logDebug(TAG, "Loading emotional trends for emotion: ${emotionalState.emotionType}")
        _uiState.value = _uiState.value.copy(isLoadingTrends = true)

        viewModelScope.launch {
            getEmotionalTrendsUseCase("userId", PeriodType.WEEK, listOf(emotionalState.emotionType))
                .onSuccess { trendResponse ->
                    LogUtils.logDebug(TAG, "Successfully loaded emotional trends")
                    _uiState.value = _uiState.value.copy(
                        emotionalTrends = trendResponse.trends,
                        insights = generateInsights(emotionalState, trendResponse.trends),
                        isLoadingTrends = false,
                        error = null
                    )
                }
                .onFailure { e ->
                    LogUtils.logError(TAG, "Error loading emotional trends", e)
                    _uiState.value = _uiState.value.copy(
                        emotionalTrends = emptyList(),
                        insights = emptyList(),
                        isLoadingTrends = false,
                        error = "Failed to load emotional trends"
                    )
                }
        }
    }

    /**
     * Generates insights based on emotional state and trends
     *
     * @param emotionalState The current emotional state
     * @param trends The list of emotional trends
     * @return A list of insights
     */
    private fun generateInsights(emotionalState: EmotionalState, trends: List<EmotionalTrend>): List<String> {
        val insights = mutableListOf<String>()

        insights.add("You are currently feeling ${emotionalState.emotionType.name} with an intensity of ${emotionalState.intensity}")

        if (trends.isNotEmpty()) {
            insights.add("Your emotional patterns show a trend of...")
        } else {
            insights.add("No emotional trends available yet. Keep logging your emotions!")
        }

        insights.add("Consider using the recommended coping strategies to manage your emotions")

        return insights
    }

    /**
     * Navigates to the tool detail screen
     *
     * @param navActions The navigation actions
     * @param toolId The ID of the tool to navigate to
     */
    fun navigateToToolDetail(navActions: NavActions, toolId: String) {
        LogUtils.logDebug(TAG, "Navigating to tool detail: $toolId")
        navActions.navigateToToolDetail(toolId)
    }

    /**
     * Navigates to the tool library screen
     *
     * @param navActions The navigation actions
     */
    fun navigateToAllTools(navActions: NavActions) {
        LogUtils.logDebug(TAG, "Navigating to tool library")
        navActions.navigateToToolLibrary()
    }

    /**
     * Navigates to the emotional trends screen
     *
     * @param navActions The navigation actions
     */
    fun navigateToEmotionalTrends(navActions: NavActions) {
        LogUtils.logDebug(TAG, "Navigating to emotional trends")
        navActions.navigateToEmotionalTrends()
    }

    /**
     * Navigates back to the previous screen
     *
     * @param navActions The navigation actions
     */
    fun navigateBack(navActions: NavActions) {
        LogUtils.logDebug(TAG, "Navigating back")
        navActions.navigateBack()
    }

    /**
     * Sealed class representing the UI state for the emotional check-in result screen
     */
    sealed class EmotionalCheckinResultUiState(
        val emotionalState: EmotionalState?,
        val recommendedTools: List<Tool>,
        val emotionalTrends: List<EmotionalTrend>,
        val insights: List<String>,
        val isLoadingTools: Boolean,
        val isLoadingTrends: Boolean,
        val error: String?
    ) {
        /**
         * Creates a copy of the state with specified properties changed
         *
         * @param emotionalState The emotional state
         * @param recommendedTools The recommended tools
         * @param emotionalTrends The emotional trends
         * @param insights The insights
         * @param isLoadingTools Whether tools are loading
         * @param isLoadingTrends Whether trends are loading
         * @param error The error message
         */
        fun copy(
            emotionalState: EmotionalState? = this.emotionalState,
            recommendedTools: List<Tool> = this.recommendedTools,
            emotionalTrends: List<EmotionalTrend> = this.emotionalTrends,
            insights: List<String> = this.insights,
            isLoadingTools: Boolean = this.isLoadingTools,
            isLoadingTrends: Boolean = this.isLoadingTrends,
            error: String? = this.error
        ): EmotionalCheckinResultUiState {
            return object : EmotionalCheckinResultUiState(
                emotionalState = emotionalState,
                recommendedTools = recommendedTools,
                emotionalTrends = emotionalTrends,
                insights = insights,
                isLoadingTools = isLoadingTools,
                isLoadingTrends = isLoadingTrends,
                error = error
            ) {}
        }

        /**
         * Companion object containing factory methods for EmotionalCheckinResultUiState
         */
        companion object {
            /**
             * Creates the initial UI state
             */
            fun initial(): EmotionalCheckinResultUiState {
                return object : EmotionalCheckinResultUiState(
                    emotionalState = null,
                    recommendedTools = emptyList(),
                    emotionalTrends = emptyList(),
                    insights = emptyList(),
                    isLoadingTools = false,
                    isLoadingTrends = false,
                    error = null
                ) {}
            }
        }
    }
}