package com.amirawellness.data.local.preferences

import android.content.Context // android version: latest
import android.content.SharedPreferences // android version: latest
import com.amirawellness.core.constants.PreferenceConstants
import com.amirawellness.core.utils.LogUtils
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines version: 1.6.4

/**
 * Defines a consistent interface for accessing and managing user preferences in the Amira Wellness
 * application. Provides methods to store and retrieve various types of data with support for
 * reactive updates through Kotlin Flows.
 */
interface PreferenceManager {
    /**
     * Retrieves a string value from preferences
     *
     * @param key The preference key
     * @param defaultValue The default value to return if the preference doesn't exist
     * @return The string value or defaultValue if not found
     */
    fun getString(key: String, defaultValue: String? = null): String?

    /**
     * Creates a Flow that emits the current string value and updates when it changes
     *
     * @param key The preference key
     * @param defaultValue The default value to emit if the preference doesn't exist
     * @return Flow of string values
     */
    fun getStringFlow(key: String, defaultValue: String? = null): Flow<String?>

    /**
     * Stores a string value in preferences
     *
     * @param key The preference key
     * @param value The value to store
     * @return True if the value was successfully stored
     */
    fun putString(key: String, value: String?): Boolean

    /**
     * Retrieves an integer value from preferences
     *
     * @param key The preference key
     * @param defaultValue The default value to return if the preference doesn't exist
     * @return The integer value or defaultValue if not found
     */
    fun getInt(key: String, defaultValue: Int): Int

    /**
     * Creates a Flow that emits the current integer value and updates when it changes
     *
     * @param key The preference key
     * @param defaultValue The default value to emit if the preference doesn't exist
     * @return Flow of integer values
     */
    fun getIntFlow(key: String, defaultValue: Int): Flow<Int>

    /**
     * Stores an integer value in preferences
     *
     * @param key The preference key
     * @param value The value to store
     * @return True if the value was successfully stored
     */
    fun putInt(key: String, value: Int): Boolean

    /**
     * Retrieves a long value from preferences
     *
     * @param key The preference key
     * @param defaultValue The default value to return if the preference doesn't exist
     * @return The long value or defaultValue if not found
     */
    fun getLong(key: String, defaultValue: Long): Long

    /**
     * Creates a Flow that emits the current long value and updates when it changes
     *
     * @param key The preference key
     * @param defaultValue The default value to emit if the preference doesn't exist
     * @return Flow of long values
     */
    fun getLongFlow(key: String, defaultValue: Long): Flow<Long>

    /**
     * Stores a long value in preferences
     *
     * @param key The preference key
     * @param value The value to store
     * @return True if the value was successfully stored
     */
    fun putLong(key: String, value: Long): Boolean

    /**
     * Retrieves a float value from preferences
     *
     * @param key The preference key
     * @param defaultValue The default value to return if the preference doesn't exist
     * @return The float value or defaultValue if not found
     */
    fun getFloat(key: String, defaultValue: Float): Float

    /**
     * Creates a Flow that emits the current float value and updates when it changes
     *
     * @param key The preference key
     * @param defaultValue The default value to emit if the preference doesn't exist
     * @return Flow of float values
     */
    fun getFloatFlow(key: String, defaultValue: Float): Flow<Float>

    /**
     * Stores a float value in preferences
     *
     * @param key The preference key
     * @param value The value to store
     * @return True if the value was successfully stored
     */
    fun putFloat(key: String, value: Float): Boolean

    /**
     * Retrieves a boolean value from preferences
     *
     * @param key The preference key
     * @param defaultValue The default value to return if the preference doesn't exist
     * @return The boolean value or defaultValue if not found
     */
    fun getBoolean(key: String, defaultValue: Boolean): Boolean

    /**
     * Creates a Flow that emits the current boolean value and updates when it changes
     *
     * @param key The preference key
     * @param defaultValue The default value to emit if the preference doesn't exist
     * @return Flow of boolean values
     */
    fun getBooleanFlow(key: String, defaultValue: Boolean): Flow<Boolean>

    /**
     * Stores a boolean value in preferences
     *
     * @param key The preference key
     * @param value The value to store
     * @return True if the value was successfully stored
     */
    fun putBoolean(key: String, value: Boolean): Boolean

    /**
     * Retrieves a set of strings from preferences
     *
     * @param key The preference key
     * @param defaultValue The default value to return if the preference doesn't exist
     * @return The string set or defaultValue if not found
     */
    fun getStringSet(key: String, defaultValue: Set<String>? = null): Set<String>?

