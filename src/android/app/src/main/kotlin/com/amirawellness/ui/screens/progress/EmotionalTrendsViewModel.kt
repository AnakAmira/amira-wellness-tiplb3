package com.amirawellness.ui.screens.progress

import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import com.amirawellness.domain.usecases.emotional.GetEmotionalTrendsUseCase // src/android/app/src/main/kotlin/com/amirawellness/domain/usecases/emotional/GetEmotionalTrendsUseCase.kt
import com.amirawellness.data.models.EmotionalTrend // src/android/app/src/main/kotlin/com/amirawellness/data/models/EmotionalTrend.kt
import com.amirawellness.data.models.EmotionalInsight // src/android/app/src/main/kotlin/com/amirawellness/data/models/EmotionalTrend.kt
import com.amirawellness.data.models.PeriodType // src/android/app/src/main/kotlin/com/amirawellness/data/models/EmotionalTrend.kt
import com.amirawellness.core.constants.AppConstants.EmotionType // src/android/app/src/main/kotlin/com/amirawellness/core/constants/AppConstants.kt
import com.amirawellness.core.utils.LogUtils // src/android/app/src/main/kotlin/com/amirawellness/core/utils/LogUtils.kt
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt:hilt-android-compiler:2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import kotlinx.coroutines.flow.catch // kotlinx.coroutines:kotlinx-coroutines-android:1.7.1
import javax.inject.Inject // javax.inject:javax.inject:1

private const val TAG = "EmotionalTrendsViewModel"

/**
 * ViewModel for the Emotional Trends screen that manages UI state and data loading
 */
