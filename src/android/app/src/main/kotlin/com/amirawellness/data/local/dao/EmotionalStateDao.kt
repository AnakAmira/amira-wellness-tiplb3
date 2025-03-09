package com.amirawellness.data.local.dao

import androidx.room.Dao // androidx.room:room-runtime:2.6+
import androidx.room.Insert // androidx.room:room-runtime:2.6+
import androidx.room.Update // androidx.room:room-runtime:2.6+
import androidx.room.Delete // androidx.room:room-runtime:2.6+
import androidx.room.Query // androidx.room:room-runtime:2.6+
import androidx.room.OnConflictStrategy // androidx.room:room-runtime:2.6+
import androidx.room.Transaction // androidx.room:room-runtime:2.6+
import com.amirawellness.data.models.EmotionalState
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines:1.6.4

/**
 * Data Access Object (DAO) interface for EmotionalState entities in the Amira Wellness Android application.
 * 
 * This interface provides methods for CRUD operations on emotional state data in the local Room database,
 * as well as specialized queries for emotional analysis, trends, and insights. These functions support
 * features like emotional check-ins, voice journaling with pre/post emotional states, and progress tracking.
 */
@Dao
interface EmotionalStateDao {

    /**
     * Inserts a new emotional state into the database.
     * 
     * @param emotionalState The EmotionalState object to insert
     * @return The row ID of the inserted item
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEmotionalState(emotionalState: EmotionalState): Long

    /**
     * Updates an existing emotional state in the database.
     * 
     * @param emotionalState The EmotionalState object to update
     * @return The number of rows updated
     */
    @Update
    suspend fun updateEmotionalState(emotionalState: EmotionalState): Int

    /**
     * Deletes an emotional state from the database.
     * 
     * @param emotionalState The EmotionalState object to delete
     * @return The number of rows deleted
     */
    @Delete
    suspend fun deleteEmotionalState(emotionalState: EmotionalState): Int

    /**
     * Gets an emotional state by its unique identifier.
     * 
     * @param id The ID of the emotional state to retrieve
     * @return A Flow that emits the emotional state or null if not found
     */
    @Query("SELECT * FROM emotional_states WHERE id = :id")
    fun getEmotionalStateById(id: String): Flow<EmotionalState?>

    /**
     * Gets all emotional states for a specific user.
     * 
     * @param userId The ID of the user
     * @return A Flow that emits the list of emotional states
     */
    @Query("SELECT * FROM emotional_states WHERE userId = :userId ORDER BY createdAt DESC")
    fun getEmotionalStatesByUserId(userId: String): Flow<List<EmotionalState>>

    /**
     * Gets emotional states associated with a specific journal entry.
     * 
     * @param journalId The ID of the journal entry
     * @return A Flow that emits the list of emotional states
     */
    @Query("SELECT * FROM emotional_states WHERE relatedJournalId = :journalId ORDER BY createdAt")
    fun getEmotionalStatesByJournalId(journalId: String): Flow<List<EmotionalState>>

    /**
     * Gets emotional states associated with a specific tool usage.
     * 
     * @param toolId The ID of the tool
     * @return A Flow that emits the list of emotional states
     */
    @Query("SELECT * FROM emotional_states WHERE relatedToolId = :toolId ORDER BY createdAt")
    fun getEmotionalStatesByToolId(toolId: String): Flow<List<EmotionalState>>

    /**
     * Gets emotional states for a specific context.
     * 
     * @param userId The ID of the user
     * @param context The context of the emotional states
     * @return A Flow that emits the list of emotional states
     */
    @Query("SELECT * FROM emotional_states WHERE userId = :userId AND context = :context ORDER BY createdAt DESC")
    fun getEmotionalStatesByContext(userId: String, context: String): Flow<List<EmotionalState>>

    /**
     * Gets emotional states created within a specific date range.
     * 
     * @param userId The ID of the user
     * @param startDate The start date of the range (as milliseconds since epoch)
     * @param endDate The end date of the range (as milliseconds since epoch)
     * @return A Flow that emits the list of emotional states
     */
    @Query("SELECT * FROM emotional_states WHERE userId = :userId AND createdAt BETWEEN :startDate AND :endDate ORDER BY createdAt")
    fun getEmotionalStatesByDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<EmotionalState>>

    /**
     * Gets emotional states of a specific emotion type.
     * 
     * @param userId The ID of the user
     * @param emotionType The type of emotion
     * @return A Flow that emits the list of emotional states
     */
    @Query("SELECT * FROM emotional_states WHERE userId = :userId AND emotionType = :emotionType ORDER BY createdAt DESC")
    fun getEmotionalStatesByEmotionType(userId: String, emotionType: String): Flow<List<EmotionalState>>

