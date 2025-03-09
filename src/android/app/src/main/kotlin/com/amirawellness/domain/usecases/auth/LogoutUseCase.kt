package com.amirawellness.domain.usecases.auth

import com.amirawellness.data.repositories.AuthRepository
import javax.inject.Inject // version: 1

/**
 * Use case for handling user logout functionality in the Amira Wellness application.
 * This class encapsulates the business logic for the logout process following clean architecture principles.
 * 
 * It delegates to the [AuthRepository] to perform the actual logout operation, which includes:
 * - Invalidating tokens on the server when online
 * - Clearing local authentication tokens
 * - Removing user data from local storage
 * 
 * This separation of concerns enables better testability and modular code structure.
 */
class LogoutUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Executes the logout operation.
     * 
     * This is implemented as a suspend operator function that can be directly invoked on the
     * use case instance. It handles the logout process and returns a Result indicating
     * success or failure.
     * 
     * @return A Result containing Unit on success or an exception on failure
     */
    suspend operator fun invoke(): Result<Unit> {
        return authRepository.logout()
    }
}