    /**
     * Creates a Flow that emits the current string set and updates when it changes
     *
     * @param key The preference key
     * @param defaultValue The default value to emit if the preference doesn't exist
     * @return Flow of string sets
     */
    fun getStringSetFlow(key: String, defaultValue: Set<String>? = null): Flow<Set<String>?>

    /**
     * Stores a set of strings in preferences
     *
     * @param key The preference key
     * @param value The value to store
     * @return True if the value was successfully stored
     */
    fun putStringSet(key: String, value: Set<String>?): Boolean

    /**
     * Checks if a preference exists
     *
     * @param key The preference key
     * @return True if the preference exists, false otherwise
     */
    fun contains(key: String): Boolean

    /**
     * Removes a preference
     *
     * @param key The preference key
     * @return True if the preference was successfully removed
     */
    fun remove(key: String): Boolean

    /**
     * Clears all preferences
     *
     * @return True if all preferences were successfully cleared
     */
    fun clear(): Boolean

    /**
     * Registers a listener for preference changes
     *
     * @param listener The listener to register
     */
    fun registerOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener)

    /**
     * Unregisters a preference change listener
     *
     * @param listener The listener to unregister
     */
    fun unregisterOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener)
}

/**
 * Standard implementation of PreferenceManager using Android's SharedPreferences
 *
 * @param context The application context used to access SharedPreferences
 * @param preferenceName The name of the SharedPreferences file to use
 */
class StandardPreferenceManager(
    context: Context,
    preferenceName: String
) : PreferenceManager {

    private val sharedPreferences: SharedPreferences = context.getSharedPreferences(
        preferenceName, Context.MODE_PRIVATE
    )

    companion object {
        private const val TAG = "StandardPreferenceManager"
    }

    override fun getString(key: String, defaultValue: String?): String? {
        return try {
            sharedPreferences.getString(key, defaultValue)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting string preference: $key", e)
            defaultValue
        }
    }

    override fun getStringFlow(key: String, defaultValue: String?): Flow<String?> {
        // Implementation uses SharedPreferences.OnSharedPreferenceChangeListener to observe changes
        // and emits updated values through the Flow when the preference changes
        // Detailed implementation would use kotlinx.coroutines.flow builders
        TODO("Return Flow that emits current string value and updates when changed")
    }

    override fun putString(key: String, value: String?): Boolean {
        return try {
            sharedPreferences.edit().putString(key, value).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error storing string preference: $key", e)
            false
        }
    }

    override fun getInt(key: String, defaultValue: Int): Int {
        return try {
            sharedPreferences.getInt(key, defaultValue)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting integer preference: $key", e)
            defaultValue
        }
    }

    override fun getIntFlow(key: String, defaultValue: Int): Flow<Int> {
        // Implementation uses SharedPreferences.OnSharedPreferenceChangeListener to observe changes
        // and emits updated values through the Flow when the preference changes
        TODO("Return Flow that emits current integer value and updates when changed")
    }

    override fun putInt(key: String, value: Int): Boolean {
        return try {
            sharedPreferences.edit().putInt(key, value).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error storing integer preference: $key", e)
            false
        }
    }

    override fun getLong(key: String, defaultValue: Long): Long {
        return try {
            sharedPreferences.getLong(key, defaultValue)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting long preference: $key", e)
            defaultValue
        }
    }

    override fun getLongFlow(key: String, defaultValue: Long): Flow<Long> {
        // Implementation uses SharedPreferences.OnSharedPreferenceChangeListener to observe changes
        // and emits updated values through the Flow when the preference changes
        TODO("Return Flow that emits current long value and updates when changed")
    }

    override fun putLong(key: String, value: Long): Boolean {
        return try {
            sharedPreferences.edit().putLong(key, value).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error storing long preference: $key", e)
            false
        }
    }

    override fun getFloat(key: String, defaultValue: Float): Float {
        return try {
            sharedPreferences.getFloat(key, defaultValue)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting float preference: $key", e)
            defaultValue
        }
    }

    override fun getFloatFlow(key: String, defaultValue: Float): Flow<Float> {
        // Implementation uses SharedPreferences.OnSharedPreferenceChangeListener to observe changes
        // and emits updated values through the Flow when the preference changes
        TODO("Return Flow that emits current float value and updates when changed")
    }

    override fun putFloat(key: String, value: Float): Boolean {
        return try {
            sharedPreferences.edit().putFloat(key, value).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error storing float preference: $key", e)
            false
        }
    }

    override fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        return try {
            sharedPreferences.getBoolean(key, defaultValue)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting boolean preference: $key", e)
            defaultValue
        }
    }

    override fun getBooleanFlow(key: String, defaultValue: Boolean): Flow<Boolean> {
        // Implementation uses SharedPreferences.OnSharedPreferenceChangeListener to observe changes
        // and emits updated values through the Flow when the preference changes
        TODO("Return Flow that emits current boolean value and updates when changed")
    }

    override fun putBoolean(key: String, value: Boolean): Boolean {
        return try {
            sharedPreferences.edit().putBoolean(key, value).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error storing boolean preference: $key", e)
            false
        }
    }

    override fun getStringSet(key: String, defaultValue: Set<String>?): Set<String>? {
        return try {
            sharedPreferences.getStringSet(key, defaultValue)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting string set preference: $key", e)
            defaultValue
        }
    }

    override fun getStringSetFlow(key: String, defaultValue: Set<String>?): Flow<Set<String>?> {
        // Implementation uses SharedPreferences.OnSharedPreferenceChangeListener to observe changes
        // and emits updated values through the Flow when the preference changes
        TODO("Return Flow that emits current string set and updates when changed")
    }

    override fun putStringSet(key: String, value: Set<String>?): Boolean {
        return try {
            sharedPreferences.edit().putStringSet(key, value).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error storing string set preference: $key", e)
            false
        }
    }

    override fun contains(key: String): Boolean {
        return try {
            sharedPreferences.contains(key)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error checking if preference contains key: $key", e)
            false
        }
    }

    override fun remove(key: String): Boolean {
        return try {
            sharedPreferences.edit().remove(key).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error removing preference: $key", e)
            false
        }
    }

    override fun clear(): Boolean {
        return try {
            sharedPreferences.edit().clear().apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error clearing preferences", e)
            false
        }
    }

    override fun registerOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener) {
        sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
    }

    override fun unregisterOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener) {
        sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
    }
}

