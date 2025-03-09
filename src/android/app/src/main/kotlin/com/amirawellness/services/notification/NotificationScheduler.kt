package com.amirawellness.services.notification

import android.content.Context
import androidx.work.WorkManager
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkRequest
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.Calendar
import java.util.Date
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

import com.amirawellness.services.notification.NotificationManager
import com.amirawellness.data.repositories.NotificationRepository
import com.amirawellness.data.models.AppNotification
import com.amirawellness.core.constants.NotificationConstants
import com.amirawellness.data.local.preferences.PreferenceManagerFactory
import com.amirawellness.core.utils.LogUtils

private const val TAG = "NotificationScheduler"
private const val KEY_NOTIFICATION_ID = "notification_id"
private const val KEY_NOTIFICATION_TYPE = "notification_type"

/**
 * Manages the scheduling of notifications in the Amira Wellness application
 */
@Singleton
class NotificationScheduler @Inject constructor(
    private val context: Context,
    private val notificationManager: NotificationManager,
    private val notificationRepository: NotificationRepository,
    private val coroutineScope: CoroutineScope
) {
    private val workManager: WorkManager = WorkManager.getInstance(context)
    private val notificationPreferences = PreferenceManagerFactory.createNotificationPreferences(context)
    
    init {
        LogUtils.d(TAG, "NotificationScheduler initialized")
    }
    
    /**
     * Initializes the notification scheduler and sets up recurring notifications
     */
    fun initialize() {
        LogUtils.d(TAG, "Initializing notification scheduler")
        
        // Schedule various types of notifications
        scheduleDailyReminders()
        scheduleStreakReminders()
        scheduleAffirmations()
        
        // Schedule the notification processing and cleanup workers
        scheduleNotificationProcessing()
        scheduleNotificationCleanup()
        
        LogUtils.d(TAG, "Notification scheduler initialization completed")
    }

    /**
     * Schedules daily reminder notifications based on user preferences
     */
    fun scheduleDailyReminders() {
        LogUtils.d(TAG, "Scheduling daily reminders")
        
        coroutineScope.launch {
            // Get user's preferred time and days for daily reminders
            val calendar = getPreferredNotificationTime(NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER)
            val preferredDays = getPreferredNotificationDays(NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER)
            
            // Build a work request for the DailyReminderWorker
            val dailyReminderRequest = PeriodicWorkRequestBuilder<DailyReminderWorker>(
                24, TimeUnit.HOURS
            )
                .setInitialDelay(calculateInitialDelay(calendar), TimeUnit.MILLISECONDS)
                .addTag(NotificationConstants.WORKER_TAGS.DAILY_REMINDER_WORKER_TAG)
                .build()
            
            // Enqueue the work request with WorkManager
            workManager.enqueueUniquePeriodicWork(
                NotificationConstants.WORKER_TAGS.DAILY_REMINDER_WORKER_TAG,
                ExistingPeriodicWorkPolicy.REPLACE,
                dailyReminderRequest
            )
            
            LogUtils.d(TAG, "Daily reminders scheduled for ${calendar.time} on days $preferredDays")
        }
    }

    /**
     * Schedules streak reminder notifications
     */
    fun scheduleStreakReminders() {
        LogUtils.d(TAG, "Scheduling streak reminders")
        
        coroutineScope.launch {
            // Get user's preferred time for streak reminders
            val calendar = getPreferredNotificationTime(NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER)
            
            // Build a work request for the StreakReminderWorker
            val streakReminderRequest = PeriodicWorkRequestBuilder<StreakReminderWorker>(
                24, TimeUnit.HOURS
            )
                .setInitialDelay(calculateInitialDelay(calendar), TimeUnit.MILLISECONDS)
                .addTag(NotificationConstants.WORKER_TAGS.STREAK_REMINDER_WORKER_TAG)
                .build()
            
            // Enqueue the work request with WorkManager
            workManager.enqueueUniquePeriodicWork(
                NotificationConstants.WORKER_TAGS.STREAK_REMINDER_WORKER_TAG,
                ExistingPeriodicWorkPolicy.REPLACE,
                streakReminderRequest
            )
            
            LogUtils.d(TAG, "Streak reminders scheduled for ${calendar.time}")
        }
    }

    /**
     * Schedules daily affirmation notifications
     */
    fun scheduleAffirmations() {
        LogUtils.d(TAG, "Scheduling affirmations")
        
        coroutineScope.launch {
            // Get user's preferred time for affirmations
            val calendar = getPreferredNotificationTime(NotificationConstants.NOTIFICATION_TYPES.AFFIRMATION)
            
            // Build a work request for the AffirmationWorker
            val affirmationRequest = PeriodicWorkRequestBuilder<AffirmationWorker>(
                24, TimeUnit.HOURS
            )
                .setInitialDelay(calculateInitialDelay(calendar), TimeUnit.MILLISECONDS)
                .addTag(NotificationConstants.WORKER_TAGS.AFFIRMATION_WORKER_TAG)
                .build()
            
            // Enqueue the work request with WorkManager
            workManager.enqueueUniquePeriodicWork(
                NotificationConstants.WORKER_TAGS.AFFIRMATION_WORKER_TAG,
                ExistingPeriodicWorkPolicy.REPLACE,
                affirmationRequest
            )
            
            LogUtils.d(TAG, "Affirmations scheduled for ${calendar.time}")
        }
    }

    /**
     * Schedules a worker to process and display due notifications
     */
    fun scheduleNotificationProcessing() {
        LogUtils.d(TAG, "Scheduling notification processing worker")
        
        // Build a periodic work request that runs every 15 minutes
        val processingRequest = PeriodicWorkRequestBuilder<NotificationWorker>(
            15, TimeUnit.MINUTES
        )
            .addTag(NotificationConstants.WORKER_TAGS.NOTIFICATION_WORKER_TAG)
            .build()
        
        // Enqueue the work request with WorkManager
        workManager.enqueueUniquePeriodicWork(
            NotificationConstants.WORKER_TAGS.NOTIFICATION_WORKER_TAG,
            ExistingPeriodicWorkPolicy.REPLACE,
            processingRequest
        )
        
        LogUtils.d(TAG, "Notification processing worker scheduled")
    }

    /**
     * Schedules a worker to clean up old notifications
     */
    fun scheduleNotificationCleanup() {
        LogUtils.d(TAG, "Scheduling notification cleanup worker")
        
        // Build a periodic work request that runs daily
        val cleanupRequest = PeriodicWorkRequestBuilder<NotificationCleanupWorker>(
            24, TimeUnit.HOURS
        )
            .build()
        
        // Enqueue the work request with WorkManager
        workManager.enqueueUniquePeriodicWork(
            "notification_cleanup_worker",
            ExistingPeriodicWorkPolicy.REPLACE,
            cleanupRequest
        )
        
        LogUtils.d(TAG, "Notification cleanup worker scheduled")
    }

    /**
     * Schedules a one-time notification to be shown at a specific time
     */
    fun scheduleOneTimeNotification(notificationId: String, notificationType: String, scheduledTime: Date) {
        LogUtils.d(TAG, "Scheduling one-time notification: $notificationId, type: $notificationType, time: $scheduledTime")
        
        // Calculate delay until scheduled time
        val currentTime = System.currentTimeMillis()
        val scheduledTimeMillis = scheduledTime.time
        val initialDelay = Math.max(0, scheduledTimeMillis - currentTime)
        
        // Build input data with notification details
        val inputData = Data.Builder()
            .putString(KEY_NOTIFICATION_ID, notificationId)
            .putString(KEY_NOTIFICATION_TYPE, notificationType)
            .build()
        
        // Build a one-time work request
        val oneTimeRequest = OneTimeWorkRequestBuilder<OneTimeNotificationWorker>()
            .setInitialDelay(initialDelay, TimeUnit.MILLISECONDS)
            .setInputData(inputData)
            .addTag(NotificationConstants.WORKER_TAGS.ONE_TIME_NOTIFICATION_WORKER_TAG)
            .addTag("notification_$notificationId")
            .build()
        
        // Enqueue the work request with WorkManager
        workManager.enqueueUniqueWork(
            "notification_$notificationId",
            ExistingWorkPolicy.REPLACE,
            oneTimeRequest
        )
        
        LogUtils.d(TAG, "One-time notification scheduled for ${scheduledTime}")
    }

    /**
     * Cancels a previously scheduled notification
     */
    fun cancelScheduledNotification(notificationId: String) {
        LogUtils.d(TAG, "Cancelling scheduled notification: $notificationId")
        
        // Cancel any work tagged with this notification ID
        workManager.cancelAllWorkByTag("notification_$notificationId")
        
        // Also cancel the notification if it's already shown
        val notificationIdHashCode = notificationId.hashCode()
        notificationManager.cancelNotification(notificationIdHashCode)
        
        LogUtils.d(TAG, "Notification cancelled: $notificationId")
    }

    /**
     * Processes due notifications and displays them to the user
     * @return The number of notifications processed
     */
    suspend fun processNotifications(): Int {
        LogUtils.d(TAG, "Processing due notifications")
        
        try {
            // Get all due notifications from repository
            val dueNotifications = notificationRepository.getDueNotifications().first()
            var count = 0
            
            // Process each notification that's due
            for (notification in dueNotifications) {
                // Show the notification
                val shown = notificationManager.showNotification(notification)
                
                if (shown) {
                    // Update the notification status
                    notificationRepository.markAsSent(notification.id)
                    count++
                }
            }
            
            LogUtils.d(TAG, "Processed $count notifications")
            return count
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error processing notifications", e)
            return 0
        }
    }

    /**
     * Updates notification scheduling based on changed user preferences
     */
    fun updateNotificationPreferences() {
        LogUtils.d(TAG, "Updating notification preferences")
        
        // Cancel existing scheduled notification workers
        workManager.cancelAllWorkByTag(NotificationConstants.WORKER_TAGS.DAILY_REMINDER_WORKER_TAG)
        workManager.cancelAllWorkByTag(NotificationConstants.WORKER_TAGS.STREAK_REMINDER_WORKER_TAG)
        workManager.cancelAllWorkByTag(NotificationConstants.WORKER_TAGS.AFFIRMATION_WORKER_TAG)
        
        // Reschedule notifications with updated preferences
        scheduleDailyReminders()
        scheduleStreakReminders()
        scheduleAffirmations()
        
        LogUtils.d(TAG, "Notification preferences updated")
    }

    /**
     * Snoozes a notification for a specified duration
     * @return true if snooze was successful, false otherwise
     */
    suspend fun snoozeNotification(notificationId: String, snoozeDurationMinutes: Int): Boolean {
        LogUtils.d(TAG, "Snoozing notification: $notificationId for $snoozeDurationMinutes minutes")
        
        try {
            // Calculate new scheduled time
            val newScheduledTime = Date(System.currentTimeMillis() + (snoozeDurationMinutes * 60 * 1000))
            
            // Reschedule the notification in the repository
            val result = notificationRepository.rescheduleNotification(notificationId, newScheduledTime)
            
            if (result > 0) {
                // Cancel the current notification
                val notificationIdHashCode = notificationId.hashCode()
                notificationManager.cancelNotification(notificationIdHashCode)
                
                // Get the notification to find its type
                val notification = notificationRepository.getNotificationById(notificationId).first()
                
                if (notification != null) {
                    // Schedule a new one-time notification
                    scheduleOneTimeNotification(
                        notificationId,
                        notification.notificationType,
                        newScheduledTime
                    )
                    
                    LogUtils.d(TAG, "Notification snoozed successfully")
                    return true
                }
            }
            
            LogUtils.d(TAG, "Failed to snooze notification")
            return false
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error snoozing notification", e)
            return false
        }
    }

    /**
     * Gets the preference key for a specific notification setting
     */
    private fun getNotificationPreferenceKey(notificationType: String, settingType: String): String {
        return "${notificationType}_${settingType}"
    }

    /**
     * Gets the user's preferred time for a notification type
     */
    private suspend fun getPreferredNotificationTime(notificationType: String): Calendar {
        // Get preference keys
        val hourKey = getNotificationPreferenceKey(notificationType, "hour")
        val minuteKey = getNotificationPreferenceKey(notificationType, "minute")
        
        // Get default values based on notification type
        val defaultHour = when (notificationType) {
            NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_HOUR
            NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_STREAK_REMINDER_HOUR
            NotificationConstants.NOTIFICATION_TYPES.AFFIRMATION -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_AFFIRMATION_HOUR
            else -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_HOUR
        }
        
        val defaultMinute = when (notificationType) {
            NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_MINUTE
            NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_STREAK_REMINDER_MINUTE
            NotificationConstants.NOTIFICATION_TYPES.AFFIRMATION -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_AFFIRMATION_MINUTE
            else -> 
                NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_MINUTE
        }
        
        // Get user preferences
        val hour = notificationPreferences.getInt(hourKey, defaultHour)
        val minute = notificationPreferences.getInt(minuteKey, defaultMinute)
        
        // Create calendar with the preferred time
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, hour)
        calendar.set(Calendar.MINUTE, minute)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        
        // If the time has already passed today, schedule for tomorrow
        if (calendar.timeInMillis < System.currentTimeMillis()) {
            calendar.add(Calendar.DAY_OF_MONTH, 1)
        }
        
        return calendar
    }

    /**
     * Gets the user's preferred days for a notification type
     */
    private suspend fun getPreferredNotificationDays(notificationType: String): Set<String> {
        // Get preference key
        val daysKey = getNotificationPreferenceKey(notificationType, "days")
        
        // Get default days
        val defaultDays = NotificationConstants.DEFAULT_SETTINGS.DEFAULT_REMINDER_DAYS
        
        // Get user preference
        return notificationPreferences.getStringSet(daysKey, defaultDays) ?: defaultDays
    }

    /**
     * Calculate the initial delay for notifications based on preferred time
     */
    private fun calculateInitialDelay(preferredTime: Calendar): Long {
        val now = Calendar.getInstance()
        
        if (preferredTime.before(now)) {
            // If preferred time is earlier today, schedule for tomorrow
            preferredTime.add(Calendar.DAY_OF_MONTH, 1)
        }
        
        return preferredTime.timeInMillis - now.timeInMillis
    }

    /**
     * Cleans up old notifications based on retention policy
     * @return The number of notifications deleted
     */
    suspend fun cleanupOldNotifications(): Int {
        LogUtils.d(TAG, "Cleaning up old notifications")
        
        val deletedCount = notificationRepository.cleanupNotifications()
        LogUtils.d(TAG, "Cleaned up $deletedCount old notifications")
        
        return deletedCount
    }
}

