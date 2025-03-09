package com.amirawellness.data.local.dao

import androidx.room.Dao // androidx.room:room-runtime:2.6+
import androidx.room.Delete // androidx.room:room-runtime:2.6+
import androidx.room.Insert // androidx.room:room-runtime:2.6+
import androidx.room.OnConflictStrategy // androidx.room:room-runtime:2.6+
import androidx.room.Query // androidx.room:room-runtime:2.6+
import androidx.room.Transaction // androidx.room:room-runtime:2.6+
import androidx.room.Update // androidx.room:room-runtime:2.6+
import com.amirawellness.data.local.entities.UserEntity
import com.amirawellness.data.models.User
import kotlinx.coroutines.flow.Flow // kotlinx.coroutines:coroutines-core:1.6.4

/**
 * Data Access Object (DAO) interface for user-related database operations in the Amira Wellness application.
 * 
 * This interface provides methods for CRUD operations on user data, managing the current user,
 * and handling user preferences in the local Room database. It supports both synchronous and
 * asynchronous (suspend) operations as well as reactive data streams through Flow.
 */
@Dao
interface UserDao {
    /**
     * Inserts a user into the database, replacing on conflict.
     * 
     * @param user The user entity to insert
     * @return The row ID of the inserted user
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(user: UserEntity): Long

    /**
     * Updates an existing user in the database.
     * 
     * @param user The user entity to update
     * @return The number of rows affected
     */
    @Update
    suspend fun update(user: UserEntity): Int

    /**
     * Deletes a user from the database.
     * 
     * @param user The user entity to delete
     * @return The number of rows affected
     */
    @Delete
    suspend fun delete(user: UserEntity): Int

    /**
     * Gets a user by their ID.
     *
     * @param userId The unique identifier of the user to retrieve
     * @return The user entity or null if not found
     */
    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getUserById(userId: String): UserEntity?

    /**
     * Gets a user by their email address.
     *
     * @param email The email address of the user to retrieve
     * @return The user entity or null if not found
     */
    @Query("SELECT * FROM users WHERE email = :email")
    suspend fun getUserByEmail(email: String): UserEntity?

    /**
     * Gets all users from the database.
     *
     * @return A list of all user entities
     */
    @Query("SELECT * FROM users")
    suspend fun getAllUsers(): List<UserEntity>

    /**
     * Gets the current authenticated user as a Flow.
     * The Flow will emit updates whenever the current user changes.
     *
     * @return Flow emitting the current user or null if not authenticated
     */
    @Query("SELECT * FROM users WHERE is_current = 1 LIMIT 1")
    fun getCurrentUser(): Flow<UserEntity?>

    /**
     * Gets the current authenticated user synchronously.
     * Useful for one-time operations that require immediate access to the current user.
     *
     * @return The current user or null if not authenticated
     */
    @Query("SELECT * FROM users WHERE is_current = 1 LIMIT 1")
    fun getCurrentUserSync(): UserEntity?

    /**
     * Clears the current user flag from all users.
     * This is typically used during logout operations.
     *
     * @return The number of rows affected
     */
    @Query("UPDATE users SET is_current = 0")
    suspend fun clearCurrentUser(): Int

    /**
     * Sets a specific user as the current user.
     * This method should be called after successful authentication.
     *
     * @param userId The ID of the user to set as current
     * @return The number of rows affected
     */
    @Query("UPDATE users SET is_current = 1 WHERE id = :userId")
    suspend fun setCurrentUser(userId: String): Int

    /**
     * Updates the last login timestamp for a user.
     *
     * @param userId The ID of the user to update
     * @param timestamp The timestamp representing the last login time
     * @return The number of rows affected
     */
    @Query("UPDATE users SET last_login = :timestamp WHERE id = :userId")
    suspend fun updateLastLogin(userId: String, timestamp: Long): Int

    /**
     * Updates the language preference for a user.
     *
     * @param userId The ID of the user to update
     * @param languageCode The language code to set (e.g., "es" for Spanish)
     * @return The number of rows affected
     */
    @Query("UPDATE users SET language_preference = :languageCode WHERE id = :userId")
    suspend fun updateLanguagePreference(userId: String, languageCode: String): Int

    /**
     * Updates the account status for a user.
     *
     * @param userId The ID of the user to update
     * @param status The new account status (e.g., "active", "suspended")
     * @return The number of rows affected
     */
    @Query("UPDATE users SET account_status = :status WHERE id = :userId")
    suspend fun updateAccountStatus(userId: String, status: String): Int

    /**
     * Updates the subscription tier for a user.
     *
     * @param userId The ID of the user to update
     * @param tier The new subscription tier (e.g., "free", "premium")
     * @return The number of rows affected
     */
    @Query("UPDATE users SET subscription_tier = :tier WHERE id = :userId")
    suspend fun updateSubscriptionTier(userId: String, tier: String): Int

    /**
     * Sets the email verified flag for a user.
     *
     * @param userId The ID of the user to update
     * @param verified The verification status to set
     * @return The number of rows affected
     */
    @Query("UPDATE users SET email_verified = :verified WHERE id = :userId")
    suspend fun setEmailVerified(userId: String, verified: Boolean): Int

    /**
     * Deletes a user by their ID.
     *
     * @param userId The ID of the user to delete
     * @return The number of rows affected
     */
    @Query("DELETE FROM users WHERE id = :userId")
    suspend fun deleteUserById(userId: String): Int

    /**
     * Deletes all users from the database.
     * This is typically used during account cleanup or for testing purposes.
     *
     * @return The number of rows affected
     */
    @Query("DELETE FROM users")
    suspend fun deleteAllUsers(): Int
}