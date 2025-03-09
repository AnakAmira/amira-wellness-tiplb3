package com.amirawellness.domain.usecases.journal

import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import org.mockito.Mockito.*
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.first
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.repositories.JournalRepository
import java.util.UUID

/**
 * Test class for GetJournalsUseCase that verifies journal retrieval functionality
 */
class GetJournalsUseCaseTest {

    @Mock
    private lateinit var mockJournalRepository: JournalRepository
    
    private lateinit var getJournalsUseCase: GetJournalsUseCase
    
    private val testUserId = "test-user-id"
    private val testJournals = createTestJournals()

    /**
     * Sets up the test environment before each test
     */
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        getJournalsUseCase = GetJournalsUseCase(mockJournalRepository)
    }

    /**
     * Tests retrieving all journals for a specific user
     */
    @Test
    fun testGetJournalsByUser() = runTest {
        // Arrange
        `when`(mockJournalRepository.getJournalsByUser(testUserId))
            .thenReturn(flowOf(testJournals))
        
        // Act
        val result = getJournalsUseCase(testUserId).first()
        
        // Assert
        assertEquals(testJournals, result)
        verify(mockJournalRepository, times(1)).getJournalsByUser(testUserId)
    }

    /**
     * Tests retrieving favorite journals for a specific user
     */
    @Test
    fun testGetFavoriteJournals() = runTest {
        // Arrange
        val favoriteJournals = testJournals.filter { it.isFavorite }
        `when`(mockJournalRepository.getFavoriteJournals(testUserId))
            .thenReturn(flowOf(favoriteJournals))
        
        // Act
        val result = getJournalsUseCase.getFavoriteJournals(testUserId).first()
        
        // Assert
        assertEquals(favoriteJournals, result)
        verify(mockJournalRepository, times(1)).getFavoriteJournals(testUserId)
    }

    /**
     * Tests retrieving journals within a specific date range
     */
    @Test
    fun testGetJournalsByDateRange() = runTest {
        // Arrange
        val startDate = 1640995200000L // 2022-01-01
        val endDate = 1672531199000L   // 2022-12-31
        
        val filteredJournals = testJournals
        
        `when`(mockJournalRepository.getJournalsByDateRange(testUserId, startDate, endDate))
            .thenReturn(flowOf(filteredJournals))
        
        // Act
        val result = getJournalsUseCase.getJournalsByDateRange(testUserId, startDate, endDate).first()
        
        // Assert
        assertEquals(filteredJournals, result)
        verify(mockJournalRepository, times(1)).getJournalsByDateRange(testUserId, startDate, endDate)
    }

    /**
     * Tests retrieving journals with a positive emotional shift
     */
    @Test
    fun testGetJournalsWithPositiveShift() = runTest {
        // Arrange
        val positiveShiftJournals = testJournals.filter { it.preEmotionalState.intensity < it.postEmotionalState.intensity }
        
        `when`(mockJournalRepository.getJournalsWithPositiveShift(testUserId))
            .thenReturn(flowOf(positiveShiftJournals))
        
        // Act
        val result = getJournalsUseCase.getJournalsWithPositiveShift(testUserId).first()
        
        // Assert
        assertEquals(positiveShiftJournals, result)
        verify(mockJournalRepository, times(1)).getJournalsWithPositiveShift(testUserId)
    }

    /**
     * Tests retrieving journals with a specific pre-recording emotion type
     */
    @Test
    fun testGetJournalsByEmotionType() = runTest {
        // Arrange
        val emotionType = "JOY"
        val filteredJournals = testJournals
        
        `when`(mockJournalRepository.getJournalsByEmotionType(testUserId, emotionType))
            .thenReturn(flowOf(filteredJournals))
        
        // Act
        val result = getJournalsUseCase.getJournalsByEmotionType(testUserId, emotionType).first()
        
        // Assert
        assertEquals(filteredJournals, result)
        verify(mockJournalRepository, times(1)).getJournalsByEmotionType(testUserId, emotionType)
    }

    /**
     * Tests retrieving the most recent journals for a user
     */
    @Test
    fun testGetRecentJournals() = runTest {
        // Arrange
        val limit = 5
        val recentJournals = testJournals.take(limit)
        
        `when`(mockJournalRepository.getRecentJournals(testUserId, limit))
            .thenReturn(flowOf(recentJournals))
        
        // Act
        val result = getJournalsUseCase.getRecentJournals(testUserId, limit).first()
        
        // Assert
        assertEquals(recentJournals, result)
        verify(mockJournalRepository, times(1)).getRecentJournals(testUserId, limit)
    }

    /**
     * Tests error handling when repository throws an exception
     */
    @Test
    fun testErrorHandling() = runTest {
        // Arrange
        val expectedException = RuntimeException("Test exception")
        
        `when`(mockJournalRepository.getJournalsByUser(testUserId))
            .thenThrow(expectedException)
            
        // Act & Assert
        try {
            getJournalsUseCase(testUserId).first()
            fail("Exception expected but not thrown")
        } catch (e: Exception) {
            // Verify that the exception from the repository is propagated
            assertEquals(expectedException, e)
        }
        
        verify(mockJournalRepository, times(1)).getJournalsByUser(testUserId)
    }

    /**
     * Helper method to create test journal entries
     */
    private fun createTestJournals(): List<Journal> {
        val journals = mutableListOf<Journal>()
        
        // Create multiple journals with different properties for testing
        for (i in 1..5) {
            val journal = mock(Journal::class.java)
            val preEmotionalState = mock(EmotionalState::class.java)
            val postEmotionalState = mock(EmotionalState::class.java)
            
            // Configure journal properties
            `when`(journal.id).thenReturn("journal$i")
            `when`(journal.userId).thenReturn(testUserId)
            `when`(journal.title).thenReturn("Journal $i")
            `when`(journal.isFavorite).thenReturn(i % 2 == 0)
            `when`(journal.createdAt).thenReturn(System.currentTimeMillis() - (i * 86400000)) // i days ago
            
            // Configure emotional states with different intensities to test positive shifts
            `when`(preEmotionalState.intensity).thenReturn(5)
            `when`(postEmotionalState.intensity).thenReturn(if (i % 2 == 0) 7 else 3) // Positive shift for even numbers
            
            `when`(journal.preEmotionalState).thenReturn(preEmotionalState)
            `when`(journal.postEmotionalState).thenReturn(postEmotionalState)
            
            journals.add(journal)
        }
        
        return journals
    }
}