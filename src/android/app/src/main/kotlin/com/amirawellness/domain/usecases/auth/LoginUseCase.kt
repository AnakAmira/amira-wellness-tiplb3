package com.amirawellness.domain.usecases.auth

import android.util.Patterns // version: latest
import com.amirawellness.data.models.User
import com.amirawellness.data.repositories.AuthRepository
import javax.inject.Inject // version: 1

/**
 * Use case implementation for user authentication in the Amira Wellness Android application.
 * This class follows the clean architecture pattern and encapsulates the business logic for user login,
 * providing a single responsibility component that validates credentials before delegating to the repository layer.
 */
class LoginUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Executes the login use case with the provided credentials.
     * Validates email format and password presence before attempting authentication.
     *
     * @param email The user's email address
     * @param password The user's password
     * @return Result containing User on success or an exception on failure
     */
    suspend operator fun invoke(email: String, password: String): Result<User> {
        // Validate credentials first
        val validationResult = validateCredentials(email, password)
        if (validationResult.isFailure) {
            return validationResult.map { User::class.java.newInstance() } as Result<User>
        }

        // Delegate to repository for actual authentication
        return authRepository.login(email, password)
    }

    /**
     * Validates the login credentials before attempting authentication.
     * Checks email format using Android's Patterns utility and ensures password is not empty.
     *
     * @param email The email to validate
     * @param password The password to validate
     * @return Result.success if valid, or Result.failure with appropriate exception if invalid
     */
    private fun validateCredentials(email: String, password: String): Result<Unit> {
        // Validate email format
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            return Result.failure(InvalidEmailException())
        }

        // Validate password (non-empty)
        if (password.isEmpty()) {
            return Result.failure(EmptyPasswordException())
        }

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