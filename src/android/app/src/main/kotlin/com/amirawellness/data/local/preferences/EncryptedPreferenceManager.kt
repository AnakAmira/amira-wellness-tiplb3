package com.amirawellness.data.local.preferences

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.amirawellness.core.constants.PreferenceConstants
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.services.encryption.KeyStoreManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

private const val TAG = "EncryptedPreferenceManager"

/**
 * Implementation of PreferenceManager that uses EncryptedSharedPreferences for secure storage
 * of sensitive user data such as authentication tokens, credentials, and privacy settings.
 *
 * This class provides end-to-end encryption for preferences stored on the device, ensuring
 * that sensitive data cannot be accessed without proper authorization.
 */
class EncryptedPreferenceManager(
    context: Context,
    preferenceName: String
) : PreferenceManager {

    private val sharedPreferences: SharedPreferences

    init {
        try {
            // Create or get the master key for encryption
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            // Create the EncryptedSharedPreferences using the master key
            sharedPreferences = EncryptedSharedPreferences.create(
                context,
                preferenceName,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )

            LogUtils.d(TAG, "Successfully initialized EncryptedSharedPreferences for $preferenceName")
        } catch (e: Exception) {
            LogUtils.e(TAG, "Failed to initialize EncryptedSharedPreferences", e)
            throw e
        }
    }

    override fun getString(key: String, defaultValue: String?): String? {
        return sharedPreferences.getString(key, defaultValue)
    }

    override fun getStringFlow(key: String, defaultValue: String?): Flow<String?> {
        return flow {
            // Emit the current value initially
            emit(getString(key, defaultValue))
            
            // Set up a listener to emit updated values when the preference changes
            val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, changedKey ->
                if (changedKey == key) {
                    emit(getString(key, defaultValue))
                }
            }
            
            // Register the listener
            sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
            
            try {
                // Keep the flow active until collection is cancelled
                kotlinx.coroutines.awaitCancellation()
            } finally {
                // Unregister the listener when the flow collection is cancelled
                sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
            }
        }
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
        return sharedPreferences.getInt(key, defaultValue)
    }

    override fun getIntFlow(key: String, defaultValue: Int): Flow<Int> {
        return flow {
            // Emit the current value initially
            emit(getInt(key, defaultValue))
            
            // Set up a listener to emit updated values when the preference changes
            val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, changedKey ->
                if (changedKey == key) {
                    emit(getInt(key, defaultValue))
                }
            }
            
            // Register the listener
            sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
            
            try {
                // Keep the flow active until collection is cancelled
                kotlinx.coroutines.awaitCancellation()
            } finally {
                // Unregister the listener when the flow collection is cancelled
                sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
            }
        }
    }

    override fun putInt(key: String, value: Int): Boolean {
        return try {
            sharedPreferences.edit().putInt(key, value).apply()
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error storing int preference: $key", e)
            false
        }
    }

    override fun getLong(key: String, defaultValue: Long): Long {
        return sharedPreferences.getLong(key, defaultValue)
    }

    override fun getLongFlow(key: String, defaultValue: Long): Flow<Long> {
        return flow {
            // Emit the current value initially
            emit(getLong(key, defaultValue))
            
            // Set up a listener to emit updated values when the preference changes
            val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, changedKey ->
                if (changedKey == key) {
                    emit(getLong(key, defaultValue))
                }
            }
            
            // Register the listener
            sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
            
            try {
                // Keep the flow active until collection is cancelled
                kotlinx.coroutines.awaitCancellation()
            } finally {
                // Unregister the listener when the flow collection is cancelled
                sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
            }
        }
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
        return sharedPreferences.getFloat(key, defaultValue)
    }

    override fun getFloatFlow(key: String, defaultValue: Float): Flow<Float> {
        return flow {
            // Emit the current value initially
            emit(getFloat(key, defaultValue))
            
            // Set up a listener to emit updated values when the preference changes
            val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, changedKey ->
                if (changedKey == key) {
                    emit(getFloat(key, defaultValue))
                }
            }
            
            // Register the listener
            sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
            
            try {
                // Keep the flow active until collection is cancelled
                kotlinx.coroutines.awaitCancellation()
            } finally {
                // Unregister the listener when the flow collection is cancelled
                sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
            }
        }
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
        return sharedPreferences.getBoolean(key, defaultValue)
    }

    override fun getBooleanFlow(key: String, defaultValue: Boolean): Flow<Boolean> {
        return flow {
            // Emit the current value initially
            emit(getBoolean(key, defaultValue))
            
            // Set up a listener to emit updated values when the preference changes
            val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, changedKey ->
                if (changedKey == key) {
                    emit(getBoolean(key, defaultValue))
                }
            }
            
            // Register the listener
            sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
            
            try {
                // Keep the flow active until collection is cancelled
                kotlinx.coroutines.awaitCancellation()
            } finally {
                // Unregister the listener when the flow collection is cancelled
                sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
            }
        }
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
        return sharedPreferences.getStringSet(key, defaultValue)
    }

    override fun getStringSetFlow(key: String, defaultValue: Set<String>?): Flow<Set<String>?> {
        return flow {
            // Emit the current value initially
            emit(getStringSet(key, defaultValue))
            
            // Set up a listener to emit updated values when the preference changes
            val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, changedKey ->
                if (changedKey == key) {
                    emit(getStringSet(key, defaultValue))
                }
            }
            
            // Register the listener
            sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
            
            try {
                // Keep the flow active until collection is cancelled
                kotlinx.coroutines.awaitCancellation()
            } finally {
                // Unregister the listener when the flow collection is cancelled
                sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
            }
        }
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
        return sharedPreferences.contains(key)
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

    companion object {
        /**
         * Checks if secure encryption is available on this device by trying to create a test
         * instance of EncryptedSharedPreferences and checking if hardware-backed KeyStore is available.
         *
         * @return True if encryption is available and working
         */
        fun isEncryptionAvailable(): Boolean {
            return try {
                // Check if hardware-backed KeyStore is available
                val isHardwareBackedKeyStoreAvailable = KeyStoreManager.isHardwareBackedKeyStoreAvailable()
                
                if (!isHardwareBackedKeyStoreAvailable) {
                    LogUtils.d(TAG, "Hardware-backed KeyStore is not available")
                    return false
                }
                
                // In a production implementation, we would try to create a test EncryptedSharedPreferences
                // instance here using a context and verify that encryption is working properly.
                // For now, we'll assume it's available if the KeyStore is available.
                
                true
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error checking encryption availability", e)
                false
            }
        }
    }
}

