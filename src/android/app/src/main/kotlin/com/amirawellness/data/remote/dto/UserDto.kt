package com.amirawellness.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Data Transfer Object representing a user in API requests and responses.
 * Contains core user information used throughout the application.
 */
data class UserDto(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("email")
    val email: String,
    
    @SerializedName("email_verified")
    val emailVerified: Boolean,
    
    @SerializedName("created_at")
    val createdAt: String,
    
    @SerializedName("updated_at")
    val updatedAt: String,
    
    @SerializedName("last_login")
    val lastLogin: String?,
    
    @SerializedName("account_status")
    val accountStatus: String,
    
    @SerializedName("subscription_tier")
    val subscriptionTier: String,
    
    @SerializedName("language_preference")
    val languagePreference: String
)

/**
 * Data Transfer Object representing a user profile with usage statistics.
 * This combines user data with activity metrics for profile display.
 */
data class UserProfileDto(
    @SerializedName("user")
    val user: UserDto,
    
    @SerializedName("journal_count")
    val journalCount: Int,
    
    @SerializedName("checkin_count")
    val checkinCount: Int,
    
    @SerializedName("tool_usage_count")
    val toolUsageCount: Int,
    
    @SerializedName("streak_days")
    val streakDays: Int
)

/**
 * Data Transfer Object for login request payload.
 * Contains the credentials needed for user authentication.
 */
data class LoginRequestDto(
    @SerializedName("email")
    val email: String,
    
    @SerializedName("password")
    val password: String
)

/**
 * Data Transfer Object for user registration request payload.
 * Contains all required fields for creating a new user account.
 */
data class RegisterRequestDto(
    @SerializedName("email")
    val email: String,
    
    @SerializedName("password")
    val password: String,
    
    @SerializedName("password_confirm")
    val passwordConfirm: String,
    
    @SerializedName("language_preference")
    val languagePreference: String
)

/**
 * Data Transfer Object for authentication token response.
 * Contains JWT tokens used for authentication and authorization.
 */
data class TokenResponseDto(
    @SerializedName("access_token")
    val accessToken: String,
    
    @SerializedName("refresh_token")
    val refreshToken: String,
    
    @SerializedName("expires_in")
    val expiresIn: Int
)

/**
 * Data Transfer Object for authentication response containing tokens and user data.
 * Provides a complete authentication response including user information.
 */
data class AuthResponseDto(
    @SerializedName("tokens")
    val tokens: TokenResponseDto,
    
    @SerializedName("user")
    val user: UserDto
)