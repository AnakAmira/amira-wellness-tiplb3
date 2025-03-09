package com.amirawellness.ui.screens.emotions

import androidx.arch.core.executor.testing.InstantTaskExecutorRule // androidx.arch.core:core-testing:2.2.0
import com.amirawellness.core.constants.AppConstants.EmotionContext // Defined internally
import com.amirawellness.core.constants.AppConstants.EmotionType // Defined internally
import com.amirawellness.core.extensions.Resource // Defined internally
import com.amirawellness.data.models.EmotionalState // Defined internally
import com.amirawellness.data.models.Tool // Defined internally
import com.amirawellness.data.models.ToolCategory // Defined internally
import com.amirawellness.domain.usecases.emotional.RecordEmotionalStateUseCase // Defined internally
import com.amirawellness.domain.usecases.tool.GetRecommendedToolsUseCase // Defined internally
import kotlinx.coroutines.ExperimentalCoroutinesApi // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import kotlinx.coroutines.flow.first // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import kotlinx.coroutines.test.StandardTestDispatcher // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import kotlinx.coroutines.test.TestScope // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import kotlinx.coroutines.test.runTest // kotlinx.coroutines:kotlinx-coroutines-test:1.7.3
import org.junit.Assert.assertEquals // junit:junit:4.13.2
import org.junit.Assert.assertNull // junit:junit:4.13.2
import org.junit.Before // junit:junit:4.13.2
import org.junit.Rule // junit:junit:4.13.2
import org.junit.Test // junit:junit:4.13.2
import org.mockito.kotlin.any // org.mockito.kotlin:mockito-kotlin:5.1.0
import org.mockito.kotlin.mock // org.mockito.kotlin:mockito-kotlin:5.1.0
import org.mockito.kotlin.verify // org.mockito.kotlin:mockito-kotlin:5.1.0
import org.mockito.kotlin.whenever // org.mockito.kotlin:mockito-kotlin:5.1.0

