package com.amirawellness.ui.screens.onboarding

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.local.preferences.PreferenceManagerFactory
import com.amirawellness.core.constants.PreferenceConstants.USER_PREFERENCES

/**
 * ViewModel for the onboarding flow in the Amira Wellness Android application.
 * Manages the state of the onboarding process, handles navigation between onboarding pages,
 * and tracks onboarding completion status.
 */
@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val navActions: NavActions,
    context: Context
) : ViewModel() {

    private val preferenceManager: PreferenceManager = PreferenceManagerFactory.createUserPreferences(context)
    
    // State management for the onboarding flow
    private val _uiState = MutableStateFlow<OnboardingState>(OnboardingState.Page1)
    val uiState: StateFlow<OnboardingState> = _uiState.asStateFlow()

    /**
     * Advances to the next onboarding page or completes onboarding if on the last page
     */
    fun nextPage() {
        when (_uiState.value) {
            is OnboardingState.Page1 -> _uiState.value = OnboardingState.Page2
            is OnboardingState.Page2 -> _uiState.value = OnboardingState.Page3
            is OnboardingState.Page3 -> {} // Already on the last page, handled by separate navigation functions
        }
    }

    /**
     * Returns to the previous onboarding page
     */
    fun previousPage() {
        when (_uiState.value) {
            is OnboardingState.Page1 -> {} // Already on the first page
            is OnboardingState.Page2 -> _uiState.value = OnboardingState.Page1
            is OnboardingState.Page3 -> _uiState.value = OnboardingState.Page2
        }
    }

    /**
     * Skips the onboarding process and marks it as completed
     */
    fun skipOnboarding() {
        viewModelScope.launch {
            preferenceManager.putBoolean(USER_PREFERENCES.ONBOARDING_COMPLETED, true)
            navActions.navigateToMain()
        }
    }

    /**
     * Marks the onboarding process as completed
     */
    fun completeOnboarding() {
        viewModelScope.launch {
            preferenceManager.putBoolean(USER_PREFERENCES.ONBOARDING_COMPLETED, true)
            navActions.navigateToMain()
        }
    }

    /**
     * Navigates to the login screen
     */
    fun navigateToLogin() {
        viewModelScope.launch {
            preferenceManager.putBoolean(USER_PREFERENCES.ONBOARDING_COMPLETED, true)
            navActions.navigateToLogin()
        }
    }

    /**
     * Navigates to the registration screen
     */
    fun navigateToRegister() {
        viewModelScope.launch {
            preferenceManager.putBoolean(USER_PREFERENCES.ONBOARDING_COMPLETED, true)
            navActions.navigateToRegister()
        }
    }
}

/**
 * Sealed class representing the different states of the onboarding flow
 */
sealed class OnboardingState {
    /**
     * Object representing the first page of the onboarding flow
     */
    object Page1 : OnboardingState()
    
    /**
     * Object representing the second page of the onboarding flow
     */
    object Page2 : OnboardingState()
    
    /**
     * Object representing the third page of the onboarding flow
     */
    object Page3 : OnboardingState()
}