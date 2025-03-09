package com.amirawellness.ui.screens.auth

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.amirawellness.data.models.User
import com.amirawellness.domain.usecases.auth.EmptyPasswordException
import com.amirawellness.domain.usecases.auth.InvalidEmailException
import com.amirawellness.domain.usecases.auth.LoginUseCase
import com.amirawellness.ui.navigation.NavActions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.mockito.ArgumentMatchers.anyString
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations
import java.util.UUID

class LoginViewModelTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    @Mock
    private lateinit var loginUseCase: LoginUseCase

    @Mock
    private lateinit var navActions: NavActions

    private lateinit var viewModel: LoginViewModel
    private val testDispatcher = StandardTestDispatcher()
    private val testScope = TestScope(testDispatcher)
    
    private val testEmail = "test@example.com"
    private val testPassword = "password123"
    private val testUserId = UUID.randomUUID().toString()

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        Dispatchers.setMain(testDispatcher)
        viewModel = LoginViewModel(loginUseCase, navActions)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun testInitialState() {
        // Verify initial state values
        assertEquals("", viewModel.uiState.value.email)
        assertEquals("", viewModel.uiState.value.password)
        assertFalse(viewModel.uiState.value.isLoading)
        assertNull(viewModel.uiState.value.errorMessage)
    }

    @Test
    fun testUpdateEmail() = runTest {
        // When updating email
        viewModel.updateEmail(testEmail)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then email should be updated in state
        assertEquals(testEmail, viewModel.uiState.value.email)
        assertNull(viewModel.uiState.value.errorMessage)
    }

    @Test
    fun testUpdatePassword() = runTest {
        // When updating password
        viewModel.updatePassword(testPassword)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then password should be updated in state
        assertEquals(testPassword, viewModel.uiState.value.password)
        assertNull(viewModel.uiState.value.errorMessage)
    }

    @Test
    fun testLogin_Success() = runTest {
        // Given valid credentials in UI state
        viewModel.updateEmail(testEmail)
        viewModel.updatePassword(testPassword)
        testDispatcher.scheduler.advanceUntilIdle()

        // And a successful login response
        val testUser = createTestUser()
        `when`(loginUseCase.invoke(testEmail, testPassword)).thenReturn(Result.success(testUser))

        // When logging in
        viewModel.login()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then should call loginUseCase and navigate to main screen
        verify(loginUseCase).invoke(testEmail, testPassword)
        verify(navActions).navigateToMain()
        assertFalse(viewModel.uiState.value.isLoading)
        assertNull(viewModel.uiState.value.errorMessage)
    }

    @Test
    fun testLogin_InvalidEmail() = runTest {
        // Given invalid email in UI state
        viewModel.updateEmail(testEmail)
        viewModel.updatePassword(testPassword)
        testDispatcher.scheduler.advanceUntilIdle()

        // And a login failure due to invalid email
        `when`(loginUseCase.invoke(testEmail, testPassword)).thenReturn(Result.failure(InvalidEmailException()))

        // When logging in
        viewModel.login()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then should call loginUseCase and update state with error
        verify(loginUseCase).invoke(testEmail, testPassword)
        assertFalse(viewModel.uiState.value.isLoading)
        assertEquals("Invalid email format", viewModel.uiState.value.errorMessage)
        verify(navActions, never()).navigateToMain()
    }

    @Test
    fun testLogin_EmptyPassword() = runTest {
        // Given empty password in UI state
        viewModel.updateEmail(testEmail)
        viewModel.updatePassword("")
        testDispatcher.scheduler.advanceUntilIdle()

        // And a login failure due to empty password
        `when`(loginUseCase.invoke(testEmail, "")).thenReturn(Result.failure(EmptyPasswordException()))

        // When logging in
        viewModel.login()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then should call loginUseCase and update state with error
        verify(loginUseCase).invoke(testEmail, "")
        assertFalse(viewModel.uiState.value.isLoading)
        assertEquals("Password cannot be empty", viewModel.uiState.value.errorMessage)
        verify(navActions, never()).navigateToMain()
    }

    @Test
    fun testLogin_GenericError() = runTest {
        // Given valid credentials in UI state
        viewModel.updateEmail(testEmail)
        viewModel.updatePassword(testPassword)
        testDispatcher.scheduler.advanceUntilIdle()

        // And a login failure due to generic error
        val errorMessage = "Authentication failed"
        `when`(loginUseCase.invoke(testEmail, testPassword)).thenReturn(Result.failure(Exception(errorMessage)))

        // When logging in
        viewModel.login()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then should call loginUseCase and update state with error
        verify(loginUseCase).invoke(testEmail, testPassword)
        assertFalse(viewModel.uiState.value.isLoading)
        assertEquals(errorMessage, viewModel.uiState.value.errorMessage)
        verify(navActions, never()).navigateToMain()
    }

    @Test
    fun testNavigateToRegister() {
        // When navigating to register
        viewModel.navigateToRegister()

        // Then should call navActions
        verify(navActions).navigateToRegister()
    }

    @Test
    fun testNavigateToForgotPassword() {
        // When navigating to forgot password
        viewModel.navigateToForgotPassword()

        // Then should call navActions
        verify(navActions).navigateToForgotPassword()
    }

    @Test
    fun testClearError() = runTest {
        // Given a state with error message
        viewModel.updateEmail(testEmail)
        testDispatcher.scheduler.advanceUntilIdle()
        
        `when`(loginUseCase.invoke(anyString(), anyString())).thenReturn(Result.failure(Exception("Test error")))
        viewModel.login()
        testDispatcher.scheduler.advanceUntilIdle()
        
        // When clearing error
        viewModel.clearError()
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then error message should be null
        assertNull(viewModel.uiState.value.errorMessage)
    }

    @Test
    fun testLoadingState_DuringLogin() = runTest {
        // Given valid credentials in UI state
        viewModel.updateEmail(testEmail)
        viewModel.updatePassword(testPassword)
        testDispatcher.scheduler.advanceUntilIdle()

        // When logging in (without advancing dispatcher)
        viewModel.login()
        
        // Then loading state should be true
        assertTrue(viewModel.uiState.value.isLoading)
        
        // When completing the operation
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then loading state should be false
        assertFalse(viewModel.uiState.value.isLoading)
    }

    private fun createTestUser(): User {
        return User(
            id = UUID.fromString(testUserId),
            email = testEmail,
            emailVerified = true,
            createdAt = java.util.Date(),
            updatedAt = java.util.Date(),
            lastLogin = java.util.Date(),
            accountStatus = "active",
            subscriptionTier = "free",
            languagePreference = "es"
        )
    }
}