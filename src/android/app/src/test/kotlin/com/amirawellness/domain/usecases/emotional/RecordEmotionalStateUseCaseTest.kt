package com.amirawellness.domain.usecases.emotional

import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.repositories.EmotionalStateRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi // kotlinx.coroutines version: 1.7.3
import kotlinx.coroutines.test.runTest // kotlinx.coroutines version: 1.7.3
import org.junit.Assert.assertEquals // JUnit version: 4.13.2
import org.junit.Assert.assertFalse // JUnit version: 4.13.2
import org.junit.Assert.assertTrue // JUnit version: 4.13.2
import org.junit.Before // JUnit version: 4.13.2
import org.junit.Test // JUnit version: 4.13.2
import org.mockito.kotlin.any // Mockito version: 5.1.0
import org.mockito.kotlin.mock // Mockito version: 5.1.0
import org.mockito.kotlin.verify // Mockito version: 5.1.0
import org.mockito.kotlin.whenever // Mockito version: 5.1.0

/**
 * Test class for RecordEmotionalStateUseCase
 */
@ExperimentalCoroutinesApi
class RecordEmotionalStateUseCaseTest {

    /**
     * Mock repository for testing
     */
    private lateinit var mockRepository: EmotionalStateRepository

    /**
     * Use case instance to be tested
     */
    private lateinit var useCase: RecordEmotionalStateUseCase

    /**
     * Test user ID
     */
    private lateinit var userId: String

    /**
     * Setup method to initialize test dependencies
     */
    @Before
    fun setup() {
        // Initialize mockRepository using mock()
        mockRepository = mock<EmotionalStateRepository>()

        // Initialize useCase with mockRepository
        useCase = RecordEmotionalStateUseCase(mockRepository)

        // Set userId to a test value
        userId = "testUserId"
    }

    /**
     * Test that validateIntensity returns true for valid intensity values
     */
    @Test
    fun testValidateIntensity_validValues_returnsTrue() {
        // Test minimum valid intensity (1)
        assertTrue(useCase.validateIntensity(1))

        // Test maximum valid intensity (10)
        assertTrue(useCase.validateIntensity(10))

        // Test middle valid intensity (5)
        assertTrue(useCase.validateIntensity(5))
    }

    /**
     * Test that validateIntensity returns false for invalid intensity values
     */
    @Test
    fun testValidateIntensity_invalidValues_returnsFalse() {
        // Test below minimum intensity (0)
        assertFalse(useCase.validateIntensity(0))

        // Test above maximum intensity (11)
        assertFalse(useCase.validateIntensity(11))

        // Test negative intensity (-5)
        assertFalse(useCase.validateIntensity(-5))
    }

    /**
     * Test that invoke returns success with valid parameters
     */
    @Test
    fun testInvoke_validParameters_returnsSuccess() = runTest {
        // Setup test data with valid parameters
        val emotionType = EmotionType.JOY
        val intensity = 5
        val context = "testContext"
        val notes = "Test notes"
        val journalId = "testJournalId"
        val toolId = "testToolId"

        // Mock repository to return success with the emotional state
        val expectedEmotionalState = EmotionalState(
            id = "testId",
            emotionType = emotionType,
            intensity = intensity,
            context = context,
            notes = notes,
            createdAt = System.currentTimeMillis(),
            relatedJournalId = journalId,
            relatedToolId = toolId
        )
        whenever(mockRepository.recordEmotionalState(any())).thenReturn(Result.success(expectedEmotionalState))

        // Call useCase with test parameters
        val result = useCase(userId, emotionType, intensity, context, notes, journalId, toolId)

        // Verify repository method was called with correct parameters
        verify(mockRepository).recordEmotionalState(any())

        // Assert that result is success
        assertTrue(result.isSuccess)

        // Assert that result contains the expected emotional state
        assertEquals(expectedEmotionalState, result.getOrNull())
    }

    /**
     * Test that invoke returns failure with invalid intensity
     */
    @Test
    fun testInvoke_invalidIntensity_returnsFailure() = runTest {
        // Setup test data with invalid intensity (0)
        val emotionType = EmotionType.JOY
        val intensity = 0
        val context = "testContext"
        val notes = "Test notes"
        val journalId = "testJournalId"
        val toolId = "testToolId"

        // Call useCase with test parameters
        val result = useCase(userId, emotionType, intensity, context, notes, journalId, toolId)

        // Verify repository method was not called
        verify(mockRepository, mockito.times(0)).recordEmotionalState(any())

        // Assert that result is failure
        assertTrue(result.isFailure)

        // Assert that exception is IllegalArgumentException
        assertTrue(result.exceptionOrNull() is IllegalArgumentException)
    }

