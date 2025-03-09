package com.amirawellness.core.utils

import android.util.Log // android version: latest
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.config.EnvironmentConfigProvider
import com.amirawellness.config.AppConfigProvider
import java.io.File // java.io version: latest
import java.io.FileWriter // java.io version: latest
import java.io.PrintWriter // java.io version: latest
import java.text.SimpleDateFormat // java.text version: latest
import java.util.Date // java.util version: latest
import java.util.Locale // java.util version: latest

/**
 * LogUtils
 *
 * Provides centralized logging utilities for the Amira Wellness Android application 
 * with privacy-aware logging, configurable log levels based on environment, and 
 * standardized log formatting. This utility ensures consistent logging practices
 * across the application while protecting sensitive user data.
 */

private const val TAG = "LogUtils"
private val SENSITIVE_PATTERNS = listOf("password", "token", "secret", "auth", "key", "credential", "email", "phone")
private val DATE_FORMAT = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault())
private var fileLoggingEnabled = false
private var logFilePath: String? = null

/**
 * Initializes the logging system with application-specific configuration
 */
fun initialize() {
    try {
        // Check if logging is enabled in the current environment
        val environmentConfig = EnvironmentConfigProvider.getInstance()
        
        // Set up file logging if enabled
        if (environmentConfig.loggingEnabled) {
            val appConfig = AppConfigProvider.getInstance()
            if (appConfig.isDebugLoggingEnabled) {
                // Create log directory if it doesn't exist
                val logDir = File(AppConstants.FILE_PATHS.getExternalStorageDirectory(), 
                                 AppConstants.FILE_PATHS.LOGS_DIRECTORY)
                if (!logDir.exists()) {
                    logDir.mkdirs()
                }
                
                // Set the log file path
                logFilePath = "${logDir.absolutePath}/app_log_${SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(Date())}.log"
                fileLoggingEnabled = true
                
                i(TAG, "Logging initialized with file logging enabled: $logFilePath")
            } else {
                i(TAG, "Logging initialized with file logging disabled")
            }
        } else {
            // Minimal logging when disabled in environment
            Log.i(TAG, "Logging disabled for current environment")
        }
    } catch (e: Exception) {
        // Always log initialization errors
        Log.e(TAG, "Error initializing logging system", e)
    }
}

/**
 * Logs a message with VERBOSE priority if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @return Result code from Android Log
 */
fun v(tag: String, message: String): Int {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.VERBOSE) {
        return 0
    }
    
    writeToLogFile("VERBOSE", tag, message, null)
    return Log.v(tag, message)
}

/**
 * Logs a message with DEBUG priority if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @return Result code from Android Log
 */
fun d(tag: String, message: String): Int {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.DEBUG) {
        return 0
    }
    
    writeToLogFile("DEBUG", tag, message, null)
    return Log.d(tag, message)
}

/**
 * Logs a message with INFO priority if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @return Result code from Android Log
 */
fun i(tag: String, message: String): Int {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.INFO) {
        return 0
    }
    
    writeToLogFile("INFO", tag, message, null)
    return Log.i(tag, message)
}

/**
 * Logs a message with WARN priority if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @return Result code from Android Log
 */
fun w(tag: String, message: String): Int {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.WARN) {
        return 0
    }
    
    writeToLogFile("WARN", tag, message, null)
    return Log.w(tag, message)
}

/**
 * Logs a message with ERROR priority if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @return Result code from Android Log
 */
fun e(tag: String, message: String): Int {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.ERROR) {
        return 0
    }
    
    writeToLogFile("ERROR", tag, message, null)
    return Log.e(tag, message)
}

/**
 * Logs an error message with exception details if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @param throwable The exception to log
 * @return Result code from Android Log
 */
fun e(tag: String, message: String, throwable: Throwable): Int {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.ERROR) {
        return 0
    }
    
    writeToLogFile("ERROR", tag, message, throwable)
    return Log.e(tag, message, throwable)
}

/**
 * Logs a message with ASSERT priority (What a Terrible Failure) if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @return Result code from Android Log
 */
