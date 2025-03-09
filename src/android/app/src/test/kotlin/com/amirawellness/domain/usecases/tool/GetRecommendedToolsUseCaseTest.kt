package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.repositories.ToolRepository
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.models.ToolContent
import com.amirawellness.data.models.ToolContentType
import com.amirawellness.core.constants.AppConstants.EmotionType
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import org.mockito.Mockito.*
import org.mockito.Mock
import org.mockito.ArgumentMatchers.*
import org.mockito.MockitoAnnotations
import kotlinx.coroutines.test.runTest
import java.util.UUID

/**
 * Test class for GetRecommendedToolsUseCase that verifies tool recommendation functionality
 */
class GetRecommendedToolsUseCaseTest {

    @Mock
    private lateinit var toolRepository: ToolRepository
    
    private lateinit var getRecommendedToolsUseCase: GetRecommendedToolsUseCase
    
    /**
     * Sets up test environment before each test
     */
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        getRecommendedToolsUseCase = GetRecommendedToolsUseCase(toolRepository)
    }
    
    /**
     * Tests successful retrieval of tool recommendations based on emotional state
     */
    @Test
    fun testInvoke_WithEmotionalState_Success() = runTest {
        // Create test emotional state with ANXIETY emotion type and intensity 7
        val emotionalState = createTestEmotionalState(EmotionType.ANXIETY, 7)
        
        // Create test tool list for recommendations
        val testTools = listOf(
            createTestTool("1", "Breathing Exercise", "1", listOf(EmotionType.ANXIETY)),
            createTestTool("2", "Mindfulness Meditation", "2", listOf(EmotionType.ANXIETY))
        )
        
        // Configure toolRepository mock to return test tools
        `when`(toolRepository.getRecommendedTools("ANXIETY", 7)).thenReturn(testTools)
        
        // Execute getRecommendedToolsUseCase with emotional state
        val result = getRecommendedToolsUseCase(emotionalState)
        
        // Verify toolRepository.getRecommendedTools was called with correct emotion type and intensity
        verify(toolRepository).getRecommendedTools("ANXIETY", 7)
        
        // Assert that the result is successful and contains the expected tools
        assertTrue(result.isSuccess)
        assertEquals(testTools, result.getOrNull())
    }
    
    /**
     * Tests successful retrieval of tool recommendations using direct emotion type and intensity parameters
     */
    @Test
    fun testInvoke_WithEmotionTypeAndIntensity_Success() = runTest {
        // Create test emotion type (ANXIETY) and intensity (7)
        val emotionType = "ANXIETY"
        val intensity = 7
        
        // Create test tool list for recommendations
        val testTools = listOf(
            createTestTool("1", "Breathing Exercise", "1", listOf(EmotionType.ANXIETY)),
            createTestTool("2", "Mindfulness Meditation", "2", listOf(EmotionType.ANXIETY))
        )
        
        // Configure toolRepository mock to return test tools
        `when`(toolRepository.getRecommendedTools(emotionType, intensity)).thenReturn(testTools)
        
        // Execute getRecommendedToolsUseCase with emotion type and intensity
        val result = getRecommendedToolsUseCase(emotionType, intensity)
        
        // Verify toolRepository.getRecommendedTools was called with correct emotion type and intensity
        verify(toolRepository).getRecommendedTools(emotionType, intensity)
        
        // Assert that the result is successful and contains the expected tools
        assertTrue(result.isSuccess)
        assertEquals(testTools, result.getOrNull())
    }
    
    /**
     * Tests retrieval of tool recommendations when result is empty
     */
    @Test
    fun testInvoke_EmptyResult() = runTest {
        // Create test emotional state
        val emotionalState = createTestEmotionalState(EmotionType.JOY, 5)
        val emptyList = emptyList<Tool>()
        
        // Configure toolRepository mock to return empty list
        `when`(toolRepository.getRecommendedTools("JOY", 5)).thenReturn(emptyList)
        
        // Execute getRecommendedToolsUseCase
        val result = getRecommendedToolsUseCase(emotionalState)
        
        // Verify toolRepository.getRecommendedTools was called
        verify(toolRepository).getRecommendedTools("JOY", 5)
        
        // Assert that the result is successful and contains an empty list
        assertTrue(result.isSuccess)
        assertEquals(emptyList, result.getOrNull())
    }
    
    /**
     * Tests error handling when repository throws an exception
     */
    @Test
    fun testInvoke_RepositoryError() = runTest {
        // Create test emotional state
        val emotionalState = createTestEmotionalState(EmotionType.ANXIETY, 6)
        val expectedException = RuntimeException("Network error")
        
        // Configure toolRepository mock to throw an exception
        `when`(toolRepository.getRecommendedTools("ANXIETY", 6)).thenThrow(expectedException)
        
        // Execute getRecommendedToolsUseCase
        val result = getRecommendedToolsUseCase(emotionalState)
        
        // Verify toolRepository.getRecommendedTools was called
        verify(toolRepository).getRecommendedTools("ANXIETY", 6)
        
        // Assert that the result is a failure containing the expected exception
        assertTrue(result.isFailure)
        assertEquals(expectedException, result.exceptionOrNull())
    }
    
    /**
     * Tests that high intensity emotional states return appropriate calming tools
     */
    @Test
    fun testInvoke_HighIntensityFiltering() = runTest {
        // Create test emotional state with high intensity (8)
        val emotionalState = createTestEmotionalState(EmotionType.ANXIETY, 8)
        
        // Create test tool list with various tool types
        val testTools = listOf(
            createTestTool("1", "Breathing Exercise", "1", listOf(EmotionType.ANXIETY)),
            createTestTool("2", "Journaling Prompt", "2", listOf(EmotionType.ANXIETY)),
            createTestTool("3", "Grounding Technique", "1", listOf(EmotionType.ANXIETY))
        )
        
        // Configure toolRepository mock to return test tools
        `when`(toolRepository.getRecommendedTools("ANXIETY", 8)).thenReturn(testTools)
        
        // Execute getRecommendedToolsUseCase
        val result = getRecommendedToolsUseCase(emotionalState)
        
        // Verify toolRepository.getRecommendedTools was called
        verify(toolRepository).getRecommendedTools("ANXIETY", 8)
        
        // Assert that the result prioritizes calming and grounding tools
        assertTrue(result.isSuccess)
        val resultList = result.getOrNull()
        assertNotNull(resultList)
        
        // Breathing exercises should be prioritized for high intensity
        assertEquals("Breathing Exercise", resultList?.get(0)?.name)
        // Grounding techniques should be prioritized next
        assertEquals("Grounding Technique", resultList?.get(1)?.name)
        // Journaling should be lower priority for high intensity
        assertEquals("Journaling Prompt", resultList?.get(2)?.name)
    }
    
    /**
     * Tests that low intensity emotional states return appropriate enhancement tools
     */
    @Test
    fun testInvoke_LowIntensityFiltering() = runTest {
        // Create test emotional state with low intensity (3)
        val emotionalState = createTestEmotionalState(EmotionType.JOY, 3)
        
        // Create test tool list with various tool types
        val testTools = listOf(
            createTestTool("1", "Breathing Exercise", "1", listOf(EmotionType.JOY)),
            createTestTool("2", "Gratitude Journal", "2", listOf(EmotionType.JOY)),
            createTestTool("3", "Reflective Practice", "1", listOf(EmotionType.JOY))
        )
        
        // Configure toolRepository mock to return test tools
        `when`(toolRepository.getRecommendedTools("JOY", 3)).thenReturn(testTools)
        
        // Execute getRecommendedToolsUseCase
        val result = getRecommendedToolsUseCase(emotionalState)
        
        // Verify toolRepository.getRecommendedTools was called
        verify(toolRepository).getRecommendedTools("JOY", 3)
        
        // Assert that the result prioritizes enhancement and maintenance tools
        assertTrue(result.isSuccess)
        val resultList = result.getOrNull()
        assertNotNull(resultList)
        
        // Gratitude exercises should be prioritized for low intensity positive emotions
        assertEquals("Gratitude Journal", resultList?.get(0)?.name)
        // Reflective practices should be prioritized next
        assertEquals("Reflective Practice", resultList?.get(1)?.name)
        // Breathing exercises lower priority for low intensity
        assertEquals("Breathing Exercise", resultList?.get(2)?.name)
    }
    
    /**
     * Helper method to create a test emotional state
     */
    private fun createTestEmotionalState(emotionType: EmotionType, intensity: Int): EmotionalState {
        return EmotionalState(
            id = UUID.randomUUID().toString(),
            emotionType = emotionType,
            intensity = intensity,
            context = "TEST_CONTEXT",
            notes = null,
            createdAt = System.currentTimeMillis(),
            relatedJournalId = null,
            relatedToolId = null
        )
    }
    
    /**
     * Helper method to create a test tool
     */
    private fun createTestTool(id: String, name: String, categoryId: String, targetEmotions: List<EmotionType>): Tool {
        val category = createTestCategory(categoryId, name)
        val content = createTestContent()
        
        return Tool(
            id = id,
            name = name,
            description = name + " description",
            category = category,
            contentType = ToolContentType.TEXT,
            content = content,
            isFavorite = false,
            usageCount = 0,
            targetEmotions = targetEmotions,
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
            title = "Test Content",
            instructions = "Test instructions",
            mediaUrl = null,
            steps = null,
            additionalResources = null
        )
    }
}