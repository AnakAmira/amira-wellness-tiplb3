package com.amirawellness.ui.screens.emotions

import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import com.amirawellness.core.constants.AppConstants.EmotionContext // Defined internally
import com.amirawellness.core.constants.AppConstants.EmotionType // Defined internally
import com.amirawellness.core.extensions.Resource // Defined internally
import com.amirawellness.core.extensions.withLoading // Defined internally
import com.amirawellness.core.utils.LogUtils // Defined internally
import com.amirawellness.data.models.EmotionalState // Defined internally
import com.amirawellness.data.models.Tool // Defined internally
import com.amirawellness.domain.usecases.emotional.RecordEmotionalStateUseCase // Defined internally
import com.amirawellness.domain.usecases.tool.GetRecommendedToolsUseCase // Defined internally
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt:hilt-android-compiler:2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.update // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import javax.inject.Inject // javax.inject:javax.inject:1

private const val TAG = "EmotionalCheckinViewModel"

/**
 * Data class representing the UI state for the emotional check-in screen
 */
data class EmotionalCheckinState(
    val userId: String = "",
    val selectedEmotionType: EmotionType = EmotionType.JOY,
    val intensity: Int = 5,
    val context: EmotionContext = EmotionContext.STANDALONE,
    val notes: String = "",
    val relatedJournalId: String? = null,
    val relatedToolId: String? = null,
    val isLoading: Boolean = false,
    val recordedState: EmotionalState? = null,
    val recommendedTools: List<Tool> = emptyList(),
    val error: Throwable? = null
) {
    /**
     * Creates a copy of the state with optionally modified properties
     */
    fun copy(
        userId: String? = this.userId,
        selectedEmotionType: EmotionType? = this.selectedEmotionType,
        intensity: Int? = this.intensity,
        context: EmotionContext? = this.context,
        notes: String? = this.notes,
        relatedJournalId: String? = this.relatedJournalId,
        relatedToolId: String? = this.relatedToolId,
        isLoading: Boolean? = this.isLoading,
        recordedState: EmotionalState? = this.recordedState,
        recommendedTools: List<Tool>? = this.recommendedTools,
        error: Throwable? = this.error
    ): EmotionalCheckinState {
        return EmotionalCheckinState(
            userId = userId ?: this.userId,
            selectedEmotionType = selectedEmotionType ?: this.selectedEmotionType,
            intensity = intensity ?: this.intensity,
            context = context ?: this.context,
            notes = notes ?: this.notes,
            relatedJournalId = relatedJournalId ?: this.relatedJournalId,
            relatedToolId = relatedToolId ?: this.relatedToolId,
            isLoading = isLoading ?: this.isLoading,
            recordedState = recordedState ?: this.recordedState,
            recommendedTools = recommendedTools ?: this.recommendedTools,
            error = error ?: this.error
        )
    }

    /**
     * Companion object containing factory methods and constants for EmotionalCheckinState
     */
    companion object {
        /**
         * Creates a default EmotionalCheckinState instance
         */
        fun createDefault(): EmotionalCheckinState {
            return EmotionalCheckinState(
                userId = "",
                selectedEmotionType = EmotionType.JOY,
                intensity = 5,
                context = EmotionContext.STANDALONE,
                notes = "",
                relatedJournalId = null,
                relatedToolId = null,
                isLoading = false,
                recordedState = null,
                recommendedTools = emptyList(),
                error = null
            )
        }
    }
}

/**
 * ViewModel for the emotional check-in screen that manages UI state and business logic
 */
@HiltViewModel
class EmotionalCheckinViewModel @Inject constructor(
    private val recordEmotionalStateUseCase: RecordEmotionalStateUseCase,
    private val getRecommendedToolsUseCase: GetRecommendedToolsUseCase
) : ViewModel() {

    /**
     * Creates a new EmotionalCheckinViewModel with the required dependencies
     */
    init {
        LogUtils.d(TAG, "EmotionalCheckinViewModel initialized")
    }

    /**
     * Mutable state flow to hold the UI state
     */
    private val _uiState = MutableStateFlow(EmotionalCheckinState.createDefault())

    /**
     * Publicly exposed read-only state flow for the UI
     */
    val uiState: StateFlow<EmotionalCheckinState> = _uiState.asStateFlow()

    /**
     * Initializes the emotional check-in with the specified context
     */
    fun initializeCheckin(
        userId: String,
        context: EmotionContext,
        relatedJournalId: String? = null,
        relatedToolId: String? = null
    ) {
        LogUtils.d(TAG, "Initializing check-in with userId=$userId, context=$context, relatedJournalId=$relatedJournalId, relatedToolId=$relatedToolId")
        _uiState.update {
            it.copy(
                userId = userId,
                context = context,
                relatedJournalId = relatedJournalId,
                relatedToolId = relatedToolId,
                selectedEmotionType = EmotionType.JOY, // Set initial emotion type
                intensity = 5, // Set initial intensity
                notes = "" // Set empty notes
            )
        }
    }

    /**
     * Updates the selected emotion type in the UI state
     */
    fun updateEmotionType(emotionType: EmotionType) {
        LogUtils.d(TAG, "Updating emotion type to $emotionType")
        _uiState.update {
            it.copy(selectedEmotionType = emotionType)
        }
    }

    /**
     * Updates the emotion intensity in the UI state
     */
    fun updateIntensity(intensity: Int) {
        LogUtils.d(TAG, "Updating intensity to $intensity")
        if (validateIntensity(intensity)) {
            _uiState.update {
                it.copy(intensity = intensity)
            }
        } else {
            LogUtils.e(TAG, "Invalid intensity value: $intensity")
        }
    }

    /**
     * Updates the notes in the UI state
     */
    fun updateNotes(notes: String) {
        LogUtils.d(TAG, "Updating notes to $notes")
        _uiState.update {
            it.copy(notes = notes)
        }
    }

    /**
     * Submits the emotional check-in and gets recommendations
     */
    fun submitCheckin() {
        LogUtils.d(TAG, "Submitting check-in")
        val userId = _uiState.value.userId
        val emotionType = _uiState.value.selectedEmotionType
        val intensity = _uiState.value.intensity
        val context = _uiState.value.context.toString()
        val notes = _uiState.value.notes
        val relatedJournalId = _uiState.value.relatedJournalId
        val relatedToolId = _uiState.value.relatedToolId

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            recordEmotionalStateUseCase(
                userId = userId,
                emotionType = emotionType,
                intensity = intensity,
                context = context,
                notes = notes,
                relatedJournalId = relatedJournalId,
                relatedToolId = relatedToolId
            ).onSuccess { recordedEmotionalState ->
                getRecommendedToolsUseCase(recordedEmotionalState).onSuccess { tools ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            recordedState = recordedEmotionalState,
                            recommendedTools = tools,
                            error = null
                        )
                    }
                }.onFailure { error ->
                    LogUtils.e(TAG, "Error getting recommended tools", error)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error
                        )
                    }
                }
            }.onFailure { error ->
                LogUtils.e(TAG, "Error recording emotional state", error)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = error
                    )
                }
            }
        }
    }

    /**
     * Resets the UI state to initial values
     */
    fun resetState() {
        LogUtils.d(TAG, "Resetting state")
        _uiState.update {
            EmotionalCheckinState.createDefault()
        }
    }

    /**
     * Validates that the intensity value is within the allowed range
     */
    private fun validateIntensity(intensity: Int): Boolean {
        return intensity in 1..10
    }
}