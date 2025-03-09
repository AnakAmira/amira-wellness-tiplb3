package com.amirawellness.core.utils

import android.content.Context // android version: latest
import android.media.MediaRecorder // android version: latest
import android.media.MediaMetadataRetriever // android version: latest
import android.media.MediaPlayer // android version: latest
import java.io.File // java.io version: latest
import java.io.IOException // java.io version: latest
import java.security.MessageDigest // java.security version: latest
import java.util.UUID // java.util version: latest
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.core.utils.LogUtils

/**
 * Utility object providing audio recording and processing functionality
 * for the Amira Wellness application. Supports voice journaling feature
 * with secure file handling, audio configuration, and waveform generation.
 */
private const val TAG = "AudioUtils"

object AudioUtils {
    /**
     * Creates a new file for audio recording with a unique name
     *
     * @param context Application context for file path resolution
     * @param customFileName Optional custom filename, uses UUID if not provided
     * @return Newly created audio file
     */
    fun createAudioFile(context: Context, customFileName: String? = null): File {
        try {
            // Create audio directory if it doesn't exist
            val audioDir = File(context.getExternalFilesDir(null), AppConstants.FILE_PATHS.AUDIO_DIRECTORY)
            if (!audioDir.exists()) {
                audioDir.mkdirs()
            }
            
            // Generate filename - either custom or UUID-based
            val fileName = customFileName ?: "recording_${UUID.randomUUID()}"
            val file = File(audioDir, "$fileName${AppConstants.AUDIO_SETTINGS.AUDIO_EXTENSION}")
            
            LogUtils.d(TAG, "Created audio file: ${file.absolutePath}")
            return file
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error creating audio file", e)
            throw e
        }
    }
    
    /**
     * Configures a MediaRecorder instance with optimal settings for voice recording
     *
     * @param recorder MediaRecorder instance to configure
     * @param outputFile File where the recording will be saved
     * @return True if configuration was successful, false otherwise
     */
    fun configureMediaRecorder(recorder: MediaRecorder, outputFile: File): Boolean {
        try {
            // Set audio source to microphone
            recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            
            // Set output format (use MPEG_4 as fallback if AAC_ADTS is not available)
            try {
                recorder.setOutputFormat(MediaRecorder.OutputFormat.AAC_ADTS)
            } catch (e: Exception) {
                LogUtils.d(TAG, "Falling back to MPEG_4 output format")
                recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            }
            
            // Set audio encoder to AAC
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            
            // Set audio parameters from constants
            recorder.setAudioSamplingRate(AppConstants.AUDIO_SETTINGS.SAMPLE_RATE)
            recorder.setAudioChannels(AppConstants.AUDIO_SETTINGS.CHANNELS)
            recorder.setAudioEncodingBitRate(AppConstants.AUDIO_SETTINGS.BIT_RATE)
            
            // Set output file
            recorder.setOutputFile(outputFile.absolutePath)
            
            // Prepare the recorder
            recorder.prepare()
            
            LogUtils.d(TAG, "MediaRecorder configured successfully")
            return true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error configuring MediaRecorder", e)
            return false
        }
    }
    
    /**
     * Gets the current amplitude (audio level) from a MediaRecorder
     *
     * @param recorder MediaRecorder instance to get amplitude from
     * @return Current amplitude value (0 if recorder is null or error occurs)
     */
    fun getAudioAmplitude(recorder: MediaRecorder?): Int {
        if (recorder == null) return 0
        
        return try {
            recorder.maxAmplitude
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting audio amplitude", e)
            0
        }
    }
    
    /**
     * Safely deletes an audio file
     *
     * @param file File to delete
     * @return True if deletion was successful, false otherwise
     */
    fun deleteAudioFile(file: File): Boolean {
        return try {
            if (file.exists()) {
                val result = file.delete()
                LogUtils.d(TAG, "Deleted audio file: ${file.absolutePath}, result: $result")
                result
            } else {
                LogUtils.d(TAG, "File doesn't exist: ${file.absolutePath}")
                false
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error deleting audio file: ${file.absolutePath}", e)
            false
        }
    }
    
    /**
     * Gets the duration of an audio file in milliseconds
     *
     * @param audioFile Audio file to get duration for
     * @return Duration in milliseconds, 0 if error occurs
     */
    fun getAudioDuration(audioFile: File): Long {
        if (!audioFile.exists()) return 0
        
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(audioFile.absolutePath)
            val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0
            return durationMs
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting audio duration", e)
            return 0
        } finally {
            retriever.release()
        }
    }
    