@ExperimentalCoroutinesApi
class EmotionalCheckinViewModelTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    private lateinit var mockRecordEmotionalStateUseCase: RecordEmotionalStateUseCase
    private lateinit var mockGetRecommendedToolsUseCase: GetRecommendedToolsUseCase
    private lateinit var viewModel: EmotionalCheckinViewModel
    private lateinit var testScope: TestScope
    private lateinit var testDispatcher: StandardTestDispatcher

    @Before
    fun setup() {
        testDispatcher = StandardTestDispatcher()
        testScope = TestScope(testDispatcher)
        mockRecordEmotionalStateUseCase = mock()
        mockGetRecommendedToolsUseCase = mock()
        viewModel = EmotionalCheckinViewModel(mockRecordEmotionalStateUseCase, mockGetRecommendedToolsUseCase)
    }

    @Test
    fun testInitializeCheckin_setsInitialState() {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        val state = viewModel.uiState.value
        assertEquals(TEST_USER_ID, state.userId)
        assertEquals(EmotionContext.STANDALONE, state.context)
        assertEquals(EmotionType.JOY, state.selectedEmotionType)
        assertEquals(5, state.intensity)
        assertEquals("", state.notes)
        assertEquals(false, state.isLoading)
        assertNull(state.error)
    }

    @Test
    fun testInitializeCheckin_withJournalingContext_setsCorrectContext() {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.PRE_JOURNALING, TEST_JOURNAL_ID)
        var state = viewModel.uiState.value
        assertEquals(EmotionContext.PRE_JOURNALING, state.context)
        assertEquals(TEST_JOURNAL_ID, state.relatedJournalId)

        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.POST_JOURNALING, TEST_JOURNAL_ID)
        state = viewModel.uiState.value
        assertEquals(EmotionContext.POST_JOURNALING, state.context)
        assertEquals(TEST_JOURNAL_ID, state.relatedJournalId)
    }

    @Test
    fun testInitializeCheckin_withToolUsageContext_setsCorrectContext() {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.TOOL_USAGE, relatedToolId = TEST_TOOL_ID)
        val state = viewModel.uiState.value
        assertEquals(EmotionContext.TOOL_USAGE, state.context)
        assertEquals(TEST_TOOL_ID, state.relatedToolId)
    }

    @Test
    fun testUpdateEmotionType_updatesStateCorrectly() {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        viewModel.updateEmotionType(EmotionType.ANXIETY)
        var state = viewModel.uiState.value
        assertEquals(EmotionType.ANXIETY, state.selectedEmotionType)

        viewModel.updateEmotionType(EmotionType.CALM)
        state = viewModel.uiState.value
        assertEquals(EmotionType.CALM, state.selectedEmotionType)
    }

    @Test
    fun testUpdateIntensity_validValue_updatesStateCorrectly() {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        viewModel.updateIntensity(8)
        var state = viewModel.uiState.value
        assertEquals(8, state.intensity)

        viewModel.updateIntensity(3)
        state = viewModel.uiState.value
        assertEquals(3, state.intensity)
    }

    @Test
    fun testUpdateIntensity_invalidValue_doesNotUpdateState() {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        viewModel.updateIntensity(5)
        var state = viewModel.uiState.value
        assertEquals(5, state.intensity)

        viewModel.updateIntensity(0)
        state = viewModel.uiState.value
        assertEquals(5, state.intensity)

        viewModel.updateIntensity(11)
        state = viewModel.uiState.value
        assertEquals(5, state.intensity)
    }

    @Test
    fun testUpdateNotes_updatesStateCorrectly() {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        viewModel.updateNotes(TEST_NOTES)
        val state = viewModel.uiState.value
        assertEquals(TEST_NOTES, state.notes)
    }

    @Test
    fun testSubmitCheckin_success_updatesStateWithRecommendations() = runTest(testDispatcher) {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        val testState = createTestEmotionalState()
        val testTools = createTestTools()

        whenever(mockRecordEmotionalStateUseCase.invoke(any(), any(), any(), any(), any(), any(), any()))
            .thenReturn(Result.success(testState))
        whenever(mockGetRecommendedToolsUseCase.invoke(any<EmotionalState>()))
            .thenReturn(Result.success(testTools))

        viewModel.submitCheckin()
        testDispatcher.scheduler.advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(false, state.isLoading)
        assertEquals(testState, state.recordedState)
        assertEquals(testTools, state.recommendedTools)
        assertNull(state.error)

        verify(mockRecordEmotionalStateUseCase).invoke(TEST_USER_ID, EmotionType.JOY, 5, EmotionContext.STANDALONE.toString(), "", null, null)
        verify(mockGetRecommendedToolsUseCase).invoke(testState)
    }

    @Test
    fun testSubmitCheckin_recordFailure_updatesStateWithError() = runTest(testDispatcher) {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        val testException = Exception("Test error")

        whenever(mockRecordEmotionalStateUseCase.invoke(any(), any(), any(), any(), any(), any(), any()))
            .thenReturn(Result.failure(testException))

        viewModel.submitCheckin()
        testDispatcher.scheduler.advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(false, state.isLoading)
        assertNull(state.recordedState)
        assertEquals(emptyList<Tool>(), state.recommendedTools)
        assertEquals(testException, state.error)

        verify(mockRecordEmotionalStateUseCase).invoke(TEST_USER_ID, EmotionType.JOY, 5, EmotionContext.STANDALONE.toString(), "", null, null)
        verify(mockGetRecommendedToolsUseCase, mockito.times(0)).invoke(any<EmotionalState>())
    }

    @Test
    fun testSubmitCheckin_recommendationFailure_updatesStateWithError() = runTest(testDispatcher) {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        val testState = createTestEmotionalState()
        val testException = Exception("Test error")

        whenever(mockRecordEmotionalStateUseCase.invoke(any(), any(), any(), any(), any(), any(), any()))
            .thenReturn(Result.success(testState))
        whenever(mockGetRecommendedToolsUseCase.invoke(any<EmotionalState>()))
            .thenReturn(Result.failure(testException))

        viewModel.submitCheckin()
        testDispatcher.scheduler.advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(false, state.isLoading)
        assertEquals(testState, state.recordedState)
        assertEquals(emptyList<Tool>(), state.recommendedTools)
        assertEquals(testException, state.error)

        verify(mockRecordEmotionalStateUseCase).invoke(TEST_USER_ID, EmotionType.JOY, 5, EmotionContext.STANDALONE.toString(), "", null, null)
        verify(mockGetRecommendedToolsUseCase).invoke(testState)
    }

    @Test
    fun testSubmitCheckin_setsLoadingState() = runTest {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        val testState = createTestEmotionalState()
        val testTools = createTestTools()

        whenever(mockRecordEmotionalStateUseCase.invoke(any(), any(), any(), any(), any(), any(), any()))
            .thenReturn(Result.success(testState))
        whenever(mockGetRecommendedToolsUseCase.invoke(any<EmotionalState>()))
            .thenReturn(Result.success(testTools))

        viewModel.submitCheckin()
        val loadingState = viewModel.uiState.value
        assertEquals(true, loadingState.isLoading)

        testDispatcher.scheduler.advanceUntilIdle()
        val finalState = viewModel.uiState.value
        assertEquals(false, finalState.isLoading)
    }

    @Test
    fun testResetState_clearsStateToDefault() = runTest {
        viewModel.initializeCheckin(TEST_USER_ID, EmotionContext.STANDALONE)
        viewModel.updateEmotionType(EmotionType.ANGER)
        viewModel.updateIntensity(3)
        viewModel.updateNotes("Some notes")

        val testState = createTestEmotionalState()
        val testTools = createTestTools()

        whenever(mockRecordEmotionalStateUseCase.invoke(any(), any(), any(), any(), any(), any(), any()))
            .thenReturn(Result.success(testState))
        whenever(mockGetRecommendedToolsUseCase.invoke(any<EmotionalState>()))
            .thenReturn(Result.success(testTools))

        viewModel.submitCheckin()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.resetState()
        val state = viewModel.uiState.value
        assertEquals(EmotionType.JOY, state.selectedEmotionType)
        assertEquals(5, state.intensity)
        assertEquals("", state.notes)
        assertEquals(false, state.isLoading)
        assertNull(state.recordedState)
        assertEquals(emptyList<Tool>(), state.recommendedTools)
        assertNull(state.error)
    }

    private fun createTestEmotionalState(): EmotionalState {
        return EmotionalState(
            id = "test-emotion-123",
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString(),
            notes = TEST_NOTES,
            createdAt = System.currentTimeMillis(),
            relatedJournalId = null,
            relatedToolId = null
        )
    }

    private fun createTestTools(): List<Tool> {
        return listOf(
            Tool(
                id = "tool-1",
                name = "Breathing Exercise",
                description = "A simple breathing exercise",
                category = ToolCategory("cat-1", "Breathing"),
                contentType = com.amirawellness.data.models.ToolContentType.TEXT,
                content = com.amirawellness.data.models.ToolContent("Breathing", "Breathe in, breathe out", null, null, null),
                isFavorite = false,
                usageCount = 0,
                targetEmotions = listOf(EmotionType.ANXIETY),
                estimatedDuration = 5
            ),
            Tool(
                id = "tool-2",
                name = "Meditation",
                description = "A guided meditation",
                category = ToolCategory("cat-2", "Meditation"),
                contentType = com.amirawellness.data.models.ToolContentType.AUDIO,
                content = com.amirawellness.data.models.ToolContent("Meditation", "Listen to the guide", null, null, null),
                isFavorite = false,
                usageCount = 0,
                targetEmotions = listOf(EmotionType.CALM),
                estimatedDuration = 10
            ),
            Tool(
                id = "tool-3",
                name = "Gratitude Journal",
                description = "Write down things you are grateful for",
                category = ToolCategory("cat-3", "Journaling"),
                contentType = com.amirawellness.data.models.ToolContentType.TEXT,
                content = com.amirawellness.data.models.ToolContent("Gratitude", "Write down 3 things", null, null, null),
                isFavorite = false,
                usageCount = 0,
                targetEmotions = listOf(EmotionType.JOY),
                estimatedDuration = 15
            )
        )
    }

    private companion object {
        const val TEST_USER_ID = "test-user-123"
        const val TEST_JOURNAL_ID = "test-journal-456"
        const val TEST_TOOL_ID = "test-tool-789"
        const val TEST_NOTES = "Test notes for emotional check-in"
    }
}