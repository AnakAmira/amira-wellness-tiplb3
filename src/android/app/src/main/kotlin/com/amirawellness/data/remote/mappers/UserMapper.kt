package com.amirawellness.data.remote.mappers

import com.amirawellness.data.models.User
import com.amirawellness.data.models.UserProfile
import com.amirawellness.data.remote.dto.UserDto
import com.amirawellness.data.remote.dto.UserProfileDto
import java.text.SimpleDateFormat
import java.util.Date
import java.util.UUID

/**
 * Mapper class responsible for converting between User domain models and UserDto 
 * data transfer objects in the Amira Wellness Android application. This class follows 
 * the clean architecture approach by providing a clear separation between domain 
 * and data layers.
 */
class UserMapper {

    companion object {
        private const val DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    }

    /**
     * Converts a UserDto to a User domain model.
     *
     * @param dto The UserDto to convert
     * @return The corresponding User domain model
     */
    fun toUser(dto: UserDto): User {
        return User(
            id = UUID.fromString(dto.id),
            email = dto.email,
            emailVerified = dto.emailVerified,
            createdAt = parseDate(dto.createdAt) ?: Date(),
            updatedAt = parseDate(dto.updatedAt) ?: Date(),
            lastLogin = parseDate(dto.lastLogin),
            accountStatus = dto.accountStatus,
            subscriptionTier = dto.subscriptionTier,
            languagePreference = dto.languagePreference
        )
    }

    /**
     * Converts a User domain model to a UserDto.
     *
     * @param model The User domain model to convert
     * @return The corresponding UserDto
     */
    fun toUserDto(model: User): UserDto {
        return UserDto(
            id = model.id.toString(),
            email = model.email,
            emailVerified = model.emailVerified,
            createdAt = formatDate(model.createdAt) ?: "",
            updatedAt = formatDate(model.updatedAt) ?: "",
            lastLogin = formatDate(model.lastLogin),
            accountStatus = model.accountStatus,
            subscriptionTier = model.subscriptionTier,
            languagePreference = model.languagePreference
        )
    }

    /**
     * Converts a UserProfileDto to a UserProfile domain model.
     *
     * @param dto The UserProfileDto to convert
     * @return The corresponding UserProfile domain model
     */
    fun toUserProfile(dto: UserProfileDto): UserProfile {
        return UserProfile(
            user = toUser(dto.user),
            journalCount = dto.journalCount,
            checkinCount = dto.checkinCount,
            toolUsageCount = dto.toolUsageCount,
            streakDays = dto.streakDays
        )
    }

    /**
     * Converts a UserProfile domain model to a UserProfileDto.
     *
     * @param model The UserProfile domain model to convert
     * @return The corresponding UserProfileDto
     */
    fun toUserProfileDto(model: UserProfile): UserProfileDto {
        return UserProfileDto(
            user = toUserDto(model.user),
            journalCount = model.journalCount,
            checkinCount = model.checkinCount,
            toolUsageCount = model.toolUsageCount,
            streakDays = model.streakDays
        )
    }

    /**
     * Parses a date string to a Date object.
     *
     * @param dateString The string representation of the date
     * @return The parsed Date object or null if the input is null or parsing fails
     */
    private fun parseDate(dateString: String?): Date? {
        if (dateString == null) return null
        
        return try {
            SimpleDateFormat(DATE_FORMAT).parse(dateString)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Formats a Date object to a string.
     *
     * @param date The Date object to format
     * @return The formatted string or null if the input is null or formatting fails
     */
    private fun formatDate(date: Date?): String? {
        if (date == null) return null
        
        return try {
            SimpleDateFormat(DATE_FORMAT).format(date)
        } catch (e: Exception) {
            null
        }
    }
}