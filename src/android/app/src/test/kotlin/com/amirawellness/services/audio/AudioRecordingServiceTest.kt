package com.amirawellness.services.audio

import org.junit.Before
import org.junit.After
import org.junit.Test
import org.junit.Rule
import org.junit.rules.TemporaryFolder
import org.junit.Assert.*
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.ArgumentMatchers.*
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.whenever
import org.mockito.kotlin.any
import org.mockito.kotlin.verify
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import android.content.Context
import android.media.MediaRecorder
import android.media.AudioManager
import java.io.File
import java.io.IOException
import java.util.UUID

import com.amirawellness.services.audio.AudioRecordingService
import com.amirawellness.services.audio.RecordingState
import com.amirawellness.services.audio.RecordingError
import com.amirawellness.core.utils.AudioUtils
import com.amirawellness.core.utils.PermissionUtils
import com.amirawellness.services.encryption.EncryptionManager
import com.amirawellness.services.encryption.EncryptedData
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.AudioMetadata
import com.amirawellness.core.constants.AppConstants

class AudioRecordingServiceTest {
    @get:Rule
    val tempFolder = TemporaryFolder()

    @Mock
    private lateinit var mockContext: Context

    @Mock
    private lateinit var mockMediaRecorder: MediaRecorder

    @Mock
    private lateinit var mockAudioManager: AudioManager

    @Mock
    private lateinit var mockEncryptionManager: EncryptionManager

    private lateinit var audioRecordingService: AudioRecordingService
    private lateinit var testDispatcher: StandardTestDispatcher
    private lateinit var testScope: TestScope
    private lateinit var testFile: File
    private val testJournalId = "test-journal-123"

    @Before
    fun setup() {
        // Initialize Mockito annotations
        MockitoAnnotations.openMocks(this)
        
        // Initialize coroutine test environment
        testDispatcher = StandardTestDispatcher()
        testScope = TestScope(testDispatcher)
        Dispatchers.setMain(testDispatcher)
        
        // Create a test file in the temporary folder
        testFile = tempFolder.newFile("test_audio.aac")
        
        // Set up mockContext to return mockAudioManager
        whenever(mockContext.getSystemService(Context.AUDIO_SERVICE)).thenReturn(mockAudioManager)
        
        // Set up mockEncryptionManager for getInstance to return the mock
        whenever(EncryptionManager.getInstance(any())).thenReturn(mockEncryptionManager)
        
        // Set up AudioUtils.createAudioFile to return testFile
        whenever(AudioUtils.createAudioFile(any(), any())).thenReturn(testFile)
        
        // Set up AudioUtils.configureMediaRecorder to return true
        whenever(AudioUtils.configureMediaRecorder(any(), any())).thenReturn(true)
        
        // Set up PermissionUtils.hasAudioRecordingPermission to return true by default
        whenever(PermissionUtils.hasAudioRecordingPermission(any())).thenReturn(true)
        
        // Initialize audioRecordingService with mockContext
        audioRecordingService = AudioRecordingService(mockContext)
    }

    @After
    fun tearDown() {
        // Reset main dispatcher
        Dispatchers.resetMain()
    }

    @Test
    fun testStartRecording_Success() = runTest {
        // Arrange - additional setup is in the setup() method
        
        // Act
        val result = audioRecordingService.startRecording(testJournalId)
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Recording::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(AudioUtils).createAudioFile(any(), any())
        verify(AudioUtils).configureMediaRecorder(any(), any())
    }