fun wtf(tag: String, message: String): Int {
    // Always log WTF messages regardless of environment
    writeToLogFile("WTF", tag, message, null)
    return Log.wtf(tag, message)
}

/**
 * Logs an assert message with exception details if logging is enabled
 *
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @param throwable The exception to log
 * @return Result code from Android Log
 */
fun wtf(tag: String, message: String, throwable: Throwable): Int {
    // Always log WTF messages regardless of environment
    writeToLogFile("WTF", tag, message, throwable)
    return Log.wtf(tag, message, throwable)
}

/**
 * Logs API request details with privacy protection
 *
 * @param url The API endpoint URL
 * @param method The HTTP method (GET, POST, etc.)
 * @param headers The request headers
 * @param body The request body (optional)
 */
fun logApiRequest(url: String, method: String, headers: Map<String, String>, body: String?) {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.DEBUG) {
        return
    }
    
    try {
        // Sanitize the request URL to remove sensitive query parameters
        val sanitizedUrl = sanitizeData(url)
        
        // Sanitize the headers to mask sensitive values
        val sanitizedHeaders = headers.mapValues { (key, value) ->
            if (SENSITIVE_PATTERNS.any { pattern -> key.lowercase().contains(pattern) }) {
                "[REDACTED]"
            } else {
                value
            }
        }
        
        // Sanitize the request body to mask sensitive data
        val sanitizedBody = body?.let { sanitizeData(it) } ?: "null"
        
        // Format the request information into a structured log message
        val requestLog = """
            API Request:
            URL: $sanitizedUrl
            Method: $method
            Headers: $sanitizedHeaders
            Body: $sanitizedBody
        """.trimIndent()
        
        // Log the sanitized request with DEBUG level
        d("API_REQUEST", requestLog)
    } catch (e: Exception) {
        e("API_REQUEST", "Error logging API request", e)
    }
}

/**
 * Logs API response details with privacy protection
 *
 * @param url The API endpoint URL
 * @param statusCode The HTTP status code
 * @param headers The response headers
 * @param body The response body (optional)
 * @param durationMs The request duration in milliseconds
 */
fun logApiResponse(url: String, statusCode: Int, headers: Map<String, String>, body: String?, durationMs: Long) {
    if (!isLoggingEnabled() || 
        EnvironmentConfigProvider.getInstance().getLogLevel() > Log.DEBUG) {
        return
    }
    
    try {
        // Sanitize the response URL to remove sensitive query parameters
        val sanitizedUrl = sanitizeData(url)
        
        // Sanitize the headers to mask sensitive values
        val sanitizedHeaders = headers.mapValues { (key, value) ->
            if (SENSITIVE_PATTERNS.any { pattern -> key.lowercase().contains(pattern) }) {
                "[REDACTED]"
            } else {
                value
            }
        }
        
        // Sanitize the response body to mask sensitive data
        val sanitizedBody = body?.let { sanitizeData(it) } ?: "null"
        
        // Format the response information into a structured log message
        val responseLog = """
            API Response:
            URL: $sanitizedUrl
            Status: $statusCode
            Duration: ${durationMs}ms
            Headers: $sanitizedHeaders
            Body: $sanitizedBody
        """.trimIndent()
        
        // Include the request duration in milliseconds
        // Log the sanitized response with DEBUG level
        d("API_RESPONSE", responseLog)
    } catch (e: Exception) {
        e("API_RESPONSE", "Error logging API response", e)
    }
}

/**
 * Sanitizes data to remove or mask sensitive information before logging
 *
 * @param data The data to sanitize
 * @return Sanitized data safe for logging
 */
