package com.amirawellness.domain.usecases.journal

import javax.inject.Inject // version: 1
import kotlinx.coroutines.Dispatchers // version: 1.6.4
import kotlinx.coroutines.withContext // version: 1.6.4
import com.amirawellness.data.models.Journal
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.core.utils.LogUtils

private const val TAG = "DeleteJournalUseCase"

/**
 * Use case for deleting journal entries and their associated audio recordings.
 * This class encapsulates the business logic for securely removing journal entries,
 * ensuring proper cleanup of resources including encrypted audio files, and handling
 * synchronization with the remote server when online.
 */
class DeleteJournalUseCase @Inject constructor(
    private val journalRepository: JournalRepository
) {
    /**
     * Deletes a journal entry and its associated audio recording.
     * 
     * This operation:
     * 1. Removes the journal entry from the local database
     * 2. Deletes associated audio files from storage
     * 3. Removes the journal from the remote server if it was previously uploaded
     * 
     * @param journal The journal entry to delete
     * @return Result indicating success or failure of the deletion operation
     */
    suspend operator fun invoke(journal: Journal): Result<Unit> {
        LogUtils.d(TAG, "Deleting journal entry: ${journal.id}")
        
        return try {
            // Use the repository to handle the deletion process
            // This will delete from local database, server (if online), and remove the audio file
            val result = journalRepository.deleteJournal(journal)
            
            // Return the result from the repository
            result
        } catch (e: Exception) {
            // Log any exceptions that occur during deletion
            LogUtils.e(TAG, "Error deleting journal entry: ${journal.id}", e)
            
            // Return a failure result with the exception
            Result.failure(e)
        }
    }
}