/**
 * WorkManager worker that processes and displays due notifications
 */
class NotificationWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        try {
            // Get the application context to access dependencies
            val appContext = applicationContext
            
            // Get NotificationScheduler from dependency injection
            val serviceLocator = appContext as? ServiceLocator
            val notificationScheduler = serviceLocator?.getNotificationScheduler()
            
            if (notificationScheduler != null) {
                // Use runBlocking to run suspend function in Worker context
                kotlinx.coroutines.runBlocking {
                    notificationScheduler.processNotifications()
                }
                return Result.success()
            } else {
                LogUtils.e(TAG, "Could not get NotificationScheduler instance")
                return Result.failure()
            }
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error processing notifications", e)
            return Result.failure()
        }
    }
}

/**
 * WorkManager worker that displays a specific one-time notification
 */
class OneTimeNotificationWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        try {
            // Extract notification ID and type from input data
            val notificationId = inputData.getString(KEY_NOTIFICATION_ID)
            val notificationType = inputData.getString(KEY_NOTIFICATION_TYPE)
            
            if (notificationId != null && notificationType != null) {
                // Get the application context to access dependencies
                val appContext = applicationContext
                val serviceLocator = appContext as? ServiceLocator
                
                // Get required dependencies
                val notificationRepository = serviceLocator?.getNotificationRepository()
                val notificationManager = serviceLocator?.getNotificationManager()
                
                if (notificationRepository != null && notificationManager != null) {
                    // Use runBlocking to run suspend function in Worker context
                    kotlinx.coroutines.runBlocking {
                        // Retrieve the notification
                        val notification = notificationRepository.getNotificationById(notificationId).first()
                        
                        // Display the notification
                        if (notification != null) {
                            notificationManager.showNotification(notification)
                            notificationRepository.markAsSent(notification.id)
                        }
                    }
                    return Result.success()
                }
            }
            
