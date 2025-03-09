package com.amirawellness.data.models

import java.util.Date
import java.util.UUID
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.TypeConverters

/**
 * Enum defining the types of activities that count toward streaks
 */
enum class ActivityType {
    VOICE_JOURNAL,
    EMOTIONAL_CHECK_IN,
    TOOL_USAGE,
    PROGRESS_REVIEW
}

/**
 * Data class representing a single day's activity for streak tracking
 */
data class DailyActivity(
    val date: Date,
    val isActive: Boolean,
    val activities: List<ActivityType>
) {
    /**
     * Checks if a specific activity type is present in this day's activities
     */
    fun hasActivity(activityType: ActivityType): Boolean {
        return activities.contains(activityType)
    }
}

/**
 * Entity class representing user streak information in the database
 */
@Entity(tableName = "streaks")
@TypeConverters(StreakConverters::class)
data class Streak(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: UUID,
    
    @ColumnInfo(name = "user_id")
    val userId: UUID,
    
    @ColumnInfo(name = "current_streak")
    val currentStreak: Int,
    
    @ColumnInfo(name = "longest_streak")
    val longestStreak: Int,
    
    @ColumnInfo(name = "last_activity_date")
    val lastActivityDate: Date?,
    
    @ColumnInfo(name = "total_days_active")
    val totalDaysActive: Int,
    
    @ColumnInfo(name = "grace_periods_used")
    val gracePeriodsUsed: Int,
    
    @ColumnInfo(name = "last_grace_period_used")
    val lastGracePeriodUsed: Date?,
    
    @ColumnInfo(name = "streak_history")
    val streakHistory: List<DailyActivity>,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date,
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date
) {
    /**
     * Updates the streak with a new activity
     */
    fun updateStreak(activityType: ActivityType, activityDate: Date): Streak {
        // Check if activity is on the same day as last activity
        val recentActivity = getActivityForDate(activityDate)
        
        if (recentActivity != null) {
            // Same day activity, just add the activity type if not already present
            if (!recentActivity.hasActivity(activityType)) {
                val updatedActivities = recentActivity.activities.toMutableList()
                updatedActivities.add(activityType)
                
                val updatedDailyActivity = recentActivity.copy(activities = updatedActivities)
                val updatedHistory = streakHistory.toMutableList()
                val index = updatedHistory.indexOfFirst { it.date.time == activityDate.time }
                if (index >= 0) {
                    updatedHistory[index] = updatedDailyActivity
                }
                
                return copy(
                    streakHistory = updatedHistory,
                    updatedAt = Date()
                )
            }
            
            // Activity already recorded for this day, no change needed
            return this
        }
        
        // New day activity
        val newCurrentStreak: Int
        val newLongestStreak: Int
        val newGracePeriodsUsed: Int
        val newLastGracePeriodUsed: Date?
        
        if (lastActivityDate == null) {
            // First activity ever
            newCurrentStreak = 1
            newLongestStreak = 1
            newGracePeriodsUsed = gracePeriodsUsed
            newLastGracePeriodUsed = lastGracePeriodUsed
        } else if (isConsecutiveDay(activityDate)) {
            // Consecutive day, increment streak
            newCurrentStreak = currentStreak + 1
            newLongestStreak = maxOf(newCurrentStreak, longestStreak)
            newGracePeriodsUsed = gracePeriodsUsed
            newLastGracePeriodUsed = lastGracePeriodUsed
        } else if (isWithinGracePeriod(activityDate) && canUseGracePeriod()) {
            // Within grace period and can use it
            newCurrentStreak = currentStreak + 1
            newLongestStreak = maxOf(newCurrentStreak, longestStreak)
            newGracePeriodsUsed = gracePeriodsUsed + 1
            newLastGracePeriodUsed = activityDate
        } else {
            // Streak broken, reset
            newCurrentStreak = 1
            newLongestStreak = longestStreak
            newGracePeriodsUsed = gracePeriodsUsed
            newLastGracePeriodUsed = lastGracePeriodUsed
        }
        
        // Create new daily activity
        val newDailyActivity = DailyActivity(
            date = activityDate,
            isActive = true,
            activities = listOf(activityType)
        )
        
        // Update streak history
        val newStreakHistory = streakHistory.toMutableList()
        newStreakHistory.add(newDailyActivity)
        
        return copy(
            currentStreak = newCurrentStreak,
            longestStreak = newLongestStreak,
            lastActivityDate = activityDate,
            totalDaysActive = totalDaysActive + 1,
            gracePeriodsUsed = newGracePeriodsUsed,
            lastGracePeriodUsed = newLastGracePeriodUsed,
            streakHistory = newStreakHistory,
            updatedAt = Date()
        )
    }
    
    /**
     * Checks if a grace period can be used for the current streak
     */
    fun canUseGracePeriod(): Boolean {
        // Allow one grace period per week
        if (gracePeriodsUsed >= 1) {
            val lastGraceDate = lastGracePeriodUsed ?: return true
            
            // Only allow another grace period if 7 days have passed since the last one
            val calendar = java.util.Calendar.getInstance()
            calendar.time = lastGraceDate
            calendar.add(java.util.Calendar.DAY_OF_YEAR, 7)
            
            return Date().after(calendar.time)
        }
        
        return true
    }
    
    /**
     * Checks if a date is consecutive with the last activity date
     */
    fun isConsecutiveDay(date: Date): Boolean {
        val lastDate = lastActivityDate ?: return true
        
        // Calculate days between dates
        val diffInMillis = date.time - lastDate.time
        val diffInDays = diffInMillis / (1000 * 60 * 60 * 24)
        
        return diffInDays == 1L
    }
    
    /**
     * Checks if a date is within the grace period of the last activity date
     */
    fun isWithinGracePeriod(date: Date): Boolean {
        val lastDate = lastActivityDate ?: return false
        
        // Calculate days between dates
        val diffInMillis = date.time - lastDate.time
        val diffInDays = diffInMillis / (1000 * 60 * 60 * 24)
        
        // Grace period is one missed day
        return diffInDays == 2L
    }
    
    /**
     * Gets the most recent daily activity from the streak history
     */
    fun getRecentActivity(): DailyActivity? {
        if (streakHistory.isEmpty()) return null
        
        return streakHistory.maxByOrNull { it.date.time }
    }
    
    /**
     * Gets the daily activity for a specific date
     */
    fun getActivityForDate(date: Date): DailyActivity? {
        // Simple day comparison - ignoring time components
        val calendar1 = java.util.Calendar.getInstance()
        calendar1.time = date
        calendar1.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar1.set(java.util.Calendar.MINUTE, 0)
        calendar1.set(java.util.Calendar.SECOND, 0)
        calendar1.set(java.util.Calendar.MILLISECOND, 0)
        val startOfDay = calendar1.time.time
        
        calendar1.add(java.util.Calendar.DAY_OF_YEAR, 1)
        val endOfDay = calendar1.time.time
        
        return streakHistory.find { 
            it.date.time >= startOfDay && it.date.time < endOfDay 
        }
    }
    
    companion object {
        // Milestone levels for streak achievements
        val MILESTONE_LEVELS = listOf(3, 7, 14, 30, 60, 90, 180, 365)
        
        /**
         * Creates a new Streak instance for a user
         */
        fun createNew(userId: UUID): Streak {
            val now = Date()
            val initialActivity = DailyActivity(
                date = now,
                isActive = true,
                activities = emptyList()
            )
            
            return Streak(
                id = UUID.randomUUID(),
                userId = userId,
                currentStreak = 1,
                longestStreak = 1,
                lastActivityDate = now,
                totalDaysActive = 1,
                gracePeriodsUsed = 0,
                lastGracePeriodUsed = null,
                streakHistory = listOf(initialActivity),
                createdAt = now,
                updatedAt = now
            )
        }
        
        /**
         * Calculates the next milestone based on current streak
         */
        fun calculateNextMilestone(currentStreak: Int): Int {
            val nextMilestone = MILESTONE_LEVELS.find { it > currentStreak }
            return nextMilestone ?: MILESTONE_LEVELS.last()
        }
        
        /**
         * Calculates the progress percentage toward the next milestone
         */
        fun calculateProgressToNextMilestone(currentStreak: Int, nextMilestone: Int): Float {
            val previousMilestone = MILESTONE_LEVELS.findLast { it < currentStreak } ?: 0
            val range = nextMilestone - previousMilestone
            val progress = currentStreak - previousMilestone
            
            return progress.toFloat() / range.toFloat()
        }
        
        /**
         * Creates a StreakInfo instance from a Streak entity
         */
        fun fromStreak(streak: Streak): StreakInfo {
            val nextMilestone = calculateNextMilestone(streak.currentStreak)
            val progress = calculateProgressToNextMilestone(streak.currentStreak, nextMilestone)
            
            return StreakInfo(
                currentStreak = streak.currentStreak,
                longestStreak = streak.longestStreak,
                totalDaysActive = streak.totalDaysActive,
                lastActiveDate = streak.lastActivityDate,
                nextMilestone = nextMilestone,
                progressToNextMilestone = progress,
                streakHistory = streak.streakHistory
            )
        }
    }
}

