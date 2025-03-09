package com.amirawellness.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Query
import androidx.room.OnConflictStrategy
import androidx.room.Transaction
import com.amirawellness.data.models.Achievement
import com.amirawellness.data.models.AchievementType
import com.amirawellness.data.models.AchievementCategory
import kotlinx.coroutines.flow.Flow
import java.util.Date
import java.util.UUID

/**
 * Data Access Object (DAO) interface for Achievement entities in the Amira Wellness application.
 * This interface defines all database operations related to user achievements, including CRUD
 * operations, queries for achievement tracking, and progress updates.
 */
@Dao
interface AchievementDao {
    /**
     * Inserts a single achievement entity into the database
     *
     * @param achievement The achievement to insert
     * @return The row ID of the newly inserted achievement
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAchievement(achievement: Achievement): Long

    /**
     * Inserts multiple achievement entities into the database
     *
     * @param achievements List of achievements to insert
     * @return List of row IDs for the newly inserted achievements
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAchievements(achievements: List<Achievement>): List<Long>

    /**
     * Updates an existing achievement entity in the database
     *
     * @param achievement The achievement to update
     * @return Number of rows affected
     */
    @Update
    suspend fun updateAchievement(achievement: Achievement): Int

    /**
     * Deletes an achievement entity from the database
     *
     * @param achievement The achievement to delete
     * @return Number of rows affected
     */
    @Delete
    suspend fun deleteAchievement(achievement: Achievement): Int

    /**
     * Retrieves an achievement by its unique identifier
     *
     * @param id Unique identifier of the achievement
     * @return Flow emitting the achievement or null if not found
     */
    @Query("SELECT * FROM achievements WHERE id = :id")
    fun getAchievementById(id: String): Flow<Achievement?>

    /**
     * Retrieves an achievement by its type
     *
     * @param type Type of the achievement
     * @return Flow emitting the achievement or null if not found
     */
    @Query("SELECT * FROM achievements WHERE type = :type")
    fun getAchievementByType(type: AchievementType): Flow<Achievement?>

    /**
     * Retrieves all achievements from the database
     *
     * @return Flow emitting a list of all achievements
     */
    @Query("SELECT * FROM achievements")
    fun getAllAchievements(): Flow<List<Achievement>>

    /**
     * Retrieves achievements filtered by category
     *
     * @param category Category to filter by
     * @return Flow emitting a list of achievements in the specified category
     */
    @Query("SELECT * FROM achievements WHERE category = :category")
    fun getAchievementsByCategory(category: AchievementCategory): Flow<List<Achievement>>

    /**
     * Retrieves achievements that have been earned by the user
     *
     * @return Flow emitting a list of earned achievements
     */
    @Query("SELECT * FROM achievements WHERE earnedAt IS NOT NULL")
    fun getEarnedAchievements(): Flow<List<Achievement>>

    /**
     * Retrieves achievements that have not yet been earned by the user
     *
     * @return Flow emitting a list of pending achievements
     */
    @Query("SELECT * FROM achievements WHERE earnedAt IS NULL")
    fun getPendingAchievements(): Flow<List<Achievement>>

    /**
     * Retrieves achievements that are visible to the user
     *
     * @return Flow emitting a list of visible achievements
     */
    @Query("SELECT * FROM achievements WHERE isHidden = 0")
    fun getVisibleAchievements(): Flow<List<Achievement>>

    /**
     * Retrieves achievements that are hidden from the user
     *
     * @return Flow emitting a list of hidden achievements
     */
    @Query("SELECT * FROM achievements WHERE isHidden = 1")
    fun getHiddenAchievements(): Flow<List<Achievement>>

    /**
     * Retrieves achievements that are in progress but not yet earned
     *
     * @return Flow emitting a list of in-progress achievements
     */
    @Query("SELECT * FROM achievements WHERE earnedAt IS NULL AND progress > 0 AND progress < 1")
    fun getAchievementsInProgress(): Flow<List<Achievement>>

    /**
     * Updates the progress value for an achievement
     *
     * @param achievementId Unique identifier of the achievement
     * @param progress New progress value (between 0.0 and 1.0)
     * @return Number of rows affected
     */
    @Query("UPDATE achievements SET progress = :progress, updatedAt = :timestamp WHERE id = :achievementId")
    suspend fun updateAchievementProgress(
        achievementId: String, 
        progress: Double,
        timestamp: Date = Date()
    ): Int

    /**
     * Marks an achievement as earned with the current timestamp
     *
     * @param achievementId Unique identifier of the achievement
     * @param earnedAt Timestamp when the achievement was earned
     * @return Number of rows affected
     */
    @Query("UPDATE achievements SET earnedAt = :earnedAt, progress = 1.0, updatedAt = :timestamp WHERE id = :achievementId")
    suspend fun markAchievementAsEarned(
        achievementId: String, 
        earnedAt: Date,
        timestamp: Date = Date()
    ): Int

    /**
     * Retrieves achievements earned within a specified time period
     *
     * @param since Date from which to retrieve earned achievements
     * @return Flow emitting a list of recently earned achievements
     */
    @Query("SELECT * FROM achievements WHERE earnedAt IS NOT NULL AND earnedAt >= :since ORDER BY earnedAt DESC")
    fun getRecentlyEarnedAchievements(since: Date): Flow<List<Achievement>>

    /**
     * Retrieves achievements matching any of the specified types
     *
     * @param types List of achievement types to filter by
     * @return Flow emitting a list of achievements matching the specified types
     */
    @Query("SELECT * FROM achievements WHERE type IN (:types)")
    fun getAchievementsByTypes(types: List<AchievementType>): Flow<List<Achievement>>

    /**
     * Deletes all achievements from the database
     *
     * @return Number of rows affected
     */
    @Query("DELETE FROM achievements")
    suspend fun deleteAllAchievements(): Int

    /**
     * Gets the total count of achievements in the database
     *
     * @return Total number of achievements
     */
    @Query("SELECT COUNT(*) FROM achievements")
    suspend fun getAchievementCount(): Int

    /**
     * Gets the count of earned achievements
     *
     * @return Number of earned achievements
     */
    @Query("SELECT COUNT(*) FROM achievements WHERE earnedAt IS NOT NULL")
    suspend fun getEarnedAchievementCount(): Int
}