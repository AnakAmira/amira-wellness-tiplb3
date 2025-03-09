package com.amirawellness.domain.usecases.emotional

import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.data.models.EmotionalInsight
import com.amirawellness.data.models.EmotionalTrend
import com.amirawellness.data.models.EmotionalTrendRequest
import com.amirawellness.data.models.EmotionalTrendResponse
import com.amirawellness.data.models.PeriodType
import com.amirawellness.data.repositories.EmotionalStateRepository
import kotlinx.coroutines.test.runTest
import org.junit.Assert.* // JUnit assertion methods //4.13.2
import org.junit.Before //JUnit annotation for setup methods //4.13.2
import org.junit.Test //JUnit annotation for test methods //4.13.2
import org.mockito.Mock //Mockito annotation for mock objects //4.0.0
import org.mockito.Mockito.* //Mockito methods for mocking //4.0.0
import org.mockito.MockitoAnnotations //Mockito utility for initializing annotations //4.0.0
import java.util.Calendar //For manipulating dates in tests //standard library
import java.util.Date //For creating test date ranges //standard library

/**
 * Test class for GetEmotionalTrendsUseCase that verifies emotional trend retrieval and processing
 */
class GetEmotionalTrendsUseCaseTest {

    @Mock
    lateinit var mockEmotionalStateRepository: EmotionalStateRepository

    private lateinit var getEmotionalTrendsUseCase: GetEmotionalTrendsUseCase

    private val testUserId = "testUserId"
    private val testStartDate: Date
    private val testEndDate: Date
    private val mockRepositoryResponse: Map<String, Any>
    private val expectedResponse: EmotionalTrendResponse

    init {
        // Initialize testUserId with a test user ID string
        // Initialize test dates for date range testing
        val calendar = Calendar.getInstance()
        testEndDate = calendar.time
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        testStartDate = calendar.time

        // Initialize mock repository response with trends and insights data
        val mockTrends = createMockTrendData()
        val mockInsights = createMockInsightData()
        mockRepositoryResponse = mapOf("trends" to mockTrends, "insights" to mockInsights)

        // Initialize expected response object with test data
        expectedResponse = EmotionalTrendResponse(emptyList(), emptyList())
    }

    /**
     * Sets up the test environment before each test
     */
    @Before
    fun setup() {
        // Initialize Mockito annotations with MockitoAnnotations.openMocks(this)
        MockitoAnnotations.openMocks(this)

        // Create GetEmotionalTrendsUseCase instance with mockEmotionalStateRepository
        getEmotionalTrendsUseCase = GetEmotionalTrendsUseCase(mockEmotionalStateRepository)
    }

    /**
     * Tests retrieving emotional trends with period type parameter
     */
    @Test
    fun testGetTrendsWithPeriodType() = runTest {
        // Arrange: Set up mockEmotionalStateRepository to return Result.success with mock data when getEmotionalTrends is called
        `when`(mockEmotionalStateRepository.getEmotionalTrends(anyString(), anyLong(), anyLong()))
            .thenReturn(Result.success(mockRepositoryResponse))

        // Act: Call getEmotionalTrendsUseCase with userId and PeriodType.WEEK using runTest
        val result = getEmotionalTrendsUseCase(testUserId, PeriodType.WEEK)

        // Assert: Verify the result is success and contains the expected trends and insights
        assertTrue(result.isSuccess)
        assertEquals(expectedResponse, result.getOrNull())

        // Assert: Verify mockEmotionalStateRepository.getEmotionalTrends was called exactly once with the correct parameters
        verify(mockEmotionalStateRepository, times(1)).getEmotionalTrends(
            eq(testUserId),
            anyLong(),
            anyLong()
        )
    }

    /**
     * Tests retrieving emotional trends with custom date range
     */
    @Test
    fun testGetTrendsWithDateRange() = runTest {
        // Arrange: Set up mockEmotionalStateRepository to return Result.success with mock data when getEmotionalTrends is called
        `when`(mockEmotionalStateRepository.getEmotionalTrends(anyString(), anyLong(), anyLong()))
            .thenReturn(Result.success(mockRepositoryResponse))

        // Act: Call getEmotionalTrendsUseCase with userId, startDate, and endDate using runTest
        val result = getEmotionalTrendsUseCase(testUserId, testStartDate, testEndDate)

        // Assert: Verify the result is success and contains the expected trends and insights
        assertTrue(result.isSuccess)
        assertEquals(expectedResponse, result.getOrNull())

        // Assert: Verify mockEmotionalStateRepository.getEmotionalTrends was called exactly once with the correct parameters
        verify(mockEmotionalStateRepository, times(1)).getEmotionalTrends(
            eq(testUserId),
            anyLong(),
            anyLong()
        )
    }

    /**
     * Tests retrieving emotional trends with emotion type filter
     */
    @Test
    fun testGetTrendsWithEmotionTypeFilter() = runTest {
        // Arrange: Set up mockEmotionalStateRepository to return Result.success with mock data when getEmotionalTrends is called
        `when`(mockEmotionalStateRepository.getEmotionalTrends(anyString(), anyLong(), anyLong()))
            .thenReturn(Result.success(mockRepositoryResponse))

        // Arrange: Create a list of emotion types to filter by (JOY, ANXIETY)
        val emotionTypes = listOf(EmotionType.JOY, EmotionType.ANXIETY)

        // Act: Call getEmotionalTrendsUseCase with userId, PeriodType.WEEK, and emotion types filter using runTest
        val result = getEmotionalTrendsUseCase(testUserId, PeriodType.WEEK, emotionTypes)

        // Assert: Verify the result is success and contains the expected trends and insights
        assertTrue(result.isSuccess)
        assertEquals(expectedResponse, result.getOrNull())

        // Assert: Verify mockEmotionalStateRepository.getEmotionalTrends was called exactly once with the correct parameters
        verify(mockEmotionalStateRepository, times(1)).getEmotionalTrends(
            eq(testUserId),
            anyLong(),
            anyLong()
        )
    }

