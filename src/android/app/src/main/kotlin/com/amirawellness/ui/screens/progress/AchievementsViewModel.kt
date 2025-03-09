package com.amirawellness.ui.screens.progress

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch
import com.amirawellness.domain.usecases.progress.GetAchievementsUseCase
import com.amirawellness.data.models.Achievement
import com.amirawellness.data.models.AchievementCategory
import com.amirawellness.core.utils.LogUtils.d
import com.amirawellness.core.utils.LogUtils.e
import javax.inject.Inject
import dagger.hilt.android.lifecycle.HiltViewModel

private const val TAG = "AchievementsViewModel"

/**
 * ViewModel for the Achievements screen that manages UI state and data loading
 * for displaying user achievements as part of the progress tracking and gamification
 * features in the Amira Wellness application.
 */
@HiltViewModel
class AchievementsViewModel @Inject constructor(
    private val getAchievementsUseCase: GetAchievementsUseCase
) : ViewModel() {

    // UI state for the achievements screen
    private val _uiState = MutableStateFlow<AchievementsUiState>(AchievementsUiState.Loading)
    val uiState: StateFlow<AchievementsUiState> = _uiState.asStateFlow()

    // Selected category filter
    private val _selectedCategory = MutableStateFlow<AchievementCategory?>(null)
    val selectedCategory: StateFlow<AchievementCategory?> = _selectedCategory.asStateFlow()

    init {
        loadAchievements()
    }

    /**
     * Loads achievements from the use case and updates the UI state
     */
    fun loadAchievements() {
        _uiState.value = AchievementsUiState.Loading
        viewModelScope.launch {
            getAchievementsUseCase()
                .catch { exception ->
                    e(TAG, "Error loading achievements", exception)
                    _uiState.value = AchievementsUiState.Error(exception.message ?: "Unknown error occurred")
                }
                .collect { achievements ->
                    _uiState.value = AchievementsUiState.Success(achievements)
                }
        }
    }

    /**
     * Refreshes the achievements data
     */
    fun refreshAchievements() {
        loadAchievements()
    }

    /**
     * Sets the selected category filter for achievements
     *
     * @param category The category to filter by, or null for no filter
     */
    fun setSelectedCategory(category: AchievementCategory?) {
        _selectedCategory.value = category
        d(TAG, "Category filter set to: ${category?.name ?: "All"}")
    }

    /**
     * Gets achievements filtered by the current selected category
     *
     * @return Filtered list of achievements
     */
    fun getFilteredAchievements(): List<Achievement> {
        val currentState = uiState.value
        val selectedCat = selectedCategory.value

        return when {
            currentState is AchievementsUiState.Success && selectedCat != null -> {
                currentState.achievements.filter { it.category == selectedCat }
            }
            currentState is AchievementsUiState.Success -> {
                currentState.achievements
            }
            else -> emptyList()
        }
    }

    /**
     * Gets all earned achievements
     *
     * @return List of earned achievements
     */
    fun getEarnedAchievements(): List<Achievement> {
        return when (val currentState = uiState.value) {
            is AchievementsUiState.Success -> {
                currentState.achievements.filter { it.isEarned() }
            }
            else -> emptyList()
        }
    }

    /**
     * Gets achievements that are in progress but not yet earned
     *
     * @return List of in-progress achievements
     */
    fun getInProgressAchievements(): List<Achievement> {
        return when (val currentState = uiState.value) {
            is AchievementsUiState.Success -> {
                currentState.achievements.filter { !it.isEarned() && it.progress > 0 }
            }
            else -> emptyList()
        }
    }

    /**
     * Gets achievements that have not been started yet
     *
     * @return List of upcoming achievements
     */
    fun getUpcomingAchievements(): List<Achievement> {
        return when (val currentState = uiState.value) {
            is AchievementsUiState.Success -> {
                currentState.achievements.filter { it.progress == 0.0 }
            }
            else -> emptyList()
        }
    }

    /**
     * Gets achievements grouped by category
     *
     * @return Map of achievements grouped by category
     */
    fun getAchievementsByCategory(): Map<AchievementCategory, List<Achievement>> {
        return when (val currentState = uiState.value) {
            is AchievementsUiState.Success -> {
                currentState.achievements.groupBy { it.category }
            }
            else -> emptyMap()
        }
    }
}

/**
 * Sealed class representing the different states of the Achievements UI
 */
sealed class AchievementsUiState {
    /**
     * Loading state indicating achievements are being fetched
     */
    object Loading : AchievementsUiState()

    /**
     * Success state containing the loaded achievements
     *
     * @property achievements List of loaded achievements
     */
    data class Success(val achievements: List<Achievement>) : AchievementsUiState()

    /**
     * Error state containing an error message
     *
     * @property message Error message to display
     */
    data class Error(val message: String) : AchievementsUiState()
}