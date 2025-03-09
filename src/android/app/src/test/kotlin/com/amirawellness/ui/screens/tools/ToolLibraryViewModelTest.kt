package com.amirawellness.ui.screens.tools

import org.junit.Before
import org.junit.After
import org.junit.Test
import org.junit.Assert.*
import org.junit.Rule
import org.mockito.Mockito.*
import org.mockito.Mock
import org.mockito.ArgumentMatchers.*
import org.mockito.MockitoAnnotations
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.Flow
import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.lifecycle.SavedStateHandle
import java.util.UUID

import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.domain.usecases.tool.GetToolCategoriesUseCase
import com.amirawellness.domain.usecases.tool.GetToolsUseCase
import com.amirawellness.domain.usecases.tool.GetFavoriteToolsUseCase
import com.amirawellness.domain.usecases.tool.ToggleToolFavoriteUseCase

/**
 * Test class for ToolLibraryViewModel that verifies tool library functionality, error handling, and navigation
 */
class ToolLibraryViewModelTest {
    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()
    
    @Mock
    private lateinit var getToolCategoriesUseCase: GetToolCategoriesUseCase
    
    @Mock
    private lateinit var getToolsUseCase: GetToolsUseCase
    
    @Mock
    private lateinit var getFavoriteToolsUseCase: GetFavoriteToolsUseCase
    
    @Mock
    private lateinit var toggleToolFavoriteUseCase: ToggleToolFavoriteUseCase
    
    private lateinit var savedStateHandle: SavedStateHandle
    private lateinit var testScope: TestScope
    private lateinit var testDispatcher: StandardTestDispatcher
    private lateinit var viewModel: ToolLibraryViewModel
    
    /**
     * Sets up test environment before each test
     */
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        testDispatcher = StandardTestDispatcher()
        testScope = TestScope(testDispatcher)
        Dispatchers.setMain(testDispatcher)
        savedStateHandle = SavedStateHandle()
        
        // Set up default mock responses
        `when`(getToolCategoriesUseCase(anyBoolean())).thenReturn(flowOf(emptyList()))
        `when`(getToolsUseCase(eq(null), anyBoolean())).thenReturn(flowOf(emptyList()))
        `when`(getFavoriteToolsUseCase()).thenReturn(flowOf(emptyList()))
        
