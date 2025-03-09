package com.amirawellness.core.extensions

import com.amirawellness.data.models.ApiResponse
import com.amirawellness.data.models.ApiResponse.Success
import com.amirawellness.data.models.ApiResponse.Error
import com.amirawellness.data.models.ApiError
import com.amirawellness.core.utils.LogUtils
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.retry
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.onCompletion
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.transformLatest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.isActive
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.flowWithLifecycle
import java.util.concurrent.TimeoutException
import kotlin.math.pow

private const val TAG = "FlowExtensions"

/**
 * Transforms a Flow of ApiResponse to a Flow of success values only.
 * If an error occurs, the defaultValue function is called to provide a fallback.
 *
 * @param defaultValue Function that provides a default value in case of error
 * @return Flow emitting only success values or default value on error
 */
fun <T> Flow<ApiResponse<T>>.onApiSuccess(defaultValue: () -> T): Flow<T> {
    return map { response ->
        response.fold(
            onSuccess = { it },
            onError = { error ->
                LogUtils.e(TAG, "API error: ${error.message}")
                defaultValue()
            }
        )
    }
}

/**
 * Transforms a Flow of ApiResponse to a Flow of error values only.
 * If no errors occur, the Flow will be empty.
 *
 * @return Flow emitting only error values, empty if no errors
 */
fun <T> Flow<ApiResponse<T>>.onApiError(): Flow<ApiError> {
    return flow {
        collect { response ->
            if (response is Error) {
                LogUtils.e(TAG, "API error: ${response.error.message}")
                emit(response.error)
            }
        }
    }
}

/**
 * Retries a Flow with exponential backoff when errors occur.
 *
 * @param maxRetries Maximum number of retry attempts
 * @param initialDelayMillis Initial delay before first retry in milliseconds
 * @param backoffFactor Factor by which the delay increases with each retry
 * @param predicate Function that determines if a particular exception should trigger a retry
 * @return Flow with retry logic applied
 */
fun <T> Flow<T>.retryWithBackoff(
    maxRetries: Int = 3,
    initialDelayMillis: Long = 1000,
    backoffFactor: Float = 2.0f,
    predicate: (Throwable) -> Boolean = { true }
): Flow<T> {
    var retryAttempt = 0
    return retry(maxRetries) { cause ->
        if (predicate(cause) && retryAttempt < maxRetries) {
            val delayMillis = (initialDelayMillis * backoffFactor.pow(retryAttempt)).toLong()
            LogUtils.d(TAG, "Retrying after error with delay $delayMillis ms: ${cause.message}")
            retryAttempt++
            delay(delayMillis)
            true
        } else {
            false
        }
    }
}

/**
 * Retries a Flow of ApiResponse when network errors occur.
 *
 * @param maxRetries Maximum number of retry attempts
 * @param initialDelayMillis Initial delay before first retry in milliseconds
 * @return Flow with network error retry logic applied
 */
fun <T> Flow<ApiResponse<T>>.retryOnNetworkError(
    maxRetries: Int = 3,
    initialDelayMillis: Long = 1000
): Flow<ApiResponse<T>> {
    var lastResponse: ApiResponse<T>? = null
    var retryAttempt = 0
    
    return onEach { response ->
        lastResponse = response
    }.retry(maxRetries) { cause ->
        val isNetworkError = cause is Throwable || 
                (lastResponse is Error && (lastResponse as Error<T>).error.isNetworkError())
                
        if (isNetworkError && retryAttempt < maxRetries) {
            val delayMillis = initialDelayMillis * (1 shl retryAttempt)
            LogUtils.d(TAG, "Retrying network error with delay $delayMillis ms")
            retryAttempt++
            delay(delayMillis)
            true
        } else {
            false
        }
    }
}

/**
 * Transforms a Flow to emit loading state before and after the actual data.
 * This is useful for UI state handling.
 *
 * @return Flow with loading state indicators
 */
fun <T> Flow<T>.withLoading(): Flow<Resource<T>> {
    return flow {
        emit(Resource.Loading())
        try {
            collect { value ->
                emit(Resource.Success(value))
            }
        } catch (e: Throwable) {
            LogUtils.e(TAG, "Error in flow: ${e.message}", e)
            emit(Resource.Error(e))
        }
    }
}

