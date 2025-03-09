package com.amirawellness.ui.screens.tools

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.SavedStateHandle
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.domain.usecases.tool.GetToolCategoriesUseCase
import com.amirawellness.domain.usecases.tool.GetToolsUseCase
import com.amirawellness.domain.usecases.tool.GetFavoriteToolsUseCase
import com.amirawellness.domain.usecases.tool.ToggleToolFavoriteUseCase
import com.amirawellness.core.utils.LogUtils.logDebug
import com.amirawellness.core.utils.LogUtils.logError

private const val TAG = "ToolLibraryViewModel"
private const val SELECTED_CATEGORY_KEY = "selected_category"

@HiltViewModel
class ToolLibraryViewModel @Inject constructor(
    private val getToolCategoriesUseCase: GetToolCategoriesUseCase,
    private val getToolsUseCase: GetToolsUseCase,
    private val getFavoriteToolsUseCase: GetFavoriteToolsUseCase,
    private val toggleToolFavoriteUseCase: ToggleToolFavoriteUseCase,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow(ToolLibraryUiState.initialState())
    val uiState: StateFlow<ToolLibraryUiState> = _uiState.asStateFlow()

    init {
        // Restore selected category from savedStateHandle if available
        savedStateHandle.get<String>(SELECTED_CATEGORY_KEY)?.let { categoryId ->
            _uiState.update { it.copy(selectedCategoryId = categoryId) }
        }
        
        // Load initial data
        loadData()
    }
    
    private fun loadData() {
        _uiState.update { it.copy(isLoading = true) }
        
        viewModelScope.launch {
            try {
                // Combine the flows from all data sources
                combine(
                    getToolCategoriesUseCase(),
                    getToolsUseCase(uiState.value.selectedCategoryId),
                    getFavoriteToolsUseCase()
                ) { categories, tools, favoriteTools ->
                    // Get recent tools (could be improved with a dedicated usecase)
                    val recentTools = tools.sortedByDescending { it.usageCount }.take(5)
                    
                    // Update UI state with the loaded data
                    _uiState.update { currentState ->
                        currentState.copy(
                            categories = categories,
                            tools = tools,
                            recentTools = recentTools,
                            favoriteCount = favoriteTools.size,
                            isLoading = false,
                            error = null
                        )
                    }
                }.catch { exception ->
                    logError(TAG, "Error loading data", exception)
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = exception.message ?: "Unknown error occurred"
                    ) }
                }.collect()
            } catch (e: Exception) {
                logError(TAG, "Error in data loading", e)
                _uiState.update { it.copy(
                    isLoading = false,
                    error = e.message ?: "Unknown error occurred"
                ) }
            }
        }
    }
    
    fun onCategorySelected(categoryId: String) {
        // Save the selected category in the savedStateHandle
        savedStateHandle[SELECTED_CATEGORY_KEY] = categoryId
        
        // Update the UI state with the selected category
        _uiState.update { it.copy(selectedCategoryId = categoryId) }
        
        // Load tools for the selected category
        viewModelScope.launch {
            try {
                getToolsUseCase(categoryId).collect { tools ->
                    _uiState.update { it.copy(tools = tools) }
                }
            } catch (e: Exception) {
                logError(TAG, "Error loading tools for category: $categoryId", e)
                _uiState.update { it.copy(error = e.message ?: "Error loading tools") }
            }
        }
    }
    
    fun onToolSelected(toolId: String) {
        _uiState.update { it.copy(selectedToolId = toolId) }
        logDebug(TAG, "Tool selected: $toolId")
    }
    
    fun onFavoritesClicked() {
        _uiState.update { it.copy(navigateToFavorites = true) }
        logDebug(TAG, "Navigate to favorites")
    }
    
    fun toggleFavorite(toolId: String) {
        val tool = uiState.value.tools.find { it.id == toolId }
        tool?.let {
            val currentFavorite = it.isFavorite
            viewModelScope.launch {
                try {
                    val success = toggleToolFavoriteUseCase(toolId, !currentFavorite)
                    if (success) {
                        // The repository should handle the update in the database
                        // and emit a new flow value, but we'll update the UI state
                        // immediately for a responsive UI
                        val updatedTools = uiState.value.tools.map { tool ->
                            if (tool.id == toolId) {
                                tool.copy(isFavorite = !currentFavorite)
                            } else {
                                tool
                            }
                        }
                        _uiState.update { it.copy(tools = updatedTools) }
                    }
                } catch (e: Exception) {
                    logError(TAG, "Error toggling favorite for tool: $toolId", e)
                    _uiState.update { it.copy(error = e.message ?: "Error updating favorite") }
                }
            }
        }
    }
    
    fun refresh() {
        _uiState.update { it.copy(isRefreshing = true) }
        
        viewModelScope.launch {
            try {
                // Load data with forceRefresh=true
                combine(
                    getToolCategoriesUseCase(forceRefresh = true),
                    getToolsUseCase(uiState.value.selectedCategoryId, forceRefresh = true),
                    getFavoriteToolsUseCase() // No forceRefresh parameter for this use case
                ) { categories, tools, favoriteTools ->
                    val recentTools = tools.sortedByDescending { it.usageCount }.take(5)
                    
                    _uiState.update { currentState ->
                        currentState.copy(
                            categories = categories,
                            tools = tools,
                            recentTools = recentTools,
                            favoriteCount = favoriteTools.size,
                            isRefreshing = false,
                            error = null
                        )
                    }
                }.catch { exception ->
                    logError(TAG, "Error refreshing data", exception)
                    _uiState.update { it.copy(
                        isRefreshing = false,
                        error = exception.message ?: "Error refreshing data"
                    ) }
                }.collect()
            } catch (e: Exception) {
                logError(TAG, "Error in refresh", e)
                _uiState.update { it.copy(
                    isRefreshing = false,
                    error = e.message ?: "Error refreshing data"
                ) }
            }
        }
    }
    
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class ToolLibraryUiState(
    val categories: List<ToolCategory>,
    val tools: List<Tool>,
    val recentTools: List<Tool>,
    val favoriteCount: Int,
    val selectedCategoryId: String?,
    val selectedToolId: String?,
    val isLoading: Boolean,
    val isRefreshing: Boolean,
    val error: String?,
    val navigateToFavorites: Boolean
) {
    companion object {
        fun initialState() = ToolLibraryUiState(
            categories = emptyList(),
            tools = emptyList(),
            recentTools = emptyList(),
            favoriteCount = 0,
            selectedCategoryId = null,
            selectedToolId = null,
            isLoading = true,
            isRefreshing = false,
            error = null,
            navigateToFavorites = false
        )
    }
}