package com.amirawellness.domain.usecases.auth

import com.amirawellness.data.models.User
import com.amirawellness.data.repositories.AuthRepository
import com.amirawellness.data.repositories.NetworkException
import com.amirawellness.data.repositories.UserAlreadyExistsException
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations
import java.util.Date
import java.util.UUID

class RegisterUseCaseTest {

    @Mock
    private lateinit var mockAuthRepository: AuthRepository
    
    private lateinit var registerUseCase: RegisterUseCase
    
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
    
    private val validEmail = "test@example.com"
    private val validPassword = "Password123"
    private val validLanguagePreference = "es"
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        registerUseCase = RegisterUseCase(mockAuthRepository)
    }
    
    @Test
    fun testSuccessfulRegistration() = runTest {
        // Arrange
        `when`(mockAuthRepository.register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(validLanguagePreference)
        )).thenReturn(Result.success(testUser))
        
        // Act
        val result = registerUseCase.invoke(
            validEmail,
            validPassword,
            validPassword,
            validLanguagePreference
        )
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(testUser, result.getOrNull())
        verify(mockAuthRepository, times(1)).register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(validLanguagePreference)
        )
    }
    
    @Test
    fun testInvalidEmail() = runTest {
        // Act
        val result = registerUseCase.invoke(
            "invalid-email",
            validPassword,
            validPassword,
            validLanguagePreference
        )
        
        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is InvalidEmailException)
        verify(mockAuthRepository, never()).register(any(), any(), any(), any())
    }
    
    @Test
    fun testEmptyPassword() = runTest {
        // Act
        val result = registerUseCase.invoke(
            validEmail,
            "",
            "",
            validLanguagePreference
        )
        
        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is EmptyPasswordException)
        verify(mockAuthRepository, never()).register(any(), any(), any(), any())
    }
    
    @Test
    fun testWeakPassword() = runTest {
        // Act
        val result = registerUseCase.invoke(
            validEmail,
            "weak",
            "weak",
            validLanguagePreference
        )
        
        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is WeakPasswordException)
        verify(mockAuthRepository, never()).register(any(), any(), any(), any())
    }
    
    @Test
    fun testPasswordMismatch() = runTest {
        // Act
        val result = registerUseCase.invoke(
            validEmail,
            validPassword,
            "DifferentPassword123",
            validLanguagePreference
        )
        
        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is PasswordMismatchException)
        verify(mockAuthRepository, never()).register(any(), any(), any(), any())
    }
    
    @Test
    fun testNetworkError() = runTest {
        // Arrange
        `when`(mockAuthRepository.register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(validLanguagePreference)
        )).thenReturn(Result.failure(NetworkException()))
        
        // Act
        val result = registerUseCase.invoke(
            validEmail,
            validPassword,
            validPassword,
            validLanguagePreference
        )
        
        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is NetworkException)
        verify(mockAuthRepository, times(1)).register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(validLanguagePreference)
        )
    }
    
    @Test
    fun testUserAlreadyExists() = runTest {
        // Arrange
        `when`(mockAuthRepository.register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(validLanguagePreference)
        )).thenReturn(Result.failure(UserAlreadyExistsException()))
        
        // Act
        val result = registerUseCase.invoke(
            validEmail,
            validPassword,
            validPassword,
            validLanguagePreference
        )
        
        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is UserAlreadyExistsException)
        verify(mockAuthRepository, times(1)).register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(validLanguagePreference)
        )
    }
    
    @Test
    fun testDifferentLanguagePreference() = runTest {
        // Arrange
        val englishLanguage = "en"
        val userWithEnglishPreference = testUser.copy(languagePreference = englishLanguage)
        
        `when`(mockAuthRepository.register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(englishLanguage)
        )).thenReturn(Result.success(userWithEnglishPreference))
        
        // Act
        val result = registerUseCase.invoke(
            validEmail,
            validPassword,
            validPassword,
            englishLanguage
        )
        
        // Assert
        assertTrue(result.isSuccess)
        assertEquals(englishLanguage, result.getOrNull()?.languagePreference)
        verify(mockAuthRepository, times(1)).register(
            eq(validEmail),
            eq(validPassword),
            eq(validPassword),
            eq(englishLanguage)
        )
    }
}