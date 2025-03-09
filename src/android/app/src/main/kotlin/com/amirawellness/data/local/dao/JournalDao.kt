package com.amirawellness.data.local.dao

import androidx.room.Dao // androidx.room:room-runtime:2.6+
import androidx.room.Delete // androidx.room:room-runtime:2.6+
import androidx.room.Insert // androidx.room:room-runtime:2.6+
import androidx.room.OnConflictStrategy // androidx.room:room-runtime:2.6+
import androidx.room.Query // androidx.room:room-runtime:2.6+
import androidx.room.Transaction // androidx.room:room-runtime:2.6+
import androidx.room.Update // androidx.room:room-runtime:2.6+
import com.amirawellness.data.models.AudioMetadata
import com.amirawellness.data.models.Journal
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines:1.6.4

/**
 * Data Access Object (DAO) interface for Journal entities in the Amira Wellness Android application.
 * Provides methods for CRUD operations on journal entries and their associated audio metadata
 * in the local Room database. Supports voice journaling with emotional check-ins,
 * offline capabilities, and synchronization with the backend.
 */
@Dao
interface JournalDao {

    /**
     * Inserts a new journal entry into the database
     *
     * @param journal The journal entry to insert
     * @return The row ID of the inserted journal
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertJournal(journal: Journal): Long

    /**
     * Inserts audio metadata associated with a journal entry
     *
     * @param audioMetadata The audio metadata to insert
     * @return The row ID of the inserted metadata
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAudioMetadata(audioMetadata: AudioMetadata): Long

    /**
     * Updates an existing journal entry in the database
     *
     * @param journal The journal entry to update
     * @return The number of rows updated
     */
    @Update
    suspend fun updateJournal(journal: Journal): Int

    /**
     * Updates existing audio metadata in the database
     *
     * @param audioMetadata The audio metadata to update
     * @return The number of rows updated
     */
    @Update
    suspend fun updateAudioMetadata(audioMetadata: AudioMetadata): Int

    /**
     * Deletes a journal entry and its associated audio metadata from the database.
     * Audio metadata will be deleted automatically via the CASCADE foreign key constraint.
     *
     * @param journal The journal entry to delete
     * @return The number of rows deleted
     */
    @Delete
    @Transaction
    suspend fun deleteJournal(journal: Journal): Int

    /**
     * Retrieves a journal entry by its unique identifier
     *
     * @param id The unique identifier of the journal entry
     * @return A Flow emitting the journal entry or null if not found
     */
    @Query("SELECT * FROM journals WHERE id = :id")
    fun getJournalById(id: String): Flow<Journal?>

    /**
     * Retrieves all journal entries for a specific user, ordered by creation date descending
     *
     * @param userId The ID of the user
     * @return A Flow emitting the list of journal entries
     */
    @Query("SELECT * FROM journals WHERE userId = :userId ORDER BY createdAt DESC")
    fun getJournalsByUserId(userId: String): Flow<List<Journal>>

    /**
     * Retrieves all favorite journal entries for a specific user
     *
     * @param userId The ID of the user
     * @return A Flow emitting the list of favorite journal entries
     */
    @Query("SELECT * FROM journals WHERE userId = :userId AND isFavorite = 1 ORDER BY createdAt DESC")
    fun getFavoriteJournals(userId: String): Flow<List<Journal>>

    /**
     * Retrieves all journal entries that haven't been uploaded to the server yet
     *
     * @param userId The ID of the user
     * @return A list of journal entries pending upload
     */
    @Query("SELECT * FROM journals WHERE userId = :userId AND isUploaded = 0 AND localFilePath IS NOT NULL")
    suspend fun getJournalsPendingUpload(userId: String): List<Journal>

    /**
     * Updates the upload status and storage path of a journal entry
     *
     * @param journalId The ID of the journal entry
     * @param isUploaded The new upload status
     * @param storagePath The new storage path (can be null)
     * @param updatedAt The timestamp of the update
     * @return The number of rows updated
     */
    @Query("UPDATE journals SET isUploaded = :isUploaded, storagePath = :storagePath, updatedAt = :updatedAt WHERE id = :journalId")
    suspend fun updateUploadStatus(journalId: String, isUploaded: Boolean, storagePath: String?, updatedAt: Long): Int

    /**
     * Updates the favorite status of a journal entry
     *
     * @param journalId The ID of the journal entry
     * @param isFavorite The new favorite status
     * @param updatedAt The timestamp of the update
     * @return The number of rows updated
     */
    @Query("UPDATE journals SET isFavorite = :isFavorite, updatedAt = :updatedAt WHERE id = :journalId")
    suspend fun updateFavoriteStatus(journalId: String, isFavorite: Boolean, updatedAt: Long): Int

    /**
     * Updates the local file path of a journal entry
     *
     * @param journalId The ID of the journal entry
     * @param localFilePath The new local file path
     * @param updatedAt The timestamp of the update
     * @return The number of rows updated
     */
    @Query("UPDATE journals SET localFilePath = :localFilePath, updatedAt = :updatedAt WHERE id = :journalId")
    suspend fun updateLocalFilePath(journalId: String, localFilePath: String, updatedAt: Long): Int

    /**
     * Gets the total count of journal entries for a specific user
     *
     * @param userId The ID of the user
     * @return A Flow emitting the count of journal entries
     */
    @Query("SELECT COUNT(*) FROM journals WHERE userId = :userId")
    fun getJournalCount(userId: String): Flow<Int>

    /**
     * Gets the total time spent journaling in seconds for a specific user
     *
     * @param userId The ID of the user
     * @return A Flow emitting the total duration in seconds
     */
    @Query("SELECT SUM(durationSeconds) FROM journals WHERE userId = :userId")
    fun getTotalJournalingTime(userId: String): Flow<Int>

    /**
     * Retrieves journal entries created within a specific date range
     *
     * @param userId The ID of the user
     * @param startDate The start date of the range (timestamp)
     * @param endDate The end date of the range (timestamp)
     * @return A Flow emitting the list of journal entries
     */
    @Query("SELECT * FROM journals WHERE userId = :userId AND createdAt BETWEEN :startDate AND :endDate ORDER BY createdAt DESC")
    fun getJournalsByDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<Journal>>

    /**
     * Retrieves journal entries with a positive emotional shift
     *
     * @param userId The ID of the user
     * @return A Flow emitting the list of journal entries with positive emotional shift
     */
    @Query("SELECT * FROM journals WHERE userId = :userId AND post_intensity > pre_intensity ORDER BY createdAt DESC")
    fun getJournalsWithPositiveShift(userId: String): Flow<List<Journal>>

    /**
     * Retrieves journal entries with a specific pre-recording emotion type
     *
     * @param userId The ID of the user
     * @param emotionType The emotion type to filter by
     * @return A Flow emitting the list of journal entries
     */
    @Query("SELECT * FROM journals WHERE userId = :userId AND pre_emotionType = :emotionType ORDER BY createdAt DESC")
    fun getJournalsByEmotionType(userId: String, emotionType: String): Flow<List<Journal>>

    /**
     * Retrieves the most recent journal entries for a specific user
     *
     * @param userId The ID of the user
     * @param limit The maximum number of entries to retrieve
     * @return A Flow emitting the list of recent journal entries
     */
    @Query("SELECT * FROM journals WHERE userId = :userId ORDER BY createdAt DESC LIMIT :limit")
    fun getRecentJournals(userId: String, limit: Int): Flow<List<Journal>>
}