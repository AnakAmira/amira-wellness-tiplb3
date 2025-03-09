package com.amirawellness.data.repositories

import com.amirawellness.data.models.User
import com.amirawellness.data.models.UserProfile
import com.amirawellness.data.local.dao.UserDao
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.mappers.UserMapper
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines:1.6.4
import kotlinx.coroutines.flow.map // kotlinx.coroutines:1.6.4
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines:1.6.4
import kotlinx.coroutines.withContext // kotlinx.coroutines:1.6.4
import javax.inject.Inject // javax.inject:1
import javax.inject.Singleton // javax.inject:1

/**
 * Repository implementation for user-related operations in the Amira Wellness application.
 * Serves as a single source of truth for user data, managing synchronization between
 * local database storage and remote API, while providing a clean interface for the domain
 * layer to access user information.
 *
 * This repository ensures consistent access to user data and handles offline scenarios
 * by prioritizing local database access when network connectivity is unavailable.
 */
@Singleton
class UserRepository @Inject constructor(
    private val userDao: UserDao,
    private val apiService: ApiService,
    private val networkMonitor: NetworkMonitor,
    private val userMapper: UserMapper
) {

    /**
     * Gets the current authenticated user as a Flow.
     * The Flow will emit updates whenever the current user changes in the database.
     *
     * @return Flow emitting the current user or null if not authenticated
     */
    fun getCurrentUser(): Flow<User?> {
        return userDao.getCurrentUser().map { userEntity ->
            userEntity?.let { userMapper.toUser(it) }
        }
    }

    /**
     * Gets a user by their ID, attempting to retrieve from local database first,
     * then from remote API if not found locally and network is available.
     *
     * @param userId The unique identifier of the user to retrieve
     * @return Result containing the User if successful, or an error if retrieval fails
     */
    suspend fun getUserById(userId: String): Result<User> = withContext(Dispatchers.IO) {
        try {
            // First try to get from local database
            val localUser = userDao.getUserById(userId)
            if (localUser != null) {
                return@withContext Result.success(userMapper.toUser(localUser))
            }

            // If not found locally and network is available, fetch from remote
            if (networkMonitor.isNetworkAvailable()) {
                val response = apiService.getCurrentUser().execute()
                
                if (response.isSuccessful && response.body() != null) {
                    val userDto = response.body()!!
                    if (userDto.id == userId) {
                        // Convert DTO to domain model
                        val user = userMapper.toUser(userDto)
                        
                        // Save to local database
                        saveUser(user)
                        
                        return@withContext Result.success(user)
                    }
                }
                return@withContext Result.failure(Exception("User not found"))
            } else {
                return@withContext Result.failure(Exception("User not found locally and network is unavailable"))
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Gets a user by their email address, attempting to retrieve from local database first,
     * then from remote API if not found locally and network is available.
     *
     * @param email The email address of the user to retrieve
     * @return Result containing the User if successful, or an error if retrieval fails
     */
    suspend fun getUserByEmail(email: String): Result<User> = withContext(Dispatchers.IO) {
        try {
            // First try to get from local database
            val localUser = userDao.getUserByEmail(email)
            if (localUser != null) {
                return@withContext Result.success(userMapper.toUser(localUser))
            }

            // If not found locally and network is available, fetch from remote
            if (networkMonitor.isNetworkAvailable()) {
                // This is a simplification - the actual API might have a specific endpoint
                // for getting user by email. Currently using getCurrentUser as a placeholder.
                val response = apiService.getCurrentUser().execute()
                
                if (response.isSuccessful && response.body() != null) {
                    val userDto = response.body()!!
                    if (userDto.email == email) {
                        // Convert DTO to domain model
                        val user = userMapper.toUser(userDto)
                        
                        // Save to local database
                        saveUser(user)
                        
                        return@withContext Result.success(user)
                    }
                }
                return@withContext Result.failure(Exception("User not found with email: $email"))
            } else {
                return@withContext Result.failure(Exception("User not found locally and network is unavailable"))
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Gets the user profile with usage statistics from the remote API.
     * This operation requires network connectivity.
     *
     * @return Result containing the UserProfile if successful, or an error if retrieval fails
     */
    suspend fun getUserProfile(): Result<UserProfile> = withContext(Dispatchers.IO) {
        try {
            if (!networkMonitor.isNetworkAvailable()) {
                return@withContext Result.failure(Exception("Network unavailable"))
            }

            val response = apiService.getUserProfile().execute()
            
            if (response.isSuccessful && response.body() != null) {
                val userProfileDto = response.body()!!
                val userProfile = userMapper.toUserProfile(userProfileDto)
                return@withContext Result.success(userProfile)
            } else {
                return@withContext Result.failure(Exception("Failed to retrieve user profile"))
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Updates the user's language preference in local database and remote API if network is available.
     *
     * @param userId The ID of the user to update
     * @param languageCode The language code to set (e.g., "es" for Spanish)
     * @return Result containing the updated User if successful, or an error if update fails
     */
    suspend fun updateUserLanguagePreference(userId: String, languageCode: String): Result<User> = withContext(Dispatchers.IO) {
        try {
            // Update in local database
            val updated = userDao.updateLanguagePreference(userId, languageCode)
            if (updated <= 0) {
                return@withContext Result.failure(Exception("Failed to update language preference"))
            }

            // Update on remote API if network is available
            if (networkMonitor.isNetworkAvailable()) {
                val localUser = userDao.getUserById(userId) ?: return@withContext Result.failure(Exception("User not found"))
                val userDto = userMapper.toUserDto(userMapper.toUser(localUser))
                
                // This is a simplification - the actual API might have a specific endpoint
                // for updating user preferences
                val response = apiService.updateUserProfile(userDto).execute()
                
                if (!response.isSuccessful) {
                    // Continue even if remote update fails, as local update succeeded
                }
            }

            // Get updated user from local database
            val updatedUser = userDao.getUserById(userId)
            if (updatedUser != null) {
                return@withContext Result.success(userMapper.toUser(updatedUser))
            } else {
                return@withContext Result.failure(Exception("Failed to retrieve updated user"))
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Updates the user's account status in local database and remote API if network is available.
     *
     * @param userId The ID of the user to update
     * @param status The new account status (e.g., "active", "suspended")
     * @return Result containing the updated User if successful, or an error if update fails
     */
    suspend fun updateUserAccountStatus(userId: String, status: String): Result<User> = withContext(Dispatchers.IO) {
        try {
            // Update in local database
            val updated = userDao.updateAccountStatus(userId, status)
            if (updated <= 0) {
                return@withContext Result.failure(Exception("Failed to update account status"))
            }

            // Update on remote API if network is available
            if (networkMonitor.isNetworkAvailable()) {
                val localUser = userDao.getUserById(userId) ?: return@withContext Result.failure(Exception("User not found"))
                val userDto = userMapper.toUserDto(userMapper.toUser(localUser))
                
                // This is a simplification - the actual API might have a specific endpoint
                // for updating account status
                val response = apiService.updateUserProfile(userDto).execute()
                
                if (!response.isSuccessful) {
                    // Continue even if remote update fails, as local update succeeded
                }
            }

            // Get updated user from local database
            val updatedUser = userDao.getUserById(userId)
            if (updatedUser != null) {
                return@withContext Result.success(userMapper.toUser(updatedUser))
            } else {
                return@withContext Result.failure(Exception("Failed to retrieve updated user"))
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Updates the user's subscription tier in local database and remote API if network is available.
     *
     * @param userId The ID of the user to update
     * @param tier The new subscription tier (e.g., "free", "premium")
     * @return Result containing the updated User if successful, or an error if update fails
     */
    suspend fun updateUserSubscriptionTier(userId: String, tier: String): Result<User> = withContext(Dispatchers.IO) {
        try {
            // Update in local database
            val updated = userDao.updateSubscriptionTier(userId, tier)
            if (updated <= 0) {
                return@withContext Result.failure(Exception("Failed to update subscription tier"))
            }

            // Update on remote API if network is available
            if (networkMonitor.isNetworkAvailable()) {
                val localUser = userDao.getUserById(userId) ?: return@withContext Result.failure(Exception("User not found"))
                val userDto = userMapper.toUserDto(userMapper.toUser(localUser))
                
                // This is a simplification - the actual API might have a specific endpoint
                // for updating subscription tier
                val response = apiService.updateUserProfile(userDto).execute()
                
                if (!response.isSuccessful) {
                    // Continue even if remote update fails, as local update succeeded
                }
            }

            // Get updated user from local database
            val updatedUser = userDao.getUserById(userId)
            if (updatedUser != null) {
                return@withContext Result.success(userMapper.toUser(updatedUser))
            } else {
                return@withContext Result.failure(Exception("Failed to retrieve updated user"))
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Synchronizes user data between local database and remote API.
     * This operation requires network connectivity.
     *
     * @return Result containing the synchronized User if successful, or an error if synchronization fails
     */
    suspend fun syncUserData(): Result<User?> = withContext(Dispatchers.IO) {
        try {
            if (!networkMonitor.isNetworkAvailable()) {
                return@withContext Result.failure(Exception("Network unavailable"))
            }

            // Fetch latest user data from remote API
            val response = apiService.getCurrentUser().execute()
            
            if (response.isSuccessful && response.body() != null) {
                val userDto = response.body()!!
                val user = userMapper.toUser(userDto)
                
                // Save or update in local database
                saveUser(user)
                
                // Set as current user
                setCurrentUser(user.id.toString())
                
                return@withContext Result.success(user)
            } else {
                return@withContext Result.failure(Exception("Failed to sync user data: ${response.code()} ${response.message()}"))
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Saves a user to the local database.
     *
     * @param user The User domain model to save
     * @return Result containing the row ID if successful, or an error if save fails
     */
    suspend fun saveUser(user: User): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val userEntity = userMapper.toUserEntity(user)
            val rowId = userDao.insert(userEntity)
            return@withContext Result.success(rowId)
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Sets a user as the current authenticated user.
     * This method clears the current user flag from all users first.
     *
     * @param userId The ID of the user to set as current
     * @return Result containing Unit if successful, or an error if operation fails
     */
    suspend fun setCurrentUser(userId: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            // Clear current user flag from all users
            userDao.clearCurrentUser()
            
            // Set current user flag for specified user
            val updated = userDao.setCurrentUser(userId)
            if (updated <= 0) {
                return@withContext Result.failure(Exception("Failed to set current user"))
            }
            
            return@withContext Result.success(Unit)
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * Clears the current user flag from all users.
     * This is typically used during logout operations.
     *
     * @return Result containing Unit if successful, or an error if operation fails
     */
    suspend fun clearCurrentUser(): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            userDao.clearCurrentUser()
            return@withContext Result.success(Unit)
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }
}