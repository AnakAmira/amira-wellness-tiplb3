package com.amirawellness.services.audio

import android.content.Context // android version: latest
import android.media.MediaRecorder // android version: latest
import android.media.AudioManager // android version: latest
import kotlinx.coroutines.CoroutineScope // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.Job // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.delay // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines version: 1.6.4
import java.io.File // java.io version: latest
import java.io.IOException // java.io version: latest
import java.io.FileInputStream // java.io version: latest
import javax.inject.Inject // javax.inject version: 1
import javax.inject.Singleton // javax.inject version: 1

import com.amirawellness.core.utils.AudioUtils
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.core.utils.PermissionUtils
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.services.encryption.EncryptionManager
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.AudioMetadata

private const val TAG = "AudioRecordingService"
private const val AMPLITUDE_UPDATE_INTERVAL_MS = 100L

/**
 * Sealed class representing the possible states of the recording process
 */
sealed class RecordingState {
    /**
     * State when no recording is in progress
     */
    object Idle : RecordingState()
    
    /**
     * State when preparing to start recording
     */
    object Preparing : RecordingState()
    
    /**
     * State when actively recording audio
     */
    data class Recording(
        val outputFile: File,
        val startTimeMs: Long
    ) : RecordingState()
    
    /**
     * State when recording is paused
     */
    data class Paused(
        val outputFile: File,
        val startTimeMs: Long,
        val pausedTimeMs: Long,
        val recordedDurationMs: Long
    ) : RecordingState()
    
    /**
     * State when recording has completed successfully
     */
    data class Completed(
        val outputFile: File,
        val startTimeMs: Long,
        val endTimeMs: Long,
        val recordedDurationMs: Long
    ) : RecordingState()
    
    /**
     * State when an error occurs during recording
     */
    data class Error(val error: RecordingError) : RecordingState()
}

/**
 * Sealed class representing possible recording errors
 */
sealed class RecordingError {
    /**
     * Error when audio recording permission is denied
     */
    object PermissionDenied : RecordingError()
    
    /**
     * Error when output file creation fails
     */
    data class FileCreationFailed(val cause: Exception) : RecordingError()
    
    /**
     * Error when MediaRecorder initialization fails
     */
    data class RecorderInitFailed(val cause: Exception) : RecordingError()
    
    /**
     * Error when recording process fails
     */
    data class RecordingFailed(val cause: Exception) : RecordingError()
    
    /**
     * Error when encryption of the recording fails
     */
    data class EncryptionFailed(val cause: Exception) : RecordingError()
    
    /**
     * Error when an operation is attempted in an invalid state
     */
    data class InvalidState(val message: String) : RecordingError()
}

/**
 * Service responsible for managing audio recording for voice journaling
 *
 * This service handles the complete lifecycle of voice journal recordings including
 * starting, pausing, resuming, and stopping recordings. It manages MediaRecorder
 * instances, tracks recording state, monitors audio levels for waveform visualization,
 * and integrates with the encryption system for privacy protection.
 */
