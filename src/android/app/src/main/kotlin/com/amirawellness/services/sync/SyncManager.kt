package com.amirawellness.services.sync

import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.repositories.JournalRepository // version: check import statements
import com.amirawellness.data.repositories.EmotionalStateRepository // version: check import statements
import com.amirawellness.data.repositories.ToolRepository // version: check import statements
import com.amirawellness.services.sync.DataQueueManager // version: check import statements
import com.amirawellness.data.remote.api.NetworkMonitor // version: check import statements
import kotlinx.coroutines.flow.Flow // version: 1.6.4
import kotlinx.coroutines.flow.MutableStateFlow // version: 1.6.4
import kotlinx.coroutines.flow.asStateFlow // version: 1.6.4
import kotlinx.coroutines.flow.combine // version: 1.6.4
import kotlinx.coroutines.flow.filter // version: 1.6.4
import kotlinx.coroutines.flow.collect // version: 1.6.4
import kotlinx.coroutines.CoroutineScope // version: 1.6.4
import kotlinx.coroutines.Dispatchers // version: 1.6.4
import kotlinx.coroutines.launch // version: 1.6.4
import kotlinx.coroutines.Job // version: 1.6.4
import kotlinx.coroutines.SupervisorJob // version: 1.6.4
import kotlinx.coroutines.withContext // version: 1.6.4
import javax.inject.Inject // version: 1
import javax.inject.Singleton // version: 1

private const val TAG = "SyncManager"
private const val SYNC_INTERVAL_MS = 900000L // 15 minutes
private const val MAX_RETRY_COUNT = 3

/**
 * Manages data synchronization between local device and remote servers
 */
