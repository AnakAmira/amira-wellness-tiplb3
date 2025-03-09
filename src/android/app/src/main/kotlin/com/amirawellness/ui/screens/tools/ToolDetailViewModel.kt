package com.amirawellness.ui.screens.tools

import androidx.lifecycle.ViewModel // androidx.lifecycle:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:2.6.1
import com.amirawellness.data.models.Tool
import com.amirawellness.domain.usecases.tool.GetToolUseCase
import com.amirawellness.domain.usecases.tool.ToggleToolFavoriteUseCase
import com.amirawellness.ui.navigation.NavActions
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt.android.lifecycle:2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines.flow:1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines.flow:1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines.flow:1.6.4
import kotlinx.coroutines.flow.catch // kotlinx.coroutines.flow:1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines:1.6.4
import javax.inject.Inject // javax.inject:1

/**
 * ViewModel for the Tool Detail screen that manages UI state and business logic for displaying
 * and interacting with tool details in the Amira Wellness application.
 */
@HiltViewModel
class ToolDetailViewModel @Inject constructor(
    private val getToolUseCase: GetToolUseCase,
    private val toggleToolFavoriteUseCase: ToggleToolFavoriteUseCase,
    private val navActions: NavActions
) : ViewModel() {

    private val _uiState = MutableStateFlow(Companion.defaultState())
    val uiState: StateFlow<ToolDetailUiState> = _uiState.asStateFlow()

    /**
     * Loads a specific tool by ID from the repository.
     *
     * @param toolId The unique identifier of the tool to load
     * @param forceRefresh Whether to force a refresh from the remote data source
     */
    fun loadTool(toolId: String, forceRefresh: Boolean = false) {
        _uiState.value = _uiState.value.copy(
            isLoading = true,
            toolId = toolId,
            error = null
        )

        viewModelScope.launch {
            getToolUseCase(toolId, forceRefresh)
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "An error occurred while loading the tool"
                    )
                }
                .collect { tool ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        tool = tool,
                        error = if (tool == null) "Tool not found" else null
                    )
                }
        }
    }

    /**
     * Toggles the favorite status of the current tool.
     */
    fun toggleFavorite() {
        val tool = uiState.value.tool ?: return

        viewModelScope.launch {
            try {
                val success = toggleToolFavoriteUseCase(tool.id, !tool.isFavorite)
                if (success) {
                    // Update the UI state with the toggled favorite status
                    _uiState.value = _uiState.value.copy(
                        tool = tool.copy(isFavorite = !tool.isFavorite)
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "An error occurred while updating favorite status"
                )
            }
        }
    }

    /**
     * Initiates the tool usage session by navigating to the tool in progress screen.
     */
    fun startTool() {
        val tool = uiState.value.tool ?: return
        navActions.navigateToToolInProgress(tool.id)
    }

    /**
     * Navigates back to the previous screen.
     */
    fun navigateBack() {
        navActions.navigateBack()
    }

    /**
     * Retries loading the tool after an error.
     */
    fun retry() {
        val toolId = uiState.value.toolId ?: return
        loadTool(toolId, true)
    }

    companion object {
        /**
         * Creates the default UI state.
         *
         * @return Default UI state with no tool loaded and no error
         */
        fun defaultState() = ToolDetailUiState(
            isLoading = false,
            tool = null,
            toolId = null,
            error = null
        )
    }
}

/**
 * Data class representing the UI state for the Tool Detail screen.
 *
 * @property isLoading Indicates if a loading operation is in progress
 * @property tool The tool data to display, null if not yet loaded
 * @property toolId The ID of the tool being displayed
 * @property error Error message to display, null if no error
 */
data class ToolDetailUiState(
    val isLoading: Boolean = false,
    val tool: Tool? = null,
    val toolId: String? = null,
    val error: String? = null
)