            LogUtils.e(TAG, "Missing notification ID, type, or dependencies")
            return Result.failure()
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error processing one-time notification", e)
            return Result.failure()
        }
    }
}

/**
 * WorkManager worker that creates and schedules daily reminder notifications
 */
class DailyReminderWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        try {
            // Get the application context to access dependencies
            val appContext = applicationContext
            val serviceLocator = appContext as? ServiceLocator
            
            // Get required dependencies
            val notificationRepository = serviceLocator?.getNotificationRepository()
            val notificationScheduler = serviceLocator?.getNotificationScheduler()
            
            if (notificationRepository != null && notificationScheduler != null) {
                // Use runBlocking to run suspend function in Worker context
                kotlinx.coroutines.runBlocking {
                    // Create a daily reminder notification
                    val notificationId = notificationRepository.createDailyReminder().toString()
                    
                    // Schedule it for immediate display
                    notificationScheduler.scheduleOneTimeNotification(
                        notificationId,
                        NotificationConstants.NOTIFICATION_TYPES.DAILY_REMINDER,
                        Date()
                    )
                }
                return Result.success()
            }
            
            LogUtils.e(TAG, "Could not get required dependencies")
            return Result.failure()
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error creating daily reminder", e)
            return Result.failure()
        }
    }
}

