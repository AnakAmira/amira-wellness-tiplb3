package com.amirawellness.data.repositories

import android.content.Context
import com.amirawellness.core.constants.ApiConstants
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.models.User
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.dto.*
import com.amirawellness.data.remote.mappers.UserMapper
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestCoroutineDispatcher
import kotlinx.coroutines.test.TestCoroutineScope
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.mockito.MockitoAnnotations
import retrofit2.Call
import retrofit2.Response
import java.io.IOException
import java.util.Date
import java.util.UUID

// Test constants
private const val TEST_EMAIL = "test@example.com"
private const val TEST_PASSWORD = "Password123!"
private const val TEST_USER_ID = "test-user-id"

@ExperimentalCoroutinesApi
class AuthRepositoryTest {

    // Mocks
    @Mock private lateinit var mockContext: Context
    @Mock private lateinit var mockApiService: ApiService
    @Mock private lateinit var mockUserMapper: UserMapper
    @Mock private lateinit var mockNetworkMonitor: NetworkMonitor
    @Mock private lateinit var mockPreferenceManager: PreferenceManager
    
    // Test coroutines
    private lateinit var testDispatcher: TestCoroutineDispatcher
    private lateinit var testScope: TestCoroutineScope
    
    // Subject under test
    private lateinit var repository: AuthRepository

    // Helper function to create a test User object
    private fun createTestUser(emailVerified: Boolean = true, accountStatus: String = "active"): User {
        return User(
            id = UUID.fromString(TEST_USER_ID),
            email = TEST_EMAIL,
            emailVerified = emailVerified,
            createdAt = Date(),
            updatedAt = Date(),
            lastLogin = Date(),
            accountStatus = accountStatus,
            subscriptionTier = "free",
            languagePreference = "es"
        )
    }

    // Helper function to create a test UserDto object
    private fun createTestUserDto(emailVerified: Boolean = true, accountStatus: String = "active"): UserDto {
        return UserDto(
            id = TEST_USER_ID,
            email = TEST_EMAIL,
            emailVerified = emailVerified,
            createdAt = "2023-01-01T00:00:00.000Z",
            updatedAt = "2023-01-01T00:00:00.000Z",
            lastLogin = "2023-01-01T00:00:00.000Z",
            accountStatus = accountStatus,
            subscriptionTier = "free",
            languagePreference = "es"
        )
    }

    // Helper function to create a test AuthResponseDto object
    private fun createTestAuthResponse(userDto: UserDto): AuthResponseDto {
        val tokenResponse = TokenResponseDto(
            accessToken = "test-access-token",
            refreshToken = "test-refresh-token",
            expiresIn = 3600
        )
        return AuthResponseDto(
            tokens = tokenResponse,
            user = userDto
        )
    }

    @Before
    fun setup() {
        MockitoAnnotations.initMocks(this)
        
        // Set up coroutines
        testDispatcher = TestCoroutineDispatcher()
        testScope = TestCoroutineScope(testDispatcher)
        
        // Default network monitor behavior
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(true)
        
        // Set up user mapper default behavior
        `when`(mockUserMapper.toUser(Mockito.any(UserDto::class.java))).thenAnswer { invocation ->
            val dto = invocation.getArgument<UserDto>(0)
            createTestUser(dto.emailVerified, dto.accountStatus)
        }
        
        // Create repository with mocks
        repository = AuthRepository(
            mockContext,
            mockApiService,
            mockUserMapper,
            mockNetworkMonitor
        )
        
        // Set the mocked preferenceManager
        val field = AuthRepository::class.java.getDeclaredField("authPreferences")
        field.isAccessible = true
        field.set(repository, mockPreferenceManager)
    }

