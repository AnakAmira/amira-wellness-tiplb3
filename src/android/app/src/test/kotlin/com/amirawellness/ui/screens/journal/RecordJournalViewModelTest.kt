package com.amirawellness.ui.screens.journal

import android.content.Context
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.utils.PermissionUtils
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.models.Journal
import com.amirawellness.domain.usecases.emotional.RecordEmotionalStateUseCase
import com.amirawellness.domain.usecases.journal.CreateJournalUseCase
import com.amirawellness.services.audio.AudioRecordingService
import com.amirawellness.services.audio.RecordingError
import com.amirawellness.services.audio.RecordingState
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestCoroutineDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations

/**
 * Test class for RecordJournalViewModel that verifies voice journaling functionality
 */
class RecordJournalViewModelTest {

    private lateinit var viewModel: RecordJournalViewModel
    private lateinit var testDispatcher: TestCoroutineDispatcher

    @Mock
    private lateinit var context: Context

    @Mock
    private lateinit var audioRecordingService: AudioRecordingService

    @Mock
    private lateinit var createJournalUseCase: CreateJournalUseCase

    @Mock
    private lateinit var recordEmotionalStateUseCase: RecordEmotionalStateUseCase

    private val testUserId = "test_user_id"
    private val testFile = File("test_file.aac")

    private val recordingStateFlow = MutableStateFlow<RecordingState>(RecordingState.Idle)
    private val amplitudeFlow = MutableStateFlow(0)
    private val durationFlow = MutableStateFlow(0L)

    /**
     * Sets up the test environment before each test
     */
    @Before
    fun setup() {
        // Initialize Mockito annotations
        MockitoAnnotations.openMocks(this)

        // Create TestCoroutineDispatcher
        testDispatcher = TestCoroutineDispatcher()

        // Set main dispatcher to testDispatcher
        Dispatchers.setMain(testDispatcher)

        // Initialize test data (userId, test file)

        // Set up StateFlows for recording state, amplitude, and duration
        `when`(audioRecordingService.getRecordingState()).thenReturn(recordingStateFlow)
        `when`(audioRecordingService.getCurrentAmplitude()).thenReturn(amplitudeFlow)
        `when`(audioRecordingService.getRecordingDuration()).thenReturn(durationFlow)

        // Create viewModel with mocked dependencies
        viewModel = RecordJournalViewModel(context, audioRecordingService, createJournalUseCase, recordEmotionalStateUseCase)

        // Set userId on viewModel
        viewModel.setUserId(testUserId)
    }

    /**
     * Cleans up the test environment after each test
     */
    @After
    fun tearDown() {
        // Reset main dispatcher
        Dispatchers.resetMain()

        // Clean up any resources
    }

    /**
     * Verifies that the initial UI state is correct
     */
    @Test
    fun testInitialState() {
        // Get the current UI state from viewModel.uiState.value
        val initialState = viewModel.uiState.value

        // Assert that isLoading is false
        assertFalse(initialState.isLoading)

        // Assert that isSaving is false
        assertFalse(initialState.isSaving)

        // Assert that recordingState is Idle
        assertEquals(RecordingState.Idle, initialState.recordingState)

        // Assert that currentAmplitude is 0
        assertEquals(0, initialState.currentAmplitude)

        // Assert that recordingDuration is 0
        assertEquals(0L, initialState.recordingDuration)

        // Assert that preEmotionalState is null
        assertNull(initialState.preEmotionalState)

        // Assert that postEmotionalState is null
        assertNull(initialState.postEmotionalState)

        // Assert that savedJournal is null
        assertNull(initialState.savedJournal)

        // Assert that message is null
        assertNull(initialState.message)

        // Assert that isError is false
        assertFalse(initialState.isError)

        // Assert that permissionGranted is false
        assertFalse(initialState.permissionGranted)
    }

