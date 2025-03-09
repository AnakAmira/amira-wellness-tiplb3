package com.amirawellness.data.remote.api

import android.content.Context
import com.google.gson.Gson // com.google.gson 2.9.0
import retrofit2.HttpException // retrofit2 2.9.0
import java.io.IOException // standard library
import java.net.SocketTimeoutException // standard library
import java.net.UnknownHostException // standard library
import javax.inject.Inject // javax.inject 1
import javax.inject.Singleton // javax.inject 1
import com.amirawellness.core.constants.ApiConstants
import com.amirawellness.data.models.ApiError
import com.amirawellness.data.models.ErrorCategory
import com.amirawellness.core.utils.LogUtils

private const val TAG = "ErrorHandler"

/**
 * Handles API and network errors by converting exceptions into standardized ApiError objects.
 * This provides a consistent error handling mechanism across the application.
 */
@Singleton
class ErrorHandler @Inject constructor(private val context: Context) {
    private val gson = Gson()

    /**
     * Converts an exception into a standardized ApiError object
     *
     * @param throwable The exception to convert
     * @return Standardized API error object
     */
    fun handleException(throwable: Throwable): ApiError {
        LogUtils.logError(TAG, "Error occurred: ${throwable.message}", throwable)

        return when (throwable) {
            is HttpException -> parseHttpError(throwable)
            is SocketTimeoutException -> createTimeoutError(throwable.message)
            is UnknownHostException -> createNetworkError("Unable to reach server. Please check your connection.")
            is IOException -> createNetworkError(throwable.message)
            else -> createSystemError("An unexpected error occurred", throwable)
        }
    }

    /**
     * Parses an HTTP error response into an ApiError object
     *
     * @param exception The HTTP exception to parse
     * @return Parsed API error object
     */
    fun parseHttpError(exception: HttpException): ApiError {
        val code = exception.code()
        val errorBody = exception.response()?.errorBody()?.string()

        return try {
            if (!errorBody.isNullOrBlank()) {
                // Try to parse the error body as ApiError
                gson.fromJson(errorBody, ApiError::class.java)
            } else {
                // Create error based on HTTP status code
                when (code) {
                    401 -> ApiError(
                        errorCode = ApiConstants.ErrorCodes.UNAUTHORIZED.toString(),
                        message = "Authentication required",
                        category = ErrorCategory.AUTHENTICATION,
                        details = mapOf("httpStatus" to code)
                    )
                    403 -> ApiError(
                        errorCode = ApiConstants.ErrorCodes.FORBIDDEN.toString(),
                        message = "You don't have permission to access this resource",
                        category = ErrorCategory.AUTHENTICATION,
                        details = mapOf("httpStatus" to code)
                    )
                    404 -> ApiError(
                        errorCode = ApiConstants.ErrorCodes.NOT_FOUND.toString(),
                        message = "The requested resource was not found",
                        category = ErrorCategory.RESOURCE,
                        details = mapOf("httpStatus" to code)
                    )
                    in 400..499 -> ApiError(
                        errorCode = ApiConstants.ErrorCodes.BAD_REQUEST.toString(),
                        message = "Invalid request",
                        category = ErrorCategory.VALIDATION,
                        details = mapOf("httpStatus" to code)
                    )
                    in 500..599 -> ApiError(
                        errorCode = ApiConstants.ErrorCodes.INTERNAL_SERVER_ERROR.toString(),
                        message = "Server error occurred",
                        category = ErrorCategory.SYSTEM,
                        details = mapOf("httpStatus" to code)
                    )
                    else -> ApiError(
                        errorCode = code.toString(),
                        message = "HTTP Error: $code",
                        category = ErrorCategory.SYSTEM,
                        details = mapOf("httpStatus" to code)
                    )
                }
            }
        } catch (e: Exception) {
            LogUtils.logError(TAG, "Error parsing HTTP error response", e)
            createSystemError("Error processing server response", e)
        }
    }

    /**
     * Creates a network connectivity error
     *
     * @param message Optional error message
     * @return Network error object
     */
    fun createNetworkError(message: String?): ApiError {
        return ApiError(
            errorCode = ApiConstants.ErrorCodes.NETWORK_ERROR.toString(),
            message = message ?: "Network connection error. Please check your internet connection.",
            category = ErrorCategory.EXTERNAL,
            details = mapOf(
                "errorType" to "network",
                "originalMessage" to (message ?: "No message")
            )
        )
    }

    /**
     * Creates a timeout error
     *
     * @param message Optional error message
     * @return Timeout error object
     */
    fun createTimeoutError(message: String?): ApiError {
        return ApiError(
            errorCode = ApiConstants.ErrorCodes.TIMEOUT_ERROR.toString(),
            message = message ?: "Request timed out. Please try again.",
            category = ErrorCategory.EXTERNAL,
            details = mapOf(
                "errorType" to "timeout",
                "originalMessage" to (message ?: "No message")
            )
        )
    }

    /**
     * Creates a system error for unexpected exceptions
     *
     * @param message Error message
     * @param throwable The original exception
     * @return System error object
     */
    fun createSystemError(message: String, throwable: Throwable): ApiError {
        val stackTrace = throwable.stackTrace.take(5).joinToString("\n") { it.toString() }
        
        return ApiError(
            errorCode = ApiConstants.ErrorCodes.UNKNOWN_ERROR.toString(),
            message = message.ifBlank { "An unexpected error occurred" },
            category = ErrorCategory.SYSTEM,
            details = mapOf(
                "errorType" to "system",
                "exceptionClass" to throwable.javaClass.name,
                "stackTrace" to stackTrace
            )
        )
    }
}

/**
 * Singleton provider for ErrorHandler instance.
 * Maintains a single instance of ErrorHandler across the application.
 */
object ErrorHandlerProvider {
    private var instance: ErrorHandler? = null

    /**
     * Gets or creates the singleton ErrorHandler instance
     *
     * @param context Android context needed for ErrorHandler
     * @return The singleton ErrorHandler instance
     */
    fun getInstance(context: Context): ErrorHandler {
        if (instance == null) {
            instance = ErrorHandler(context)
        }
        return instance!!
    }

    /**
     * Resets the singleton instance (for testing purposes)
     */
    fun resetInstance() {
        instance = null
    }
}