@HiltViewModel
class EmotionalTrendsViewModel @Inject constructor(
    private val getEmotionalTrendsUseCase: GetEmotionalTrendsUseCase
) : ViewModel() {

    /**
     * Creates a new EmotionalTrendsViewModel with the required use case
     * @param getEmotionalTrendsUseCase
     */
    @Inject
    constructor(getEmotionalTrendsUseCase: GetEmotionalTrendsUseCase) : this(getEmotionalTrendsUseCase) {
        // Call super() to initialize ViewModel
        // Initialize getEmotionalTrendsUseCase property with the injected instance
        // Initialize _uiState with MutableStateFlow containing initial EmotionalTrendsUiState.Loading
        _uiState.value = EmotionalTrendsUiState.Loading
        // Initialize uiState as a read-only StateFlow from _uiState
        // Initialize _selectedPeriodType with MutableStateFlow containing PeriodType.WEEK as default
        _selectedPeriodType.value = PeriodType.WEEK
        // Initialize selectedPeriodType as a read-only StateFlow from _selectedPeriodType
        // Set userId to a temporary value (will be set properly when loadData is called)
        // Call loadData() to load initial data
        loadData("tempUserId")
    }

    private val _uiState = MutableStateFlow<EmotionalTrendsUiState>(EmotionalTrendsUiState.Loading)
    val uiState: StateFlow<EmotionalTrendsUiState> = _uiState.asStateFlow()

    private val _selectedPeriodType = MutableStateFlow(PeriodType.WEEK)
    val selectedPeriodType: StateFlow<PeriodType> = _selectedPeriodType.asStateFlow()

    private var userId: String = ""

    /**
     * Loads emotional trend data based on the selected period type
     * @param userId
     */
    fun loadData(userId: String) {
        // Store the provided userId in the class property
        this.userId = userId
        // Set _uiState.value to EmotionalTrendsUiState.Loading
        _uiState.value = EmotionalTrendsUiState.Loading
        // Launch a coroutine in viewModelScope
        viewModelScope.launch {
            // Get the current selected period type
            val periodType = selectedPeriodType.value
            // Call getEmotionalTrendsUseCase with userId and selectedPeriodType
            getEmotionalTrendsUseCase(userId, periodType)
                // Process the result from the use case
                .fold(
                    onSuccess = { result ->
                        // If successful, update _uiState.value to EmotionalTrendsUiState.Success with the trend data
                        _uiState.value = EmotionalTrendsUiState.Success(result.trends, result.insights)
                    },
                    onFailure = { e ->
                        // If failed, update _uiState.value to EmotionalTrendsUiState.Error with the error message
                        _uiState.value = EmotionalTrendsUiState.Error(e.message ?: "Unknown error")
                        // Log any errors that occur during data loading
                        LogUtils.logError(TAG, "Error loading emotional trend data", e)
                    }
                )
        }
    }

    /**
     * Refreshes the emotional trend data with the current settings
     */
    fun refreshData() {
        // Call loadData() with the current userId to reload data
        loadData(userId)
    }

    /**
     * Sets the selected period type and reloads data
     * @param periodType
     */
    fun setPeriodType(periodType: PeriodType) {
        // Update _selectedPeriodType.value to the provided periodType
        _selectedPeriodType.value = periodType
        // Call loadData() with the current userId to reload data with the new period type
        loadData(userId)
    }

    /**
     * Calculates the most frequent emotions from the trend data
     */
    fun getMostFrequentEmotions(): List<Pair<EmotionType, Int>> {
        // Get the current UI state
        return when (val state = _uiState.value) {
            is EmotionalTrendsUiState.Success -> {
                // If state is EmotionalTrendsUiState.Success, process the trends data
                state.trends
                    // Group trends by emotion type
                    .groupBy { it.emotionType }
                    // Count occurrences of each emotion type
                    .mapValues { (_, trends) -> trends.sumOf { it.occurrenceCount } }
                    // Sort emotions by occurrence count in descending order
                    .entries.sortedByDescending { it.value }
                    // Take the top 5 most frequent emotions
                    .take(5)
                    // Return the list of emotion type and count pairs
                    .map { Pair(it.key, it.value) }
            }
            else -> {
                // If state is not Success, return an empty list
                emptyList()
            }
        }
    }

    /**
     * Gets insights related to a specific emotion type
     * @param emotionType
     */
    fun getInsightsForEmotion(emotionType: EmotionType): List<EmotionalInsight> {
        // Get the current UI state
        return when (val state = _uiState.value) {
            is EmotionalTrendsUiState.Success -> {
                // If state is EmotionalTrendsUiState.Success, filter insights related to the specified emotion
                state.insights
                    .filter { emotionType in it.relatedEmotions }
                    // Sort insights by confidence level in descending order
                    .sortedByDescending { it.confidence }
                // Return the filtered and sorted insights
            }
            else -> {
                // If state is not Success, return an empty list
                emptyList()
            }
        }
    }

    /**
     * Gets the trend data for a specific emotion type
     * @param emotionType
     */
    fun getTrendForEmotion(emotionType: EmotionType): EmotionalTrend? {
        // Get the current UI state
        return when (val state = _uiState.value) {
            is EmotionalTrendsUiState.Success -> {
                // If state is EmotionalTrendsUiState.Success, find the trend with the specified emotion type
                state.trends.find { it.emotionType == emotionType }
                // Return the found trend or null if not found
            }
            else -> {
                // If state is not Success, return null
                null
            }
        }
    }

    /**
     * Sealed class representing the different states of the Emotional Trends UI
     */
    sealed class EmotionalTrendsUiState {
        /**
         * Default constructor for sealed class
         */
        object Loading : EmotionalTrendsUiState() {
            /**
             * Default constructor for object
             */
        }

        /**
         * Data class representing the success state with loaded emotional trend data
         * @param trends
         * @param insights
         */
        data class Success(val trends: List<EmotionalTrend>, val insights: List<EmotionalInsight>) : EmotionalTrendsUiState() {
            /**
             * Creates a Success state with the provided trend data
             * @param trends
             * @param insights
             */
            init {
                // Initialize trends property with the provided trends list
                // Initialize insights property with the provided insights list
            }
        }

        /**
         * Data class representing the error state with an error message
         * @param message
         */
        data class Error(val message: String) : EmotionalTrendsUiState() {
            /**
             * Creates an Error state with the provided error message
             * @param message
             */
            init {
                // Initialize message property with the provided error message
            }
        }
    }
}