package com.amirawellness.domain.usecases.progress

import com.amirawellness.data.models.PeriodType
import com.amirawellness.data.repositories.ProgressRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case implementation for retrieving user usage statistics in the Amira Wellness application.
 * This class follows the clean architecture pattern, providing a single responsibility function 
 * to fetch usage statistics data from the repository layer and expose it to the presentation layer.
 * It supports the progress tracking feature by providing comprehensive usage data for visualization 
 * in the progress dashboard.
 */
class GetUsageStatisticsUseCase @Inject constructor(
    private val progressRepository: ProgressRepository
) {
    /**
     * Operator function that retrieves usage statistics from the repository for a specified time period.
     *
     * @param periodType The type of period to analyze (DAY, WEEK, MONTH)
     * @param periodValue The number of periods to include (default is 1)
     * @return Flow emitting usage statistics data including journal counts, tool usage, emotional check-ins, etc.
     */
    operator fun invoke(periodType: PeriodType, periodValue: Int = 1): Flow<Map<String, Any>> {
        return progressRepository.getProgressStatistics(periodType, periodValue)
    }
}