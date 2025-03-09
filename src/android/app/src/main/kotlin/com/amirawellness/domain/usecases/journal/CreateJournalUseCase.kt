package com.amirawellness.domain.usecases.journal

import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.util.UUID
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.AudioMetadata
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.core.utils.AudioUtils

private const val TAG = "CreateJournalUseCase"

/**
 * Use case for creating new journal entries with emotional check-ins and optional audio recordings.
 * This class implements the business logic for the journal creation process in the Amira Wellness application.
 * It serves as the bridge between the UI layer and the repository layer for the voice journaling feature.
 */
class CreateJournalUseCase @Inject constructor(
    private val journalRepository: JournalRepository
) {
    /**
     * Creates a new journal entry with the provided emotional states and optional audio file
     *
     * @param userId The ID of the user creating the journal
     * @param preEmotionalState The emotional state before recording
     * @param postEmotionalState The emotional state after recording
     * @param audioFile Optional audio recording file
     * @param title Optional journal title (generated if not provided)
     * @return Result containing the created journal or an error
     */
    suspend operator fun invoke(
        userId: String,
        preEmotionalState: EmotionalState,
        postEmotionalState: EmotionalState,
        audioFile: File? = null,
        title: String? = null
    ): Result<Journal> {
        LogUtils.d(TAG, "Creating journal for user: $userId")
        
        try {
            // Validate emotional states have correct contexts
            if (!validateEmotionalStates(preEmotionalState, postEmotionalState)) {
                return Result.failure(IllegalArgumentException("Emotional states have incorrect contexts. Pre-state must have PRE_JOURNALING context and post-state must have POST_JOURNALING context."))
            }
            
            // Generate a unique journal ID
            val journalId = UUID.randomUUID().toString()
            
            // Calculate journal duration from audio file if available
            val durationSeconds = if (audioFile != null) {
                (AudioUtils.getAudioDuration(audioFile) / 1000).toInt()
            } else {
                0
            }
            
            // Create a title if not provided
            val journalTitle = title ?: generateDefaultTitle(preEmotionalState)
            
            // Create the journal entry
            val journal = Journal.Companion.createEmpty(userId, preEmotionalState).copy(
                title = journalTitle,
                durationSeconds = durationSeconds,
                postEmotionalState = postEmotionalState
            )
            
            // Process audio file if provided
            if (audioFile != null) {
                val (audioMetadata, duration) = processAudioFile(audioFile, journal.id)
                
                // Update journal with audio metadata and local file path
                val updatedJournal = journal.copy(
                    durationSeconds = duration,
                    localFilePath = audioFile.absolutePath,
                    audioMetadata = audioMetadata
                )
                
                // Save the journal entry with the repository
                return journalRepository.createJournal(updatedJournal)
            }
            
            // Save the journal entry without audio
            return journalRepository.createJournal(journal)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error creating journal", e)
            return Result.failure(e)
        }
    }
    
    /**
     * Validates that the emotional states have the correct contexts
     *
     * @param preState The pre-recording emotional state
     * @param postState The post-recording emotional state
     * @return True if both states have the correct contexts, false otherwise
     */
    private fun validateEmotionalStates(preState: EmotionalState, postState: EmotionalState): Boolean {
        return preState.context == EmotionContext.PRE_JOURNALING.toString() &&
               postState.context == EmotionContext.POST_JOURNALING.toString()
    }
    
    /**
     * Generates a default title for a journal entry based on the pre-emotional state
     *
     * @param preEmotionalState The emotional state before recording
     * @return A generated title including the emotion name and timestamp
     */
    private fun generateDefaultTitle(preEmotionalState: EmotionalState): String {
        val emotionName = preEmotionalState.getDisplayName()
        val timestamp = java.text.SimpleDateFormat("dd/MM/yyyy HH:mm", java.util.Locale.getDefault())
                            .format(java.util.Date())
        return "$emotionName - $timestamp"
    }
    
    /**
     * Processes an audio file to extract metadata and duration
     *
     * @param audioFile The audio file to process
     * @param journalId The ID of the journal to associate with the audio
     * @return Pair containing the AudioMetadata and duration in seconds
     */
    private suspend fun processAudioFile(audioFile: File, journalId: String): Pair<AudioMetadata, Int> {
        return withContext(Dispatchers.IO) {
            // Get audio duration in seconds
            val durationSeconds = (AudioUtils.getAudioDuration(audioFile) / 1000).toInt()
            
            // Get audio metadata
            val metadata = AudioUtils.getAudioMetadata(audioFile)
            
            // Create AudioMetadata object
            val audioMetadata = AudioMetadata(
                id = UUID.randomUUID().toString(),
                journalId = journalId,
                fileFormat = metadata.fileFormat,
                fileSizeBytes = metadata.fileSizeBytes,
                sampleRate = metadata.sampleRate,
                bitRate = metadata.bitRate,
                channels = metadata.channels,
                checksum = metadata.checksum
            )
            
            Pair(audioMetadata, durationSeconds)
        }
    }
}