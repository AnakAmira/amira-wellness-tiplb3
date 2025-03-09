# src/android/app/src/main/kotlin/com/amirawellness/ui/screens/home/HomeViewModel.kt
```kotlin
package com.amirawellness.ui.screens.home

import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6+
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6+
import com.amirawellness.core.utils.LogUtils // Importing LogUtils for logging
import com.amirawellness.data.models.EmotionalState // Importing EmotionalState data class
import com.amirawellness.data.models.Journal // Importing Journal data class
import com.amirawellness.data.models.StreakInfo // Importing StreakInfo data class
import com.amirawellness.data.models.Tool // Importing Tool data class
import com.amirawellness.data.models.User // Importing User data class
import com.amirawellness.data.repositories.EmotionalStateRepository // Importing EmotionalStateRepository
import com.amirawellness.data.repositories.JournalRepository // Importing JournalRepository
import com.amirawellness.data.repositories.UserRepository // Importing UserRepository
import com.amirawellness.domain.usecases.progress.GetStreakInfoUseCase // Importing GetStreakInfoUseCase
import com.amirawellness.domain.usecases.tool.GetRecommendedToolsUseCase // Importing GetRecommendedToolsUseCase
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt:hilt-android-gradle-plugin:2.44+
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines:1.7+
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines:1.7+
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:1.7+
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:1.7+
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:1.7+
import kotlinx.coroutines.flow.catch // kotlinx.coroutines:1.7+
import kotlinx.coroutines.flow.combine // kotlinx.coroutines:1.7+
import kotlinx.coroutines.launch // kotlinx.coroutines:1.7+
import javax.inject.Inject // javax.inject:1
import kotlin.coroutines.CoroutineContext

private const val TAG = "HomeViewModel" // Tag for logging
private const val RECENT_JOURNALS_LIMIT = 3 // Limit for recent journals
private const val RECENT_EMOTIONAL_STATES_LIMIT = 5 // Limit for recent emotional states
private const val RECOMMENDED_TOOLS_LIMIT = 2 // Limit for recommended tools

/**
 * Data class representing the UI state for the home screen
 */
data class HomeUiState(
    val user: User? = null, // Current user
    val recentJournals: List<Journal> = emptyList(), // List of recent journals
    val lastEmotionalState: EmotionalState? = null, // Last emotional state
    val recommendedTools: List<Tool> = emptyList(), // List of recommended tools
    val streakInfo: StreakInfo? = null, // Streak information
    val isLoading: Boolean = false, // Loading state
    val error: String? = null // Error message
) {
    /**
     * Creates a copy of the HomeUiState with optional property changes
     */
    fun copy(
        user: User? = this.user,
        recentJournals: List<Journal>? = this.recentJournals,
        lastEmotionalState: EmotionalState? = this.lastEmotionalState,
        recommendedTools: List<Tool>? = this.recommendedTools,
        streakInfo: StreakInfo? = this.streakInfo,
        isLoading: Boolean? = this.isLoading,
        error: String? = this.error
    ): HomeUiState {
        return HomeUiState(
            user = user ?: this.user,
            recentJournals = recentJournals ?: this.recentJournals,
            lastEmotionalState = lastEmotionalState ?: this.lastEmotionalState,
            recommendedTools = recommendedTools ?: this.recommendedTools,
            streakInfo = streakInfo ?: this.streakInfo,
            isLoading = isLoading ?: this.isLoading,
            error = error ?: this.error
        )
    }
}

/**
 * ViewModel for the home screen that manages UI state and data loading
 */
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val userRepository: UserRepository, // Repository for user-related operations
    private val journalRepository: JournalRepository, // Repository for journal-related operations
    private val emotionalStateRepository: EmotionalStateRepository, // Repository for emotional state operations
    private val getRecommendedToolsUseCase: GetRecommendedToolsUseCase, // Use case for retrieving tool recommendations
    private val getStreakInfoUseCase: GetStreakInfoUseCase // Use case for retrieving streak information
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState()) // Mutable state flow for UI state
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow() // Read-only state flow for UI

    init {
        loadHomeData() // Load initial data
    }

    /**
     * Loads all data needed for the home screen
     */
    fun loadHomeData() {
        LogUtils.logDebug(TAG, "Loading home data")
        updateUiState(uiState.value.copy(isLoading = true, error = null)) // Set loading state

        viewModelScope.launch {
            combine(
                loadCurrentUser(),
                loadRecentJournals(uiState.value.user?.id.toString()),
                loadLastEmotionalState(uiState.value.user?.id.toString()),
                loadStreakInfo()
            ) { user, recentJournals, lastEmotionalState, streakInfo ->
                LogUtils.logDebug(TAG, "Combining data for home screen")
                val recommendedTools = loadRecommendedTools(lastEmotionalState)
                HomeUiState(
                    user = user,
                    recentJournals = recentJournals,
                    lastEmotionalState = lastEmotionalState,
                    recommendedTools = recommendedTools,
                    streakInfo = streakInfo,
                    isLoading = false,
                    error = null
                )
            }
                .catch { e ->
                    LogUtils.logError(TAG, "Error loading home data", e)
                    updateUiState(uiState.value.copy(isLoading = false, error = e.message))
                }
                .collect { newState ->
                    LogUtils.logDebug(TAG, "Updating UI state with new data")
                    updateUiState(newState)
                }
        }
    }

    /**
     * Loads the current authenticated user
     */
    private suspend fun loadCurrentUser(): Flow<User?> = userRepository.getCurrentUser()
        .catch { e ->
            LogUtils.logError(TAG, "Error loading current user", e)
        }

    /**
     * Loads the most recent journal entries
     */
    private suspend fun loadRecentJournals(userId: String): List<Journal> {
        return try {
            journalRepository.getRecentJournals(userId, RECENT_JOURNALS_LIMIT).first()
        } catch (e: Exception) {
            LogUtils.logError(TAG, "Error loading recent journals", e)
            emptyList()
        }
    }

    /**
     * Loads the most recent emotional state
     */
    private suspend fun loadLastEmotionalState(userId: String): EmotionalState? {
        return try {
            emotionalStateRepository.getRecentEmotionalStates(userId, RECENT_EMOTIONAL_STATES_LIMIT).first().firstOrNull()
        } catch (e: Exception) {
            LogUtils.logError(TAG, "Error loading last emotional state", e)
            null
        }
    }

    /**
     * Loads recommended tools based on the most recent emotional state
     */
    private suspend fun loadRecommendedTools(emotionalState: EmotionalState?): List<Tool> {
        return try {
            if (emotionalState != null) {
                getRecommendedToolsUseCase(emotionalState).getOrNull() ?: emptyList()
            } else {
                emptyList()
            }
        } catch (e: Exception) {
            LogUtils.logError(TAG, "Error loading recommended tools", e)
            emptyList()
        }
    }

    /**
     * Loads the user's streak information
     */
    private suspend fun loadStreakInfo(): Flow<StreakInfo?> = getStreakInfoUseCase()
        .catch { e ->
            LogUtils.logError(TAG, "Error loading streak info", e)
        }

    /**
     * Refreshes all home screen data
     */
    fun refreshData() {
        LogUtils.logDebug(TAG, "Refreshing home data")
        loadHomeData()
    }

    /**
     * Updates the UI state with new values
     */
    private fun updateUiState(newState: HomeUiState) {
        _uiState.value = newState
    }
}