    /**
     * Test that invoke returns failure when repository throws exception
     */
    @Test
    fun testInvoke_repositoryError_returnsFailure() = runTest {
        // Setup test data with valid parameters
        val emotionType = EmotionType.JOY
        val intensity = 5
        val context = "testContext"
        val notes = "Test notes"
        val journalId = "testJournalId"
        val toolId = "testToolId"

        // Mock repository to throw an exception
        val exception = RuntimeException("Test exception")
        whenever(mockRepository.recordEmotionalState(any())).thenThrow(exception)

        // Call useCase with test parameters
        val result = useCase(userId, emotionType, intensity, context, notes, journalId, toolId)

        // Verify repository method was called
        verify(mockRepository).recordEmotionalState(any())

        // Assert that result is failure
        assertTrue(result.isFailure)

        // Assert that exception is the expected exception
        assertEquals(exception, result.exceptionOrNull())
    }

    /**
     * Test that journal ID is correctly passed to repository
     */
    @Test
    fun testInvoke_withJournalId_passesJournalIdToRepository() = runTest {
        // Setup test data with valid parameters including journal ID
        val emotionType = EmotionType.JOY
        val intensity = 5
        val context = EmotionContext.PRE_JOURNALING.toString()
        val notes = "Test notes"
        val journalId = "testJournalId"
        val toolId = null

        // Mock repository to return success
        whenever(mockRepository.recordEmotionalState(any())).thenReturn(Result.success(mock()))

        // Call useCase with test parameters
        useCase(userId, emotionType, intensity, context, notes, journalId, toolId)

        // Verify repository method was called with emotional state containing the journal ID
        verify(mockRepository).recordEmotionalState(
            argThat { emotionalState ->
                emotionalState.relatedJournalId == journalId
            }
        )
    }

    /**
     * Test that tool ID is correctly passed to repository
     */
    @Test
    fun testInvoke_withToolId_passesToolIdToRepository() = runTest {
        // Setup test data with valid parameters including tool ID
        val emotionType = EmotionType.JOY
        val intensity = 5
        val context = EmotionContext.TOOL_USAGE.toString()
        val notes = "Test notes"
        val journalId = null
        val toolId = "testToolId"

        // Mock repository to return success
        whenever(mockRepository.recordEmotionalState(any())).thenReturn(Result.success(mock()))

        // Call useCase with test parameters
        useCase(userId, emotionType, intensity, context, notes, journalId, toolId)

        // Verify repository method was called with emotional state containing the tool ID
        verify(mockRepository).recordEmotionalState(
            argThat { emotionalState ->
                emotionalState.relatedToolId == toolId
            }
        )
    }

    /**
     * Test that notes are correctly passed to repository
     */
    @Test
    fun testInvoke_withNotes_passesNotesToRepository() = runTest {
        // Setup test data with valid parameters including notes
        val emotionType = EmotionType.JOY
        val intensity = 5
        val context = "testContext"
        val notes = "Test notes"
        val journalId = null
        val toolId = null

        // Mock repository to return success
        whenever(mockRepository.recordEmotionalState(any())).thenReturn(Result.success(mock()))

        // Call useCase with test parameters
        useCase(userId, emotionType, intensity, context, notes, journalId, toolId)

        // Verify repository method was called with emotional state containing the notes
        verify(mockRepository).recordEmotionalState(
            argThat { emotionalState ->
                emotionalState.notes == notes
            }
        )
    }

    /**
     * Test that different contexts are correctly passed to repository
     */
    @Test
    fun testInvoke_differentContexts_passesContextToRepository() = runTest {
        // Test with PRE_JOURNALING context
        val emotionType = EmotionType.JOY
        val intensity = 5
        val notes = "Test notes"
        val journalId = null
        val toolId = null

        // Mock repository to return success
        whenever(mockRepository.recordEmotionalState(any())).thenReturn(Result.success(mock()))

        // Test with PRE_JOURNALING context
        useCase(userId, emotionType, intensity, EmotionContext.PRE_JOURNALING.toString(), notes, journalId, toolId)
        verify(mockRepository).recordEmotionalState(
            argThat { emotionalState ->
                emotionalState.context == EmotionContext.PRE_JOURNALING.toString()
            }
        )

        // Test with POST_JOURNALING context
        useCase(userId, emotionType, intensity, EmotionContext.POST_JOURNALING.toString(), notes, journalId, toolId)
        verify(mockRepository).recordEmotionalState(
            argThat { emotionalState ->
                emotionalState.context == EmotionContext.POST_JOURNALING.toString()
            }
        )

        // Test with STANDALONE context
        useCase(userId, emotionType, intensity, EmotionContext.STANDALONE.toString(), notes, journalId, toolId)
        verify(mockRepository).recordEmotionalState(
            argThat { emotionalState ->
                emotionalState.context == EmotionContext.STANDALONE.toString()
            }
        )
    }
}