        // Initialize the view model with mocked dependencies
        viewModel = ToolLibraryViewModel(
            getToolCategoriesUseCase,
            getToolsUseCase,
            getFavoriteToolsUseCase,
            toggleToolFavoriteUseCase,
            savedStateHandle
        )
    }
    
    /**
     * Cleans up test environment after each test
     */
    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }
    
    /**
     * Tests that the initial UI state is correctly initialized
     */
    @Test
    fun testInitialState() {
        // Assert that initial state values match expected defaults
        assertEquals(emptyList<ToolCategory>(), viewModel.uiState.value.categories)
        assertEquals(emptyList<Tool>(), viewModel.uiState.value.tools)
        assertEquals(emptyList<Tool>(), viewModel.uiState.value.recentTools)
        assertEquals(0, viewModel.uiState.value.favoriteCount)
        assertNull(viewModel.uiState.value.selectedCategoryId)
        assertNull(viewModel.uiState.value.selectedToolId)
        assertTrue(viewModel.uiState.value.isLoading)
        assertFalse(viewModel.uiState.value.isRefreshing)
        assertNull(viewModel.uiState.value.error)
        assertFalse(viewModel.uiState.value.navigateToFavorites)
    }
    
    /**
     * Tests successful loading of tool categories and tools
     */
    @Test
    fun testLoadData_Success() = runTest {
        // Create test data
        val testCategories = createTestCategories()
        val testTools = createTestTools()
        val testFavoriteTools = createTestFavoriteTools()
        
        // Configure mocks to return test data
        `when`(getToolCategoriesUseCase(anyBoolean())).thenReturn(flowOf(testCategories))
        `when`(getToolsUseCase(eq(null), anyBoolean())).thenReturn(flowOf(testTools))
        `when`(getFavoriteToolsUseCase()).thenReturn(flowOf(testFavoriteTools))
        
        // Advance dispatcher to execute coroutines
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify the UI state is updated with the test data
        assertEquals(testCategories, viewModel.uiState.value.categories)
        assertEquals(testTools, viewModel.uiState.value.tools)
        assertEquals(testFavoriteTools.size, viewModel.uiState.value.favoriteCount)
        assertFalse(viewModel.uiState.value.isLoading)
        assertNull(viewModel.uiState.value.error)
    }
    
    /**
     * Tests error handling during data loading
     */
    @Test
    fun testLoadData_Error() = runTest {
        // Configure mock to throw an exception
        `when`(getToolCategoriesUseCase(anyBoolean())).thenAnswer { 
            throw RuntimeException("Test exception") 
        }
        
        // Advance dispatcher to execute coroutines
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify error state is set correctly
        assertFalse(viewModel.uiState.value.isLoading)
        assertNotNull(viewModel.uiState.value.error)
        assertTrue(viewModel.uiState.value.error?.contains("Test exception") ?: false)
    }
    
    /**
     * Tests category selection functionality
     */
    @Test
    fun testOnCategorySelected() = runTest {
        // Create test category ID and tools
        val categoryId = "test-category-id"
        val categoryTools = createTestTools(categoryId)
        
        // Configure mock to return tools for the selected category
        `when`(getToolsUseCase(eq(categoryId), anyBoolean())).thenReturn(flowOf(categoryTools))
        
        // Call method under test
        viewModel.onCategorySelected(categoryId)
        
        // Advance dispatcher to execute coroutines
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify use case was called and state was updated correctly
        verify(getToolsUseCase).invoke(eq(categoryId), anyBoolean())
        assertEquals(categoryId, viewModel.uiState.value.selectedCategoryId)
        assertEquals(categoryTools, viewModel.uiState.value.tools)
        assertEquals(categoryId, savedStateHandle.get<String>("selected_category"))
    }
    
    /**
     * Tests tool selection functionality
     */
    @Test
    fun testOnToolSelected() {
        // Create test tool ID
        val toolId = "test-tool-id"
        
        // Call method under test
        viewModel.onToolSelected(toolId)
        
        // Verify state was updated correctly
        assertEquals(toolId, viewModel.uiState.value.selectedToolId)
    }
    
    /**
     * Tests navigation to favorites screen
     */
    @Test
    fun testOnFavoritesClicked() {
        // Call method under test
        viewModel.onFavoritesClicked()
        
        // Verify navigation flag is set
        assertTrue(viewModel.uiState.value.navigateToFavorites)
    }
    
    /**
     * Tests successful toggling of tool favorite status
     */
    @Test
    fun testToggleFavorite_Success() = runTest {
        // Create test tool with favorite status false
        val toolId = "test-tool-id"
        val initialFavoriteState = false
        val tool = Tool(
            id = toolId,
            name = "Test Tool",
            description = "Test Description",
            category = ToolCategory("category-id", "Test Category", "Test Description", null, 0),
            contentType = ToolContentType.TEXT,
            content = ToolContent("Title", "Instructions", null, null, null),
            isFavorite = initialFavoriteState,
            usageCount = 0,
            targetEmotions = emptyList(),
            estimatedDuration = 5
        )
        val tools = listOf(tool)
        
        // Configure mocks
        `when`(getToolsUseCase(eq(null), anyBoolean())).thenReturn(flowOf(tools))
        `when`(toggleToolFavoriteUseCase(eq(toolId), eq(!initialFavoriteState))).thenReturn(true)
        
        // Advance dispatcher to load initial data
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Call method under test
        viewModel.toggleFavorite(toolId)
        
        // Advance dispatcher to execute toggle operation
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify toggle use case was called with correct parameters
        verify(toggleToolFavoriteUseCase).invoke(eq(toolId), eq(!initialFavoriteState))
        
        // Update mock to return tools with toggled favorite status
        val updatedTools = listOf(
            tool.copy(isFavorite = !initialFavoriteState)
        )
        `when`(getToolsUseCase(eq(null), anyBoolean())).thenReturn(flowOf(updatedTools))
        
        // Advance dispatcher to reload data
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify tool in UI state has updated favorite status
        val toolInState = viewModel.uiState.value.tools.find { it.id == toolId }
        assertNotNull(toolInState)
        assertEquals(!initialFavoriteState, toolInState?.isFavorite)
    }
    
    /**
     * Tests error handling during favorite toggling
     */
    @Test
    fun testToggleFavorite_Error() = runTest {
        // Create test tool with favorite status false
        val toolId = "test-tool-id"
        val initialFavoriteState = false
        val tool = Tool(
            id = toolId,
            name = "Test Tool",
            description = "Test Description",
            category = ToolCategory("category-id", "Test Category", "Test Description", null, 0),
            contentType = ToolContentType.TEXT,
            content = ToolContent("Title", "Instructions", null, null, null),
            isFavorite = initialFavoriteState,
            usageCount = 0,
            targetEmotions = emptyList(),
            estimatedDuration = 5
        )
        val tools = listOf(tool)
        
        // Configure mocks
        `when`(getToolsUseCase(eq(null), anyBoolean())).thenReturn(flowOf(tools))
        `when`(toggleToolFavoriteUseCase(eq(toolId), anyBoolean())).thenAnswer {
            throw RuntimeException("Toggle favorite error")
        }
        
        // Advance dispatcher to load initial data
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Call method under test
        viewModel.toggleFavorite(toolId)
        
        // Advance dispatcher to execute toggle operation
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify error state is set
        assertNotNull(viewModel.uiState.value.error)
        assertTrue(viewModel.uiState.value.error?.contains("Toggle favorite error") ?: false)
    }
    
    /**
     * Tests refresh functionality
     */
    @Test
    fun testRefresh() = runTest {
        // Call method under test
        viewModel.refresh()
        
        // Verify isRefreshing flag is set to true
        assertTrue(viewModel.uiState.value.isRefreshing)
        
        // Advance dispatcher to execute refresh operation
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify use cases were called with forceRefresh=true
        verify(getToolCategoriesUseCase).invoke(eq(true))
        verify(getToolsUseCase).invoke(eq(null), eq(true))
        verify(getFavoriteToolsUseCase).invoke()
        
        // Verify isRefreshing flag is reset to false
        assertFalse(viewModel.uiState.value.isRefreshing)
    }
    
    /**
     * Tests clearing error message in UI state
     */
    @Test
    fun testClearError() = runTest {
        // Set up UI state with an error message
        `when`(getToolCategoriesUseCase(anyBoolean())).thenAnswer { 
            throw RuntimeException("Test exception") 
        }
        
        // Advance dispatcher to trigger error
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Verify error is set
        assertNotNull(viewModel.uiState.value.error)
        
        // Call method under test
        viewModel.clearError()
        
        // Verify error is cleared
        assertNull(viewModel.uiState.value.error)
    }
    
    /**
     * Helper method to create test tool categories
     */
    private fun createTestCategories(): List<ToolCategory> {
        return listOf(
            ToolCategory(
                id = "category-1",
                name = "Breathing",
                description = "Breathing exercises",
                iconUrl = null,
                toolCount = 3
            ),
            ToolCategory(
                id = "category-2",
                name = "Meditation",
                description = "Meditation exercises",
                iconUrl = null,
                toolCount = 2
            )
        )
    }
    
    /**
     * Helper method to create test tools
     */
    private fun createTestTools(categoryId: String? = null): List<Tool> {
        val category = ToolCategory(
            id = categoryId ?: "category-1",
            name = "Test Category",
            description = "Test Description",
            iconUrl = null,
            toolCount = 2
        )
        
        return listOf(
            Tool(
                id = "tool-1",
                name = "Deep Breathing",
                description = "A simple breathing exercise",
                category = category,
                contentType = ToolContentType.TEXT,
                content = ToolContent("Deep Breathing", "Breathe deeply", null, null, null),
                isFavorite = false,
                usageCount = 5,
                targetEmotions = emptyList(),
                estimatedDuration = 5
            ),
            Tool(
                id = "tool-2",
                name = "Box Breathing",
                description = "A box breathing technique",
                category = category,
                contentType = ToolContentType.TEXT,
                content = ToolContent("Box Breathing", "Follow the box pattern", null, null, null),
                isFavorite = true,
                usageCount = 3,
                targetEmotions = emptyList(),
                estimatedDuration = 3
            )
        )
    }
    
    /**
     * Helper method to create test favorite tools
     */
    private fun createTestFavoriteTools(): List<Tool> {
        return listOf(
            Tool(
                id = "tool-2",
                name = "Box Breathing",
                description = "A box breathing technique",
                category = ToolCategory("category-1", "Breathing", "Breathing exercises", null, 3),
                contentType = ToolContentType.TEXT,
                content = ToolContent("Box Breathing", "Follow the box pattern", null, null, null),
                isFavorite = true,
                usageCount = 3,
                targetEmotions = emptyList(),
                estimatedDuration = 3
            ),
            Tool(
                id = "tool-3",
                name = "Meditation",
                description = "A simple meditation",
                category = ToolCategory("category-2", "Meditation", "Meditation exercises", null, 2),
                contentType = ToolContentType.AUDIO,
                content = ToolContent("Meditation", "Follow the guide", "url", null, null),
                isFavorite = true,
                usageCount = 1,
                targetEmotions = emptyList(),
                estimatedDuration = 10
            )
        )
    }
}