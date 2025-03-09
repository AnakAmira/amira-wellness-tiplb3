package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.models.Tool
import com.amirawellness.data.repositories.ToolRepository
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines version: 1.6.4
import javax.inject.Inject // javax.inject version: 1

/**
 * Use case for retrieving tools from the repository, optionally filtered by category.
 * This class implements the Tool Library feature (F-005) by providing a clean architecture
 * component that encapsulates the business logic for fetching tools.
 *
 * The use case follows the single responsibility principle by focusing only on retrieving
 * tools, with support for category-based filtering and forced data refresh from remote sources
 * when needed.
 */
class GetToolsUseCase @Inject constructor(
    private val toolRepository: ToolRepository
) {
    /**
     * Executes the use case to retrieve tools, optionally filtered by category.
     *
     * @param categoryId Optional category ID to filter tools by category, supporting the Tool
     *                   Categorization requirement for organized presentation
     * @param forceRefresh Whether to force a refresh from the remote data source, which supports
     *                     the Offline Capabilities requirement by enabling manual refresh
     * @return Flow emitting a list of tools, filtered by category if specified
     */
    suspend operator fun invoke(
        categoryId: String? = null,
        forceRefresh: Boolean = false
    ): Flow<List<Tool>> {
        return toolRepository.getTools(categoryId, forceRefresh)
    }
}