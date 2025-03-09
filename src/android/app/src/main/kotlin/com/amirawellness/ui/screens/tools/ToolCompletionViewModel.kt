package com.amirawellness.ui.screens.tools

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.models.Tool
import com.amirawellness.domain.usecases.emotional.RecordEmotionalStateUseCase
import com.amirawellness.domain.usecases.tool.GetRecommendedToolsUseCase
import com.amirawellness.domain.usecases.tool.GetToolUseCase
import com.amirawellness.domain.usecases.tool.TrackToolUsageUseCase
import com.amirawellness.ui.navigation.NavActions
import dagger.hilt.android.lifecycle.HiltViewModel // Hilt version: 2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines version: 1.6.4
import javax.inject.Inject // javax.inject version: 1

private const val TAG = "ToolCompletionViewModel"
private const val TOOL_ID_KEY = "toolId"

/**
 * Data class representing the UI state for the Tool Completion screen
 */
data class ToolCompletionUiState(
    val isLoading: Boolean = true,
    val completedTool: Tool? = null,
    val recommendedTools: List<Tool> = emptyList(),
    val showEmotionalInputForm: Boolean = false,
    val emotionalStateSaved: Boolean = false,
    val error: String? = null
)

/**
 * ViewModel for the Tool Completion screen that manages state and business logic
 */
