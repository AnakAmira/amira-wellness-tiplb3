package com.amirawellness.data.models

import java.util.Date // java.util standard library - For handling date and time properties
import java.util.UUID // java.util standard library - For unique user identification

/**
 * Domain model representing a user account in the Amira Wellness application.
 * This class serves as the core user entity for the application's business logic,
 * containing essential user information and providing methods for user state validation.
 * It follows a clean architecture approach by separating domain models from
 * data transfer objects and database entities.
 */
data class User(
    val id: UUID,
    val email: String,
    val emailVerified: Boolean,
    val createdAt: Date,
    val updatedAt: Date,
    val lastLogin: Date?,
    val accountStatus: String,
    val subscriptionTier: String,
    val languagePreference: String
) {
    /**
     * Checks if the user account is active.
     *
     * @return True if the account is active, false otherwise.
     */
    fun isActive(): Boolean {
        return accountStatus == "active"
    }

    /**
     * Checks if the user has a premium subscription.
     *
     * @return True if the user has a premium subscription, false otherwise.
     */
    fun isPremium(): Boolean {
        return subscriptionTier == "premium"
    }

    /**
     * Creates a copy of the user with updated language preference.
     * This method automatically updates the updatedAt timestamp.
     *
     * @param languageCode The new language preference code.
     * @return A new User instance with the updated language preference.
     */
    fun withUpdatedLanguage(languageCode: String): User {
        return copy(
            languagePreference = languageCode,
            updatedAt = Date()
        )
    }
}

/**
 * Extended user profile with usage statistics.
 * This class combines the core user information with activity and usage data
 * to provide a complete view of the user's engagement with the application.
 */
data class UserProfile(
    val user: User,
    val journalCount: Int,
    val checkinCount: Int,
    val toolUsageCount: Int,
    val streakDays: Int
) {
    /**
     * Calculates the total number of activities performed by the user.
     *
     * @return The sum of journal entries, check-ins, and tool usages.
     */
    fun getTotalActivities(): Int {
        return journalCount + checkinCount + toolUsageCount
    }
}