    /**
     * Tests retrieving emotional trends with invalid date range (end date before start date)
     */
    @Test
    fun testInvalidDateRange() = runTest {
        // Arrange: Create invalid date range where endDate is before startDate
        val invalidStartDate = testEndDate
        val invalidEndDate = testStartDate

        // Act: Call getEmotionalTrendsUseCase with userId and invalid date range using runTest
        val result = getEmotionalTrendsUseCase(testUserId, invalidStartDate, invalidEndDate)

        // Assert: Verify the result is failure with InvalidRequestException
        assertTrue(result.isFailure)
        assertNotNull(result.exceptionOrNull())
        assertTrue(result.exceptionOrNull() is GetEmotionalTrendsUseCase.InvalidRequestException)

        // Assert: Verify mockEmotionalStateRepository.getEmotionalTrends was never called
        verify(mockEmotionalStateRepository, never()).getEmotionalTrends(anyString(), anyLong(), anyLong())
    }

    /**
     * Tests retrieving emotional trends when network is unavailable
     */
    @Test
    fun testNetworkUnavailable() = runTest {
        // Arrange: Set up mockEmotionalStateRepository to return Result.failure with NetworkUnavailableException when getEmotionalTrends is called
        `when`(mockEmotionalStateRepository.getEmotionalTrends(anyString(), anyLong(), anyLong()))
            .thenReturn(Result.failure(EmotionalStateRepository.NetworkUnavailableException("Network unavailable")))

        // Act: Call getEmotionalTrendsUseCase with userId and PeriodType.WEEK using runTest
        val result = getEmotionalTrendsUseCase(testUserId, PeriodType.WEEK)

        // Assert: Verify the result is failure with NetworkUnavailableException
        assertTrue(result.isFailure)
        assertNotNull(result.exceptionOrNull())
        assertTrue(result.exceptionOrNull() is EmotionalStateRepository.NetworkUnavailableException)

        // Assert: Verify mockEmotionalStateRepository.getEmotionalTrends was called exactly once with the correct parameters
        verify(mockEmotionalStateRepository, times(1)).getEmotionalTrends(
            eq(testUserId),
            anyLong(),
            anyLong()
        )
    }

    /**
     * Tests retrieving emotional trends when repository throws an exception
     */
    @Test
    fun testRepositoryError() = runTest {
        // Arrange: Set up mockEmotionalStateRepository to return Result.failure with RuntimeException when getEmotionalTrends is called
        `when`(mockEmotionalStateRepository.getEmotionalTrends(anyString(), anyLong(), anyLong()))
            .thenReturn(Result.failure(RuntimeException("Repository error")))

        // Act: Call getEmotionalTrendsUseCase with userId and PeriodType.WEEK using runTest
        val result = getEmotionalTrendsUseCase(testUserId, PeriodType.WEEK)

        // Assert: Verify the result is failure with RuntimeException
        assertTrue(result.isFailure)
        assertNotNull(result.exceptionOrNull())
        assertTrue(result.exceptionOrNull() is RuntimeException)

        // Assert: Verify mockEmotionalStateRepository.getEmotionalTrends was called exactly once with the correct parameters
        verify(mockEmotionalStateRepository, times(1)).getEmotionalTrends(
            eq(testUserId),
            anyLong(),
            anyLong()
        )
    }

    /**
     * Helper method to create mock trend data for testing
     */
    private fun createMockTrendData(): List<Map<String, Any>> {
        // Create a list of maps representing trend data
        val trendData = mutableListOf<Map<String, Any>>()

        // Add mock trend data for JOY emotion with data points, trend direction, and intensity values
        trendData.add(
            mapOf(
                "emotionType" to EmotionType.JOY,
                "dataPoints" to listOf(
                    mapOf("date" to Date(), "value" to 5, "context" to "Morning"),
                    mapOf("date" to Date(), "value" to 7, "context" to "Evening")
                ),
                "overallTrend" to "INCREASING",
                "averageIntensity" to 6.0,
                "peakIntensity" to 7.0,
                "peakDate" to Date(),
                "occurrenceCount" to 2
            )
        )

        // Add mock trend data for ANXIETY emotion with data points, trend direction, and intensity values
        trendData.add(
            mapOf(
                "emotionType" to EmotionType.ANXIETY,
                "dataPoints" to listOf(
                    mapOf("date" to Date(), "value" to 8, "context" to "Morning"),
                    mapOf("date" to Date(), "value" to 6, "context" to "Evening")
                ),
                "overallTrend" to "DECREASING",
                "averageIntensity" to 7.0,
                "peakIntensity" to 8.0,
                "peakDate" to Date(),
                "occurrenceCount" to 2
            )
        )

        // Return the list of mock trend data
        return trendData
    }

    /**
     * Helper method to create mock insight data for testing
     */
    private fun createMockInsightData(): List<Map<String, Any>> {
        // Create a list of maps representing insight data
        val insightData = mutableListOf<Map<String, Any>>()

        // Add mock insight data with type, description, related emotions, and confidence values
        insightData.add(
            mapOf(
                "type" to "Pattern",
                "description" to "You tend to feel more joyful in the evenings",
                "relatedEmotions" to listOf(EmotionType.JOY),
                "confidence" to 0.8
            )
        )

        // Return the list of mock insight data
        return insightData
    }
}