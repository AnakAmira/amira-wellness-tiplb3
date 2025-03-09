package com.amirawellness.data.models

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.amirawellness.core.constants.NotificationConstants.ENTITY_TYPES
import com.amirawellness.core.constants.NotificationConstants.NOTIFICATION_TYPES
import java.util.Date
import java.util.UUID

/**
 * Data model representing a notification in the Amira Wellness application.
 * This class serves as both the domain model and the Room database entity for notifications.
 * It supports various notification types including reminders, achievements, and affirmations.
 */
@Entity(tableName = "notifications")
@TypeConverters(DateConverter::class)
data class AppNotification(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    
    @ColumnInfo(name = "notification_type")
    val notificationType: String,
    
    @ColumnInfo(name = "title")
    val title: String,
    
    @ColumnInfo(name = "content")
    val content: String,
    
    @ColumnInfo(name = "related_entity_type")
    val relatedEntityType: String?,
    
    @ColumnInfo(name = "related_entity_id")
    val relatedEntityId: String?,
    
    @ColumnInfo(name = "scheduled_for")
    val scheduledFor: Date?,
    
    @ColumnInfo(name = "is_read")
    val isRead: Boolean,
    
    @ColumnInfo(name = "is_sent")
    val isSent: Boolean,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date,
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: Date,
    
    @ColumnInfo(name = "read_at")
    val readAt: Date?,
    
    @ColumnInfo(name = "sent_at")
    val sentAt: Date?
) {
    /**
     * Creates a copy of this notification with read status set to true
     * 
     * @param readAt The timestamp when the notification was read
     * @return A new notification instance with updated read status
     */
    fun markAsRead(readAt: Date): AppNotification {
        return this.copy(
            isRead = true,
            readAt = readAt,
            updatedAt = readAt
        )
    }
    
    /**
     * Creates a copy of this notification with sent status set to true
     * 
     * @param sentAt The timestamp when the notification was sent
     * @return A new notification instance with updated sent status
     */
    fun markAsSent(sentAt: Date): AppNotification {
        return this.copy(
            isSent = true,
            sentAt = sentAt,
            updatedAt = sentAt
        )
    }
    
    /**
     * Creates a copy of this notification with an updated scheduled time
     * 
     * @param newScheduledTime The new time to schedule this notification
     * @return A new notification instance with updated scheduled time
     */
    fun reschedule(newScheduledTime: Date): AppNotification {
        return this.copy(
            scheduledFor = newScheduledTime,
            isSent = false,
            updatedAt = Date()
        )
    }
    
    /**
     * Generates a deep link URI for this notification based on its type and related entity
     * 
     * @return A deep link URI string or null if no deep link is applicable
     */
    fun getDeepLink(): String? {
        return when {
            // Achievement notifications link to the specific achievement
            notificationType == NOTIFICATION_TYPES.ACHIEVEMENT && relatedEntityId != null -> 
                "amirawellness://achievements/$relatedEntityId"
                
            // Journal notifications link to the specific journal entry
            relatedEntityType == ENTITY_TYPES.JOURNAL && relatedEntityId != null -> 
                "amirawellness://journals/$relatedEntityId"
                
            // Emotional check-in reminders link to the check-in screen
            notificationType == NOTIFICATION_TYPES.EMOTIONAL_CHECKIN_REMINDER -> 
                "amirawellness://emotions/checkin"
                
            // Tool recommendations link to the specific tool
            notificationType == NOTIFICATION_TYPES.TOOL_RECOMMENDATION && relatedEntityId != null -> 
                "amirawellness://tools/$relatedEntityId"
                
            // Streak notifications link to the streaks page
            notificationType == NOTIFICATION_TYPES.STREAK_REMINDER -> 
                "amirawellness://progress/streaks"
                
            // Default case: no deep link
            else -> null
        }
    }
    
    companion object {
        /**
         * Creates a new notification with default values for some fields
         * 
         * @param notificationType The type of notification
         * @param title The notification title
         * @param content The notification content
         * @param relatedEntityType The type of related entity (if any)
         * @param relatedEntityId The ID of related entity (if any)
         * @param scheduledFor When the notification should be delivered (if scheduled)
         * @return A new notification instance
         */
        fun create(
            notificationType: String,
            title: String,
            content: String,
            relatedEntityType: String? = null,
            relatedEntityId: String? = null,
            scheduledFor: Date? = null
        ): AppNotification {
            val now = Date()
            return AppNotification(
                id = UUID.randomUUID().toString(),
                notificationType = notificationType,
                title = title,
                content = content,
                relatedEntityType = relatedEntityType,
                relatedEntityId = relatedEntityId,
                scheduledFor = scheduledFor,
                isRead = false,
                isSent = false,
                createdAt = now,
                updatedAt = now,
                readAt = null,
                sentAt = null
            )
        }
        
        /**
         * Creates a daily check-in reminder notification
         * 
         * @param scheduledFor When the notification should be delivered (if scheduled)
         * @return A new daily reminder notification
         */
        fun createDailyReminder(scheduledFor: Date? = null): AppNotification {
            return create(
                notificationType = NOTIFICATION_TYPES.DAILY_REMINDER,
                title = "¿Cómo te sientes hoy?",
                content = "Toma un momento para hacer tu check-in emocional diario",
                scheduledFor = scheduledFor
            )
        }
        
        /**
         * Creates a streak maintenance reminder notification
         * 
         * @param currentStreak The user's current streak count
         * @param scheduledFor When the notification should be delivered (if scheduled)
         * @return A new streak reminder notification
         */
        fun createStreakReminder(currentStreak: Int, scheduledFor: Date? = null): AppNotification {
            return create(
                notificationType = NOTIFICATION_TYPES.STREAK_REMINDER,
                title = "¡Mantén tu racha!",
                content = "Tienes una racha de $currentStreak días. Haz un check-in hoy para mantenerla.",
                relatedEntityType = ENTITY_TYPES.STREAK,
                scheduledFor = scheduledFor
            )
        }
        
        /**
         * Creates an achievement notification
         * 
         * @param achievementId The ID of the achievement
         * @param achievementTitle The title of the achievement
         * @return A new achievement notification
         */
        fun createAchievementNotification(achievementId: String, achievementTitle: String): AppNotification {
            return create(
                notificationType = NOTIFICATION_TYPES.ACHIEVEMENT,
                title = "¡Felicidades! Has desbloqueado un logro",
                content = "Has obtenido: $achievementTitle",
                relatedEntityType = ENTITY_TYPES.ACHIEVEMENT,
                relatedEntityId = achievementId
            )
        }
        
        /**
         * Creates a daily affirmation notification
         * 
         * @param affirmationText The affirmation text
         * @param scheduledFor When the notification should be delivered (if scheduled)
         * @return A new affirmation notification
         */
        fun createAffirmationNotification(affirmationText: String, scheduledFor: Date? = null): AppNotification {
            return create(
                notificationType = NOTIFICATION_TYPES.AFFIRMATION,
                title = "Afirmación diaria",
                content = affirmationText,
                scheduledFor = scheduledFor
            )
        }
        
        /**
         * Creates a tool recommendation notification
         * 
         * @param toolId The ID of the recommended tool
         * @param toolName The name of the recommended tool
         * @param reason The reason for recommending this tool
         * @return A new tool recommendation notification
         */
        fun createToolRecommendationNotification(toolId: String, toolName: String, reason: String): AppNotification {
            return create(
                notificationType = NOTIFICATION_TYPES.TOOL_RECOMMENDATION,
                title = "Herramienta recomendada",
                content = "$toolName - $reason",
                relatedEntityType = ENTITY_TYPES.TOOL,
                relatedEntityId = toolId
            )
        }
    }
}

/**
 * Type converter for Room database to convert between Date and Long types
 */
class DateConverter {
    /**
     * Converts a timestamp to a Date object
     * 
     * @param value The timestamp in milliseconds
     * @return Date object or null if the input is null
     */
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }
    
    /**
     * Converts a Date object to a timestamp
     * 
     * @param date The Date object
     * @return Timestamp or null if the input is null
     */
    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }
}