@HiltViewModel
class ToolCompletionViewModel @Inject constructor(
    private val getToolUseCase: GetToolUseCase,
    private val getRecommendedToolsUseCase: GetRecommendedToolsUseCase,
    private val recordEmotionalStateUseCase: RecordEmotionalStateUseCase,
    private val trackToolUsageUseCase: TrackToolUsageUseCase,
    private val navActions: NavActions,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    // Initialize all use case properties with provided parameters

    // Initialize navActions property with provided parameter
    // Extract toolId from savedStateHandle using TOOL_ID_KEY
    private val toolId: String = checkNotNull(savedStateHandle[TOOL_ID_KEY])

    // Initialize _uiState with default values (loading=true, completedTool=null, recommendedTools=emptyList(), showEmotionalInputForm=false, emotionalStateSaved=false, error=null)
    private val _uiState = MutableStateFlow(ToolCompletionUiState())

    // Initialize uiState as a read-only view of _uiState
    val uiState: StateFlow<ToolCompletionUiState> = _uiState.asStateFlow()

    // Initialize toolDuration to 0
    private var toolDuration: Int = 0

    /**
     * Loads the completed tool and recommended tools based on the tool ID
     */
    fun loadTool(durationSeconds: Int) {
        // Set toolDuration to the provided durationSeconds
        toolDuration = durationSeconds

        // Update UI state to show loading
        updateUiState(isLoading = true, completedTool = null, recommendedTools = emptyList(), showEmotionalInputForm = false, emotionalStateSaved = false, error = null)

        // Launch a coroutine in viewModelScope
        viewModelScope.launch {
            // Track tool usage using trackToolUsageUseCase with toolId and durationSeconds
            trackToolUsageUseCase(toolId, durationSeconds)

            // Get the tool using getToolUseCase with toolId
            getToolUseCase(toolId).collect { tool ->
                if (tool == null) {
                    // If tool is null, update UI state with error message
                    updateUiState(isLoading = false, completedTool = null, recommendedTools = emptyList(), showEmotionalInputForm = false, emotionalStateSaved = false, error = "Tool not found")
                } else {
                    // If tool is not null, get recommended tools based on the tool's target emotions
                    val recommendedTools = getRecommendedTools(tool)

                    // Update UI state with loaded tool and recommendations
                    updateUiState(isLoading = false, completedTool = tool, recommendedTools = recommendedTools, showEmotionalInputForm = false, emotionalStateSaved = false, error = null)
                }
            }
        }
    }

    /**
     * Navigates to the emotional check-in screen
     */
    fun navigateToEmotionalCheckin() {
        // Call navActions.navigateToEmotionalCheckin with source parameter set to 'tool_completion'
        navActions.navigateToEmotionalCheckin(source = "tool_completion")
    }

    /**
     * Navigates to the tool detail screen for a specific tool
     */
    fun navigateToToolDetail(toolId: String) {
        // Call navActions.navigateToToolDetail with the provided toolId
        navActions.navigateToToolDetail(toolId = toolId)
    }

    /**
     * Navigates back to the home screen
     */
    fun navigateToHome() {
        // Call navActions.navigateToHome
        navActions.navigateToHome()
    }

    /**
     * Records the user's emotional state after completing the tool
     */
    fun recordEmotionalState(emotionType: EmotionType, intensity: Int, notes: String?) {
        // Launch a coroutine in viewModelScope
        viewModelScope.launch {
            // Get the current user ID (implementation detail)
            val userId = "testUserId" // Replace with actual user ID retrieval

            // Call recordEmotionalStateUseCase with userId, emotionType, intensity, EmotionContext.TOOL_USAGE, notes, null, toolId
            recordEmotionalStateUseCase(
                userId = userId,
                emotionType = emotionType,
                intensity = intensity,
                context = EmotionContext.TOOL_USAGE.name,
                notes = notes,
                relatedJournalId = null,
                relatedToolId = toolId
            ).onSuccess {
                // If successful, update UI state to show emotional state saved and hide the form
                updateUiState(isLoading = false, completedTool = _uiState.value.completedTool, recommendedTools = _uiState.value.recommendedTools, showEmotionalInputForm = false, emotionalStateSaved = true, error = null)
            }.onFailure { e ->
                // If unsuccessful, update UI state with error message
                LogUtils.logError(TAG, "Error recording emotional state", e)
                updateUiState(isLoading = false, completedTool = _uiState.value.completedTool, recommendedTools = _uiState.value.recommendedTools, showEmotionalInputForm = true, emotionalStateSaved = false, error = "Failed to record emotional state")
            }
        }
    }

    /**
     * Toggles the visibility of the emotional input form
     */
    fun toggleEmotionalInputForm() {
        // Update UI state to toggle showEmotionalInputForm value
        updateUiState(isLoading = false, completedTool = _uiState.value.completedTool, recommendedTools = _uiState.value.recommendedTools, showEmotionalInputForm = !_uiState.value.showEmotionalInputForm, emotionalStateSaved = false, error = null)
    }

    /**
     * Gets recommended tools based on the completed tool
     */
    private suspend fun getRecommendedTools(tool: Tool): List<Tool> {
        // If tool has target emotions, get the first target emotion
        val emotionType = tool.targetEmotions.firstOrNull() ?: return emptyList()

        return try {
            // Call getRecommendedToolsUseCase with the emotion type and a default intensity
            getRecommendedToolsUseCase(emotionType.name, 5).getOrThrow().filter { it.id != tool.id }
        } catch (e: Exception) {
            // Handle any exceptions by logging the error and returning an empty list
            LogUtils.logError(TAG, "Error getting recommended tools", e)
            emptyList()
        }
    }

    /**
     * Updates the UI state with new values
     */
    private fun updateUiState(
        isLoading: Boolean = false,
        completedTool: Tool? = null,
        recommendedTools: List<Tool> = emptyList(),
        showEmotionalInputForm: Boolean = false,
        emotionalStateSaved: Boolean = false,
        error: String? = null
    ) {
        // Create a new ToolCompletionUiState with the provided parameters
        val newState = ToolCompletionUiState(
            isLoading = isLoading,
            completedTool = completedTool,
            recommendedTools = recommendedTools,
            showEmotionalInputForm = showEmotionalInputForm,
            emotionalStateSaved = emotionalStateSaved,
            error = error
        )

        // Assign the new state to _uiState
        _uiState.value = newState
    }

    /**
     * Companion object for ToolCompletionViewModel containing factory methods
     */
    companion object {
        /**
         * Creates the default UI state for the Tool Completion screen
         */
        fun createDefaultState(): ToolCompletionUiState {
            // Return a new ToolCompletionUiState with isLoading=true, completedTool=null, recommendedTools=emptyList(), showEmotionalInputForm=false, emotionalStateSaved=false, error=null
            return ToolCompletionUiState(
                isLoading = true,
                completedTool = null,
                recommendedTools = emptyList(),
                showEmotionalInputForm = false,
                emotionalStateSaved = false,
                error = null
            )
        }
    }
}