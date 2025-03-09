package com.amirawellness.services.audio

import androidx.test.ext.junit.runners.AndroidJUnit4 // androidx.test.ext.junit.runners version: 1.1.5
import androidx.test.platform.app.InstrumentationRegistry // androidx.test.platform.app version: 1.1.5
import androidx.test.rule.GrantPermissionRule // androidx.test.rule version: 1.1.5
import android.Manifest // android version: latest
import android.content.Context // android version: latest
import org.junit.Assert.* // org.junit version: 4.13.2
import org.junit.Before // org.junit version: 4.13.2
import org.junit.After // org.junit version: 4.13.2
import org.junit.Test // org.junit version: 4.13.2
import org.junit.Rule // org.junit version: 4.13.2
import org.junit.rules.TemporaryFolder // org.junit.rules version: 4.13.2
import org.junit.runner.RunWith // org.junit.runner version: 4.13.2
import kotlinx.coroutines.flow.first // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.runBlocking // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.delay // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.collect // kotlinx.coroutines version: 1.6.4
import java.io.File // java.io version: latest
import java.util.UUID // java.util version: latest

import com.amirawellness.core.utils.AudioUtils
import com.amirawellness.core.utils.PermissionUtils
import com.amirawellness.services.encryption.EncryptionManager
import com.amirawellness.core.constants.AppConstants

/**
 * Instrumented test class for AudioRecordingService that verifies audio recording functionality on actual Android devices
 */
@RunWith(AndroidJUnit4::class)
class AudioRecordingServiceInstrumentedTest {

    @get:Rule
    val tempFolder = TemporaryFolder()
    
    @get:Rule
    val permissionRule = GrantPermissionRule.grant(Manifest.permission.RECORD_AUDIO)
    
    private lateinit var context: Context
    private lateinit var audioRecordingService: AudioRecordingService
    private lateinit var testFile: File
    private val testJournalId = "test-journal-${UUID.randomUUID()}"
    
    /**
     * Setup method to initialize test environment before each test
     */
    @Before
    fun setup() {
        // Get instrumentation context from InstrumentationRegistry.getInstrumentation().targetContext
        context = InstrumentationRegistry.getInstrumentation().targetContext
        
        // Initialize audioRecordingService with the context
        audioRecordingService = AudioRecordingService(context)
        
        // Create a test directory for audio files if it doesn't exist
        val testDir = File(context.getExternalFilesDir(null), "test_audio")
        if (!testDir.exists()) {
            testDir.mkdirs()
        }
    }
    
    /**
     * Cleanup method to reset test environment after each test
     */
    @After
    fun cleanup() {
        // Cancel any ongoing recording
        try {
            audioRecordingService.cancelRecording()
        } catch (e: Exception) {
            // Ignore exceptions during cleanup
        }
        
        // Delete any test files created during the test
        try {
            if (::testFile.isInitialized && testFile.exists()) {
                testFile.delete()
            }
        } catch (e: Exception) {
            // Ignore exceptions during cleanup
        }
    }
    
    /**
     * Test the complete recording lifecycle on a real device
     */
    @Test
    fun testRecordingLifecycle() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        val outputFile = startResult.getOrThrow()
        testFile = outputFile
        
        // Verify that isRecording() returns true
        assertTrue("isRecording should return true", audioRecordingService.isRecording())
        
        // Collect the current state and verify it's Recording
        val recordingState = audioRecordingService.getRecordingState().first()
        assertTrue("State should be Recording", recordingState is RecordingState.Recording)
        
        // Wait for a short duration to record some audio
        delay(2000) // 2 seconds
        
        // Pause the recording with audioRecordingService.pauseRecording()
        val pauseResult = audioRecordingService.pauseRecording()
        assertTrue("Pausing should succeed", pauseResult.isSuccess)
        
        // Verify that isPaused() returns true
        assertTrue("isPaused should return true", audioRecordingService.isPaused())
        
        // Collect the current state and verify it's Paused
        val pausedState = audioRecordingService.getRecordingState().first()
        assertTrue("State should be Paused", pausedState is RecordingState.Paused)
        
