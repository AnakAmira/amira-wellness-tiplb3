package com.amirawellness.ui.screens.progress

import androidx.arch.core.executor.testing.InstantTaskExecutorRule // androidx.arch.core:core-testing:2.2.0
import com.amirawellness.core.constants.AppConstants.EmotionType // Defined in the project
import com.amirawellness.data.models.Achievement // Defined in the project
import com.amirawellness.data.models.AchievementCategory // Defined in the project
import com.amirawellness.data.models.AchievementType // Defined in the project
import com.amirawellness.data.models.DailyActivity // Defined in the project
import com.amirawellness.data.models.EmotionalTrend // Defined in the project
import com.amirawellness.data.models.PeriodType // Defined in the project
import com.amirawellness.data.models.StreakInfo // Defined in the project
import com.amirawellness.data.models.TrendDataPoint // Defined in the project
import com.amirawellness.data.models.TrendDirection // Defined in the project
import com.amirawellness.domain.usecases.emotional.GetEmotionalTrendsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetAchievementsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetProgressInsightsUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetStreakInfoUseCase // Defined in the project
import com.amirawellness.domain.usecases.progress.GetUsageStatisticsUseCase // Defined in the project
import kotlinx.coroutines.ExperimentalCoroutinesApi // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines:kotlinx-coroutines-core:1.7.3
import kotlinx.coroutines.flow.first // kotlinx.coroutines:kotlinx-coroutines-core:1.7.3
import kotlinx.coroutines.flow.flowOf // kotlinx.coroutines:kotlinx-coroutines-core:1.7.3
import kotlinx.coroutines.test.StandardTestDispatcher // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import kotlinx.coroutines.test.TestScope // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import kotlinx.coroutines.test.runTest // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import org.junit.Assert.assertEquals // junit:junit:4.13.2
import org.junit.Before // junit:junit:4.13.2
import org.junit.Rule // junit:junit:4.13.2
import org.junit.Test // junit:junit:4.13.2
import org.mockito.kotlin.any // org.mockito.kotlin:mockito-kotlin:5.1.0
import org.mockito.kotlin.mock // org.mockito.kotlin:mockito-kotlin:5.1.0
import org.mockito.kotlin.verify // org.mockito.kotlin:mockito-kotlin:5.1.0
import org.mockito.kotlin.whenever // org.mockito.kotlin:mockito-kotlin:5.1.0
import java.util.Date // java.util:java.util:standard library
import java.util.UUID // java.util:java.util:standard library

private const val TEST_USER_ID = "test-user-123"

/**
 * Test class for ProgressDashboardViewModel
 */
@ExperimentalCoroutinesApi
class ProgressDashboardViewModelTest {

    private lateinit var mockGetStreakInfoUseCase: GetStreakInfoUseCase
    private lateinit var mockGetAchievementsUseCase: GetAchievementsUseCase
    private lateinit var mockGetEmotionalTrendsUseCase: GetEmotionalTrendsUseCase
    private lateinit var mockGetProgressInsightsUseCase: GetProgressInsightsUseCase
    private lateinit var mockGetUsageStatisticsUseCase: GetUsageStatisticsUseCase
    private lateinit var viewModel: ProgressDashboardViewModel
    private lateinit var testScope: TestScope
    private lateinit var testDispatcher: StandardTestDispatcher

    /**
     * JUnit rule for Architecture Components
     */
    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    /**
     * Setup method to initialize test dependencies
     */
    @Before
    fun setup() {
        testDispatcher = StandardTestDispatcher()
        testScope = TestScope(testDispatcher)
        mockGetStreakInfoUseCase = mock()
        mockGetAchievementsUseCase = mock()
        mockGetEmotionalTrendsUseCase = mock()
        mockGetProgressInsightsUseCase = mock()
        mockGetUsageStatisticsUseCase = mock()
        viewModel = ProgressDashboardViewModel(
            mockGetStreakInfoUseCase,
            mockGetAchievementsUseCase,
            mockGetEmotionalTrendsUseCase,
            mockGetProgressInsightsUseCase,
            mockGetUsageStatisticsUseCase
        )
    }

    /**
     * Test that the initial UI state is Loading
     */
    @Test
    fun testInitialState_isLoading() {
        val initialState = viewModel.uiState.value
        assertEquals(ProgressUiState.Loading, initialState)
    }

