package com.amirawellness.domain.usecases.journal

import javax.inject.Inject // version: 1
import kotlinx.coroutines.flow.Flow // version: 1.6.4
import kotlinx.coroutines.flow.catch // version: 1.6.4
import com.amirawellness.data.models.Journal
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.core.utils.LogUtils

/**
 * Use case for retrieving journal entries with various filtering options.
 * 
 * This class implements the business logic for fetching voice journal entries,
 * handling the interaction between the UI layer and repository layer, and
 * providing a clean API for accessing journal data.
 */
class GetJournalsUseCase @Inject constructor(
    private val journalRepository: JournalRepository
) {
    private companion object {
        private const val TAG = "GetJournalsUseCase"
    }
    
    /**
     * Retrieves all journal entries for a specific user.
     * 
     * @param userId The ID of the user whose journals to retrieve
     * @return Flow emitting a list of journal entries
     */
    operator fun invoke(userId: String): Flow<List<Journal>> {
        LogUtils.d(TAG, "Retrieving journals for user: $userId")
        return journalRepository.getJournalsByUser(userId)
            .catch { throwable ->
                LogUtils.e(TAG, "Error retrieving journals for user: $userId", throwable)
                throw throwable
            }
    }
    
    /**
     * Retrieves favorite journal entries for a specific user.
     * 
     * @param userId The ID of the user whose favorite journals to retrieve
     * @return Flow emitting a list of favorite journal entries
     */
    fun getFavoriteJournals(userId: String): Flow<List<Journal>> {
        LogUtils.d(TAG, "Retrieving favorite journals for user: $userId")
        return journalRepository.getFavoriteJournals(userId)
            .catch { throwable ->
                LogUtils.e(TAG, "Error retrieving favorite journals for user: $userId", throwable)
                throw throwable
            }
    }
    
    /**
     * Retrieves journal entries within a specific date range.
     * 
     * @param userId The ID of the user whose journals to retrieve
     * @param startDate The start date of the range (timestamp)
     * @param endDate The end date of the range (timestamp)
     * @return Flow emitting a list of journal entries within the date range
     */
    fun getJournalsByDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<Journal>> {
        LogUtils.d(TAG, "Retrieving journals for user: $userId between dates: $startDate - $endDate")
        return journalRepository.getJournalsByDateRange(userId, startDate, endDate)
            .catch { throwable ->
                LogUtils.e(TAG, "Error retrieving journals by date range for user: $userId", throwable)
                throw throwable
            }
    }
    
    /**
     * Retrieves journal entries with a positive emotional shift.
     * 
     * @param userId The ID of the user whose journals to retrieve
     * @return Flow emitting a list of journal entries with positive emotional shift
     */
    fun getJournalsWithPositiveShift(userId: String): Flow<List<Journal>> {
        LogUtils.d(TAG, "Retrieving journals with positive emotional shift for user: $userId")
        return journalRepository.getJournalsWithPositiveShift(userId)
            .catch { throwable ->
                LogUtils.e(TAG, "Error retrieving journals with positive shift for user: $userId", throwable)
                throw throwable
            }
    }
    
    /**
     * Retrieves journal entries with a specific pre-recording emotion type.
     * 
     * @param userId The ID of the user whose journals to retrieve
     * @param emotionType The emotion type to filter by
     * @return Flow emitting a list of journal entries with the specified emotion type
     */
    fun getJournalsByEmotionType(userId: String, emotionType: String): Flow<List<Journal>> {
        LogUtils.d(TAG, "Retrieving journals with emotion type: $emotionType for user: $userId")
        return journalRepository.getJournalsByEmotionType(userId, emotionType)
            .catch { throwable ->
                LogUtils.e(TAG, "Error retrieving journals by emotion type for user: $userId", throwable)
                throw throwable
            }
    }
    
    /**
     * Retrieves the most recent journal entries for a user.
     * 
     * @param userId The ID of the user whose journals to retrieve
     * @param limit The maximum number of entries to retrieve
     * @return Flow emitting a list of recent journal entries
     */
    fun getRecentJournals(userId: String, limit: Int): Flow<List<Journal>> {
        LogUtils.d(TAG, "Retrieving $limit recent journals for user: $userId")
        return journalRepository.getRecentJournals(userId, limit)
            .catch { throwable ->
                LogUtils.e(TAG, "Error retrieving recent journals for user: $userId", throwable)
                throw throwable
            }
    }
}