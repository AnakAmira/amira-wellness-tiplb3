package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.models.Tool
import com.amirawellness.data.repositories.ToolRepository
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines version: 1.6.4
import javax.inject.Inject // javax.inject version: 1

/**
 * Use case for retrieving a specific tool by its ID from the repository.
 * 
 * This class follows the clean architecture pattern and encapsulates the business logic
 * for fetching a single tool from the repository. It provides a single responsibility
 * component that can be easily tested and maintained.
 */
class GetToolUseCase @Inject constructor(
    private val toolRepository: ToolRepository
) {
    /**
     * Executes the use case to retrieve a specific tool by its ID.
     *
     * @param id The unique identifier of the tool to retrieve
     * @param forceRefresh If true, forces a refresh from the remote data source
     * @return Flow emitting the tool if found, or null if not found
     */
    suspend operator fun invoke(id: String, forceRefresh: Boolean = false): Flow<Tool?> {
        return toolRepository.getToolById(id, forceRefresh)
    }
}