    /**
     * Gets the frequency count of each emotion type for a user.
     * 
     * @param userId The ID of the user
     * @return A Flow that emits a map of emotion types to their frequency counts
     */
    @Query("SELECT emotionType, COUNT(*) as count FROM emotional_states WHERE userId = :userId GROUP BY emotionType")
    fun getEmotionTypeFrequency(userId: String): Flow<Map<String, Int>>

    /**
     * Gets the average intensity for each emotion type.
     * 
     * @param userId The ID of the user
     * @return A Flow that emits a map of emotion types to their average intensities
     */
    @Query("SELECT emotionType, AVG(intensity) as avgIntensity FROM emotional_states WHERE userId = :userId GROUP BY emotionType")
    fun getAverageIntensityByEmotionType(userId: String): Flow<Map<String, Float>>

    /**
     * Gets the total count of emotional states for a user.
     * 
     * @param userId The ID of the user
     * @return A Flow that emits the count
     */
    @Query("SELECT COUNT(*) FROM emotional_states WHERE userId = :userId")
    fun getEmotionalStateCount(userId: String): Flow<Int>

    /**
     * Gets the most frequently recorded emotion type for a user.
     * 
     * @param userId The ID of the user
     * @return A Flow that emits the most frequent emotion type or null if no data
     */
    @Query("SELECT emotionType FROM emotional_states WHERE userId = :userId GROUP BY emotionType ORDER BY COUNT(*) DESC LIMIT 1")
    fun getMostFrequentEmotionType(userId: String): Flow<String?>

    /**
     * Gets a limited number of most recent emotional states for a user.
     * 
     * @param userId The ID of the user
     * @param limit The maximum number of records to retrieve
     * @return A Flow that emits the list of emotional states
     */
    @Query("SELECT * FROM emotional_states WHERE userId = :userId ORDER BY createdAt DESC LIMIT :limit")
    fun getEmotionalStatesByUserIdAndLimit(userId: String, limit: Int): Flow<List<EmotionalState>>

    /**
     * Gets the count of emotional states within a date range grouped by day.
     * 
     * @param userId The ID of the user
     * @param startDate The start date of the range (as milliseconds since epoch)
     * @param endDate The end date of the range (as milliseconds since epoch)
     * @return A Flow that emits a map of days to counts
     */
    @Query("SELECT strftime('%Y%m%d', datetime(createdAt/1000, 'unixepoch')) as day, COUNT(*) as count FROM emotional_states WHERE userId = :userId AND createdAt BETWEEN :startDate AND :endDate GROUP BY day")
    fun getEmotionalStateCountByDateRange(userId: String, startDate: Long, endDate: Long): Flow<Map<Long, Int>>

    /**
     * Gets the average intensity of emotional states within a date range grouped by day.
     * 
     * @param userId The ID of the user
     * @param startDate The start date of the range (as milliseconds since epoch)
     * @param endDate The end date of the range (as milliseconds since epoch)
     * @return A Flow that emits a map of days to average intensities
     */
    @Query("SELECT strftime('%Y%m%d', datetime(createdAt/1000, 'unixepoch')) as day, AVG(intensity) as avgIntensity FROM emotional_states WHERE userId = :userId AND createdAt BETWEEN :startDate AND :endDate GROUP BY day")
    fun getIntensityTrendByDateRange(userId: String, startDate: Long, endDate: Long): Flow<Map<Long, Float>>

    /**
     * Deletes all emotional states associated with a specific journal entry.
     * 
     * @param journalId The ID of the journal entry
     * @return The number of rows deleted
     */
    @Query("DELETE FROM emotional_states WHERE relatedJournalId = :journalId")
    suspend fun deleteEmotionalStatesByJournalId(journalId: String): Int

    /**
     * Deletes all emotional states for a specific user.
     * 
     * @param userId The ID of the user
     * @return The number of rows deleted
     */
    @Query("DELETE FROM emotional_states WHERE userId = :userId")
    suspend fun deleteEmotionalStatesByUserId(userId: String): Int

    /**
     * Gets the count of emotional states for each context.
     * 
     * @param userId The ID of the user
     * @return A Flow that emits a map of contexts to counts
     */
    @Query("SELECT context, COUNT(*) as count FROM emotional_states WHERE userId = :userId GROUP BY context")
    fun getEmotionalStateCountByContext(userId: String): Flow<Map<String, Int>>
}