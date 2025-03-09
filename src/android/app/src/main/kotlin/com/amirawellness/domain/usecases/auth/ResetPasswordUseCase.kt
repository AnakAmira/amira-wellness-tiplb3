package com.amirawellness.domain.usecases.auth

import android.util.Patterns
import com.amirawellness.data.repositories.AuthRepository
import javax.inject.Inject

/**
 * Use case for initiating a password reset process for a user account.
 * This class follows the clean architecture pattern by encapsulating the business logic
 * for password reset operations and providing a clear boundary between
 * the domain and data layers.
 */
class ResetPasswordUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Executes the password reset use case with the provided email.
     * Validates the email format before delegating to the repository layer.
     *
     * @param email The email address for which to reset the password
     * @return Result containing Unit on success or an exception on failure
     */
    suspend operator fun invoke(email: String): Result<Unit> {
        // First validate the email format
        val validationResult = validateEmail(email)
        if (validationResult.isFailure) {
            return validationResult
        }
        
        // If email is valid, delegate to the repository
        return authRepository.resetPassword(email)
    }
    
    /**
     * Validates the email address before attempting password reset.
     * Uses Android's Patterns utility for standard email format validation.
     *
     * @param email The email address to validate
     * @return Result with success if valid, or failure with InvalidEmailException if invalid
     */
    private fun validateEmail(email: String): Result<Unit> {
        return if (Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            Result.success(Unit)
        } else {
            Result.failure(InvalidEmailException())
        }
    }
}

/**
 * Exception thrown when an invalid email format is provided.
 * This provides a clear error message for presentation to the user.
 */
class InvalidEmailException : Exception("Invalid email format")