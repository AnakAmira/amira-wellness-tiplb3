package com.amirawellness.ui.screens.settings

import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

import com.amirawellness.core.constants.NotificationConstants
import com.amirawellness.core.constants.PreferenceConstants
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.local.preferences.PreferenceManagerFactory
import com.amirawellness.services.notification.NotificationScheduler
import com.amirawellness.core.utils.LogUtils

private const val TAG = "NotificationSettingsViewModel"

/**
 * Data class representing the UI state for notification settings
 */
data class NotificationSettingsUiState(
    val isLoading: Boolean = false,
    val dailyRemindersEnabled: Boolean = false,
    val streakRemindersEnabled: Boolean = false,
    val achievementNotificationsEnabled: Boolean = false,
    val affirmationNotificationsEnabled: Boolean = false,
    val wellnessTipsEnabled: Boolean = false,
    val appUpdatesEnabled: Boolean = false,
    val reminderHour: Int = 9, // Default to 9:00 AM
    val reminderMinute: Int = 0,
    val reminderDays: Set<String> = emptySet(),
    val systemNotificationsEnabled: Boolean = true
)

/**
 * ViewModel for managing notification settings in the Amira Wellness application
 */
@HiltViewModel
class NotificationSettingsViewModel @Inject constructor(
    private val application: Application,
    private val notificationScheduler: NotificationScheduler
) : ViewModel() {
    
    private val preferenceManager: PreferenceManager = 
        PreferenceManagerFactory.createNotificationPreferences(application)
    
    private val _uiState = MutableStateFlow(NotificationSettingsUiState())
    val uiState: StateFlow<NotificationSettingsUiState> = _uiState.asStateFlow()
    
    init {
        loadNotificationSettings()
    }
    
    /**
     * Loads current notification settings from preferences
     */
    private fun loadNotificationSettings() {
        _uiState.value = _uiState.value.copy(isLoading = true)
        
        viewModelScope.launch {
            // Get the individual preference flows
            val dailyRemindersFlow = preferenceManager.getBooleanFlow(
                PreferenceConstants.NOTIFICATION_PREFERENCES.DAILY_REMINDERS_ENABLED, 
                true) // Default to enabled
                
            val streakRemindersFlow = preferenceManager.getBooleanFlow(
                PreferenceConstants.NOTIFICATION_PREFERENCES.STREAK_REMINDERS_ENABLED, 
                true) // Default to enabled
                
            val achievementsFlow = preferenceManager.getBooleanFlow(
                PreferenceConstants.NOTIFICATION_PREFERENCES.ACHIEVEMENTS_ENABLED, 
                true) // Default to enabled
                
            val affirmationsFlow = preferenceManager.getBooleanFlow(
                PreferenceConstants.NOTIFICATION_PREFERENCES.AFFIRMATIONS_ENABLED, 
                true) // Default to enabled
                
            val wellnessTipsFlow = preferenceManager.getBooleanFlow(
                PreferenceConstants.NOTIFICATION_PREFERENCES.WELLNESS_TIPS_ENABLED, 
                false) // Default to disabled
                
            val appUpdatesFlow = preferenceManager.getBooleanFlow(
                PreferenceConstants.NOTIFICATION_PREFERENCES.APP_UPDATES_ENABLED, 
                true) // Default to enabled
            
            // For reminder time, we'll use hour and minute separately
            val reminderHourFlow = preferenceManager.getIntFlow(
                "daily_reminder_hour",
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_HOUR)
                
            val reminderMinuteFlow = preferenceManager.getIntFlow(
                "daily_reminder_minute",
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_MINUTE)
                
            val reminderDaysFlow = preferenceManager.getStringSetFlow(
                PreferenceConstants.NOTIFICATION_PREFERENCES.REMINDER_DAYS, 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_DAYS)
                
            // Combine all flows to get a single state update
            combine(
                dailyRemindersFlow,
                streakRemindersFlow,
                achievementsFlow,
                affirmationsFlow,
                wellnessTipsFlow,
                appUpdatesFlow,
                reminderHourFlow,
                reminderMinuteFlow,
                reminderDaysFlow
            ) { dailyReminders, streakReminders, achievements, affirmations, 
                wellnessTips, appUpdates, hour, minute, days ->
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    dailyRemindersEnabled = dailyReminders,
                    streakRemindersEnabled = streakReminders,
                    achievementNotificationsEnabled = achievements,
                    affirmationNotificationsEnabled = affirmations,
                    wellnessTipsEnabled = wellnessTips,
                    appUpdatesEnabled = appUpdates,
                    reminderHour = hour,
                    reminderMinute = minute,
                    reminderDays = days ?: NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_DAYS,
                    systemNotificationsEnabled = areSystemNotificationsEnabled()
                )
            }.collect() // Start collecting the combined flow
        }
    }
    
    /**
     * Toggles the daily reminders setting
     */
    fun toggleDailyReminders(enabled: Boolean) {
        viewModelScope.launch {
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.DAILY_REMINDERS_ENABLED, 
                enabled)
                
            updateUiState { copy(dailyRemindersEnabled = enabled) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Daily reminders ${if (enabled) "enabled" else "disabled"}")
        }
    }
    
    /**
     * Toggles the streak reminders setting
     */
    fun toggleStreakReminders(enabled: Boolean) {
        viewModelScope.launch {
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.STREAK_REMINDERS_ENABLED, 
                enabled)
                
            updateUiState { copy(streakRemindersEnabled = enabled) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Streak reminders ${if (enabled) "enabled" else "disabled"}")
        }
    }
    
    /**
     * Toggles the achievement notifications setting
     */
    fun toggleAchievementNotifications(enabled: Boolean) {
        viewModelScope.launch {
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.ACHIEVEMENTS_ENABLED, 
                enabled)
                
            updateUiState { copy(achievementNotificationsEnabled = enabled) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Achievement notifications ${if (enabled) "enabled" else "disabled"}")
        }
    }
    
    /**
     * Toggles the affirmation notifications setting
     */
    fun toggleAffirmationNotifications(enabled: Boolean) {
        viewModelScope.launch {
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.AFFIRMATIONS_ENABLED, 
                enabled)
                
            updateUiState { copy(affirmationNotificationsEnabled = enabled) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Affirmation notifications ${if (enabled) "enabled" else "disabled"}")
        }
    }
    
    /**
     * Toggles the wellness tips setting
     */
    fun toggleWellnessTips(enabled: Boolean) {
        viewModelScope.launch {
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.WELLNESS_TIPS_ENABLED, 
                enabled)
                
            updateUiState { copy(wellnessTipsEnabled = enabled) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Wellness tips ${if (enabled) "enabled" else "disabled"}")
        }
    }
    
    /**
     * Toggles the app updates setting
     */
    fun toggleAppUpdates(enabled: Boolean) {
        viewModelScope.launch {
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.APP_UPDATES_ENABLED, 
                enabled)
                
            updateUiState { copy(appUpdatesEnabled = enabled) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "App updates ${if (enabled) "enabled" else "disabled"}")
        }
    }
    
    /**
     * Updates the daily reminder time
     */
    fun updateReminderTime(hour: Int, minute: Int) {
        viewModelScope.launch {
            // Using direct keys since we don't have constants for these
            preferenceManager.putInt("daily_reminder_hour", hour)
            preferenceManager.putInt("daily_reminder_minute", minute)
                
            updateUiState { copy(reminderHour = hour, reminderMinute = minute) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Reminder time updated to $hour:$minute")
        }
    }
    
    /**
     * Updates the days when daily reminders should be sent
     */
    fun updateReminderDays(days: Set<String>) {
        viewModelScope.launch {
            preferenceManager.putStringSet(
                PreferenceConstants.NOTIFICATION_PREFERENCES.REMINDER_DAYS, 
                days)
                
            updateUiState { copy(reminderDays = days) }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Reminder days updated to: $days")
        }
    }
    
    /**
     * Resets all notification settings to default values
     */
    fun resetToDefaults() {
        viewModelScope.launch {
            updateUiState { copy(isLoading = true) }
            
            // Reset to default values
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.DAILY_REMINDERS_ENABLED, 
                true)
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.STREAK_REMINDERS_ENABLED, 
                true)
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.ACHIEVEMENTS_ENABLED, 
                true)
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.AFFIRMATIONS_ENABLED, 
                true)
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.WELLNESS_TIPS_ENABLED, 
                false)
            preferenceManager.putBoolean(
                PreferenceConstants.NOTIFICATION_PREFERENCES.APP_UPDATES_ENABLED, 
                true)
                
            // Reset reminder time
            preferenceManager.putInt(
                "daily_reminder_hour",
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_HOUR)
            preferenceManager.putInt(
                "daily_reminder_minute",
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_MINUTE)
                
            // Reset reminder days
            preferenceManager.putStringSet(
                PreferenceConstants.NOTIFICATION_PREFERENCES.REMINDER_DAYS,
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_DAYS)
            
            updateUiState { 
                copy(
                    isLoading = false,
                    dailyRemindersEnabled = true,
                    streakRemindersEnabled = true,
                    achievementNotificationsEnabled = true,
                    affirmationNotificationsEnabled = true,
                    wellnessTipsEnabled = false,
                    appUpdatesEnabled = true,
                    reminderHour = NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_HOUR,
                    reminderMinute = NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_MINUTE,
                    reminderDays = NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_DAYS
                )
            }
            
            // Update notification scheduling
            notificationScheduler.updateNotificationPreferences()
            
            LogUtils.d(TAG, "Notification settings reset to defaults")
        }
    }
    
    /**
     * Checks if system notifications are enabled for the app
     */
    fun areSystemNotificationsEnabled(): Boolean {
        val notificationManager = application.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return notificationManager.areNotificationsEnabled()
    }
    
    /**
     * Opens the system notification settings for the app
     */
    fun openNotificationSettings() {
        val intent = Intent()
        
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, application.packageName)
        } else {
            intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
            intent.addCategory(Intent.CATEGORY_DEFAULT)
            intent.data = Uri.parse("package:" + application.packageName)
        }
        
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        application.startActivity(intent)
        
        LogUtils.d(TAG, "Opening system notification settings")
    }
    
    /**
     * Updates the UI state with new values
     */
    private fun updateUiState(update: NotificationSettingsUiState.() -> NotificationSettingsUiState) {
        _uiState.value = update(_uiState.value)
    }
}