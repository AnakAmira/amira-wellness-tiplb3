package com.amirawellness.data.local.dao

import androidx.room.Dao // androidx.room:2.6+
import androidx.room.Delete // androidx.room:2.6+
import androidx.room.Insert // androidx.room:2.6+
import androidx.room.OnConflictStrategy // androidx.room:2.6+
import androidx.room.Query // androidx.room:2.6+
import androidx.room.Update // androidx.room:2.6+
import com.amirawellness.data.models.Tool
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines.flow:1.7+

/**
 * Data Access Object (DAO) interface for Tool entities in the Amira Wellness application.
 * This interface defines database operations for emotional regulation tools,
 * including CRUD operations, specialized queries for tool management,
 * and methods for handling tool favorites and usage tracking.
 */
@Dao
interface ToolDao {
    /**
     * Inserts a tool entity into the database.
     *
     * @param tool The tool entity to insert
     * @return The new rowId for the inserted item
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTool(tool: Tool): Long

    /**
     * Inserts multiple tool entities into the database.
     *
     * @param tools The list of tool entities to insert
     * @return The new rowIds for the inserted items
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTools(tools: List<Tool>): List<Long>

    /**
     * Updates an existing tool entity in the database.
     *
     * @param tool The tool entity to update
     * @return The number of rows updated
     */
    @Update
    suspend fun updateTool(tool: Tool): Int

    /**
     * Deletes a tool entity from the database.
     *
     * @param tool The tool entity to delete
     * @return The number of rows deleted
     */
    @Delete
    suspend fun deleteTool(tool: Tool): Int

    /**
     * Retrieves a tool by its unique identifier.
     *
     * @param id The unique identifier of the tool
     * @return Flow emitting the tool entity or null if not found
     */
    @Query("SELECT * FROM tools WHERE id = :id")
    fun getToolById(id: String): Flow<Tool?>

    /**
     * Retrieves all tools in the database.
     *
     * @return Flow emitting a list of all tool entities
     */
    @Query("SELECT * FROM tools ORDER BY name ASC")
    fun getAllTools(): Flow<List<Tool>>

    /**
     * Retrieves tools belonging to a specific category.
     *
     * @param categoryId The category identifier
     * @return Flow emitting a list of tools in the specified category
     */
    @Query("SELECT * FROM tools WHERE category.id = :categoryId ORDER BY name ASC")
    fun getToolsByCategory(categoryId: String): Flow<List<Tool>>

    /**
     * Retrieves tools marked as favorites.
     *
     * @return Flow emitting a list of favorite tool entities
     */
    @Query("SELECT * FROM tools WHERE isFavorite = 1 ORDER BY name ASC")
    fun getFavoriteTools(): Flow<List<Tool>>

    /**
     * Retrieves tools that target a specific emotion type.
     *
     * @param emotionType The emotion type to filter by
     * @return Flow emitting a list of tools targeting the specified emotion
     */
    @Query("SELECT * FROM tools WHERE targetEmotions LIKE '%' || :emotionType || '%' ORDER BY name ASC")
    fun getToolsByEmotionType(emotionType: String): Flow<List<Tool>>

    /**
     * Updates the favorite status of a tool.
     *
     * @param id The unique identifier of the tool
     * @param isFavorite The new favorite status
     * @return The number of rows updated
     */
    @Query("UPDATE tools SET isFavorite = :isFavorite WHERE id = :id")
    suspend fun updateFavoriteStatus(id: String, isFavorite: Boolean): Int

    /**
     * Increments the usage count for a tool.
     *
     * @param id The unique identifier of the tool
     * @return The number of rows updated
     */
    @Query("UPDATE tools SET usageCount = usageCount + 1 WHERE id = :id")
    suspend fun incrementUsageCount(id: String): Int

    /**
     * Searches for tools by name or description.
     *
     * @param query The search query string
     * @return Flow emitting a list of matching tool entities
     */
    @Query("SELECT * FROM tools WHERE name LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%' ORDER BY name ASC")
    fun searchTools(query: String): Flow<List<Tool>>

    /**
     * Retrieves tools with duration less than or equal to specified minutes.
     *
     * @param maxDurationMinutes The maximum duration in minutes
     * @return Flow emitting a list of tools with appropriate duration
     */
    @Query("SELECT * FROM tools WHERE estimatedDuration <= :maxDurationMinutes ORDER BY estimatedDuration ASC")
    fun getToolsByDuration(maxDurationMinutes: Int): Flow<List<Tool>>

    /**
     * Gets the total count of tools in the database.
     *
     * @return Flow emitting the count of tools
     */
    @Query("SELECT COUNT(*) FROM tools")
    fun getToolCount(): Flow<Int>

    /**
     * Gets the count of tools in a specific category.
     *
     * @param categoryId The category identifier
     * @return Flow emitting the count of tools in the category
     */
    @Query("SELECT COUNT(*) FROM tools WHERE category.id = :categoryId")
    fun getToolCountByCategory(categoryId: String): Flow<Int>

    /**
     * Retrieves the most frequently used tools.
     *
     * @param limit The maximum number of tools to retrieve
     * @return Flow emitting a list of most used tools
     */
    @Query("SELECT * FROM tools ORDER BY usageCount DESC LIMIT :limit")
    fun getMostUsedTools(limit: Int): Flow<List<Tool>>

    /**
     * Deletes all tools from the database.
     *
     * @return The number of rows deleted
     */
    @Query("DELETE FROM tools")
    suspend fun deleteAllTools(): Int
}