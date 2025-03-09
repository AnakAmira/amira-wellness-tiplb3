package com.amirawellness.services.encryption

import com.amirawellness.services.encryption.KeyStoreManager
import com.amirawellness.services.encryption.KeyType
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.core.utils.AudioUtils
import android.content.Context // version: latest
import android.util.Base64 // version: latest
import java.io.File // version: latest
import java.io.FileInputStream // version: latest
import java.io.FileOutputStream // version: latest
import javax.crypto.Cipher // version: latest
import javax.crypto.spec.GCMParameterSpec // version: latest
import javax.crypto.spec.SecretKeySpec // version: latest
import java.security.SecureRandom // version: latest

private const val TAG = "EncryptionManager"
private const val BUFFER_SIZE = 8192

sealed class EncryptionException : Exception() {
    data class EncryptionFailed(override val message: String? = null, val cause: Throwable? = null) : EncryptionException()
    data class DecryptionFailed(override val message: String? = null, val cause: Throwable? = null) : EncryptionException()
    data class InvalidKey(override val message: String? = null) : EncryptionException()
    data class FileOperationFailed(override val message: String? = null, val cause: Throwable? = null) : EncryptionException()
}

/**
 * Manages encryption and decryption operations for sensitive data in the Amira Wellness application.
 * Implements AES-256-GCM encryption for end-to-end encryption of voice recordings and other sensitive data.
 */
class EncryptionManager private constructor(private val context: Context) {
    
    private val keyStoreManager = KeyStoreManager.getInstance(context)
    
    init {
        LogUtils.d(TAG, "EncryptionManager initialized, encryption enabled: ${AppConstants.ENCRYPTION_ENABLED}")
    }
    
    companion object {
        @Volatile
        private var instance: EncryptionManager? = null
        
        /**
         * Gets the singleton instance of EncryptionManager
         *
         * @param context Application context
         * @return The EncryptionManager instance
         */
        @JvmStatic
        fun getInstance(context: Context): EncryptionManager {
            return instance ?: synchronized(this) {
                instance ?: EncryptionManager(context.applicationContext).also { instance = it }
            }
        }
    }
    
