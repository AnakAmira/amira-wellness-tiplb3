package com.amirawellness.domain.usecases.auth

import com.amirawellness.data.models.User
import com.amirawellness.data.repositories.AuthRepository
import com.amirawellness.data.repositories.InvalidCredentialsException
import com.amirawellness.data.repositories.NetworkException
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations
import java.util.Date
import java.util.UUID

class LoginUseCaseTest {

    @Mock
    private lateinit var mockAuthRepository: AuthRepository
    
    private lateinit var loginUseCase: LoginUseCase
    
    private val testUser = User(
        id = UUID.randomUUID(),
        email = "test@example.com",
        emailVerified = true,
        createdAt = Date(),
        updatedAt = Date(),
        lastLogin = Date(),
        accountStatus = "active",
        subscriptionTier = "free",
        languagePreference = "es"
    )

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        loginUseCase = LoginUseCase(mockAuthRepository)
    }

    @Test
    fun testSuccessfulLogin() = runTest {
        // Arrange
        val email = "test@example.com"
        val password = "password123"
        `when`(mockAuthRepository.login(email, password)).thenReturn(Result.success(testUser))

        // Act
        val result = loginUseCase(email, password)

        // Assert
        assertTrue(result.isSuccess)
        assertEquals(testUser, result.getOrNull())
        verify(mockAuthRepository, times(1)).login(email, password)
    }

    @Test
    fun testInvalidEmail() = runTest {
        // Arrange
        val email = "invalid-email"
        val password = "password123"

        // Act
        val result = loginUseCase(email, password)

        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is InvalidEmailException)
        verify(mockAuthRepository, never()).login(any(), any())
    }

    @Test
    fun testEmptyPassword() = runTest {
        // Arrange
        val email = "test@example.com"
        val password = ""

        // Act
        val result = loginUseCase(email, password)

        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is EmptyPasswordException)
        verify(mockAuthRepository, never()).login(any(), any())
    }

    @Test
    fun testNetworkError() = runTest {
        // Arrange
        val email = "test@example.com"
        val password = "password123"
        `when`(mockAuthRepository.login(email, password)).thenReturn(Result.failure(NetworkException()))

        // Act
        val result = loginUseCase(email, password)

        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is NetworkException)
        verify(mockAuthRepository, times(1)).login(email, password)
    }

    @Test
    fun testInvalidCredentials() = runTest {
        // Arrange
        val email = "test@example.com"
        val password = "wrong-password"
        `when`(mockAuthRepository.login(email, password)).thenReturn(Result.failure(InvalidCredentialsException()))

        // Act
        val result = loginUseCase(email, password)

        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is InvalidCredentialsException)
        verify(mockAuthRepository, times(1)).login(email, password)
    }
}