/**
 * Data class containing comprehensive streak information for display in the UI
 */
data class StreakInfo(
    val currentStreak: Int,
    val longestStreak: Int,
    val totalDaysActive: Int,
    val lastActiveDate: Date?,
    val nextMilestone: Int,
    val progressToNextMilestone: Float,
    val streakHistory: List<DailyActivity>
) {
    /**
     * Gets the count of active days for each day of the week
     */
    fun getActiveWeekdays(): Map<Int, Int> {
        val weekdayCounts = mutableMapOf<Int, Int>()
        
        // Initialize with all days of week (1=Monday, 7=Sunday)
        for (i in 1..7) {
            weekdayCounts[i] = 0
        }
        
        // Count active days by weekday
        streakHistory.filter { it.isActive }.forEach { activity ->
            val calendar = java.util.Calendar.getInstance()
            calendar.time = activity.date
            
            // Calendar uses 1=Sunday, but we want 1=Monday
            var dayOfWeek = calendar.get(java.util.Calendar.DAY_OF_WEEK) - 1
            if (dayOfWeek == 0) dayOfWeek = 7 // Sunday becomes 7
            
            weekdayCounts[dayOfWeek] = (weekdayCounts[dayOfWeek] ?: 0) + 1
        }
        
        return weekdayCounts
    }
    
    /**
     * Checks if the streak is currently active (activity within the last day)
     */
    fun getActiveStreak(): Boolean {
        val lastActive = lastActiveDate ?: return false
        
        val calendar = java.util.Calendar.getInstance()
        val today = calendar.time
        
        // Calculate days between last active date and today
        val diffInMillis = today.time - lastActive.time
        val diffInDays = diffInMillis / (1000 * 60 * 60 * 24)
        
        // Streak is active if there was activity today or yesterday
        return diffInDays <= 1
    }
}

