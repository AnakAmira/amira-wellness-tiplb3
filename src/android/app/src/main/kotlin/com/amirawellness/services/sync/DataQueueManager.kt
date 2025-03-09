package com.amirawellness.services.sync

import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.Journal
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.data.repositories.ToolRepository
import com.amirawellness.data.remote.api.NetworkMonitor
import com.google.gson.Gson // version: 2.9.0
import kotlinx.coroutines.CoroutineScope // version: 1.6.4
import kotlinx.coroutines.Dispatchers // version: 1.6.4
import kotlinx.coroutines.Job // version: 1.6.4
import kotlinx.coroutines.SupervisorJob // version: 1.6.4
import kotlinx.coroutines.delay // version: 1.6.4
import kotlinx.coroutines.flow.Flow // version: 1.6.4
import kotlinx.coroutines.flow.MutableStateFlow // version: 1.6.4
import kotlinx.coroutines.flow.asStateFlow // version: 1.6.4
import kotlinx.coroutines.flow.collect // version: 1.6.4
import kotlinx.coroutines.flow.filter // version: 1.6.4
import kotlinx.coroutines.launch // version: 1.6.4
import kotlinx.coroutines.withContext // version: 1.6.4
import javax.inject.Inject // version: 1
import javax.inject.Singleton // version: 1

private const val TAG = "DataQueueManager"
private const val MAX_RETRY_COUNT = 3
private const val RETRY_DELAY_MS = 5000L

/**
 * Manages a queue of operations to be performed when network connectivity is available
 */