/**
 * Caches Flow emissions and replays them to new collectors.
 *
 * @param capacity Maximum number of items to cache
 * @return Flow with caching behavior
 */
fun <T> Flow<T>.cachedIn(capacity: Int = 10): Flow<T> {
    val sharedFlow = MutableSharedFlow<T>(
        replay = capacity,
        extraBufferCapacity = 0,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    
    // Coroutine to collect from original flow and emit to shared flow
    val scope = CoroutineScope(Dispatchers.Default)
    val job = scope.launch {
        try {
            this@cachedIn.collect { value ->
                sharedFlow.emit(value)
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error in cached flow: ${e.message}", e)
        }
    }
    
    // Return the shared flow with cleanup
    return sharedFlow.onCompletion {
        job.cancel()
        scope.cancel()
    }
}

/**
 * Throttles a Flow to emit only the first item during the specified window.
 *
 * @param windowDurationMillis Duration of the throttling window in milliseconds
 * @return Flow that emits only the first item in each time window
 */
fun <T> Flow<T>.throttleFirst(windowDurationMillis: Long): Flow<T> {
    return flow {
        var lastEmissionTime = 0L
        collect { value ->
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastEmissionTime > windowDurationMillis) {
                lastEmissionTime = currentTime
                emit(value)
            }
        }
    }
}

/**
 * Throttles a Flow to emit only the last item during the specified window.
 *
 * @param windowDurationMillis Duration of the throttling window in milliseconds
 * @return Flow that emits only the last item in each time window
 */
fun <T> Flow<T>.throttleLast(windowDurationMillis: Long): Flow<T> {
    return flow {
        coroutineScope {
            var latestValue: T? = null
            var hasValue = false
            
            val ticker = launch {
                while (isActive) {
                    delay(windowDurationMillis)
                    if (hasValue) {
                        latestValue?.let { emit(it) }
                        hasValue = false
                    }
                }
            }
            
            try {
                collect { value ->
                    latestValue = value
                    hasValue = true
                }
            } finally {
                ticker.cancel()
            }
        }
    }
}

/**
 * Debounces a Flow to emit only after a specified quiet period.
 *
 * @param timeoutMillis Duration of the quiet period in milliseconds
 * @return Flow that emits values only after the quiet period
 */
fun <T> Flow<T>.debounce(timeoutMillis: Long): Flow<T> {
    return flow {
        var debounceJob: Job? = null
        
        coroutineScope {
            collect { value ->
                debounceJob?.cancel()
                debounceJob = launch {
                    delay(timeoutMillis)
                    emit(value)
                }
            }
        }
    }
}

/**
 * Makes a Flow lifecycle-aware to automatically stop collection when the lifecycle owner is destroyed.
 *
 * @param lifecycleOwner The lifecycle owner to observe
 * @param minActiveState Minimum lifecycle state in which the flow will be collected
 * @return Lifecycle-aware Flow
 */
fun <T> Flow<T>.withLifecycle(
    lifecycleOwner: LifecycleOwner,
    minActiveState: Lifecycle.State = Lifecycle.State.STARTED
): Flow<T> {
    return this.flowWithLifecycle(lifecycleOwner.lifecycle, minActiveState)
}

/**
 * Logs all emissions from a Flow for debugging purposes.
 *
 * @param tag Log tag to use
 * @param message Optional message prefix for log entries
 * @return Original Flow with logging side effects
 */
fun <T> Flow<T>.logFlow(tag: String = TAG, message: String = ""): Flow<T> {
    return onEach { value ->
        LogUtils.d(tag, "$message: $value")
    }.catch { error ->
        LogUtils.e(tag, "$message error: ${error.message}", error)
        throw error
    }
}

/**
 * Maps a Flow of ApiResponse to a Flow of Resource for UI consumption.
 *
 * @return Flow of Resource objects representing loading, success, or error states
 */
fun <T> Flow<ApiResponse<T>>.mapToResource(): Flow<Resource<T>> {
    return flow {
        emit(Resource.Loading())
        
        collect { response ->
            when (response) {
                is Success -> emit(Resource.Success(response.data))
                is Error -> emit(Resource.Error(Exception(response.error.message), null))
            }
        }
    }.catch { error ->
        LogUtils.e(TAG, "Error in flow: ${error.message}", error)
        emit(Resource.Error(error))
    }
}

/**
 * Transforms each value of the original Flow into a new Flow and flattens these Flows,
 * emitting only values from the latest Flow.
 *
 * @param transform Function that transforms each value into a new Flow
 * @return Flow containing values from the latest transformed Flow
 */
fun <T, R> Flow<T>.flatMapLatest(transform: (T) -> Flow<R>): Flow<R> {
    return transformLatest { value ->
        emitAll(transform(value))
    }
}

/**
 * Filters out null values from a Flow of nullable type.
 *
 * @return Flow containing only non-null values
 */
fun <T : Any> Flow<T?>.filterNotNull(): Flow<T> {
    return filter { it != null }.map { it!! }
}

/**
 * Provides a default value for a Flow if it completes without emitting any values.
 *
 * @param defaultValue The default value to emit if the original Flow completes without values
 * @return Flow that emits at least the default value
 */
fun <T> Flow<T>.withDefault(defaultValue: T): Flow<T> {
    return flow {
        var hasEmitted = false
        
        collect { value ->
            hasEmitted = true
            emit(value)
        }
        
        if (!hasEmitted) {
            emit(defaultValue)
        }
    }
}

/**
 * Applies a timeout to a Flow, emitting an error if no values are emitted within the specified time.
 *
 * @param timeoutMillis Timeout duration in milliseconds
 * @return Flow with timeout applied
 */
fun <T> Flow<T>.withTimeout(timeoutMillis: Long): Flow<T> {
    return flow {
        coroutineScope {
            val timeoutJob = launch {
                delay(timeoutMillis)
                throw TimeoutException("Flow timed out after $timeoutMillis ms")
            }
            
            try {
                collect { value ->
                    timeoutJob.cancel()
                    emit(value)
                }
            } finally {
                timeoutJob.cancel()
            }
        }
    }
}

/**
 * Sealed class representing different states of a resource for UI consumption.
 *
 * @param T Type of data payload in success state
 */
sealed class Resource<T> {
    /**
     * Checks if this resource is in loading state.
     *
     * @return True if loading, false otherwise
     */
    fun isLoading(): Boolean = this is Loading
    
    /**
     * Checks if this resource is in success state.
     *
     * @return True if success, false otherwise
     */
    fun isSuccess(): Boolean = this is Success
    
    /**
     * Checks if this resource is in error state.
     *
     * @return True if error, false otherwise
     */
    fun isError(): Boolean = this is Error
    
    /**
     * Gets the data payload if success, or null otherwise.
     *
     * @return Data payload if success, null otherwise
     */
    fun getOrNull(): T? = (this as? Success)?.data
    
    /**
     * Gets the error if error state, or null otherwise.
     *
     * @return Error if error state, null otherwise
     */
    fun getErrorOrNull(): Throwable? = (this as? Error)?.error
    
    /**
     * Applies the appropriate function based on the resource state.
     *
     * @param onLoading Function to apply if this is Loading
     * @param onSuccess Function to apply if this is Success
     * @param onError Function to apply if this is Error
     * @return Result of applying the appropriate function
     */
    fun <R> fold(
        onLoading: () -> R,
        onSuccess: (T) -> R,
        onError: (Throwable) -> R
    ): R {
        return when (this) {
            is Loading -> onLoading()
            is Success -> onSuccess(data)
            is Error -> onError(error)
        }
    }
    
    /**
     * Represents a resource in loading state.
     */
    class Loading<T> : Resource<T>()
    
    /**
     * Represents a resource in success state with data payload.
     *
     * @property data The data payload
     */
    class Success<T>(val data: T) : Resource<T>()
    
    /**
     * Represents a resource in error state with error information.
     *
     * @property error The error that occurred
     * @property data Optional data that might be available despite the error
     */
    class Error<T>(val error: Throwable, val data: T? = null) : Resource<T>()
}