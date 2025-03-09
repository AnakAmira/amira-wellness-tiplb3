package com.amirawellness.data.repositories

import com.amirawellness.data.local.dao.AchievementDao
import com.amirawellness.data.local.dao.StreakDao
import com.amirawellness.data.models.*
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.dto.AchievementDto
import com.amirawellness.data.remote.dto.StreakDto
import com.amirawellness.data.remote.mappers.AchievementMapper
import com.amirawellness.data.remote.mappers.StreakMapper
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestCoroutineDispatcher
import kotlinx.coroutines.test.TestCoroutineScope
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.*
import retrofit2.Response
import java.util.Date
import java.util.UUID

// Test constants
private const val TEST_USER_ID = "test-user-id"
private const val TEST_STREAK_ID = "test-streak-id"
private const val TEST_ACHIEVEMENT_ID = "test-achievement-id"

/**
 * Unit tests for the ProgressRepository implementation, which handles streak tracking,
 * achievements, emotional trends, and progress statistics in the Amira Wellness
 * Android application.
 */
@ExperimentalCoroutinesApi
class ProgressRepositoryTest {

    @Mock
    private lateinit var mockStreakDao: StreakDao

    @Mock
    private lateinit var mockAchievementDao: AchievementDao

    @Mock
    private lateinit var mockApiService: ApiService

    @Mock
    private lateinit var mockNetworkMonitor: NetworkMonitor

    private lateinit var testDispatcher: TestCoroutineDispatcher
    private lateinit var testScope: TestCoroutineScope
    private lateinit var repository: ProgressRepository

    /**
     * Creates a test streak instance with predefined values
     */
    private fun createTestStreak(currentStreak: Int, longestStreak: Int): Streak {
        return Streak(
            id = UUID.fromString(TEST_STREAK_ID),
            userId = UUID.fromString(TEST_USER_ID),
            currentStreak = currentStreak,
            longestStreak = longestStreak,
            lastActivityDate = Date(),
            totalDaysActive = currentStreak,
            gracePeriodsUsed = 0,
            lastGracePeriodUsed = null,
            streakHistory = emptyList(),
            createdAt = Date(),
            updatedAt = Date()
        )
    }

    /**
     * Creates a test streak info instance with predefined values
     */
    private fun createTestStreakInfo(currentStreak: Int, longestStreak: Int, totalDaysActive: Int): StreakInfo {
        val nextMilestone = 7 // Simplified for testing
        val progressToNextMilestone = currentStreak.toFloat() / nextMilestone.toFloat()
        
        return StreakInfo(
            currentStreak = currentStreak,
            longestStreak = longestStreak,
            totalDaysActive = totalDaysActive,
            lastActiveDate = Date(),
            nextMilestone = nextMilestone,
            progressToNextMilestone = progressToNextMilestone,
            streakHistory = emptyList()
        )
    }

    /**
     * Creates a test achievement instance with predefined values
     */
    private fun createTestAchievement(
        type: AchievementType, 
        category: AchievementCategory,
        progress: Double,
        earnedAt: Date? = null
    ): Achievement {
        return Achievement(
            id = UUID.fromString(TEST_ACHIEVEMENT_ID),
            type = type,
            category = category,
            title = "Test Achievement ${type.name}",
            description = "This is a test achievement for ${type.name}",
            iconUrl = "https://example.com/icons/${type.name.lowercase()}.png",
            points = 100,
            isHidden = false,
            earnedAt = earnedAt,
            progress = progress,
            metadata = mapOf("key" to "value")
        )
    }

    /**
     * Creates a test streak DTO instance with predefined values
     */
    private fun createTestStreakDto(currentStreak: Int, longestStreak: Int): StreakDto {
        return StreakDto(
            id = TEST_STREAK_ID,
            userId = TEST_USER_ID,
            currentStreak = currentStreak,
            longestStreak = longestStreak,
            lastActivityDate = "2023-09-01T12:00:00.000Z",
            totalDaysActive = currentStreak,
            gracePeriodsUsed = 0,
            lastGracePeriodUsed = null,
            streakHistory = emptyList(),
            createdAt = "2023-01-01T12:00:00.000Z",
            updatedAt = "2023-09-01T12:00:00.000Z"
        )
    }