    /**
     * Encrypts data using AES-256-GCM
     *
     * @param data Data to encrypt
     * @param key Encryption key
     * @param associatedData Additional authenticated data (optional)
     * @return Encrypted data result
     */
    fun encrypt(data: ByteArray, key: ByteArray, associatedData: ByteArray? = null): Result<EncryptedData> {
        if (key.isEmpty()) {
            return Result.failure(EncryptionException.InvalidKey("Encryption key cannot be empty"))
        }
        
        try {
            // Generate random IV (Initialization Vector)
            val iv = ByteArray(AppConstants.ENCRYPTION_SETTINGS.IV_SIZE)
            SecureRandom().nextBytes(iv)
            
            // Create secret key from provided key bytes
            val secretKey = SecretKeySpec(key, "AES")
            
            // Create GCM parameters with IV and tag length
            val gcmParameterSpec = GCMParameterSpec(
                AppConstants.ENCRYPTION_SETTINGS.GCM_TAG_LENGTH,
                iv
            )
            
            // Initialize cipher for encryption
            val cipher = Cipher.getInstance(AppConstants.ENCRYPTION_SETTINGS.ALGORITHM)
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, gcmParameterSpec)
            
            // Add associated authenticated data if provided
            if (associatedData != null) {
                cipher.updateAAD(associatedData)
            }
            
            // Encrypt the data
            val encryptedBytes = cipher.doFinal(data)
            
            // Return encrypted data with IV
            return Result.success(EncryptedData(encryptedBytes, iv))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Encryption failed", e)
            return Result.failure(EncryptionException.EncryptionFailed("Failed to encrypt data", e))
        }
    }
    
    /**
     * Decrypts data using AES-256-GCM
     *
     * @param encryptedData Encrypted data to decrypt
     * @param key Decryption key
     * @param associatedData Additional authenticated data (optional)
     * @return Decrypted data result
     */
    fun decrypt(encryptedData: EncryptedData, key: ByteArray, associatedData: ByteArray? = null): Result<ByteArray> {
        if (key.isEmpty()) {
            return Result.failure(EncryptionException.InvalidKey("Decryption key cannot be empty"))
        }
        
        try {
            // Create secret key from provided key bytes
            val secretKey = SecretKeySpec(key, "AES")
            
            // Create GCM parameters with IV and tag length
            val gcmParameterSpec = GCMParameterSpec(
                AppConstants.ENCRYPTION_SETTINGS.GCM_TAG_LENGTH,
                encryptedData.iv
            )
            
            // Initialize cipher for decryption
            val cipher = Cipher.getInstance(AppConstants.ENCRYPTION_SETTINGS.ALGORITHM)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, gcmParameterSpec)
            
            // Add associated authenticated data if provided
            if (associatedData != null) {
                cipher.updateAAD(associatedData)
            }
            
            // Decrypt the data
            val decryptedData = cipher.doFinal(encryptedData.encryptedBytes)
            
            return Result.success(decryptedData)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Decryption failed", e)
            return Result.failure(EncryptionException.DecryptionFailed("Failed to decrypt data", e))
        }
    }
    
    /**
     * Encrypts a file using AES-256-GCM
     *
     * @param inputFile File to encrypt
     * @param outputFile File to write encrypted data to
     * @param key Encryption key
     * @return Success or error result
     */
    fun encryptFile(inputFile: File, outputFile: File, key: ByteArray): Result<Boolean> {
        // Check if the input file exists and is valid
        if (!inputFile.exists() || !inputFile.canRead()) {
            return Result.failure(EncryptionException.FileOperationFailed("Input file does not exist or cannot be read"))
        }
        
        if (key.isEmpty()) {
            return Result.failure(EncryptionException.InvalidKey("Encryption key cannot be empty"))
        }
        
        var inputStream: FileInputStream? = null
        var outputStream: FileOutputStream? = null
        
        try {
            // Generate random IV
            val iv = ByteArray(AppConstants.ENCRYPTION_SETTINGS.IV_SIZE)
            SecureRandom().nextBytes(iv)
            
            // Create secret key from provided key bytes
            val secretKey = SecretKeySpec(key, "AES")
            
            // Create GCM parameters with IV and tag length
            val gcmParameterSpec = GCMParameterSpec(
                AppConstants.ENCRYPTION_SETTINGS.GCM_TAG_LENGTH,
                iv
            )
            
            // Initialize cipher for encryption
            val cipher = Cipher.getInstance(AppConstants.ENCRYPTION_SETTINGS.ALGORITHM)
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, gcmParameterSpec)
            
            // Set up the streams
            inputStream = FileInputStream(inputFile)
            outputStream = FileOutputStream(outputFile)
            
            // Write the IV to the beginning of the output file
            outputStream.write(iv)
            
            // Read input file in chunks and encrypt to output file
            val buffer = ByteArray(BUFFER_SIZE)
            var bytesRead: Int
            
            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                val encryptedChunk = cipher.update(buffer, 0, bytesRead)
                if (encryptedChunk != null) {
                    outputStream.write(encryptedChunk)
                }
            }
            
            // Write the final block
            val finalBlock = cipher.doFinal()
            if (finalBlock != null) {
                outputStream.write(finalBlock)
            }
            
            LogUtils.d(TAG, "File encrypted successfully: ${inputFile.name} -> ${outputFile.name}")
            return Result.success(true)
        } catch (e: Exception) {
            when (e) {
                is java.io.IOException -> {
                    LogUtils.e(TAG, "File I/O error during encryption", e)
                    return Result.failure(EncryptionException.FileOperationFailed("File I/O error during encryption", e))
                }
                else -> {
                    LogUtils.e(TAG, "Encryption error", e)
                    return Result.failure(EncryptionException.EncryptionFailed("Failed to encrypt file", e))
                }
            }
        } finally {
            // Close streams
            try {
                inputStream?.close()
                outputStream?.close()
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error closing streams", e)
            }
        }
    }
    
    /**
     * Decrypts a file using AES-256-GCM
     *
     * @param inputFile File to decrypt
     * @param outputFile File to write decrypted data to
     * @param key Decryption key
     * @return Success or error result
     */
    fun decryptFile(inputFile: File, outputFile: File, key: ByteArray): Result<Boolean> {
        // Check if the input file exists and is valid
        if (!inputFile.exists() || !inputFile.canRead()) {
            return Result.failure(EncryptionException.FileOperationFailed("Input file does not exist or cannot be read"))
        }
        
        if (key.isEmpty()) {
            return Result.failure(EncryptionException.InvalidKey("Decryption key cannot be empty"))
        }
        
        var inputStream: FileInputStream? = null
        var outputStream: FileOutputStream? = null
        
        try {
            // Set up input stream
            inputStream = FileInputStream(inputFile)
            
            // Read the IV from the beginning of the file
            val iv = ByteArray(AppConstants.ENCRYPTION_SETTINGS.IV_SIZE)
            if (inputStream.read(iv) != iv.size) {
                return Result.failure(EncryptionException.DecryptionFailed("Failed to read IV from encrypted file"))
            }
            
            // Create secret key from provided key bytes
            val secretKey = SecretKeySpec(key, "AES")
            
            // Create GCM parameters with IV and tag length
            val gcmParameterSpec = GCMParameterSpec(
                AppConstants.ENCRYPTION_SETTINGS.GCM_TAG_LENGTH,
                iv
            )
            
            // Initialize cipher for decryption
            val cipher = Cipher.getInstance(AppConstants.ENCRYPTION_SETTINGS.ALGORITHM)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, gcmParameterSpec)
            
            // Set up output stream
            outputStream = FileOutputStream(outputFile)
            
            // Read encrypted data in chunks, decrypt, and write to output file
            val buffer = ByteArray(BUFFER_SIZE)
            var bytesRead: Int
            
            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                val decryptedChunk = cipher.update(buffer, 0, bytesRead)
                if (decryptedChunk != null) {
                    outputStream.write(decryptedChunk)
                }
            }
            
            // Process final block
            val finalBlock = cipher.doFinal()
            if (finalBlock.isNotEmpty()) {
                outputStream.write(finalBlock)
            }
            
            LogUtils.d(TAG, "File decrypted successfully: ${inputFile.name} -> ${outputFile.name}")
            return Result.success(true)
        } catch (e: Exception) {
            when (e) {
                is java.io.IOException -> {
                    LogUtils.e(TAG, "File I/O error during decryption", e)
                    return Result.failure(EncryptionException.FileOperationFailed("File I/O error during decryption", e))
                }
                else -> {
                    LogUtils.e(TAG, "Decryption error", e)
                    return Result.failure(EncryptionException.DecryptionFailed("Failed to decrypt file", e))
                }
            }
        } finally {
            // Close streams
            try {
                inputStream?.close()
                outputStream?.close()
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error closing streams", e)
            }
        }
    }
    
    /**
     * Encrypts journal data using a journal-specific key
     *
     * @param journalData Journal data to encrypt
     * @param journalId Unique identifier for the journal
     * @return Encrypted journal data result
     */
    fun encryptJournal(journalData: ByteArray, journalId: String): Result<EncryptedData> {
        try {
            // Get or generate a journal-specific key
            val keyResult = keyStoreManager.getDataKey(KeyType.JOURNAL, journalId)
            
            val key = keyResult.getOrElse {
                // If getting the key fails, try to generate a new one
                val generateResult = keyStoreManager.generateDataKey(KeyType.JOURNAL, journalId)
                generateResult.getOrElse { error ->
                    LogUtils.e(TAG, "Failed to get or generate journal key", error)
                    return Result.failure(EncryptionException.EncryptionFailed("Failed to get or generate journal key", error))
                }
            }
            
            // Use the journal ID as associated data for additional security
            val associatedData = journalId.toByteArray()
            
            // Encrypt the journal data
            return encrypt(journalData, key, associatedData)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Journal encryption failed", e)
            return Result.failure(EncryptionException.EncryptionFailed("Failed to encrypt journal", e))
        }
    }
    
    /**
     * Decrypts journal data using a journal-specific key
     *
     * @param encryptedData Encrypted journal data
     * @param journalId Unique identifier for the journal
     * @return Decrypted journal data result
     */
    fun decryptJournal(encryptedData: EncryptedData, journalId: String): Result<ByteArray> {
        try {
            // Get the journal-specific key
            val keyResult = keyStoreManager.getDataKey(KeyType.JOURNAL, journalId)
            
            val key = keyResult.getOrElse {
                LogUtils.e(TAG, "Failed to get journal key", it)
                return Result.failure(EncryptionException.DecryptionFailed("Failed to get journal key", it))
            }
            
            // Use the journal ID as associated data for additional security
            val associatedData = journalId.toByteArray()
            
            // Decrypt the journal data
            return decrypt(encryptedData, key, associatedData)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Journal decryption failed", e)
            return Result.failure(EncryptionException.DecryptionFailed("Failed to decrypt journal", e))
        }
    }
    
    /**
     * Encrypts data using a user-provided password
     *
     * @param data Data to encrypt
     * @param password User-provided password
     * @return Password-encrypted data result
     */
    fun encryptWithPassword(data: ByteArray, password: String): Result<PasswordEncryptedData> {
        if (password.isEmpty()) {
            return Result.failure(EncryptionException.InvalidKey("Password cannot be empty"))
        }
        
        try {
            // Derive an encryption key from the password
            val keyDerivationResult = keyStoreManager.deriveKeyFromPassword(password)
            
            val (key, salt) = keyDerivationResult.getOrElse {
                LogUtils.e(TAG, "Key derivation failed", it)
                return Result.failure(EncryptionException.EncryptionFailed("Failed to derive key from password", it))
            }
            
            // Encrypt the data with the derived key
            val encryptResult = encrypt(data, key)
            
            val encryptedData = encryptResult.getOrElse {
                return Result.failure(it as EncryptionException)
            }
            
            // Return the encrypted data with the salt
            return Result.success(PasswordEncryptedData(encryptedData, salt))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Password-based encryption failed", e)
            return Result.failure(EncryptionException.EncryptionFailed("Failed to encrypt with password", e))
        }
    }
    
    /**
     * Decrypts data using a user-provided password
     *
     * @param encryptedData Password-encrypted data
     * @param password User-provided password
     * @return Decrypted data result
     */
    fun decryptWithPassword(encryptedData: PasswordEncryptedData, password: String): Result<ByteArray> {
        if (password.isEmpty()) {
            return Result.failure(EncryptionException.InvalidKey("Password cannot be empty"))
        }
        
        try {
            // Derive the decryption key from the password and stored salt
            val keyDerivationResult = keyStoreManager.deriveKeyFromPassword(password, encryptedData.salt)
            
            val (key, _) = keyDerivationResult.getOrElse {
                LogUtils.e(TAG, "Key derivation failed", it)
                return Result.failure(EncryptionException.DecryptionFailed("Failed to derive key from password", it))
            }
            
            // Decrypt the data with the derived key
            return decrypt(encryptedData.encryptedData, key)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Password-based decryption failed", e)
            return Result.failure(EncryptionException.DecryptionFailed("Failed to decrypt with password", e))
        }
    }
    
    /**
     * Encodes binary data to Base64 string
     *
     * @param data Binary data to encode
     * @return Base64 encoded string
     */
    fun encodeToBase64(data: ByteArray): String {
        return Base64.encodeToString(data, Base64.NO_WRAP)
    }
    
    /**
     * Decodes Base64 string to binary data
     *
     * @param base64String Base64 encoded string
     * @return Decoded binary data
     */
    fun decodeFromBase64(base64String: String): ByteArray {
        return Base64.decode(base64String, Base64.NO_WRAP)
    }
}

/**
 * Data class representing encrypted data with metadata
 */
data class EncryptedData(
    val encryptedBytes: ByteArray,
    val iv: ByteArray,
    val timestamp: Long = System.currentTimeMillis()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as EncryptedData

        if (!encryptedBytes.contentEquals(other.encryptedBytes)) return false
        if (!iv.contentEquals(other.iv)) return false
        if (timestamp != other.timestamp) return false

        return true
    }

    override fun hashCode(): Int {
        var result = encryptedBytes.contentHashCode()
        result = 31 * result + iv.contentHashCode()
        result = 31 * result + timestamp.hashCode()
        return result
    }
}

/**
 * Data class representing password-encrypted data with salt
 */
data class PasswordEncryptedData(
    val encryptedData: EncryptedData,
    val salt: ByteArray
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as PasswordEncryptedData

        if (encryptedData != other.encryptedData) return false
        if (!salt.contentEquals(other.salt)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = encryptedData.hashCode()
        result = 31 * result + salt.contentHashCode()
        return result
    }
}