    /**
     * Tests permission checking when permission is granted
     */
    @Test
    fun testCheckPermissions_whenPermissionGranted() {
        // Mock PermissionUtils.hasAudioRecordingPermission to return true
        `when`(PermissionUtils.hasAudioRecordingPermission(context)).thenReturn(true)

        // Call viewModel.checkPermissions()
        viewModel.checkPermissions()

        // Assert that uiState.permissionGranted is true
        assertTrue(viewModel.uiState.value.permissionGranted)
    }

    /**
     * Tests permission checking when permission is denied
     */
    @Test
    fun testCheckPermissions_whenPermissionDenied() {
        // Mock PermissionUtils.hasAudioRecordingPermission to return false
        `when`(PermissionUtils.hasAudioRecordingPermission(context)).thenReturn(false)

        // Call viewModel.checkPermissions()
        viewModel.checkPermissions()

        // Assert that uiState.permissionGranted is false
        assertFalse(viewModel.uiState.value.permissionGranted)
    }

    /**
     * Tests updating the pre-recording emotional state
     */
    @Test
    fun testUpdatePreEmotionalState() = runTest {
        // Create a test EmotionalState with JOY emotion type
        val testEmotionalState = EmotionalState(
            id = "test_emotion_id",
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = "PRE_JOURNALING",
            notes = "Feeling good",
            createdAt = System.currentTimeMillis(),
            relatedJournalId = null,
            relatedToolId = null
        )

        // Mock recordEmotionalStateUseCase to return success with the test state
        `when`(recordEmotionalStateUseCase.invoke(testUserId, EmotionType.JOY, 7, "PRE_JOURNALING", "Feeling good", null, null))
            .thenReturn(Result.success(testEmotionalState))

        // Call viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")
        viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")

        // Verify recordEmotionalStateUseCase was called with correct parameters
        verify(recordEmotionalStateUseCase).invoke(testUserId, EmotionType.JOY, 7, "PRE_JOURNALING", "Feeling good", null, null)

        // Assert that uiState.preEmotionalState matches the test state
        assertEquals(testEmotionalState, viewModel.uiState.value.preEmotionalState)
    }

    /**
     * Tests starting recording when pre-emotional state is set
     */
    @Test
    fun testStartRecording_withPreEmotionalState() = runTest {
        // Set up pre-emotional state in the viewModel
        viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")

        // Mock audioRecordingService.startRecording to return success with test file
        `when`(audioRecordingService.startRecording(anyString())).thenReturn(Result.success(testFile))

        // Call viewModel.startRecording()
        viewModel.startRecording()

        // Verify audioRecordingService.startRecording was called
        verify(audioRecordingService).startRecording(anyString())

        // Update recordingStateFlow to Recording state
        recordingStateFlow.value = RecordingState.Recording(testFile, System.currentTimeMillis())

        // Assert that uiState.recordingState is Recording
        assertTrue(viewModel.uiState.value.recordingState is RecordingState.Recording)
    }

    /**
     * Tests starting recording when pre-emotional state is not set
     */
    @Test
    fun testStartRecording_withoutPreEmotionalState() = runTest {
        // Call viewModel.startRecording() without setting pre-emotional state
        viewModel.startRecording()

        // Verify audioRecordingService.startRecording was not called
        verify(audioRecordingService, never()).startRecording(anyString())

        // Assert that uiState.isError is true
        assertTrue(viewModel.uiState.value.isError)

        // Assert that uiState.message contains error about missing pre-emotional state
        assertEquals("Please select pre-recording emotional state first", viewModel.uiState.value.message)
    }

    /**
     * Tests pausing an active recording
     */
    @Test
    fun testPauseRecording() = runTest {
        // Set up recording state to Recording
        recordingStateFlow.value = RecordingState.Recording(testFile, System.currentTimeMillis())

        // Mock audioRecordingService.pauseRecording to return success
        `when`(audioRecordingService.pauseRecording()).thenReturn(Result.success(Unit))

        // Call viewModel.pauseRecording()
        viewModel.pauseRecording()

        // Verify audioRecordingService.pauseRecording was called
        verify(audioRecordingService).pauseRecording()

        // Update recordingStateFlow to Paused state
        recordingStateFlow.value = RecordingState.Paused(testFile, System.currentTimeMillis(), System.currentTimeMillis(), 0L)

        // Assert that uiState.recordingState is Paused
        assertTrue(viewModel.uiState.value.recordingState is RecordingState.Paused)
    }

