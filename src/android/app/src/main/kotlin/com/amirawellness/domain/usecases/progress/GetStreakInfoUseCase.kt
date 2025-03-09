package com.amirawellness.domain.usecases.progress

import com.amirawellness.data.models.StreakInfo
import com.amirawellness.data.repositories.ProgressRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case for retrieving user streak information in the Amira Wellness application.
 * This class follows the clean architecture pattern, providing a single responsibility function
 * to fetch streak data from the repository layer and expose it to the presentation layer.
 * It supports the gamification aspect of the application by providing streak information
 * for display in the progress dashboard.
 */
class GetStreakInfoUseCase @Inject constructor(
    private val progressRepository: ProgressRepository
) {
    /**
     * Retrieves streak information from the progress repository.
     * 
     * @return A Flow emitting streak information
     */
    operator fun invoke(): Flow<StreakInfo> {
        return progressRepository.getStreakInfo()
    }
}