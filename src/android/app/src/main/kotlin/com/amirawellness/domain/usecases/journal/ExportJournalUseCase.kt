package com.amirawellness.domain.usecases.journal

import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import com.amirawellness.data.models.Journal
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.services.encryption.EncryptionManager
import com.amirawellness.core.utils.AudioUtils
import com.amirawellness.core.utils.LogUtils

private const val TAG = "ExportJournalUseCase"

/**
 * Enum defining supported export formats for journal audio recordings
 */
enum class ExportFormat {
    MP3,
    AAC,
    WAV,
    ENCRYPTED
}

/**
 * Use case for exporting journal audio recordings to external formats
 * Handles decryption, format conversion, and file operations while maintaining privacy and security
 */
class ExportJournalUseCase @Inject constructor(
    private val journalRepository: JournalRepository
) {
    private val encryptionManager = EncryptionManager.getInstance()

    /**
     * Exports a journal audio recording to the specified format and destination
     * 
     * @param journal The journal entry to export
     * @param destinationFile The destination file for the exported audio
     * @param format The desired export format
     * @return Result containing the destination file if successful, or an error
     */
    suspend operator fun invoke(journal: Journal, destinationFile: File, format: ExportFormat): Result<File> {
        LogUtils.d(TAG, "Exporting journal ${journal.id} to format $format")
        
        // Validate journal has a local file
        if (!validateJournal(journal)) {
            return Result.failure(IllegalStateException("Journal cannot be exported: no local file or file doesn't exist"))
        }
        
        return try {
            // Create a temporary file for the decrypted audio
            val tempDir = File(destinationFile.parent, "temp").apply { mkdirs() }
            val tempDecryptedFile = File(tempDir, "decrypted_${System.currentTimeMillis()}.aac")
            
            // Decrypt the journal audio
            val decryptResult = journalRepository.decryptJournalAudio(
                journal.id,
                File(journal.localFilePath!!),
                tempDecryptedFile,
                journal.encryptionIv!!
            )
            
            val decryptedFile = decryptResult.getOrElse {
                LogUtils.e(TAG, "Failed to decrypt journal audio", it)
                return Result.failure(it)
            }
            
            // Convert the audio to the requested format if needed
            val finalFile = if (format != ExportFormat.AAC) {
                val convertResult = convertAudioFormat(decryptedFile, format)
                
                convertResult.getOrElse {
                    LogUtils.e(TAG, "Failed to convert audio format", it)
                    // Clean up temp file
                    tempDecryptedFile.delete()
                    return Result.failure(it)
                }
            } else {
                decryptedFile
            }
            
            // Copy the final file to the destination
            val copyResult = copyFile(finalFile, destinationFile)
            
            // Clean up temporary files
            val tempFiles = mutableListOf(tempDecryptedFile)
            if (finalFile != tempDecryptedFile) {
                tempFiles.add(finalFile)
            }
            cleanupTempFiles(tempFiles)
            
            copyResult.getOrElse {
                LogUtils.e(TAG, "Failed to copy file to destination", it)
                return Result.failure(it)
            }
            
            LogUtils.d(TAG, "Journal exported successfully to ${destinationFile.absolutePath}")
            Result.success(destinationFile)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error exporting journal", e)
            Result.failure(e)
        }
    }

    /**
     * Validates that a journal has the required data for export
     *
     * @param journal The journal to validate
     * @return True if the journal is valid for export, false otherwise
     */
    private fun validateJournal(journal: Journal): Boolean {
        // Check if journal has a local file path
        if (journal.localFilePath.isNullOrEmpty()) {
            LogUtils.e(TAG, "Journal ${journal.id} has no local file path")
            return false
        }
        
        // Check if the file exists
        val file = File(journal.localFilePath)
        if (!file.exists()) {
            LogUtils.e(TAG, "Journal file does not exist: ${journal.localFilePath}")
            return false
        }
        
        return true
    }

    /**
     * Converts an audio file to the specified format
     *
     * @param sourceFile The source audio file
     * @param format The desired output format
     * @return Result containing the converted file if successful, or an error
     */
    private suspend fun convertAudioFormat(sourceFile: File, format: ExportFormat): Result<File> {
        return withContext(Dispatchers.IO) {
            val outputFile = File(
                sourceFile.parentFile,
                "${sourceFile.nameWithoutExtension}_converted.${format.toString().lowercase()}"
            )
            
            try {
                // Use AudioUtils to convert the file
                AudioUtils.convertAudioFormat(sourceFile, outputFile)
                Result.success(outputFile)
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error converting audio format", e)
                Result.failure(e)
            }
        }
    }

    /**
     * Copies a file to the destination path
     *
     * @param sourceFile The source file
     * @param destinationFile The destination file
     * @return Result containing the destination file if successful, or an error
     */
    private fun copyFile(sourceFile: File, destinationFile: File): Result<File> {
        return try {
            // Create parent directories if they don't exist
            destinationFile.parentFile?.mkdirs()
            
            // Copy the file
            sourceFile.inputStream().use { input ->
                destinationFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            Result.success(destinationFile)
        } catch (e: IOException) {
            LogUtils.e(TAG, "Error copying file", e)
            Result.failure(e)
        }
    }

    /**
     * Cleans up temporary files created during export
     *
     * @param tempFiles The list of temporary files to clean up
     */
    private fun cleanupTempFiles(tempFiles: List<File>) {
        for (file in tempFiles) {
            try {
                if (file.exists()) {
                    file.delete()
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error deleting temporary file: ${file.absolutePath}", e)
                // Continue cleanup process even if one file fails to delete
            }
        }
    }
}