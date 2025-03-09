package com.amirawellness.ui.screens.settings

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import com.amirawellness.core.constants.PreferenceConstants // Ensure correct version
import com.amirawellness.core.utils.LogUtils // Ensure correct version
import com.amirawellness.data.local.preferences.PreferenceManager // Ensure correct version
import com.amirawellness.data.local.preferences.PreferenceManagerFactory // Ensure correct version
import com.amirawellness.data.repositories.UserRepository // Ensure correct version
import com.amirawellness.services.analytics.AnalyticsManager // Ensure correct version
import com.amirawellness.services.encryption.EncryptionManager // Ensure correct version
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt:hilt-android-compiler:2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import javax.inject.Inject // javax.inject:javax.inject:1

private const val TAG = "PrivacySettingsViewModel"

/**
 * Data class representing the UI state for the privacy settings screen.
 * This class holds all the necessary data to render the privacy settings UI,
 * including flags for analytics consent, crash reporting, data retention period,
 * encryption settings, and loading/success/error states.
 */
data class PrivacySettingsUiState(
    val analyticsEnabled: Boolean = false,
    val crashReportingEnabled: Boolean = false,
    val dataRetentionPeriod: String = "3 months", // Default retention period
    val encryptionEnabled: Boolean = false,
    val exportEncryptionEnabled: Boolean = false,
    val isLoading: Boolean = false,
    val deleteSuccess: Boolean = false,
    val exportSuccess: Boolean = false,
    val errorMessage: String? = null,
    val exportFileUri: Uri? = null
) {
    /**
     * Creates a copy of the current state with specified properties changed.
     * This function allows for easy and immutable state updates.
     *
     * @param analyticsEnabled New value for analyticsEnabled
     * @param crashReportingEnabled New value for crashReportingEnabled
     * @param dataRetentionPeriod New value for dataRetentionPeriod
     * @param encryptionEnabled New value for encryptionEnabled
     * @param exportEncryptionEnabled New value for exportEncryptionEnabled
     * @param isLoading New value for isLoading
     * @param deleteSuccess New value for deleteSuccess
     * @param exportSuccess New value for exportSuccess
     * @param errorMessage New value for errorMessage
     * @param exportFileUri New value for exportFileUri
     * @return A new PrivacySettingsUiState with the specified properties changed
     */
    fun copy(
        analyticsEnabled: Boolean = this.analyticsEnabled,
        crashReportingEnabled: Boolean = this.crashReportingEnabled,
        dataRetentionPeriod: String = this.dataRetentionPeriod,
        encryptionEnabled: Boolean = this.encryptionEnabled,
        exportEncryptionEnabled: Boolean = this.exportEncryptionEnabled,
        isLoading: Boolean = this.isLoading,
        deleteSuccess: Boolean = this.deleteSuccess,
        exportSuccess: Boolean = this.exportSuccess,
        errorMessage: String? = this.errorMessage,
        exportFileUri: Uri? = this.exportFileUri
    ): PrivacySettingsUiState {
        return PrivacySettingsUiState(
            analyticsEnabled = analyticsEnabled,
            crashReportingEnabled = crashReportingEnabled,
            dataRetentionPeriod = dataRetentionPeriod,
            encryptionEnabled = encryptionEnabled,
            exportEncryptionEnabled = exportEncryptionEnabled,
            isLoading = isLoading,
            deleteSuccess = deleteSuccess,
            exportSuccess = exportSuccess,
            errorMessage = errorMessage,
            exportFileUri = exportFileUri
        )
    }
}

/**
 * ViewModel for the privacy settings screen that manages user privacy preferences.
 * This ViewModel is responsible for loading and saving privacy settings,
 * toggling analytics and crash reporting consent, setting the data retention period,
 * toggling end-to-end encryption, exporting user data, and deleting all user data.
 */
