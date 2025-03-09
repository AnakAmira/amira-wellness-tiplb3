package com.amirawellness.data.repositories

import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.data.local.dao.EmotionalStateDao
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.dto.EmotionalStateDto
import com.amirawellness.services.sync.DataQueueManager
import com.amirawellness.services.sync.OperationType
import com.google.common.truth.Truth.assertThat
import com.google.gson.Gson // version: 2.9.0
import java.io.IOException
import java.util.Date
import java.util.UUID
import kotlinx.coroutines.ExperimentalCoroutinesApi // version: 1.6.4
import kotlinx.coroutines.flow.first // version: 1.6.4
import kotlinx.coroutines.flow.flowOf // version: 1.6.4
import kotlinx.coroutines.test.TestCoroutineDispatcher // version: 1.6.4
import kotlinx.coroutines.test.TestCoroutineScope // version: 1.6.4
import kotlinx.coroutines.test.runTest // version: 1.6.4
import org.junit.Before // version: 4.13.2
import org.junit.Rule // version: 4.13.2
import org.junit.Test // version: 4.13.2
import org.mockito.ArgumentMatchers // version: 4.0.0
import org.mockito.Mock // version: 4.0.0
import org.mockito.Mockito // version: 4.0.0

@ExperimentalCoroutinesApi
class EmotionalStateRepositoryTest {

    @Mock
    private lateinit var mockEmotionalStateDao: EmotionalStateDao

    @Mock
    private lateinit var mockApiService: ApiService

    @Mock
    private lateinit var mockNetworkMonitor: NetworkMonitor

    @Mock
    private lateinit var mockDataQueueManager: DataQueueManager

    private val testDispatcher = TestCoroutineDispatcher()
    private val testScope = TestCoroutineScope(testDispatcher)
    private lateinit var repository: EmotionalStateRepository
    private lateinit var gson: Gson

    @Before
    fun setup() {
        MockitoAnnotations.initMocks(this)
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        gson = Gson()
        repository = EmotionalStateRepository(
            mockEmotionalStateDao,
            mockApiService,
            mockNetworkMonitor,
            mockDataQueueManager
        )
    }

    @Test
    fun testRecordEmotionalState_success() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = null,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        val testEmotionalStateDto = createTestEmotionalStateDto(
            id = null,
            emotionType = EmotionType.JOY.name,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockEmotionalStateDao.insertEmotionalState(ArgumentMatchers.any()))
            .thenReturn(1L)
        Mockito.`when`(mockApiService.recordEmotionalState(ArgumentMatchers.any()))
            .thenReturn(Response.success(testEmotionalStateDto))
        Mockito.`when`(mockEmotionalStateDao.updateEmotionalState(ArgumentMatchers.any()))
            .thenReturn(1)

        val result = repository.recordEmotionalState(testEmotionalState)