/**
 * Type converters for Room database to handle complex types in Streak entity
 */
class StreakConverters {
    /**
     * Converts a Date to a Long timestamp for database storage
     */
    @TypeConverter
    fun fromDate(date: Date?): Long? {
        return date?.time
    }
    
    /**
     * Converts a Long timestamp to a Date for application use
     */
    @TypeConverter
    fun toDate(timestamp: Long?): Date? {
        return if (timestamp == null) null else Date(timestamp)
    }
    
    /**
     * Converts a UUID to a String for database storage
     */
    @TypeConverter
    fun fromUUID(uuid: UUID?): String? {
        return uuid?.toString()
    }
    
    /**
     * Converts a String to a UUID for application use
     */
    @TypeConverter
    fun toUUID(uuidString: String?): UUID? {
        return if (uuidString == null) null else UUID.fromString(uuidString)
    }
    
    /**
     * Converts a list of DailyActivity to a JSON string for database storage
     * Note: In a real implementation, this would use a JSON library like Moshi or Gson
     */
    @TypeConverter
    fun fromDailyActivities(activities: List<DailyActivity>?): String? {
        if (activities == null) return null
        
        // In a real implementation, this would serialize the list to a JSON string
        // using a library like Moshi or Gson
        return activities.toString()
    }
    
    /**
     * Converts a JSON string to a list of DailyActivity for application use
     * Note: In a real implementation, this would use a JSON library like Moshi or Gson
     */
    @TypeConverter
    fun toDailyActivities(json: String?): List<DailyActivity>? {
        if (json == null) return null
        
        // In a real implementation, this would deserialize the JSON string to a list
        // using a library like Moshi or Gson
        return emptyList()
    }
}