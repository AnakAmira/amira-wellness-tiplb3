package com.amirawellness.core.utils

import android.content.Context
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.core.utils.LogUtils

/**
 * Utility class for content and file operations in the Amira Wellness application.
 * Provides functionality for managing tool content, exported files, and shared media.
 * Supports file operations, content loading, MIME type detection, and secure sharing.
 */
class ContentUtils private constructor() {
    // Private constructor to prevent instantiation
    init {
        throw IllegalStateException("ContentUtils is a utility class and should not be instantiated")
    }
    
    companion object {
        private const val TAG = "ContentUtils"
        private const val BUFFER_SIZE = 8192 // 8KB buffer size for file operations
        private const val DEFAULT_MIME_TYPE = "application/octet-stream"
        private const val AUTHORITY = "com.amirawellness.fileprovider"
        
        /**
         * Creates a directory if it doesn't exist
         *
         * @param context Application context
         * @param directoryName Name of the directory to create
         * @return The created or existing directory
         */
        fun createDirectory(context: Context, directoryName: String): File {
            val directory = File(context.getExternalFilesDir(null), directoryName)
            if (!directory.exists()) {
                val created = directory.mkdirs()
                LogUtils.d(TAG, "Directory creation result for $directoryName: $created")
            }
            return directory
        }
        
        /**
         * Gets or creates the export directory for the app
         *
         * @param context Application context
         * @return The export directory
         */
        fun getExportDirectory(context: Context): File {
            return createDirectory(context, AppConstants.FILE_PATHS.EXPORT_DIRECTORY)
        }
        
        /**
         * Gets or creates the cache directory for the app
         *
         * @param context Application context
         * @return The cache directory
         */
        fun getCacheDirectory(context: Context): File {
            return createDirectory(context, AppConstants.FILE_PATHS.CACHE_DIRECTORY)
        }
        
        /**
         * Gets or creates a temporary directory for the app
         *
         * @param context Application context
         * @return The temporary directory
         */
        fun getTempDirectory(context: Context): File {
            return createDirectory(context, AppConstants.FILE_PATHS.TEMP_DIRECTORY)
        }
        
        /**
         * Copies a file from source to destination
         *
         * @param sourceFile Source file to copy from
         * @param destFile Destination file to copy to
         * @return True if copy was successful, false otherwise
         */
        fun copyFile(sourceFile: File, destFile: File): Boolean {
            if (!sourceFile.exists()) {
                LogUtils.e(TAG, "Source file does not exist: ${sourceFile.absolutePath}")
                return false
            }
            
            var inputStream: FileInputStream? = null
            var outputStream: FileOutputStream? = null
            
            try {
                // Create parent directories if they don't exist
                destFile.parentFile?.mkdirs()
                
                inputStream = FileInputStream(sourceFile)
                outputStream = FileOutputStream(destFile)
                
                val buffer = ByteArray(BUFFER_SIZE)
                var bytesRead: Int
                
                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                }
                
                outputStream.flush()
                LogUtils.d(TAG, "File copied successfully from ${sourceFile.absolutePath} to ${destFile.absolutePath}")
                return true
            } catch (e: IOException) {
                LogUtils.e(TAG, "Error copying file: ${e.message}")
                return false
            } finally {
                try {
                    inputStream?.close()
                    outputStream?.close()
                } catch (e: IOException) {
                    LogUtils.e(TAG, "Error closing streams: ${e.message}")
                }
            }
        }
        
