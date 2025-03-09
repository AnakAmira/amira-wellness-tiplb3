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
import com.amirawellness.domain.usecases.auth.RegisterUseCase
import com.amirawellness.domain.usecases.auth.InvalidEmailException
import com.amirawellness.domain.usecases.auth.EmptyPasswordException
import com.amirawellness.domain.usecases.auth.WeakPasswordException
import com.amirawellness.domain.usecases.auth.PasswordMismatchException
import com.amirawellness.data.repositories.UserAlreadyExistsException
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.core.utils.LogUtils

private const val TAG = "RegisterViewModel"

/**
 * ViewModel for the registration screen that manages UI state and registration logic
 */
@HiltViewModel
class RegisterViewModel @Inject constructor(
    private val registerUseCase: RegisterUseCase,
    private val navActions: NavActions
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        RegisterUiState(
            email = "",
            password = "",
            passwordConfirm = "",
            termsAccepted = false,
            isLoading = false,
            errorMessage = null
        )
    )
    val uiState: StateFlow<RegisterUiState> = _uiState.asStateFlow()

    /**
     * Updates the email in the UI state
     *
     * @param email The new email value
     */
    fun updateEmail(email: String) {
        _uiState.update { it.copy(email = email, errorMessage = null) }
    }

    /**
     * Updates the password in the UI state
     *
     * @param password The new password value
     */
    fun updatePassword(password: String) {
        _uiState.update { it.copy(password = password, errorMessage = null) }
    }

    /**
     * Updates the password confirmation in the UI state
     *
     * @param passwordConfirm The new password confirmation value
     */
    fun updatePasswordConfirm(passwordConfirm: String) {
        _uiState.update { it.copy(passwordConfirm = passwordConfirm, errorMessage = null) }
    }

    /**
     * Updates the terms accepted state in the UI state
     *
     * @param accepted Whether terms are accepted
     */
    fun updateTermsAccepted(accepted: Boolean) {
        _uiState.update { it.copy(termsAccepted = accepted, errorMessage = null) }
    }

    /**
     * Attempts to register a new user with the provided credentials
     */
    fun register() {
        val currentState = _uiState.value
        
        // Check if terms are accepted
        if (!currentState.termsAccepted) {
            _uiState.update { it.copy(errorMessage = "Por favor acepta los términos y condiciones para continuar") }
            return
        }
        
        // Set loading state
        _uiState.update { it.copy(isLoading = true, errorMessage = null) }
        
        viewModelScope.launch {
            try {
                // Get values from current state
                val email = currentState.email
                val password = currentState.password
                val passwordConfirm = currentState.passwordConfirm
                
                // Call register use case
                val result = registerUseCase(
                    email = email,
                    password = password,
                    passwordConfirm = passwordConfirm,
                    languagePreference = "es" // Default to Spanish as per requirements
                )
                
                result.fold(
                    onSuccess = {
                        // Registration successful, navigate to main screen
                        LogUtils.logDebug(TAG, "Registration successful for email: $email")
                        navActions.navigateToMain()
                    },
                    onFailure = { exception ->
                        // Handle specific exceptions with appropriate user-friendly messages
                        val errorMessage = when (exception) {
                            is InvalidEmailException -> "Formato de correo electrónico inválido"
                            is EmptyPasswordException -> "La contraseña no puede estar vacía"
                            is WeakPasswordException -> "La contraseña debe tener al menos 8 caracteres"
                            is PasswordMismatchException -> "Las contraseñas no coinciden"
                            is UserAlreadyExistsException -> "Ya existe un usuario con este correo electrónico"
                            else -> "Registro fallido: ${exception.message}"
                        }
                        LogUtils.logError(TAG, "Registration failed: $errorMessage", exception)
                        _uiState.update { it.copy(errorMessage = errorMessage) }
                    }
                )
            } catch (e: Exception) {
                // Handle unexpected exceptions
                LogUtils.logError(TAG, "Unexpected error during registration", e)
                _uiState.update { 
                    it.copy(errorMessage = "Ocurrió un error inesperado. Por favor intenta de nuevo.")
                }
            } finally {
                // Reset loading state regardless of outcome
                _uiState.update { it.copy(isLoading = false) }
            }
        }
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
}

/**
 * Data class representing the UI state for the registration screen
 */
data class RegisterUiState(
    val email: String,
    val password: String,
    val passwordConfirm: String,
    val termsAccepted: Boolean,
    val isLoading: Boolean,
    val errorMessage: String?
)