/**
 * WorkManager worker that creates and schedules streak reminder notifications
 */
class StreakReminderWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        try {
            // Get the application context to access dependencies
            val appContext = applicationContext
            val serviceLocator = appContext as? ServiceLocator
            
            // Get required dependencies
            val notificationRepository = serviceLocator?.getNotificationRepository()
            val notificationScheduler = serviceLocator?.getNotificationScheduler()
            val streakService = serviceLocator?.getStreakService()
            
            if (notificationRepository != null && notificationScheduler != null && streakService != null) {
                // Use runBlocking to run suspend function in Worker context
                kotlinx.coroutines.runBlocking {
                    // Get current streak count
                    val currentStreak = streakService.getCurrentStreakCount()
                    
                    if (currentStreak > 0) {
                        // Create a streak reminder notification
                        val notificationId = notificationRepository.createStreakReminder(currentStreak).toString()
                        
                        // Schedule it for immediate display
                        notificationScheduler.scheduleOneTimeNotification(
                            notificationId,
                            NotificationConstants.NOTIFICATION_TYPES.STREAK_REMINDER,
                            Date()
                        )
                    }
                }
                return Result.success()
            }
            
            LogUtils.e(TAG, "Could not get required dependencies")
            return Result.failure()
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error creating streak reminder", e)
            return Result.failure()
        }
    }
}

