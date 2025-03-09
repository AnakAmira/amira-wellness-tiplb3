package com.amirawellness.data.remote.mappers

import javax.inject.Inject // javax.inject 1.0
import java.text.SimpleDateFormat // JDK
import java.util.Date // JDK
import java.util.UUID // JDK
import com.amirawellness.data.models.Streak
import com.amirawellness.data.models.StreakInfo
import com.amirawellness.data.models.DailyActivity
import com.amirawellness.data.models.ActivityType
import com.amirawellness.data.remote.dto.StreakDto
import com.amirawellness.data.remote.dto.StreakInfoDto
import com.amirawellness.data.remote.dto.DailyActivityDto
import com.amirawellness.data.remote.dto.ActivityTypeDto
import com.amirawellness.data.remote.dto.StreakUpdateDto

/**
 * Mapper class responsible for converting between Streak domain models and StreakDto 
 * data transfer objects in the Amira Wellness Android application. This class provides 
 * bidirectional mapping functionality to facilitate communication between the application 
 * and the backend API for streak tracking and progress visualization.
 */
@Inject
class StreakMapper {
    
    // Date formatter for ISO 8601 format used in API communication
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").apply {
        timeZone = java.util.TimeZone.getTimeZone("UTC")
    }
    
    /**
     * Converts a Streak domain model to a StreakDto for API communication
     * 
     * @param domain The Streak domain model to convert
     * @return The DTO representation of the domain model
     */
    fun toDto(domain: Streak): StreakDto {
        return StreakDto(
            id = domain.id.toString(),
            userId = domain.userId.toString(),
            currentStreak = domain.currentStreak,
            longestStreak = domain.longestStreak,
            lastActivityDate = domain.lastActivityDate?.let { dateFormat.format(it) },
            totalDaysActive = domain.totalDaysActive,
            gracePeriodsUsed = domain.gracePeriodsUsed,
            lastGracePeriodUsed = domain.lastGracePeriodUsed?.let { dateFormat.format(it) },
            streakHistory = toDailyActivityDtoList(domain.streakHistory),
            createdAt = dateFormat.format(domain.createdAt),
            updatedAt = dateFormat.format(domain.updatedAt)
        )
    }
    
    /**
     * Converts a StreakDto to a Streak domain model
     * 
     * @param dto The StreakDto to convert
     * @return The domain model representation of the DTO
     */
    fun toDomain(dto: StreakDto): Streak {
        return Streak(
            id = UUID.fromString(dto.id),
            userId = UUID.fromString(dto.userId),
            currentStreak = dto.currentStreak,
            longestStreak = dto.longestStreak,
            lastActivityDate = dto.lastActivityDate?.let { dateFormat.parse(it) },
            totalDaysActive = dto.totalDaysActive,
            gracePeriodsUsed = dto.gracePeriodsUsed,
            lastGracePeriodUsed = dto.lastGracePeriodUsed?.let { dateFormat.parse(it) },
            streakHistory = toDailyActivityList(dto.streakHistory),
            createdAt = dateFormat.parse(dto.createdAt),
            updatedAt = dateFormat.parse(dto.updatedAt)
        )
    }
    
    /**
     * Converts a list of StreakDto objects to a list of Streak domain models
     * 
     * @param dtoList The list of DTOs to convert
     * @return List of domain model representations
     */
    fun toDomainList(dtoList: List<StreakDto>): List<Streak> {
        return dtoList.map { toDomain(it) }
    }
    
    /**
     * Converts a list of Streak domain models to a list of StreakDto objects
     * 
     * @param domainList The list of domain models to convert
     * @return List of DTO representations
     */
    fun toDtoList(domainList: List<Streak>): List<StreakDto> {
        return domainList.map { toDto(it) }
    }
    
    /**
     * Converts a StreakInfo domain model to a StreakInfoDto
     * 
     * @param domain The StreakInfo domain model to convert
     * @return The DTO representation of the domain model
     */
    fun toStreakInfoDto(domain: StreakInfo): StreakInfoDto {
        return StreakInfoDto(
            currentStreak = domain.currentStreak,
            longestStreak = domain.longestStreak,
            totalDaysActive = domain.totalDaysActive,
            lastActiveDate = domain.lastActiveDate?.let { dateFormat.format(it) },
            nextMilestone = domain.nextMilestone,
            progressToNextMilestone = domain.progressToNextMilestone,
            streakHistory = toDailyActivityDtoList(domain.streakHistory)
        )
    }
    
    /**
     * Converts a StreakInfoDto to a StreakInfo domain model
     * 
     * @param dto The StreakInfoDto to convert
     * @return The domain model representation of the DTO
     */
    fun toStreakInfo(dto: StreakInfoDto): StreakInfo {
        return StreakInfo(
            currentStreak = dto.currentStreak,
            longestStreak = dto.longestStreak,
            totalDaysActive = dto.totalDaysActive,
            lastActiveDate = dto.lastActiveDate?.let { dateFormat.parse(it) },
            nextMilestone = dto.nextMilestone,
            progressToNextMilestone = dto.progressToNextMilestone,
            streakHistory = toDailyActivityList(dto.streakHistory)
        )
    }
    
    /**
     * Converts a DailyActivity domain model to a DailyActivityDto
     * 
     * @param domain The DailyActivity domain model to convert
     * @return The DTO representation of the domain model
     */
    fun toDailyActivityDto(domain: DailyActivity): DailyActivityDto {
        return DailyActivityDto(
            date = dateFormat.format(domain.date),
            isActive = domain.isActive,
            activities = domain.activities.map { mapActivityTypeToString(it) }
        )
    }
    
    /**
     * Converts a DailyActivityDto to a DailyActivity domain model
     * 
     * @param dto The DailyActivityDto to convert
     * @return The domain model representation of the DTO
     */
    fun toDailyActivity(dto: DailyActivityDto): DailyActivity {
        return DailyActivity(
            date = dateFormat.parse(dto.date),
            isActive = dto.isActive,
            activities = dto.activities.map { mapStringToActivityType(it) }
        )
    }
    
    /**
     * Converts a list of DailyActivity domain models to a list of DailyActivityDto objects
     * 
     * @param domainList The list of domain models to convert
     * @return List of DTO representations
     */
    fun toDailyActivityDtoList(domainList: List<DailyActivity>): List<DailyActivityDto> {
        return domainList.map { toDailyActivityDto(it) }
    }
    
    /**
     * Converts a list of DailyActivityDto objects to a list of DailyActivity domain models
     * 
     * @param dtoList The list of DTOs to convert
     * @return List of domain model representations
     */
    fun toDailyActivityList(dtoList: List<DailyActivityDto>): List<DailyActivity> {
        return dtoList.map { toDailyActivity(it) }
    }
    
    /**
     * Maps an ActivityType enum value to its string representation
     * 
     * @param activityType The ActivityType enum value
     * @return String representation of the activity type
     */
    fun mapActivityTypeToString(activityType: ActivityType): String {
        return activityType.name
    }
    
    /**
     * Maps a string to the corresponding ActivityType enum value
     * 
     * @param activityTypeString The string representation of an activity type
     * @return Corresponding ActivityType enum value
     */
    fun mapStringToActivityType(activityTypeString: String): ActivityType {
        return try {
            ActivityType.valueOf(activityTypeString)
        } catch (e: IllegalArgumentException) {
            // Default to EMOTIONAL_CHECK_IN if the activity type can't be parsed
            ActivityType.EMOTIONAL_CHECK_IN
        }
    }
    
    /**
     * Creates a StreakUpdateDto for updating a streak with a new activity
     * 
     * @param activityType The type of activity performed
     * @param activityDate The date of the activity
     * @param useGracePeriod Whether to use a grace period if applicable
     * @return DTO for updating a streak
     */
    fun createUpdateDto(
        activityType: ActivityType,
        activityDate: Date,
        useGracePeriod: Boolean
    ): StreakUpdateDto {
        return StreakUpdateDto(
            activityDate = dateFormat.format(activityDate),
            activityType = mapActivityTypeToString(activityType),
            useGracePeriod = useGracePeriod
        )
    }
}