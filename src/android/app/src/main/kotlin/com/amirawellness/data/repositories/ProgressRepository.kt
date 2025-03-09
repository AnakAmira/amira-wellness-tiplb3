package com.amirawellness.data.repositories

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton
import java.util.Date
import java.util.UUID

import com.amirawellness.data.models.Streak
import com.amirawellness.data.models.StreakInfo
import com.amirawellness.data.models.ActivityType
import com.amirawellness.data.models.Achievement
import com.amirawellness.data.models.AchievementCategory
import com.amirawellness.data.models.EmotionalTrend
import com.amirawellness.data.models.PeriodType
import com.amirawellness.data.local.dao.StreakDao
import com.amirawellness.data.local.dao.AchievementDao
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.mappers.AchievementMapper
import com.amirawellness.data.remote.mappers.StreakMapper
import com.amirawellness.core.utils.LogUtils.logDebug
import com.amirawellness.core.utils.LogUtils.logError

private const val TAG = "ProgressRepository"

/**
 * Repository implementation for progress tracking functionality in the Amira Wellness Android application.
 * This class manages user streaks, achievements, emotional trends, and usage statistics,
 * providing a unified interface for accessing progress data from both local database and remote API sources.
 * It implements offline-first functionality with synchronization capabilities.
 */