@Singleton
class DataQueueManager @Inject constructor(
    private val journalRepository: JournalRepository,
    private val toolRepository: ToolRepository,
    private val networkMonitor: NetworkMonitor,
    private val queuedOperationDao: QueuedOperationDao
) {

    /**
     * Enum representing the type of queued operation
     */
    enum class OperationType {
        JOURNAL_UPLOAD,
        EMOTIONAL_STATE_SYNC,
        TOOL_USAGE_SYNC
    }

    /**
     * Enum representing the status of a queued operation
     */
    enum class OperationStatus {
        PENDING,
        IN_PROGRESS,
        COMPLETED,
        FAILED
    }

    /**
     * Data Access Object for queued operations
     */
    @androidx.room.Dao // androidx.room:2.5.0
    interface QueuedOperationDao {
        @androidx.room.Insert // androidx.room:2.5.0
        suspend fun insertOperation(operation: QueuedOperation): Long

        @androidx.room.Update // androidx.room:2.5.0
        suspend fun updateOperation(operation: QueuedOperation): Int

        @androidx.room.Delete // androidx.room:2.5.0
        suspend fun deleteOperation(operation: QueuedOperation): Int

        @androidx.room.Query("SELECT * FROM queued_operations WHERE id = :id") // androidx.room:2.5.0
        suspend fun getOperationById(id: Long): QueuedOperation?

        @androidx.room.Query("SELECT * FROM queued_operations WHERE status = 'PENDING' ORDER BY created_at ASC") // androidx.room:2.5.0
        suspend fun getPendingOperations(): List<QueuedOperation>

        @androidx.room.Query("SELECT * FROM queued_operations WHERE status = 'FAILED' ORDER BY created_at ASC") // androidx.room:2.5.0
        suspend fun getFailedOperations(): List<QueuedOperation>

        @androidx.room.Query("SELECT COUNT(*) FROM queued_operations WHERE status = 'PENDING' OR status = 'FAILED'") // androidx.room:2.5.0
        fun getOperationCount(): Flow<Int>

        @androidx.room.Query("DELETE FROM queued_operations WHERE status = 'COMPLETED' AND completed_at < :cutoffDate") // androidx.room:2.5.0
        suspend fun deleteCompletedOperations(cutoffDate: Long): Int

        @androidx.room.Query("UPDATE queued_operations SET status = 'PENDING', retry_count = 0, error_message = NULL WHERE status = 'FAILED'") // androidx.room:2.5.0
        suspend fun resetFailedOperations(): Int
    }

    /**
     * Entity representing an operation in the queue
     */
    @androidx.room.Entity(tableName = "queued_operations") // androidx.room:2.5.0
    data class QueuedOperation(
        @androidx.room.PrimaryKey(autoGenerate = true) // androidx.room:2.5.0
        val id: Long = 0,
        @androidx.room.ColumnInfo(name = "operation_type") // androidx.room:2.5.0
        val operationType: OperationType,
        @androidx.room.ColumnInfo(name = "operation_data") // androidx.room:2.5.0
        val operationData: String,
        @androidx.room.ColumnInfo(name = "created_at") // androidx.room:2.5.0
        val createdAt: Long,
        @androidx.room.ColumnInfo(name = "status") // androidx.room:2.5.0
        var status: OperationStatus = OperationStatus.PENDING,
        @androidx.room.ColumnInfo(name = "retry_count") // androidx.room:2.5.0
        var retryCount: Int = 0,
        @androidx.room.ColumnInfo(name = "last_attempt") // androidx.room:2.5.0
        var lastAttempt: Long? = null,
        @androidx.room.ColumnInfo(name = "completed_at") // androidx.room:2.5.0
        var completedAt: Long? = null,
        @androidx.room.ColumnInfo(name = "error_message") // androidx.room:2.5.0
        var errorMessage: String? = null
    ) {
        /**
         * Creates a copy of the operation with updated status
         */
        fun withUpdatedStatus(newStatus: OperationStatus, errorMessage: String? = null): QueuedOperation {
            return this.copy(status = newStatus, errorMessage = errorMessage)
        }

        /**
         * Creates a copy of the operation with incremented retry count
         */
        fun incrementRetryCount(): QueuedOperation {
            return this.copy(retryCount = retryCount + 1)
        }
    }

    init {
        LogUtils.logDebug(TAG, "Initializing DataQueueManager")
        // Store provided dependencies as properties
        // Create coroutine scope with Dispatchers.IO and SupervisorJob
        val job = SupervisorJob()
        scope = CoroutineScope(Dispatchers.IO + job)
        // Initialize processingFlow with initial value false
        processingFlow = MutableStateFlow(false)
        // Set processingJob to null initially
        processingJob = null
    }

    private val gson = Gson()
    private val scope: CoroutineScope
    private val processingFlow: MutableStateFlow<Boolean>
    private var processingJob: Job?

    /**
     * Adds an operation to the queue for later execution
     */
    suspend fun enqueueOperation(operation: QueuedOperation): Result<Long> {
        LogUtils.logDebug(TAG, "Enqueueing operation: ${operation.operationType}")
        return try {
            // Insert operation into database using queuedOperationDao.insertOperation
            val operationId = queuedOperationDao.insertOperation(operation)
            // Return Result.success with the operation ID
            Result.success(operationId)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error enqueueing operation", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Processes all operations in the queue if network is available
     */
    suspend fun processQueue(): Result<Int> {
        LogUtils.logDebug(TAG, "Processing queue")
        return try {
            // If network is not available, return Result.failure with NetworkUnavailableException
            if (!networkMonitor.isNetworkAvailable()) {
                return Result.failure(Exception("Network unavailable"))
            }
            // Update processingFlow to true
            processingFlow.value = true
            // Get all pending operations from queuedOperationDao.getPendingOperations
            val pendingOperations = queuedOperationDao.getPendingOperations()
            var processedCount = 0
            // For each operation, attempt to process it
            for (operation in pendingOperations) {
                processOperation(operation).onSuccess {
                    // If operation is processed successfully, mark as completed
                    val updatedOperation = operation.withUpdatedStatus(OperationStatus.COMPLETED, null)
                    queuedOperationDao.updateOperation(updatedOperation)
                    processedCount++
                }.onFailure {
                    // If operation fails, increment retry count or mark as failed if max retries reached
                    val updatedOperation = if (operation.retryCount < MAX_RETRY_COUNT) {
                        operation.incrementRetryCount().copy(lastAttempt = System.currentTimeMillis())
                    } else {
                        operation.withUpdatedStatus(OperationStatus.FAILED, it.message)
                    }
                    queuedOperationDao.updateOperation(updatedOperation)
                }
            }
            // Update processingFlow to false
            processingFlow.value = false
            // Return Result.success with count of processed operations
            Result.success(processedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error processing queue", e)
            // Update processingFlow to false
            processingFlow.value = false
            // Return Result.failure with the exception on error
            Result.failure(e)
        } finally {
            processingFlow.value = false
        }
    }

    /**
     * Processes a single queued operation based on its type
     */
    suspend fun processOperation(operation: QueuedOperation): Result<Boolean> {
        LogUtils.logDebug(TAG, "Processing operation: ${operation.operationType}")
        return try {
            // Parse operation data using Gson
            when (operation.operationType) {
                OperationType.JOURNAL_UPLOAD -> {
                    // JOURNAL_UPLOAD: Get journal from data and call journalRepository.uploadJournalAudio
                    val journal = gson.fromJson(operation.operationData, Journal::class.java)
                    journalRepository.uploadJournalAudio(journal).fold(
                        onSuccess = {
                            LogUtils.logInfo(TAG, "Successfully uploaded journal audio for journal ${journal.id}")
                            Result.success(true)
                        },
                        onFailure = {
                            LogUtils.logError(TAG, "Failed to upload journal audio for journal ${journal.id}", it)
                            Result.failure(it)
                        }
                    )
                }

                OperationType.EMOTIONAL_STATE_SYNC -> {
                    // EMOTIONAL_STATE_SYNC: Handle emotional state data directly or skip for now
                    LogUtils.logInfo(TAG, "Skipping EMOTIONAL_STATE_SYNC operation")
                    Result.success(true) // Placeholder
                }

                OperationType.TOOL_USAGE_SYNC -> {
                    // TOOL_USAGE_SYNC: Get tool usage data and call toolRepository.trackToolUsage
                    val toolUsageData = gson.fromJson(operation.operationData, ToolUsageData::class.java)
                    toolRepository.trackToolUsage(toolUsageData.toolId, toolUsageData.durationSeconds)
                    Result.success(true)
                }

                else -> {
                    // Else: Return Result.failure with UnsupportedOperationException
                    Result.failure(UnsupportedOperationException("Unsupported operation type: ${operation.operationType}"))
                }
            }
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error processing operation", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Starts monitoring network status and processing queue when network becomes available
     */
    fun startQueueProcessing() {
        LogUtils.logDebug(TAG, "Starting queue processing")
        // Cancel any existing processing job
        processingJob?.cancel()
        // Launch new coroutine in scope
        processingJob = scope.launch {
            // Collect network status flow filtered for network available events
            networkMonitor.getNetworkStatusFlow().filter { it }.collect {
                // For each network available event, call processQueue()
                processQueue().onFailure { e ->
                    // Log any errors during processing
                    LogUtils.logError(TAG, "Error during queue processing", e)
                }
            }
        }
    }

    /**
     * Stops monitoring network status and processing queue
     */
    fun stopQueueProcessing() {
        LogUtils.logDebug(TAG, "Stopping queue processing")
        // Cancel processing job if it exists
        processingJob?.cancel()
        // Set processingJob to null
        processingJob = null
    }

    /**
     * Gets the count of operations in the queue
     */
    fun getQueuedOperationCount(): Flow<Int> {
        return queuedOperationDao.getOperationCount()
    }

    /**
     * Gets a Flow indicating whether the queue is currently being processed
     */
    fun isProcessing(): Flow<Boolean> {
        return processingFlow.asStateFlow()
    }

    /**
     * Clears completed operations from the queue
     */
    suspend fun clearCompletedOperations(olderThanDays: Int): Result<Int> {
        LogUtils.logDebug(TAG, "Clearing completed operations older than $olderThanDays days")
        return try {
            // Calculate cutoff date based on olderThanDays
            val cutoffDate = System.currentTimeMillis() - (olderThanDays * 24 * 60 * 60 * 1000)
            // Delete completed operations older than cutoff date using queuedOperationDao.deleteCompletedOperations
            val deletedCount = queuedOperationDao.deleteCompletedOperations(cutoffDate)
            // Return Result.success with count of deleted operations
            Result.success(deletedCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error clearing completed operations", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Resets failed operations to pending status for retry
     */
    suspend fun retryFailedOperations(): Result<Int> {
        LogUtils.logDebug(TAG, "Retrying failed operations")
        return try {
            // Reset failed operations to pending status using queuedOperationDao.resetFailedOperations
            val resetCount = queuedOperationDao.resetFailedOperations()
            // Return Result.success with count of reset operations
            Result.success(resetCount)
        } catch (e: Exception) {
            // Catch and log any exceptions
            LogUtils.logError(TAG, "Error retrying failed operations", e)
            // Return Result.failure with the exception on error
            Result.failure(e)
        }
    }

    /**
     * Data class to hold tool usage data for queueing
     */
    data class ToolUsageData(val toolId: String, val durationSeconds: Int)
}