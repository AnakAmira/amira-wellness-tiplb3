package com.amirawellness.services.sync

import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.data.repositories.EmotionalStateRepository
import com.amirawellness.data.repositories.ToolRepository
import com.amirawellness.services.sync.DataQueueManager
import com.amirawellness.data.remote.api.NetworkMonitor
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.filter // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.collect // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.CoroutineScope // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.Job // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.SupervisorJob // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.withContext // kotlinx.coroutines version: 1.6.4
import javax.inject.Inject // javax.inject version: 1
import javax.inject.Singleton // javax.inject version: 1

/**
 * Manages offline data synchronization for the Amira Wellness Android application.
 * This class coordinates the synchronization of locally stored data with remote servers when
 * network connectivity is available, ensuring data consistency across the application while
 * supporting offline-first functionality.
 */
@Singleton
class OfflineDataManager @Inject constructor(
    private val journalRepository: JournalRepository,
    private val emotionalStateRepository: EmotionalStateRepository,
    private val toolRepository: ToolRepository,
    private val dataQueueManager: DataQueueManager,
    private val networkMonitor: NetworkMonitor
) {

    init {
        LogUtils.logDebug(TAG, "OfflineDataManager initialized")
    }

    /**
     * Initializes the OfflineDataManager with required dependencies
     *
     * @param journalRepository Repository for journal data operations and synchronization
     * @param emotionalStateRepository Repository for emotional state data operations and synchronization
     * @param toolRepository Repository for tool data operations and synchronization
     * @param dataQueueManager Manages queue of operations to be performed when online
     * @param networkMonitor Monitors network connectivity status
     */
    @Inject
    constructor(
        journalRepository: JournalRepository,
        emotionalStateRepository: EmotionalStateRepository,
        toolRepository: ToolRepository,
        dataQueueManager: DataQueueManager,
        networkMonitor: NetworkMonitor,
    ) : this(journalRepository, emotionalStateRepository, toolRepository, dataQueueManager, networkMonitor) {
        LogUtils.logDebug(TAG, "OfflineDataManager initialized")
    }

    /**
     * Initialize TAG constant with class name for logging
     */
    private val TAG: String = "OfflineDataManager"

    /**
     * Create coroutine scope with Dispatchers.IO and SupervisorJob
     */
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    /**
     * Mutable state holder for sync status
     */
    private val syncStatusFlow = MutableStateFlow(SyncStatus.IDLE)

    /**
     * Handle to coroutine for cancellation
     */
    private var syncMonitoringJob: Job? = null

    /**
     * User ID for whom the sync is being monitored
     */
    private var currentUserId: String? = null

    /**
     * Timestamp of the last successful sync
     */
    private var lastSyncTimestamp: Long = 0L

    /**
     * Starts monitoring network status and triggers synchronization when network becomes available
     *
     * @param userId
     */
    fun startSyncMonitoring(userId: String) {
        LogUtils.logInfo(TAG, "Starting sync monitoring for user: $userId")
        // Store userId in currentUserId property
        currentUserId = userId
        // Cancel any existing sync monitoring job
        syncMonitoringJob?.cancel()
        // Launch new coroutine in scope
        syncMonitoringJob = scope.launch {
            // Collect network status flow filtered for network available events
            networkMonitor.getNetworkStatusFlow().filter { it }.collect {
                // For each network available event, check if sync is needed
                if (isSyncNeeded()) {
                    // If sync is needed (based on time since last sync), call synchronizeAll()
                    synchronizeAll().onSuccess {
                        // Update lastSyncTimestamp after successful sync
                        lastSyncTimestamp = System.currentTimeMillis()
                    }.onFailure { e ->
                        // Log any errors during monitoring
                        LogUtils.logError(TAG, "Error during synchronization", e)
                    }
                }
            }
        }
    }

    /**
     * Stops monitoring network status and synchronization
     */
    fun stopSyncMonitoring() {
        LogUtils.logInfo(TAG, "Stopping sync monitoring")
        // Cancel sync monitoring job if it exists
        syncMonitoringJob?.cancel()
        // Set syncMonitoringJob to null
        syncMonitoringJob = null
        // Set currentUserId to null
        currentUserId = null
        // Update syncStatusFlow to SyncStatus.IDLE
        syncStatusFlow.value = SyncStatus.IDLE
    }

    /**
     * Synchronizes all data types with the server
     */
    suspend fun synchronizeAll(): Result<Boolean> {
        LogUtils.logDebug(TAG, "Synchronizing all data")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // If currentUserId is null, return Result.failure with IllegalStateException
        if (currentUserId == null) {
            return Result.failure(IllegalStateException("User ID is null"))
        }
        // Update syncStatusFlow to SyncStatus.SYNCING
        syncStatusFlow.value = SyncStatus.SYNCING
        return try {
            // Process queued operations with dataQueueManager.processQueue()
            dataQueueManager.processQueue().getOrThrow()
            // Synchronize journals with journalRepository.syncJournals(currentUserId!!)
            journalRepository.syncJournals(currentUserId!!).getOrThrow()
            // Synchronize emotional states with emotionalStateRepository.syncEmotionalStates(currentUserId!!)
            emotionalStateRepository.syncEmotionalStates(currentUserId!!).getOrThrow()
            // Refresh tool categories with toolRepository.refreshToolCategories()
            toolRepository.refreshToolCategories()
            // Refresh tools with toolRepository.refreshTools()
            toolRepository.refreshTools()
            // Synchronize tool favorites with toolRepository.syncFavorites()
            toolRepository.syncFavorites()
            // Update syncStatusFlow to SyncStatus.IDLE
            syncStatusFlow.value = SyncStatus.IDLE
            // Return Result.success with true
            Result.success(true)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error synchronizing all data", e)
            // Update syncStatusFlow to SyncStatus.ERROR
            syncStatusFlow.value = SyncStatus.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Synchronizes only journal data with the server
     */
    suspend fun synchronizeJournals(): Result<Int> {
        LogUtils.logDebug(TAG, "Synchronizing journals")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // If currentUserId is null, return Result.failure with IllegalStateException
        if (currentUserId == null) {
            return Result.failure(IllegalStateException("User ID is null"))
        }
        // Update syncStatusFlow to SyncStatus.SYNCING
        syncStatusFlow.value = SyncStatus.SYNCING
        return try {
            // Synchronize journals with journalRepository.syncJournals(currentUserId!!)
            val syncedCount = journalRepository.syncJournals(currentUserId!!).getOrThrow()
            // Update syncStatusFlow to SyncStatus.IDLE
            syncStatusFlow.value = SyncStatus.IDLE
            // Return Result.success with the count of synchronized journals
            Result.success(syncedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error synchronizing journals", e)
            // Update syncStatusFlow to SyncStatus.ERROR
            syncStatusFlow.value = SyncStatus.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Synchronizes only emotional state data with the server
     */
    suspend fun synchronizeEmotionalStates(): Result<Int> {
        LogUtils.logDebug(TAG, "Synchronizing emotional states")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // If currentUserId is null, return Result.failure with IllegalStateException
        if (currentUserId == null) {
            return Result.failure(IllegalStateException("User ID is null"))
        }
        // Update syncStatusFlow to SyncStatus.SYNCING
        syncStatusFlow.value = SyncStatus.SYNCING
        return try {
            // Synchronize emotional states with emotionalStateRepository.syncEmotionalStates(currentUserId!!)
            val syncedCount = emotionalStateRepository.syncEmotionalStates(currentUserId!!).getOrThrow()
            // Update syncStatusFlow to SyncStatus.IDLE
            syncStatusFlow.value = SyncStatus.IDLE
            // Return Result.success with the count of synchronized emotional states
            Result.success(syncedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error synchronizing emotional states", e)
            // Update syncStatusFlow to SyncStatus.ERROR
            syncStatusFlow.value = SyncStatus.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Synchronizes tool data with the server
     */
    suspend fun synchronizeTools(): Result<Boolean> {
        LogUtils.logDebug(TAG, "Synchronizing tools")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // Update syncStatusFlow to SyncStatus.SYNCING
        syncStatusFlow.value = SyncStatus.SYNCING
        return try {
            // Refresh tool categories with toolRepository.refreshToolCategories()
            toolRepository.refreshToolCategories()
            // Refresh tools with toolRepository.refreshTools()
            toolRepository.refreshTools()
            // Synchronize tool favorites with toolRepository.syncFavorites()
            toolRepository.syncFavorites()
            // Update syncStatusFlow to SyncStatus.IDLE
            syncStatusFlow.value = SyncStatus.IDLE
            // Return Result.success with true
            Result.success(true)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error synchronizing tools", e)
            // Update syncStatusFlow to SyncStatus.ERROR
            syncStatusFlow.value = SyncStatus.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Processes all queued operations
     */
    suspend fun processQueuedOperations(): Result<Int> {
        LogUtils.logDebug(TAG, "Processing queued operations")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // Update syncStatusFlow to SyncStatus.SYNCING
        syncStatusFlow.value = SyncStatus.SYNCING
        return try {
            // Process queued operations with dataQueueManager.processQueue()
            val processedCount = dataQueueManager.processQueue().getOrThrow()
            // Update syncStatusFlow to SyncStatus.IDLE
            syncStatusFlow.value = SyncStatus.IDLE
            // Return Result.success with the count of processed operations
            Result.success(processedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error processing queued operations", e)
            // Update syncStatusFlow to SyncStatus.ERROR
            syncStatusFlow.value = SyncStatus.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Gets the current synchronization status
     */
    fun getSyncStatus(): Flow<SyncStatus> {
        return syncStatusFlow.asStateFlow()
    }

    /**
     * Checks if network connectivity is currently available
     */
    fun isNetworkAvailable(): Boolean {
        return networkMonitor.isNetworkAvailable()
    }

    /**
     * Determines if synchronization is needed based on time since last sync
     */
    private fun isSyncNeeded(): Boolean {
        // Get current time in milliseconds
        val currentTime = System.currentTimeMillis()
        // Calculate time elapsed since last sync
        val elapsedTime = currentTime - lastSyncTimestamp
        // Return true if elapsed time is greater than SYNC_INTERVAL_MS
        if (elapsedTime > SYNC_INTERVAL_MS) {
            return true
        }
        // Return true if lastSyncTimestamp is 0 (never synced)
        if (lastSyncTimestamp == 0L) {
            return true
        }
        // Otherwise return false
        return false
    }

    /**
     * Enum representing the current synchronization status
     */
    enum class SyncStatus {
        IDLE,
        SYNCING,
        ERROR
    }

    /**
     * Exception thrown when a network operation is attempted without connectivity
     */
    class NetworkUnavailableException(message: String) : Exception(message)

    companion object {
        /**
         * Time interval between automatic synchronizations (15 minutes)
         */
        private const val SYNC_INTERVAL_MS = 900000L
    }
}