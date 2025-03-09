package com.amirawellness.data.repositories

import com.amirawellness.data.local.dao.ToolDao
import com.amirawellness.data.local.dao.ToolCategoryDao
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.models.ToolContent
import com.amirawellness.data.models.ToolContentType
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.dto.ToolCategoryDto
import com.amirawellness.data.remote.dto.ToolContentDto
import com.amirawellness.data.remote.dto.ToolDto
import com.amirawellness.data.remote.mappers.ToolMapper
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestCoroutineDispatcher
import kotlinx.coroutines.test.TestCoroutineScope
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.anyList
import org.mockito.ArgumentMatchers.anyString
import org.mockito.ArgumentMatchers.eq
import org.mockito.Mock
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mockito.Mockito.verifyNoInteractions
import org.mockito.MockitoAnnotations
import retrofit2.Call
import retrofit2.Response
import java.io.IOException
import java.util.UUID

@ExperimentalCoroutinesApi
class ToolRepositoryTest {
    private const val TEST_TOOL_ID = "test-tool-id"
    private const val TEST_CATEGORY_ID = "test-category-id"
    private const val TEST_EMOTION_TYPE = "ANXIETY"

    @Mock
    private lateinit var mockToolDao: ToolDao
    
    @Mock
    private lateinit var mockToolCategoryDao: ToolCategoryDao
    
    @Mock
    private lateinit var mockApiService: ApiService
    
    @Mock
    private lateinit var mockNetworkMonitor: NetworkMonitor
    
    @Mock
    private lateinit var mockToolMapper: ToolMapper

    private lateinit var testDispatcher: TestCoroutineDispatcher
    private lateinit var testScope: TestCoroutineScope
    private lateinit var repository: ToolRepository

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        
        testDispatcher = TestCoroutineDispatcher()
        testScope = TestCoroutineScope(testDispatcher)
        
        // Default network availability is true
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        
        // Set up default behavior for Tool mapper
        `when`(mockToolMapper.toTool(any())).thenAnswer { invocation ->
            val dto = invocation.getArgument<ToolDto>(0)
            createTestTool(id = dto.id, isFavorite = dto.isFavorite, usageCount = dto.usageCount)
        }
        
