package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.repositories.ToolRepository
import javax.inject.Inject // javax.inject version: 1
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.withContext // kotlinx.coroutines version: 1.6.4

/**
 * Use case for tracking tool usage in the Amira Wellness application.
 * This class encapsulates the business logic for recording when a user completes a tool exercise,
 * including the duration spent. It follows the clean architecture pattern and provides a single
 * responsibility component that can be easily tested and maintained.
 */
class TrackToolUsageUseCase @Inject constructor(
    private val toolRepository: ToolRepository
) {
    /**
     * Executes the use case to track tool usage with the specified duration.
     * This operation is performed on the IO dispatcher to avoid blocking the main thread.
     * The function supports offline usage tracking with synchronization when connectivity is restored,
     * as implemented in the repository layer.
     *
     * @param toolId The unique identifier of the tool that was used
     * @param durationSeconds The duration in seconds that the user spent using the tool
     * @return Boolean indicating success (true) or failure (false) of the tracking operation
     */
    suspend operator fun invoke(toolId: String, durationSeconds: Int): Boolean {
        return withContext(Dispatchers.IO) {
            toolRepository.trackToolUsage(toolId, durationSeconds)
        }
    }
}