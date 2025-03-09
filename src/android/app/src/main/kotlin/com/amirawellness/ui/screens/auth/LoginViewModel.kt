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
import com.amirawellness.domain.usecases.auth.LoginUseCase
import com.amirawellness.domain.usecases.auth.InvalidEmailException
import com.amirawellness.domain.usecases.auth.EmptyPasswordException
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.core.utils.LogUtils.e as logError
import com.amirawellness.core.utils.LogUtils.d as logDebug

private const val TAG = "LoginViewModel"

/**
 * ViewModel for the login screen that manages UI state and authentication logic
 */
@HiltViewModel
class LoginViewModel @Inject constructor(
    private val loginUseCase: LoginUseCase,
    private val navActions: NavActions
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(LoginUiState(
        email = "",
        password = "",
        isLoading = false,
        errorMessage = null
    ))
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    /**
     * Updates the email in the UI state
     *
     * @param email The new email value
     */
    fun updateEmail(email: String) {
        _uiState.update { it.copy(
            email = email,
            errorMessage = null
        )}
    }

    /**
     * Updates the password in the UI state
     *
     * @param password The new password value
     */
    fun updatePassword(password: String) {
        _uiState.update { it.copy(
            password = password,
            errorMessage = null
        )}
    }

    /**
     * Attempts to authenticate the user with the provided credentials
     */
    fun login() {
        // Set loading state
        _uiState.update { it.copy(isLoading = true) }
        
        viewModelScope.launch {
            try {
                // Get current email and password from state
                val email = uiState.value.email
                val password = uiState.value.password
                
                // Call login use case
                val result = loginUseCase(email, password)
                
                if (result.isSuccess) {
                    // Success - navigate to main screen
                    navActions.navigateToMain()
                } else {
                    // Handle error
                    handleLoginError(result.exceptionOrNull())
                }
            } catch (e: Exception) {
                // Handle unexpected errors
                logError(TAG, "Error during login", e)
                _uiState.update { it.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "An unexpected error occurred"
                )}
            } finally {
                // Reset loading state if still in this ViewModel
                if (_uiState.value.isLoading) {
                    _uiState.update { it.copy(isLoading = false) }
                }
            }
        }
    }
    
    private fun handleLoginError(error: Throwable?) {
        val errorMessage = when (error) {
            is InvalidEmailException -> "Invalid email format"
            is EmptyPasswordException -> "Password cannot be empty"
            else -> error?.message ?: "Authentication failed"
        }
        
        _uiState.update { it.copy(
            isLoading = false,
            errorMessage = errorMessage
        )}
    }
    
    /**
     * Navigates to the registration screen
     */
    fun navigateToRegister() {
        navActions.navigateToRegister()
    }
    
    /**
     * Navigates to the forgot password screen
     */
    fun navigateToForgotPassword() {
        navActions.navigateToForgotPassword()
    }
    
    /**
     * Clears the error message in the UI state
     */
    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}

/**
 * Data class representing the UI state for the login screen
 */
data class LoginUiState(
    val email: String,
    val password: String,
    val isLoading: Boolean,
    val errorMessage: String?
)