/**
 * Factory for creating appropriate PreferenceManager instances for different preference types.
 * Provides centralized access to various preference stores used throughout the application.
 */
object PreferenceManagerFactory {
    
    private const val TAG = "PreferenceManagerFactory"
    
    /**
     * Creates a PreferenceManager for user preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for user preferences
     */
    fun createUserPreferences(context: Context): PreferenceManager {
        return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.USER_PREFS)
    }
    
    /**
     * Creates a PreferenceManager for authentication preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for authentication preferences
     */
    fun createAuthPreferences(context: Context): PreferenceManager {
        // Try to create an EncryptedPreferenceManager for secure storage
        // Fall back to StandardPreferenceManager if encryption is not available
        try {
            // In a real implementation, this would attempt to use EncryptedSharedPreferences
            // Fall back to standard implementation if not available
            return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.AUTH_PREFS)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Failed to create encrypted preferences, falling back to standard", e)
            return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.AUTH_PREFS)
        }
    }
    
    /**
     * Creates a PreferenceManager for notification preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for notification preferences
     */
    fun createNotificationPreferences(context: Context): PreferenceManager {
        return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.NOTIFICATION_PREFS)
    }
    
    /**
     * Creates a PreferenceManager for privacy preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for privacy preferences
     */
    fun createPrivacyPreferences(context: Context): PreferenceManager {
        // Try to create an EncryptedPreferenceManager for secure storage
        // Fall back to StandardPreferenceManager if encryption is not available
        try {
            // In a real implementation, this would attempt to use EncryptedSharedPreferences
            // Fall back to standard implementation if not available
            return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.PRIVACY_PREFS)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Failed to create encrypted preferences, falling back to standard", e)
            return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.PRIVACY_PREFS)
        }
    }
    
    /**
     * Creates a PreferenceManager for application preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for application preferences
     */
    fun createAppPreferences(context: Context): PreferenceManager {
        return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.APP_PREFS)
    }
    
    /**
     * Creates a PreferenceManager for journal preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for journal preferences
     */
    fun createJournalPreferences(context: Context): PreferenceManager {
        return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.JOURNAL_PREFS)
    }
    
    /**
     * Creates a PreferenceManager for tool preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for tool preferences
     */
    fun createToolPreferences(context: Context): PreferenceManager {
        return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.TOOL_PREFS)
    }
    
    /**
     * Creates a PreferenceManager for synchronization preferences.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for synchronization preferences
     */
    fun createSyncPreferences(context: Context): PreferenceManager {
        return StandardPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.SYNC_PREFS)
    }
}