package com.amirawellness.services.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.amirawellness.core.constants.NotificationConstants
import com.amirawellness.data.models.AppNotification
import com.amirawellness.data.repositories.NotificationRepository
import com.amirawellness.core.utils.LogUtils
import java.util.Date
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "NotificationManager"

/**
 * Manages the creation and display of notifications in the Amira Wellness application
 */
@Singleton
class NotificationManager @Inject constructor(
    private val context: Context,
    private val notificationRepository: NotificationRepository,
    private val coroutineScope: CoroutineScope
) {
    private val systemNotificationManager: android.app.NotificationManager

    init {
        systemNotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels()
        }
        LogUtils.d(TAG, "NotificationManager initialized")
    }

    /**
     * Creates notification channels for Android O and above
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create channels for each defined channel in NotificationConstants
            val remindersChannel = NotificationChannel(
                NotificationConstants.CHANNELS.REMINDERS.ID,
                NotificationConstants.CHANNELS.REMINDERS.NAME,
                NotificationConstants.CHANNELS.REMINDERS.IMPORTANCE
            ).apply {
                description = NotificationConstants.CHANNELS.REMINDERS.DESCRIPTION
            }
            
            val achievementsChannel = NotificationChannel(
                NotificationConstants.CHANNELS.ACHIEVEMENTS.ID,
                NotificationConstants.CHANNELS.ACHIEVEMENTS.NAME,
                NotificationConstants.CHANNELS.ACHIEVEMENTS.IMPORTANCE
            ).apply {
                description = NotificationConstants.CHANNELS.ACHIEVEMENTS.DESCRIPTION
            }
            
            val affirmationsChannel = NotificationChannel(
                NotificationConstants.CHANNELS.AFFIRMATIONS.ID,
                NotificationConstants.CHANNELS.AFFIRMATIONS.NAME,
                NotificationConstants.CHANNELS.AFFIRMATIONS.IMPORTANCE
            ).apply {
                description = NotificationConstants.CHANNELS.AFFIRMATIONS.DESCRIPTION
            }
            
            val recommendationsChannel = NotificationChannel(
                NotificationConstants.CHANNELS.RECOMMENDATIONS.ID,
                NotificationConstants.CHANNELS.RECOMMENDATIONS.NAME,
                NotificationConstants.CHANNELS.RECOMMENDATIONS.IMPORTANCE
            ).apply {
                description = NotificationConstants.CHANNELS.RECOMMENDATIONS.DESCRIPTION
            }
            
            val updatesChannel = NotificationChannel(
                NotificationConstants.CHANNELS.UPDATES.ID,
                NotificationConstants.CHANNELS.UPDATES.NAME,
                NotificationConstants.CHANNELS.UPDATES.IMPORTANCE
            ).apply {
                description = NotificationConstants.CHANNELS.UPDATES.DESCRIPTION
            }
            
            // Register all channels with the system
            systemNotificationManager.createNotificationChannels(
                listOf(
                    remindersChannel,
                    achievementsChannel,
                    affirmationsChannel,
                    recommendationsChannel,
                    updatesChannel
                )
            )
            
            LogUtils.d(TAG, "Notification channels created")
        }
    }

    /**
     * Displays a notification to the user
     *
     * @param notification The notification to display
     * @return True if notification was displayed successfully, false otherwise
     */
    fun showNotification(notification: AppNotification): Boolean {
        try {
            LogUtils.d(TAG, "Showing notification: ${notification.id}, type: ${notification.notificationType}")
            
            // Determine the appropriate channel based on notification type
            val channelId = getChannelForNotificationType(notification.notificationType)
            
            // Build the notification
            val builder = getNotificationBuilder(notification, channelId)
                .setContentIntent(createContentIntent(notification))
                .setAutoCancel(true)
                
            // Add appropriate actions based on notification type
            addActionsForNotificationType(builder, notification)
            
            // Show the notification
            val notificationId = getNotificationId(notification)
            systemNotificationManager.notify(notificationId, builder.build())
            
            // Mark notification as sent in repository
            coroutineScope.launch(Dispatchers.IO) {
                notificationRepository.markAsSent(notification.id)
            }
            
            return true
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error showing notification", e)
            return false
        }
    }

    /**
     * Cancels a previously shown notification
     *
     * @param notificationId The ID of the notification to cancel
     */
    fun cancelNotification(notificationId: Int) {
        try {
            LogUtils.d(TAG, "Cancelling notification: $notificationId")
            systemNotificationManager.cancel(notificationId)
            LogUtils.d(TAG, "Notification cancelled: $notificationId")
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error cancelling notification", e)
        }
    }

    /**
     * Cancels all previously shown notifications
     */
    fun cancelAllNotifications() {
        try {
            LogUtils.d(TAG, "Cancelling all notifications")
            systemNotificationManager.cancelAll()
            LogUtils.d(TAG, "All notifications cancelled")
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error cancelling all notifications", e)
        }
    }

    /**
     * Creates a notification builder with appropriate settings for the notification type
     *
     * @param notification The notification to create a builder for
     * @param channelId The channel ID to use
     * @return Configured notification builder
     */
    private fun getNotificationBuilder(notification: AppNotification, channelId: String): NotificationCompat.Builder {
        return NotificationCompat.Builder(context, channelId)
            .setContentTitle(notification.title)
            .setContentText(notification.content)
            .setSmallIcon(getSmallIconForNotificationType(notification.notificationType))
            .setWhen(System.currentTimeMillis())
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(getCategoryForNotificationType(notification.notificationType))
            .setAutoCancel(true)
    }

    /**
     * Determines the appropriate notification channel for a given notification type
     *
     * @param notificationType The type of notification
     * @return Channel ID for the notification type
     */
    private fun getChannelForNotificationType(notificationType: String): String {
        return when (notificationType) {
            NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.JOURNAL_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.EMOTIONAL_CHECKIN_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER -> {
                NotificationConstants.CHANNELS.REMINDERS.ID
            }
            NotificationConstants.NOTIFICATION_TYPES.ACHIEVEMENT -> {
                NotificationConstants.CHANNELS.ACHIEVEMENTS.ID
            }
            NotificationConstants.NOTIFICATION_TYPES.AFFIRMATION,
            NotificationConstants.NOTIFICATION_TYPES.WELLNESS_TIP -> {
                NotificationConstants.CHANNELS.AFFIRMATIONS.ID
            }
            NotificationConstants.NOTIFICATION_TYPES.TOOL_RECOMMENDATION -> {
                NotificationConstants.CHANNELS.RECOMMENDATIONS.ID
            }
            NotificationConstants.NOTIFICATION_TYPES.APP_UPDATE -> {
                NotificationConstants.CHANNELS.UPDATES.ID
            }
            else -> {
                NotificationConstants.CHANNELS.REMINDERS.ID // Default to reminders channel
            }
        }
    }

    /**
     * Determines the appropriate notification category for a given notification type
     *
     * @param notificationType The type of notification
     * @return Notification category
     */
    private fun getCategoryForNotificationType(notificationType: String): String {
        return when (notificationType) {
            NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.JOURNAL_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.EMOTIONAL_CHECKIN_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER -> {
                NotificationCompat.CATEGORY_REMINDER
            }
            NotificationConstants.NOTIFICATION_TYPES.ACHIEVEMENT -> {
                NotificationCompat.CATEGORY_SOCIAL
            }
            NotificationConstants.NOTIFICATION_TYPES.TOOL_RECOMMENDATION -> {
                NotificationCompat.CATEGORY_RECOMMENDATION
            }
            else -> {
                NotificationCompat.CATEGORY_MESSAGE
            }
        }
    }

    /**
     * Gets the appropriate small icon resource for a notification type
     *
     * @param notificationType The type of notification
     * @return Resource ID for the small icon
     */
    private fun getSmallIconForNotificationType(notificationType: String): Int {
        // Get the resource ID for the appropriate notification icon
        // This would normally pull from R.drawable with the actual resource IDs
        // For this implementation, we're returning a placeholder value
        val packageName = context.packageName
        val resourceName = when (notificationType) {
            NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.JOURNAL_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.EMOTIONAL_CHECKIN_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER -> {
                "ic_notification_reminder"
            }
            NotificationConstants.NOTIFICATION_TYPES.ACHIEVEMENT -> {
                "ic_notification_achievement"
            }
            NotificationConstants.NOTIFICATION_TYPES.AFFIRMATION,
            NotificationConstants.NOTIFICATION_TYPES.WELLNESS_TIP -> {
                "ic_notification_affirmation"
            }
            NotificationConstants.NOTIFICATION_TYPES.TOOL_RECOMMENDATION -> {
                "ic_notification_recommendation"
            }
            else -> {
                "ic_notification_default"
            }
        }
        
        val resourceId = context.resources.getIdentifier(resourceName, "drawable", packageName)
        return if (resourceId != 0) resourceId else context.resources.getIdentifier("ic_notification_default", "drawable", packageName)
    }

    /**
     * Adds appropriate actions to a notification based on its type
     *
     * @param builder The notification builder to add actions to
     * @param notification The notification to add actions for
     * @return Builder with added actions
     */
    private fun addActionsForNotificationType(builder: NotificationCompat.Builder, notification: AppNotification): NotificationCompat.Builder {
        when (notification.notificationType) {
            NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER,
            NotificationConstants.NOTIFICATION_TYPES.EMOTIONAL_CHECKIN_REMINDER -> {
                // Add check-in action
                val checkInIntent = createActionIntent(NotificationConstants.ACTIONS.ACTION_CHECKIN, notification)
                builder.addAction(
                    getResourceIdForDrawable("ic_action_checkin"),
                    "Check In",
                    checkInIntent
                )
                
                // Add snooze action
                val snoozeIntent = createActionIntent(NotificationConstants.ACTIONS.ACTION_SNOOZE, notification)
                builder.addAction(
                    getResourceIdForDrawable("ic_action_snooze"),
                    "Snooze",
                    snoozeIntent
                )
            }
            
            NotificationConstants.NOTIFICATION_TYPES.ACHIEVEMENT -> {
                // Add view achievement action
                val viewAchievementIntent = createActionIntent(
                    NotificationConstants.ACTIONS.ACTION_VIEW_ACHIEVEMENT,
                    notification
                )
                builder.addAction(
                    getResourceIdForDrawable("ic_action_view"),
                    "View",
                    viewAchievementIntent
                )
            }
            
            NotificationConstants.NOTIFICATION_TYPES.TOOL_RECOMMENDATION -> {
                // Add view tool action
                val viewToolIntent = createActionIntent(
                    NotificationConstants.ACTIONS.ACTION_VIEW_TOOL,
                    notification
                )
                builder.addAction(
                    getResourceIdForDrawable("ic_action_view"),
                    "View",
                    viewToolIntent
                )
            }
        }
        
        // Add dismiss action to all notifications
        val dismissIntent = createActionIntent(NotificationConstants.ACTIONS.ACTION_DISMISS, notification)
        builder.addAction(
            getResourceIdForDrawable("ic_action_dismiss"),
            "Dismiss",
            dismissIntent
        )
        
        return builder
    }

    /**
     * Helper method to get drawable resource ID by name
     */
    private fun getResourceIdForDrawable(name: String): Int {
        val packageName = context.packageName
        val resourceId = context.resources.getIdentifier(name, "drawable", packageName)
        return if (resourceId != 0) resourceId else android.R.drawable.ic_dialog_info // Fallback to system icon
    }

    /**
     * Creates a PendingIntent for when the notification is tapped
     *
     * @param notification The notification to create an intent for
     * @return Content intent for the notification
     */
    private fun createContentIntent(notification: AppNotification): PendingIntent {
        // Create an intent for when the notification is tapped
        val deepLinkUri = notification.getDeepLink()?.let { Uri.parse(it) }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = deepLinkUri
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_NOTIFICATION_ID, notification.id)
            putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_NOTIFICATION_TYPE, notification.notificationType)
            
            // Add entity info if available
            if (notification.relatedEntityType != null && notification.relatedEntityId != null) {
                putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_ENTITY_TYPE, notification.relatedEntityType)
                putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_ENTITY_ID, notification.relatedEntityId)
            }
        }
        
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        return PendingIntent.getActivity(
            context,
            notification.id.hashCode(),
            intent,
            flags
        )
    }

    /**
     * Creates a PendingIntent for a notification action
     *
     * @param action The action to create an intent for
     * @param notification The notification to create an intent for
     * @return Action intent for the notification
     */
    private fun createActionIntent(action: String, notification: AppNotification): PendingIntent {
        val intent = Intent(action).apply {
            putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_NOTIFICATION_ID, notification.id)
            putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_NOTIFICATION_TYPE, notification.notificationType)
            
            // Add entity info if available
            if (notification.relatedEntityType != null && notification.relatedEntityId != null) {
                putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_ENTITY_TYPE, notification.relatedEntityType)
                putExtra(NotificationConstants.EXTRA_KEYS.EXTRA_ENTITY_ID, notification.relatedEntityId)
            }
        }
        
        // Create a unique request code based on action and notification ID
        val requestCode = (action.hashCode() + notification.id.hashCode())
        
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            flags
        )
    }

    /**
     * Generates a unique notification ID based on notification type and entity
     *
     * @param notification The notification to generate an ID for
     * @return Unique notification ID
     */
    private fun getNotificationId(notification: AppNotification): Int {
        // Generate a unique notification ID based on notification type and entity ID
        val baseId = when (notification.notificationType) {
            NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER -> NotificationConstants.NOTIFICATION_IDS.DAILY_REMINDER_ID
            NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER -> NotificationConstants.NOTIFICATION_IDS.STREAK_REMINDER_ID
            NotificationConstants.NOTIFICATION_TYPES.ACHIEVEMENT -> NotificationConstants.NOTIFICATION_IDS.ACHIEVEMENT_ID
            NotificationConstants.NOTIFICATION_TYPES.AFFIRMATION -> NotificationConstants.NOTIFICATION_IDS.AFFIRMATION_ID
            NotificationConstants.NOTIFICATION_TYPES.WELLNESS_TIP -> NotificationConstants.NOTIFICATION_IDS.WELLNESS_TIP_ID
            NotificationConstants.NOTIFICATION_TYPES.JOURNAL_REMINDER -> NotificationConstants.NOTIFICATION_IDS.JOURNAL_REMINDER_ID
            NotificationConstants.NOTIFICATION_TYPES.EMOTIONAL_CHECKIN_REMINDER -> NotificationConstants.NOTIFICATION_IDS.EMOTIONAL_CHECKIN_ID
            NotificationConstants.NOTIFICATION_TYPES.TOOL_RECOMMENDATION -> NotificationConstants.NOTIFICATION_IDS.TOOL_RECOMMENDATION_ID
            NotificationConstants.NOTIFICATION_TYPES.APP_UPDATE -> NotificationConstants.NOTIFICATION_IDS.APP_UPDATE_ID
            else -> NotificationConstants.NOTIFICATION_IDS.DAILY_REMINDER_ID
        }
        
        // Generate a unique ID using the base ID and either the entity ID or notification ID
        return if (notification.relatedEntityId != null) {
            baseId + notification.relatedEntityId.hashCode()
        } else {
            baseId + notification.id.hashCode()
        }
    }
}