        /**
         * Copies content from a Uri to a destination file
         *
         * @param context Application context
         * @param sourceUri Source URI to copy from
         * @param destFile Destination file to copy to
         * @return True if copy was successful, false otherwise
         */
        fun copyUriToFile(context: Context, sourceUri: Uri, destFile: File): Boolean {
            val contentResolver: ContentResolver = context.contentResolver
            var inputStream: InputStream? = null
            var outputStream: FileOutputStream? = null
            
            try {
                inputStream = contentResolver.openInputStream(sourceUri)
                if (inputStream == null) {
                    LogUtils.e(TAG, "Cannot open input stream from Uri: $sourceUri")
                    return false
                }
                
                // Create parent directories if they don't exist
                destFile.parentFile?.mkdirs()
                
                outputStream = FileOutputStream(destFile)
                
                val buffer = ByteArray(BUFFER_SIZE)
                var bytesRead: Int
                
                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                }
                
                outputStream.flush()
                LogUtils.d(TAG, "Content copied successfully from $sourceUri to ${destFile.absolutePath}")
                return true
            } catch (e: IOException) {
                LogUtils.e(TAG, "Error copying from Uri to file: ${e.message}")
                return false
            } finally {
                try {
                    inputStream?.close()
                    outputStream?.close()
                } catch (e: IOException) {
                    LogUtils.e(TAG, "Error closing streams: ${e.message}")
                }
            }
        }
        
        /**
         * Safely deletes a file
         *
         * @param file File to delete
         * @return True if deletion was successful, false otherwise
         */
        fun deleteFile(file: File): Boolean {
            try {
                if (file.exists()) {
                    val deleted = file.delete()
                    LogUtils.d(TAG, "File deletion result for ${file.absolutePath}: $deleted")
                    return deleted
                }
                return false
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error deleting file ${file.absolutePath}: ${e.message}")
                return false
            }
        }
        
        /**
         * Clears all files in a directory
         *
         * @param directory Directory to clear
         * @return True if clearing was successful, false otherwise
         */
        fun clearDirectory(directory: File): Boolean {
            try {
                if (!directory.exists() || !directory.isDirectory) {
                    LogUtils.e(TAG, "Not a valid directory: ${directory.absolutePath}")
                    return false
                }
                
                var success = true
                val files = directory.listFiles()
                if (files != null) {
                    for (file in files) {
                        if (file.isDirectory) {
                            success = success && clearDirectory(file)
                            success = success && file.delete()
                        } else {
                            success = success && file.delete()
                        }
                    }
                }
                
                LogUtils.d(TAG, "Directory ${directory.absolutePath} cleared with result: $success")
                return success
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error clearing directory ${directory.absolutePath}: ${e.message}")
                return false
            }
        }
        
        /**
         * Gets the MIME type for a file based on its extension
         *
         * @param file File to get MIME type for
         * @return MIME type string
         */
        fun getMimeType(file: File): String {
            try {
                val extension = getFileExtension(file.name)
                if (extension.isNotEmpty()) {
                    val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                    if (mimeType != null) {
                        return mimeType
                    }
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error determining MIME type: ${e.message}")
            }
            return DEFAULT_MIME_TYPE
        }
        
        /**
         * Gets the MIME type for a file path based on its extension
         *
         * @param filePath Path of the file to get MIME type for
         * @return MIME type string
         */
        fun getMimeType(filePath: String): String {
            return getMimeType(File(filePath))
        }
        
        /**
         * Gets the file extension from a file name
         *
         * @param fileName File name to extract extension from
         * @return File extension without the dot, or empty string if none
         */
        fun getFileExtension(fileName: String): String {
            try {
                val lastDotIndex = fileName.lastIndexOf('.')
                if (lastDotIndex > 0) {
                    return fileName.substring(lastDotIndex + 1).lowercase()
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error extracting file extension: ${e.message}")
            }
            return ""
        }
        
        /**
         * Extracts the file name from a Uri
         *
         * @param context Application context
         * @param uri Uri to extract file name from
         * @return File name or null if not available
         */
        fun getFileNameFromUri(context: Context, uri: Uri): String? {
            var fileName: String? = null
            try {
                val contentResolver = context.contentResolver
                val cursor = contentResolver.query(uri, null, null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val displayNameIndex = it.getColumnIndex("_display_name")
                        if (displayNameIndex != -1) {
                            fileName = it.getString(displayNameIndex)
                        }
                    }
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error getting file name from Uri: ${e.message}")
            }
            return fileName
        }
        
        /**
         * Gets the size of a file in bytes
         *
         * @param file File to get size of
         * @return File size in bytes, 0 if error occurs
         */
        fun getFileSize(file: File): Long {
            try {
                if (file.exists()) {
                    return file.length()
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error getting file size: ${e.message}")
            }
            return 0
        }
        
        /**
         * Gets a content Uri for a file using FileProvider
         *
         * @param context Application context
         * @param file File to get Uri for
         * @return Content Uri for the file
         * @throws IllegalArgumentException if file cannot be shared
         */
        fun getUriForFile(context: Context, file: File): Uri {
            try {
                return FileProvider.getUriForFile(context, AUTHORITY, file)
            } catch (e: IllegalArgumentException) {
                LogUtils.e(TAG, "Error getting Uri for file: ${e.message}")
                throw IllegalArgumentException("File cannot be shared: ${file.absolutePath}", e)
            }
        }
        
        /**
         * Creates an intent for sharing a file
         *
         * @param context Application context
         * @param file File to share
         * @param title Optional title for share chooser
         * @return Share intent configured for the file
         * @throws IllegalArgumentException if file cannot be shared
         */
        fun createShareIntent(context: Context, file: File, title: String? = null): Intent {
            try {
                val contentUri = getUriForFile(context, file)
                val mimeType = getMimeType(file)
                
                val intent = Intent(Intent.ACTION_SEND)
                intent.type = mimeType
                intent.putExtra(Intent.EXTRA_STREAM, contentUri)
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                
                return Intent.createChooser(intent, title ?: "Share with")
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error creating share intent: ${e.message}")
                throw IllegalArgumentException("Error creating share intent", e)
            }
        }
        
        /**
         * Reads text content from an asset file
         *
         * @param context Application context
         * @param assetPath Path to the asset file
         * @return Text content of the asset file
         */
        fun readTextFromAsset(context: Context, assetPath: String): String {
            try {
                context.assets.open(assetPath).use { inputStream ->
                    return inputStream.bufferedReader().use { it.readText() }
                }
            } catch (e: IOException) {
                LogUtils.e(TAG, "Error reading text from asset: ${e.message}")
                return ""
            }
        }
        
        /**
         * Reads text content from a file
         *
         * @param file File to read from
         * @return Text content of the file
         */
        fun readTextFromFile(file: File): String {
            try {
                if (!file.exists()) {
                    LogUtils.e(TAG, "File does not exist: ${file.absolutePath}")
                    return ""
                }
                
                FileInputStream(file).use { inputStream ->
                    return inputStream.bufferedReader().use { it.readText() }
                }
            } catch (e: IOException) {
                LogUtils.e(TAG, "Error reading text from file: ${e.message}")
                return ""
            }
        }
        
        /**
         * Writes text content to a file
         *
         * @param file File to write to
         * @param content Text content to write
         * @param append Whether to append or overwrite
         * @return True if write was successful, false otherwise
         */
        fun writeTextToFile(file: File, content: String, append: Boolean = false): Boolean {
            try {
                // Create parent directories if they don't exist
                file.parentFile?.mkdirs()
                
                FileOutputStream(file, append).use { outputStream ->
                    outputStream.write(content.toByteArray())
                    outputStream.flush()
                }
                
                LogUtils.d(TAG, "Text written successfully to ${file.absolutePath}")
                return true
            } catch (e: IOException) {
                LogUtils.e(TAG, "Error writing text to file: ${e.message}")
                return false
            }
        }
        
        /**
         * Checks if external storage is available for write
         *
         * @return True if external storage is writable
         */
        fun isExternalStorageWritable(): Boolean {
            val state = android.os.Environment.getExternalStorageState()
            return android.os.Environment.MEDIA_MOUNTED == state
        }
        
        /**
         * Checks if external storage is at least readable
         *
         * @return True if external storage is readable
         */
        fun isExternalStorageReadable(): Boolean {
            val state = android.os.Environment.getExternalStorageState()
            return android.os.Environment.MEDIA_MOUNTED == state || 
                    android.os.Environment.MEDIA_MOUNTED_READ_ONLY == state
        }
        
        /**
         * Reads and returns JSON content from an asset file
         *
         * @param context Application context
         * @param assetPath Path to the JSON asset file
         * @return JSON content as string
         */
        fun getJsonFromAsset(context: Context, assetPath: String): String {
            return readTextFromAsset(context, assetPath)
        }
        
        /**
         * Caches a file in the app's cache directory
         *
         * @param context Application context
         * @param sourceFile Source file to cache
         * @param customFileName Optional custom file name for the cached file
         * @return Cached file or null if caching failed
         */
        fun cacheFile(context: Context, sourceFile: File, customFileName: String? = null): File? {
            try {
                val cacheDir = getCacheDirectory(context)
                val fileName = customFileName ?: sourceFile.name
                val cachedFile = File(cacheDir, fileName)
                
                if (copyFile(sourceFile, cachedFile)) {
                    LogUtils.d(TAG, "File cached successfully: ${cachedFile.absolutePath}")
                    return cachedFile
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error caching file: ${e.message}")
            }
            return null
        }
        
        /**
         * Clears the app's cache directory
         *
         * @param context Application context
         * @return True if cache was cleared successfully
         */
        fun clearCache(context: Context): Boolean {
            try {
                val cacheDir = getCacheDirectory(context)
                val result = clearDirectory(cacheDir)
                LogUtils.d(TAG, "Cache cleared with result: $result")
                return result
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error clearing cache: ${e.message}")
                return false
            }
        }
    }
}