        repository = ToolRepository(
            toolDao = mockToolDao,
            toolCategoryDao = mockToolCategoryDao,
            apiService = mockApiService,
            networkMonitor = mockNetworkMonitor
        )
    }

    private fun createTestTool(
        id: String = TEST_TOOL_ID, 
        isFavorite: Boolean = false, 
        usageCount: Int = 0
    ): Tool {
        val category = createTestToolCategory()
        return Tool(
            id = id,
            name = "Test Tool",
            description = "Test description",
            category = category,
            contentType = ToolContentType.TEXT,
            content = ToolContent(
                title = "Test Content",
                instructions = "Test instructions",
                mediaUrl = null,
                steps = null,
                additionalResources = null
            ),
            isFavorite = isFavorite,
            usageCount = usageCount,
            targetEmotions = listOf(com.amirawellness.core.constants.AppConstants.EmotionType.ANXIETY),
            estimatedDuration = 5
        )
    }

    private fun createTestToolDto(
        id: String = TEST_TOOL_ID, 
        isFavorite: Boolean = false, 
        usageCount: Int = 0
    ): ToolDto {
        val category = createTestToolCategoryDto()
        return ToolDto(
            id = id,
            name = "Test Tool",
            description = "Test description",
            category = category,
            contentType = "TEXT",
            content = ToolContentDto(
                title = "Test Content",
                instructions = "Test instructions",
                mediaUrl = null,
                steps = null,
                additionalResources = null
            ),
            isFavorite = isFavorite,
            usageCount = usageCount,
            targetEmotions = listOf(TEST_EMOTION_TYPE),
            estimatedDuration = 5
        )
    }

    private fun createTestToolCategory(
        id: String = TEST_CATEGORY_ID, 
        name: String = "Test Category"
    ): ToolCategory {
        return ToolCategory(
            id = id,
            name = name,
            description = "Test category description",
            iconUrl = null,
            toolCount = 5
        )
    }

    private fun createTestToolCategoryDto(
        id: String = TEST_CATEGORY_ID, 
        name: String = "Test Category"
    ): ToolCategoryDto {
        return ToolCategoryDto(
            id = id,
            name = name,
            description = "Test category description",
            iconUrl = null,
            toolCount = 5
        )
    }

    @Test
    fun testGetTools_noCategory_success() = runTest {
        // Create test data
        val testTools = listOf(createTestTool(), createTestTool(id = "tool-2"))
        
        // Set up mock responses
        `when`(mockToolDao.getAllTools()).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getTools(categoryId = null, forceRefresh = false)
        
        // Verify interactions
        verify(mockToolDao).getAllTools()
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testGetTools_withCategory_success() = runTest {
        // Create test data
        val testTools = listOf(createTestTool(), createTestTool(id = "tool-2"))
        
        // Set up mock responses
        `when`(mockToolDao.getToolsByCategory(TEST_CATEGORY_ID)).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getTools(categoryId = TEST_CATEGORY_ID, forceRefresh = false)
        
        // Verify interactions
        verify(mockToolDao).getToolsByCategory(TEST_CATEGORY_ID)
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testGetTools_forceRefresh_success() = runTest {
        // Create test data
        val testTools = listOf(createTestTool(), createTestTool(id = "tool-2"))
        val testToolDtos = listOf(createTestToolDto(), createTestToolDto(id = "tool-2"))
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<List<ToolDto>>
        val mockResponse = Response.success(testToolDtos)
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.getToolsByCategory(null)).thenReturn(mockCall)
        
        // Set up DAO mocks
        `when`(mockToolDao.insertTools(anyList())).thenReturn(listOf(1L, 2L))
        `when`(mockToolDao.getAllTools()).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getTools(categoryId = null, forceRefresh = true)
        
        // Verify interactions
        verify(mockApiService).getToolsByCategory(null)
        verify(mockToolDao).insertTools(anyList())
        verify(mockToolDao).getAllTools()
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testGetTools_forceRefresh_networkError() = runTest {
        // Create test data
        val testTools = listOf(createTestTool(), createTestTool(id = "tool-2"))
        
        // Set up network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Set up mock responses
        `when`(mockToolDao.getAllTools()).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getTools(categoryId = null, forceRefresh = true)
        
        // Verify interactions
        verify(mockApiService, never()).getToolsByCategory(any())
        verify(mockToolDao).getAllTools()
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testGetToolById_success() = runTest {
        // Create test data
        val testTool = createTestTool()
        
        // Set up mock responses
        `when`(mockToolDao.getToolById(TEST_TOOL_ID)).thenReturn(flowOf(testTool))
        
        // Call the method under test
        val result = repository.getToolById(TEST_TOOL_ID, forceRefresh = false)
        
        // Verify interactions
        verify(mockToolDao).getToolById(TEST_TOOL_ID)
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTool)
    }

    @Test
    fun testGetToolById_forceRefresh_success() = runTest {
        // Create test data
        val testTool = createTestTool()
        val testToolDto = createTestToolDto()
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<ToolDto>
        val mockResponse = Response.success(testToolDto)
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.getTool(TEST_TOOL_ID)).thenReturn(mockCall)
        
        // Set up DAO mocks
        `when`(mockToolDao.insertTool(any())).thenReturn(1L)
        `when`(mockToolDao.getToolById(TEST_TOOL_ID)).thenReturn(flowOf(testTool))
        
        // Call the method under test
        val result = repository.getToolById(TEST_TOOL_ID, forceRefresh = true)
        
        // Verify interactions
        verify(mockApiService).getTool(TEST_TOOL_ID)
        verify(mockToolDao).insertTool(any())
        verify(mockToolDao).getToolById(TEST_TOOL_ID)
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTool)
    }

    @Test
    fun testGetToolById_notFound() = runTest {
        // Set up mock responses
        `when`(mockToolDao.getToolById(TEST_TOOL_ID)).thenReturn(flowOf(null))
        
        // Call the method under test
        val result = repository.getToolById(TEST_TOOL_ID, forceRefresh = false)
        
        // Verify interactions
        verify(mockToolDao).getToolById(TEST_TOOL_ID)
        
        // Assert the result
        assertThat(result.first()).isNull()
    }

    @Test
    fun testGetFavoriteTools_success() = runTest {
        // Create test data
        val testTools = listOf(
            createTestTool(isFavorite = true), 
            createTestTool(id = "tool-2", isFavorite = true)
        )
        
        // Set up mock responses
        `when`(mockToolDao.getFavoriteTools()).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getFavoriteTools()
        
        // Verify interactions
        verify(mockToolDao).getFavoriteTools()
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testToggleToolFavorite_success() = runTest {
        // Set up mock responses
        `when`(mockToolDao.updateFavoriteStatus(TEST_TOOL_ID, true)).thenReturn(1)
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<ToolDto>
        val mockResponse = Response.success(createTestToolDto(isFavorite = true))
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.toggleToolFavorite(TEST_TOOL_ID)).thenReturn(mockCall)
        
        // Call the method under test
        val result = repository.toggleToolFavorite(TEST_TOOL_ID, true)
        
        // Verify interactions
        verify(mockToolDao).updateFavoriteStatus(TEST_TOOL_ID, true)
        verify(mockApiService).toggleToolFavorite(TEST_TOOL_ID)
        
        // Assert the result
        assertThat(result).isTrue()
    }

    @Test
    fun testToggleToolFavorite_offline() = runTest {
        // Set up network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Set up mock responses
        `when`(mockToolDao.updateFavoriteStatus(TEST_TOOL_ID, true)).thenReturn(1)
        
        // Call the method under test
        val result = repository.toggleToolFavorite(TEST_TOOL_ID, true)
        
        // Verify interactions
        verify(mockToolDao).updateFavoriteStatus(TEST_TOOL_ID, true)
        verify(mockApiService, never()).toggleToolFavorite(anyString())
        
        // Assert the result
        assertThat(result).isTrue()
    }

    @Test
    fun testTrackToolUsage_success() = runTest {
        // Set up mock responses
        `when`(mockToolDao.incrementUsageCount(TEST_TOOL_ID)).thenReturn(1)
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<ToolDto>
        val mockResponse = Response.success(createTestToolDto(usageCount = 1))
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.trackToolUsage(eq(TEST_TOOL_ID), eq(300))).thenReturn(mockCall)
        
        // Call the method under test
        val result = repository.trackToolUsage(TEST_TOOL_ID, 300)
        
        // Verify interactions
        verify(mockToolDao).incrementUsageCount(TEST_TOOL_ID)
        verify(mockApiService).trackToolUsage(TEST_TOOL_ID, 300)
        
        // Assert the result
        assertThat(result).isTrue()
    }

    @Test
    fun testTrackToolUsage_offline() = runTest {
        // Set up network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Set up mock responses
        `when`(mockToolDao.incrementUsageCount(TEST_TOOL_ID)).thenReturn(1)
        
        // Call the method under test
        val result = repository.trackToolUsage(TEST_TOOL_ID, 300)
        
        // Verify interactions
        verify(mockToolDao).incrementUsageCount(TEST_TOOL_ID)
        verify(mockApiService, never()).trackToolUsage(anyString(), any())
        
        // Assert the result
        assertThat(result).isTrue()
    }

    @Test
    fun testSearchTools_success() = runTest {
        // Create test data
        val searchQuery = "breathing"
        val testTools = listOf(
            createTestTool(), 
            createTestTool(id = "tool-2")
        )
        
        // Set up mock responses
        `when`(mockToolDao.searchTools(searchQuery)).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.searchTools(searchQuery)
        
        // Verify interactions
        verify(mockToolDao).searchTools(searchQuery)
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testGetToolsByDuration_success() = runTest {
        // Create test data
        val maxDuration = 5
        val testTools = listOf(
            createTestTool(), 
            createTestTool(id = "tool-2")
        )
        
        // Set up mock responses
        `when`(mockToolDao.getToolsByDuration(maxDuration)).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getToolsByDuration(maxDuration)
        
        // Verify interactions
        verify(mockToolDao).getToolsByDuration(maxDuration)
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testGetToolsByEmotionType_success() = runTest {
        // Create test data
        val testTools = listOf(
            createTestTool(), 
            createTestTool(id = "tool-2")
        )
        
        // Set up mock responses
        `when`(mockToolDao.getToolsByEmotionType(TEST_EMOTION_TYPE)).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getToolsByEmotionType(TEST_EMOTION_TYPE)
        
        // Verify interactions
        verify(mockToolDao).getToolsByEmotionType(TEST_EMOTION_TYPE)
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testTools)
    }

    @Test
    fun testGetRecommendedTools_online_success() = runTest {
        // Create test data
        val emotionType = TEST_EMOTION_TYPE
        val intensity = 7
        val testTools = listOf(
            createTestTool(), 
            createTestTool(id = "tool-2")
        )
        val testToolDtos = listOf(
            createTestToolDto(), 
            createTestToolDto(id = "tool-2")
        )
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<List<ToolDto>>
        val mockResponse = Response.success(testToolDtos)
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.getToolRecommendations(emotionType, intensity)).thenReturn(mockCall)
        
        // Mock the Tool.Companion.fromDto method via the mockToolMapper
        `when`(mockToolMapper.toTool(testToolDtos[0])).thenReturn(testTools[0])
        `when`(mockToolMapper.toTool(testToolDtos[1])).thenReturn(testTools[1])
        
        // Call the method under test
        val result = repository.getRecommendedTools(emotionType, intensity)
        
        // Verify interactions
        verify(mockApiService).getToolRecommendations(emotionType, intensity)
        verify(mockToolMapper, times(2)).toTool(any())
        
        // Assert the result
        assertThat(result).containsExactlyElementsIn(testTools)
    }

    @Test
    fun testGetRecommendedTools_offline_fallback() = runTest {
        // Create test data
        val emotionType = TEST_EMOTION_TYPE
        val intensity = 7
        val testTools = listOf(
            createTestTool(), 
            createTestTool(id = "tool-2")
        )
        
        // Set up network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Set up mock responses
        `when`(mockToolDao.getToolsByEmotionType(emotionType)).thenReturn(flowOf(testTools))
        
        // Call the method under test
        val result = repository.getRecommendedTools(emotionType, intensity)
        
        // Verify interactions
        verify(mockApiService, never()).getToolRecommendations(anyString(), any())
        verify(mockToolDao).getToolsByEmotionType(emotionType)
        
        // Assert the result
        assertThat(result).containsExactlyElementsIn(testTools)
    }

    @Test
    fun testGetToolCategories_success() = runTest {
        // Create test data
        val testCategories = listOf(
            createTestToolCategory(), 
            createTestToolCategory(id = "category-2", name = "Another Category")
        )
        
        // Set up mock responses
        `when`(mockToolCategoryDao.getAllCategories()).thenReturn(flowOf(testCategories))
        
        // Call the method under test
        val result = repository.getToolCategories(forceRefresh = false)
        
        // Verify interactions
        verify(mockToolCategoryDao).getAllCategories()
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testCategories)
    }

    @Test
    fun testGetToolCategories_forceRefresh_success() = runTest {
        // Create test data
        val testCategories = listOf(
            createTestToolCategory(), 
            createTestToolCategory(id = "category-2", name = "Another Category")
        )
        val testCategoryDtos = listOf(
            createTestToolCategoryDto(), 
            createTestToolCategoryDto(id = "category-2", name = "Another Category")
        )
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<List<ToolCategoryDto>>
        val mockResponse = Response.success(testCategoryDtos)
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.getToolCategories()).thenReturn(mockCall)
        
        // Set up DAO mocks
        `when`(mockToolCategoryDao.insertCategories(anyList())).thenReturn(listOf(1L, 2L))
        `when`(mockToolCategoryDao.getAllCategories()).thenReturn(flowOf(testCategories))
        
        // Call the method under test
        val result = repository.getToolCategories(forceRefresh = true)
        
        // Verify interactions
        verify(mockApiService).getToolCategories()
        verify(mockToolCategoryDao).insertCategories(anyList())
        verify(mockToolCategoryDao).getAllCategories()
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testCategories)
    }

    @Test
    fun testGetCategoryById_success() = runTest {
        // Create test data
        val testCategory = createTestToolCategory()
        
        // Set up mock responses
        `when`(mockToolCategoryDao.getCategoryById(TEST_CATEGORY_ID)).thenReturn(flowOf(testCategory))
        
        // Call the method under test
        val result = repository.getCategoryById(TEST_CATEGORY_ID)
        
        // Verify interactions
        verify(mockToolCategoryDao).getCategoryById(TEST_CATEGORY_ID)
        
        // Assert the result
        assertThat(result.first()).isEqualTo(testCategory)
    }

    @Test
    fun testRefreshTools_success() = runTest {
        // Create test data
        val testToolDtos = listOf(
            createTestToolDto(), 
            createTestToolDto(id = "tool-2")
        )
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<List<ToolDto>>
        val mockResponse = Response.success(testToolDtos)
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.getToolsByCategory(null)).thenReturn(mockCall)
        
        // Set up DAO mocks
        `when`(mockToolDao.insertTools(anyList())).thenReturn(listOf(1L, 2L))
        
        // Call the method under test
        val result = repository.refreshTools()
        
        // Verify interactions
        verify(mockApiService).getToolsByCategory(null)
        verify(mockToolDao).insertTools(anyList())
        
        // Assert the result
        assertThat(result).isTrue()
    }

    @Test
    fun testRefreshTools_networkError() = runTest {
        // Set up network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Call the method under test
        val result = repository.refreshTools()
        
        // Verify interactions
        verify(mockApiService, never()).getToolsByCategory(any())
        
        // Assert the result
        assertThat(result).isFalse()
    }

    @Test
    fun testRefreshToolCategories_success() = runTest {
        // Create test data
        val testCategoryDtos = listOf(
            createTestToolCategoryDto(), 
            createTestToolCategoryDto(id = "category-2", name = "Another Category")
        )
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<List<ToolCategoryDto>>
        val mockResponse = Response.success(testCategoryDtos)
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.getToolCategories()).thenReturn(mockCall)
        
        // Set up DAO mocks
        `when`(mockToolCategoryDao.insertCategories(anyList())).thenReturn(listOf(1L, 2L))
        
        // Call the method under test
        val result = repository.refreshToolCategories()
        
        // Verify interactions
        verify(mockApiService).getToolCategories()
        verify(mockToolCategoryDao).insertCategories(anyList())
        
        // Assert the result
        assertThat(result).isTrue()
    }

    @Test
    fun testRefreshToolCategories_networkError() = runTest {
        // Set up network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Call the method under test
        val result = repository.refreshToolCategories()
        
        // Verify interactions
        verifyNoInteractions(mockApiService)
        
        // Assert the result
        assertThat(result).isFalse()
    }

    @Test
    fun testSyncFavorites_success() = runTest {
        // Create test data
        val testToolDtos = listOf(
            createTestToolDto(isFavorite = true), 
            createTestToolDto(id = "tool-2", isFavorite = true)
        )
        val testTools = listOf(
            createTestTool(id = TEST_TOOL_ID, isFavorite = false),
            createTestTool(id = "tool-2", isFavorite = false),
            createTestTool(id = "tool-3", isFavorite = true)
        )
        
        // Set up API call mock
        val mockCall = mock(Call::class.java) as Call<List<ToolDto>>
        val mockResponse = Response.success(testToolDtos)
        `when`(mockCall.execute()).thenReturn(mockResponse)
        `when`(mockApiService.getFavoriteTools()).thenReturn(mockCall)
        
        // Set up DAO mocks
        `when`(mockToolDao.getAllTools()).thenReturn(flowOf(testTools))
        `when`(mockToolDao.updateFavoriteStatus(anyString(), any())).thenReturn(1)
        
        // Call the method under test
        val result = repository.syncFavorites()
        
        // Verify interactions
        verify(mockApiService).getFavoriteTools()
        verify(mockToolDao).getAllTools()
        verify(mockToolDao, times(3)).updateFavoriteStatus(anyString(), any())
        
        // Assert the result
        assertThat(result).isTrue()
    }

    @Test
    fun testSyncFavorites_networkError() = runTest {
        // Set up network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Call the method under test
        val result = repository.syncFavorites()
        
        // Verify interactions
        verifyNoInteractions(mockApiService)
        
        // Assert the result
        assertThat(result).isFalse()
    }
}