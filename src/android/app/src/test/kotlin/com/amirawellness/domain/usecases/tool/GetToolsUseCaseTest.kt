package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.models.ToolContent
import com.amirawellness.data.models.ToolContentType
import com.amirawellness.data.repositories.ToolRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.mockito.MockitoAnnotations
import java.util.UUID

/**
 * Test class for GetToolsUseCase that verifies tool retrieval functionality
 */
class GetToolsUseCaseTest {

    @Mock
    private lateinit var toolRepository: ToolRepository

    private lateinit var getToolsUseCase: GetToolsUseCase

    /**
     * Sets up test environment before each test
     */
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        getToolsUseCase = GetToolsUseCase(toolRepository)
    }

    /**
     * Tests successful retrieval of all tools without parameters
     */
    @Test
    fun testInvoke_NoParameters_Success() = runTest {
        // Create test tool list
        val tools = listOf(
            createTestTool("1", "Tool 1", "category1"),
            createTestTool("2", "Tool 2", "category1")
        )

        // Configure toolRepository mock to return test tools
        `when`(toolRepository.getTools(isNull(), eq(false))).thenReturn(flowOf(tools))

        // Execute getToolsUseCase with no parameters
        val result = getToolsUseCase().first()

        // Verify toolRepository.getTools was called with null categoryId and false forceRefresh
        verify(toolRepository).getTools(null, false)

        // Assert that the result contains the expected tools
        assertEquals(tools, result)
    }

    /**
     * Tests successful retrieval of tools filtered by category
     */
    @Test
    fun testInvoke_WithCategoryId_Success() = runTest {
        // Create test category ID
        val categoryId = "category1"
        
        // Create test tool list for the category
        val tools = listOf(
            createTestTool("1", "Tool 1", categoryId),
            createTestTool("2", "Tool 2", categoryId)
        )

        // Configure toolRepository mock to return test tools for the category
        `when`(toolRepository.getTools(eq(categoryId), eq(false))).thenReturn(flowOf(tools))

        // Execute getToolsUseCase with category ID
        val result = getToolsUseCase(categoryId).first()

        // Verify toolRepository.getTools was called with the correct category ID and false forceRefresh
        verify(toolRepository).getTools(categoryId, false)

        // Assert that the result contains the expected tools
        assertEquals(tools, result)
    }

    /**
     * Tests successful retrieval of tools with forced refresh
     */
    @Test
    fun testInvoke_WithForceRefresh_Success() = runTest {
        // Create test tool list
        val tools = listOf(
            createTestTool("1", "Tool 1", "category1"),
            createTestTool("2", "Tool 2", "category1")
        )

        // Configure toolRepository mock to return test tools
        `when`(toolRepository.getTools(isNull(), eq(true))).thenReturn(flowOf(tools))

        // Execute getToolsUseCase with forceRefresh=true
        val result = getToolsUseCase(forceRefresh = true).first()

        // Verify toolRepository.getTools was called with null categoryId and true forceRefresh
        verify(toolRepository).getTools(null, true)

        // Assert that the result contains the expected tools
        assertEquals(tools, result)
    }

    /**
     * Tests successful retrieval of tools filtered by category with forced refresh
     */
    @Test
    fun testInvoke_WithCategoryIdAndForceRefresh_Success() = runTest {
        // Create test category ID
        val categoryId = "category1"
        
        // Create test tool list for the category
        val tools = listOf(
            createTestTool("1", "Tool 1", categoryId),
            createTestTool("2", "Tool 2", categoryId)
        )

        // Configure toolRepository mock to return test tools for the category
        `when`(toolRepository.getTools(eq(categoryId), eq(true))).thenReturn(flowOf(tools))

        // Execute getToolsUseCase with category ID and forceRefresh=true
        val result = getToolsUseCase(categoryId, true).first()

        // Verify toolRepository.getTools was called with the correct category ID and true forceRefresh
        verify(toolRepository).getTools(categoryId, true)

        // Assert that the result contains the expected tools
        assertEquals(tools, result)
    }

    /**
     * Tests retrieval of tools when result is empty
     */
    @Test
    fun testInvoke_EmptyResult() = runTest {
        // Configure toolRepository mock to return empty list
        `when`(toolRepository.getTools(isNull(), eq(false))).thenReturn(flowOf(emptyList()))

        // Execute getToolsUseCase
        val result = getToolsUseCase().first()

        // Verify toolRepository.getTools was called
        verify(toolRepository).getTools(null, false)

        // Assert that the result is an empty list
        assertEquals(emptyList<Tool>(), result)
    }

    /**
     * Helper method to create a test tool
     */
    private fun createTestTool(id: String, name: String, categoryId: String): Tool {
        return Tool(
            id = id,
            name = name,
            description = "Test description",
            category = createTestCategory(categoryId, "Test Category"),
            contentType = ToolContentType.TEXT,
            content = createTestContent(),
            isFavorite = false,
            usageCount = 0,
            targetEmotions = emptyList(),
            estimatedDuration = 5
        )
    }

    /**
     * Helper method to create a test tool category
     */
    private fun createTestCategory(id: String, name: String): ToolCategory {
        return ToolCategory(
            id = id,
            name = name,
            description = "Test category description",
            iconUrl = null,
            toolCount = 0
        )
    }

    /**
     * Helper method to create test tool content
     */
    private fun createTestContent(): ToolContent {
        return ToolContent(
            title = "Test Title",
            instructions = "Test Instructions",
            mediaUrl = null,
            steps = null,
            additionalResources = null
        )
    }
}