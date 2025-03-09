# src/android/app/src/main/kotlin/com/amirawellness/ui/screens/journal/JournalListViewModel.kt
```kotlin
package com.amirawellness.ui.screens.journal

import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.0
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.0
import com.amirawellness.data.models.Journal // Journal data model
import com.amirawellness.domain.usecases.journal.GetJournalsUseCase // Use case for retrieving journals
import com.amirawellness.domain.usecases.journal.DeleteJournalUseCase // Use case for deleting journals
import com.amirawellness.data.repositories.UserRepository // Repository for user data
import com.amirawellness.core.utils.LogUtils // Logging utility
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.update // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.collectLatest // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import dagger.hilt.android.lifecycle.HiltViewModel // Hilt for ViewModel injection version: 2.44
import javax.inject.Inject // version: 1

private const val TAG = "JournalListViewModel"

/**
 * Data class representing the UI state for the journal list screen.
 * This class holds all the necessary data to render the journal list UI,
 * including loading state, journal entries, error messages, and search query.
 */
data class JournalListUiState(
    val isLoading: Boolean = true,
    val journals: List<Journal> = emptyList(),
    val error: String? = null,
    val message: String? = null,
    val isRefreshing: Boolean = false,
    val showFavoritesOnly: Boolean = false,
    val searchQuery: String = ""
)

/**
 * ViewModel for managing the journal list screen state and operations.
 * This class is responsible for fetching journal entries, deleting journals,
 * filtering journals based on search query, and handling UI state updates.
 */
@HiltViewModel
class JournalListViewModel @Inject constructor(
    private val getJournalsUseCase: GetJournalsUseCase,
    private val deleteJournalUseCase: DeleteJournalUseCase,
    private val userRepository: UserRepository
) : ViewModel() {

    // Mutable state flow to hold the UI state
    private val _uiState = MutableStateFlow(JournalListUiState())

    // Public read-only state flow to expose the UI state
    val uiState: StateFlow<JournalListUiState> = _uiState.asStateFlow()

    // Private variable to store the current user ID
    private var currentUserId: String = ""

    // Private variable to store the search query
    private var searchQuery: String = ""

    // Private variable to store the flag for showing only favorite journals
    private var showFavoritesOnlyFlag: Boolean = false

    // Private variable to store the refreshing state
    private var isRefreshing: Boolean = false

    init {
        // Launch a coroutine to observe the current user
        viewModelScope.launch {
            // Collect the latest user from the userRepository
            userRepository.getCurrentUser().collectLatest { user ->
                // Update the current user ID and load journals
                currentUserId = user?.id?.toString() ?: ""
                loadJournals()
            }
        }
    }

    /**
     * Loads journal entries for the current user.
     * This function fetches journal entries from the repository and updates the UI state.
     */
    private fun loadJournals() {
        // Check if the current user ID is empty
        if (currentUserId.isEmpty()) return

        // Update the UI state to loading
        _uiState.update { it.copy(isLoading = true, error = null) }

        // Launch a coroutine in the viewModelScope
        viewModelScope.launch {
            try {
                // Determine which journals to load based on the showFavoritesOnlyFlag
                val journalsFlow = if (showFavoritesOnlyFlag) {
                    getJournalsUseCase.getFavoriteJournals(currentUserId)
                } else {
                    getJournalsUseCase(currentUserId)
                }

                // Collect the latest journals from the Flow
                journalsFlow.collectLatest { journals ->
                    // Filter journals based on the search query if it's not empty
                    val filteredJournals = if (searchQuery.isNotEmpty()) {
                        journals.filter { journal ->
                            journal.title.contains(searchQuery, ignoreCase = true)
                        }
                    } else {
                        journals
                    }

                    // Update the UI state with the loaded journals
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            journals = filteredJournals,
                            error = null,
                            isRefreshing = false
                        )
                    }
                }
            } catch (e: Exception) {
                // Handle exceptions by updating the UI state with an error message
                LogUtils.e(TAG, "Error loading journals", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        journals = emptyList(),
                        error = "Failed to load journals: ${e.message}",
                        isRefreshing = false
                    )
                }
            }
        }
    }

    /**
     * Deletes a journal entry.
     * This function deletes a journal entry from the repository and updates the UI state.
     *
     * @param journal The journal entry to delete
     */
    fun deleteJournal(journal: Journal) {
        viewModelScope.launch {
            try {
                // Call the deleteJournalUseCase to delete the journal
                val result = deleteJournalUseCase(journal)

                // Update the UI state based on the result
                if (result.isSuccess) {
                    _uiState.update { it.copy(message = "Journal deleted successfully") }
                    loadJournals() // Refresh the journal list
                } else {
                    _uiState.update { it.copy(error = "Failed to delete journal: ${result.exceptionOrNull()?.message}") }
                }
                LogUtils.d(TAG, "Delete journal result: $result")
            } catch (e: Exception) {
                // Handle exceptions by updating the UI state with an error message
                LogUtils.e(TAG, "Error deleting journal", e)
                _uiState.update { it.copy(error = "Error deleting journal: ${e.message}") }
            }
        }
    }

    /**
     * Filters journal entries based on the search query.
     * This function updates the searchQuery and reloads the journals to apply the filter.
     *
     * @param query The search query to filter the journal entries
     */
    fun filterJournals(query: String) {
        // Update the searchQuery with the provided query
        searchQuery = query
        // Load journals to apply the filter
        loadJournals()
    }

    /**
     * Toggles showing only favorite journal entries.
     * This function updates the showFavoritesOnlyFlag and reloads the journals to apply the filter.
     *
     * @param showFavoritesOnly Whether to show only favorite journal entries
     */
    fun showFavoritesOnly(showFavoritesOnly: Boolean) {
        // Update the showFavoritesOnlyFlag with the provided value
        showFavoritesOnlyFlag = showFavoritesOnly
        // Load journals to apply the filter
        loadJournals()
    }

    /**
     * Refreshes the journal list.
     * This function sets the isRefreshing flag to true and reloads the journals.
     */
    fun refresh() {
        // Set the isRefreshing flag to true
        isRefreshing = true
        // Load journals to refresh the list
        loadJournals()
    }

    /**
     * Clears any message in the UI state.
     * This function updates the UI state to clear the message.
     */
    fun clearMessage() {
        // Update the UI state to clear the message
        _uiState.update { it.copy(message = null, error = null) }
    }
}