    /**
     * Generates waveform data from an audio file for visualization
     *
     * Note: This is a simplified approach. For production use, you should implement
     * a proper audio processing algorithm that analyzes the actual audio samples.
     * This implementation provides approximate data for visualization purposes.
     *
     * @param audioFile Audio file to generate waveform from
     * @param sampleCount Number of samples to generate
     * @return Array of normalized amplitude values (0.0-1.0) for waveform visualization
     */
    fun generateWaveformData(audioFile: File, sampleCount: Int): FloatArray {
        if (!audioFile.exists() || sampleCount <= 0) {
            return FloatArray(0)
        }
        
        val mediaPlayer = MediaPlayer()
        try {
            mediaPlayer.setDataSource(audioFile.absolutePath)
            mediaPlayer.prepare()
            
            val duration = mediaPlayer.duration
            val waveform = FloatArray(sampleCount)
            val interval = duration / sampleCount
            
            // This is a simplified approach - in a real implementation,
            // you would need to process the actual audio data for accurate waveform
            // Here we're simulating by sampling at regular intervals
            for (i in 0 until sampleCount) {
                try {
                    // Seek to position
                    val position = i * interval
                    mediaPlayer.seekTo(position)
                    
                    // Get a simulated amplitude value
                    // In a real implementation, you would extract the actual audio data
                    val amplitude = Math.random().toFloat()
                    waveform[i] = amplitude
                } catch (e: Exception) {
                    waveform[i] = 0f
                }
            }
            
            return waveform
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error generating waveform data", e)
            return FloatArray(0)
        } finally {
            mediaPlayer.release()
        }
    }
    
    /**
     * Calculates a checksum for an audio file to verify integrity
     *
     * @param audioFile Audio file to calculate checksum for
     * @return Hexadecimal checksum string
     */
    fun calculateAudioChecksum(audioFile: File): String {
        if (!audioFile.exists()) return ""
        
        try {
            val digest = MessageDigest.getInstance("SHA-256")
            val buffer = ByteArray(8192)
            val inputStream = audioFile.inputStream()
            
            var read: Int
            while (inputStream.read(buffer).also { read = it } > 0) {
                digest.update(buffer, 0, read)
            }
            
            inputStream.close()
            
            // Convert to hex string
            val hexBytes = digest.digest()
            val hexString = StringBuilder()
            
            for (hexByte in hexBytes) {
                val hex = Integer.toHexString(0xff and hexByte.toInt())
                if (hex.length == 1) {
                    hexString.append('0')
                }
                hexString.append(hex)
            }
            
            return hexString.toString()
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error calculating audio checksum", e)
            return ""
        }
    }
    
    /**
     * Extracts metadata from an audio file
     *
     * @param audioFile Audio file to extract metadata from
     * @return Map of metadata key-value pairs
     */
    fun getAudioFileMetadata(audioFile: File): Map<String, String> {
        if (!audioFile.exists()) return emptyMap()
        
        val metadata = mutableMapOf<String, String>()
        val retriever = MediaMetadataRetriever()
        
        try {
            retriever.setDataSource(audioFile.absolutePath)
            
            // Extract common metadata
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.let {
                metadata["duration"] = it
            }
            
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.let {
                metadata["bitrate"] = it
            }
            
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)?.let {
                metadata["mimetype"] = it
            }
            
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE)?.let {
                metadata["date"] = it
            }
            
            // Add file information
            metadata["fileSize"] = audioFile.length().toString()
            metadata["fileName"] = audioFile.name
            metadata["filePath"] = audioFile.absolutePath
            
            return metadata
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error extracting audio metadata", e)
            return emptyMap()
        } finally {
            retriever.release()
        }
    }
    
    /**
     * Checks if an audio file is valid and playable
     *
     * @param audioFile Audio file to check
     * @return True if the file is valid, false otherwise
     */
    fun isAudioFileValid(audioFile: File): Boolean {
        if (!audioFile.exists() || audioFile.length() == 0L) {
            return false
        }
        
        val mediaPlayer = MediaPlayer()
        return try {
            mediaPlayer.setDataSource(audioFile.absolutePath)
            mediaPlayer.prepare() // If this succeeds, the file is valid
            true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Invalid audio file: ${audioFile.absolutePath}", e)
            false
        } finally {
            mediaPlayer.release()
        }
    }
    
    /**
     * Gets the size of an audio file in bytes
     *
     * @param audioFile Audio file to get size for
     * @return File size in bytes, 0 if error occurs
     */
    fun getAudioFileSizeBytes(audioFile: File): Long {
        return try {
            if (audioFile.exists()) {
                audioFile.length()
            } else {
                0
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error getting audio file size", e)
            0
        }
    }
}