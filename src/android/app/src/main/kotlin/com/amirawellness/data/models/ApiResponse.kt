package com.amirawellness.data.models

import kotlinx.serialization.Serializable // kotlinx.serialization 1.5.0
import kotlinx.serialization.SerialName // kotlinx.serialization 1.5.0

/**
 * A sealed class that wraps API responses, providing a standardized way to handle
 * both successful responses and errors. This enables consistent error handling
 * and type-safe response processing throughout the application.
 *
 * @param T The type of data expected in a successful response
 */
@Serializable
sealed class ApiResponse<T> {
    /**
     * Checks if the response is a success.
     *
     * @return True if this is a Success response, false otherwise
     */
    fun isSuccess(): Boolean = this is Success<*>

    /**
     * Checks if the response is an error.
     *
     * @return True if this is an Error response, false otherwise
     */
    fun isError(): Boolean = this is Error<*>

    /**
     * Gets the data if this is a success response, or null if it's an error.
     *
     * @return The data if successful, null otherwise
     */
    fun getOrNull(): T? = (this as? Success<T>)?.data

    /**
     * Gets the error if this is an error response, or null if it's a success.
     *
     * @return The error if this is an error response, null otherwise
     */
    fun getErrorOrNull(): ApiError? = (this as? Error<T>)?.error

    /**
     * Transforms the response based on whether it's a success or error.
     * This allows for concise handling of both cases with a single expression.
     *
     * @param onSuccess Function to apply if this is a success response
     * @param onError Function to apply if this is an error response
     * @return Result of applying the appropriate transformation
     */
    fun <R> fold(onSuccess: (T) -> R, onError: (ApiError) -> R): R {
        return when (this) {
            is Success -> onSuccess(data)
            is Error -> onError(error)
        }
    }
}

/**
 * Represents a successful API response with data.
 *
 * @param T The type of data contained in the response
 * @property data The response data
 */
@Serializable
@SerialName("success")
class Success<T>(
    val data: T
) : ApiResponse<T>()

/**
 * Represents an error API response with error details.
 *
 * @param T The type that would have been returned in a successful response
 * @property error The details about the error that occurred
 */
@Serializable
@SerialName("error")
class Error<T>(
    val error: ApiError
) : ApiResponse<T>() {
    /**
     * Gets the user-friendly error message.
     *
     * @return The error message
     */
    fun getErrorMessage(): String = error.message

    /**
     * Gets the error code.
     *
     * @return The error code
     */
    fun getErrorCode(): String = error.errorCode

    /**
     * Checks if this is a network-related error.
     *
     * @return True if this is a network error, false otherwise
     */
    fun isNetworkError(): Boolean = error.isNetworkError()

    /**
     * Checks if this is an authentication error.
     *
     * @return True if this is an authentication error, false otherwise
     */
    fun isAuthenticationError(): Boolean = error.isAuthenticationError()

    /**
     * Checks if this is a validation error.
     *
     * @return True if this is a validation error, false otherwise
     */
    fun isValidationError(): Boolean = error.isValidationError()
}