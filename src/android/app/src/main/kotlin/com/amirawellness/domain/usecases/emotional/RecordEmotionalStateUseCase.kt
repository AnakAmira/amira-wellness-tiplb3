package com.amirawellness.domain.usecases.emotional

import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.repositories.EmotionalStateRepository
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private const val TAG = "RecordEmotionalStateUseCase"

/**
 * Use case for recording emotional states with validation
 */
class RecordEmotionalStateUseCase @Inject constructor(
    private val emotionalStateRepository: EmotionalStateRepository
) {

    /**
     * Initializes the use case with required dependencies
     *
     * @param emotionalStateRepository The repository for emotional state data operations
     */
    @Inject
    constructor(
        emotionalStateRepository: EmotionalStateRepository
    ) : this(emotionalStateRepository) {
        // Store provided repository in class property
    }

    /**
     * Main operator function to record an emotional state
     *
     * @param userId The ID of the user recording the emotional state
     * @param emotionType The type of emotion being recorded
     * @param intensity The intensity of the emotion (1-10)
     * @param context The context in which the emotion is being recorded
     * @param notes Optional notes about the emotional state
     * @param relatedJournalId Optional ID of the related journal entry
     * @param relatedToolId Optional ID of the related tool
     * @return Result containing the recorded EmotionalState or an error
     */
    suspend operator fun invoke(
        userId: String,
        emotionType: EmotionType,
        intensity: Int,
        context: String,
        notes: String?,
        relatedJournalId: String?,
        relatedToolId: String?
    ): Result<EmotionalState> = withContext(Dispatchers.IO) {
        LogUtils.logDebug(TAG, "Recording emotional state with parameters: userId=$userId, emotionType=$emotionType, intensity=$intensity, context=$context, notes=$notes, relatedJournalId=$relatedJournalId, relatedToolId=$relatedToolId")

        // Validate intensity value using validateIntensity function
        if (!validateIntensity(intensity)) {
            // If validation fails, return Result.failure with IllegalArgumentException
            LogUtils.logError(TAG, "Invalid intensity value: $intensity")
            return@withContext Result.failure(InvalidIntensityException(intensity))
        }

        try {
            // Create a new EmotionalState object with provided parameters and current timestamp
            val emotionalState = createEmotionalState(userId, emotionType, intensity, context, notes, relatedJournalId, relatedToolId)

            // Call emotionalStateRepository.recordEmotionalState with the created emotional state
            val result = emotionalStateRepository.recordEmotionalState(emotionalState)

            // Return the result from the repository
            result
        } catch (e: Exception) {
            // Log errors if they occur
            LogUtils.logError(TAG, "Error recording emotional state", e)
            // Return Result.failure with the caught exception
            Result.failure(e)
        }
    }

    /**
     * Validates that the intensity value is within the allowed range
     *
     * @param intensity The intensity value to validate
     * @return True if the intensity is valid, false otherwise
     */
    private fun validateIntensity(intensity: Int): Boolean {
        // Check if intensity is between EMOTION_INTENSITY_MIN (1) and EMOTION_INTENSITY_MAX (10) inclusive
        return intensity in EmotionalState.EMOTION_INTENSITY_MIN..EmotionalState.EMOTION_INTENSITY_MAX
    }

    /**
     * Creates a new EmotionalState object with the provided parameters
     *
     * @param userId The ID of the user recording the emotional state
     * @param emotionType The type of emotion being recorded
     * @param intensity The intensity of the emotion (1-10)
     * @param context The context in which the emotion is being recorded
     * @param notes Optional notes about the emotional state
     * @param relatedJournalId Optional ID of the related journal entry
     * @param relatedToolId Optional ID of the related tool
     * @return A new EmotionalState object with the provided parameters and generated values
     */
    private fun createEmotionalState(
        userId: String,
        emotionType: EmotionType,
        intensity: Int,
        context: String,
        notes: String?,
        relatedJournalId: String?,
        relatedToolId: String?
    ): EmotionalState {
        // Generate a random ID using UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        // Get current timestamp using System.currentTimeMillis()
        val createdAt = System.currentTimeMillis()

        // Create and return a new EmotionalState with the provided parameters and generated values
        return EmotionalState(
            id = id,
            emotionType = emotionType,
            intensity = intensity,
            context = context,
            notes = notes,
            createdAt = createdAt,
            relatedJournalId = relatedJournalId,
            relatedToolId = relatedToolId
        )
    }

    /**
     * Exception thrown when an invalid intensity value is provided
     */
    class InvalidIntensityException(intensity: Int) : IllegalArgumentException(
        "Invalid intensity value: $intensity. Must be between ${EmotionalState.EMOTION_INTENSITY_MIN} and ${EmotionalState.EMOTION_INTENSITY_MAX}"
    )
}