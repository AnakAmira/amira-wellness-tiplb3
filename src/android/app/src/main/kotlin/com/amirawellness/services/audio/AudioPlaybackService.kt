package com.amirawellness.services.audio

import android.content.Context // android version: latest
import android.media.MediaPlayer // android version: latest
import android.media.AudioManager // android version: latest
import android.media.AudioAttributes // android version: latest
import android.media.AudioFocusRequest // android version: latest
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
import java.io.FileOutputStream // java.io version: latest
import javax.inject.Inject // javax.inject version: 1
import javax.inject.Singleton // javax.inject version: 1
import com.amirawellness.core.utils.AudioUtils
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.services.encryption.EncryptionManager
import com.amirawellness.data.models.Journal

private const val TAG = "AudioPlaybackService"
private const val PROGRESS_UPDATE_INTERVAL_MS = 100L
private const val WAVEFORM_SAMPLE_COUNT = 100

/**
 * Sealed class representing the possible states of the audio playback process
 */
sealed class PlaybackState {
    /**
     * State when no playback is in progress
     */
    object Idle : PlaybackState()
    
    /**
     * State when preparing to start playback
     */
    object Preparing : PlaybackState()
    
    /**
     * State when actively playing audio
     */
    data class Playing(val audioFile: File, val durationMs: Long) : PlaybackState()
    
    /**
     * State when playback is paused
     */
    data class Paused(val audioFile: File, val durationMs: Long, val currentPosition: Int) : PlaybackState()
    
    /**
     * State when playback has completed
     */
    data class Completed(val audioFile: File, val durationMs: Long) : PlaybackState()
    
    /**
     * State when an error occurs during playback
     */
    data class Error(val error: PlaybackError) : PlaybackState()
}

/**
 * Sealed class representing possible playback errors
 */
sealed class PlaybackError {
    /**
     * Error when audio file is not found
     */
    data class FileNotFound(val filePath: String) : PlaybackError()
    
    /**
     * Error when audio file is invalid or corrupted
     */
    data class InvalidFile(val filePath: String) : PlaybackError()
    
    /**
     * Error when decryption of encrypted audio file fails
     */
    data class DecryptionFailed(val cause: Exception) : PlaybackError()
    
    /**
     * Error when MediaPlayer fails during playback
     */
    data class PlaybackFailed(val cause: Exception) : PlaybackError()
    
    /**
     * Error when an operation is attempted in an invalid state
     */
    data class InvalidState(val message: String) : PlaybackError()
}

/**
 * Service responsible for managing audio playback for voice journaling
 * 
 * This service handles playback of encrypted and unencrypted voice journal recordings,
 * with proper state management, progress tracking, and waveform visualization support.
 */
