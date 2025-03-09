package com.amirawellness.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.TypeConverters
import java.util.UUID
import java.util.Date

/**
 * Enumeration of achievement categories for grouping related achievements
 */
enum class AchievementCategory {
    STREAK,
    JOURNALING,
    EMOTIONAL_AWARENESS,
    TOOL_USAGE,
    MILESTONE
}

/**
 * Enumeration of achievement types available in the system
 */
enum class AchievementType {
    FIRST_STEP,
    STREAK_3_DAYS,
    STREAK_7_DAYS,
    STREAK_14_DAYS,
    STREAK_30_DAYS,
    STREAK_60_DAYS,
    STREAK_90_DAYS,
    FIRST_JOURNAL,
    JOURNAL_MASTER,
    EMOTIONAL_EXPLORER,
    EMOTIONAL_INSIGHT,
    TOOL_EXPLORER,
    BREATHING_MASTER,
    MEDITATION_MASTER,
    SOMATIC_MASTER,
    JOURNALING_MASTER,
    GRATITUDE_MASTER,
    WELLNESS_JOURNEY
}

/**
 * Domain model representing a user achievement in the Amira Wellness application.
 * Achievements support gamification and progress tracking features by providing
 * clear goals and rewards for consistent app usage.
 */
@Entity(tableName = "achievements")
@TypeConverters(Converters::class)
data class Achievement(
    @PrimaryKey
    val id: UUID,
    
    @ColumnInfo
    val type: AchievementType,
    
    @ColumnInfo
    val category: AchievementCategory,
    
    @ColumnInfo
    val title: String,
    
    @ColumnInfo
    val description: String,
    
    @ColumnInfo
    val iconUrl: String,
    
    @ColumnInfo
    val points: Int,
    
    @ColumnInfo
    val isHidden: Boolean,
    
    @ColumnInfo
    val earnedAt: Date?,
    
    @ColumnInfo
    val progress: Double,
    
    @ColumnInfo
    val metadata: Map<String, Any>?
) {
    /**
     * Checks if the achievement has been earned by the user
     * 
     * @return True if the achievement has been earned, false otherwise
     */
    fun isEarned(): Boolean = earnedAt != null
    
    /**
     * Checks if the achievement progress is complete (100%)
     * 
     * @return True if progress is 1.0 (100%), false otherwise
     */
    fun isComplete(): Boolean = progress >= 1.0
    
    /**
     * Gets the progress as a percentage value
     * 
     * @return Progress as a percentage (0-100)
     */
    fun getProgressPercentage(): Int = (progress * 100).toInt()
    
    /**
     * Creates a copy of the achievement with updated progress
     * 
     * @param newProgress The new progress value between 0.0 and 1.0
     * @return New Achievement instance with updated progress
     */
    fun withProgress(newProgress: Double): Achievement {
        val normalizedProgress = newProgress.coerceIn(0.0, 1.0)
        val newEarnedAt = if (normalizedProgress >= 1.0 && earnedAt == null) Date() else earnedAt
        
        return copy(
            progress = normalizedProgress,
            earnedAt = newEarnedAt
        )
    }
    
    /**
     * Creates a copy of the achievement marked as earned
     * 
     * @return New Achievement instance marked as earned
     */
    fun markAsEarned(): Achievement {
        return copy(
            progress = 1.0,
            earnedAt = earnedAt ?: Date()
        )
    }
    
    companion object {
        /**
         * Creates a new Achievement instance with default values
         * 
         * @param type The achievement type
         * @param category The achievement category
         * @param title The display title for the achievement
         * @param description A detailed description of the achievement
         * @param iconUrl URL to the achievement icon
         * @param points Point value of the achievement
         * @param isHidden Whether the achievement should be hidden until earned
         * @return New Achievement instance with default values
         */
        fun create(
            type: AchievementType,
            category: AchievementCategory,
            title: String,
            description: String,
            iconUrl: String,
            points: Int,
            isHidden: Boolean = false
        ): Achievement {
            return Achievement(
                id = UUID.randomUUID(),
                type = type,
                category = category,
                title = title,
                description = description,
                iconUrl = iconUrl,
                points = points,
                isHidden = isHidden,
                earnedAt = null,
                progress = 0.0,
                metadata = null
            )
        }
    }
}