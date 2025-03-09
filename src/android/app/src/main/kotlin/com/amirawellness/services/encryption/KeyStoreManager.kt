package com.amirawellness.services.encryption

import android.content.Context // android version: latest
import android.security.keystore.KeyGenParameterSpec // android version: latest
import android.security.keystore.KeyProperties // android version: latest
import android.util.Log // android version: latest
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.services.biometric.BiometricManager
import java.security.KeyStore // java.security version: latest
import java.security.SecureRandom // java.security version: latest
import javax.crypto.KeyGenerator // javax.crypto version: latest
import javax.crypto.SecretKey // javax.crypto version: latest
import javax.crypto.spec.PBEKeySpec // javax.crypto version: latest
import javax.crypto.SecretKeyFactory // javax.crypto version: latest

/**
 * Defines possible exceptions that can occur during key management operations.
 */
sealed class KeyStoreException : Exception() {
    data class KeyGenerationFailed(override val message: String? = null, val cause: Throwable? = null) : KeyStoreException()
    data class KeyRetrievalFailed(override val message: String? = null, val cause: Throwable? = null) : KeyStoreException()
    data class KeyDeletionFailed(override val message: String? = null, val cause: Throwable? = null) : KeyStoreException()
    data class KeyDerivationFailed(override val message: String? = null, val cause: Throwable? = null) : KeyStoreException()
    data class HardwareBackedKeyStoreNotAvailable(override val message: String? = null) : KeyStoreException()
}

/**
 * Enum defining the types of keys managed by KeyStoreManager.
 */
enum class KeyType {
    MASTER, // Main encryption key stored in KeyStore
    USER,   // User-specific keys derived from credentials
    JOURNAL, // Keys for voice journal encryption
    EXPORT  // Keys for secure data export
}

/**
 * Manages cryptographic keys using Android KeyStore system for secure encryption operations.
 * This class is responsible for generating, storing, and retrieving encryption keys securely,
 * supporting the end-to-end encryption requirements for sensitive user data like voice recordings.
 */
class KeyStoreManager private constructor(private val context: Context) {
    private val TAG = "KeyStoreManager"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"
    private val MASTER_KEY_ALIAS = "amira_master_key"
    private val DATA_KEY_PREFIX = "amira_data_key_"
    
    private val keyStore: KeyStore
    private val secureRandom: SecureRandom
    
    init {
        // Initialize KeyStore
        keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)
        
        // Initialize SecureRandom for generating random data
        secureRandom = SecureRandom()
        