@Singleton
class SyncManager @Inject constructor(
    private val journalRepository: JournalRepository,
    private val emotionalStateRepository: EmotionalStateRepository,
    private val toolRepository: ToolRepository,
    private val dataQueueManager: DataQueueManager,
    private val networkMonitor: NetworkMonitor
) {

    /**
     * Initializes the SyncManager with required dependencies
     */
    @Inject
    constructor(
        journalRepository: JournalRepository,
        emotionalStateRepository: EmotionalStateRepository,
        toolRepository: ToolRepository,
        dataQueueManager: DataQueueManager,
        networkMonitor: NetworkMonitor
    ) : this(journalRepository, emotionalStateRepository, toolRepository, dataQueueManager, networkMonitor) {
        LogUtils.logDebug(TAG, "SyncManager initialized")
    }

    /**
     * Initialize TAG constant with class name for logging
     */
    private val TAG: String = "SyncManager"

    /**
     * Create coroutine scope with Dispatchers.IO and SupervisorJob
     */
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    /**
     * Initialize syncStateFlow with initial value SyncState.IDLE
     */
    private val syncStateFlow = MutableStateFlow<SyncState>(SyncState.IDLE)

    /**
     * Set syncMonitoringJob to null initially
     */
    private var syncMonitoringJob: Job? = null

    /**
     * Set currentUserId to null initially
     */
    private var currentUserId: String? = null

    /**
     * Initialize lastSyncTimestamp to 0L
     */
    private var lastSyncTimestamp: Long = 0L

    /**
     * Initialize retryCount to 0
     */
    private var retryCount: Int = 0

    /**
     * Initializes the SyncManager for a specific user
     */
    fun initialize(userId: String) {
        LogUtils.logInfo(TAG, "Initializing SyncManager for user: $userId")
        // Store userId in currentUserId property
        currentUserId = userId
        // Start monitoring network status
        startNetworkMonitoring()
        // Start queue processing in DataQueueManager
        dataQueueManager.startQueueProcessing()
    }

    /**
     * Shuts down the SyncManager and stops all synchronization activities
     */
    fun shutdown() {
        LogUtils.logInfo(TAG, "Shutting down SyncManager")
        // Stop network monitoring
        stopNetworkMonitoring()
        // Stop queue processing in DataQueueManager
        dataQueueManager.stopQueueProcessing()
        // Set currentUserId to null
        currentUserId = null
        // Update syncStateFlow to SyncState.IDLE
        syncStateFlow.value = SyncState.IDLE
    }

    /**
     * Starts monitoring network status and triggers synchronization when network becomes available
     */
    private fun startNetworkMonitoring() {
        LogUtils.logDebug(TAG, "Starting network monitoring")
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
                        // Reset retryCount after successful sync
                        retryCount = 0
                    }.onFailure { e ->
                        // If sync fails, increment retryCount and log error
                        retryCount++
                        LogUtils.logError(TAG, "Synchronization failed (attempt $retryCount)", e)
                        // If retryCount exceeds MAX_RETRY_COUNT, log warning and reset retryCount
                        if (retryCount > MAX_RETRY_COUNT) {
                            LogUtils.logError(TAG, "Max retry count reached, synchronization will be retried later")
                            retryCount = 0
                        }
                    }
                }
            }
        }
    }

    /**
     * Stops monitoring network status and synchronization
     */
    private fun stopNetworkMonitoring() {
        LogUtils.logDebug(TAG, "Stopping network monitoring")
        // Cancel sync monitoring job if it exists
        syncMonitoringJob?.cancel()
        // Set syncMonitoringJob to null
        syncMonitoringJob = null
    }

    /**
     * Synchronizes all data types with the server
     */
    suspend fun synchronizeAll(): Result<Boolean> {
        LogUtils.logInfo(TAG, "Synchronizing all data")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // If currentUserId is null, return Result.failure with IllegalStateException
        if (currentUserId == null) {
            return Result.failure(IllegalStateException("User ID not initialized"))
        }
        return try {
            // Update syncStateFlow to SyncState.SYNCING
            syncStateFlow.value = SyncState.SYNCING
            // Process queued operations with dataQueueManager.processQueue()
            dataQueueManager.processQueue()
            // Synchronize journals with journalRepository.syncJournals(currentUserId!!)
            journalRepository.syncJournals(currentUserId!!)
            // Synchronize emotional states with emotionalStateRepository.syncEmotionalStates(currentUserId!!)
            emotionalStateRepository.syncEmotionalStates(currentUserId!!)
            // Refresh tool categories with toolRepository.refreshToolCategories()
            toolRepository.refreshToolCategories()
            // Refresh tools with toolRepository.refreshTools()
            toolRepository.refreshTools()
            // Synchronize tool favorites with toolRepository.syncFavorites()
            toolRepository.syncFavorites()
            // Update syncStateFlow to SyncState.IDLE
            syncStateFlow.value = SyncState.IDLE
            // Return Result.success with true
            Result.success(true)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error during full synchronization", e)
            // Update syncStateFlow to SyncState.ERROR
            syncStateFlow.value = SyncState.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Synchronizes only journal data with the server
     */
    suspend fun synchronizeJournals(): Result<Int> {
        LogUtils.logInfo(TAG, "Synchronizing journals")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // If currentUserId is null, return Result.failure with IllegalStateException
        if (currentUserId == null) {
            return Result.failure(IllegalStateException("User ID not initialized"))
        }
        return try {
            // Update syncStateFlow to SyncState.SYNCING
            syncStateFlow.value = SyncState.SYNCING
            // Synchronize journals with journalRepository.syncJournals(currentUserId!!)
            val syncedCount = journalRepository.syncJournals(currentUserId!!).getOrThrow()
            // Update syncStateFlow to SyncState.IDLE
            syncStateFlow.value = SyncState.IDLE
            // Return Result.success with the count of synchronized journals
            Result.success(syncedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error synchronizing journals", e)
            // Update syncStateFlow to SyncState.ERROR
            syncStateFlow.value = SyncState.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Synchronizes only emotional state data with the server
     */
    suspend fun synchronizeEmotionalStates(): Result<Int> {
        LogUtils.logInfo(TAG, "Synchronizing emotional states")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        // If currentUserId is null, return Result.failure with IllegalStateException
        if (currentUserId == null) {
            return Result.failure(IllegalStateException("User ID not initialized"))
        }
        return try {
            // Update syncStateFlow to SyncState.SYNCING
            syncStateFlow.value = SyncState.SYNCING
            // Synchronize emotional states with emotionalStateRepository.syncEmotionalStates(currentUserId!!)
            val syncedCount = emotionalStateRepository.syncEmotionalStates(currentUserId!!).getOrThrow()
            // Update syncStateFlow to SyncState.IDLE
            syncStateFlow.value = SyncState.IDLE
            // Return Result.success with the count of synchronized emotional states
            Result.success(syncedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error synchronizing emotional states", e)
            // Update syncStateFlow to SyncState.ERROR
            syncStateFlow.value = SyncState.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Synchronizes tool data with the server
     */
    suspend fun synchronizeTools(): Result<Boolean> {
        LogUtils.logInfo(TAG, "Synchronizing tools")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        return try {
            // Update syncStateFlow to SyncState.SYNCING
            syncStateFlow.value = SyncState.SYNCING
            // Refresh tool categories with toolRepository.refreshToolCategories()
            toolRepository.refreshToolCategories()
            // Refresh tools with toolRepository.refreshTools()
            toolRepository.refreshTools()
            // Synchronize tool favorites with toolRepository.syncFavorites()
            toolRepository.syncFavorites()
            // Update syncStateFlow to SyncState.IDLE
            syncStateFlow.value = SyncState.IDLE
            // Return Result.success with true
            Result.success(true)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error synchronizing tools", e)
            // Update syncStateFlow to SyncState.ERROR
            syncStateFlow.value = SyncState.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Processes all queued operations
     */
    suspend fun processQueuedOperations(): Result<Int> {
        LogUtils.logInfo(TAG, "Processing queued operations")
        // If network is not available, return Result.failure with NetworkUnavailableException
        if (!networkMonitor.isNetworkAvailable()) {
            return Result.failure(NetworkUnavailableException("Network unavailable"))
        }
        return try {
            // Update syncStateFlow to SyncState.SYNCING
            syncStateFlow.value = SyncState.SYNCING
            // Process queued operations with dataQueueManager.processQueue()
            val processedCount = dataQueueManager.processQueue().getOrThrow()
            // Update syncStateFlow to SyncState.IDLE
            syncStateFlow.value = SyncState.IDLE
            // Return Result.success with the count of processed operations
            Result.success(processedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error processing queued operations", e)
            // Update syncStateFlow to SyncState.ERROR
            syncStateFlow.value = SyncState.ERROR
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Gets the current synchronization state
     */
    fun getSyncState(): Flow<SyncState> {
        return syncStateFlow.asStateFlow()
    }

    /**
     * Gets a flow of synchronization progress information
     */
    fun getSyncProgress(): Flow<SyncProgress> {
        return combine(
            syncStateFlow,
            dataQueueManager.getQueuedOperationCount(),
            dataQueueManager.isProcessing()
        ) { state, pendingOperations, isProcessing ->
            SyncProgress(state, pendingOperations, isProcessing)
        }
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
        val timeElapsed = currentTime - lastSyncTimestamp
        // Return true if elapsed time is greater than SYNC_INTERVAL_MS
        return timeElapsed > SYNC_INTERVAL_MS || lastSyncTimestamp == 0L // Also sync if never synced
    }

    /**
     * Forces an immediate synchronization regardless of the sync interval
     */
    suspend fun forceSynchronization(): Result<Boolean> {
        LogUtils.logInfo(TAG, "Forcing synchronization")
        // Call synchronizeAll() to perform full synchronization
        return synchronizeAll()
        // Return the result of synchronizeAll()
    }

    /**
     * Enum representing the current synchronization state
     */
    enum class SyncState {
        IDLE,
        SYNCING,
        ERROR
    }

    /**
     * Data class representing synchronization progress information
     */
    data class SyncProgress(
        val state: SyncState,
        val pendingOperations: Int,
        val isProcessing: Boolean
    )

    /**
     * Exception thrown when a network operation is attempted without connectivity
     */
    class NetworkUnavailableException(message: String) : Exception(message)
}