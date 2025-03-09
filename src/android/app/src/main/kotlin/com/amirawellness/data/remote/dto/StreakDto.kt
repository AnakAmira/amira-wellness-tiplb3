package com.amirawellness.data.remote.dto

import com.google.gson.annotations.SerializedName  // gson 2.10+

/**
 * Enumeration of activity types that can be tracked for streak purposes in the API.
 * These represent different ways users can interact with the application to maintain
 * their activity streak.
 */
enum class ActivityTypeDto {
    @SerializedName("VOICE_JOURNAL")
    VOICE_JOURNAL,
    
    @SerializedName("EMOTIONAL_CHECK_IN")
    EMOTIONAL_CHECK_IN,
    
    @SerializedName("TOOL_USAGE")
    TOOL_USAGE,
    
    @SerializedName("PROGRESS_REVIEW")
    PROGRESS_REVIEW
}

/**
 * Data class representing a single day's activity data from the API.
 *
 * @property date The date of the activity in ISO 8601 format (YYYY-MM-DD).
 * @property isActive Whether the user was active on this date.
 * @property activities List of activity types performed on this date.
 */
data class DailyActivityDto(
    @SerializedName("date")
    val date: String,
    
    @SerializedName("isActive")
    val isActive: Boolean,
    
    @SerializedName("activities")
    val activities: List<String>
)

/**
 * Data transfer object representing a user's streak information from the API.
 *
 * @property id Unique identifier for the streak record.
 * @property userId The identifier of the user this streak belongs to.
 * @property currentStreak The current consecutive days streak.
 * @property longestStreak The longest streak achieved by the user.
 * @property lastActivityDate The date of the last recorded activity.
 * @property totalDaysActive Total number of days the user has been active.
 * @property gracePeriodsUsed Number of grace periods used (allowing streak continuation despite a missed day).
 * @property lastGracePeriodUsed The date when a grace period was last used.
 * @property streakHistory List of daily activities for historical tracking.
 * @property createdAt When the streak record was created.
 * @property updatedAt When the streak record was last updated.
 */
data class StreakDto(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("userId")
    val userId: String,
    
    @SerializedName("currentStreak")
    val currentStreak: Int,
    
    @SerializedName("longestStreak")
    val longestStreak: Int,
    
    @SerializedName("lastActivityDate")
    val lastActivityDate: String?,
    
    @SerializedName("totalDaysActive")
    val totalDaysActive: Int,
    
    @SerializedName("gracePeriodsUsed")
    val gracePeriodsUsed: Int,
    
    @SerializedName("lastGracePeriodUsed")
    val lastGracePeriodUsed: String?,
    
    @SerializedName("streakHistory")
    val streakHistory: List<DailyActivityDto>,
    
    @SerializedName("createdAt")
    val createdAt: String,
    
    @SerializedName("updatedAt")
    val updatedAt: String
)

/**
 * Data transfer object containing comprehensive streak information for display in the UI.
 * This model extends the basic streak data with UI-friendly information like progress metrics.
 *
 * @property currentStreak The current consecutive days streak.
 * @property longestStreak The longest streak achieved by the user.
 * @property totalDaysActive Total number of days the user has been active.
 * @property lastActiveDate The date when the user was last active.
 * @property nextMilestone The next streak milestone to achieve (e.g., 7, 14, 30 days).
 * @property progressToNextMilestone Percentage progress towards the next milestone (0.0-1.0).
 * @property streakHistory List of daily activities for historical tracking and visualization.
 */
data class StreakInfoDto(
    @SerializedName("currentStreak")
    val currentStreak: Int,
    
    @SerializedName("longestStreak")
    val longestStreak: Int,
    
    @SerializedName("totalDaysActive")
    val totalDaysActive: Int,
    
    @SerializedName("lastActiveDate")
    val lastActiveDate: String?,
    
    @SerializedName("nextMilestone")
    val nextMilestone: Int,
    
    @SerializedName("progressToNextMilestone")
    val progressToNextMilestone: Float,
    
    @SerializedName("streakHistory")
    val streakHistory: List<DailyActivityDto>
)

/**
 * Data transfer object for updating a user's streak with a new activity.
 * Used when posting new activity data to the streak tracking system.
 *
 * @property activityDate The date of the activity in ISO 8601 format (YYYY-MM-DD).
 * @property activityType The type of activity performed.
 * @property useGracePeriod Whether to use a grace period if applicable (can be null).
 */
data class StreakUpdateDto(
    @SerializedName("activityDate")
    val activityDate: String,
    
    @SerializedName("activityType")
    val activityType: String,
    
    @SerializedName("useGracePeriod")
    val useGracePeriod: Boolean? = null
)