fun sanitizeData(data: String): String {
    if (data.isBlank()) {
        return data
    }
    
    var sanitizedData = data
    
    // For each sensitive pattern in SENSITIVE_PATTERNS
    SENSITIVE_PATTERNS.forEach { pattern ->
        // Match pattern in JSON fields or URL parameters
        val regex = "\"$pattern\"\\s*:\\s*\"[^\"]*\"".toRegex()
        sanitizedData = sanitizedData.replace(regex, "\"$pattern\":\"[REDACTED]\"")
        
        // URL parameter pattern
        val urlParamRegex = "($pattern=[^&]*)".toRegex(RegexOption.IGNORE_CASE)
        sanitizedData = sanitizedData.replace(urlParamRegex, "$pattern=[REDACTED]")
    }
    
    return sanitizedData
}

/**
 * Writes a log entry to the log file if file logging is enabled
 *
 * @param level The log level (VERBOSE, DEBUG, etc.)
 * @param tag Identifying tag for the log message
 * @param message The message to log
 * @param throwable The exception to log (optional)
 * @return True if successfully written, false otherwise
 */
private fun writeToLogFile(level: String, tag: String, message: String, throwable: Throwable?): Boolean {
    if (!fileLoggingEnabled || logFilePath == null) {
        return false
    }
    
    try {
        val timestamp = DATE_FORMAT.format(Date())
        val logFile = File(logFilePath!!)
        
        // Ensure log directory exists
        logFile.parentFile?.mkdirs()
        
        // Format the log entry with timestamp, level, tag, and message
        val logEntry = StringBuilder()
            .append("$timestamp | $level | $tag | $message")
        
        // If throwable is not null, include the exception details
        throwable?.let { t ->
            logEntry.append("\n")
                .append("Exception: ${t.javaClass.name}: ${t.message}")
                .append("\nStacktrace:\n")
            t.stackTrace.take(10).forEach { // Limit stacktrace to 10 lines
                logEntry.append("  at ${it}\n")
            }
        }
        logEntry.append("\n")
        
        // Append the formatted entry to the log file
        FileWriter(logFile, true).use { writer ->
            writer.append(logEntry.toString())
        }
        
        return true
    } catch (e: Exception) {
        // Don't try to log this error to the file (could cause infinite recursion)
        Log.e(TAG, "Error writing to log file", e)
        return false
    }
}

/**
 * Gets the current log file path
 *
 * @return The current log file path or null if not set
 */
fun getLogFilePath(): String? {
    return logFilePath
}

/**
 * Enables or disables file logging
 *
 * @param enabled True to enable file logging, false to disable
 */
fun setFileLoggingEnabled(enabled: Boolean) {
    fileLoggingEnabled = enabled
    
    // If enabling file logging and log file path is not set, initialize it
    if (enabled && logFilePath == null) {
        val logDir = File(AppConstants.FILE_PATHS.getExternalStorageDirectory(), 
                         AppConstants.FILE_PATHS.LOGS_DIRECTORY)
        if (!logDir.exists()) {
            logDir.mkdirs()
        }
        logFilePath = "${logDir.absolutePath}/app_log_${SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(Date())}.log"
    }
    
    // Log the change in file logging status
    i(TAG, "File logging ${if (enabled) "enabled" else "disabled"}")
}

/**
 * Clears the current log file
 *
 * @return True if successfully cleared, false otherwise
 */
fun clearLogFile(): Boolean {
    val path = logFilePath ?: return false
    
    try {
        val logFile = File(path)
        if (logFile.exists()) {
            // Truncate the file to zero length
            PrintWriter(logFile).close()
            i(TAG, "Log file cleared: $path")
            return true
        }
    } catch (e: Exception) {
        Log.e(TAG, "Error clearing log file", e)
    }
    return false
}

/**
 * Checks if logging is enabled for the current environment
 *
 * @return True if logging is enabled, false otherwise
 */
fun isLoggingEnabled(): Boolean {
    return try {
        // Get the environment configuration
        val environmentConfig = EnvironmentConfigProvider.getInstance()
        
        // Check if logging is enabled in the current environment
        environmentConfig.loggingEnabled
    } catch (e: Exception) {
        // Default to true for debugging initialization issues
        Log.e(TAG, "Error checking if logging is enabled", e)
        AppConstants.DEBUG_LOGGING_ENABLED
    }
}