@Singleton
class ProgressRepository @Inject constructor(
    private val streakDao: StreakDao,
    private val achievementDao: AchievementDao,
    private val apiService: ApiService,
    private val networkMonitor: NetworkMonitor
) {

    /**
     * Gets the user's streak information from local database and syncs with server if online.
     * 
     * @return Flow emitting streak information
     */
    fun getStreakInfo(): Flow<StreakInfo> = flow {
        try {
            // Get streak information from local database
            val localStreakInfo = streakDao.getStreakInfo().first()
            
            // Emit local data first for immediate UI update
            localStreakInfo?.let { emit(it) }
            
            // If network is available, sync with server
            if (networkMonitor.isNetworkAvailable()) {
                val syncSuccessful = syncStreakWithServer()
                if (syncSuccessful) {
                    // Emit updated data after sync
                    val updatedStreakInfo = streakDao.getStreakInfo().first()
                    updatedStreakInfo?.let { emit(it) }
                }
            }
        } catch (e: Exception) {
            logError(TAG, "Error getting streak info", e)
            throw e
        }
    }.catch { e ->
        logError(TAG, "Error in getStreakInfo flow", e)
        // Create an empty StreakInfo if there's an error
        emit(StreakInfo(
            currentStreak = 0,
            longestStreak = 0,
            totalDaysActive = 0,
            lastActiveDate = null,
            nextMilestone = 3,
            progressToNextMilestone = 0f,
            streakHistory = emptyList()
        ))
    }

    /**
     * Updates the user's streak with a new activity and checks for milestone achievements.
     * 
     * @param activityType The type of activity performed
     * @param activityDate The date when the activity was performed
     * @return True if streak was successfully updated, false otherwise
     */
    suspend fun updateStreak(activityType: ActivityType, activityDate: Date = Date()): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Get current user streak from database
                var streak = streakDao.getCurrentUserStreak()
                
                // If no streak exists, create a new one
                if (streak == null) {
                    val newStreak = Streak.Companion.createNew(UUID.randomUUID())
                    streakDao.insertStreak(newStreak)
                    streak = newStreak
                }
                
                // Update the streak with the new activity
                val updatedStreak = streak.updateStreak(activityType, activityDate)
                
                // Save updated streak to database
                val result = streakDao.updateStreak(updatedStreak)
                
                // Check for streak milestone achievements
                if (result > 0) {
                    checkForStreakMilestones(updatedStreak.currentStreak)
                }
                
                result > 0
            } catch (e: Exception) {
                logError(TAG, "Error updating streak", e)
                false
            }
        }
    }

    /**
     * Gets all user achievements from local database and syncs with server if online.
     * 
     * @return Flow emitting list of achievements
     */
    fun getAchievements(): Flow<List<Achievement>> = flow {
        try {
            // Get achievements from local database
            val localAchievements = achievementDao.getAllAchievements().first()
            
            // Emit local data first for immediate UI update
            emit(localAchievements)
            
            // If network is available, sync with server
            if (networkMonitor.isNetworkAvailable()) {
                val syncSuccessful = syncAchievementsWithServer()
                if (syncSuccessful) {
                    // Emit updated data after sync
                    val updatedAchievements = achievementDao.getAllAchievements().first()
                    emit(updatedAchievements)
                }
            }
        } catch (e: Exception) {
            logError(TAG, "Error getting achievements", e)
            throw e
        }
    }.catch { e ->
        logError(TAG, "Error in getAchievements flow", e)
        emit(emptyList<Achievement>())
    }

    /**
     * Gets achievements that have been earned by the user.
     * 
     * @return Flow emitting list of earned achievements
     */
    fun getEarnedAchievements(): Flow<List<Achievement>> = flow {
        try {
            val achievements = achievementDao.getEarnedAchievements().first()
            emit(achievements)
        } catch (e: Exception) {
            logError(TAG, "Error getting earned achievements", e)
            throw e
        }
    }.catch { e ->
        logError(TAG, "Error in getEarnedAchievements flow", e)
        emit(emptyList<Achievement>())
    }

    /**
     * Gets achievements that have not yet been earned by the user.
     * 
     * @return Flow emitting list of pending achievements
     */
    fun getPendingAchievements(): Flow<List<Achievement>> = flow {
        try {
            val achievements = achievementDao.getPendingAchievements().first()
            emit(achievements)
        } catch (e: Exception) {
            logError(TAG, "Error getting pending achievements", e)
            throw e
        }
    }.catch { e ->
        logError(TAG, "Error in getPendingAchievements flow", e)
        emit(emptyList<Achievement>())
    }

    /**
     * Updates the progress value for an achievement.
     * 
     * @param achievementId Unique identifier of the achievement
     * @param progress New progress value (between 0.0 and 1.0)
     * @return True if progress was successfully updated, false otherwise
     */
    suspend fun updateAchievementProgress(achievementId: String, progress: Double): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val normalizedProgress = progress.coerceIn(0.0, 1.0)
                val result = achievementDao.updateAchievementProgress(
                    achievementId = achievementId,
                    progress = normalizedProgress
                )
                
                // If progress is complete, mark achievement as earned
                if (normalizedProgress >= 1.0) {
                    val achievement = achievementDao.getAchievementById(achievementId).first()
                    achievement?.let {
                        if (it.earnedAt == null) {
                            markAchievementAsEarned(achievementId)
                        }
                    }
                }
                
                result > 0
            } catch (e: Exception) {
                logError(TAG, "Error updating achievement progress", e)
                false
            }
        }
    }

    /**
     * Marks an achievement as earned with the current timestamp.
     * 
     * @param achievementId Unique identifier of the achievement
     * @return True if achievement was successfully marked as earned, false otherwise
     */
    suspend fun markAchievementAsEarned(achievementId: String): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val earnedDate = Date()
                val result = achievementDao.markAchievementAsEarned(
                    achievementId = achievementId,
                    earnedAt = earnedDate
                )
                result > 0
            } catch (e: Exception) {
                logError(TAG, "Error marking achievement as earned", e)
                false
            }
        }
    }

    /**
     * Gets emotional trend analysis for a specified time period.
     * 
     * @param periodType The type of period to analyze (DAY, WEEK, MONTH)
     * @param periodValue The number of periods to include
     * @return Flow emitting list of emotional trends
     */
    fun getEmotionalTrends(periodType: PeriodType, periodValue: Int = 1): Flow<List<EmotionalTrend>> = flow {
        try {
            // If network is not available, emit empty list
            if (!networkMonitor.isNetworkAvailable()) {
                emit(emptyList<EmotionalTrend>())
                return@flow
            }
            
            // Calculate date range based on period type and value
            val (startDate, endDate) = calculateDateRange(periodType, periodValue)
            
            // Format dates to string format required by API
            val startDateStr = formatDateForApi(startDate)
            val endDateStr = formatDateForApi(endDate)
            
            // Fetch emotional trends from server
            val response = apiService.getEmotionalTrends(
                startDate = startDateStr,
                endDate = endDateStr
            )
            
            // Process the response - in a real implementation this would convert 
            // API data to EmotionalTrend objects using a mapper
            emit(emptyList<EmotionalTrend>())
        } catch (e: Exception) {
            logError(TAG, "Error getting emotional trends", e)
            throw e
        }
    }.catch { e ->
        logError(TAG, "Error in getEmotionalTrends flow", e)
        emit(emptyList<EmotionalTrend>())
    }

    /**
     * Gets usage statistics for a specified time period.
     * 
     * @param periodType The type of period to analyze (DAY, WEEK, MONTH)
     * @param periodValue The number of periods to include
     * @return Flow emitting progress statistics data
     */
    fun getProgressStatistics(periodType: PeriodType, periodValue: Int = 1): Flow<Map<String, Any>> = flow {
        try {
            // If network is not available, emit empty map
            if (!networkMonitor.isNetworkAvailable()) {
                emit(emptyMap<String, Any>())
                return@flow
            }
            
            // Calculate date range based on period type and value
            val (startDate, endDate) = calculateDateRange(periodType, periodValue)
            
            // Format dates to string format required by API
            val startDateStr = formatDateForApi(startDate)
            val endDateStr = formatDateForApi(endDate)
            
            // Fetch progress statistics from server
            val response = apiService.getProgressStatistics()
            
            emit(response)
        } catch (e: Exception) {
            logError(TAG, "Error getting progress statistics", e)
            throw e
        }
    }.catch { e ->
        logError(TAG, "Error in getProgressStatistics flow", e)
        emit(emptyMap<String, Any>())
    }

    /**
     * Gets comprehensive progress dashboard data.
     * 
     * @return Flow emitting dashboard data
     */
    fun getProgressDashboard(): Flow<Map<String, Any>> = flow {
        try {
            if (networkMonitor.isNetworkAvailable()) {
                // Fetch dashboard data from server if online
                val response = apiService.getProgressDashboard()
                emit(response)
            } else {
                // Create dashboard from local data if offline
                val localDashboard = createLocalDashboard()
                emit(localDashboard)
            }
        } catch (e: Exception) {
            logError(TAG, "Error getting progress dashboard", e)
            throw e
        }
    }.catch { e ->
        logError(TAG, "Error in getProgressDashboard flow", e)
        // Fall back to local dashboard on error
        emit(createLocalDashboard())
    }

    /**
     * Synchronizes achievements with the server.
     * 
     * @return True if sync was successful, false otherwise
     */
    suspend fun syncAchievementsWithServer(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Return false if network is not available
                if (!networkMonitor.isNetworkAvailable()) {
                    return@withContext false
                }
                
                // Fetch achievements from server
                val response = apiService.getAchievements()
                
                // Map response DTOs to domain models
                val achievements = response.map { achievementDto ->
                    AchievementMapper.mapDtoToModel(achievementDto)
                }
                
                // Insert or update achievements in local database
                achievementDao.insertAchievements(achievements)
                
                true
            } catch (e: Exception) {
                logError(TAG, "Error syncing achievements with server", e)
                false
            }
        }
    }

    /**
     * Synchronizes streak information with the server.
     * 
     * @return True if sync was successful, false otherwise
     */
    suspend fun syncStreakWithServer(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Return false if network is not available
                if (!networkMonitor.isNetworkAvailable()) {
                    return@withContext false
                }
                
                // Fetch streak info from server
                val response = apiService.getStreakInfo()
                
                // Map response DTO to domain model
                val streak = StreakMapper.mapDtoToModel(response)
                
                // Get current streak from local database
                val currentStreak = streakDao.getCurrentUserStreak()
                
                if (currentStreak != null) {
                    // Update existing streak with server data
                    val updatedStreak = currentStreak.copy(
                        currentStreak = streak.currentStreak,
                        longestStreak = streak.longestStreak,
                        totalDaysActive = streak.totalDaysActive,
                        lastActivityDate = streak.lastActivityDate,
                        gracePeriodsUsed = streak.gracePeriodsUsed,
                        lastGracePeriodUsed = streak.lastGracePeriodUsed,
                        // Merge local and server streak history, preferring server data
                        streakHistory = mergeStreakHistory(currentStreak.streakHistory, streak.streakHistory),
                        updatedAt = Date()
                    )
                    streakDao.updateStreak(updatedStreak)
                } else {
                    // Insert new streak if none exists locally
                    streakDao.insertStreak(streak)
                }
                
                true
            } catch (e: Exception) {
                logError(TAG, "Error syncing streak with server", e)
                false
            }
        }
    }

    /**
     * Checks if any streak-related achievements should be unlocked based on current streak.
     * 
     * @param currentStreak The current streak value
     * @return True if any achievements were earned, false otherwise
     */
    private suspend fun checkForStreakMilestones(currentStreak: Int): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Get pending achievements in the STREAK category
                val pendingAchievements = achievementDao.getPendingAchievements().first()
                    .filter { it.category == AchievementCategory.STREAK }
                
                var achievementsEarned = false
                
                // Check each achievement to see if milestone is reached
                for (achievement in pendingAchievements) {
                    // Extract milestone value from achievement type or metadata
                    val milestone = getStreakMilestoneForAchievement(achievement)
                    
                    // If current streak meets or exceeds milestone, mark as earned
                    if (milestone != null && currentStreak >= milestone) {
                        markAchievementAsEarned(achievement.id.toString())
                        achievementsEarned = true
                        logDebug(TAG, "Streak achievement unlocked: ${achievement.title}")
                    }
                }
                
                achievementsEarned
            } catch (e: Exception) {
                logError(TAG, "Error checking for streak milestones", e)
                false
            }
        }
    }

    /**
     * Creates a dashboard from local data when offline.
     * 
     * @return Map containing streak and achievement data for the dashboard
     */
    private suspend fun createLocalDashboard(): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            try {
                // Get streak info from local database
                val streakInfo = streakDao.getStreakInfo().first()
                
                // Get earned achievements from local database
                val earnedAchievements = achievementDao.getEarnedAchievements().first()
                
                // Create dashboard map with available local data
                mapOf(
                    "streak" to (streakInfo ?: StreakInfo(
                        currentStreak = 0,
                        longestStreak = 0,
                        totalDaysActive = 0,
                        lastActiveDate = null,
                        nextMilestone = 3,
                        progressToNextMilestone = 0f,
                        streakHistory = emptyList()
                    )),
                    "earnedAchievements" to earnedAchievements,
                    "achievementCount" to earnedAchievements.size,
                    "totalAchievements" to achievementDao.getAchievementCount(),
                    "isOffline" to true
                )
            } catch (e: Exception) {
                logError(TAG, "Error creating local dashboard", e)
                mapOf("error" to "Failed to create dashboard", "isOffline" to true)
            }
        }
    }

    /**
     * Calculates a date range based on period type and value.
     * 
     * @param periodType The type of period to calculate (DAY, WEEK, MONTH)
     * @param periodValue The number of periods to include
     * @return Pair of start and end dates
     */
    private fun calculateDateRange(periodType: PeriodType, periodValue: Int): Pair<Date, Date> {
        val calendar = java.util.Calendar.getInstance()
        val endDate = calendar.time
        
        when (periodType) {
            PeriodType.DAY -> calendar.add(java.util.Calendar.DAY_OF_YEAR, -periodValue)
            PeriodType.WEEK -> calendar.add(java.util.Calendar.WEEK_OF_YEAR, -periodValue)
            PeriodType.MONTH -> calendar.add(java.util.Calendar.MONTH, -periodValue)
        }
        
        val startDate = calendar.time
        return Pair(startDate, endDate)
    }

    /**
     * Formats a date for API requests.
     * 
     * @param date The date to format
     * @return Formatted date string
     */
    private fun formatDateForApi(date: Date): String {
        val formatter = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US)
        formatter.timeZone = java.util.TimeZone.getTimeZone("UTC")
        return formatter.format(date)
    }

    /**
     * Merges local and server streak history, preferring server data for overlapping dates.
     * 
     * @param localHistory List of local daily activities
     * @param serverHistory List of server daily activities
     * @return Merged list of daily activities
     */
    private fun mergeStreakHistory(
        localHistory: List<DailyActivity>,
        serverHistory: List<DailyActivity>
    ): List<DailyActivity> {
        // Create a map of activities by date for quick lookup
        val localHistoryMap = localHistory.associateBy { 
            formatDateForComparison(it.date)
        }
        val serverHistoryMap = serverHistory.associateBy { 
            formatDateForComparison(it.date)
        }
        
        // Create a set of all dates from both histories
        val allDates = localHistoryMap.keys + serverHistoryMap.keys
        
        // For each date, prefer server data if available, otherwise use local data
        return allDates.mapNotNull { dateKey ->
            serverHistoryMap[dateKey] ?: localHistoryMap[dateKey]
        }.sortedBy { it.date }
    }

    /**
     * Formats a date for comparison (stripping time component).
     * 
     * @param date The date to format
     * @return String representation of the date for comparison
     */
    private fun formatDateForComparison(date: Date): String {
        val formatter = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
        return formatter.format(date)
    }

    /**
     * Extracts the streak milestone value from an achievement.
     * 
     * @param achievement The achievement to analyze
     * @return The milestone value or null if not applicable
     */
    private fun getStreakMilestoneForAchievement(achievement: Achievement): Int? {
        // Extract milestone from achievement type
        return when (achievement.type) {
            AchievementType.STREAK_3_DAYS -> 3
            AchievementType.STREAK_7_DAYS -> 7
            AchievementType.STREAK_14_DAYS -> 14
            AchievementType.STREAK_30_DAYS -> 30
            AchievementType.STREAK_60_DAYS -> 60
            AchievementType.STREAK_90_DAYS -> 90
            else -> {
                // Check if milestone is in metadata
                achievement.metadata?.get("streakMilestone") as? Int
            }
        }
    }
}