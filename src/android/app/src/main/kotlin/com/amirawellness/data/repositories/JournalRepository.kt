package com.amirawellness.data.repositories

import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.AudioMetadata
import com.amirawellness.data.local.dao.JournalDao
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.dto.JournalDto
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.services.encryption.EncryptionManager
import com.amirawellness.services.encryption.EncryptedData
import com.amirawellness.core.utils.LogUtils
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.Date

private const val TAG = "JournalRepository"

/**
 * Repository implementation for managing voice journal entries in the Amira Wellness Android application.
 * This class serves as the single source of truth for journal data, coordinating between local database
 * storage and remote API services. It handles CRUD operations for journals, audio metadata, and implements
 * offline-first functionality with synchronization capabilities.
 */
@Singleton
class JournalRepository @Inject constructor(
    private val journalDao: JournalDao,
    private val apiService: ApiService,
    private val networkMonitor: NetworkMonitor
) {
    private val encryptionManager = EncryptionManager.getInstance()

    /**
     * Creates a new journal entry in the local database and syncs with remote if online
     *
     * @param journal The journal entry to create
     * @return Result containing the created journal or an error
     */
    suspend fun createJournal(journal: Journal): Result<Journal> {
        return try {
            LogUtils.d(TAG, "Creating journal entry: ${journal.id}")
            
            // Insert into local database
            journalDao.insertJournal(journal)
            
            // Insert audio metadata if available
            journal.audioMetadata?.let { metadata ->
                journalDao.insertAudioMetadata(metadata)
            }
            
            // Try to sync with server if online and has audio file
            if (networkMonitor.isOnline() && journal.localFilePath != null) {
                try {
                    LogUtils.d(TAG, "Online - uploading journal to server")
                    val dto = journal.toJournalDto()
                    val responseDto = apiService.createJournal(dto)
                    
                    // Update local entry with remote data
                    val updatedJournal = journal.withUpdatedUploadStatus(true, responseDto.storagePath)
                    journalDao.updateJournal(updatedJournal)
                    
                    return Result.success(updatedJournal)
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Failed to upload journal to server", e)
                    // Continue with local journal - will sync later
                }
            } else {
                LogUtils.d(TAG, "Offline - journal will be synchronized when online")
            }
            
            Result.success(journal)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error creating journal", e)
            Result.failure(e)
        }
    }
    
    /**
     * Gets a journal entry by its ID
     *
     * @param journalId The unique identifier of the journal entry
     * @return Flow emitting the journal entry or null if not found
     */
    fun getJournal(journalId: String): Flow<Journal?> {
        return journalDao.getJournalById(journalId)
            .catch { e ->
                LogUtils.e(TAG, "Error getting journal: $journalId", e)
                throw e
            }
    }
    
    /**
     * Gets all journal entries for a specific user
     *
     * @param userId The ID of the user
     * @return Flow emitting the list of journal entries
     */
    fun getJournalsByUser(userId: String): Flow<List<Journal>> {
        return journalDao.getJournalsByUserId(userId)
            .catch { e ->
                LogUtils.e(TAG, "Error getting journals for user: $userId", e)
                throw e
            }
    }
    
    /**
     * Gets favorite journal entries for a specific user
     *
     * @param userId The ID of the user
     * @return Flow emitting the list of favorite journal entries
     */
    fun getFavoriteJournals(userId: String): Flow<List<Journal>> {
        return journalDao.getFavoriteJournals(userId)
            .catch { e ->
                LogUtils.e(TAG, "Error getting favorite journals for user: $userId", e)
                throw e
            }
    }
    
    /**
     * Updates an existing journal entry in the local database and syncs with remote if online
     *
     * @param journal The journal entry to update
     * @return Result containing the updated journal or an error
     */
    suspend fun updateJournal(journal: Journal): Result<Journal> {
        return try {
            LogUtils.d(TAG, "Updating journal: ${journal.id}")
            
            // Update in local database
            journalDao.updateJournal(journal)
            
            // Update audio metadata if available
            journal.audioMetadata?.let { metadata ->
                journalDao.updateAudioMetadata(metadata)
            }
            
            // Try to sync with server if online
            if (networkMonitor.isOnline()) {
                try {
                    LogUtils.d(TAG, "Online - updating journal on server")
                    val dto = journal.toJournalDto()
                    val responseDto = apiService.updateJournal(journal.id, dto)
                    
                    // Update local entry with any changes from server
                    val updatedJournal = journal.copy(updatedAt = System.currentTimeMillis())
                    journalDao.updateJournal(updatedJournal)
                    
                    return Result.success(updatedJournal)
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Failed to update journal on server", e)
                    // Continue with local journal update
                }
            } else {
                LogUtils.d(TAG, "Offline - journal update will be synced later")
            }
            
            Result.success(journal)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error updating journal", e)
            Result.failure(e)
        }
    }
    
    /**
     * Deletes a journal entry from the local database and remote if online
     *
     * @param journal The journal entry to delete
     * @return Result indicating success or an error
     */
    suspend fun deleteJournal(journal: Journal): Result<Unit> {
        return try {
            LogUtils.d(TAG, "Deleting journal: ${journal.id}")
            
            // Delete from local database
            journalDao.deleteJournal(journal)
            
            // Try to delete from server if uploaded and online
            if (networkMonitor.isOnline() && journal.isUploaded) {
                try {
                    LogUtils.d(TAG, "Online - deleting journal from server")
                    apiService.deleteJournal(journal.id)
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Failed to delete journal from server", e)
                    // Continue with local deletion
                }
            } else if (journal.isUploaded) {
                LogUtils.d(TAG, "Offline - remote deletion will be performed when online")
                // Could mark for deletion when back online
            }
            
            // Delete local audio file if it exists
            journal.localFilePath?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    file.delete()
                }
            }
            
            Result.success(Unit)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error deleting journal", e)
            Result.failure(e)
        }
    }
    
    /**
     * Toggles the favorite status of a journal entry
     *
     * @param journal The journal entry to toggle
     * @return Result containing the updated journal or an error
     */
    suspend fun toggleFavorite(journal: Journal): Result<Journal> {
        return try {
            LogUtils.d(TAG, "Toggling favorite status for journal: ${journal.id}")
            
            // Create updated journal with toggled favorite status
            val updatedJournal = journal.withUpdatedFavoriteStatus(!journal.isFavorite)
            
            // Update in local database
            journalDao.updateFavoriteStatus(journal.id, updatedJournal.isFavorite, System.currentTimeMillis())
            
            // Try to sync with server if online and journal is uploaded
            if (networkMonitor.isOnline() && journal.isUploaded) {
                try {
                    LogUtils.d(TAG, "Online - updating favorite status on server")
                    apiService.toggleJournalFavorite(journal.id)
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Failed to update favorite status on server", e)
                    // Continue with local update
                }
            } else if (journal.isUploaded) {
                LogUtils.d(TAG, "Offline - remote update will be performed when online")
            }
            
            Result.success(updatedJournal)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error toggling favorite status", e)
            Result.failure(e)
        }
    }
    
    /**
     * Uploads a journal's audio recording to the remote server
     *
     * @param journal The journal entry to upload
     * @return Result containing the updated journal or an error
     */
    suspend fun uploadJournalAudio(journal: Journal): Result<Journal> {
        if (journal.localFilePath == null || journal.isUploaded) {
            return Result.failure(IllegalStateException("Journal can't be uploaded: no local file or already uploaded"))
        }
        
        if (!networkMonitor.isOnline()) {
            return Result.failure(IOException("Not connected to the internet"))
        }
        
        return try {
            LogUtils.d(TAG, "Uploading journal audio: ${journal.id}")
            
            // Create file from local path
            val audioFile = File(journal.localFilePath)
            if (!audioFile.exists()) {
                return Result.failure(IllegalStateException("Audio file does not exist: ${journal.localFilePath}"))
            }
            
            // Create multipart request
            val requestFile = audioFile.asRequestBody("audio/aac".toMediaTypeOrNull())
            val audioPart = MultipartBody.Part.createFormData("audio", audioFile.name, requestFile)
            
            // Upload file
            val responseDto = apiService.uploadJournalAudio(journal.id, audioPart)
            
            // Update local journal with server data
            val updatedJournal = journal.withUpdatedUploadStatus(true, responseDto.storagePath)
            journalDao.updateUploadStatus(journal.id, true, responseDto.storagePath, System.currentTimeMillis())
            
            Result.success(updatedJournal)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error uploading journal audio", e)
            Result.failure(e)
        }
    }
    
    /**
     * Downloads a journal's audio recording from the remote server
     *
     * @param journal The journal entry to download
     * @param destinationFile The file to save the downloaded audio to
     * @return Result containing the downloaded file or an error
     */
    suspend fun downloadJournalAudio(journal: Journal, destinationFile: File): Result<File> {
        if (!journal.isUploaded || journal.storagePath == null) {
            return Result.failure(IllegalStateException("Journal can't be downloaded: not uploaded or no storage path"))
        }
        
        if (!networkMonitor.isOnline()) {
            return Result.failure(IOException("Not connected to the internet"))
        }
        
        return try {
            LogUtils.d(TAG, "Downloading journal audio: ${journal.id}")
            
            // Download file
            val responseBody = apiService.downloadJournalAudio(journal.id)
            
            // Write to destination file
            val outputStream = FileOutputStream(destinationFile)
            val inputStream = responseBody.byteStream()
            val buffer = ByteArray(4096)
            var bytesRead: Int
            
            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                outputStream.write(buffer, 0, bytesRead)
            }
            
            outputStream.flush()
            outputStream.close()
            inputStream.close()
            
            // Update local file path in the database
            journalDao.updateLocalFilePath(journal.id, destinationFile.absolutePath, System.currentTimeMillis())
            
            Result.success(destinationFile)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error downloading journal audio", e)
            Result.failure(e)
        }
    }
    
    /**
     * Synchronizes local journals with the remote server
     *
     * @param userId The ID of the user whose journals to sync
     * @return Result containing the number of successfully synced journals or an error
     */
    suspend fun syncJournals(userId: String): Result<Int> {
        if (!networkMonitor.isOnline()) {
            return Result.failure(IOException("Not connected to the internet"))
        }
        
        return try {
            LogUtils.d(TAG, "Syncing journals for user: $userId")
            
            // Get journals pending upload
            val pendingJournals = journalDao.getJournalsPendingUpload(userId)
            var syncCount = 0
            
            // Upload each pending journal
            for (journal in pendingJournals) {
                try {
                    if (journal.localFilePath != null) {
                        // Upload audio file first
                        val uploadResult = uploadJournalAudio(journal)
                        if (uploadResult.isSuccess) {
                            syncCount++
                        }
                    } else {
                        // Just sync metadata
                        val dto = journal.toJournalDto()
                        val responseDto = apiService.createJournal(dto)
                        
                        // Update local entry
                        val updatedJournal = journal.withUpdatedUploadStatus(true, responseDto.storagePath)
                        journalDao.updateJournal(updatedJournal)
                        
                        syncCount++
                    }
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Error syncing journal: ${journal.id}", e)
                    // Continue with next journal
                }
            }
            
            Result.success(syncCount)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error syncing journals", e)
            Result.failure(e)
        }
    }
    
    /**
     * Encrypts a journal's audio file for privacy protection
     *
     * @param journalId The ID of the journal
     * @param audioFile The audio file to encrypt
     * @param encryptedFile The file to save the encrypted audio to
     * @return Result containing the encryption IV for storage or an error
     */
    suspend fun encryptJournalAudio(journalId: String, audioFile: File, encryptedFile: File): Result<String> {
        return try {
            LogUtils.d(TAG, "Encrypting journal audio: $journalId")
            
            // Read audio file data
            val audioData = withContext(Dispatchers.IO) {
                audioFile.readBytes()
            }
            
            // Encrypt data
            val encryptResult = encryptionManager.encryptJournal(audioData, journalId)
            
            val encryptedData = encryptResult.getOrElse {
                return Result.failure(it)
            }
            
            // Write encrypted data to file
            withContext(Dispatchers.IO) {
                encryptedFile.writeBytes(encryptedData.encryptedBytes)
            }
            
            // Return IV for storage
            Result.success(encryptionManager.encodeToBase64(encryptedData.iv))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error encrypting journal audio", e)
            Result.failure(e)
        }
    }
    
    /**
     * Decrypts a journal's audio file for playback
     *
     * @param journalId The ID of the journal
     * @param encryptedFile The encrypted audio file
     * @param decryptedFile The file to save the decrypted audio to
     * @param encryptionIv The encryption IV used for decryption
     * @return Result containing the decrypted file or an error
     */
    suspend fun decryptJournalAudio(journalId: String, encryptedFile: File, decryptedFile: File, encryptionIv: String): Result<File> {
        return try {
            LogUtils.d(TAG, "Decrypting journal audio: $journalId")
            
            // Read encrypted file data
            val encryptedData = withContext(Dispatchers.IO) {
                encryptedFile.readBytes()
            }
            
            // Decode IV from Base64
            val iv = encryptionManager.decodeFromBase64(encryptionIv)
            
            // Create encrypted data object
            val encrypted = EncryptedData(encryptedData, iv)
            
            // Decrypt data
            val decryptResult = encryptionManager.decryptJournal(encrypted, journalId)
            
            val decryptedData = decryptResult.getOrElse {
                return Result.failure(it)
            }
            
            // Write decrypted data to file
            withContext(Dispatchers.IO) {
                decryptedFile.writeBytes(decryptedData)
            }
            
            Result.success(decryptedFile)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error decrypting journal audio", e)
            Result.failure(e)
        }
    }
    
    /**
     * Gets the total count of journal entries for a user
     *
     * @param userId The ID of the user
     * @return Flow emitting the count of journal entries
     */
    fun getJournalCount(userId: String): Flow<Int> {
        return journalDao.getJournalCount(userId)
            .catch { e ->
                LogUtils.e(TAG, "Error getting journal count for user: $userId", e)
                throw e
            }
    }
    
    /**
     * Gets the total time spent journaling in seconds
     *
     * @param userId The ID of the user
     * @return Flow emitting the total duration in seconds
     */
    fun getTotalJournalingTime(userId: String): Flow<Int> {
        return journalDao.getTotalJournalingTime(userId)
            .catch { e ->
                LogUtils.e(TAG, "Error getting total journaling time for user: $userId", e)
                throw e
            }
    }
    
    /**
     * Gets journal entries within a specific date range
     *
     * @param userId The ID of the user
     * @param startDate The start date of the range (timestamp)
     * @param endDate The end date of the range (timestamp)
     * @return Flow emitting the list of journal entries
     */
    fun getJournalsByDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<Journal>> {
        return journalDao.getJournalsByDateRange(userId, startDate, endDate)
            .catch { e ->
                LogUtils.e(TAG, "Error getting journals by date range for user: $userId", e)
                throw e
            }
    }
    
    /**
     * Gets journal entries with a positive emotional shift
     *
     * @param userId The ID of the user
     * @return Flow emitting the list of journal entries with positive emotional shift
     */
    fun getJournalsWithPositiveShift(userId: String): Flow<List<Journal>> {
        return journalDao.getJournalsWithPositiveShift(userId)
            .catch { e ->
                LogUtils.e(TAG, "Error getting journals with positive shift for user: $userId", e)
                throw e
            }
    }
    
    /**
     * Gets journal entries with a specific pre-recording emotion type
     *
     * @param userId The ID of the user
     * @param emotionType The emotion type to filter by
     * @return Flow emitting the list of journal entries
     */
    fun getJournalsByEmotionType(userId: String, emotionType: String): Flow<List<Journal>> {
        return journalDao.getJournalsByEmotionType(userId, emotionType)
            .catch { e ->
                LogUtils.e(TAG, "Error getting journals by emotion type for user: $userId", e)
                throw e
            }
    }
    
    /**
     * Gets the most recent journal entries for a user
     *
     * @param userId The ID of the user
     * @param limit The maximum number of entries to retrieve
     * @return Flow emitting the list of recent journal entries
     */
    fun getRecentJournals(userId: String, limit: Int): Flow<List<Journal>> {
        return journalDao.getRecentJournals(userId, limit)
            .catch { e ->
                LogUtils.e(TAG, "Error getting recent journals for user: $userId", e)
                throw e
            }
    }
}