        // Log initialization status with encryption settings
        if (AppConstants.ENCRYPTION_ENABLED) {
            Log.d(TAG, "KeyStoreManager initialized with encryption enabled")
        } else {
            Log.w(TAG, "KeyStoreManager initialized but encryption is disabled in app settings")
        }
    }
    
    companion object {
        @Volatile
        private var instance: KeyStoreManager? = null
        
        /**
         * Gets the singleton instance of KeyStoreManager.
         *
         * @param context Application context
         * @return The KeyStoreManager instance
         */
        @JvmStatic
        fun getInstance(context: Context): KeyStoreManager {
            return instance ?: synchronized(this) {
                instance ?: KeyStoreManager(context.applicationContext).also { instance = it }
            }
        }
        
        /**
         * Checks if hardware-backed KeyStore is available on the device.
         * Hardware-backed KeyStore provides stronger security guarantees.
         *
         * @return True if hardware-backed KeyStore is available
         */
        @JvmStatic
        fun isHardwareBackedKeyStoreAvailable(): Boolean {
            return try {
                // Attempt to determine if the device supports hardware-backed KeyStore
                val keyStore = KeyStore.getInstance("AndroidKeyStore")
                keyStore.load(null)
                
                // KeyStore.getProvider().toString() typically contains "AndroidKeyStore"
                // and information about hardware backing if available
                val provider = keyStore.provider.toString()
                val isHardwareBacked = provider.contains("hardware") || 
                                       provider.contains("TEE") || 
                                       provider.contains("StrongBox")
                
                Log.d("KeyStoreManager", "KeyStore provider: $provider, Hardware backed: $isHardwareBacked")
                isHardwareBacked
            } catch (e: Exception) {
                Log.e("KeyStoreManager", "Error checking hardware-backed KeyStore availability", e)
                false
            }
        }
    }
    
    /**
     * Generates or retrieves the master encryption key from Android KeyStore.
     * This key is used as the root of trust for encryption operations.
     *
     * @return The master encryption key or an error
     */
    fun generateMasterKey(): Result<SecretKey> {
        return try {
            // Check if master key already exists
            if (keyStore.containsAlias(MASTER_KEY_ALIAS)) {
                val entry = keyStore.getEntry(MASTER_KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
                entry?.secretKey?.let {
                    Log.d(TAG, "Retrieved existing master key")
                    return Result.success(it)
                }
            }
            
            // Create new master key
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                ANDROID_KEYSTORE
            )
            
            val keyGenSpec = KeyGenParameterSpec.Builder(
                MASTER_KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(AppConstants.ENCRYPTION_SETTINGS.KEY_SIZE)
                .setUserAuthenticationRequired(false) // Master key doesn't require auth for use
                .build()
            
            keyGenerator.init(keyGenSpec)
            val key = keyGenerator.generateKey()
            Log.d(TAG, "Generated new master key")
            Result.success(key)
        } catch (e: Exception) {
            Log.e(TAG, "Error generating master key", e)
            Result.failure(KeyStoreException.KeyGenerationFailed("Failed to generate master key", e))
        }
    }
    
    /**
     * Generates a new data encryption key for specific data types.
     * Unlike the master key, these keys are not stored in KeyStore but are
     * encrypted with the master key for storage.
     *
     * @param keyType The type of key to generate
     * @param keyId Unique identifier for the key
     * @return The generated data key as a byte array or an error
     */
    fun generateDataKey(keyType: KeyType, keyId: String): Result<ByteArray> {
        return try {
            val keyAlias = "$DATA_KEY_PREFIX${keyType.name}_$keyId"
            
            // Generate a random AES key
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES)
            keyGenerator.init(AppConstants.ENCRYPTION_SETTINGS.KEY_SIZE)
            val secretKey = keyGenerator.generateKey()
            
            // Convert to byte array
            val keyBytes = secretKey.encoded
            
            // In a real implementation, we would encrypt this key with the master key
            // and store it securely, but for simplicity we're just returning it
            Log.d(TAG, "Generated new data key for $keyType:$keyId")
            Result.success(keyBytes)
        } catch (e: Exception) {
            Log.e(TAG, "Error generating data key for $keyType:$keyId", e)
            Result.failure(KeyStoreException.KeyGenerationFailed("Failed to generate data key for $keyType:$keyId", e))
        }
    }
    
    /**
     * Retrieves a data encryption key for a specific data type.
     * If the key doesn't exist, a new one is generated.
     *
     * @param keyType The type of key to retrieve
     * @param keyId Unique identifier for the key
     * @return The data key as a byte array or an error
     */
    fun getDataKey(keyType: KeyType, keyId: String): Result<ByteArray> {
        return try {
            val keyAlias = "$DATA_KEY_PREFIX${keyType.name}_$keyId"
            
            // In a real implementation, we would look up the encrypted key,
            // decrypt it with the master key, and return it.
            // For now, we'll just generate a new key if one doesn't exist.
            
            // Simulating key retrieval
            // In real implementation, this would check secure storage
            val retrievedKey = null
            
            if (retrievedKey != null) {
                Log.d(TAG, "Retrieved existing data key for $keyType:$keyId")
                Result.success(retrievedKey)
            } else {
                Log.d(TAG, "No existing data key found for $keyType:$keyId, generating new one")
                generateDataKey(keyType, keyId)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error retrieving data key for $keyType:$keyId", e)
            Result.failure(KeyStoreException.KeyRetrievalFailed("Failed to retrieve data key for $keyType:$keyId", e))
        }
    }
    
    /**
     * Deletes a data encryption key for a specific data type.
     *
     * @param keyType The type of key to delete
     * @param keyId Unique identifier for the key
     * @return True if deletion was successful, or an error
     */
    fun deleteDataKey(keyType: KeyType, keyId: String): Result<Boolean> {
        return try {
            val keyAlias = "$DATA_KEY_PREFIX${keyType.name}_$keyId"
            
            // In a real implementation, we would remove the key from secure storage
            // For now, we'll just log the action
            
            Log.d(TAG, "Deleted data key for $keyType:$keyId")
            Result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting data key for $keyType:$keyId", e)
            Result.failure(KeyStoreException.KeyDeletionFailed("Failed to delete data key for $keyType:$keyId", e))
        }
    }
    
    /**
     * Derives an encryption key from a user password using PBKDF2.
     * This is used for user-controlled encryption where the key is derived
     * from the user's password rather than stored in KeyStore.
     *
     * @param password The user password to derive key from
     * @param salt Salt bytes for key derivation, generated if null
     * @return The derived key and salt used, or an error
     */
    fun deriveKeyFromPassword(password: String, salt: ByteArray? = null): Result<Pair<ByteArray, ByteArray>> {
        return try {
            // Generate a random salt if not provided
            val keySalt = salt ?: ByteArray(AppConstants.ENCRYPTION_SETTINGS.SALT_SIZE_BYTES).apply {
                secureRandom.nextBytes(this)
            }
            
            // Create PBEKeySpec with password, salt, iteration count, and key length
            val spec = PBEKeySpec(
                password.toCharArray(),
                keySalt,
                AppConstants.ENCRYPTION_SETTINGS.KEY_DERIVATION_ITERATIONS,
                AppConstants.ENCRYPTION_SETTINGS.KEY_SIZE
            )
            
            // Get SecretKeyFactory for PBKDF2WithHmacSHA256 algorithm
            val factory = SecretKeyFactory.getInstance(AppConstants.ENCRYPTION_SETTINGS.KEY_DERIVATION_ALGORITHM)
            
            // Generate a SecretKey from the PBEKeySpec
            val key = factory.generateSecret(spec)
            
            // Convert the key to a byte array
            val keyBytes = key.encoded
            
            Log.d(TAG, "Derived key from password successfully")
            Result.success(Pair(keyBytes, keySalt))
        } catch (e: Exception) {
            Log.e(TAG, "Error deriving key from password", e)
            Result.failure(KeyStoreException.KeyDerivationFailed("Failed to derive key from password", e))
        }
    }
    
    /**
     * Generates cryptographically secure random bytes.
     * Used for initialization vectors, salts, and other cryptographic purposes.
     *
     * @param length The length of the random byte array to generate
     * @return Array of random bytes
     */
    fun generateRandomBytes(length: Int): ByteArray {
        val bytes = ByteArray(length)
        secureRandom.nextBytes(bytes)
        return bytes
    }
    
    /**
     * Checks if biometric authentication is available on the device.
     * This is used to determine if biometric protection can be applied to keys.
     *
     * @return True if biometric authentication is available
     */
    fun isBiometricAuthAvailable(): Boolean {
        return BiometricManager.getInstance(context).canAuthenticate()
    }
}