package com.amirawellness.domain.usecases.auth

import android.util.Patterns
import com.amirawellness.data.models.User
import com.amirawellness.data.repositories.AuthRepository
import javax.inject.Inject

/**
 * Use case for registering a new user with email, password, and language preference.
 * This class follows the clean architecture pattern, encapsulating the business logic
 * for user registration and validation before delegating to the repository layer.
 */
class RegisterUseCase @Inject constructor(private val authRepository: AuthRepository) {

    /**
     * Executes the registration use case with the provided credentials.
     *
     * @param email User's email address
     * @param password User's password
     * @param passwordConfirm Password confirmation to verify
     * @param languagePreference User's preferred language (default: Spanish)
     * @return Result containing User on success or an exception on failure
     */
    suspend operator fun invoke(
        email: String,
        password: String,
        passwordConfirm: String,
        languagePreference: String = "es"
    ): Result<User> {
        // First validate the registration data
        val validationResult = validateRegistrationData(email, password, passwordConfirm)
        if (validationResult.isFailure) {
            return validationResult.mapCatching { throw it!! }
        }

        // If validation passes, delegate to repository for registration
        return authRepository.register(
            email = email,
            password = password,
            passwordConfirm = passwordConfirm,
            languagePreference = languagePreference
        )
    }

    /**
     * Validates the registration data before attempting registration.
     *
     * @param email User's email address to validate
     * @param password User's password to validate
     * @param passwordConfirm Password confirmation to check
     * @return Result containing Unit on success or an exception on failure
     */
    private fun validateRegistrationData(
        email: String,
        password: String,
        passwordConfirm: String
    ): Result<Unit> {
        // Validate email format
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            return Result.failure(InvalidEmailException())
        }

        // Validate password is not empty
        if (password.isEmpty()) {
            return Result.failure(EmptyPasswordException())
        }

        // Validate password strength (minimum 8 characters)
        if (password.length < 8) {
            return Result.failure(WeakPasswordException())
        }

        // Validate password confirmation matches
        if (password != passwordConfirm) {
            return Result.failure(PasswordMismatchException())
        }

        // All validations passed
        return Result.success(Unit)
    }
}

/**
 * Exception thrown when an invalid email format is provided.
 */
class InvalidEmailException : Exception("Invalid email format")

/**
 * Exception thrown when an empty password is provided.
 */
class EmptyPasswordException : Exception("Password cannot be empty")

/**
 * Exception thrown when a password doesn't meet minimum strength requirements.
 */
class WeakPasswordException : Exception("Password must be at least 8 characters long")

/**
 * Exception thrown when password and confirmation password don't match.
 */
class PasswordMismatchException : Exception("Passwords do not match")