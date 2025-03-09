package com.amirawellness.data.models

import kotlinx.serialization.Serializable // kotlinx.serialization 1.5.0
import kotlinx.serialization.SerialName // kotlinx.serialization 1.5.0

/**
 * Data class representing an API error response with standardized fields.
 * This model encapsulates error details including error code, message, category,
 * and additional details to enable consistent error handling across the application.
 *
 * @property errorCode A unique identifier for the error
 * @property message A human-readable error message
 * @property category The error category (see [ErrorCategory])
 * @property details Optional map of additional error details
 */
@Serializable
data class ApiError(
    @SerialName("error_code")
    val errorCode: String,
    
    @SerialName("message")
    val message: String,
    
    @SerialName("category")
    val category: String,
    
    @SerialName("details")
    val details: Map<String, Any>? = null
) {
    /**
     * Checks if this is a network-related error.
     *
     * @return True if this is a network error, false otherwise
     */
    fun isNetworkError(): Boolean {
        return errorCode.startsWith("EXT_") && errorCode.contains("NETWORK")
    }

    /**
     * Checks if this is an authentication error.
     *
     * @return True if this is an authentication error, false otherwise
     */
    fun isAuthenticationError(): Boolean {
        return category == ErrorCategory.AUTHENTICATION
    }

    /**
     * Checks if this is a validation error.
     *
     * @return True if this is a validation error, false otherwise
     */
    fun isValidationError(): Boolean {
        return category == ErrorCategory.VALIDATION
    }

    /**
     * Checks if this is a resource error (e.g., not found).
     *
     * @return True if this is a resource error, false otherwise
     */
    fun isResourceError(): Boolean {
        return category == ErrorCategory.RESOURCE
    }

    /**
     * Checks if this is a system error.
     *
     * @return True if this is a system error, false otherwise
     */
    fun isSystemError(): Boolean {
        return category == ErrorCategory.SYSTEM
    }

    /**
     * Gets a specific detail value by key with type casting.
     *
     * @param key The key to look up in the details map
     * @return The value for the specified key cast to type T, or null if not found
     */
    inline fun <reified T> getDetailValue(key: String): T? {
        return if (details?.containsKey(key) == true) {
            details[key] as? T
        } else {
            null
        }
    }
}

/**
 * Object containing constants for error categories.
 * Provides standardized categories for classifying API errors.
 */
object ErrorCategory {
    /**
     * Authentication errors such as invalid credentials or expired tokens
     */
    const val AUTHENTICATION = "authentication"

    /**
     * Authorization errors such as insufficient permissions
     */
    const val AUTHORIZATION = "authorization"

    /**
     * Validation errors such as invalid input data
     */
    const val VALIDATION = "validation"

    /**
     * Resource errors such as not found or already exists
     */
    const val RESOURCE = "resource"

    /**
     * Business logic errors specific to the application domain
     */
    const val BUSINESS = "business"

    /**
     * System errors such as internal server errors
     */
    const val SYSTEM = "system"

    /**
     * Errors from external services or dependencies
     */
    const val EXTERNAL = "external"

    /**
     * Encryption-related errors such as key management issues
     */
    const val ENCRYPTION = "encryption"
}