        Mockito.verify(mockEmotionalStateDao).insertEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockApiService).recordEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockEmotionalStateDao).updateEmotionalState(ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()?.emotionType).isEqualTo(EmotionType.JOY)
    }

    @Test
    fun testRecordEmotionalState_offline() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = null,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        Mockito.`when`(mockEmotionalStateDao.insertEmotionalState(ArgumentMatchers.any()))
            .thenReturn(1L)
        Mockito.`when`(mockDataQueueManager.enqueueOperation(ArgumentMatchers.any()))
            .thenReturn(Result.success(1L))

        val result = repository.recordEmotionalState(testEmotionalState)

        Mockito.verify(mockEmotionalStateDao).insertEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockApiService, Mockito.never()).recordEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockDataQueueManager).enqueueOperation(ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()?.emotionType).isEqualTo(EmotionType.JOY)
    }

    @Test
    fun testRecordEmotionalState_apiError() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = null,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockEmotionalStateDao.insertEmotionalState(ArgumentMatchers.any()))
            .thenReturn(1L)
        Mockito.`when`(mockApiService.recordEmotionalState(ArgumentMatchers.any()))
            .thenReturn(Response.error(500, Mockito.mock(ResponseBody::class.java)))
        Mockito.`when`(mockDataQueueManager.enqueueOperation(ArgumentMatchers.any()))
            .thenReturn(Result.success(1L))

        val result = repository.recordEmotionalState(testEmotionalState)

        Mockito.verify(mockEmotionalStateDao).insertEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockApiService).recordEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockDataQueueManager).enqueueOperation(ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()?.emotionType).isEqualTo(EmotionType.JOY)
    }

    @Test
    fun testGetEmotionalStateById() = runTest {
        val testId = UUID.randomUUID().toString()
        val testEmotionalState = createTestEmotionalState(
            id = testId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStateById(testId))
            .thenReturn(flowOf(testEmotionalState))

        val result = repository.getEmotionalStateById(testId).first()

        Mockito.verify(mockEmotionalStateDao).getEmotionalStateById(testId)
        assertThat(result).isEqualTo(testEmotionalState)
    }

    @Test
    fun testGetEmotionalStatesByUserId() = runTest {
        val testUserId = "user123"
        val testEmotionalStates = listOf(
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.JOY,
                intensity = 7,
                context = EmotionContext.STANDALONE.name,
                relatedJournalId = null,
                relatedToolId = null
            ),
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.SADNESS,
                intensity = 3,
                context = EmotionContext.POST_JOURNALING.name,
                relatedJournalId = null,
                relatedToolId = null
            )
        )
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStatesByUserId(testUserId))
            .thenReturn(flowOf(testEmotionalStates))

        val result = repository.getEmotionalStatesByUserId(testUserId).first()

        Mockito.verify(mockEmotionalStateDao).getEmotionalStatesByUserId(testUserId)
        assertThat(result).isEqualTo(testEmotionalStates)
    }

    @Test
    fun testGetEmotionalStatesByJournalId() = runTest {
        val testJournalId = "journal123"
        val testEmotionalStates = listOf(
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.JOY,
                intensity = 7,
                context = EmotionContext.PRE_JOURNALING.name,
                relatedJournalId = testJournalId,
                relatedToolId = null
            ),
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.SADNESS,
                intensity = 3,
                context = EmotionContext.POST_JOURNALING.name,
                relatedJournalId = testJournalId,
                relatedToolId = null
            )
        )
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStatesByJournalId(testJournalId))
            .thenReturn(flowOf(testEmotionalStates))

        val result = repository.getEmotionalStatesByJournalId(testJournalId).first()

        Mockito.verify(mockEmotionalStateDao).getEmotionalStatesByJournalId(testJournalId)
        assertThat(result).isEqualTo(testEmotionalStates)
    }

    @Test
    fun testGetEmotionalStatesByToolId() = runTest {
        val testToolId = "tool123"
        val testEmotionalStates = listOf(
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.JOY,
                intensity = 7,
                context = EmotionContext.TOOL_USAGE.name,
                relatedJournalId = null,
                relatedToolId = testToolId
            ),
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.SADNESS,
                intensity = 3,
                context = EmotionContext.TOOL_USAGE.name,
                relatedJournalId = null,
                relatedToolId = testToolId
            )
        )
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStatesByToolId(testToolId))
            .thenReturn(flowOf(testEmotionalStates))

        val result = repository.getEmotionalStatesByToolId(testToolId).first()

        Mockito.verify(mockEmotionalStateDao).getEmotionalStatesByToolId(testToolId)
        assertThat(result).isEqualTo(testEmotionalStates)
    }

    @Test
    fun testGetEmotionalStatesByContext() = runTest {
        val testUserId = "user123"
        val testContext = EmotionContext.STANDALONE.name
        val testEmotionalStates = listOf(
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.JOY,
                intensity = 7,
                context = testContext,
                relatedJournalId = null,
                relatedToolId = null
            ),
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.SADNESS,
                intensity = 3,
                context = testContext,
                relatedJournalId = null,
                relatedToolId = null
            )
        )
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStatesByContext(testUserId, testContext))
            .thenReturn(flowOf(testEmotionalStates))

        val result = repository.getEmotionalStatesByContext(testUserId, testContext).first()

        Mockito.verify(mockEmotionalStateDao).getEmotionalStatesByContext(testUserId, testContext)
        assertThat(result).isEqualTo(testEmotionalStates)
    }

    @Test
    fun testGetEmotionalStatesByDateRange() = runTest {
        val testUserId = "user123"
        val startDate = Date().time - 86400000 // Yesterday
        val endDate = Date().time
        val testEmotionalStates = listOf(
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.JOY,
                intensity = 7,
                context = EmotionContext.STANDALONE.name,
                relatedJournalId = null,
                relatedToolId = null
            ),
            createTestEmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = EmotionType.SADNESS,
                intensity = 3,
                context = EmotionContext.STANDALONE.name,
                relatedJournalId = null,
                relatedToolId = null
            )
        )
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStatesByDateRange(testUserId, startDate, endDate))
            .thenReturn(flowOf(testEmotionalStates))

        val result = repository.getEmotionalStatesByDateRange(testUserId, startDate, endDate).first()

        Mockito.verify(mockEmotionalStateDao).getEmotionalStatesByDateRange(testUserId, startDate, endDate)
        assertThat(result).isEqualTo(testEmotionalStates)
    }

    @Test
    fun testGetEmotionalTrends_online() = runTest {
        val testUserId = "user123"
        val startDate = Date().time - 86400000 // Yesterday
        val endDate = Date().time
        val testTrendData = mapOf("trend1" to 1.0, "trend2" to 2.0)
        Mockito.`when`(mockApiService.getEmotionalTrends(startDate.toString(), endDate.toString()))
            .thenReturn(Response.success(testTrendData))

        val result = repository.getEmotionalTrends(testUserId, startDate, endDate)

        Mockito.verify(mockApiService).getEmotionalTrends(startDate.toString(), endDate.toString())
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(testTrendData)
    }

    @Test
    fun testGetEmotionalTrends_offline() = runTest {
        val testUserId = "user123"
        val startDate = Date().time - 86400000 // Yesterday
        val endDate = Date().time
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStatesByDateRange(testUserId, startDate, endDate))
            .thenReturn(flowOf(emptyList()))
        Mockito.`when`(mockEmotionalStateDao.getEmotionTypeFrequency(testUserId))
            .thenReturn(flowOf(emptyMap()))

        val result = repository.getEmotionalTrends(testUserId, startDate, endDate)

        Mockito.verify(mockApiService, Mockito.never()).getEmotionalTrends(ArgumentMatchers.any(), ArgumentMatchers.any())
        Mockito.verify(mockEmotionalStateDao).getEmotionalStatesByDateRange(testUserId, startDate, endDate)
        Mockito.verify(mockEmotionalStateDao).getEmotionTypeFrequency(testUserId)
        assertThat(result.isSuccess).isTrue()
    }

    @Test
    fun testGetEmotionalInsights_online() = runTest {
        val testUserId = "user123"
        val testInsightData = mapOf("insight1" to "value1", "insight2" to "value2")
        Mockito.`when`(mockApiService.getEmotionalInsights())
            .thenReturn(Response.success(testInsightData))

        val result = repository.getEmotionalInsights(testUserId)

        Mockito.verify(mockApiService).getEmotionalInsights()
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(testInsightData)
    }

    @Test
    fun testGetEmotionalInsights_offline() = runTest {
        val testUserId = "user123"
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        Mockito.`when`(mockEmotionalStateDao.getMostFrequentEmotionType(testUserId))
            .thenReturn(flowOf("JOY"))
        Mockito.`when`(mockEmotionalStateDao.getAverageIntensityByEmotionType(testUserId))
            .thenReturn(flowOf(emptyMap()))

        val result = repository.getEmotionalInsights(testUserId)

        Mockito.verify(mockApiService, Mockito.never()).getEmotionalInsights()
        Mockito.verify(mockEmotionalStateDao).getMostFrequentEmotionType(testUserId)
        Mockito.verify(mockEmotionalStateDao).getAverageIntensityByEmotionType(testUserId)
        assertThat(result.isSuccess).isTrue()
    }

    @Test
    fun testGetToolRecommendations_online() = runTest {
        val testEmotionType = "JOY"
        val testIntensity = 7
        val testToolIds = listOf("tool1", "tool2")
        val testToolDtos = testToolIds.map {
            ToolDto(
                id = it,
                name = "Tool $it",
                description = "Description for Tool $it",
                category = ToolCategoryDto("cat1", "Category 1", "Desc", null, 1),
                contentType = "TEXT",
                content = ToolContentDto("Title", "Instructions", null, null, null),
                isFavorite = false,
                usageCount = 0,
                targetEmotions = listOf(testEmotionType),
                estimatedDuration = 5
            )
        }
        Mockito.`when`(mockApiService.getToolRecommendations(testEmotionType, testIntensity))
            .thenReturn(Response.success(testToolDtos))

        val result = repository.getToolRecommendations(testEmotionType, testIntensity)

        Mockito.verify(mockApiService).getToolRecommendations(testEmotionType, testIntensity)
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(testToolIds)
    }

    @Test
    fun testGetToolRecommendations_offline() = runTest {
        val testEmotionType = "JOY"
        val testIntensity = 7
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)

        val result = repository.getToolRecommendations(testEmotionType, testIntensity)

        Mockito.verify(mockApiService, Mockito.never()).getToolRecommendations(ArgumentMatchers.any(), ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(emptyList<String>())
    }

    @Test
    fun testSyncEmotionalState_success() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = null,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        val testEmotionalStateDto = createTestEmotionalStateDto(
            id = "remote-id",
            emotionType = EmotionType.JOY.name,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockApiService.recordEmotionalState(ArgumentMatchers.any()))
            .thenReturn(Response.success(testEmotionalStateDto))
        Mockito.`when`(mockEmotionalStateDao.updateEmotionalState(ArgumentMatchers.any()))
            .thenReturn(1)

        val result = repository.syncEmotionalState(testEmotionalState)

        Mockito.verify(mockApiService).recordEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockEmotionalStateDao).updateEmotionalState(ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()?.id).isEqualTo("remote-id")
    }

    @Test
    fun testSyncEmotionalState_apiError() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = null,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockApiService.recordEmotionalState(ArgumentMatchers.any()))
            .thenReturn(Response.error(500, Mockito.mock(ResponseBody::class.java)))

        val result = repository.syncEmotionalState(testEmotionalState)

        Mockito.verify(mockApiService).recordEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockEmotionalStateDao, Mockito.never()).updateEmotionalState(ArgumentMatchers.any())
        assertThat(result.isFailure).isTrue()
    }

    @Test
    fun testSyncEmotionalStates_success() = runTest {
        val testUserId = "user123"
        val testEmotionalStates = listOf(
            createTestEmotionalState(
                id = null,
                emotionType = EmotionType.JOY,
                intensity = 7,
                context = EmotionContext.STANDALONE.name,
                relatedJournalId = null,
                relatedToolId = null
            ),
            createTestEmotionalState(
                id = null,
                emotionType = EmotionType.SADNESS,
                intensity = 3,
                context = EmotionContext.POST_JOURNALING.name,
                relatedJournalId = null,
                relatedToolId = null
            )
        )
        Mockito.`when`(mockEmotionalStateDao.getEmotionalStatesByUserId(testUserId))
            .thenReturn(flowOf(testEmotionalStates))
        Mockito.`when`(repository.syncEmotionalState(ArgumentMatchers.any()))
            .thenReturn(Result.success(testEmotionalStates[0]))

        val result = repository.syncEmotionalStates(testUserId)

        Mockito.verify(mockEmotionalStateDao).getEmotionalStatesByUserId(testUserId)
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(0)
    }

    @Test
    fun testSyncEmotionalStates_networkUnavailable() = runTest {
        val testUserId = "user123"
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)

        val result = repository.syncEmotionalStates(testUserId)

        Mockito.verify(mockEmotionalStateDao, Mockito.never()).getEmotionalStatesByUserId(ArgumentMatchers.any())
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(EmotionalStateRepository.NetworkUnavailableException::class.java)
    }

    @Test
    fun testDeleteEmotionalState_success() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = "remote-id",
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockEmotionalStateDao.deleteEmotionalState(ArgumentMatchers.any()))
            .thenReturn(1)
        Mockito.`when`(mockApiService.deleteEmotionalState(ArgumentMatchers.any()))
            .thenReturn(Response.success(null))

        val result = repository.deleteEmotionalState(testEmotionalState)

        Mockito.verify(mockEmotionalStateDao).deleteEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockApiService).deleteEmotionalState(ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
    }

    @Test
    fun testDeleteEmotionalState_offline() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = "remote-id",
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        Mockito.`when`(mockEmotionalStateDao.deleteEmotionalState(ArgumentMatchers.any()))
            .thenReturn(1)
        Mockito.`when`(mockDataQueueManager.enqueueOperation(ArgumentMatchers.any()))
            .thenReturn(Result.success(1L))

        val result = repository.deleteEmotionalState(testEmotionalState)

        Mockito.verify(mockEmotionalStateDao).deleteEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockApiService, Mockito.never()).deleteEmotionalState(ArgumentMatchers.any())
        Mockito.verify(mockDataQueueManager).enqueueOperation(ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
    }

    @Test
    fun testDeleteEmotionalStatesByJournalId() = runTest {
        val testJournalId = "journal123"
        Mockito.`when`(mockEmotionalStateDao.deleteEmotionalStatesByJournalId(testJournalId))
            .thenReturn(2)

        val result = repository.deleteEmotionalStatesByJournalId(testJournalId)

        Mockito.verify(mockEmotionalStateDao).deleteEmotionalStatesByJournalId(testJournalId)
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(2)
    }

    @Test
    fun testQueueEmotionalStateSync() = runTest {
        val testEmotionalState = createTestEmotionalState(
            id = null,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.name,
            relatedJournalId = null,
            relatedToolId = null
        )
        Mockito.`when`(mockDataQueueManager.enqueueOperation(ArgumentMatchers.any()))
            .thenReturn(Result.success(1L))

        val result = repository.queueEmotionalStateSync(testEmotionalState)

        Mockito.verify(mockDataQueueManager).enqueueOperation(ArgumentMatchers.any())
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(1L)
    }

    @Test
    fun testProcessQueuedEmotionalStates_success() = runTest {
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        Mockito.`when`(mockDataQueueManager.processQueue())
            .thenReturn(Result.success(2))

        val result = repository.processQueuedEmotionalStates()

        Mockito.verify(mockDataQueueManager).processQueue()
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(2)
    }

    @Test
    fun testProcessQueuedEmotionalStates_networkUnavailable() = runTest {
        Mockito.`when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)

        val result = repository.processQueuedEmotionalStates()

        Mockito.verify(mockDataQueueManager, Mockito.never()).processQueue()
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(EmotionalStateRepository.NetworkUnavailableException::class.java)
    }

    private fun createTestEmotionalState(
        id: String?,
        emotionType: EmotionType,
        intensity: Int,
        context: String,
        relatedJournalId: String?,
        relatedToolId: String?
    ): EmotionalState {
        val uuid = id?.let { UUID.fromString(it) } ?: UUID.randomUUID()
        val createdAt = Date().time
        return EmotionalState(
            id = uuid.toString(),
            emotionType = emotionType,
            intensity = intensity,
            context = context,
            notes = "Test notes",
            createdAt = createdAt,
            relatedJournalId = relatedJournalId,
            relatedToolId = relatedToolId
        )
    }

    private fun createTestEmotionalStateDto(
        id: String?,
        emotionType: String,
        intensity: Int,
        context: String,
        relatedJournalId: String?,
        relatedToolId: String?
    ): EmotionalStateDto {
        val createdAt = Date().toString()
        return EmotionalStateDto(
            id = id,
            emotionType = emotionType,
            intensity = intensity,
            context = context,
            notes = "Test notes",
            createdAt = createdAt,
            relatedJournalId = relatedJournalId,
            relatedToolId = relatedToolId
        )
    }
}