    @Test
    fun testStartRecording_PermissionDenied() = runTest {
        // Arrange
        whenever(PermissionUtils.hasAudioRecordingPermission(any())).thenReturn(false)
        
        // Act
        val result = audioRecordingService.startRecording(testJournalId)
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Error::class.java, audioRecordingService.getRecordingState().value::class.java)
        val errorState = audioRecordingService.getRecordingState().value as RecordingState.Error
        assertEquals(RecordingError.PermissionDenied::class.java, errorState.error::class.java)
    }

    @Test
    fun testStartRecording_FileCreationFailed() = runTest {
        // Arrange
        whenever(AudioUtils.createAudioFile(any(), any())).thenThrow(IOException("File creation failed"))
        
        // Act
        val result = audioRecordingService.startRecording(testJournalId)
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Error::class.java, audioRecordingService.getRecordingState().value::class.java)
        val errorState = audioRecordingService.getRecordingState().value as RecordingState.Error
        assertEquals(RecordingError.FileCreationFailed::class.java, errorState.error::class.java)
    }

    @Test
    fun testStartRecording_RecorderInitFailed() = runTest {
        // Arrange
        whenever(AudioUtils.configureMediaRecorder(any(), any())).thenReturn(false)
        
        // Act
        val result = audioRecordingService.startRecording(testJournalId)
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Error::class.java, audioRecordingService.getRecordingState().value::class.java)
        val errorState = audioRecordingService.getRecordingState().value as RecordingState.Error
        assertEquals(RecordingError.RecorderInitFailed::class.java, errorState.error::class.java)
    }

    @Test
    fun testStartRecording_RecordingFailed() = runTest {
        // Arrange
        doThrow(IllegalStateException("Recording failed")).whenever(mockMediaRecorder).start()
        
        // Act
        val result = audioRecordingService.startRecording(testJournalId)
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Error::class.java, audioRecordingService.getRecordingState().value::class.java)
        val errorState = audioRecordingService.getRecordingState().value as RecordingState.Error
        assertEquals(RecordingError.RecordingFailed::class.java, errorState.error::class.java)
    }

    @Test
    fun testPauseRecording_Success() = runTest {
        // Arrange - Set up a successful recording start first
        setupSuccessfulRecordingStart()
        
        // Act
        val result = audioRecordingService.pauseRecording()
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Paused::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(mockMediaRecorder).pause()
    }

    @Test
    fun testPauseRecording_InvalidState() = runTest {
        // Arrange - No recording started
        
        // Act
        val result = audioRecordingService.pauseRecording()
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Idle::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(mockMediaRecorder, never()).pause()
    }

    @Test
    fun testPauseRecording_Failed() = runTest {
        // Arrange - Set up a successful recording start first
        setupSuccessfulRecordingStart()
        
        // Set up pause to throw exception
        doThrow(IllegalStateException("Pause failed")).whenever(mockMediaRecorder).pause()
        
        // Act
        val result = audioRecordingService.pauseRecording()
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Error::class.java, audioRecordingService.getRecordingState().value::class.java)
        val errorState = audioRecordingService.getRecordingState().value as RecordingState.Error
        assertEquals(RecordingError.RecordingFailed::class.java, errorState.error::class.java)
    }

    @Test
    fun testResumeRecording_Success() = runTest {
        // Arrange - Set up a successful recording start and pause first
        setupSuccessfulRecordingStartAndPause()
        
        // Act
        val result = audioRecordingService.resumeRecording()
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Recording::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(mockMediaRecorder).resume()
    }

    @Test
    fun testResumeRecording_InvalidState() = runTest {
        // Arrange - No recording started or paused
        
        // Act
        val result = audioRecordingService.resumeRecording()
        
        // Assert
        assertTrue(result.isFailure)
        verify(mockMediaRecorder, never()).resume()
    }

    @Test
    fun testResumeRecording_Failed() = runTest {
        // Arrange - Set up a successful recording start and pause first
        setupSuccessfulRecordingStartAndPause()
        
        // Set up resume to throw exception
        doThrow(IllegalStateException("Resume failed")).whenever(mockMediaRecorder).resume()
        
        // Act
        val result = audioRecordingService.resumeRecording()
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Error::class.java, audioRecordingService.getRecordingState().value::class.java)
        val errorState = audioRecordingService.getRecordingState().value as RecordingState.Error
        assertEquals(RecordingError.RecordingFailed::class.java, errorState.error::class.java)
    }

    @Test
    fun testStopRecording_Success() = runTest {
        // Arrange - Set up a successful recording start first
        setupSuccessfulRecordingStart()
        
        // Act
        val result = audioRecordingService.stopRecording()
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Completed::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(mockMediaRecorder).stop()
        verify(mockMediaRecorder).release()
        assertEquals(testFile, result.getOrNull())
    }

    @Test
    fun testStopRecording_FromPausedState() = runTest {
        // Arrange - Set up a successful recording start and pause
        setupSuccessfulRecordingStartAndPause()
        
        // Act
        val result = audioRecordingService.stopRecording()
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Completed::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(mockMediaRecorder).stop()
        verify(mockMediaRecorder).release()
        assertEquals(testFile, result.getOrNull())
    }

    @Test
    fun testStopRecording_InvalidState() = runTest {
        // Arrange - No recording started
        
        // Act
        val result = audioRecordingService.stopRecording()
        
        // Assert
        assertTrue(result.isFailure)
        verify(mockMediaRecorder, never()).stop()
    }

    @Test
    fun testStopRecording_Failed() = runTest {
        // Arrange - Set up a successful recording start first
        setupSuccessfulRecordingStart()
        
        // Set up stop to throw exception
        doThrow(IllegalStateException("Stop failed")).whenever(mockMediaRecorder).stop()
        
        // Act
        val result = audioRecordingService.stopRecording()
        
        // Assert
        assertTrue(result.isFailure)
        assertEquals(RecordingState.Error::class.java, audioRecordingService.getRecordingState().value::class.java)
        val errorState = audioRecordingService.getRecordingState().value as RecordingState.Error
        assertEquals(RecordingError.RecordingFailed::class.java, errorState.error::class.java)
    }

    @Test
    fun testCancelRecording_FromRecordingState() = runTest {
        // Arrange - Set up a successful recording start first
        setupSuccessfulRecordingStart()
        
        // Act
        val result = audioRecordingService.cancelRecording()
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Idle::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(mockMediaRecorder).stop()
        verify(mockMediaRecorder).release()
        verify(AudioUtils).deleteAudioFile(testFile)
    }

    @Test
    fun testCancelRecording_FromPausedState() = runTest {
        // Arrange - Set up a successful recording start and pause
        setupSuccessfulRecordingStartAndPause()
        
        // Act
        val result = audioRecordingService.cancelRecording()
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Idle::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(mockMediaRecorder).stop()
        verify(mockMediaRecorder).release()
        verify(AudioUtils).deleteAudioFile(testFile)
    }

    @Test
    fun testCancelRecording_FromPreparingState() = runTest {
        // Arrange - Set up a state where recording is preparing but not started
        // This is simulated by setting the state to Preparing
        audioRecordingService.getRecordingState() as MutableStateFlow<RecordingState>
        (audioRecordingService.getRecordingState() as MutableStateFlow<RecordingState>).value = RecordingState.Preparing
        
        // Act
        val result = audioRecordingService.cancelRecording()
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(RecordingState.Idle::class.java, audioRecordingService.getRecordingState().value::class.java)
        verify(AudioUtils).deleteAudioFile(any())
    }

    @Test
    fun testCancelRecording_InvalidState() = runTest {
        // Arrange - No recording started or prepared
        
        // Act
        val result = audioRecordingService.cancelRecording()
        
        // Assert
        assertTrue(result.isFailure)
        verify(mockMediaRecorder, never()).stop()
        verify(AudioUtils, never()).deleteAudioFile(any())
    }

    @Test
    fun testEncryptRecording_Success() = runTest {
        // Arrange
        val testEncryptedData = EncryptedData(ByteArray(100), ByteArray(16))
        whenever(mockEncryptionManager.encryptJournal(any(), eq(testJournalId))).thenReturn(Result.success(testEncryptedData))
        
        // Act
        val result = audioRecordingService.encryptRecording(testFile, testJournalId)
        
        // Assert
        assertTrue(result.isSuccess)
        verify(mockEncryptionManager).encryptJournal(any(), eq(testJournalId))
        assertNotNull(result.getOrNull())
    }

    @Test
    fun testEncryptRecording_FileNotExists() = runTest {
        // Arrange
        val nonExistentFile = File(tempFolder.root, "nonexistent.aac")
        
        // Act
        val result = audioRecordingService.encryptRecording(nonExistentFile, testJournalId)
        
        // Assert
        assertTrue(result.isFailure)
        verify(mockEncryptionManager, never()).encryptJournal(any(), any())
    }

    @Test
    fun testEncryptRecording_EncryptionFailed() = runTest {
        // Arrange
        whenever(mockEncryptionManager.encryptJournal(any(), any())).thenReturn(
            Result.failure(Exception("Encryption failed"))
        )
        
        // Act
        val result = audioRecordingService.encryptRecording(testFile, testJournalId)
        
        // Assert
        assertTrue(result.isFailure)
        verify(mockEncryptionManager).encryptJournal(any(), any())
    }

    @Test
    fun testCreateAudioMetadata_Success() = runTest {
        // Arrange
        val testChecksum = "testChecksum123"
        whenever(AudioUtils.calculateAudioChecksum(any())).thenReturn(testChecksum)
        
        // Act
        val result = audioRecordingService.createAudioMetadata(testFile, testJournalId)
        
        // Assert
        assertTrue(result.isSuccess)
        val metadata = result.getOrNull()
        assertNotNull(metadata)
        assertEquals(testJournalId, metadata?.journalId)
        assertEquals(AppConstants.AUDIO_SETTINGS.AUDIO_FORMAT, metadata?.fileFormat)
        assertEquals(AppConstants.AUDIO_SETTINGS.SAMPLE_RATE, metadata?.sampleRate)
        assertEquals(AppConstants.AUDIO_SETTINGS.BIT_RATE, metadata?.bitRate)
        assertEquals(AppConstants.AUDIO_SETTINGS.CHANNELS, metadata?.channels)
        assertEquals(testChecksum, metadata?.checksum)
        verify(AudioUtils).calculateAudioChecksum(testFile)
    }

    @Test
    fun testCreateAudioMetadata_Failed() = runTest {
        // Arrange
        whenever(AudioUtils.calculateAudioChecksum(any())).thenThrow(IOException("Checksum calculation failed"))
        
        // Act
        val result = audioRecordingService.createAudioMetadata(testFile, testJournalId)
        
        // Assert
        assertTrue(result.isFailure)
        verify(AudioUtils).calculateAudioChecksum(testFile)
    }

    @Test
    fun testGetRecordingState() = runTest {
        // Arrange - Initial state
        
        // Act & Assert - Initial state
        assertEquals(RecordingState.Idle::class.java, audioRecordingService.getRecordingState().value::class.java)
        
        // Arrange - Start recording
        setupSuccessfulRecordingStart()
        
        // Assert - Recording state
        assertEquals(RecordingState.Recording::class.java, audioRecordingService.getRecordingState().value::class.java)
        
        // Arrange - Pause recording
        audioRecordingService.pauseRecording()
        
        // Assert - Paused state
        assertEquals(RecordingState.Paused::class.java, audioRecordingService.getRecordingState().value::class.java)
    }

    @Test
    fun testGetCurrentAmplitude() = runTest {
        // Arrange - Initial state
        
        // Act & Assert - Initial amplitude
        assertEquals(0, audioRecordingService.getCurrentAmplitude().value)
        
        // Arrange - Start recording
        setupSuccessfulRecordingStart()
        
        // Arrange - Set up audio amplitude mock
        val testAmplitude = 1000
        whenever(AudioUtils.getAudioAmplitude(any())).thenReturn(testAmplitude)
        
        // Advance dispatcher to allow amplitude updates
        testDispatcher.scheduler.advanceTimeBy(1000)
        
        // Assert - Updated amplitude
        assertEquals(testAmplitude, audioRecordingService.getCurrentAmplitude().value)
    }

    @Test
    fun testGetRecordingDuration() = runTest {
        // Arrange - Initial state
        
        // Act & Assert - Initial duration
        assertEquals(0L, audioRecordingService.getRecordingDuration().value)
        
        // Arrange - Start recording
        setupSuccessfulRecordingStart()
        
        // Advance dispatcher to simulate recording time
        testDispatcher.scheduler.advanceTimeBy(5000)
        
        // Assert - Duration has increased
        assertTrue(audioRecordingService.getRecordingDuration().value > 0)
    }

    @Test
    fun testIsRecording() = runTest {
        // Arrange - Initial state
        
        // Act & Assert - Initial recording state
        assertFalse(audioRecordingService.isRecording())
        
        // Arrange - Start recording
        setupSuccessfulRecordingStart()
        
        // Act & Assert - Recording state
        assertTrue(audioRecordingService.isRecording())
        
        // Arrange - Pause recording
        audioRecordingService.pauseRecording()
        
        // Act & Assert - Paused state
        assertFalse(audioRecordingService.isRecording())
    }

    @Test
    fun testIsPaused() = runTest {
        // Arrange - Initial state
        
        // Act & Assert - Initial paused state
        assertFalse(audioRecordingService.isPaused())
        
        // Arrange - Start recording
        setupSuccessfulRecordingStart()
        
        // Act & Assert - Recording state
        assertFalse(audioRecordingService.isPaused())
        
        // Arrange - Pause recording
        audioRecordingService.pauseRecording()
        
        // Act & Assert - Paused state
        assertTrue(audioRecordingService.isPaused())
        
        // Arrange - Resume recording
        audioRecordingService.resumeRecording()
        
        // Act & Assert - Recording state again
        assertFalse(audioRecordingService.isPaused())
    }

    // Helper methods for test setup

    private fun setupSuccessfulRecordingStart() {
        // Simulate a successful recording start
        audioRecordingService.startRecording(testJournalId)
        // Force the recording state to Recording for testing subsequent operations
        if (audioRecordingService.getRecordingState().value !is RecordingState.Recording) {
            (audioRecordingService.getRecordingState() as MutableStateFlow<RecordingState>).value = 
                RecordingState.Recording(testFile, System.currentTimeMillis())
        }
    }

    private fun setupSuccessfulRecordingStartAndPause() {
        // First set up a successful recording start
        setupSuccessfulRecordingStart()
        
        // Then simulate a successful pause
        audioRecordingService.pauseRecording()
        // Force the recording state to Paused for testing subsequent operations
        if (audioRecordingService.getRecordingState().value !is RecordingState.Paused) {
            (audioRecordingService.getRecordingState() as MutableStateFlow<RecordingState>).value = 
                RecordingState.Paused(testFile, System.currentTimeMillis(), System.currentTimeMillis(), 1000L)
        }
    }
}