    /**
     * Tests resuming a paused recording
     */
    @Test
    fun testResumeRecording() = runTest {
        // Set up recording state to Paused
        recordingStateFlow.value = RecordingState.Paused(testFile, System.currentTimeMillis(), System.currentTimeMillis(), 0L)

        // Mock audioRecordingService.resumeRecording to return success
        `when`(audioRecordingService.resumeRecording()).thenReturn(Result.success(Unit))

        // Call viewModel.resumeRecording()
        viewModel.resumeRecording()

        // Verify audioRecordingService.resumeRecording was called
        verify(audioRecordingService).resumeRecording()

        // Update recordingStateFlow to Recording state
        recordingStateFlow.value = RecordingState.Recording(testFile, System.currentTimeMillis())

        // Assert that uiState.recordingState is Recording
        assertTrue(viewModel.uiState.value.recordingState is RecordingState.Recording)
    }

    /**
     * Tests stopping a recording
     */
    @Test
    fun testStopRecording() = runTest {
        // Set up recording state to Recording
        recordingStateFlow.value = RecordingState.Recording(testFile, System.currentTimeMillis())

        // Set up pre-emotional state in the viewModel
        viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")

        // Mock audioRecordingService.stopRecording to return success with test file
        `when`(audioRecordingService.stopRecording()).thenReturn(Result.success(testFile))

        // Call viewModel.stopRecording()
        viewModel.stopRecording()

        // Verify audioRecordingService.stopRecording was called
        verify(audioRecordingService).stopRecording()

        // Update recordingStateFlow to Completed state
        recordingStateFlow.value = RecordingState.Completed(testFile, System.currentTimeMillis(), System.currentTimeMillis(), 0L)

        // Assert that uiState.recordingState is Completed
        assertTrue(viewModel.uiState.value.recordingState is RecordingState.Completed)

        // Assert that uiState.postEmotionalState is not null
        assertNotNull(viewModel.uiState.value.postEmotionalState)

        // Assert that uiState.postEmotionalState has same emotion type as preEmotionalState
        assertEquals(EmotionType.JOY, viewModel.uiState.value.postEmotionalState?.emotionType)
    }

    /**
     * Tests canceling a recording
     */
    @Test
    fun testCancelRecording() = runTest {
        // Set up recording state to Recording
        recordingStateFlow.value = RecordingState.Recording(testFile, System.currentTimeMillis())

        // Mock audioRecordingService.cancelRecording to return success
        `when`(audioRecordingService.cancelRecording()).thenReturn(Result.success(Unit))

        // Call viewModel.cancelRecording()
        viewModel.cancelRecording()

        // Verify audioRecordingService.cancelRecording was called
        verify(audioRecordingService).cancelRecording()

        // Update recordingStateFlow to Idle state
        recordingStateFlow.value = RecordingState.Idle

        // Assert that uiState.recordingState is Idle
        assertEquals(RecordingState.Idle, viewModel.uiState.value.recordingState)
    }

    /**
     * Tests updating the post-recording emotional state
     */
    @Test
    fun testUpdatePostEmotionalState() = runTest {
        // Create a test EmotionalState with CALM emotion type
        val testEmotionalState = EmotionalState(
            id = "test_emotion_id",
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = "POST_JOURNALING",
            notes = "Feeling calm",
            createdAt = System.currentTimeMillis(),
            relatedJournalId = null,
            relatedToolId = null
        )

        // Mock recordEmotionalStateUseCase to return success with the test state
        `when`(recordEmotionalStateUseCase.invoke(testUserId, EmotionType.CALM, 8, "POST_JOURNALING", "Feeling calm", null, null))
            .thenReturn(Result.success(testEmotionalState))

        // Call viewModel.updatePostEmotionalState(EmotionType.CALM, 8, "Feeling calm")
        viewModel.updatePostEmotionalState(EmotionType.CALM, 8, "Feeling calm")

        // Verify recordEmotionalStateUseCase was called with correct parameters
        verify(recordEmotionalStateUseCase).invoke(testUserId, EmotionType.CALM, 8, "POST_JOURNALING", "Feeling calm", null, null)

        // Assert that uiState.postEmotionalState matches the test state
        assertEquals(testEmotionalState, viewModel.uiState.value.postEmotionalState)
    }