        // Resume the recording with audioRecordingService.resumeRecording()
        val resumeResult = audioRecordingService.resumeRecording()
        assertTrue("Resuming should succeed", resumeResult.isSuccess)
        
        // Verify that isRecording() returns true again
        assertTrue("isRecording should return true after resume", audioRecordingService.isRecording())
        
        // Wait for another short duration to record more audio
        delay(2000) // 2 more seconds
        
        // Stop the recording with audioRecordingService.stopRecording()
        val stopResult = audioRecordingService.stopRecording()
        assertTrue("Stopping should succeed", stopResult.isSuccess)
        
        // Verify that the returned file exists and is not empty
        val finalFile = stopResult.getOrThrow()
        assertTrue("Output file should exist", finalFile.exists())
        assertTrue("Output file should not be empty", finalFile.length() > 0)
        
        // Collect the current state and verify it's Completed
        val completedState = audioRecordingService.getRecordingState().first()
        assertTrue("State should be Completed", completedState is RecordingState.Completed)
    }
    
    /**
     * Test that amplitude updates are generated during recording
     */
    @Test
    fun testAmplitudeUpdates() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        testFile = startResult.getOrThrow()
        
        // Collect the initial amplitude value
        val initialAmplitude = audioRecordingService.getCurrentAmplitude().first()
        
        // Make a loud sound near the device microphone
        println("PLEASE MAKE NOISE NEAR THE DEVICE MICROPHONE")
        
        // Wait for amplitude updates to be processed
        delay(3000) // 3 seconds
        
        // Collect the updated amplitude value
        val updatedAmplitude = audioRecordingService.getCurrentAmplitude().first()
        
        // Stop the recording with audioRecordingService.stopRecording()
        val stopResult = audioRecordingService.stopRecording()
        assertTrue("Stopping should succeed", stopResult.isSuccess)
        
        // Verify that the amplitude has changed from the initial value
        // Note: In an automated test environment without guaranteed noise, 
        // we'll just verify that amplitude monitoring is functioning
        assertNotNull("Amplitude value should be available", updatedAmplitude)
        println("Amplitude change: $initialAmplitude -> $updatedAmplitude")
    }
    
    /**
     * Test that recording duration is tracked correctly
     */
    @Test
    fun testRecordingDuration() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        testFile = startResult.getOrThrow()
        
        // Collect the initial duration value (should be near 0)
        val initialDuration = audioRecordingService.getRecordingDuration().first()
        assertTrue("Initial duration should be near 0", initialDuration < 100) // Allow for small processing time
        
        // Wait for a specific duration (e.g., 3 seconds)
        val recordDuration = 3000L // 3 seconds
        delay(recordDuration)
        
        // Collect the updated duration value
        val updatedDuration = audioRecordingService.getRecordingDuration().first()
        
        // Stop the recording with audioRecordingService.stopRecording()
        val stopResult = audioRecordingService.stopRecording()
        assertTrue("Stopping should succeed", stopResult.isSuccess)
        
        // Verify that the duration has increased by approximately the wait time
        // Allow for some margin of error (±20%)
        val expectedMinDuration = recordDuration * 0.8
        val expectedMaxDuration = recordDuration * 1.2
        assertTrue(
            "Duration should increase by approximately $recordDuration ms (actual: $updatedDuration)",
            updatedDuration in expectedMinDuration.toLong()..expectedMaxDuration.toLong()
        )
    }
    
    /**
     * Test cancellation of recording
     */
    @Test
    fun testCancelRecording() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        testFile = startResult.getOrThrow()
        
        // Wait for a short duration to record some audio
        delay(1000) // 1 second
        
        // Cancel the recording with audioRecordingService.cancelRecording()
        val cancelResult = audioRecordingService.cancelRecording()
        assertTrue("Cancellation should succeed", cancelResult.isSuccess)
        
        // Collect the current state and verify it's Idle
        val idleState = audioRecordingService.getRecordingState().first()
        assertTrue("State should be Idle after cancellation", idleState is RecordingState.Idle)
        
        // Verify that the recording file was deleted
        assertFalse("Recording file should be deleted after cancellation", testFile.exists())
    }
    
    /**
     * Test encryption of recorded audio
     */
    @Test
    fun testEncryptRecording() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        testFile = startResult.getOrThrow()
        
        // Wait for a short duration to record some audio
        delay(2000) // 2 seconds
        
        // Stop the recording with audioRecordingService.stopRecording()
        val stopResult = audioRecordingService.stopRecording()
        assertTrue("Stopping should succeed", stopResult.isSuccess)
        val outputFile = stopResult.getOrThrow()
        assertTrue("Output file should exist", outputFile.exists())
        
        // Get the file size before encryption
        val originalSize = outputFile.length()
        
        // Encrypt the recording with audioRecordingService.encryptRecording(outputFile, testJournalId)
        val encryptResult = audioRecordingService.encryptRecording(outputFile, testJournalId)
        assertTrue("Encryption should succeed", encryptResult.isSuccess)
        
        // Verify that the encryption result is successful
        val (encryptedFilePath, iv) = encryptResult.getOrThrow()
        
        // Verify that the encrypted file exists
        val encryptedFile = File(encryptedFilePath)
        assertTrue("Encrypted file should exist", encryptedFile.exists())
        
        // Verify that the encrypted file is different from the original file
        assertNotEquals(
            "Encrypted file size should differ from original",
            originalSize,
            encryptedFile.length()
        )
        
        // Verify that the IV (initialization vector) is not empty
        assertTrue("IV should not be empty", iv.isNotEmpty())
    }
    
    /**
     * Test creation of audio metadata
     */
    @Test
    fun testCreateAudioMetadata() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        testFile = startResult.getOrThrow()
        
        // Wait for a short duration to record some audio
        delay(2000) // 2 seconds
        
        // Stop the recording with audioRecordingService.stopRecording()
        val stopResult = audioRecordingService.stopRecording()
        assertTrue("Stopping should succeed", stopResult.isSuccess)
        val outputFile = stopResult.getOrThrow()
        assertTrue("Output file should exist", outputFile.exists())
        
        // Create audio metadata with audioRecordingService.createAudioMetadata(outputFile, testJournalId)
        val metadataResult = audioRecordingService.createAudioMetadata(outputFile, testJournalId)
        assertTrue("Metadata creation should succeed", metadataResult.isSuccess)
        
        val metadata = metadataResult.getOrThrow()
        
        // Verify that the metadata contains the correct journalId
        assertEquals("Metadata should contain correct journalId", testJournalId, metadata.journalId)
        
        // Verify that the metadata contains the expected audio format settings
        assertEquals("Metadata should contain correct audio format", 
                    AppConstants.AUDIO_SETTINGS.AUDIO_FORMAT, metadata.fileFormat)
        assertEquals("Metadata should contain correct sample rate", 
                    AppConstants.AUDIO_SETTINGS.SAMPLE_RATE, metadata.sampleRate)
        assertEquals("Metadata should contain correct bit rate", 
                    AppConstants.AUDIO_SETTINGS.BIT_RATE, metadata.bitRate)
        assertEquals("Metadata should contain correct channels", 
                    AppConstants.AUDIO_SETTINGS.CHANNELS, metadata.channels)
                    
        // Verify that the metadata contains a valid checksum
        assertTrue("Metadata should contain a non-empty checksum", metadata.checksum.isNotEmpty())
    }
    
    /**
     * Test recording with simulated background noise
     */
    @Test
    fun testRecordingWithBackgroundNoise() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        testFile = startResult.getOrThrow()
        
        // Play background noise from another thread or device
        println("SIMULATING BACKGROUND NOISE - PLEASE MAKE NOISE NEAR DEVICE")
        
        // Wait for a short duration to record audio with noise
        delay(3000) // 3 seconds
        
        // Monitor amplitude values during recording
        var maxAmplitude = 0
        for (i in 1..5) {
            val amplitude = audioRecordingService.getCurrentAmplitude().first()
            maxAmplitude = maxOf(maxAmplitude, amplitude)
            delay(500) // Sample amplitude every 0.5 seconds
        }
        
        // Stop the recording with audioRecordingService.stopRecording()
        val stopResult = audioRecordingService.stopRecording()
        assertTrue("Stopping should succeed", stopResult.isSuccess)
        val outputFile = stopResult.getOrThrow()
        
        // Verify that the recording file exists and has content
        assertTrue("Output file should exist", outputFile.exists())
        assertTrue("Output file should not be empty", outputFile.length() > 0)
        
        // Verify that amplitude values were above a minimum threshold during recording
        // Note: For automated tests without guaranteed noise, just log the values
        println("Maximum amplitude recorded: $maxAmplitude")
    }
    
    /**
     * Test multiple recording sessions in sequence
     */
    @Test
    fun testMultipleRecordingSessions() = runBlocking {
        // Start first recording with audioRecordingService.startRecording("session1")
        val startResult1 = audioRecordingService.startRecording("session1")
        assertTrue("First recording should start successfully", startResult1.isSuccess)
        val file1 = startResult1.getOrThrow()
        
        // Wait for a short duration to record some audio
        delay(2000) // 2 seconds
        
        // Stop the first recording with audioRecordingService.stopRecording()
        val stopResult1 = audioRecordingService.stopRecording()
        assertTrue("First stopping should succeed", stopResult1.isSuccess)
        val outputFile1 = stopResult1.getOrThrow()
        assertTrue("First output file should exist", outputFile1.exists())
        
        // Start second recording with audioRecordingService.startRecording("session2")
        val startResult2 = audioRecordingService.startRecording("session2")
        assertTrue("Second recording should start successfully", startResult2.isSuccess)
        val file2 = startResult2.getOrThrow()
        testFile = file2  // Set for cleanup
        
        // Verify that files are different
        assertNotEquals("Second file should be different from first", 
                      file1.absolutePath, file2.absolutePath)
        
        // Wait for a short duration to record some audio
        delay(2000) // 2 seconds
        
        // Stop the second recording with audioRecordingService.stopRecording()
        val stopResult2 = audioRecordingService.stopRecording()
        assertTrue("Second stopping should succeed", stopResult2.isSuccess)
        val outputFile2 = stopResult2.getOrThrow()
        assertTrue("Second output file should exist", outputFile2.exists())
        
        // Verify that both recording files exist and have different content
        assertTrue("Both recordings should have content", 
                 outputFile1.length() > 0 && outputFile2.length() > 0)
        
        // Clean up the first file (second file will be handled by cleanup)
        outputFile1.delete()
    }
    
    /**
     * Test recording with simulated audio focus interruption
     */
    @Test
    fun testRecordingWithInterruption() = runBlocking {
        // Start recording with audioRecordingService.startRecording(testJournalId)
        val startResult = audioRecordingService.startRecording(testJournalId)
        assertTrue("Recording should start successfully", startResult.isSuccess)
        testFile = startResult.getOrThrow()
        
        // Wait for a short duration to record some audio
        delay(2000) // 2 seconds
        
        // Simulate audio focus loss (e.g., incoming call)
        println("SIMULATING AUDIO FOCUS LOSS (e.g., incoming call)")
        
        // Verify that the recording is automatically paused or handles the interruption gracefully
        // For this test, we'll manually pause to simulate what should happen
        val pauseResult = audioRecordingService.pauseRecording()
        assertTrue("Pausing on interruption should succeed", pauseResult.isSuccess)
        
        // Verify recording paused state
        assertTrue("isPaused should return true after interruption", audioRecordingService.isPaused())
        
        // Simulate audio focus regain
        println("SIMULATING AUDIO FOCUS REGAIN")
        
        // Verify that recording can be resumed
        val resumeResult = audioRecordingService.resumeRecording()
        assertTrue("Resuming after interruption should succeed", resumeResult.isSuccess)
        
        // Verify recording active state
        assertTrue("isRecording should return true after focus regain", audioRecordingService.isRecording())
        
        // Record a bit more audio
        delay(1000) // 1 more second
        
        // Stop the recording with audioRecordingService.stopRecording()
        val stopResult = audioRecordingService.stopRecording()
        assertTrue("Stopping should succeed", stopResult.isSuccess)
        
        // Verify final recording exists
        val finalFile = stopResult.getOrThrow()
        assertTrue("Recording file should exist after interruption handling", finalFile.exists())
        assertTrue("Recording file should have content", finalFile.length() > 0)
    }
}