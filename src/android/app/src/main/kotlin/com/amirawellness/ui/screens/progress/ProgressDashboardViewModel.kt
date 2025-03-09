package com.amirawellness.ui.screens.progress

import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import com.amirawellness.core.utils.LogUtils // Defined in the project
import com.amirawellness.data.models.Achievement // Defined in the project
import com.amirawellness.data.models.AchievementCategory // Defined in the project
import com.amirawellness.data.models.EmotionalInsight // Defined in the project
import com.amirawellness.data.models.EmotionalTrend // Defined in the project
import com.amirawellness.data.models.PeriodType // Defined in the project
import com.amirawellness.data.models.StreakInfo // Defined in the project
import com.amirawellness.domain.usecases.emotional.GetEmotionalTrendsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetAchievementsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetProgressInsightsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetStreakInfoUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetUsageStatisticsUseCase // Defined in the project
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt:hilt-android-gradle-plugin:2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.flow.catch // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.flow.combine // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import javax.inject.Inject // javax.inject:javax.inject:1

private const val TAG = "ProgressDashboardViewModel"

/**
 * Sealed class representing the different states of the Progress Dashboard UI
 */
sealed class ProgressUiState {
    /**
     * Object representing the loading state of the Progress Dashboard
     */
    object Loading : ProgressUiState()

    /**
     * Data class representing the success state with loaded progress data
     * @property data The loaded progress data
     */
    data class Success(val data: ProgressData) : ProgressUiState()

    /**
     * Data class representing the error state with an error message
     * @property message The error message
     */
    data class Error(val message: String) : ProgressUiState()
}

/**
 * Data class containing all progress data for the dashboard
 * @property streakInfo Information about the user's streak
 * @property achievements List of user achievements
 * @property emotionalTrends List of emotional trends
 * @property insights List of emotional insights
 * @property usageStatistics Map containing usage statistics
 */
data class ProgressData(
    val streakInfo: StreakInfo,
    val achievements: List<Achievement>,
    val emotionalTrends: List<EmotionalTrend>,
    val insights: List<EmotionalInsight>,
    val usageStatistics: Map<String, Any>
)

/**
 * ViewModel for the Progress Dashboard screen that manages UI state and data loading
 * @property getStreakInfoUseCase Use case for retrieving user streak information
 * @property getAchievementsUseCase Use case for retrieving user achievements
 * @property getEmotionalTrendsUseCase Use case for retrieving emotional trend data
 * @property getProgressInsightsUseCase Use case for retrieving progress insights
 * @property getUsageStatisticsUseCase Use case for retrieving usage statistics
 */
@HiltViewModel
class ProgressDashboardViewModel @Inject constructor(
    private val getStreakInfoUseCase: GetStreakInfoUseCase,
    private val getAchievementsUseCase: GetAchievementsUseCase,
    private val getEmotionalTrendsUseCase: GetEmotionalTrendsUseCase,
    private val getProgressInsightsUseCase: GetProgressInsightsUseCase,
    private val getUsageStatisticsUseCase: GetUsageStatisticsUseCase
) : ViewModel() {

    /**
     * Mutable state flow for the UI state
     */
    private val _uiState = MutableStateFlow<ProgressUiState>(ProgressUiState.Loading)

    /**
     * Read-only state flow for the UI state
     */
    val uiState: StateFlow<ProgressUiState> = _uiState.asStateFlow()

    /**
     * Mutable state flow for the selected period type
     */
    private val _selectedPeriod = MutableStateFlow(PeriodType.WEEK)

    /**
     * Read-only state flow for the selected period type
     */
    val selectedPeriod: StateFlow<PeriodType> = _selectedPeriod.asStateFlow()

    init {
        // Call super() to initialize ViewModel
        super.onCleared()

        // Call loadProgressData() to load initial data
        loadProgressData()
    }

    /**
     * Loads all progress data from the use cases and updates the UI state
     */
    fun loadProgressData() {
        // Set _uiState.value to ProgressUiState.Loading
        _uiState.value = ProgressUiState.Loading

        // Launch a coroutine in viewModelScope
        viewModelScope.launch {
            // Combine flows from getStreakInfoUseCase, getAchievementsUseCase, getEmotionalTrendsUseCase, getProgressInsightsUseCase, and getUsageStatisticsUseCase
            combine(
                getStreakInfoUseCase(),
                getAchievementsUseCase(),
                getEmotionalTrendsUseCase("test_user", _selectedPeriod.value), // TODO: Replace "test_user" with actual user ID
                getProgressInsightsUseCase(),
                getUsageStatisticsUseCase(_selectedPeriod.value)
            ) { streakInfo, achievements, emotionalTrendsResult, progressInsights, usageStatistics ->
                // Transform the combined data into a ProgressData object
                ProgressData(
                    streakInfo = streakInfo,
                    achievements = achievements,
                    emotionalTrends = emotionalTrendsResult.getOrDefault(emptyList()), // Use getOrDefault to handle potential errors
                    insights = progressInsights.getOrDefault(emptyList()), // Use getOrDefault to handle potential errors
                    usageStatistics = usageStatistics
                )
            }
                .catch { e ->
                    // Log the error with LogUtils.logError
                    LogUtils.logError(TAG, "Error loading progress data", e)
                    // Update _uiState.value to ProgressUiState.Error with the error message
                    _uiState.value = ProgressUiState.Error(e.message ?: "Unknown error")
                }
                .collect { progressData ->
                    // Update _uiState.value to ProgressUiState.Success with the ProgressData
                    _uiState.value = ProgressUiState.Success(progressData)
                }
        }
    }

    /**
     * Refreshes all progress data
     */
    fun refreshData() {
        // Call loadProgressData() to reload all data
        loadProgressData()
    }

    /**
     * Sets the selected period type for trend analysis
     * @param periodType The selected period type
     */
    fun setPeriodType(periodType: PeriodType) {
        // Update _selectedPeriod.value to the provided periodType
        _selectedPeriod.value = periodType
        // Call loadProgressData() to reload data with the new period
        loadProgressData()
    }

    /**
     * Gets achievements filtered by category
     * @param category The category to filter by
     * @return List of achievements in the specified category
     */
    fun getFilteredAchievements(category: AchievementCategory): List<Achievement> {
        // Get the current UI state
        return when (val state = _uiState.value) {
            is ProgressUiState.Success -> {
                // If state is ProgressUiState.Success, filter achievements by the specified category
                state.data.achievements.filter { it.category == category }
            }
            else -> {
                // Otherwise, return an empty list
                emptyList()
            }
        }
    }

    /**
     * Gets all earned achievements
     * @return List of earned achievements
     */
    fun getEarnedAchievements(): List<Achievement> {
        // Get the current UI state
        return when (val state = _uiState.value) {
            is ProgressUiState.Success -> {
                // If state is ProgressUiState.Success, filter achievements where isEarned() is true
                state.data.achievements.filter { it.isEarned() }
            }
            else -> {
                // Otherwise, return an empty list
                emptyList()
            }
        }
    }

    /**
     * Gets achievements that are in progress but not yet earned
     * @return List of in-progress achievements
     */
    fun getInProgressAchievements(): List<Achievement> {
        // Get the current UI state
        return when (val state = _uiState.value) {
            is ProgressUiState.Success -> {
                // If state is ProgressUiState.Success, filter achievements where progress > 0 but not isEarned()
                state.data.achievements.filter { it.progress > 0.0 && !it.isEarned() }
            }
            else -> {
                // Otherwise, return an empty list
                emptyList()
            }
        }
    }
}