@Singleton
class AudioPlaybackService @Inject constructor(
    private val context: Context
) {
    // Coroutine scope for async operations
    private val coroutineScope = CoroutineScope(Dispatchers.IO)
    
    // Encryption manager for handling encrypted recordings
    private val encryptionManager = EncryptionManager.getInstance(context)
    
    // MediaPlayer instance for audio playback
    private var mediaPlayer: MediaPlayer? = null
    
    // Audio manager for handling audio focus
    private var audioManager: AudioManager? = null
    
    // Audio focus request
    private var audioFocusRequest: AudioFocusRequest? = null
    
    // Job for tracking playback progress
    private var progressJob: Job? = null
    
    // Reference to temporary decrypted file
    private var tempDecryptedFile: File? = null
    
    // State flows for observing playback state and progress
    private val _playbackState = MutableStateFlow<PlaybackState>(PlaybackState.Idle)
    private val _currentProgress = MutableStateFlow(0)
    private val _waveformData = MutableStateFlow(FloatArray(0))
    
    init {
        // Get audio manager from system service
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        LogUtils.d(TAG, "AudioPlaybackService initialized")
    }
    
    /**
     * Starts playback of a journal's audio recording
     *
     * @param journal Journal to play
     * @return Success or error result
     */
    fun playJournal(journal: Journal): Result<Unit> {
        try {
            // Check if already playing
            val currentState = _playbackState.value
            if (currentState is PlaybackState.Playing || currentState is PlaybackState.Preparing) {
                // Stop current playback before starting new one
                stopPlayback()
            }
            
            // Update state to preparing
            _playbackState.value = PlaybackState.Preparing
            
            // Get the audio file path from journal
            val filePath = journal.localFilePath ?: journal.storagePath
            if (filePath == null) {
                _playbackState.value = PlaybackState.Error(PlaybackError.FileNotFound("No file path available for journal ${journal.id}"))
                return Result.failure(IllegalArgumentException("Journal has no audio file path"))
            }
            
            LogUtils.d(TAG, "Playing journal recording: ${journal.id}, path: $filePath")
            
            // Process file based on encryption status
            val audioFile = if (journal.encryptionIv != null) {
                // Journal is encrypted, need to decrypt
                LogUtils.d(TAG, "Journal is encrypted, decrypting for playback")
                val ivBytes = encryptionManager.decodeFromBase64(journal.encryptionIv)
                val decryptResult = decryptAudioFile(filePath, journal.id, ivBytes)
                
                decryptResult.getOrElse {
                    val error = PlaybackError.DecryptionFailed(it as Exception)
                    _playbackState.value = PlaybackState.Error(error)
                    return Result.failure(it)
                }
            } else {
                // Journal is not encrypted, use file directly
                File(filePath)
            }
            
            // Verify the audio file is valid
            if (!AudioUtils.isAudioFileValid(audioFile)) {
                val error = PlaybackError.InvalidFile(audioFile.absolutePath)
                _playbackState.value = PlaybackState.Error(error)
                return Result.failure(IllegalArgumentException("Invalid audio file: ${audioFile.absolutePath}"))
            }
            
            // Initialize and configure MediaPlayer
            mediaPlayer = MediaPlayer().apply {
                setOnErrorListener { _, what, extra ->
                    LogUtils.e(TAG, "MediaPlayer error: $what, $extra")
                    _playbackState.value = PlaybackState.Error(PlaybackError.PlaybackFailed(Exception("MediaPlayer error: $what, $extra")))
                    releaseMediaPlayer()
                    true
                }
                
                setOnCompletionListener {
                    val state = _playbackState.value
                    if (state is PlaybackState.Playing) {
                        _playbackState.value = PlaybackState.Completed(state.audioFile, state.durationMs)
                        _currentProgress.value = state.durationMs.toInt()
                        stopProgressTracking()
                        abandonAudioFocus()
                    }
                }
            }
            
            // Request audio focus
            if (!requestAudioFocus()) {
                _playbackState.value = PlaybackState.Error(PlaybackError.PlaybackFailed(Exception("Could not get audio focus")))
                return Result.failure(Exception("Could not get audio focus"))
            }
            
            try {
                // Set data source to the audio file
                mediaPlayer?.setDataSource(audioFile.absolutePath)
                mediaPlayer?.prepare()
                mediaPlayer?.start()
                
                // Get audio duration from the file or MediaPlayer
                val durationMs = if (journal.durationSeconds > 0) {
                    journal.durationSeconds * 1000L
                } else {
                    mediaPlayer?.duration?.toLong() ?: AudioUtils.getAudioDuration(audioFile)
                }
                
                // Update playback state
                _playbackState.value = PlaybackState.Playing(audioFile, durationMs)
                
                // Generate waveform data for visualization
                generateWaveformData(audioFile)
                
                // Start tracking progress
                startProgressTracking()
                
                return Result.success(Unit)
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error starting playback", e)
                releaseMediaPlayer()
                cleanupTempFiles()
                val error = PlaybackError.PlaybackFailed(e)
                _playbackState.value = PlaybackState.Error(error)
                return Result.failure(e)
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Unexpected error in playJournal", e)
            val error = PlaybackError.PlaybackFailed(e)
            _playbackState.value = PlaybackState.Error(error)
            return Result.failure(e)
        }
    }
    
    /**
     * Pauses the current audio playback
     *
     * @return Success or error result
     */
    fun pausePlayback(): Result<Unit> {
        try {
            val currentState = _playbackState.value
            
            if (currentState !is PlaybackState.Playing) {
                val error = PlaybackError.InvalidState("Cannot pause: not currently playing")
                _playbackState.value = PlaybackState.Error(error)
                return Result.failure(IllegalStateException("Cannot pause: not currently playing"))
            }
            
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.pause()
                    val currentPosition = it.currentPosition
                    _playbackState.value = PlaybackState.Paused(currentState.audioFile, currentState.durationMs, currentPosition)
                    stopProgressTracking()
                    LogUtils.d(TAG, "Playback paused at position: $currentPosition")
                    return Result.success(Unit)
                }
            }
            
            val error = PlaybackError.PlaybackFailed(Exception("MediaPlayer is null or not playing"))
            _playbackState.value = PlaybackState.Error(error)
            return Result.failure(Exception("MediaPlayer is null or not playing"))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error pausing playback", e)
            val error = PlaybackError.PlaybackFailed(e)
            _playbackState.value = PlaybackState.Error(error)
            return Result.failure(e)
        }
    }
    
    /**
     * Resumes a paused audio playback
     *
     * @return Success or error result
     */
    fun resumePlayback(): Result<Unit> {
        try {
            val currentState = _playbackState.value
            
            if (currentState !is PlaybackState.Paused) {
                val error = PlaybackError.InvalidState("Cannot resume: not currently paused")
                _playbackState.value = PlaybackState.Error(error)
                return Result.failure(IllegalStateException("Cannot resume: not currently paused"))
            }
            
            // Request audio focus before resuming
            if (!requestAudioFocus()) {
                val error = PlaybackError.PlaybackFailed(Exception("Could not get audio focus"))
                _playbackState.value = PlaybackState.Error(error)
                return Result.failure(Exception("Could not get audio focus"))
            }
            
            mediaPlayer?.let {
                it.start()
                _playbackState.value = PlaybackState.Playing(currentState.audioFile, currentState.durationMs)
                startProgressTracking()
                LogUtils.d(TAG, "Playback resumed from position: ${currentState.currentPosition}")
                return Result.success(Unit)
            }
            
            val error = PlaybackError.PlaybackFailed(Exception("MediaPlayer is null"))
            _playbackState.value = PlaybackState.Error(error)
            return Result.failure(Exception("MediaPlayer is null"))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error resuming playback", e)
            val error = PlaybackError.PlaybackFailed(e)
            _playbackState.value = PlaybackState.Error(error)
            return Result.failure(e)
        }
    }
    
    /**
     * Stops the current audio playback
     *
     * @return Success or error result
     */
    fun stopPlayback(): Result<Unit> {
        try {
            val currentState = _playbackState.value
            
            if (currentState !is PlaybackState.Playing && currentState !is PlaybackState.Paused) {
                val error = PlaybackError.InvalidState("Cannot stop: not currently playing or paused")
                _playbackState.value = PlaybackState.Error(error)
                return Result.failure(IllegalStateException("Cannot stop: not currently playing or paused"))
            }
            
            releaseMediaPlayer()
            abandonAudioFocus()
            _playbackState.value = PlaybackState.Idle
            stopProgressTracking()
            cleanupTempFiles()
            
            LogUtils.d(TAG, "Playback stopped")
            return Result.success(Unit)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error stopping playback", e)
            _playbackState.value = PlaybackState.Error(PlaybackError.PlaybackFailed(e))
            return Result.failure(e)
        } finally {
            // Ensure all resources are released
            abandonAudioFocus()
            stopProgressTracking()
            cleanupTempFiles()
        }
    }
    
    /**
     * Seeks to a specific position in the audio playback
     *
     * @param positionMs Position in milliseconds to seek to
     * @return Success or error result
     */
    fun seekTo(positionMs: Int): Result<Unit> {
        try {
            val currentState = _playbackState.value
            
            if (currentState !is PlaybackState.Playing && currentState !is PlaybackState.Paused) {
                val error = PlaybackError.InvalidState("Cannot seek: not currently playing or paused")
                _playbackState.value = PlaybackState.Error(error)
                return Result.failure(IllegalStateException("Cannot seek: not currently playing or paused"))
            }
            
            // Validate position is within playback bounds
            val duration = when (currentState) {
                is PlaybackState.Playing -> currentState.durationMs
                is PlaybackState.Paused -> currentState.durationMs
                else -> 0L
            }
            
            if (positionMs < 0 || positionMs > duration) {
                return Result.failure(IllegalArgumentException("Seek position out of bounds: $positionMs, duration: $duration"))
            }
            
            mediaPlayer?.let {
                it.seekTo(positionMs)
                _currentProgress.value = positionMs
                LogUtils.d(TAG, "Seeked to position: $positionMs")
                return Result.success(Unit)
            }
            
            val error = PlaybackError.PlaybackFailed(Exception("MediaPlayer is null"))
            _playbackState.value = PlaybackState.Error(error)
            return Result.failure(Exception("MediaPlayer is null"))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error seeking to position", e)
            val error = PlaybackError.PlaybackFailed(e)
            _playbackState.value = PlaybackState.Error(error)
            return Result.failure(e)
        }
    }
    
    /**
     * Gets the current playback state as a StateFlow
     *
     * @return Current playback state as a StateFlow
     */
    fun getPlaybackState(): StateFlow<PlaybackState> {
        return _playbackState.asStateFlow()
    }
    
    /**
     * Gets the current playback progress as a StateFlow
     *
     * @return Current progress in milliseconds as a StateFlow
     */
    fun getCurrentProgress(): StateFlow<Int> {
        return _currentProgress.asStateFlow()
    }
    
    /**
     * Gets the waveform data for visualization as a StateFlow
     *
     * @return Waveform data as a StateFlow
     */
    fun getWaveformData(): StateFlow<FloatArray> {
        return _waveformData.asStateFlow()
    }
    
    /**
     * Checks if audio is currently playing
     *
     * @return True if audio is playing, false otherwise
     */
    fun isPlaying(): Boolean {
        return _playbackState.value is PlaybackState.Playing
    }
    
    /**
     * Checks if audio playback is currently paused
     *
     * @return True if playback is paused, false otherwise
     */
    fun isPaused(): Boolean {
        return _playbackState.value is PlaybackState.Paused
    }
    
    /**
     * Decrypts an encrypted audio file to a temporary location
     *
     * @param encryptedFilePath Path to the encrypted file
     * @param journalId Journal ID for encryption key retrieval
     * @param encryptionIv Initialization vector for decryption
     * @return Result containing the decrypted file or an error
     */
    private fun decryptAudioFile(
        encryptedFilePath: String,
        journalId: String,
        encryptionIv: ByteArray
    ): Result<File> {
        try {
            LogUtils.d(TAG, "Decrypting audio file for playback: $encryptedFilePath")
            
            // Create a temporary file for the decrypted audio
            val tempFile = File.createTempFile("decrypted_", ".aac", context.cacheDir)
            
            // Read the encrypted data
            val encryptedFile = File(encryptedFilePath)
            if (!encryptedFile.exists()) {
                return Result.failure(IOException("Encrypted file does not exist: $encryptedFilePath"))
            }
            
            // Setup encrypted data for decryption
            val encryptedData = encryptedFile.readBytes()
            
            // Decrypt the data
            val decryptedDataResult = encryptionManager.decryptJournal(
                EncryptionManager.EncryptedData(encryptedData, encryptionIv),
                journalId
            )
            
            val decryptedData = decryptedDataResult.getOrElse {
                LogUtils.e(TAG, "Failed to decrypt journal audio", it)
                return Result.failure(it)
            }
            
            // Write decrypted data to the temporary file
            FileOutputStream(tempFile).use { it.write(decryptedData) }
            
            // Store the reference to clean up later
            tempDecryptedFile = tempFile
            
            LogUtils.d(TAG, "Audio file decrypted successfully to: ${tempFile.absolutePath}")
            return Result.success(tempFile)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error decrypting audio file", e)
            return Result.failure(e)
        }
    }
    
    /**
     * Generates waveform data for audio visualization
     *
     * @param audioFile Audio file to generate waveform from
     * @return Result containing waveform data or an error
     */
    private fun generateWaveformData(audioFile: File): Result<FloatArray> {
        try {
            LogUtils.d(TAG, "Generating waveform data for visualization")
            
            // Generate waveform data using AudioUtils
            val waveformData = AudioUtils.generateWaveformData(audioFile, WAVEFORM_SAMPLE_COUNT)
            
            // Update the waveform data flow
            _waveformData.value = waveformData
            
            LogUtils.d(TAG, "Waveform data generated successfully with ${waveformData.size} samples")
            return Result.success(waveformData)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error generating waveform data", e)
            return Result.failure(e)
        }
    }
    
    /**
     * Starts a job to track and update playback progress
     */
    private fun startProgressTracking() {
        // Cancel any existing job
        progressJob?.cancel()
        
        // Create a new job for progress tracking
        progressJob = coroutineScope.launch {
            try {
                while (mediaPlayer != null && _playbackState.value is PlaybackState.Playing) {
                    mediaPlayer?.let {
                        if (it.isPlaying) {
                            _currentProgress.value = it.currentPosition
                        }
                    }
                    delay(PROGRESS_UPDATE_INTERVAL_MS)
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error tracking playback progress", e)
            }
        }
    }
    
    /**
     * Stops the progress tracking job
     */
    private fun stopProgressTracking() {
        progressJob?.cancel()
        progressJob = null
    }
    
    /**
     * Releases MediaPlayer resources
     */
    private fun releaseMediaPlayer() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.release()
            }
            mediaPlayer = null
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error releasing MediaPlayer", e)
        }
    }
    
    /**
     * Cleans up temporary decrypted files
     */
    private fun cleanupTempFiles() {
        try {
            tempDecryptedFile?.let {
                if (it.exists()) {
                    it.delete()
                    LogUtils.d(TAG, "Deleted temporary decrypted file: ${it.absolutePath}")
                }
                tempDecryptedFile = null
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error cleaning up temporary files", e)
        }
    }
    
    /**
     * Requests audio focus for playback
     *
     * @return True if focus granted, false otherwise
     */
    private fun requestAudioFocus(): Boolean {
        try {
            val am = audioManager ?: return false
            
            // For devices running Android O and above, use AudioFocusRequest
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val playbackAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                
                val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(playbackAttributes)
                    .setAcceptsDelayedFocusGain(true)
                    .setOnAudioFocusChangeListener { focusChange ->
                        when (focusChange) {
                            AudioManager.AUDIOFOCUS_LOSS -> {
                                // Permanent loss - stop playback
                                stopPlayback()
                            }
                            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                                // Temporary loss - pause playback
                                if (isPlaying()) {
                                    pausePlayback()
                                }
                            }
                            AudioManager.AUDIOFOCUS_GAIN -> {
                                // Focus gained or regained
                                if (isPaused()) {
                                    resumePlayback()
                                }
                            }
                        }
                    }
                    .build()
                
                audioFocusRequest = focusRequest
                
                val result = am.requestAudioFocus(focusRequest)
                return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } else {
                // Legacy implementation for older Android versions
                val result = am.requestAudioFocus(
                    { focusChange ->
                        when (focusChange) {
                            AudioManager.AUDIOFOCUS_LOSS -> stopPlayback()
                            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                                if (isPlaying()) {
                                    pausePlayback()
                                }
                            }
                            AudioManager.AUDIOFOCUS_GAIN -> {
                                if (isPaused()) {
                                    resumePlayback()
                                }
                            }
                        }
                    },
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN
                )
                
                return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error requesting audio focus", e)
            return false
        }
    }
    
    /**
     * Abandons audio focus when playback is complete
     */
    private fun abandonAudioFocus() {
        try {
            val am = audioManager ?: return
            
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val request = audioFocusRequest
                if (request != null) {
                    am.abandonAudioFocusRequest(request)
                }
                audioFocusRequest = null
            } else {
                am.abandonAudioFocus(null)
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error abandoning audio focus", e)
        }
    }
}