    /**
     * Creates a test achievement DTO instance with predefined values
     */
    private fun createTestAchievementDto(
        type: AchievementType, 
        category: AchievementCategory,
        progress: Double,
        earnedAt: Date? = null
    ): AchievementDto {
        return AchievementDto(
            id = TEST_ACHIEVEMENT_ID,
            type = type.toString(),
            category = category.toString(),
            title = "Test Achievement ${type.name}",
            description = "This is a test achievement for ${type.name}",
            iconUrl = "https://example.com/icons/${type.name.lowercase()}.png",
            points = 100,
            isHidden = false,
            earnedAt = earnedAt?.toString(),
            progress = progress,
            metadata = mapOf("key" to "value")
        )
    }

    /**
     * Sets up the test environment before each test
     */
    @Before
    fun setup() {
        testDispatcher = TestCoroutineDispatcher()
        testScope = TestCoroutineScope(testDispatcher)
        
        // Initialize mocks
        mockStreakDao = mock(StreakDao::class.java)
        mockAchievementDao = mock(AchievementDao::class.java)
        mockApiService = mock(ApiService::class.java)
        mockNetworkMonitor = mock(NetworkMonitor::class.java)
        
        // Set up default behavior
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        
        // Create repository instance with mocked dependencies
        repository = ProgressRepository(
            streakDao = mockStreakDao,
            achievementDao = mockAchievementDao,
            apiService = mockApiService,
            networkMonitor = mockNetworkMonitor
        )
    }

    /**
     * Tests successful retrieval of streak information
     */
    @Test
    fun testGetStreakInfo_success() = runTest {
        // Arrange
        val testStreakInfo = createTestStreakInfo(5, 7, 10)
        `when`(mockStreakDao.getStreakInfo()).thenReturn(flowOf(testStreakInfo))
        
        // Act
        val result = repository.getStreakInfo().first()
        
        // Assert
        verify(mockStreakDao).getStreakInfo()
        assertThat(result).isEqualTo(testStreakInfo)
        assertThat(result.currentStreak).isEqualTo(5)
        assertThat(result.longestStreak).isEqualTo(7)
        assertThat(result.totalDaysActive).isEqualTo(10)
    }

    /**
     * Tests successful retrieval of streak information with remote synchronization
     */
    @Test
    fun testGetStreakInfo_withRemoteSync_success() = runTest {
        // Arrange
        val testStreakInfo = createTestStreakInfo(5, 7, 10)
        val testStreakDto = createTestStreakDto(8, 8)
        val testStreak = createTestStreak(5, 7)
        
        `when`(mockStreakDao.getStreakInfo()).thenReturn(flowOf(testStreakInfo))
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getStreakInfo()).thenReturn(Response.success(testStreakDto))
        `when`(mockStreakDao.getCurrentUserStreak()).thenReturn(testStreak)
        `when`(mockStreakDao.updateStreak(any())).thenReturn(1)
        
        // Act
        val result = repository.getStreakInfo().first()
        
