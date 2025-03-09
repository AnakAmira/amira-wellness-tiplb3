package com.amirawellness.ui.screens.tools

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.SavedStateHandle
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers
import javax.inject.Inject
import dagger.hilt.android.lifecycle.HiltViewModel
import com.amirawellness.data.models.Tool
import com.amirawellness.domain.usecases.tool.GetFavoriteToolsUseCase
import com.amirawellness.domain.usecases.tool.ToggleToolFavoriteUseCase
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.core.utils.LogUtils.logError

private const val TAG = "FavoritesViewModel"

/**
 * ViewModel for managing the state and business logic of the Favorites screen.
 * 
 * This ViewModel handles loading favorite tools, toggling favorite status, and
 * navigation to related screens. It follows the MVVM pattern and exposes an immutable
 * UI state for the view to observe and render.
 */
@HiltViewModel
class FavoritesViewModel @Inject constructor(
    private val getFavoriteToolsUseCase: GetFavoriteToolsUseCase,
    private val toggleToolFavoriteUseCase: ToggleToolFavoriteUseCase,
    private val navActions: NavActions,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow<FavoritesUiState>(FavoritesUiState.Loading)
    val uiState: StateFlow<FavoritesUiState> = _uiState.asStateFlow()

    init {
        loadFavoriteTools()
    }

    /**
     * Loads favorite tools from the repository and updates the UI state accordingly.
     * Handles errors by updating UI state with error message.
     */
    private fun loadFavoriteTools() {
        _uiState.value = FavoritesUiState.Loading
        viewModelScope.launch {
            getFavoriteToolsUseCase()
                .catch { e ->
                    logError(TAG, "Error loading favorite tools", e)
                    _uiState.value = FavoritesUiState.Error(e.message ?: "Unknown error occurred")
                }
                .collectLatest { tools ->
                    _uiState.value = FavoritesUiState.Success(tools)
                }
        }
    }

    /**
     * Refreshes the list of favorite tools.
     */
    fun refresh() {
        viewModelScope.launch {
            loadFavoriteTools()
        }
    }

    /**
     * Handles selection of a tool, navigating to the tool detail screen.
     *
     * @param toolId The ID of the selected tool
     */
    fun onToolSelected(toolId: String) {
        navActions.navigateToToolDetail(toolId)
    }

    /**
     * Toggles the favorite status of a tool.
     *
     * @param toolId The ID of the tool to toggle
     * @param isFavorite The new favorite status to set
     */
    fun toggleFavorite(toolId: String, isFavorite: Boolean) {
        viewModelScope.launch {
            try {
                toggleToolFavoriteUseCase(toolId, isFavorite)
                // The favorites list will be automatically updated via Flow collection
            } catch (e: Exception) {
                logError(TAG, "Error toggling favorite status for tool $toolId", e)
                loadFavoriteTools() // Refresh on error to ensure UI is consistent with data
            }
        }
    }

    /**
     * Handles back button press, navigating back to the previous screen.
     */
    fun onBackPressed() {
        navActions.navigateBack()
    }

    /**
     * Handles click on the "Browse Tools" button, navigating to the tool library.
     * Used when the favorites list is empty.
     */
    fun onBrowseToolsClick() {
        navActions.navigateToToolLibrary()
    }
}

/**
 * Sealed class representing the different states of the Favorites screen UI.
 * This pattern ensures type-safe handling of all possible UI states.
 */
sealed class FavoritesUiState {
    /**
     * State representing that favorite tools are being loaded.
     * The UI should display a loading indicator during this state.
     */
    object Loading : FavoritesUiState()
    
    /**
     * State representing that favorite tools have been successfully loaded.
     * The UI should display the list of favorite tools, or an empty state if the list is empty.
     * 
     * @param favoriteTools List of favorite tool objects
     */
    data class Success(val favoriteTools: List<Tool>) : FavoritesUiState()
    
    /**
     * State representing that an error occurred while loading favorite tools.
     * The UI should display an error message with a retry option.
     * 
     * @param message The error message to display
     */
    data class Error(val message: String) : FavoritesUiState()
}