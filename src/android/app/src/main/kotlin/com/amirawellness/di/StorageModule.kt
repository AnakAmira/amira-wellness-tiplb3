package com.amirawellness.di

import android.content.Context
import androidx.room.Room // androidx.room:room-runtime:2.6+
import com.amirawellness.core.constants.PreferenceConstants
import com.amirawellness.data.local.AppDatabase
import com.amirawellness.data.local.dao.UserDao
import com.amirawellness.data.local.dao.JournalDao
import com.amirawellness.data.local.dao.EmotionalStateDao
import com.amirawellness.data.local.dao.ToolDao
import com.amirawellness.data.local.dao.ToolCategoryDao
import com.amirawellness.data.local.dao.AchievementDao
import com.amirawellness.data.local.dao.StreakDao
import com.amirawellness.data.local.dao.NotificationDao
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.local.preferences.StandardPreferenceManager
import com.amirawellness.data.local.preferences.EncryptedPreferenceManager
import org.koin.android.ext.koin.androidContext // org.koin:koin-android:3.3.0
import org.koin.core.module.Module // org.koin:koin-core:3.3.0
import org.koin.dsl.module // org.koin:koin-core:3.3.0
import org.koin.core.qualifier.named // org.koin:koin-core:3.3.0
import org.koin.dsl.bind // org.koin:koin-core:3.3.0

/**
 * Koin module for storage-related dependencies.
 * This module provides dependencies for the Room database, DAOs, and PreferenceManagers.
 */
val storageModule: Module = module {

    /**
     * Provides a singleton instance of the Room database.
     *
     * @param context The application context
     * @return Singleton instance of the Room database
     */
    single {
        AppDatabase.getInstance(androidContext())
    }

    /**
     * Provides the UserDao for user-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for user-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.userDao()
    }

    /**
     * Provides the JournalDao for journal-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for journal-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.journalDao()
    }

    /**
     * Provides the EmotionalStateDao for emotional state-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for emotional state-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.emotionalStateDao()
    }

    /**
     * Provides the ToolDao for tool-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for tool-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.toolDao()
    }

    /**
     * Provides the ToolCategoryDao for tool category-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for tool category-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.toolCategoryDao()
    }

    /**
     * Provides the AchievementDao for achievement-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for achievement-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.achievementDao()
    }

    /**
     * Provides the StreakDao for streak-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for streak-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.streakDao()
    }

    /**
     * Provides the NotificationDao for notification-related database operations.
     *
     * @param database The AppDatabase instance
     * @return Data access object for notification-related operations
     */
    single {
        val database = get<AppDatabase>()
        database.notificationDao()
    }

    /**
     * Provides a PreferenceManager for user preferences.
     *
     * @param context The application context
     * @return PreferenceManager for user preferences
     */
    single(named("userPreferences")) {
        StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.USER_PREFS)
    } bind PreferenceManager::class

    /**
     * Provides a secure PreferenceManager for authentication preferences.
     *
     * @param context The application context
     * @return Secure PreferenceManager for authentication preferences
     */
    single(named("authPreferences")) {
        if (EncryptedPreferenceManager.isEncryptionAvailable()) {
            EncryptedPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.AUTH_PREFS)
        } else {
            StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.AUTH_PREFS)
        }
    } bind PreferenceManager::class

    /**
     * Provides a PreferenceManager for notification preferences.
     *
     * @param context The application context
     * @return PreferenceManager for notification preferences
     */
    single(named("notificationPreferences")) {
        StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.NOTIFICATION_PREFS)
    } bind PreferenceManager::class

    /**
     * Provides a secure PreferenceManager for privacy preferences.
     *
     * @param context The application context
     * @return Secure PreferenceManager for privacy preferences
     */
    single(named("privacyPreferences")) {
        if (EncryptedPreferenceManager.isEncryptionAvailable()) {
            EncryptedPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.PRIVACY_PREFS)
        } else {
            StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.PRIVACY_PREFS)
        }
    } bind PreferenceManager::class

    /**
     * Provides a PreferenceManager for application preferences.
     *
     * @param context The application context
     * @return PreferenceManager for application preferences
     */
    single(named("appPreferences")) {
        StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.APP_PREFS)
    } bind PreferenceManager::class

    /**
     * Provides a PreferenceManager for journal preferences.
     *
     * @param context The application context
     * @return PreferenceManager for journal preferences
     */
    single(named("journalPreferences")) {
        StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.JOURNAL_PREFS)
    } bind PreferenceManager::class

    /**
     * Provides a PreferenceManager for tool preferences.
     *
     * @param context The application context
     * @return PreferenceManager for tool preferences
     */
    single(named("toolPreferences")) {
        StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.TOOL_PREFS)
    } bind PreferenceManager::class

    /**
     * Provides a PreferenceManager for synchronization preferences.
     *
     * @param context The application context
     * @return PreferenceManager for synchronization preferences
     */
    single(named("syncPreferences")) {
        StandardPreferenceManager(androidContext(), PreferenceConstants.PREFERENCE_FILES.SYNC_PREFS)
    } bind PreferenceManager::class
}