        // Assert
        verify(mockStreakDao).getStreakInfo()
        verify(mockApiService).getStreakInfo()
        verify(mockStreakDao).updateStreak(any())
        // We're not checking the actual result since it depends on the implementation details
        // of how the repository merges local and remote data
    }

    /**
     * Tests retrieval of streak information when offline
     */
    @Test
    fun testGetStreakInfo_offline() = runTest {
        // Arrange
        val testStreakInfo = createTestStreakInfo(5, 7, 10)
        `when`(mockStreakDao.getStreakInfo()).thenReturn(flowOf(testStreakInfo))
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.getStreakInfo().first()
        
        // Assert
        verify(mockStreakDao).getStreakInfo()
        verify(mockApiService, never()).getStreakInfo() // API should not be called when offline
        assertThat(result).isEqualTo(testStreakInfo)
    }

    /**
     * Tests successful streak update with a new activity
     */
    @Test
    fun testUpdateStreak_success() = runTest {
        // Arrange
        val testStreak = createTestStreak(5, 7)
        `when`(mockStreakDao.getCurrentUserStreak()).thenReturn(testStreak)
        `when`(mockStreakDao.updateStreak(any())).thenReturn(1)
        val activityDate = Date()
        
        // Act
        val result = repository.updateStreak(ActivityType.VOICE_JOURNAL, activityDate)
        
        // Assert
        verify(mockStreakDao).getCurrentUserStreak()
        verify(mockStreakDao).updateStreak(any())
        assertThat(result).isTrue()
    }

    /**
     * Tests successful streak creation when no streak exists
     */
    @Test
    fun testUpdateStreak_newStreak_success() = runTest {
        // Arrange
        `when`(mockStreakDao.getCurrentUserStreak()).thenReturn(null) // No existing streak
        `when`(mockStreakDao.insertStreak(any())).thenReturn(1L)
        val activityDate = Date()
        
        // Act
        val result = repository.updateStreak(ActivityType.EMOTIONAL_CHECK_IN, activityDate)
        
        // Assert
        verify(mockStreakDao).getCurrentUserStreak()
        verify(mockStreakDao).insertStreak(any())
        assertThat(result).isTrue()
    }

    /**
     * Tests streak update that triggers a milestone achievement
     */
    @Test
    fun testUpdateStreak_withMilestoneAchievement_success() = runTest {
        // Arrange
        val testStreak = createTestStreak(2, 2) // Current streak is 2, will become 3
        val testAchievement = createTestAchievement(
            AchievementType.STREAK_3_DAYS, 
            AchievementCategory.STREAK,
            0.0,
            null
        )
        
        `when`(mockStreakDao.getCurrentUserStreak()).thenReturn(testStreak)
        `when`(mockStreakDao.updateStreak(any())).thenReturn(1)
        `when`(mockAchievementDao.getAchievementsByCategory(AchievementCategory.STREAK))
            .thenReturn(flowOf(listOf(testAchievement)))
        `when`(mockAchievementDao.markAchievementAsEarned(eq(TEST_ACHIEVEMENT_ID), any())).thenReturn(1)
        
        val activityDate = Date()
        
        // Act
        val result = repository.updateStreak(ActivityType.TOOL_USAGE, activityDate)
        
        // Assert
        verify(mockStreakDao).getCurrentUserStreak()
        verify(mockStreakDao).updateStreak(any())
        verify(mockAchievementDao).getAchievementsByCategory(AchievementCategory.STREAK)
        verify(mockAchievementDao).markAchievementAsEarned(eq(TEST_ACHIEVEMENT_ID), any())
        assertThat(result).isTrue()
    }

    /**
     * Tests successful retrieval of all achievements
     */
    @Test
    fun testGetAchievements_success() = runTest {
        // Arrange
        val testAchievements = listOf(
            createTestAchievement(AchievementType.STREAK_3_DAYS, AchievementCategory.STREAK, 1.0, Date()),
            createTestAchievement(AchievementType.STREAK_7_DAYS, AchievementCategory.STREAK, 0.5, null)
        )
        `when`(mockAchievementDao.getAllAchievements()).thenReturn(flowOf(testAchievements))
        
        // Act
        val result = repository.getAchievements().first()
        
        // Assert
        verify(mockAchievementDao).getAllAchievements()
        assertThat(result).hasSize(2)
        assertThat(result).containsExactlyElementsIn(testAchievements)
    }

    /**
     * Tests successful retrieval of achievements with remote synchronization
     */
    @Test
    fun testGetAchievements_withRemoteSync_success() = runTest {
        // Arrange
        val testAchievements = listOf(
            createTestAchievement(AchievementType.STREAK_3_DAYS, AchievementCategory.STREAK, 1.0, Date()),
            createTestAchievement(AchievementType.STREAK_7_DAYS, AchievementCategory.STREAK, 0.5, null)
        )
        val testAchievementDtos = listOf(
            createTestAchievementDto(AchievementType.STREAK_3_DAYS, AchievementCategory.STREAK, 1.0, Date()),
            createTestAchievementDto(AchievementType.STREAK_7_DAYS, AchievementCategory.STREAK, 0.7, null),
            createTestAchievementDto(AchievementType.FIRST_JOURNAL, AchievementCategory.JOURNALING, 1.0, Date())
        )
        
        `when`(mockAchievementDao.getAllAchievements()).thenReturn(flowOf(testAchievements))
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getAchievements()).thenReturn(Response.success(testAchievementDtos))
        `when`(mockAchievementDao.insertAchievements(any())).thenReturn(listOf(1L, 2L, 3L))
        
        // Act
        val result = repository.getAchievements().first()
        
        // Assert
        verify(mockAchievementDao).getAllAchievements()
        verify(mockApiService).getAchievements()
        verify(mockAchievementDao).insertAchievements(any())
        // We're not checking the exact result as it depends on the implementation details
        // of how the repository merges local and remote data
    }

    /**
     * Tests successful retrieval of earned achievements
     */
    @Test
    fun testGetEarnedAchievements_success() = runTest {
        // Arrange
        val testAchievements = listOf(
            createTestAchievement(AchievementType.STREAK_3_DAYS, AchievementCategory.STREAK, 1.0, Date()),
            createTestAchievement(AchievementType.FIRST_JOURNAL, AchievementCategory.JOURNALING, 1.0, Date())
        )
        `when`(mockAchievementDao.getEarnedAchievements()).thenReturn(flowOf(testAchievements))
        
        // Act
        val result = repository.getEarnedAchievements().first()
        
        // Assert
        verify(mockAchievementDao).getEarnedAchievements()
        assertThat(result).hasSize(2)
        // All achievements should have earnedAt not null
        assertThat(result.all { it.earnedAt != null }).isTrue()
    }

    /**
     * Tests successful retrieval of pending achievements
     */
    @Test
    fun testGetPendingAchievements_success() = runTest {
        // Arrange
        val testAchievements = listOf(
            createTestAchievement(AchievementType.STREAK_7_DAYS, AchievementCategory.STREAK, 0.5, null),
            createTestAchievement(AchievementType.JOURNAL_MASTER, AchievementCategory.JOURNALING, 0.2, null)
        )
        `when`(mockAchievementDao.getPendingAchievements()).thenReturn(flowOf(testAchievements))
        
        // Act
        val result = repository.getPendingAchievements().first()
        
        // Assert
        verify(mockAchievementDao).getPendingAchievements()
        assertThat(result).hasSize(2)
        // All achievements should have earnedAt null
        assertThat(result.all { it.earnedAt == null }).isTrue()
    }

    /**
     * Tests successful update of achievement progress
     */
    @Test
    fun testUpdateAchievementProgress_success() = runTest {
        // Arrange
        `when`(mockAchievementDao.updateAchievementProgress(eq(TEST_ACHIEVEMENT_ID), eq(0.5), any())).thenReturn(1)
        
        // Act
        val result = repository.updateAchievementProgress(TEST_ACHIEVEMENT_ID, 0.5)
        
        // Assert
        verify(mockAchievementDao).updateAchievementProgress(eq(TEST_ACHIEVEMENT_ID), eq(0.5), any())
        assertThat(result).isTrue()
    }

    /**
     * Tests successful marking of an achievement as earned
     */
    @Test
    fun testMarkAchievementAsEarned_success() = runTest {
        // Arrange
        `when`(mockAchievementDao.markAchievementAsEarned(eq(TEST_ACHIEVEMENT_ID), any())).thenReturn(1)
        
        // Act
        val result = repository.markAchievementAsEarned(TEST_ACHIEVEMENT_ID)
        
        // Assert
        verify(mockAchievementDao).markAchievementAsEarned(eq(TEST_ACHIEVEMENT_ID), any())
        assertThat(result).isTrue()
    }

    /**
     * Tests successful retrieval of emotional trends
     */
    @Test
    fun testGetEmotionalTrends_success() = runTest {
        // Arrange
        val testTrendsData = mapOf(
            "joy" to listOf(5, 6, 7),
            "sadness" to listOf(2, 1, 1),
            "anxiety" to listOf(4, 3, 2)
        )
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getEmotionalTrends(any(), any())).thenReturn(Response.success(testTrendsData))
        
        // Act
        val result = repository.getEmotionalTrends(PeriodType.WEEK, 1).first()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService).getEmotionalTrends(any(), any())
        // The result content depends on the implementation of how the repository processes the raw data
    }

    /**
     * Tests retrieval of emotional trends when offline
     */
    @Test
    fun testGetEmotionalTrends_offline() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.getEmotionalTrends(PeriodType.WEEK, 1).first()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService, never()).getEmotionalTrends(any(), any())
        assertThat(result).isEmpty()
    }

    /**
     * Tests successful retrieval of progress statistics
     */
    @Test
    fun testGetProgressStatistics_success() = runTest {
        // Arrange
        val testStatistics = mapOf(
            "journalCount" to 15,
            "checkInCount" to 30,
            "toolUsageCount" to 25,
            "favoriteTools" to listOf("breathing", "meditation")
        )
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getProgressStatistics()).thenReturn(Response.success(testStatistics))
        
        // Act
        val result = repository.getProgressStatistics(PeriodType.MONTH, 1).first()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService).getProgressStatistics()
        assertThat(result).isEqualTo(testStatistics)
    }

    /**
     * Tests retrieval of progress statistics when offline
     */
    @Test
    fun testGetProgressStatistics_offline() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.getProgressStatistics(PeriodType.MONTH, 1).first()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService, never()).getProgressStatistics()
        assertThat(result).isEmpty()
    }

    /**
     * Tests successful retrieval of progress dashboard data
     */
    @Test
    fun testGetProgressDashboard_success() = runTest {
        // Arrange
        val testDashboard = mapOf(
            "streak" to mapOf("current" to 5, "longest" to 7),
            "achievements" to listOf(mapOf("id" to TEST_ACHIEVEMENT_ID, "title" to "Test")),
            "recentEmotions" to listOf("joy", "calm")
        )
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getProgressDashboard()).thenReturn(Response.success(testDashboard))
        
        // Act
        val result = repository.getProgressDashboard().first()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService).getProgressDashboard()
        assertThat(result).isEqualTo(testDashboard)
    }

    /**
     * Tests retrieval of progress dashboard data when offline
     */
    @Test
    fun testGetProgressDashboard_offline() = runTest {
        // Arrange
        val testStreakInfo = createTestStreakInfo(5, 7, 10)
        val testAchievements = listOf(
            createTestAchievement(AchievementType.STREAK_3_DAYS, AchievementCategory.STREAK, 1.0, Date())
        )
        
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        `when`(mockStreakDao.getStreakInfo()).thenReturn(flowOf(testStreakInfo))
        `when`(mockAchievementDao.getEarnedAchievements()).thenReturn(flowOf(testAchievements))
        `when`(mockAchievementDao.getAchievementCount()).thenReturn(5)
        
        // Act
        val result = repository.getProgressDashboard().first()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService, never()).getProgressDashboard()
        verify(mockStreakDao).getStreakInfo()
        verify(mockAchievementDao).getEarnedAchievements()
        
        // Check that the local dashboard contains expected data
        assertThat(result).containsKey("streak")
        assertThat(result).containsKey("earnedAchievements")
        assertThat(result).containsKey("isOffline")
        assertThat(result["isOffline"]).isEqualTo(true)
    }

    /**
     * Tests successful synchronization of achievements with server
     */
    @Test
    fun testSyncAchievementsWithServer_success() = runTest {
        // Arrange
        val testAchievementDtos = listOf(
            createTestAchievementDto(AchievementType.STREAK_3_DAYS, AchievementCategory.STREAK, 1.0, Date()),
            createTestAchievementDto(AchievementType.STREAK_7_DAYS, AchievementCategory.STREAK, 0.5, null)
        )
        
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getAchievements()).thenReturn(Response.success(testAchievementDtos))
        `when`(mockAchievementDao.insertAchievements(any())).thenReturn(listOf(1L, 2L))
        
        // Act
        val result = repository.syncAchievementsWithServer()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService).getAchievements()
        verify(mockAchievementDao).insertAchievements(any())
        assertThat(result).isTrue()
    }

    /**
     * Tests achievement synchronization when offline
     */
    @Test
    fun testSyncAchievementsWithServer_offline() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.syncAchievementsWithServer()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService, never()).getAchievements()
        assertThat(result).isFalse()
    }

    /**
     * Tests successful synchronization of streak with server
     */
    @Test
    fun testSyncStreakWithServer_success() = runTest {
        // Arrange
        val testStreakDto = createTestStreakDto(7, 7)
        val testStreak = createTestStreak(5, 7)
        
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getStreakInfo()).thenReturn(Response.success(testStreakDto))
        `when`(mockStreakDao.getCurrentUserStreak()).thenReturn(testStreak)
        `when`(mockStreakDao.updateStreak(any())).thenReturn(1)
        
        // Act
        val result = repository.syncStreakWithServer()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService).getStreakInfo()
        verify(mockStreakDao).getCurrentUserStreak()
        verify(mockStreakDao).updateStreak(any())
        assertThat(result).isTrue()
    }

    /**
     * Tests successful synchronization of streak with server when no local streak exists
     */
    @Test
    fun testSyncStreakWithServer_newStreak_success() = runTest {
        // Arrange
        val testStreakDto = createTestStreakDto(1, 1)
        
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        `when`(mockApiService.getStreakInfo()).thenReturn(Response.success(testStreakDto))
        `when`(mockStreakDao.getCurrentUserStreak()).thenReturn(null) // No existing streak
        `when`(mockStreakDao.insertStreak(any())).thenReturn(1L)
        
        // Act
        val result = repository.syncStreakWithServer()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService).getStreakInfo()
        verify(mockStreakDao).getCurrentUserStreak()
        verify(mockStreakDao).insertStreak(any())
        assertThat(result).isTrue()
    }

    /**
     * Tests streak synchronization when offline
     */
    @Test
    fun testSyncStreakWithServer_offline() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.syncStreakWithServer()
        
        // Assert
        verify(mockNetworkMonitor).isNetworkAvailable()
        verify(mockApiService, never()).getStreakInfo()
        assertThat(result).isFalse()
    }
}