/**
 * WorkManager worker that creates and schedules daily affirmation notifications
 */
class AffirmationWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        try {
            // Get the application context to access dependencies
            val appContext = applicationContext
            val serviceLocator = appContext as? ServiceLocator
            
            // Get required dependencies
            val notificationRepository = serviceLocator?.getNotificationRepository()
            val notificationScheduler = serviceLocator?.getNotificationScheduler()
            
            if (notificationRepository != null && notificationScheduler != null) {
                // Use runBlocking to run suspend function in Worker context
                kotlinx.coroutines.runBlocking {
                    // Get a random affirmation text
                    val affirmationText = getRandomAffirmation()
                    
                    // Create an affirmation notification
                    val notificationId = notificationRepository.createAffirmationNotification(affirmationText).toString()
                    
                    // Schedule it for immediate display
                    notificationScheduler.scheduleOneTimeNotification(
                        notificationId,
                        NotificationConstants.NOTIFICATION_TYPES.AFFIRMATION,
                        Date()
                    )
                }
                return Result.success()
            }
            
            LogUtils.e(TAG, "Could not get required dependencies")
            return Result.failure()
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error creating affirmation", e)
            return Result.failure()
        }
    }
    
    private fun getRandomAffirmation(): String {
        // This would normally come from a repository or service
        val affirmations = listOf(
            "Hoy estoy lleno de energía y rebosante de alegría.",
            "Me acepto tal y como soy y estoy en paz conmigo mismo.",
            "Cada día, de todas formas, estoy mejor y mejor.",
            "Soy consciente de mis emociones y las acepto con compasión.",
            "Estoy agradecido por todas las bendiciones en mi vida."
        )
        return affirmations.random()
    }
}

/**
 * WorkManager worker that cleans up old notifications
 */
class NotificationCleanupWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        try {
            // Get the application context to access dependencies
            val appContext = applicationContext
            val serviceLocator = appContext as? ServiceLocator
            
            // Get required dependencies
            val notificationScheduler = serviceLocator?.getNotificationScheduler()
            
            if (notificationScheduler != null) {
                // Use runBlocking to run suspend function in Worker context
                kotlinx.coroutines.runBlocking {
                    notificationScheduler.cleanupOldNotifications()
                }
                return Result.success()
            }
            
            LogUtils.e(TAG, "Could not get NotificationScheduler instance")
            return Result.failure()
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error cleaning up notifications", e)
            return Result.failure()
        }
    }
}

/**
 * Interface for accessing application services in WorkManager workers
 * This would typically be implemented by the Application class or a dependency injection component
 */
interface ServiceLocator {
    fun getNotificationManager(): NotificationManager
    fun getNotificationRepository(): NotificationRepository
    fun getNotificationScheduler(): NotificationScheduler
    fun getStreakService(): Any // Replace with actual StreakService type
}