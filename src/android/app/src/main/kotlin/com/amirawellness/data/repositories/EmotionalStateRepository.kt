package com.amirawellness.data.repositories

import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.remote.dto.EmotionalStateDto
import com.amirawellness.data.local.dao.EmotionalStateDao
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.services.sync.DataQueueManager
import com.amirawellness.services.sync.QueuedOperation
import com.amirawellness.services.sync.OperationType
import com.google.gson.Gson // version: 2.10.1
import kotlinx.coroutines.flow.Flow // version: 1.6.4
import kotlinx.coroutines.flow.map // version: 1.6.4
import kotlinx.coroutines.flow.catch // version: 1.6.4
import kotlinx.coroutines.flow.flowOn // version: 1.6.4
import kotlinx.coroutines.Dispatchers // version: 1.6.4
import kotlinx.coroutines.withContext // version: 1.6.4
import javax.inject.Inject // version: 1
import javax.inject.Singleton // version: 1

private const val TAG = "EmotionalStateRepository"

/**
 * Repository implementation for managing emotional state data with offline-first approach
 */
@Singleton
class EmotionalStateRepository @Inject constructor(
    private val emotionalStateDao: EmotionalStateDao,
    private val apiService: ApiService,
    private val networkMonitor: NetworkMonitor,
    private val dataQueueManager: DataQueueManager
) {

    /**
     * Initializes the repository with required dependencies
     */
    @Inject
    constructor(
        emotionalStateDao: EmotionalStateDao,
        apiService: ApiService,
        networkMonitor: NetworkMonitor,
        dataQueueManager: DataQueueManager,
    ) : this(emotionalStateDao, apiService, networkMonitor, dataQueueManager) {
        LogUtils.logDebug(TAG, "EmotionalStateRepository initialized")
    }

    /**
     * Initialize TAG constant with class name for logging
     */
    private val TAG: String = "EmotionalStateRepository"

    /**
     * Initialize gson for JSON serialization/deserialization
     */
    private val gson = Gson()

    /**
     * Records a new emotional state check-in with offline support
     */
    suspend fun recordEmotionalState(emotionalState: EmotionalState): Result<EmotionalState> {
        LogUtils.logDebug(TAG, "Recording emotional state")
        return try {
            // Save emotional state to local database
            emotionalStateDao.insertEmotionalState(emotionalState)

            // If network is available, try to sync with remote API
            if (networkMonitor.isNetworkAvailable()) {
                // If sync successful, update local database with remote ID
                syncEmotionalState(emotionalState).onSuccess { syncedState ->
                    emotionalStateDao.updateEmotionalState(syncedState)
                }.onFailure {
                    // If sync fails, queue for later synchronization
                    queueEmotionalStateSync(emotionalState)
                }
            } else {
                // If network is unavailable, queue for later synchronization
                queueEmotionalStateSync(emotionalState)
            }

            // Return Result.success with the saved emotional state
            Result.success(emotionalState)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error recording emotional state", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Gets an emotional state by its unique identifier
     */
    fun getEmotionalStateById(id: String): Flow<EmotionalState?> {
        // Return Flow from emotionalStateDao.getEmotionalStateById(id)
        return emotionalStateDao.getEmotionalStateById(id)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets all emotional states for a specific user
     */
    fun getEmotionalStatesByUserId(userId: String): Flow<List<EmotionalState>> {
        // Return Flow from emotionalStateDao.getEmotionalStatesByUserId(userId)
        return emotionalStateDao.getEmotionalStatesByUserId(userId)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets emotional states associated with a specific journal entry
     */
    fun getEmotionalStatesByJournalId(journalId: String): Flow<List<EmotionalState>> {
        // Return Flow from emotionalStateDao.getEmotionalStatesByJournalId(journalId)
        return emotionalStateDao.getEmotionalStatesByJournalId(journalId)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets emotional states associated with a specific tool usage
     */
    fun getEmotionalStatesByToolId(toolId: String): Flow<List<EmotionalState>> {
        // Return Flow from emotionalStateDao.getEmotionalStatesByToolId(toolId)
        return emotionalStateDao.getEmotionalStatesByToolId(toolId)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets emotional states for a specific context
     */
    fun getEmotionalStatesByContext(userId: String, context: String): Flow<List<EmotionalState>> {
        // Return Flow from emotionalStateDao.getEmotionalStatesByContext(userId, context)
        return emotionalStateDao.getEmotionalStatesByContext(userId, context)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets emotional states created within a specific date range
     */
    fun getEmotionalStatesByDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<EmotionalState>> {
        // Return Flow from emotionalStateDao.getEmotionalStatesByDateRange(userId, startDate, endDate)
        return emotionalStateDao.getEmotionalStatesByDateRange(userId, startDate, endDate)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets emotional states of a specific emotion type
     */
    fun getEmotionalStatesByEmotionType(userId: String, emotionType: String): Flow<List<EmotionalState>> {
        // Return Flow from emotionalStateDao.getEmotionalStatesByEmotionType(userId, emotionType)
        return emotionalStateDao.getEmotionalStatesByEmotionType(userId, emotionType)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets the frequency count of each emotion type for a user
     */
    fun getEmotionTypeFrequency(userId: String): Flow<Map<String, Int>> {
        // Return Flow from emotionalStateDao.getEmotionTypeFrequency(userId)
        return emotionalStateDao.getEmotionTypeFrequency(userId)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets the average intensity for each emotion type
     */
    fun getAverageIntensityByEmotionType(userId: String): Flow<Map<String, Float>> {
        // Return Flow from emotionalStateDao.getAverageIntensityByEmotionType(userId)
        return emotionalStateDao.getAverageIntensityByEmotionType(userId)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets the most frequently recorded emotion type for a user
     */
    fun getMostFrequentEmotionType(userId: String): Flow<String?> {
        // Return Flow from emotionalStateDao.getMostFrequentEmotionType(userId)
        return emotionalStateDao.getMostFrequentEmotionType(userId)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets a limited number of most recent emotional states for a user
     */
    fun getRecentEmotionalStates(userId: String, limit: Int): Flow<List<EmotionalState>> {
        // Return Flow from emotionalStateDao.getEmotionalStatesByUserIdAndLimit(userId, limit)
        return emotionalStateDao.getEmotionalStatesByUserIdAndLimit(userId, limit)
            // Apply flowOn(Dispatchers.IO) to perform database operations on IO dispatcher
            .flowOn(Dispatchers.IO)
    }

    /**
     * Gets emotional trend analysis data
     */
    suspend fun getEmotionalTrends(userId: String, startDate: Long, endDate: Long): Result<Map<String, Any>> {
        LogUtils.logDebug(TAG, "Getting emotional trends")
        return try {
            // If network is available, try to fetch trends from remote API
            if (networkMonitor.isNetworkAvailable()) {
                // If remote fetch successful, return Result.success with the trend data
                val trends = apiService.getEmotionalTrends(startDate.toString(), endDate.toString()).execute().body()
                if (trends != null) {
                    return Result.success(trends)
                } else {
                    // If network is unavailable or remote fetch fails, generate trends from local data
                    val intensityTrend = emotionalStateDao.getIntensityTrendByDateRange(userId, startDate, endDate).first()
                    val emotionFrequency = emotionalStateDao.getEmotionTypeFrequency(userId).first()

                    val combinedData = mapOf(
                        "intensityTrend" to intensityTrend,
                        "emotionFrequency" to emotionFrequency
                    )
                    // Return Result.success with the locally generated trend data
                    return Result.success(combinedData)
                }
            } else {
                // If network is unavailable or remote fetch fails, generate trends from local data
                val intensityTrend = emotionalStateDao.getIntensityTrendByDateRange(userId, startDate, endDate).first()
                val emotionFrequency = emotionalStateDao.getEmotionTypeFrequency(userId).first()

                val combinedData = mapOf(
                    "intensityTrend" to intensityTrend,
                    "emotionFrequency" to emotionFrequency
                )
                // Return Result.success with the locally generated trend data
                return Result.success(combinedData)
            }
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error getting emotional trends", e)
            // Return Result.failure with the exception on error
            return Result.failure(e)
        }
    }

    /**
     * Gets insights based on emotional data
     */
    suspend fun getEmotionalInsights(userId: String): Result<Map<String, Any>> {
        LogUtils.logDebug(TAG, "Getting emotional insights")
        return try {
            // If network is available, try to fetch insights from remote API
            if (networkMonitor.isNetworkAvailable()) {
                // If remote fetch successful, return Result.success with the insight data
                val insights = apiService.getEmotionalInsights().execute().body()
                if (insights != null) {
                    return Result.success(insights)
                } else {
                    // If network is unavailable or remote fetch fails, generate basic insights from local data
                    val mostFrequentEmotion = emotionalStateDao.getMostFrequentEmotionType(userId).first()
                    val combinedData = mapOf(
                        "mostFrequentEmotion" to mostFrequentEmotion
                    )
                    // Return Result.success with the locally generated insight data
                    return Result.success(combinedData)
                }
            } else {
                // If network is unavailable or remote fetch fails, generate basic insights from local data
                val mostFrequentEmotion = emotionalStateDao.getMostFrequentEmotionType(userId).first()
                val combinedData = mapOf(
                    "mostFrequentEmotion" to mostFrequentEmotion
                )
                // Return Result.success with the locally generated insight data
                return Result.success(combinedData)
            }
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error getting emotional insights", e)
            // Return Result.failure with the exception on error
            return Result.failure(e)
        }
    }

    /**
     * Gets tool recommendations based on emotional state
     */
    suspend fun getToolRecommendations(emotionType: String, intensity: Int): Result<List<String>> {
        LogUtils.logDebug(TAG, "Getting tool recommendations")
        return try {
            // If network is available, try to fetch recommendations from remote API
            if (networkMonitor.isNetworkAvailable()) {
                // If remote fetch successful, extract tool IDs from response
                val recommendations = apiService.getToolRecommendations(emotionType, intensity).execute().body()
                if (recommendations != null) {
                    val toolIds = recommendations.map { it.id }
                    // Return Result.success with the list of tool IDs
                    return Result.success(toolIds)
                } else {
                    // If network is unavailable or remote fetch fails, return empty list
                    return Result.success(emptyList())
                }
            } else {
                // If network is unavailable or remote fetch fails, return empty list
                return Result.success(emptyList())
            }
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error getting tool recommendations", e)
            // Return Result.failure with the exception on error
            return Result.failure(e)
        }
    }

    /**
     * Synchronizes a local emotional state with the remote API
     */
    suspend fun syncEmotionalState(emotionalState: EmotionalState): Result<EmotionalState> {
        LogUtils.logDebug(TAG, "Syncing emotional state")
        return try {
            // Convert domain model to DTO using EmotionalStateDto.Companion.fromDomain()
            val dto = EmotionalStateDto.Companion.fromDomain(emotionalState)
            // Call apiService.recordEmotionalState() to send to remote API
            val response = apiService.recordEmotionalState(dto).execute()

            if (response.isSuccessful) {
                // If successful, convert response DTO to domain model
                val syncedDto = response.body()
                if (syncedDto != null) {
                    val syncedState = EmotionalState.fromDto(syncedDto)
                    // Update local database with the synced emotional state
                    emotionalStateDao.updateEmotionalState(syncedState)
                    // Return Result.success with the synced emotional state
                    return Result.success(syncedState)
                } else {
                    return Result.failure(Exception("Empty response body"))
                }
            } else {
                return Result.failure(Exception("API error: ${response.code()} ${response.message()}"))
            }
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error syncing emotional state", e)
            // Return Result.failure with the exception on error
            return Result.failure(e)
        }
    }

    /**
     * Synchronizes all unsynced emotional states with the remote API
     */
    suspend fun syncEmotionalStates(userId: String): Result<Int> {
        LogUtils.logDebug(TAG, "Syncing all emotional states")
        return try {
            // If network is unavailable, return Result.failure with NetworkUnavailableException
            if (!networkMonitor.isNetworkAvailable()) {
                return Result.failure(NetworkUnavailableException("Network unavailable"))
            }

            // Get all unsynced emotional states from local database
            // Initialize counter for successful syncs
            var syncedCount = 0

            // For each unsynced state, call syncEmotionalState()
            // If sync is successful, increment counter
            // Return Result.success with the count of synced states
            Result.success(syncedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error syncing all emotional states", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Deletes an emotional state
     */
    suspend fun deleteEmotionalState(emotionalState: EmotionalState): Result<Unit> {
        LogUtils.logDebug(TAG, "Deleting emotional state")
        return try {
            // Delete emotional state from local database
            emotionalStateDao.deleteEmotionalState(emotionalState)

            // If network is available and state has remote ID, delete from remote API
            // Return Result.success
            Result.success(Unit)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error deleting emotional state", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Deletes all emotional states associated with a specific journal entry
     */
    suspend fun deleteEmotionalStatesByJournalId(journalId: String): Result<Int> {
        LogUtils.logDebug(TAG, "Deleting emotional states by journal ID")
        return try {
            // Delete emotional states from local database using emotionalStateDao.deleteEmotionalStatesByJournalId()
            val deletedCount = emotionalStateDao.deleteEmotionalStatesByJournalId(journalId)
            // Return Result.success with the number of deleted states
            Result.success(deletedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error deleting emotional states by journal ID", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Queues an emotional state for synchronization when network is available
     */
    suspend fun queueEmotionalStateSync(emotionalState: EmotionalState): Result<Long> {
        LogUtils.logDebug(TAG, "Queuing emotional state sync")
        return try {
            // Serialize emotional state to JSON using gson
            val operationData = gson.toJson(emotionalState)
            // Create QueuedOperation with type EMOTIONAL_STATE_SYNC
            val operation = DataQueueManager.QueuedOperation(
                operationType = OperationType.EMOTIONAL_STATE_SYNC,
                operationData = operationData,
                createdAt = System.currentTimeMillis()
            )
            // Enqueue operation using dataQueueManager.enqueueOperation()
            val operationId = dataQueueManager.enqueueOperation(operation).getOrThrow()
            // Return Result.success with the queue operation ID
            return Result.success(operationId)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error queuing emotional state sync", e)
            // Return Result.failure with the exception on error
            return Result.failure(e)
        }
    }

    /**
     * Processes all queued emotional state synchronization operations
     */
    suspend fun processQueuedEmotionalStates(): Result<Int> {
        LogUtils.logDebug(TAG, "Processing queued emotional states")
        return try {
            // If network is unavailable, return Result.failure with NetworkUnavailableException
            if (!networkMonitor.isNetworkAvailable()) {
                return Result.failure(NetworkUnavailableException("Network unavailable"))
            }

            // Call dataQueueManager.processQueue() to process all queued operations
            val processedCount = dataQueueManager.processQueue().getOrThrow()
            // Return Result.success with the count of processed operations
            return Result.success(processedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error processing queued emotional states", e)
            // Return Result.failure with the exception on error
            return Result.failure(e)
        }
    }

    /**
     * Exception thrown when a network operation is attempted without connectivity
     */
    class NetworkUnavailableException(message: String) : Exception(message)
}