    @Test
    fun testLogin_success() = runTest {
        // Arrange
        val userDto = createTestUserDto()
        val user = createTestUser()
        val authResponse = createTestAuthResponse(userDto)
        
        // Mock API response
        val mockCall = Mockito.mock(Call::class.java) as Call<AuthResponseDto>
        `when`(mockCall.execute()).thenReturn(Response.success(authResponse))
        `when`(mockApiService.login(Mockito.any(LoginRequestDto::class.java))).thenReturn(mockCall)
        
        // Mock preference storage
        `when`(mockPreferenceManager.putString(Mockito.anyString(), Mockito.anyString())).thenReturn(true)
        `when`(mockPreferenceManager.putLong(Mockito.anyString(), Mockito.anyLong())).thenReturn(true)
        
        // Act
        val result = repository.login(TEST_EMAIL, TEST_PASSWORD)
        
        // Assert
        verify(mockApiService).login(Mockito.any(LoginRequestDto::class.java))
        verify(mockUserMapper).toUser(userDto)
        verify(mockPreferenceManager).putString(
            Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN),
            Mockito.eq("test-access-token")
        )
        verify(mockPreferenceManager).putString(
            Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN),
            Mockito.eq("test-refresh-token")
        )
        
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(user)
    }

    @Test
    fun testLogin_networkError() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.login(TEST_EMAIL, TEST_PASSWORD)
        
        // Assert
        verify(mockApiService, never()).login(Mockito.any(LoginRequestDto::class.java))
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(NetworkException::class.java)
    }

    @Test
    fun testLogin_invalidCredentials() = runTest {
        // Arrange
        val mockCall = Mockito.mock(Call::class.java) as Call<AuthResponseDto>
        `when`(mockCall.execute()).thenReturn(Response.error(401, Mockito.mock(okhttp3.ResponseBody::class.java)))
        `when`(mockApiService.login(Mockito.any(LoginRequestDto::class.java))).thenReturn(mockCall)
        
        // Act
        val result = repository.login(TEST_EMAIL, TEST_PASSWORD)
        
        // Assert
        verify(mockApiService).login(Mockito.any(LoginRequestDto::class.java))
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(InvalidCredentialsException::class.java)
    }

    @Test
    fun testLogin_serverError() = runTest {
        // Arrange
        val mockCall = Mockito.mock(Call::class.java) as Call<AuthResponseDto>
        `when`(mockCall.execute()).thenReturn(Response.error(500, Mockito.mock(okhttp3.ResponseBody::class.java)))
        `when`(mockApiService.login(Mockito.any(LoginRequestDto::class.java))).thenReturn(mockCall)
        
        // Act
        val result = repository.login(TEST_EMAIL, TEST_PASSWORD)
        
        // Assert
        verify(mockApiService).login(Mockito.any(LoginRequestDto::class.java))
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(ServerException::class.java)
    }

    @Test
    fun testRegister_success() = runTest {
        // Arrange
        val userDto = createTestUserDto()
        val user = createTestUser()
        val authResponse = createTestAuthResponse(userDto)
        
        // Mock API response
        val mockCall = Mockito.mock(Call::class.java) as Call<AuthResponseDto>
        `when`(mockCall.execute()).thenReturn(Response.success(authResponse))
        `when`(mockApiService.register(Mockito.any(RegisterRequestDto::class.java))).thenReturn(mockCall)
        
        // Mock preference storage
        `when`(mockPreferenceManager.putString(Mockito.anyString(), Mockito.anyString())).thenReturn(true)
        `when`(mockPreferenceManager.putLong(Mockito.anyString(), Mockito.anyLong())).thenReturn(true)
        
        // Act
        val result = repository.register(TEST_EMAIL, TEST_PASSWORD, TEST_PASSWORD, "es")
        
        // Assert
        verify(mockApiService).register(Mockito.any(RegisterRequestDto::class.java))
        verify(mockUserMapper).toUser(userDto)
        verify(mockPreferenceManager).putString(
            Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN),
            Mockito.eq("test-access-token")
        )
        
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(user)
    }

    @Test
    fun testRegister_networkError() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.register(TEST_EMAIL, TEST_PASSWORD, TEST_PASSWORD, "es")
        
        // Assert
        verify(mockApiService, never()).register(Mockito.any(RegisterRequestDto::class.java))
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(NetworkException::class.java)
    }

    @Test
    fun testRegister_userAlreadyExists() = runTest {
        // Arrange
        val mockCall = Mockito.mock(Call::class.java) as Call<AuthResponseDto>
        `when`(mockCall.execute()).thenReturn(Response.error(409, Mockito.mock(okhttp3.ResponseBody::class.java)))
        `when`(mockApiService.register(Mockito.any(RegisterRequestDto::class.java))).thenReturn(mockCall)
        
        // Act
        val result = repository.register(TEST_EMAIL, TEST_PASSWORD, TEST_PASSWORD, "es")
        
        // Assert
        verify(mockApiService).register(Mockito.any(RegisterRequestDto::class.java))
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(UserAlreadyExistsException::class.java)
    }

    @Test
    fun testGetCurrentUser_authenticated() = runTest {
        // Arrange
        val userDto = createTestUserDto()
        val user = createTestUser()
        
        // Mock token exists
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN), Mockito.nullable(String::class.java))).thenReturn("valid-token")
        
        // Mock API response
        val mockCall = Mockito.mock(Call::class.java) as Call<UserDto>
        `when`(mockCall.execute()).thenReturn(Response.success(userDto))
        `when`(mockApiService.getCurrentUser()).thenReturn(mockCall)
        
        // Act
        val result = repository.getCurrentUser()
        
        // Assert
        verify(mockApiService).getCurrentUser()
        verify(mockUserMapper).toUser(userDto)
        
        val userResult = result.first() // Collect first value from flow
        assertThat(userResult).isEqualTo(user)
    }

    @Test
    fun testGetCurrentUser_notAuthenticated() = runTest {
        // Arrange
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN), Mockito.nullable(String::class.java))).thenReturn(null)
        
        // Act
        val result = repository.getCurrentUser()
        
        // Assert
        verify(mockApiService, never()).getCurrentUser()
        
        val userResult = result.first() // Collect first value from flow
        assertThat(userResult).isNull()
    }

    @Test
    fun testGetCurrentUser_networkError() = runTest {
        // Arrange
        val userJson = "{\"id\":\"$TEST_USER_ID\",\"email\":\"$TEST_EMAIL\",\"emailVerified\":true,\"createdAt\":1672531200000,\"updatedAt\":1672531200000,\"lastLogin\":1672531200000,\"accountStatus\":\"active\",\"subscriptionTier\":\"free\",\"languagePreference\":\"es\"}"
        
        // Mock token exists
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN), Mockito.nullable(String::class.java))).thenReturn("valid-token")
        
        // Mock network unavailable
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Mock user in preferences
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.USER_PREFERENCES.USER_DATA), Mockito.nullable(String::class.java))).thenReturn(userJson)
        
        // Act
        val result = repository.getCurrentUser()
        
        // Assert
        verify(mockApiService, never()).getCurrentUser()
        
        val userResult = result.first() // Collect first value from flow
        assertThat(userResult).isNotNull()
        assertThat(userResult?.email).isEqualTo(TEST_EMAIL)
    }

    @Test
    fun testLogout_success() = runTest {
        // Arrange
        val mockCall = Mockito.mock(Call::class.java) as Call<Unit>
        `when`(mockCall.execute()).thenReturn(Response.success(Unit))
        `when`(mockApiService.logout()).thenReturn(mockCall)
        
        // Mock preference clearing
        `when`(mockPreferenceManager.remove(Mockito.anyString())).thenReturn(true)
        
        // Act
        val result = repository.logout()
        
        // Assert
        verify(mockApiService).logout()
        verify(mockPreferenceManager).remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN)
        verify(mockPreferenceManager).remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN)
        
        assertThat(result.isSuccess).isTrue()
    }

    @Test
    fun testLogout_networkError() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Mock preference clearing
        `when`(mockPreferenceManager.remove(Mockito.anyString())).thenReturn(true)
        
        // Act
        val result = repository.logout()
        
        // Assert
        verify(mockApiService, never()).logout()
        
        // Local logout should still succeed
        verify(mockPreferenceManager).remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN)
        verify(mockPreferenceManager).remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN)
        
        assertThat(result.isSuccess).isTrue()
    }

    @Test
    fun testRefreshToken_success() = runTest {
        // Arrange
        val tokenResponse = TokenResponseDto(
            accessToken = "new-access-token",
            refreshToken = "new-refresh-token",
            expiresIn = 3600
        )
        
        // Mock refresh token exists
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN), Mockito.nullable(String::class.java))).thenReturn("old-refresh-token")
        
        // Mock API response
        val mockCall = Mockito.mock(Call::class.java) as Call<TokenResponseDto>
        `when`(mockCall.execute()).thenReturn(Response.success(tokenResponse))
        `when`(mockApiService.refreshToken(Mockito.anyString())).thenReturn(mockCall)
        
        // Mock preference storage
        `when`(mockPreferenceManager.putString(Mockito.anyString(), Mockito.anyString())).thenReturn(true)
        `when`(mockPreferenceManager.putLong(Mockito.anyString(), Mockito.anyLong())).thenReturn(true)
        
        // Act
        val result = repository.refreshToken()
        
        // Assert
        verify(mockApiService).refreshToken(Mockito.anyString())
        verify(mockPreferenceManager).putString(
            Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN),
            Mockito.eq("new-access-token")
        )
        
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isTrue()
    }

    @Test
    fun testRefreshToken_noRefreshToken() = runTest {
        // Arrange
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN), Mockito.nullable(String::class.java))).thenReturn(null)
        
        // Act
        val result = repository.refreshToken()
        
        // Assert
        verify(mockApiService, never()).refreshToken(Mockito.anyString())
        
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(AuthException::class.java)
    }

    @Test
    fun testRefreshToken_networkError() = runTest {
        // Arrange
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN), Mockito.nullable(String::class.java))).thenReturn("old-refresh-token")
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.refreshToken()
        
        // Assert
        verify(mockApiService, never()).refreshToken(Mockito.anyString())
        
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(NetworkException::class.java)
    }

    @Test
    fun testRefreshToken_invalidToken() = runTest {
        // Arrange
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN), Mockito.nullable(String::class.java))).thenReturn("old-refresh-token")
        
        // Mock API error response
        val mockCall = Mockito.mock(Call::class.java) as Call<TokenResponseDto>
        `when`(mockCall.execute()).thenReturn(Response.error(401, Mockito.mock(okhttp3.ResponseBody::class.java)))
        `when`(mockApiService.refreshToken(Mockito.anyString())).thenReturn(mockCall)
        
        // Act
        val result = repository.refreshToken()
        
        // Assert
        verify(mockApiService).refreshToken(Mockito.anyString())
        
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(AuthException::class.java)
    }

    @Test
    fun testResetPassword_success() = runTest {
        // Arrange
        val mockCall = Mockito.mock(Call::class.java) as Call<Unit>
        `when`(mockCall.execute()).thenReturn(Response.success(Unit))
        `when`(mockApiService.resetPassword(Mockito.anyString())).thenReturn(mockCall)
        
        // Act
        val result = repository.resetPassword(TEST_EMAIL)
        
        // Assert
        verify(mockApiService).resetPassword(TEST_EMAIL)
        
        assertThat(result.isSuccess).isTrue()
    }

    @Test
    fun testResetPassword_networkError() = runTest {
        // Arrange
        `when`(mockNetworkMonitor.isNetworkAvailable()).thenReturn(false)
        
        // Act
        val result = repository.resetPassword(TEST_EMAIL)
        
        // Assert
        verify(mockApiService, never()).resetPassword(Mockito.anyString())
        
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(NetworkException::class.java)
    }

    @Test
    fun testIsAuthenticated_withCurrentUser() {
        // Arrange
        val user = createTestUser()
        
        // Set currentUser in repository
        val field = AuthRepository::class.java.getDeclaredField("currentUser")
        field.isAccessible = true
        field.set(repository, user)
        
        // Act
        val result = repository.isAuthenticated()
        
        // Assert
        assertThat(result).isTrue()
    }

    @Test
    fun testIsAuthenticated_withAccessToken() {
        // Arrange
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN), Mockito.nullable(String::class.java))).thenReturn("valid-token")
        
        // Ensure currentUser is null
        val field = AuthRepository::class.java.getDeclaredField("currentUser")
        field.isAccessible = true
        field.set(repository, null)
        
        // Act
        val result = repository.isAuthenticated()
        
        // Assert
        assertThat(result).isTrue()
    }

    @Test
    fun testIsAuthenticated_notAuthenticated() {
        // Arrange
        `when`(mockPreferenceManager.getString(Mockito.eq(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN), Mockito.nullable(String::class.java))).thenReturn(null)
        
        // Ensure currentUser is null
        val field = AuthRepository::class.java.getDeclaredField("currentUser")
        field.isAccessible = true
        field.set(repository, null)
        
        // Act
        val result = repository.isAuthenticated()
        
        // Assert
        assertThat(result).isFalse()
    }
}