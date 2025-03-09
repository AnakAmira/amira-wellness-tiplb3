package com.amirawellness.data.repositories

import android.content.Context
import com.amirawellness.core.constants.ApiConstants
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.local.preferences.PreferenceManagerFactory
import com.amirawellness.data.models.User
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.dto.AuthResponseDto
import com.amirawellness.data.remote.dto.LoginRequestDto
import com.amirawellness.data.remote.dto.RegisterRequestDto
import com.amirawellness.data.remote.dto.TokenResponseDto
import com.amirawellness.data.remote.dto.UserDto
import com.amirawellness.data.remote.mappers.UserMapper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.withContext
import org.json.JSONObject
import retrofit2.Response
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "AuthRepository"

/**
 * Repository for handling authentication-related operations in the Amira Wellness application.
 * Implements end-to-end encryption for secure data storage and provides both online and offline
 * authentication capabilities.
 */
@Singleton
class AuthRepository @Inject constructor(
    private val context: Context,
    private val apiService: ApiService,
    private val userMapper: UserMapper,
    private val networkMonitor: NetworkMonitor
) {
    private val authPreferences: PreferenceManager = PreferenceManagerFactory.createAuthPreferences(context)
    private var currentUser: User? = null

    /**
     * Authenticates a user with email and password.
     *
     * @param email User's email address
     * @param password User's password
     * @return Result containing User on success or an exception on failure
     */
    suspend fun login(email: String, password: String): Result<User> = withContext(Dispatchers.IO) {
        try {
            val loginRequest = LoginRequestDto(email, password)
            
            // Check if network is available
            if (!networkMonitor.isNetworkAvailable()) {
                // Try to retrieve cached user if offline
                val cachedUser = getUserFromPreferences()
                if (cachedUser != null) {
                    currentUser = cachedUser
                    return@withContext Result.success(cachedUser)
                }
                return@withContext Result.failure(NetworkException(null))
            }

            // Call API to login
            val response = apiService.login(loginRequest).execute()
            
            if (response.isSuccessful) {
                val authResponse = response.body()
                if (authResponse != null) {
                    // Save tokens to secure storage
                    saveAuthTokens(
                        authResponse.tokens.accessToken,
                        authResponse.tokens.refreshToken,
                        authResponse.tokens.expiresIn
                    )
                    
                    // Map to domain model and save user
                    val user = userMapper.toUser(authResponse.user)
                    currentUser = user
                    saveUserToPreferences(user)
                    
                    return@withContext Result.success(user)
                } else {
                    LogUtils.e(TAG, "Login successful but response body is null")
                    return@withContext Result.failure(ServerException(null))
                }
            } else {
                // Handle API errors
                val exception = when (response.code()) {
                    401 -> InvalidCredentialsException(null)
                    else -> handleApiError(IOException("API error code: ${response.code()}"))
                }
                return@withContext Result.failure(exception)
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Login failed", e)
            return@withContext Result.failure(handleApiError(e))
        }
    }

    /**
     * Registers a new user account.
     *
     * @param email User's email address
     * @param password User's password
     * @param passwordConfirm Password confirmation to verify
     * @param languagePreference User's preferred language (default: Spanish)
     * @return Result containing User on success or an exception on failure
     */
    suspend fun register(
        email: String,
        password: String,
        passwordConfirm: String,
        languagePreference: String = "es"
    ): Result<User> = withContext(Dispatchers.IO) {
        try {
            val registerRequest = RegisterRequestDto(email, password, passwordConfirm, languagePreference)
            
            // Network check before API call
            if (!networkMonitor.isNetworkAvailable()) {
                return@withContext Result.failure(NetworkException(null))
            }
            
            // Call API to register
            val response = apiService.register(registerRequest).execute()
            
            if (response.isSuccessful) {
                val authResponse = response.body()
                if (authResponse != null) {
                    // Save tokens to secure storage
                    saveAuthTokens(
                        authResponse.tokens.accessToken,
                        authResponse.tokens.refreshToken,
                        authResponse.tokens.expiresIn
                    )
                    
                    // Map to domain model and save user
                    val user = userMapper.toUser(authResponse.user)
                    currentUser = user
                    saveUserToPreferences(user)
                    
                    return@withContext Result.success(user)
                } else {
                    LogUtils.e(TAG, "Registration successful but response body is null")
                    return@withContext Result.failure(ServerException(null))
                }
            } else {
                // Handle API errors
                val exception = when (response.code()) {
                    409 -> UserAlreadyExistsException(null)
                    400 -> {
                        val errorBody = response.errorBody()?.string()
                        if (errorBody != null && errorBody.contains("password")) {
                            AuthException("Password validation failed: Passwords must match and meet complexity requirements", null)
                        } else {
                            AuthException("Registration failed: Invalid request", null)
                        }
                    }
                    else -> handleApiError(IOException("API error code: ${response.code()}"))
                }
                return@withContext Result.failure(exception)
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Registration failed", e)
            return@withContext Result.failure(handleApiError(e))
        }
    }

    /**
     * Gets the current authenticated user.
     * If user is cached in memory, returns immediately.
     * Otherwise tries to get user from preferences or API.
     *
     * @return Flow of User or null if not authenticated
     */
    suspend fun getCurrentUser(): Flow<User?> {
        return flow {
            try {
                // If we already have the user in memory, return it
                currentUser?.let {
                    emit(it)
                    return@flow
                }
                
                // Check if we have token - if not, user is not authenticated
                val accessToken = getAccessToken()
                if (accessToken.isNullOrEmpty()) {
                    emit(null)
                    return@flow
                }
                
                // Try to get user from API if online, or preferences if offline
                if (!networkMonitor.isNetworkAvailable()) {
                    // Offline - try to get from preferences
                    val userFromPrefs = getUserFromPreferences()
                    currentUser = userFromPrefs
                    emit(userFromPrefs)
                } else {
                    // Online - try to get from API
                    val response = apiService.getCurrentUser().execute()
                    if (response.isSuccessful) {
                        val userDto = response.body()
                        if (userDto != null) {
                            val user = userMapper.toUser(userDto)
                            currentUser = user
                            saveUserToPreferences(user)
                            emit(user)
                        } else {
                            emit(null)
                        }
                    } else {
                        // Token might be expired or invalid
                        if (response.code() == 401) {
                            // Try to refresh token
                            val refreshResult = refreshToken()
                            if (refreshResult.isSuccess) {
                                // Retry getting user
                                val retryResponse = apiService.getCurrentUser().execute()
                                if (retryResponse.isSuccessful) {
                                    val userDto = retryResponse.body()
                                    if (userDto != null) {
                                        val user = userMapper.toUser(userDto)
                                        currentUser = user
                                        saveUserToPreferences(user)
                                        emit(user)
                                    } else {
                                        emit(null)
                                    }
                                } else {
                                    emit(null)
                                }
                            } else {
                                // Refresh failed, user needs to login again
                                clearAuthTokens()
                                currentUser = null
                                emit(null)
                            }
                        } else {
                            emit(null)
                        }
                    }
                }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error getting current user", e)
                // Try to get from preferences as fallback
                val userFromPrefs = getUserFromPreferences()
                currentUser = userFromPrefs
                emit(userFromPrefs)
            }
        }
    }

    /**
     * Logs out the current user by clearing auth tokens and user data.
     * Attempts to notify the server if online.
     *
     * @return Result containing Unit on success or an exception on failure
     */
    suspend fun logout(): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            // Try to call logout API if online
            if (networkMonitor.isNetworkAvailable()) {
                try {
                    apiService.logout().execute()
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Error calling logout API", e)
                    // Continue with local logout even if API call fails
                }
            }
            
            // Always clear local auth state
            clearAuthTokens()
            currentUser = null
            
            return@withContext Result.success(Unit)
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error during logout", e)
            
            // Still try to clear local auth state in case of error
            try {
                clearAuthTokens()
                currentUser = null
            } catch (clearEx: Exception) {
                LogUtils.e(TAG, "Error clearing auth tokens during logout", clearEx)
            }
            
            return@withContext Result.failure(handleApiError(e))
        }
    }

    /**
     * Refreshes the authentication token.
     *
     * @return Result containing Boolean (true if successful) or an exception on failure
     */
    suspend fun refreshToken(): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val refreshToken = getRefreshToken()
            if (refreshToken.isNullOrEmpty()) {
                LogUtils.e(TAG, "Refresh token is null or empty")
                return@withContext Result.failure(AuthException("No refresh token found", null))
            }
            
            // Network check
            if (!networkMonitor.isNetworkAvailable()) {
                return@withContext Result.failure(NetworkException(null))
            }
            
            // Call API to refresh token
            val response = apiService.refreshToken(refreshToken).execute()
            
            if (response.isSuccessful) {
                val tokenResponse = response.body()
                if (tokenResponse != null) {
                    // Save new tokens
                    saveAuthTokens(
                        tokenResponse.accessToken,
                        tokenResponse.refreshToken,
                        tokenResponse.expiresIn
                    )
                    return@withContext Result.success(true)
                } else {
                    LogUtils.e(TAG, "Token refresh successful but response body is null")
                    return@withContext Result.failure(ServerException(null))
                }
            } else {
                // Handle API errors
                val exception = when (response.code()) {
                    401 -> AuthException("Invalid refresh token", null)
                    else -> handleApiError(IOException("API error code: ${response.code()}"))
                }
                return@withContext Result.failure(exception)
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Token refresh failed", e)
            return@withContext Result.failure(handleApiError(e))
        }
    }

    /**
     * Initiates password reset process for a given email.
     *
     * @param email User's email address
     * @return Result containing Unit on success or an exception on failure
     */
    suspend fun resetPassword(email: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            // Network check
            if (!networkMonitor.isNetworkAvailable()) {
                return@withContext Result.failure(NetworkException(null))
            }
            
            // Call API to reset password
            val response = apiService.resetPassword(email).execute()
            
            if (response.isSuccessful) {
                return@withContext Result.success(Unit)
            } else {
                // Even if email doesn't exist, we return success for security reasons
                if (response.code() == 404) {
                    return@withContext Result.success(Unit)
                }
                
                val exception = handleApiError(IOException("API error code: ${response.code()}"))
                return@withContext Result.failure(exception)
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Password reset failed", e)
            return@withContext Result.failure(handleApiError(e))
        }
    }

    /**
     * Checks if the user is currently authenticated by looking at the current user
     * or checking for a valid access token in storage.
     *
     * @return True if user is authenticated, false otherwise
     */
    fun isAuthenticated(): Boolean {
        // Check if we have current user in memory
        if (currentUser != null) {
            return true
        }
        
        // Check if we have valid token
        val accessToken = getAccessToken()
        return !accessToken.isNullOrEmpty()
    }

    /**
     * Gets the current access token for API requests.
     *
     * @return Access token or null if not authenticated
     */
    fun getAccessToken(): String? {
        return authPreferences.getString(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN)
    }

    /**
     * Saves authentication tokens to secure storage.
     *
     * @param accessToken The JWT access token
     * @param refreshToken The refresh token for obtaining new access tokens
     * @param expiresIn Expiration time in seconds
     * @return True if successful, false otherwise
     */
    private fun saveAuthTokens(accessToken: String, refreshToken: String, expiresIn: Int): Boolean {
        try {
            // Calculate expiration time
            val expirationTime = System.currentTimeMillis() + (expiresIn * 1000)
            
            // Save tokens to secure preferences
            val accessTokenSaved = authPreferences.putString(
                ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN, 
                accessToken
            )
            
            val refreshTokenSaved = authPreferences.putString(
                ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN,
                refreshToken
            )
            
            val expiryTimeSaved = authPreferences.putLong(
                ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.TOKEN_EXPIRY,
                expirationTime
            )
            
            LogUtils.d(TAG, "Auth tokens saved successfully")
            return accessTokenSaved && refreshTokenSaved && expiryTimeSaved
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error saving auth tokens", e)
            return false
        }
    }

    /**
     * Gets the refresh token from secure storage.
     *
     * @return Refresh token or null if not found
     */
    private fun getRefreshToken(): String? {
        return authPreferences.getString(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN)
    }

    /**
     * Clears all authentication tokens from storage during logout.
     *
     * @return True if successful, false otherwise
     */
    private fun clearAuthTokens(): Boolean {
        try {
            authPreferences.remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.ACCESS_TOKEN)
            authPreferences.remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.REFRESH_TOKEN)
            authPreferences.remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.TOKEN_EXPIRY)
            authPreferences.remove(ApiConstants.PREFERENCE_KEYS.AUTH_PREFERENCES.IS_LOGGED_IN)
            authPreferences.remove(ApiConstants.PREFERENCE_KEYS.USER_PREFERENCES.USER_ID)
            authPreferences.remove(ApiConstants.PREFERENCE_KEYS.USER_PREFERENCES.USER_EMAIL)
            
            LogUtils.d(TAG, "Auth tokens cleared successfully")
            return true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error clearing auth tokens", e)
            return false
        }
    }

    /**
     * Saves user data to preferences for offline access.
     *
     * @param user The user to save
     * @return True if successful, false otherwise
     */
    private fun saveUserToPreferences(user: User): Boolean {
        try {
            // Convert user to JSON string
            val userJson = JSONObject().apply {
                put("id", user.id.toString())
                put("email", user.email)
                put("emailVerified", user.emailVerified)
                put("createdAt", user.createdAt.time)
                put("updatedAt", user.updatedAt.time)
                put("lastLogin", user.lastLogin?.time ?: JSONObject.NULL)
                put("accountStatus", user.accountStatus)
                put("subscriptionTier", user.subscriptionTier)
                put("languagePreference", user.languagePreference)
            }.toString()
            
            // Save to preferences
            return authPreferences.putString(
                ApiConstants.PREFERENCE_KEYS.USER_PREFERENCES.USER_DATA,
                userJson
            )
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error saving user to preferences", e)
            return false
        }
    }

    /**
     * Retrieves user data from preferences for offline access.
     *
     * @return User object or null if not found or invalid
     */
    private fun getUserFromPreferences(): User? {
        try {
            val userJson = authPreferences.getString(ApiConstants.PREFERENCE_KEYS.USER_PREFERENCES.USER_DATA)
                ?: return null
            
            // Parse JSON to User object
            val jsonObject = JSONObject(userJson)
            return User(
                id = java.util.UUID.fromString(jsonObject.getString("id")),
                email = jsonObject.getString("email"),
                emailVerified = jsonObject.getBoolean("emailVerified"),
                createdAt = java.util.Date(jsonObject.getLong("createdAt")),
                updatedAt = java.util.Date(jsonObject.getLong("updatedAt")),
                lastLogin = if (jsonObject.isNull("lastLogin")) null else java.util.Date(jsonObject.getLong("lastLogin")),
                accountStatus = jsonObject.getString("accountStatus"),
                subscriptionTier = jsonObject.getString("subscriptionTier"),
                languagePreference = jsonObject.getString("languagePreference")
            )
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error retrieving user from preferences", e)
            return null
        }
    }

    /**
     * Handles API errors and converts them to appropriate exceptions.
     *
     * @param error The error to handle
     * @return Appropriate AuthException subclass
     */
    private fun handleApiError(error: Throwable): AuthException {
        LogUtils.e(TAG, "API error", error)
        
        return when (error) {
            is IOException -> NetworkException(error)
            is retrofit2.HttpException -> {
                when (error.code()) {
                    401 -> InvalidCredentialsException(error)
                    in 500..599 -> ServerException(error)
                    else -> AuthException("API error: ${error.message()}", error)
                }
            }
            else -> AuthException("Unknown error: ${error.message}", error)
        }
    }
}

/**
 * Base exception class for authentication errors.
 */
open class AuthException(message: String, cause: Throwable? = null) : Exception(message, cause)

/**
 * Exception thrown when a network error occurs during authentication.
 */
class NetworkException(cause: Throwable? = null) : AuthException("Network error occurred. Please check your internet connection and try again.", cause)

/**
 * Exception thrown when invalid credentials are provided.
 */
class InvalidCredentialsException(cause: Throwable? = null) : AuthException("Invalid email or password. Please check your credentials and try again.", cause)

/**
 * Exception thrown when a server error occurs during authentication.
 */
class ServerException(cause: Throwable? = null) : AuthException("Server error occurred. Please try again later.", cause)

/**
 * Exception thrown when attempting to register with an email that is already in use.
 */
class UserAlreadyExistsException(cause: Throwable? = null) : AuthException("User with this email already exists. Please use a different email or try to log in.", cause)