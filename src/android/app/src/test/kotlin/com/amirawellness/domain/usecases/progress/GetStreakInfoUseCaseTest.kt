package com.amirawellness.domain.usecases.progress

import com.amirawellness.data.models.ActivityType
import com.amirawellness.data.models.DailyActivity
import com.amirawellness.data.models.StreakInfo
import com.amirawellness.data.repositories.ProgressRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.mockito.MockitoAnnotations
import java.util.Date

/**
 * Unit tests for the GetStreakInfoUseCase class.
 *
 * These tests verify that the use case correctly interacts with the ProgressRepository
 * to retrieve streak information in the Amira Wellness Android application.
 */
class GetStreakInfoUseCaseTest {

    @Mock
    private lateinit var progressRepository: ProgressRepository

    private lateinit var getStreakInfoUseCase: GetStreakInfoUseCase

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        getStreakInfoUseCase = GetStreakInfoUseCase(progressRepository)
    }

    /**
     * Tests successful retrieval of streak information from the repository.
     */
    @Test
    fun testInvoke_Success() = runTest {
        // Create test data
        val streakInfo = createTestStreakInfo(5, 10, 20)
        
        // Mock the repository response
        `when`(progressRepository.getStreakInfo()).thenReturn(flowOf(streakInfo))
        
        // Execute the use case
        val result = getStreakInfoUseCase().first()
        
        // Verify repository was called
        verify(progressRepository).getStreakInfo()
        
        // Verify result matches expected data
        assertEquals(5, result.currentStreak)
        assertEquals(10, result.longestStreak)
        assertEquals(20, result.totalDaysActive)
        assertEquals(7, result.nextMilestone)
        assertEquals(streakInfo.progressToNextMilestone, result.progressToNextMilestone, 0.001f)
    }

    /**
     * Tests retrieval of streak information when the user has no streak yet.
     */
    @Test
    fun testInvoke_EmptyResult() = runTest {
        // Create empty streak info (new user scenario)
        val emptyStreakInfo = createTestStreakInfo(0, 0, 0)
        
        // Mock the repository response
        `when`(progressRepository.getStreakInfo()).thenReturn(flowOf(emptyStreakInfo))
        
        // Execute the use case
        val result = getStreakInfoUseCase().first()
        
        // Verify repository was called
        verify(progressRepository).getStreakInfo()
        
        // Verify result contains default values
        assertEquals(0, result.currentStreak)
        assertEquals(0, result.longestStreak)
        assertEquals(0, result.totalDaysActive)
        assertEquals(3, result.nextMilestone) // First milestone is 3 days
        assertEquals(0f, result.progressToNextMilestone, 0.001f)
    }

    /**
     * Tests error handling when the repository throws an exception.
     */
    @Test
    fun testInvoke_RepositoryError() = runTest {
        // Define test exception
        val testException = RuntimeException("Test error")
        
        // Mock the repository to throw an exception
        `when`(progressRepository.getStreakInfo()).thenReturn(flow { throw testException })
        
        try {
            // Execute the use case
            getStreakInfoUseCase().first()
            fail("Expected an exception to be thrown")
        } catch (e: Exception) {
            // Verify repository was called
            verify(progressRepository).getStreakInfo()
            
            // Verify the exception is propagated
            assertEquals(testException, e)
        }
    }

    /**
     * Helper method to create test streak information with specified values.
     *
     * @param currentStreak The current streak value
     * @param longestStreak The longest streak value
     * @param totalDaysActive Total number of active days
     * @return A test StreakInfo instance
     */
    private fun createTestStreakInfo(currentStreak: Int, longestStreak: Int, totalDaysActive: Int): StreakInfo {
        val lastActiveDate = Date()
        val nextMilestone = if (currentStreak < 3) 3 else if (currentStreak < 7) 7 else if (currentStreak < 14) 14 else 30
        val progressToNextMilestone = if (nextMilestone > 0) currentStreak.toFloat() / nextMilestone else 0f
        
        return StreakInfo(
            currentStreak = currentStreak,
            longestStreak = longestStreak,
            totalDaysActive = totalDaysActive,
            lastActiveDate = lastActiveDate,
            nextMilestone = nextMilestone,
            progressToNextMilestone = progressToNextMilestone,
            streakHistory = listOf(
                createTestDailyActivity(
                    date = lastActiveDate,
                    isActive = true,
                    activities = listOf(ActivityType.EMOTIONAL_CHECK_IN, ActivityType.VOICE_JOURNAL)
                )
            )
        )
    }

    /**
     * Helper method to create a test daily activity.
     *
     * @param date The date of the activity
     * @param isActive Whether the day was active
     * @param activities List of activities performed on that day
     * @return A test DailyActivity instance
     */
    private fun createTestDailyActivity(date: Date, isActive: Boolean, activities: List<ActivityType>): DailyActivity {
        return DailyActivity(
            date = date,
            isActive = isActive,
            activities = activities
        )
    }
}