    /**
     * Tests successfully saving a journal entry
     */
    @Test
    fun testSaveJournal_success() = runTest {
        // Set up pre-emotional state in the viewModel
        viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")

        // Set up post-emotional state in the viewModel
        viewModel.updatePostEmotionalState(EmotionType.CALM, 8, "Feeling calm")

        // Set up recording state to Completed with test file
        recordingStateFlow.value = RecordingState.Completed(testFile, System.currentTimeMillis(), System.currentTimeMillis(), 0L)

        // Create a test Journal instance
        val testJournal = Journal(
            id = "test_journal_id",
            userId = testUserId,
            createdAt = System.currentTimeMillis(),
            updatedAt = null,
            title = "Test Journal",
            durationSeconds = 0,
            isFavorite = false,
            isUploaded = false,
            localFilePath = "test_file.aac",
            storagePath = null,
            encryptionIv = null,
            preEmotionalState = viewModel.uiState.value.preEmotionalState!!,
            postEmotionalState = viewModel.uiState.value.postEmotionalState!!,
            audioMetadata = null
        )

        // Mock audioRecordingService.encryptRecording to return success with encrypted file and IV
        `when`(audioRecordingService.encryptRecording(any(), anyString())).thenReturn(Result.success(Pair(testFile.absolutePath, "testIv".toByteArray())))

        // Mock createJournalUseCase to return success with test Journal
        `when`(createJournalUseCase.invoke(testUserId, viewModel.uiState.value.preEmotionalState!!, viewModel.uiState.value.postEmotionalState!!, any(), "Test Journal"))
            .thenReturn(Result.success(testJournal))

        // Call viewModel.saveJournal("Test Journal")
        viewModel.saveJournal("Test Journal")

        // Verify audioRecordingService.encryptRecording was called
        verify(audioRecordingService).encryptRecording(any(), anyString())

        // Verify createJournalUseCase was called with correct parameters
        verify(createJournalUseCase).invoke(testUserId, viewModel.uiState.value.preEmotionalState!!, viewModel.uiState.value.postEmotionalState!!, any(), "Test Journal")

        // Assert that uiState.isSaving changed from true to false
        assertFalse(viewModel.uiState.value.isSaving)

        // Assert that uiState.savedJournal matches the test Journal
        assertEquals(testJournal, viewModel.uiState.value.savedJournal)

        // Assert that uiState.recordingState is Idle
        assertEquals(RecordingState.Idle, viewModel.uiState.value.recordingState)
    }

    /**
     * Tests saving a journal without emotional states set
     */
    @Test
    fun testSaveJournal_withoutEmotionalStates() = runTest {
        // Call viewModel.saveJournal() without setting emotional states
        viewModel.saveJournal()

        // Verify createJournalUseCase was not called
        verify(createJournalUseCase, never()).invoke(anyString(), any(), any(), any(), any())

        // Assert that uiState.isError is true
        assertTrue(viewModel.uiState.value.isError)

        // Assert that uiState.message contains error about missing emotional states
        assertEquals("Please select both pre and post recording emotional states", viewModel.uiState.value.message)
    }

