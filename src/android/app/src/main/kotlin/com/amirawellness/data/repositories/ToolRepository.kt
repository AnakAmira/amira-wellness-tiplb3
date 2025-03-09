package com.amirawellness.data.repositories

import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.local.dao.ToolDao
import com.amirawellness.data.local.dao.ToolCategoryDao
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.core.utils.LogUtils.d as logDebug
import com.amirawellness.core.utils.LogUtils.e as logError
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import retrofit2.Call
import retrofit2.Response
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "ToolRepository"

/**
 * Repository implementation for managing tools in the Amira Wellness application.
 * 
 * This class serves as a single source of truth for tool-related data,
 * coordinating between local database storage and remote API. It implements
 * the Tool Library feature with support for categorization, favoriting,
 * searching, and recommendation features.
 */
@Singleton
class ToolRepository @Inject constructor(
    private val toolDao: ToolDao,
    private val toolCategoryDao: ToolCategoryDao,
    private val apiService: ApiService,
    private val networkMonitor: NetworkMonitor
) {
    /**
     * Retrieves tools, optionally filtered by category, with support for forced refresh from remote.
     *
     * @param categoryId Optional category ID to filter tools
     * @param forceRefresh Whether to force refresh data from remote API
     * @return Flow emitting a list of tools
     */
    suspend fun getTools(categoryId: String? = null, forceRefresh: Boolean = false): Flow<List<Tool>> {
        if (forceRefresh && networkMonitor.isNetworkAvailable()) {
            try {
                refreshTools()
            } catch (e: Exception) {
                logError(TAG, "Error refreshing tools", e)
            }
        }
        
        return if (categoryId != null) {
            toolDao.getToolsByCategory(categoryId)
        } else {
            toolDao.getAllTools()
        }
    }
    
    /**
     * Retrieves a specific tool by its ID, with support for forced refresh from remote.
     *
     * @param id The tool ID
     * @param forceRefresh Whether to force refresh data from remote API
     * @return Flow emitting the tool if found, or null if not found
     */
    suspend fun getToolById(id: String, forceRefresh: Boolean = false): Flow<Tool?> {
        if (forceRefresh && networkMonitor.isNetworkAvailable()) {
            try {
                val response = executeApiCall { apiService.getTool(id) }
                response?.let {
                    val tool = Tool.Companion.fromDto(it)
                    toolDao.insertTool(tool)
                }
            } catch (e: Exception) {
                logError(TAG, "Error refreshing tool: $id", e)
            }
        }
        
        return toolDao.getToolById(id)
    }
    
    /**
     * Retrieves tools marked as favorites.
     *
     * @return Flow emitting a list of favorite tools
     */
    fun getFavoriteTools(): Flow<List<Tool>> {
        return toolDao.getFavoriteTools()
    }
    
    /**
     * Toggles the favorite status of a tool and synchronizes with the server if online.
     *
     * @param id The tool ID
     * @param isFavorite The new favorite status
     * @return True if successful, false otherwise
     */
    suspend fun toggleToolFavorite(id: String, isFavorite: Boolean): Boolean {
        val result = toolDao.updateFavoriteStatus(id, isFavorite)
        
        if (result > 0 && networkMonitor.isNetworkAvailable()) {
            try {
                executeApiCall { apiService.toggleToolFavorite(id) }
                return true
            } catch (e: Exception) {
                logError(TAG, "Error syncing favorite status to server for tool: $id", e)
                // We don't revert the local change - it will be synced later
            }
        }
        
        return result > 0
    }
    
    /**
     * Records tool usage and synchronizes with the server if online.
     *
     * @param id The tool ID
     * @param durationSeconds The duration of tool usage in seconds
     * @return True if successful, false otherwise
     */
    suspend fun trackToolUsage(id: String, durationSeconds: Int): Boolean {
        val result = toolDao.incrementUsageCount(id)
        
        if (result > 0 && networkMonitor.isNetworkAvailable()) {
            try {
                executeApiCall { apiService.trackToolUsage(id, durationSeconds) }
                return true
            } catch (e: Exception) {
                logError(TAG, "Error syncing usage data to server for tool: $id", e)
                // We don't revert the local update - usage data will be eventually consistent
            }
        }
        
        return result > 0
    }
    
    /**
     * Searches for tools by name or description.
     *
     * @param query The search query
     * @return Flow emitting a list of matching tools
     */
    fun searchTools(query: String): Flow<List<Tool>> {
        return toolDao.searchTools(query)
    }
    
    /**
     * Retrieves tools with duration less than or equal to specified minutes.
     *
     * @param maxDurationMinutes The maximum duration in minutes
     * @return Flow emitting a list of tools with appropriate duration
     */
    fun getToolsByDuration(maxDurationMinutes: Int): Flow<List<Tool>> {
        return toolDao.getToolsByDuration(maxDurationMinutes)
    }
    
    /**
     * Retrieves tools that target a specific emotion type.
     *
     * @param emotionType The emotion type to filter by
     * @return Flow emitting a list of tools targeting the specified emotion
     */
    fun getToolsByEmotionType(emotionType: String): Flow<List<Tool>> {
        return toolDao.getToolsByEmotionType(emotionType)
    }
    
    /**
     * Gets tool recommendations based on emotional state, with offline fallback.
     *
     * @param emotionType The emotion type
     * @param intensity The emotion intensity (1-10)
     * @return List of recommended tools
     */
    suspend fun getRecommendedTools(emotionType: String, intensity: Int): List<Tool> {
        if (networkMonitor.isNetworkAvailable()) {
            try {
                val response = executeApiCall { 
                    apiService.getToolRecommendations(emotionType, intensity) 
                }
                
                if (response != null) {
                    // Convert DTOs to domain models and return
                    return response.map { Tool.Companion.fromDto(it) }
                }
            } catch (e: Exception) {
                logError(TAG, "Error getting recommended tools from server", e)
                // Fall back to local recommendations
            }
        }
        
        // Offline fallback: get tools targeted for this emotion
        return withContext(Dispatchers.IO) {
            toolDao.getToolsByEmotionType(emotionType).first()
        }
    }
    
    /**
     * Retrieves all tool categories, with support for forced refresh from remote.
     *
     * @param forceRefresh Whether to force refresh data from remote API
     * @return Flow emitting a list of tool categories
     */
    suspend fun getToolCategories(forceRefresh: Boolean = false): Flow<List<ToolCategory>> {
        if (forceRefresh && networkMonitor.isNetworkAvailable()) {
            try {
                refreshToolCategories()
            } catch (e: Exception) {
                logError(TAG, "Error refreshing tool categories", e)
            }
        }
        
        return toolCategoryDao.getAllCategories()
    }
    
    /**
     * Retrieves a specific tool category by its ID.
     *
     * @param id The category ID
     * @return Flow emitting the category if found, or null if not found
     */
    fun getCategoryById(id: String): Flow<ToolCategory?> {
        return toolCategoryDao.getCategoryById(id)
    }
    
    /**
     * Refreshes all tools from the remote API.
     *
     * @return True if successful, false otherwise
     */
    suspend fun refreshTools(): Boolean {
        if (!networkMonitor.isNetworkAvailable()) {
            return false
        }
        
        try {
            // Refresh categories first to ensure proper relationships
            refreshToolCategories()
            
            // Now fetch all tools
            val response = executeApiCall { apiService.getToolsByCategory(null) }
            
            if (response != null) {
                // Convert DTOs to domain models
                val tools = response.map { Tool.Companion.fromDto(it) }
                
                // Insert all tools - this will replace existing ones with the same ID
                withContext(Dispatchers.IO) {
                    toolDao.insertTools(tools)
                }
                
                logDebug(TAG, "Successfully refreshed ${tools.size} tools")
                return true
            }
        } catch (e: Exception) {
            logError(TAG, "Error refreshing tools", e)
        }
        
        return false
    }
    
    /**
     * Refreshes all tool categories from the remote API.
     *
     * @return True if successful, false otherwise
     */
    suspend fun refreshToolCategories(): Boolean {
        if (!networkMonitor.isNetworkAvailable()) {
            return false
        }
        
        try {
            val response = executeApiCall { apiService.getToolCategories() }
            
            if (response != null) {
                // Convert DTOs to domain models
                val categories = response.map { ToolCategory.Companion.fromDto(it) }
                
                // Insert all categories - this will replace existing ones with the same ID
                withContext(Dispatchers.IO) {
                    toolCategoryDao.insertCategories(categories)
                }
                
                logDebug(TAG, "Successfully refreshed ${categories.size} tool categories")
                return true
            }
        } catch (e: Exception) {
            logError(TAG, "Error refreshing tool categories", e)
        }
        
        return false
    }
    
    /**
     * Synchronizes favorite tools with the server.
     *
     * @return True if successful, false otherwise
     */
    suspend fun syncFavorites(): Boolean {
        if (!networkMonitor.isNetworkAvailable()) {
            return false
        }
        
        try {
            val response = executeApiCall { apiService.getFavoriteTools() }
            
            if (response != null) {
                // We need to update the favorite status for all tools based on server data
                val serverFavorites = response.map { it.id }
                
                // Get all local tools
                val localTools = withContext(Dispatchers.IO) {
                    toolDao.getAllTools().first()
                }
                
                // Update favorite status for each tool
                localTools.forEach { tool ->
                    val shouldBeFavorite = tool.id in serverFavorites
                    if (tool.isFavorite != shouldBeFavorite) {
                        toolDao.updateFavoriteStatus(tool.id, shouldBeFavorite)
                    }
                }
                
                logDebug(TAG, "Successfully synced favorite tools")
                return true
            }
        } catch (e: Exception) {
            logError(TAG, "Error syncing favorite tools", e)
        }
        
        return false
    }
    
    /**
     * Helper function to execute API calls safely with error handling.
     *
     * @param apiCall The API call function to execute
     * @return The response body if successful, null otherwise
     */
    private suspend fun <T> executeApiCall(apiCall: suspend () -> Call<T>): T? {
        return try {
            val call = apiCall()
            val response = withContext(Dispatchers.IO) {
                call.execute()
            }
            
            if (response.isSuccessful) {
                response.body()
            } else {
                logError(TAG, "API error: ${response.code()} ${response.message()}")
                null
            }
        } catch (e: Exception) {
            logError(TAG, "Error executing API call", e)
            null
        }
    }
}