    /**
     * Test that the initial period type is WEEK
     */
    @Test
    fun testInitialPeriodType_isWeek() = runTest {
        val initialPeriodType = viewModel.selectedPeriod.first()
        assertEquals(PeriodType.WEEK, initialPeriodType)
    }

    /**
     * Test that loadProgressData updates state with data on success
     */
    @Test
    fun testLoadProgressData_success_updatesStateWithData() = runTest {
        val testStreakInfo = createTestStreakInfo()
        val testAchievements = createTestAchievements()
        val testEmotionalTrends = createTestEmotionalTrends()
        val testInsights = createTestInsights()
        val testUsageStatistics = createTestUsageStatistics()

        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(testStreakInfo))
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(testEmotionalTrends)))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(testInsights))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(testUsageStatistics))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        val finalState = viewModel.uiState.value
        assert(finalState is ProgressUiState.Success)
        finalState as ProgressUiState.Success
        assertEquals(testStreakInfo, finalState.data.streakInfo)
        assertEquals(testAchievements, finalState.data.achievements)
        assertEquals(testEmotionalTrends, finalState.data.emotionalTrends)
        assertEquals(testInsights, finalState.data.insights)
        assertEquals(testUsageStatistics, finalState.data.usageStatistics)

        verify(mockGetStreakInfoUseCase).invoke()
        verify(mockGetAchievementsUseCase).invoke()
        verify(mockGetEmotionalTrendsUseCase).invoke(any(), any())
        verify(mockGetProgressInsightsUseCase).invoke()
        verify(mockGetUsageStatisticsUseCase).invoke(any())
    }

    /**
     * Test that loadProgressData updates state with error when a use case fails
     */
    @Test
    fun testLoadProgressData_error_updatesStateWithError() = runTest {
        val testException = Exception("Test error")
        whenever(mockGetStreakInfoUseCase()).thenThrow(testException)
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(emptyList()))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(emptyList())))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(emptyMap()))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(emptyMap()))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        val finalState = viewModel.uiState.value
        assert(finalState is ProgressUiState.Error)
        finalState as ProgressUiState.Error
        assertEquals(testException.message ?: "Unknown error", finalState.message)
    }

    /**
     * Test that refreshData reloads all progress data
     */
    @Test
    fun testRefreshData_reloadsData() = runTest {
        val testStreakInfo1 = createTestStreakInfo()
        val testAchievements1 = createTestAchievements()
        val testEmotionalTrends1 = createTestEmotionalTrends()
        val testInsights1 = createTestInsights()
        val testUsageStatistics1 = createTestUsageStatistics()

        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(testStreakInfo1))
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements1))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(testEmotionalTrends1)))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(testInsights1))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(testUsageStatistics1))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        verify(mockGetStreakInfoUseCase).invoke()
        verify(mockGetAchievementsUseCase).invoke()
        verify(mockGetEmotionalTrendsUseCase).invoke(any(), any())
        verify(mockGetProgressInsightsUseCase).invoke()
        verify(mockGetUsageStatisticsUseCase).invoke(any())

        val testStreakInfo2 = createTestStreakInfo()
        val testAchievements2 = createTestAchievements()
        val testEmotionalTrends2 = createTestEmotionalTrends()
        val testInsights2 = createTestInsights()
        val testUsageStatistics2 = createTestUsageStatistics()

        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(testStreakInfo2))
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements2))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(testEmotionalTrends2)))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(testInsights2))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(testUsageStatistics2))

        viewModel.refreshData()
        testDispatcher.scheduler.advanceUntilIdle()

        val finalState = viewModel.uiState.value
        assert(finalState is ProgressUiState.Success)
        finalState as ProgressUiState.Success
        assertEquals(testStreakInfo2, finalState.data.streakInfo)
        assertEquals(testAchievements2, finalState.data.achievements)
        assertEquals(testEmotionalTrends2, finalState.data.emotionalTrends)
        assertEquals(testInsights2, finalState.data.insights)
        assertEquals(testUsageStatistics2, finalState.data.usageStatistics)

        verify(mockGetStreakInfoUseCase, times(2)).invoke()
        verify(mockGetAchievementsUseCase, times(2)).invoke()
        verify(mockGetEmotionalTrendsUseCase, times(2)).invoke(any(), any())
        verify(mockGetProgressInsightsUseCase, times(2)).invoke()
        verify(mockGetUsageStatisticsUseCase, times(2)).invoke(any())
    }

    /**
     * Test that setPeriodType updates the selected period and reloads data
     */
    @Test
    fun testSetPeriodType_updatesSelectedPeriodAndReloadsData() = runTest {
        val testStreakInfo1 = createTestStreakInfo()
        val testAchievements1 = createTestAchievements()
        val testEmotionalTrends1 = createTestEmotionalTrends()
        val testInsights1 = createTestInsights()
        val testUsageStatistics1 = createTestUsageStatistics()

        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(testStreakInfo1))
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements1))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(testEmotionalTrends1)))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(testInsights1))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(testUsageStatistics1))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        val testStreakInfo2 = createTestStreakInfo()
        val testAchievements2 = createTestAchievements()
        val testEmotionalTrends2 = createTestEmotionalTrends()
        val testInsights2 = createTestInsights()
        val testUsageStatistics2 = createTestUsageStatistics()

        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(testStreakInfo2))
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements2))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(testEmotionalTrends2)))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(testInsights2))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(testUsageStatistics2))

        viewModel.setPeriodType(PeriodType.MONTH)
        testDispatcher.scheduler.advanceUntilIdle()

        val updatedPeriodType = viewModel.selectedPeriod.first()
        assertEquals(PeriodType.MONTH, updatedPeriodType)

        val finalState = viewModel.uiState.value
        assert(finalState is ProgressUiState.Success)
        finalState as ProgressUiState.Success
        assertEquals(testStreakInfo2, finalState.data.streakInfo)
        assertEquals(testAchievements2, finalState.data.achievements)
        assertEquals(testEmotionalTrends2, finalState.data.emotionalTrends)
        assertEquals(testInsights2, finalState.data.insights)
        assertEquals(testUsageStatistics2, finalState.data.usageStatistics)

        verify(mockGetEmotionalTrendsUseCase).invoke(any(), eq(PeriodType.MONTH))
    }

    /**
     * Test that getFilteredAchievements returns achievements for the specified category
     */
    @Test
    fun testGetFilteredAchievements_returnsAchievementsForCategory() = runTest {
        val testAchievements = createTestAchievements()
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements))
        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(createTestStreakInfo()))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(emptyList())))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(emptyMap()))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(emptyMap()))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        val streakAchievements = viewModel.getFilteredAchievements(AchievementCategory.STREAK)
        assertEquals(2, streakAchievements.size)
        streakAchievements.forEach {
            assertEquals(AchievementCategory.STREAK, it.category)
        }

        val journalingAchievements = viewModel.getFilteredAchievements(AchievementCategory.JOURNALING)
        assertEquals(1, journalingAchievements.size)
        journalingAchievements.forEach {
            assertEquals(AchievementCategory.JOURNALING, it.category)
        }
    }

    /**
     * Test that getFilteredAchievements returns an empty list when in error state
     */
    @Test
    fun testGetFilteredAchievements_withErrorState_returnsEmptyList() = runTest {
        val testException = Exception("Test error")
        whenever(mockGetStreakInfoUseCase()).thenThrow(testException)
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(emptyList()))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(emptyList())))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(emptyMap()))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(emptyMap()))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        val filteredAchievements = viewModel.getFilteredAchievements(AchievementCategory.STREAK)
        assertEquals(0, filteredAchievements.size)
    }

    /**
     * Test that getEarnedAchievements returns only earned achievements
     */
    @Test
    fun testGetEarnedAchievements_returnsOnlyEarnedAchievements() = runTest {
        val testAchievements = createTestAchievements()
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements))
        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(createTestStreakInfo()))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(emptyList())))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(emptyMap()))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(emptyMap()))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        val earnedAchievements = viewModel.getEarnedAchievements()
        assertEquals(1, earnedAchievements.size)
        earnedAchievements.forEach {
            assert(it.isEarned())
        }
    }

    /**
     * Test that getInProgressAchievements returns only in-progress achievements
     */
    @Test
    fun testGetInProgressAchievements_returnsOnlyInProgressAchievements() = runTest {
        val testAchievements = createTestAchievements()
        whenever(mockGetAchievementsUseCase()).thenReturn(flowOf(testAchievements))
        whenever(mockGetStreakInfoUseCase()).thenReturn(flowOf(createTestStreakInfo()))
        whenever(mockGetEmotionalTrendsUseCase(any(), any())).thenReturn(flowOf(Result.success(emptyList())))
        whenever(mockGetProgressInsightsUseCase()).thenReturn(flowOf(emptyMap()))
        whenever(mockGetUsageStatisticsUseCase(any())).thenReturn(flowOf(emptyMap()))

        viewModel.loadProgressData()
        testDispatcher.scheduler.advanceUntilIdle()

        val inProgressAchievements = viewModel.getInProgressAchievements()
        assertEquals(1, inProgressAchievements.size)
        inProgressAchievements.forEach {
            assert(!it.isEarned())
            assert(it.progress > 0.0)
        }
    }

    /**
     * Helper method to create test streak info
     */
    private fun createTestStreakInfo(): StreakInfo {
        val streakHistory = listOf(
            DailyActivity(date = Date(), isActive = true, activities = listOf(ActivityType.VOICE_JOURNAL)),
            DailyActivity(date = Date(), isActive = true, activities = listOf(ActivityType.EMOTIONAL_CHECK_IN)),
            DailyActivity(date = Date(), isActive = true, activities = listOf(ActivityType.TOOL_USAGE))
        )

        return StreakInfo(
            currentStreak = 5,
            longestStreak = 7,
            totalDaysActive = 15,
            lastActiveDate = Date(),
            nextMilestone = 7,
            progressToNextMilestone = 0.7f,
            streakHistory = streakHistory
        )
    }

    /**
     * Helper method to create test achievements
     */
    private fun createTestAchievements(): List<Achievement> {
        return listOf(
            Achievement(
                id = UUID.randomUUID().toString(),
                type = AchievementType.STREAK_3_DAYS,
                category = AchievementCategory.STREAK,
                title = "Streak 3 Days",
                description = "Maintain a 3-day streak",
                iconUrl = "url1",
                points = 10,
                isHidden = false,
                earnedAt = Date(),
                progress = 1.0,
                metadata = null
            ),
            Achievement(
                id = UUID.randomUUID().toString(),
                type = AchievementType.JOURNAL_MASTER,
                category = AchievementCategory.JOURNALING,
                title = "Journal Master",
                description = "Create 10 journal entries",
                iconUrl = "url2",
                points = 20,
                isHidden = false,
                earnedAt = null,
                progress = 0.5,
                metadata = null
            ),
            Achievement(
                id = UUID.randomUUID().toString(),
                type = AchievementType.STREAK_7_DAYS,
                category = AchievementCategory.STREAK,
                title = "Streak 7 Days",
                description = "Maintain a 7-day streak",
                iconUrl = "url3",
                points = 15,
                isHidden = false,
                earnedAt = null,
                progress = 0.0,
                metadata = null
            )
        )
    }

    /**
     * Helper method to create test emotional trends
     */
    private fun createTestEmotionalTrends(): List<EmotionalTrend> {
        return listOf(
            EmotionalTrend(
                emotionType = EmotionType.JOY,
                dataPoints = listOf(
                    TrendDataPoint(date = Date(), value = 7),
                    TrendDataPoint(date = Date(), value = 8)
                ),
                overallTrend = TrendDirection.INCREASING,
                averageIntensity = 7.5,
                peakIntensity = 9.0,
                peakDate = Date(),
                occurrenceCount = 10
            ),
            EmotionalTrend(
                emotionType = EmotionType.SADNESS,
                dataPoints = listOf(
                    TrendDataPoint(date = Date(), value = 3),
                    TrendDataPoint(date = Date(), value = 2)
                ),
                overallTrend = TrendDirection.DECREASING,
                averageIntensity = 2.5,
                peakIntensity = 4.0,
                peakDate = Date(),
                occurrenceCount = 5
            )
        )
    }

    /**
     * Helper method to create test emotional insights
     */
    private fun createTestInsights(): Map<String, Any> {
        return mapOf(
            "insight1" to "You tend to feel more joyful in the mornings",
            "insight2" to "Breathing exercises help reduce anxiety"
        )
    }

    /**
     * Helper method to create test usage statistics
     */
    private fun createTestUsageStatistics(): Map<String, Any> {
        return mapOf(
            "totalJournalEntries" to 25,
            "totalCheckIns" to 50,
            "totalToolUsage" to 100
        )
    }
}