    /**
     * Tests handling encryption failure during journal saving
     */
    @Test
    fun testSaveJournal_encryptionFailure() = runTest {
        // Set up pre-emotional state in the viewModel
        viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")

        // Set up post-emotional state in the viewModel
        viewModel.updatePostEmotionalState(EmotionType.CALM, 8, "Feeling calm")

        // Set up recording state to Completed with test file
        recordingStateFlow.value = RecordingState.Completed(testFile, System.currentTimeMillis(), System.currentTimeMillis(), 0L)

        // Mock audioRecordingService.encryptRecording to return failure
        `when`(audioRecordingService.encryptRecording(any(), anyString())).thenReturn(Result.failure(Exception("Encryption failed")))

        // Call viewModel.saveJournal("Test Journal")
        viewModel.saveJournal("Test Journal")

        // Verify audioRecordingService.encryptRecording was called
        verify(audioRecordingService).encryptRecording(any(), anyString())

        // Verify createJournalUseCase was not called
        verify(createJournalUseCase, never()).invoke(anyString(), any(), any(), any(), any())

        // Assert that uiState.isSaving changed from true to false
        assertFalse(viewModel.uiState.value.isSaving)

        // Assert that uiState.isError is true
        assertTrue(viewModel.uiState.value.isError)

        // Assert that uiState.message contains error about encryption failure
        assertEquals("Error encrypting recording: Encryption failed", viewModel.uiState.value.message)
    }

    /**
     * Tests handling journal creation failure
     */
    @Test
    fun testSaveJournal_createJournalFailure() = runTest {
        // Set up pre-emotional state in the viewModel
        viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")

        // Set up post-emotional state in the viewModel
        viewModel.updatePostEmotionalState(EmotionType.CALM, 8, "Feeling calm")

        // Set up recording state to Completed with test file
        recordingStateFlow.value = RecordingState.Completed(testFile, System.currentTimeMillis(), System.currentTimeMillis(), 0L)

        // Mock audioRecordingService.encryptRecording to return success with encrypted file and IV
        `when`(audioRecordingService.encryptRecording(any(), anyString())).thenReturn(Result.success(Pair(testFile.absolutePath, "testIv".toByteArray())))

        // Mock createJournalUseCase to return failure
        `when`(createJournalUseCase.invoke(testUserId, viewModel.uiState.value.preEmotionalState!!, viewModel.uiState.value.postEmotionalState!!, any(), "Test Journal"))
            .thenReturn(Result.failure(Exception("Journal creation failed")))

        // Call viewModel.saveJournal("Test Journal")
        viewModel.saveJournal("Test Journal")

        // Verify audioRecordingService.encryptRecording was called
        verify(audioRecordingService).encryptRecording(any(), anyString())

        // Verify createJournalUseCase was called
        verify(createJournalUseCase).invoke(testUserId, viewModel.uiState.value.preEmotionalState!!, viewModel.uiState.value.postEmotionalState!!, any(), "Test Journal")

        // Assert that uiState.isSaving changed from true to false
        assertFalse(viewModel.uiState.value.isSaving)

        // Assert that uiState.isError is true
        assertTrue(viewModel.uiState.value.isError)

        // Assert that uiState.message contains error about journal creation failure
        assertEquals("Error saving journal: Journal creation failed", viewModel.uiState.value.message)
    }

    /**
     * Tests clearing error messages
     */
    @Test
    fun testClearMessage() {
        // Set up an error message in the viewModel
        viewModel.startRecording()

        // Call viewModel.clearMessage()
        viewModel.clearMessage()

        // Assert that uiState.message is null
        assertNull(viewModel.uiState.value.message)

        // Assert that uiState.isError is false
        assertFalse(viewModel.uiState.value.isError)
    }

    /**
     * Tests resetting the ViewModel state
     */
    @Test
    fun testResetState() = runTest {
        // Set up various state changes in the viewModel
        viewModel.updatePreEmotionalState(EmotionType.JOY, 7, "Feeling good")
        viewModel.updatePostEmotionalState(EmotionType.CALM, 8, "Feeling calm")
        recordingStateFlow.value = RecordingState.Recording(testFile, System.currentTimeMillis())

        // Call viewModel.resetState()
        viewModel.resetState()

        // Assert that uiState matches the default initial state
        assertEquals(RecordJournalViewModel.createDefaultUiState(), viewModel.uiState.value)
    }
}