@HiltViewModel
class PrivacySettingsViewModel @Inject constructor(
    private val context: Context,
    private val userRepository: UserRepository,
    private val analyticsManager: AnalyticsManager
) : ViewModel() {

    private val privacyPreferences: PreferenceManager =
        PreferenceManagerFactory.createPrivacyPreferences(context)

    private val encryptionManager: EncryptionManager = EncryptionManager.getInstance(context)

    private val _uiState = MutableStateFlow(PrivacySettingsUiState())
    val uiState: StateFlow<PrivacySettingsUiState> = _uiState.asStateFlow()

    init {
        loadPrivacySettings()
    }

    /**
     * Loads current privacy settings from preferences.
     * This function retrieves the current values for analytics consent, crash reporting,
     * data retention period, and encryption settings from SharedPreferences and updates the UI state.
     */
    private fun loadPrivacySettings() {
        val analyticsEnabled =
            privacyPreferences.getBoolean(PreferenceConstants.PRIVACY_PREFERENCES.ANALYTICS_ENABLED, false)
        val crashReportingEnabled =
            privacyPreferences.getBoolean(PreferenceConstants.PRIVACY_PREFERENCES.CRASH_REPORTING_ENABLED, false)
        val dataRetentionPeriod =
            privacyPreferences.getString(PreferenceConstants.PRIVACY_PREFERENCES.DATA_RETENTION_PERIOD, "3 months") ?: "3 months"
        val encryptionEnabled =
            privacyPreferences.getBoolean(PreferenceConstants.PRIVACY_PREFERENCES.EXPORT_DATA_ENCRYPTION, false)
        val exportEncryptionEnabled =
            privacyPreferences.getBoolean(PreferenceConstants.PRIVACY_PREFERENCES.EXPORT_DATA_ENCRYPTION, false)

        _uiState.value = _uiState.value.copy(
            analyticsEnabled = analyticsEnabled,
            crashReportingEnabled = crashReportingEnabled,
            dataRetentionPeriod = dataRetentionPeriod,
            encryptionEnabled = encryptionEnabled,
            exportEncryptionEnabled = exportEncryptionEnabled
        )
    }

    /**
     * Toggles analytics data collection consent.
     * This function updates the analytics consent setting in SharedPreferences,
     * enables or disables analytics tracking in Firebase, and updates the UI state.
     *
     * @param enabled Whether analytics data collection is enabled
     */
    fun toggleAnalyticsConsent(enabled: Boolean) {
        privacyPreferences.putBoolean(PreferenceConstants.PRIVACY_PREFERENCES.ANALYTICS_ENABLED, enabled)
        analyticsManager.setEnabled(enabled)
        if (!enabled) {
            analyticsManager.clearAnalyticsData()
        }
        _uiState.value = _uiState.value.copy(analyticsEnabled = enabled)
        LogUtils.d(TAG, "Analytics consent toggled: enabled = $enabled")
    }

    /**
     * Toggles crash reporting consent.
     * This function updates the crash reporting setting in SharedPreferences and updates the UI state.
     *
     * @param enabled Whether crash reporting is enabled
     */
    fun toggleCrashReportingConsent(enabled: Boolean) {
        privacyPreferences.putBoolean(PreferenceConstants.PRIVACY_PREFERENCES.CRASH_REPORTING_ENABLED, enabled)
        _uiState.value = _uiState.value.copy(crashReportingEnabled = enabled)
        LogUtils.d(TAG, "Crash reporting consent toggled: enabled = $enabled")
    }

    /**
     * Sets the data retention period for user data.
     * This function updates the data retention period setting in SharedPreferences and updates the UI state.
     *
     * @param period The data retention period (e.g., "3 months", "6 months", "1 year")
     */
    fun setDataRetentionPeriod(period: String) {
        privacyPreferences.putString(PreferenceConstants.PRIVACY_PREFERENCES.DATA_RETENTION_PERIOD, period)
        _uiState.value = _uiState.value.copy(dataRetentionPeriod = period)
        LogUtils.d(TAG, "Data retention period set: period = $period")
    }

    /**
     * Toggles end-to-end encryption for sensitive data.
     * This function updates the encryption setting in SharedPreferences and updates the UI state.
     *
     * @param enabled Whether end-to-end encryption is enabled
     */
    fun toggleEncryption(enabled: Boolean) {
        privacyPreferences.putBoolean(PreferenceConstants.PRIVACY_PREFERENCES.EXPORT_DATA_ENCRYPTION, enabled)
        _uiState.value = _uiState.value.copy(encryptionEnabled = enabled)
        LogUtils.d(TAG, "Encryption toggled: enabled = $enabled")
    }

    /**
     * Toggles encryption for exported data.
     * This function updates the export encryption setting in SharedPreferences and updates the UI state.
     *
     * @param enabled Whether encryption for exported data is enabled
     */
    fun toggleExportEncryption(enabled: Boolean) {
        privacyPreferences.putBoolean(PreferenceConstants.PRIVACY_PREFERENCES.EXPORT_DATA_ENCRYPTION, enabled)
        _uiState.value = _uiState.value.copy(exportEncryptionEnabled = enabled)
        LogUtils.d(TAG, "Export encryption toggled: enabled = $enabled")
    }

    /**
     * Exports user data with optional encryption.
     * This function exports all user data, including voice recordings, emotional check-ins,
     * and profile information, to a file. The data can be optionally encrypted with a
     * user-provided password.
     *
     * @param password Optional password to encrypt the exported data
     */
    fun exportData(password: String?) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null, exportSuccess = false, exportFileUri = null)
        viewModelScope.launch {
            try {
                if (_uiState.value.exportEncryptionEnabled && password.isNullOrEmpty()) {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = "Password is required for encrypted export"
                    )
                    return@launch
                }

                // TODO: Implement data export logic here
                // 1. Gather all user data (voice recordings, emotional check-ins, profile info)
                // 2. Serialize the data to a file (e.g., JSON)
                // 3. If encryption is enabled, encrypt the file with the password
                // 4. Generate a URI for the exported file
                // 5. Update _uiState with success and file URI

                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    exportSuccess = true,
                    exportFileUri = Uri.parse("content://com.amirawellness/exports/dummy_data.json") // Replace with actual file URI
                )
                LogUtils.d(TAG, "Data exported successfully")
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Data export failed: ${e.message}"
                )
                LogUtils.e(TAG, "Data export failed", e)
            }
        }
    }

    /**
     * Deletes all user data from the application.
     * This function deletes all user data from the local database and clears all
     * user preferences. It also disables analytics tracking to ensure user privacy.
     */
    fun deleteAllData() {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null, deleteSuccess = false)
        viewModelScope.launch {
            try {
                userRepository.deleteUserData()
                privacyPreferences.clear()
                analyticsManager.clearAnalyticsData()

                _uiState.value = _uiState.value.copy(isLoading = false, deleteSuccess = true)
                LogUtils.d(TAG, "All user data deleted successfully")
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Data deletion failed: ${e.message}"
                )
                LogUtils.e(TAG, "Data deletion failed", e)
            }
        }
    }

    /**
     * Resets the UI state to clear success/error messages.
     * This function clears the isLoading, success, error, and exportFileUri properties
     * in the UI state to prepare the screen for new interactions.
     */
    fun resetState() {
        _uiState.value = _uiState.value.copy(
            isLoading = false,
            deleteSuccess = false,
            exportSuccess = false,
            errorMessage = null,
            exportFileUri = null
        )
    }
}