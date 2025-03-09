package com.amirawellness.domain.usecases.journal

import com.amirawellness.data.models.Journal
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.core.utils.LogUtils
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch

private const val TAG = "GetJournalUseCase"

/**
 * Use case for retrieving a single journal entry by its ID.
 * This class encapsulates the business logic for fetching a specific journal entry,
 * handling the interaction between the UI layer and the repository layer.
 * 
 * Part of the voice journaling feature (F-001) that allows users to access
 * detailed information about their voice journal entries with emotional check-ins.
 */
class GetJournalUseCase @Inject constructor(
    private val journalRepository: JournalRepository
) {
    /**
     * Retrieves a specific journal entry by its ID.
     *
     * @param journalId The unique identifier of the journal entry to retrieve
     * @return Flow emitting the journal entry or null if not found
     */
    operator fun invoke(journalId: String): Flow<Journal?> {
        LogUtils.d(TAG, "Retrieving journal with ID: $journalId")
        return journalRepository.getJournal(journalId)
            .catch { e ->
                LogUtils.e(TAG, "Error retrieving journal with ID: $journalId", e)
                throw e
            }
    }
}