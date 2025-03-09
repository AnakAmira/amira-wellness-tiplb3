package com.amirawellness.domain.usecases.emotional

import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.repositories.EmotionalStateRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject

private const val TAG = "GetEmotionalHistoryUseCase"

/**
 * Data class for filtering emotional state history.
 * This class encapsulates optional parameters for filtering emotional state data,
 * including date ranges, context, emotion type, result limit, and sorting order.
 */
data class EmotionalHistoryFilter(
    val startDate: Long? = null,
    val endDate: Long? = null,
    val context: String? = null,
    val emotionType: String? = null,
    val limit: Int? = null,
    val sortDescending: Boolean = true
) {
    /**
     * Creates a new filter with the specified parameters.
     * Initializes all properties with provided values.
     * Sets default value for sortDescending to true if not provided.
     *
     * @param startDate The start date of the range (optional)
     * @param endDate The end date of the range (optional)
     * @param context The context of the emotional states (optional)
     * @param emotionType The type of emotion to filter by (optional)
     * @param limit The maximum number of results to return (optional)
     * @param sortDescending Whether to sort the results in descending order (optional, default: true)
     */
    constructor(
        startDate: Long? = null,
        endDate: Long? = null,
        context: String? = null,
        emotionType: String? = null,
        limit: Int? = null
    ) : this(startDate, endDate, context, emotionType, limit, true)

    /**
     * Checks if this filter has a date range specified.
     *
     * @return True if both startDate and endDate are not null, false otherwise
     */
    fun hasDateRange(): Boolean {
        return startDate != null && endDate != null
    }
}

/**
 * Use case for retrieving emotional state history with filtering capabilities.
 * This class encapsulates the business logic for fetching a user's emotional
 * check-in history with filtering capabilities, providing a clean API for the
 * presentation layer to access emotional data.
 */
class GetEmotionalHistoryUseCase @Inject constructor(
    private val emotionalStateRepository: EmotionalStateRepository
) {

    /**
     * Initializes the use case with required dependencies.
     * Stores provided repository in class property.
     *
     * @param emotionalStateRepository Repository for emotional state data operations
     */
    @Inject
    constructor(emotionalStateRepository: EmotionalStateRepository) : this(emotionalStateRepository)

    /**
     * Main operator function to retrieve emotional state history.
     *
     * @param userId The ID of the user
     * @param filter Optional filter to apply to the emotional state history
     * @return Flow emitting a list of emotional states
     */
    operator fun invoke(userId: String, filter: EmotionalHistoryFilter?): Flow<List<EmotionalState>> {
        LogUtils.logDebug(TAG, "Retrieving emotional history for userId: $userId, filter: $filter")

        var emotionalStatesFlow: Flow<List<EmotionalState>> =
            emotionalStateRepository.getEmotionalStatesByUserId(userId)

        if (filter != null) {
            if (filter.hasDateRange()) {
                val startDate = filter.startDate!!
                val endDate = filter.endDate!!
                emotionalStatesFlow = getByDateRange(userId, startDate, endDate)
                LogUtils.logDebug(TAG, "Applying date range filter: startDate=$startDate, endDate=$endDate")
            }

            if (filter.context != null) {
                val context = filter.context
                emotionalStatesFlow = getByContext(userId, context)
                LogUtils.logDebug(TAG, "Applying context filter: context=$context")
            }

            if (filter.emotionType != null) {
                val emotionType = filter.emotionType
                emotionalStatesFlow = getByEmotionType(userId, emotionType)
                LogUtils.logDebug(TAG, "Applying emotion type filter: emotionType=$emotionType")
            }

            if (filter.limit != null) {
                val limit = filter.limit
                emotionalStatesFlow = emotionalStateRepository.getRecentEmotionalStates(userId, limit)
                LogUtils.logDebug(TAG, "Applying limit filter: limit=$limit")
            }
        }

        return emotionalStatesFlow
            .catch { e ->
                LogUtils.logError(TAG, "Error retrieving emotional history", e)
                throw e
            }
    }

    /**
     * Retrieves emotional states within a specific date range.
     *
     * @param userId The ID of the user
     * @param startDate The start date of the range
     * @param endDate The end date of the range
     * @return Flow emitting a list of emotional states
     */
    fun getByDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<EmotionalState>> {
        LogUtils.logDebug(TAG, "Retrieving emotional states by date range for userId: $userId, startDate: $startDate, endDate: $endDate")
        return emotionalStateRepository.getEmotionalStatesByDateRange(userId, startDate, endDate)
    }

    /**
     * Retrieves emotional states for a specific context.
     *
     * @param userId The ID of the user
     * @param context The context of the emotional states
     * @return Flow emitting a list of emotional states
     */
    fun getByContext(userId: String, context: String): Flow<List<EmotionalState>> {
        LogUtils.logDebug(TAG, "Retrieving emotional states by context for userId: $userId, context: $context")
        return emotionalStateRepository.getEmotionalStatesByContext(userId, context)
    }

    /**
     * Retrieves emotional states of a specific emotion type.
     *
     * @param userId The ID of the user
     * @param emotionType The type of emotion
     * @return Flow emitting a list of emotional states
     */
    fun getByEmotionType(userId: String, emotionType: String): Flow<List<EmotionalState>> {
        LogUtils.logDebug(TAG, "Retrieving emotional states by emotion type for userId: $userId, emotionType: $emotionType")
        return emotionalStateRepository.getEmotionalStatesByEmotionType(userId, emotionType)
    }
}