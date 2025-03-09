package com.amirawellness.domain.usecases.progress

import com.amirawellness.data.models.Achievement
import com.amirawellness.data.repositories.ProgressRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case for retrieving user achievements from the progress repository.
 * 
 * This class follows the clean architecture pattern, providing a single responsibility
 * function to fetch achievement data from the repository layer and expose it to the 
 * presentation layer. It supports the gamification aspect of the application by providing
 * achievement information for display in the progress dashboard.
 */
class GetAchievementsUseCase @Inject constructor(
    private val progressRepository: ProgressRepository
) {
    /**
     * Operator function that retrieves achievements from the repository.
     * 
     * @return Flow emitting list of achievements
     */
    operator fun invoke(): Flow<List<Achievement>> {
        return progressRepository.getAchievements()
    }
}