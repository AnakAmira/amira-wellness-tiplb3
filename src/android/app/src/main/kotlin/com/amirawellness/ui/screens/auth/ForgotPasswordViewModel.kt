package com.amirawellness.ui.screens.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject
import dagger.hilt.android.lifecycle.HiltViewModel
import com.amirawellness.domain.usecases.auth.ResetPasswordUseCase
import com.amirawellness.domain.usecases.auth.InvalidEmailException
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.core.utils.LogUtils

private const val TAG = "ForgotPasswordViewModel"

/**
 * ViewModel for the forgot password screen that manages UI state and password reset logic
 */
@HiltViewModel
class ForgotPasswordViewModel @Inject constructor(
    private val resetPasswordUseCase: ResetPasswordUseCase,
    private val navActions: NavActions
) : ViewModel() {

    private val _uiState = MutableStateFlow(ForgotPasswordUiState())
    val uiState: StateFlow<ForgotPasswordUiState> = _uiState.asStateFlow()

    /**
     * Updates the email in the UI state
     *
     * @param email The new email value to set
     */
    fun updateEmail(email: String) {
        _uiState.update { currentState ->
            currentState.copy(
                email = email,
                errorMessage = null // Clear error message when email is updated
            )
        }
    }

    /**
     * Attempts to initiate a password reset for the provided email
     */
    fun resetPassword() {
        // Set loading state
        _uiState.update { it.copy(isLoading = true) }

        viewModelScope.launch {
            try {
                val email = uiState.value.email
                val result = resetPasswordUseCase(email)

                if (result.isSuccess) {
                    // Success
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            successMessage = "Password reset instructions have been sent to your email",
                            errorMessage = null
                        )
                    }
                } else {
                    // Handle specific errors
                    val exception = result.exceptionOrNull()
                    val errorMessage = when (exception) {
                        is InvalidEmailException -> "Please enter a valid email address"
                        else -> "An error occurred. Please try again later."
                    }

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = errorMessage,
                            successMessage = null
                        )
                    }
                }
            } catch (e: Exception) {
                LogUtils.logError(TAG, "Error resetting password", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        errorMessage = "An unexpected error occurred. Please try again later.",
                        successMessage = null
                    )
                }
            }
        }
    }

    /**
     * Navigates back to the previous screen
     */
    fun navigateBack() {
        navActions.navigateBack()
    }

    /**
     * Navigates to the login screen
     */
    fun navigateToLogin() {
        navActions.navigateToLogin()
    }

    /**
     * Clears the error message in the UI state
     */
    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    /**
     * Clears the success message in the UI state
     */
    fun clearSuccess() {
        _uiState.update { it.copy(successMessage = null) }
    }
}

/**
 * Data class representing the UI state for the forgot password screen
 */
data class ForgotPasswordUiState(
    val email: String = "",
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)