package com.amirawellness.ui.screens.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import com.amirawellness.data.models.UserProfile
import com.amirawellness.data.repositories.UserRepository
import com.amirawellness.data.repositories.AuthRepository
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.core.utils.LogUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

private const val TAG = "ProfileViewModel"

/**
 * ViewModel that manages the UI state and business logic for the profile screen
 */
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val authRepository: AuthRepository,
    private val navActions: NavActions
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState(isLoading = true))
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    init {
        loadUserProfile()
    }

    /**
     * Loads the user profile data from the repository
     */
    fun loadUserProfile() {
        _uiState.update { it.copy(isLoading = true) }
        viewModelScope.launch {
            try {
                val result = userRepository.getUserProfile()
                if (result.isSuccess) {
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            userProfile = result.getOrNull(),
                            error = null
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = result.exceptionOrNull()?.message ?: "Unknown error occurred"
                        )
                    }
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error loading user profile", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Unknown error occurred"
                    )
                }
            }
        }
    }

    /**
     * Refreshes the user profile data from the server
     */
    fun refreshProfile() {
        _uiState.update { it.copy(isLoading = true) }
        viewModelScope.launch {
            try {
                val syncResult = userRepository.syncUserData()
                if (syncResult.isSuccess) {
                    loadUserProfile()
                } else {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = syncResult.exceptionOrNull()?.message ?: "Error synchronizing data"
                        )
                    }
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error refreshing profile", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Unknown error occurred"
                    )
                }
            }
        }
    }

    /**
     * Logs out the current user
     */
    fun logout() {
        viewModelScope.launch {
            try {
                val result = authRepository.logout()
                if (result.isSuccess) {
                    navActions.navigateToLogin()
                } else {
                    _uiState.update {
                        it.copy(error = result.exceptionOrNull()?.message ?: "Error during logout")
                    }
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error during logout", e)
                _uiState.update {
                    it.copy(error = e.message ?: "Error during logout")
                }
            }
        }
    }

    /**
     * Navigates to the settings screen
     */
    fun navigateToSettings() {
        navActions.navigateToSettings()
    }

    /**
     * Navigates to the data export screen
     */
    fun navigateToDataExport() {
        navActions.navigateToDataExport()
    }
}

/**
 * Data class representing the UI state for the profile screen
 */
data class ProfileUiState(
    val isLoading: Boolean = false,
    val userProfile: UserProfile? = null,
    val error: String? = null
)