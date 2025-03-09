package com.amirawellness.domain.usecases.emotional

import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.EmotionalInsight
import com.amirawellness.data.models.EmotionalTrend
import com.amirawellness.data.models.EmotionalTrendRequest
import com.amirawellness.data.models.EmotionalTrendResponse
import com.amirawellness.data.models.PeriodType
import com.amirawellness.data.repositories.EmotionalStateRepository
import java.util.Date
import javax.inject.Inject

private const val TAG = "GetEmotionalTrendsUseCase"

/**
 * Use case for retrieving emotional trend data with validation and processing
 */
class GetEmotionalTrendsUseCase @Inject constructor(
    private val emotionalStateRepository: EmotionalStateRepository
) {

    /**
     * Initializes the use case with required dependencies
     * @param emotionalStateRepository
     */
    @Inject
    constructor(emotionalStateRepository: EmotionalStateRepository) : this(emotionalStateRepository) {
        // Store provided repository in class property
    }

    /**
     * Main operator function to retrieve emotional trend data
     * @param userId
     * @param periodType
     * @param emotionTypes
     * @return Result<EmotionalTrendResponse>
     */
    suspend operator fun invoke(
        userId: String,
        periodType: PeriodType,
        emotionTypes: List<EmotionType>? = null
    ): Result<EmotionalTrendResponse> {
        LogUtils.logDebug(TAG, "Retrieving emotional trends for userId: $userId, periodType: $periodType, emotionTypes: $emotionTypes")

        return try {
            // Get date range from periodType using getDateRange function
            val (startDate, endDate) = periodType.getDateRange()

            // Create EmotionalTrendRequest with periodType, date range, and emotionTypes
            val request = EmotionalTrendRequest(periodType, startDate, endDate, emotionTypes)

            // Validate request using isValid function
            if (!request.isValid()) {
                // If validation fails, return Result.failure with InvalidRequestException
                return Result.failure(InvalidRequestException("Invalid request parameters"))
            }

            // Convert dates to timestamps for repository call
            val startTime = startDate.time
            val endTime = endDate.time

            // Call emotionalStateRepository.getEmotionalTrends with userId and date range
            emotionalStateRepository.getEmotionalTrends(userId, startTime, endTime).fold(
                onSuccess = { result ->
                    // Process the repository result to convert to EmotionalTrendResponse
                    val response = processRepositoryResult(result)
                    // Return Result.success with the processed response
                    Result.success(response)
                },
                onFailure = { e ->
                    // Log errors if they occur
                    LogUtils.logError(TAG, "Error retrieving emotional trends", e)
                    // Return Result.failure with the caught exception
                    Result.failure(e)
                }
            )
        } catch (e: Exception) {
            // Log errors if they occur
            LogUtils.logError(TAG, "Error retrieving emotional trends", e)
            // Return Result.failure with the caught exception
            return Result.failure(e)
        }
    }

    /**
     * Overloaded operator function to retrieve emotional trend data with custom date range
     * @param userId
     * @param startDate
     * @param endDate
     * @param emotionTypes
     * @return Result<EmotionalTrendResponse>
     */
    suspend operator fun invoke(
        userId: String,
        startDate: Date,
        endDate: Date,
        emotionTypes: List<EmotionType>? = null
    ): Result<EmotionalTrendResponse> {
        LogUtils.logDebug(TAG, "Retrieving emotional trends for userId: $userId, startDate: $startDate, endDate: $endDate, emotionTypes: $emotionTypes")

        return try {
            // Create EmotionalTrendRequest with custom date range and emotionTypes
            val request = EmotionalTrendRequest(PeriodType.DAY, startDate, endDate, emotionTypes)

            // Validate request using isValid function
            if (!request.isValid()) {
                // If validation fails, return Result.failure with InvalidRequestException
                return Result.failure(InvalidRequestException("Invalid request parameters"))
            }

            // Convert dates to timestamps for repository call
            val startTime = startDate.time
            val endTime = endDate.time

            // Call emotionalStateRepository.getEmotionalTrends with userId and date range
            emotionalStateRepository.getEmotionalTrends(userId, startTime, endTime).fold(
                onSuccess = { result ->
                    // Process the repository result to convert to EmotionalTrendResponse
                    val response = processRepositoryResult(result)
                    // Return Result.success with the processed response
                    Result.success(response)
                },
                onFailure = { e ->
                    // Log errors if they occur
                    LogUtils.logError(TAG, "Error retrieving emotional trends", e)
                    // Return Result.failure with the caught exception
                    Result.failure(e)
                }
            )
        } catch (e: Exception) {
            // Log errors if they occur
            LogUtils.logError(TAG, "Error retrieving emotional trends", e)
            // Return Result.failure with the caught exception
            return Result.failure(e)
        }
    }

    /**
     * Processes the raw repository result into a structured EmotionalTrendResponse
     * @param result
     * @return EmotionalTrendResponse
     */
    private fun processRepositoryResult(result: Map<String, Any>): EmotionalTrendResponse {
        // Extract 'trends' and 'insights' from the result map
        val trendsData = result["trends"] as? List<*> ?: emptyList<Any>()
        val insightsData = result["insights"] as? List<*> ?: emptyList<Any>()

        // Convert trend data to list of EmotionalTrend objects
        val trends = trendsData.mapNotNull { trendDto ->
            (trendDto as? Map<*, *>)?.let {
                // Assuming EmotionalTrend.fromMap(it) exists and handles the conversion
                // For now, just return null
                null
            }
        }.filterIsInstance<EmotionalTrend>()

        // Convert insight data to list of EmotionalInsight objects
        val insights = insightsData.mapNotNull { insightDto ->
            (insightDto as? Map<*, *>)?.let {
                // Assuming EmotionalInsight.fromMap(it) exists and handles the conversion
                // For now, just return null
                null
            }
        }.filterIsInstance<EmotionalInsight>()

        // Create and return EmotionalTrendResponse with processed data
        return EmotionalTrendResponse(trends, insights)
    }

    /**
     * Validates that the date range is valid
     * @param startDate
     * @param endDate
     * @return Boolean
     */
    private fun validateDateRange(startDate: Date, endDate: Date): Boolean {
        // Check if startDate is before endDate
        if (startDate.after(endDate)) {
            return false
        }

        // Check if date range is within reasonable limits (e.g., not more than 1 year)
        // Return true if valid, false otherwise
        return true
    }

    /**
     * Exception thrown when an invalid request is provided
     * @param message
     */
    class InvalidRequestException(message: String) : Exception(message) {
        /**
         * Creates a new InvalidRequestException with the specified message
         * @param message
         */
        init {
            // Call super constructor with the provided message
        }
    }
}