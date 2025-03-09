package com.amirawellness.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.amirawellness.data.models.AppNotification
import kotlinx.coroutines.flow.Flow
import java.util.Date

/**
 * Data Access Object (DAO) interface for AppNotification entities in the Amira Wellness application.
 * This interface defines database operations for notifications, including CRUD operations,
 * queries for different notification types, and status updates.
 */
@Dao
interface NotificationDao {

    /**
     * Inserts a notification entity into the database
     * 
     * @param notification The notification to insert
     * @return The row ID of the inserted notification
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNotification(notification: AppNotification): Long

    /**
     * Inserts multiple notification entities into the database
     * 
     * @param notifications The list of notifications to insert
     * @return List of row IDs for the inserted notifications
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNotifications(notifications: List<AppNotification>): List<Long>

    /**
     * Updates an existing notification entity in the database
     * 
     * @param notification The notification to update
     * @return The number of notifications updated (should be 1)
     */
    @Update
    suspend fun updateNotification(notification: AppNotification): Int

    /**
     * Deletes a notification entity from the database
     * 
     * @param notification The notification to delete
     * @return The number of notifications deleted (should be 1)
     */
    @Delete
    suspend fun deleteNotification(notification: AppNotification): Int

    /**
     * Retrieves a notification by its unique identifier
     * 
     * @param id The ID of the notification to retrieve
     * @return Flow emitting the notification entity or null if not found
     */
    @Query("SELECT * FROM notifications WHERE id = :id")
    fun getNotificationById(id: String): Flow<AppNotification?>

    /**
     * Retrieves all notifications ordered by creation date (newest first)
     * 
     * @return Flow emitting a list of all notification entities
     */
    @Query("SELECT * FROM notifications ORDER BY created_at DESC")
    fun getAllNotifications(): Flow<List<AppNotification>>

    /**
     * Retrieves all unread notifications ordered by creation date (newest first)
     * 
     * @return Flow emitting a list of unread notification entities
     */
    @Query("SELECT * FROM notifications WHERE is_read = 0 ORDER BY created_at DESC")
    fun getUnreadNotifications(): Flow<List<AppNotification>>

    /**
     * Retrieves notifications of a specific type ordered by creation date (newest first)
     * 
     * @param notificationType The type of notifications to retrieve
     * @return Flow emitting a list of notification entities of the specified type
     */
    @Query("SELECT * FROM notifications WHERE notification_type = :notificationType ORDER BY created_at DESC")
    fun getNotificationsByType(notificationType: String): Flow<List<AppNotification>>

    /**
     * Retrieves notifications scheduled for future delivery ordered by scheduled time
     * 
     * @return Flow emitting a list of scheduled notification entities
     */
    @Query("SELECT * FROM notifications WHERE scheduled_for IS NOT NULL AND is_sent = 0 ORDER BY scheduled_for ASC")
    fun getScheduledNotifications(): Flow<List<AppNotification>>

    /**
     * Retrieves notifications that are due for delivery (scheduled time has passed)
     * 
     * @param currentTime The current time in milliseconds
     * @return Flow emitting a list of due notification entities
     */
    @Query("SELECT * FROM notifications WHERE scheduled_for IS NOT NULL AND scheduled_for <= :currentTime AND is_sent = 0")
    fun getDueNotifications(currentTime: Long): Flow<List<AppNotification>>

    /**
     * Retrieves notifications related to a specific entity
     * 
     * @param entityType The type of related entity
     * @param entityId The ID of related entity
     * @return Flow emitting a list of notification entities related to the specified entity
     */
    @Query("SELECT * FROM notifications WHERE related_entity_type = :entityType AND related_entity_id = :entityId ORDER BY created_at DESC")
    fun getNotificationsByRelatedEntity(entityType: String, entityId: String): Flow<List<AppNotification>>

    /**
     * Marks a notification as read
     * 
     * @param id The ID of the notification to mark as read
     * @param readAt The timestamp when the notification was read
     * @return The number of notifications updated (should be 1)
     */
    @Query("UPDATE notifications SET is_read = 1, read_at = :readAt, updated_at = :readAt WHERE id = :id")
    suspend fun markAsRead(id: String, readAt: Long): Int

    /**
     * Marks all unread notifications as read
     * 
     * @param readAt The timestamp when the notifications were read
     * @return The number of notifications updated
     */
    @Query("UPDATE notifications SET is_read = 1, read_at = :readAt, updated_at = :readAt WHERE is_read = 0")
    suspend fun markAllAsRead(readAt: Long): Int

    /**
     * Marks a notification as sent
     * 
     * @param id The ID of the notification to mark as sent
     * @param sentAt The timestamp when the notification was sent
     * @return The number of notifications updated (should be 1)
     */
    @Query("UPDATE notifications SET is_sent = 1, sent_at = :sentAt, updated_at = :sentAt WHERE id = :id")
    suspend fun markAsSent(id: String, sentAt: Long): Int

    /**
     * Deletes notifications older than the specified time
     * 
     * @param olderThan The cutoff timestamp for notification age
     * @return The number of notifications deleted
     */
    @Query("DELETE FROM notifications WHERE created_at < :olderThan")
    suspend fun deleteOldNotifications(olderThan: Long): Int

    /**
     * Gets the count of unread notifications
     * 
     * @return Flow emitting the count of unread notifications
     */
    @Query("SELECT COUNT(*) FROM notifications WHERE is_read = 0")
    fun getUnreadNotificationCount(): Flow<Int>

    /**
     * Deletes all notifications from the database
     * 
     * @return The number of notifications deleted
     */
    @Query("DELETE FROM notifications")
    suspend fun deleteAllNotifications(): Int
}