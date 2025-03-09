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
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.domain.usecases.tool.GetToolsUseCase
import com.amirawellness.domain.usecases.tool.ToggleToolFavoriteUseCase
import com.amirawellness.core.utils.LogUtils.d as logDebug
import com.amirawellness.core.utils.LogUtils.e as logError

private const val TAG = "ToolCategoryViewModel"
private const val CATEGORY_ID_KEY = "category_id"

/**
 * ViewModel for the Tool Category screen that manages UI state and business logic
 */
@HiltViewModel
class ToolCategoryViewModel @Inject constructor(
    private val getToolsUseCase: GetToolsUseCase,
    private val toggleToolFavoriteUseCase: ToggleToolFavoriteUseCase,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        Companion.initialState(
            categoryId = savedStateHandle.get<String>(CATEGORY_ID_KEY) ?: "",
            categoryName = savedStateHandle.get<String>("category_name") ?: ""
        )
    )
    val uiState: StateFlow<ToolCategoryUiState> = _uiState.asStateFlow()

    private val categoryId: String = savedStateHandle.get<String>(CATEGORY_ID_KEY) ?: ""

    init {
        loadTools(false)
    }

    private fun loadTools(forceRefresh: Boolean = false) {
        _uiState.update { it.copy(isLoading = true) }
        
        viewModelScope.launch {
            try {
                getToolsUseCase(categoryId = categoryId, forceRefresh = forceRefresh)
                    .catch { error ->
                        logError(TAG, "Error loading tools: ${error.message}", error)
                        _uiState.update { 
                            it.copy(isLoading = false, error = error.message) 
                        }
                    }
                    .collect { tools ->
                        _uiState.update { currentState -> 
                            currentState.copy(
                                tools = tools,
                                filteredTools = filterTools(tools, currentState.searchQuery),
                                isLoading = false,
                                isRefreshing = false,
                                error = null
                            ) 
                        }
                        logDebug(TAG, "Loaded ${tools.size} tools for category $categoryId")
                    }
            } catch (e: Exception) {
                logError(TAG, "Error loading tools: ${e.message}", e)
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        isRefreshing = false, 
                        error = e.message ?: "Unknown error occurred"
                    ) 
                }
            }
        }
    }

    fun onToolSelected(toolId: String) {
        _uiState.update { it.copy(selectedToolId = toolId) }
        logDebug(TAG, "Tool selected: $toolId")
    }

    fun toggleFavorite(toolId: String) {
        val currentTools = _uiState.value.tools
        val tool = currentTools.find { it.id == toolId }
        
        tool?.let {
            val currentFavoriteStatus = it.isFavorite
            
            viewModelScope.launch {
                try {
                    toggleToolFavoriteUseCase(toolId, !currentFavoriteStatus)
                    
                    // Update UI state with the new favorite status
                    val updatedTools = currentTools.map { currentTool ->
                        if (currentTool.id == toolId) {
                            currentTool.copy(isFavorite = !currentFavoriteStatus)
                        } else {
                            currentTool
                        }
                    }
                    
                    _uiState.update { currentState -> 
                        currentState.copy(
                            tools = updatedTools,
                            filteredTools = filterTools(updatedTools, currentState.searchQuery)
                        ) 
                    }
                    
                    logDebug(TAG, "Toggled favorite for tool $toolId to ${!currentFavoriteStatus}")
                } catch (e: Exception) {
                    logError(TAG, "Error toggling favorite: ${e.message}", e)
                    _uiState.update { it.copy(error = e.message) }
                }
            }
        }
    }

    private fun filterTools(tools: List<Tool>, query: String): List<Tool> {
        return if (query.isEmpty()) {
            tools
        } else {
            tools.filter { 
                it.name.contains(query, ignoreCase = true) || 
                it.description.contains(query, ignoreCase = true) 
            }
        }
    }

    fun refresh() {
        _uiState.update { it.copy(isRefreshing = true) }
        viewModelScope.launch {
            try {
                loadTools(forceRefresh = true)
            } catch (e: Exception) {
                logError(TAG, "Error refreshing tools: ${e.message}", e)
                _uiState.update { 
                    it.copy(
                        isRefreshing = false,
                        error = e.message ?: "Unknown error occurred during refresh"
                    ) 
                }
            }
        }
    }

    fun onBackPressed() {
        _uiState.update { it.copy(navigateBack = true) }
        logDebug(TAG, "Back navigation requested from category $categoryId")
    }

    fun filterTools(query: String) {
        val filteredList = filterTools(_uiState.value.tools, query)
        _uiState.update { it.copy(searchQuery = query, filteredTools = filteredList) }
        logDebug(TAG, "Filtered tools by query: '$query', found ${filteredList.size} results")
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
    
    companion object {
        /**
         * Creates the initial UI state with default values
         */
        fun initialState(categoryId: String, categoryName: String): ToolCategoryUiState {
            return ToolCategoryUiState(
                categoryId = categoryId,
                categoryName = categoryName,
                tools = emptyList(),
                filteredTools = emptyList(),
                searchQuery = "",
                selectedToolId = null,
                isLoading = true,
                isRefreshing = false,
                error = null,
                navigateBack = false
            )
        }
    }
}

/**
 * Data class representing the UI state for the Tool Category screen
 */
data class ToolCategoryUiState(
    val categoryId: String,
    val categoryName: String,
    val tools: List<Tool>,
    val filteredTools: List<Tool>,
    val searchQuery: String,
    val selectedToolId: String?,
    val isLoading: Boolean,
    val isRefreshing: Boolean,
    val error: String?,
    val navigateBack: Boolean
)