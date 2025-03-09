package com.amirawellness.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.amirawellness.data.models.ToolCategory
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object (DAO) interface for tool categories in the Amira Wellness application.
 * This interface defines database operations for accessing and manipulating tool category data
 * stored in the local Room database, supporting the Tool Library feature.
 */
@Dao
interface ToolCategoryDao {

    /**
     * Inserts a new tool category into the database.
     * If a category with the same ID already exists, it will be replaced.
     *
     * @param category The tool category to insert
     * @return The row ID of the newly inserted category
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCategory(category: ToolCategory): Long

    /**
     * Inserts multiple tool categories into the database.
     * If categories with the same IDs already exist, they will be replaced.
     *
     * @param categories The list of tool categories to insert
     * @return A list of row IDs for the newly inserted categories
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCategories(categories: List<ToolCategory>): List<Long>

    /**
     * Updates an existing tool category in the database.
     *
     * @param category The tool category to update
     * @return The number of categories updated (should be 1 if successful)
     */
    @Update
    suspend fun updateCategory(category: ToolCategory): Int

    /**
     * Deletes a tool category from the database.
     *
     * @param category The tool category to delete
     * @return The number of categories deleted (should be 1 if successful)
     */
    @Delete
    suspend fun deleteCategory(category: ToolCategory): Int

    /**
     * Retrieves a tool category by its unique identifier.
     *
     * @param id The unique identifier of the tool category
     * @return A Flow emitting the tool category if found, or null if not found
     */
    @Query("SELECT * FROM tool_categories WHERE id = :id")
    fun getCategoryById(id: String): Flow<ToolCategory?>

    /**
     * Retrieves all tool categories from the database, ordered by name alphabetically.
     *
     * @return A Flow emitting a list of all tool categories
     */
    @Query("SELECT * FROM tool_categories ORDER BY name ASC")
    fun getAllCategories(): Flow<List<ToolCategory>>

    /**
     * Retrieves a tool category by its name.
     *
     * @param name The name of the tool category to find
     * @return A Flow emitting the tool category if found, or null if not found
     */
    @Query("SELECT * FROM tool_categories WHERE name = :name")
    fun getCategoryByName(name: String): Flow<ToolCategory?>

    /**
     * Searches for tool categories matching the given query string in either name or description.
     *
     * @param query The search query string
     * @return A Flow emitting a list of matching tool categories
     */
    @Query("SELECT * FROM tool_categories WHERE name LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%' ORDER BY name ASC")
    fun searchCategories(query: String): Flow<List<ToolCategory>>

    /**
     * Updates the tool count for a specific category.
     *
     * @param id The unique identifier of the category to update
     * @param toolCount The new tool count value
     * @return The number of rows updated (should be 1 if successful)
     */
    @Query("UPDATE tool_categories SET tool_count = :toolCount WHERE id = :id")
    suspend fun updateToolCount(id: String, toolCount: Int): Int

    /**
     * Increments the tool count for a specific category by 1.
     *
     * @param id The unique identifier of the category to update
     * @return The number of rows updated (should be 1 if successful)
     */
    @Query("UPDATE tool_categories SET tool_count = tool_count + 1 WHERE id = :id")
    suspend fun incrementToolCount(id: String): Int

    /**
     * Decrements the tool count for a specific category by 1, ensuring it doesn't go below zero.
     *
     * @param id The unique identifier of the category to update
     * @return The number of rows updated (should be 1 if successful)
     */
    @Query("UPDATE tool_categories SET tool_count = MAX(0, tool_count - 1) WHERE id = :id")
    suspend fun decrementToolCount(id: String): Int

    /**
     * Gets the total count of tool categories in the database.
     *
     * @return A Flow emitting the count of tool categories
     */
    @Query("SELECT COUNT(*) FROM tool_categories")
    fun getCategoryCount(): Flow<Int>

    /**
     * Deletes all tool categories from the database.
     * Use with caution as this will remove all category data.
     *
     * @return The number of categories deleted
     */
    @Query("DELETE FROM tool_categories")
    suspend fun deleteAllCategories(): Int
}