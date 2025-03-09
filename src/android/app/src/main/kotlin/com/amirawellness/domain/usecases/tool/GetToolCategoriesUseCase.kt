package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.repositories.ToolRepository
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines version: 1.6.4
import javax.inject.Inject // javax.inject version: 1

/**
 * Use case for retrieving tool categories from the repository.
 * 
 * This class follows the clean architecture pattern and encapsulates the business logic
 * for fetching tool categories, providing a single responsibility component that can be
 * easily tested and maintained. It supports offline capabilities through the repository's
 * local caching mechanism with an option to force refresh from the remote data source.
 */
class GetToolCategoriesUseCase @Inject constructor(
    private val toolRepository: ToolRepository
) {
    /**
     * Executes the use case to retrieve tool categories.
     *
     * @param forceRefresh If true, forces a refresh from the remote data source
     * @return Flow emitting a list of tool categories
     */
    suspend operator fun invoke(forceRefresh: Boolean = false): Flow<List<ToolCategory>> {
        return toolRepository.getToolCategories(forceRefresh)
    }
}