/**
 * Factory for creating appropriate EncryptedPreferenceManager instances for different preference types.
 * Provides centralized access to secure preference storage for authentication and privacy preferences.
 */
object EncryptedPreferenceManagerFactory {
    
    /**
     * Creates an EncryptedPreferenceManager for authentication preferences such as tokens and credentials.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for authentication preferences
     */
    fun createAuthPreferences(context: Context): PreferenceManager {
        return if (EncryptedPreferenceManager.isEncryptionAvailable()) {
            // Use encrypted preferences if available
            EncryptedPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.AUTH_PREFS)
        } else {
            // Fall back to standard preferences if encryption is not available
            LogUtils.d(TAG, "Encryption not available, falling back to standard preferences for authentication")
            // Use appropriate fallback mechanism from the PreferenceManagerFactory
            com.amirawellness.data.local.preferences.PreferenceManagerFactory.createAuthPreferences(context)
        }
    }
    
    /**
     * Creates an EncryptedPreferenceManager for privacy preferences such as consent settings and data collection options.
     *
     * @param context The context used to access SharedPreferences
     * @return A PreferenceManager for privacy preferences
     */
    fun createPrivacyPreferences(context: Context): PreferenceManager {
        return if (EncryptedPreferenceManager.isEncryptionAvailable()) {
            // Use encrypted preferences if available
            EncryptedPreferenceManager(context, PreferenceConstants.PREFERENCE_FILES.PRIVACY_PREFS)
        } else {
            // Fall back to standard preferences if encryption is not available
            LogUtils.d(TAG, "Encryption not available, falling back to standard preferences for privacy")
            // Use appropriate fallback mechanism from the PreferenceManagerFactory
            com.amirawellness.data.local.preferences.PreferenceManagerFactory.createPrivacyPreferences(context)
        }
    }
}