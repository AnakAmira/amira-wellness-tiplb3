package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.models.Tool
import com.amirawellness.data.repositories.ToolRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case for retrieving tools marked as favorites from the repository.
 * 
 * This class follows the clean architecture pattern, encapsulating the business logic
 * for fetching favorite tools. It provides a single responsibility component that
 * can be easily tested and maintained while supporting the Tool Favoriting feature
 * requirement (F-006).
 */
class GetFavoriteToolsUseCase @Inject constructor(
    private val toolRepository: ToolRepository
) {
    /**
     * Executes the use case to retrieve favorite tools.
     * Delegates to the repository's getFavoriteTools method which returns a Flow
     * that will emit updates when the favorites list changes.
     * 
     * This supports the offline capabilities requirement by leveraging the repository's
     * caching mechanism for favorite tools.
     *
     * @return Flow emitting a list of tools marked as favorites
     */
    operator fun invoke(): Flow<List<Tool>> {
        return toolRepository.getFavoriteTools()
    }
}