package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.repositories.ToolRepository
import javax.inject.Inject // version: 1
import kotlinx.coroutines.Dispatchers // version: 1.6.4
import kotlinx.coroutines.withContext // version: 1.6.4

/**
 * Use case for toggling the favorite status of a tool in the Amira Wellness application.
 * 
 * This use case encapsulates the business logic for marking or unmarking a tool as a favorite,
 * delegating the actual data operation to the ToolRepository. It follows the clean architecture
 * pattern by providing a single responsibility component that can be easily tested and maintained.
 * 
 * The implementation supports offline favoriting with synchronization when connectivity is restored,
 * as the underlying repository handles local storage and eventual server synchronization.
 */
class ToggleToolFavoriteUseCase @Inject constructor(
    private val toolRepository: ToolRepository
) {
    /**
     * Executes the use case to toggle the favorite status of a tool.
     * 
     * This operator function allows the use case to be called directly as a function:
     * val result = toggleToolFavoriteUseCase(toolId, isFavorite)
     * 
     * The operation is performed on the IO dispatcher to avoid blocking the main thread.
     * 
     * @param toolId The unique identifier of the tool to toggle
     * @param isFavorite The new favorite status (true to mark as favorite, false to unmark)
     * @return Boolean indicating success (true) or failure (false) of the operation
     */
    suspend operator fun invoke(toolId: String, isFavorite: Boolean): Boolean {
        return withContext(Dispatchers.IO) {
            toolRepository.toggleToolFavorite(toolId, isFavorite)
        }
    }
}