package com.amirawellness.ui.screens.settings

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.amirawellness.core.constants.PreferenceConstants
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.local.preferences.PreferenceManagerFactory
import com.amirawellness.domain.usecases.auth.LogoutUseCase
import com.amirawellness.services.biometric.BiometricManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

private const val TAG = "SettingsViewModel"

/**
 * ViewModel for the settings screen that manages user preferences and settings.
 * Handles theme selection, language selection, biometric authentication, and logout functionality.
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val context: Context,
    private val logoutUseCase: LogoutUseCase
) : ViewModel() {
    
    private val userPreferences: PreferenceManager = PreferenceManagerFactory.createUserPreferences(context)
    private val appPreferences: PreferenceManager = PreferenceManagerFactory.createAppPreferences(context)
    private val biometricManager: BiometricManager = BiometricManager.getInstance(context)
    
    private val _uiState = MutableStateFlow(
        SettingsUiState(
            theme = "system",
            language = "es",
            biometricAuthEnabled = false,
            isLoading = false,
            logoutSuccess = false,
            errorMessage = null
        )
    )
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()
    
    init {
        loadSettings()
    }
    
    /**
     * Loads the current settings from preferences.
     */
    private fun loadSettings() {
        // Get theme preference from user preferences
        val theme = userPreferences.getString(
            PreferenceConstants.USER_PREFERENCES.THEME, 
            "system"
        ) ?: "system"
        
        // Get language preference from user preferences
        val language = userPreferences.getString(
            PreferenceConstants.USER_PREFERENCES.LANGUAGE, 
            "es"
        ) ?: "es"
        
        // Get biometric authentication preference
        val biometricAuthEnabled = userPreferences.getBoolean(
            PreferenceConstants.AUTH_PREFERENCES.BIOMETRIC_ENABLED, 
            false
        )
        
        // Update UI state with loaded settings
        _uiState.value = _uiState.value.copy(
            theme = theme,
            language = language,
            biometricAuthEnabled = biometricAuthEnabled
        )
    }
    
    /**
     * Updates the theme setting.
     *
     * @param theme The new theme to apply ("light", "dark", or "system")
     */
    fun updateTheme(theme: String) {
        // Save theme preference
        userPreferences.putString(PreferenceConstants.USER_PREFERENCES.THEME, theme)
        
        // Update UI state
        _uiState.value = _uiState.value.copy(theme = theme)
        
        LogUtils.d(TAG, "Theme updated to: $theme")
    }
    
    /**
     * Updates the language setting.
     *
     * @param language The new language code to apply (e.g., "es" for Spanish)
     */
    fun updateLanguage(language: String) {
        // Save language preference
        userPreferences.putString(PreferenceConstants.USER_PREFERENCES.LANGUAGE, language)
        
        // Update UI state
        _uiState.value = _uiState.value.copy(language = language)
        
        LogUtils.d(TAG, "Language updated to: $language")
    }
    
    /**
     * Toggles biometric authentication on or off.
     *
     * @param enabled True to enable biometric authentication, false to disable it
     */
    fun toggleBiometricAuth(enabled: Boolean) {
        // Check if biometric authentication is available
        if (enabled && !biometricManager.canAuthenticate()) {
            LogUtils.e(TAG, "Biometric authentication is not available on this device")
            return
        }
        
        // Save biometric authentication preference
        userPreferences.putBoolean(PreferenceConstants.AUTH_PREFERENCES.BIOMETRIC_ENABLED, enabled)
        
        // Update UI state
        _uiState.value = _uiState.value.copy(biometricAuthEnabled = enabled)
        
        LogUtils.d(TAG, "Biometric authentication ${if (enabled) "enabled" else "disabled"}")
    }
    
    /**
     * Checks if biometric authentication is available on the device.
     *
     * @return True if biometric authentication is available, false otherwise
     */
    fun isBiometricAvailable(): Boolean {
        return biometricManager.canAuthenticate()
    }
    
    /**
     * Logs out the current user.
     * Updates the UI state to show loading, then success or error based on the logout result.
     */
    fun logout() {
        viewModelScope.launch {
            // Show loading state
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            try {
                // Call logout use case
                val result = logoutUseCase()
                
                if (result.isSuccess) {
                    // Update UI state for successful logout
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        logoutSuccess = true,
                        errorMessage = null
                    )
                    LogUtils.d(TAG, "Logout successful")
                } else {
                    // Update UI state for failed logout
                    val error = result.exceptionOrNull()?.message ?: "Unknown error occurred"
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        logoutSuccess = false,
                        errorMessage = error
                    )
                    LogUtils.e(TAG, "Logout failed: $error")
                }
            } catch (e: Exception) {
                // Handle unexpected exceptions
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    logoutSuccess = false,
                    errorMessage = e.message ?: "An unexpected error occurred"
                )
                LogUtils.e(TAG, "Logout failed with exception", e)
            }
        }
    }
    
    /**
     * Resets the logout state in the UI.
     * Useful after navigating away from the settings screen or handling the logout result.
     */
    fun resetLogoutState() {
        _uiState.value = _uiState.value.copy(
            logoutSuccess = false,
            errorMessage = null
        )
    }
}

/**
 * Data class representing the UI state for the settings screen.
 *
 * @property theme The current theme setting ("light", "dark", or "system")
 * @property language The current language setting (e.g., "es" for Spanish)
 * @property biometricAuthEnabled Whether biometric authentication is currently enabled
 * @property isLoading Whether an async operation (like logout) is in progress
 * @property logoutSuccess Whether a logout operation completed successfully
 * @property errorMessage Error message to display, if any
 */
data class SettingsUiState(
    val theme: String,
    val language: String,
    val biometricAuthEnabled: Boolean,
    val isLoading: Boolean,
    val logoutSuccess: Boolean,
    val errorMessage: String?
)