@Singleton
class AudioRecordingService @Inject constructor(
    private val context: Context
) {
    private val coroutineScope = CoroutineScope(Dispatchers.IO)
    private val encryptionManager: EncryptionManager = EncryptionManager.getInstance(context)
    
    // MediaRecorder instance for audio recording
    private var mediaRecorder: MediaRecorder? = null
    private var audioManager: AudioManager? = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    
    // Coroutine job for amplitude updates
    private var amplitudeJob: Job? = null
    
    // State flows for observing recording state, amplitude, and duration
    private val _recordingState = MutableStateFlow<RecordingState>(RecordingState.Idle)
    private val _currentAmplitude = MutableStateFlow(0)
    private val _recordingDuration = MutableStateFlow(0L)
    
    /**
     * Starts a new audio recording session
     *
     * @param journalId Unique identifier for the journal entry
     * @param customFileName Optional custom filename, uses journalId if not provided
     * @return Result containing the output file or an error
     */
    fun startRecording(journalId: String, customFileName: String? = null): Result<File> {
        // Check if already recording
        val currentState = _recordingState.value
        if (currentState is RecordingState.Recording || currentState is RecordingState.Paused) {
            LogUtils.e(TAG, "Cannot start recording when already in progress")
            return Result.failure(IllegalStateException("Recording already in progress"))
        }
        
        // Check audio recording permission
        if (!PermissionUtils.hasAudioRecordingPermission(context)) {
            LogUtils.e(TAG, "Audio recording permission denied")
            _recordingState.value = RecordingState.Error(RecordingError.PermissionDenied)
            return Result.failure(SecurityException("Audio recording permission denied"))
        }
        
        // Update state to preparing
        _recordingState.value = RecordingState.Preparing
        
        try {
            // Create output file
            val fileName = customFileName ?: "journal_$journalId"
            val outputFile = AudioUtils.createAudioFile(context, fileName)
            LogUtils.d(TAG, "Created output file: ${outputFile.absolutePath}")
            
            // Initialize MediaRecorder
            mediaRecorder = MediaRecorder().apply {
                // Configure the recorder
                if (!AudioUtils.configureMediaRecorder(this, outputFile)) {
                    throw IOException("Failed to configure MediaRecorder")
                }
                
                // Set error listener
                setOnErrorListener { _, what, extra ->
                    LogUtils.e(TAG, "MediaRecorder error: $what, extra: $extra")
                    _recordingState.value = RecordingState.Error(
                        RecordingError.RecordingFailed(
                            Exception("MediaRecorder error: $what, extra: $extra")
                        )
                    )
                    releaseMediaRecorder()
                }
            }
            
            // Start recording
            mediaRecorder?.start()
            
            // Update state to recording
            val startTimeMs = System.currentTimeMillis()
            _recordingState.value = RecordingState.Recording(outputFile, startTimeMs)
            _recordingDuration.value = 0L
            
            // Start amplitude monitoring
            startAmplitudeUpdates()
            
            LogUtils.i(TAG, "Recording started successfully")
            return Result.success(outputFile)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error starting recording", e)
            releaseMediaRecorder()
            
            val error = when (e) {
                is IOException -> RecordingError.FileCreationFailed(e)
                else -> RecordingError.RecorderInitFailed(e)
            }
            
            _recordingState.value = RecordingState.Error(error)
            return Result.failure(e)
        }
    }
    
    /**
     * Pauses the current recording
     *
     * @return Success or error result
     */
    fun pauseRecording(): Result<Unit> {
        val currentState = _recordingState.value
        if (currentState !is RecordingState.Recording) {
            LogUtils.e(TAG, "Cannot pause recording when not in Recording state")
            return Result.failure(IllegalStateException("Not in Recording state"))
        }
        
        try {
            mediaRecorder?.pause()
            
            val pausedTimeMs = System.currentTimeMillis()
            val recordedDurationMs = _recordingDuration.value
            
            _recordingState.value = RecordingState.Paused(
                currentState.outputFile,
                currentState.startTimeMs,
                pausedTimeMs,
                recordedDurationMs
            )
            
            // Stop amplitude updates
            stopAmplitudeUpdates()
            
            LogUtils.i(TAG, "Recording paused successfully")
            return Result.success(Unit)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error pausing recording", e)
            _recordingState.value = RecordingState.Error(RecordingError.RecordingFailed(e))
            return Result.failure(e)
        }
    }
    
    /**
     * Resumes a paused recording
     *
     * @return Success or error result
     */
    fun resumeRecording(): Result<Unit> {
        val currentState = _recordingState.value
        if (currentState !is RecordingState.Paused) {
            LogUtils.e(TAG, "Cannot resume recording when not in Paused state")
            return Result.failure(IllegalStateException("Not in Paused state"))
        }
        
        try {
            mediaRecorder?.resume()
            
            _recordingState.value = RecordingState.Recording(
                currentState.outputFile,
                currentState.startTimeMs
            )
            
            // Resume amplitude updates
            startAmplitudeUpdates()
            
            LogUtils.i(TAG, "Recording resumed successfully")
            return Result.success(Unit)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error resuming recording", e)
            _recordingState.value = RecordingState.Error(RecordingError.RecordingFailed(e))
            return Result.failure(e)
        }
    }
    
    /**
     * Stops the current recording and finalizes the audio file
     *
     * @return Result containing the output file or an error
     */
    fun stopRecording(): Result<File> {
        val currentState = _recordingState.value
        if (currentState !is RecordingState.Recording && currentState !is RecordingState.Paused) {
            LogUtils.e(TAG, "Cannot stop recording when not in Recording or Paused state")
            return Result.failure(IllegalStateException("Not in Recording or Paused state"))
        }
        
        try {
            // Stop and release MediaRecorder
            mediaRecorder?.stop()
            releaseMediaRecorder()
            
            // Get the output file and calculate duration
            val outputFile = when (currentState) {
                is RecordingState.Recording -> currentState.outputFile
                is RecordingState.Paused -> currentState.outputFile
                else -> throw IllegalStateException("Invalid state for stopping recording")
            }
            
            val startTimeMs = when (currentState) {
                is RecordingState.Recording -> currentState.startTimeMs
                is RecordingState.Paused -> currentState.startTimeMs
                else -> throw IllegalStateException("Invalid state for stopping recording")
            }
            
            val endTimeMs = System.currentTimeMillis()
            val recordedDurationMs = AudioUtils.getAudioDuration(outputFile)
            
            // Update state to completed
            _recordingState.value = RecordingState.Completed(
                outputFile,
                startTimeMs,
                endTimeMs,
                recordedDurationMs
            )
            
            // Stop amplitude updates
            stopAmplitudeUpdates()
            
            LogUtils.i(TAG, "Recording stopped successfully: ${outputFile.absolutePath}")
            return Result.success(outputFile)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error stopping recording", e)
            _recordingState.value = RecordingState.Error(RecordingError.RecordingFailed(e))
            return Result.failure(e)
        }
    }
    
    /**
     * Cancels the current recording and deletes the audio file
     *
     * @return Success or error result
     */
    fun cancelRecording(): Result<Unit> {
        val currentState = _recordingState.value
        if (currentState !is RecordingState.Recording && 
            currentState !is RecordingState.Paused && 
            currentState !is RecordingState.Preparing) {
            
            LogUtils.e(TAG, "Cannot cancel recording when not in Recording, Paused, or Preparing state")
            return Result.failure(IllegalStateException("Not in a cancellable state"))
        }
        
        try {
            // Stop MediaRecorder if active
            try {
                mediaRecorder?.stop()
            } catch (e: Exception) {
                // Ignore exceptions on stop during cancel
                LogUtils.d(TAG, "Ignoring exception during MediaRecorder stop on cancel")
            }
            
            // Release resources
            releaseMediaRecorder()
            
            // Delete the output file
            val outputFile = when (currentState) {
                is RecordingState.Recording -> currentState.outputFile
                is RecordingState.Paused -> currentState.outputFile
                else -> null
            }
            
            if (outputFile != null && outputFile.exists()) {
                AudioUtils.deleteAudioFile(outputFile)
                LogUtils.d(TAG, "Deleted output file during cancel: ${outputFile.absolutePath}")
            }
            
            // Reset state
            _recordingState.value = RecordingState.Idle
            
            // Stop amplitude updates
            stopAmplitudeUpdates()
            
            LogUtils.i(TAG, "Recording canceled successfully")
            return Result.success(Unit)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error canceling recording", e)
            _recordingState.value = RecordingState.Idle // Still reset to idle on error
            return Result.failure(e)
        }
    }
    
    /**
     * Encrypts the recorded audio file for secure storage
     *
     * @param audioFile The audio file to encrypt
     * @param journalId The journal ID associated with the recording
     * @return Result containing the encrypted file path and initialization vector
     */
    fun encryptRecording(audioFile: File, journalId: String): Result<Pair<String, ByteArray>> {
        try {
            // Check if the file exists and is readable
            if (!audioFile.exists() || !audioFile.canRead()) {
                LogUtils.e(TAG, "Audio file does not exist or cannot be read: ${audioFile.absolutePath}")
                return Result.failure(IOException("Audio file does not exist or cannot be read"))
            }
            
            // Read the audio file
            val audioBytes = audioFile.readBytes()
            
            // Encrypt the audio data
            val encryptResult = encryptionManager.encryptJournal(audioBytes, journalId)
            
            // Check if encryption was successful
            val encryptedData = encryptResult.getOrElse {
                LogUtils.e(TAG, "Failed to encrypt audio data", it)
                return Result.failure(it)
            }
            
            // Create encrypted file path with .eaac extension
            val encryptedFilePath = audioFile.absolutePath.replace(
                AppConstants.AUDIO_SETTINGS.AUDIO_EXTENSION,
                AppConstants.AUDIO_SETTINGS.ENCRYPTED_AUDIO_EXTENSION
            )
            
            // Write encrypted data to file
            File(encryptedFilePath).writeBytes(encryptedData.encryptedBytes)
            
            LogUtils.i(TAG, "Audio file encrypted successfully: $encryptedFilePath")
            return Result.success(Pair(encryptedFilePath, encryptedData.iv))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error encrypting audio file", e)
            return Result.failure(RecordingError.EncryptionFailed(e))
        }
    }
    
    /**
     * Gets the current recording state as a StateFlow
     *
     * @return Current recording state as a StateFlow
     */
    fun getRecordingState(): StateFlow<RecordingState> = _recordingState.asStateFlow()
    
    /**
     * Gets the current audio amplitude as a StateFlow
     *
     * @return Current amplitude as a StateFlow
     */
    fun getCurrentAmplitude(): StateFlow<Int> = _currentAmplitude.asStateFlow()
    
    /**
     * Gets the current recording duration as a StateFlow
     *
     * @return Current duration in milliseconds as a StateFlow
     */
    fun getRecordingDuration(): StateFlow<Long> = _recordingDuration.asStateFlow()
    
    /**
     * Checks if recording is currently in progress
     *
     * @return True if recording is in progress, false otherwise
     */
    fun isRecording(): Boolean = _recordingState.value is RecordingState.Recording
    
    /**
     * Checks if recording is currently paused
     *
     * @return True if recording is paused, false otherwise
     */
    fun isPaused(): Boolean = _recordingState.value is RecordingState.Paused
    
    /**
     * Creates AudioMetadata for a recorded audio file
     *
     * @param audioFile The audio file to create metadata for
     * @param journalId The journal ID associated with the recording
     * @return Result containing the audio metadata or an error
     */
    fun createAudioMetadata(audioFile: File, journalId: String): Result<AudioMetadata> {
        try {
            // Generate unique ID for metadata
            val metadataId = java.util.UUID.randomUUID().toString()
            
            // Get file format from extension
            val fileFormat = AppConstants.AUDIO_SETTINGS.AUDIO_FORMAT
            
            // Get file size
            val fileSizeBytes = audioFile.length().toInt()
            
            // Get audio settings from constants
            val sampleRate = AppConstants.AUDIO_SETTINGS.SAMPLE_RATE
            val bitRate = AppConstants.AUDIO_SETTINGS.BIT_RATE
            val channels = AppConstants.AUDIO_SETTINGS.CHANNELS
            
            // Calculate checksum for file integrity verification
            val checksum = AudioUtils.calculateAudioChecksum(audioFile)
            
            // Create metadata object
            val metadata = AudioMetadata(
                id = metadataId,
                journalId = journalId,
                fileFormat = fileFormat,
                fileSizeBytes = fileSizeBytes,
                sampleRate = sampleRate,
                bitRate = bitRate,
                channels = channels,
                checksum = checksum
            )
            
            LogUtils.d(TAG, "Created audio metadata for journal $journalId")
            return Result.success(metadata)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error creating audio metadata", e)
            return Result.failure(e)
        }
    }
    
    /**
     * Starts a job to monitor and update audio amplitude
     */
    private fun startAmplitudeUpdates() {
        // Cancel any existing job
        amplitudeJob?.cancel()
        
        // Create new job for amplitude monitoring
        amplitudeJob = coroutineScope.launch {
            try {
                val startTime = System.currentTimeMillis()
                val initialDuration = _recordingDuration.value
                
                while (mediaRecorder != null && _recordingState.value is RecordingState.Recording) {
                    // Get current amplitude
                    val amplitude = AudioUtils.getAudioAmplitude(mediaRecorder)
                    _currentAmplitude.value = amplitude
                    
                    // Update duration
                    val currentTime = System.currentTimeMillis()
                    val elapsedTime = currentTime - startTime
                    _recordingDuration.value = initialDuration + elapsedTime
                    
                    // Wait for next update
                    delay(AMPLITUDE_UPDATE_INTERVAL_MS)
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error in amplitude monitoring", e)
            }
        }
    }
    
    /**
     * Stops the amplitude update job
     */
    private fun stopAmplitudeUpdates() {
        amplitudeJob?.cancel()
        amplitudeJob = null
    }
    
    /**
     * Releases MediaRecorder resources
     */
    private fun releaseMediaRecorder() {
        try {
            mediaRecorder?.apply {
                try {
                    stop()
                } catch (e: Exception) {
                    LogUtils.d(TAG, "Ignoring exception during MediaRecorder stop on release")
                }
                reset()
                release()
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error releasing MediaRecorder", e)
        } finally {
            mediaRecorder = null
        }
    }
}