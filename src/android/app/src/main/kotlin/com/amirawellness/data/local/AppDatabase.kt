package com.amirawellness.data.local

import androidx.room.Database // androidx.room:room-runtime:2.6+
import androidx.room.RoomDatabase // androidx.room:room-runtime:2.6+
import androidx.room.TypeConverters // androidx.room:room-runtime:2.6+
import android.content.Context // android version: latest
import androidx.room.Room // androidx.room:room-runtime:2.6+
import androidx.sqlite.db.SupportSQLiteDatabase // androidx.sqlite.db:2.3+
import androidx.room.migration.Migration // androidx.room:room-runtime:2.6+
import com.amirawellness.data.local.dao.UserDao
import com.amirawellness.data.local.dao.JournalDao
import com.amirawellness.data.local.dao.EmotionalStateDao
import com.amirawellness.data.local.dao.ToolDao
import com.amirawellness.data.local.dao.ToolCategoryDao
import com.amirawellness.data.local.dao.AchievementDao
import com.amirawellness.data.local.dao.StreakDao
import com.amirawellness.data.local.dao.NotificationDao
import com.amirawellness.data.models.User
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.models.Achievement
import com.amirawellness.data.models.Streak
import com.amirawellness.data.models.AppNotification
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.util.Date

private const val DATABASE_NAME = "amira_wellness.db"
private const val DATABASE_VERSION = 1

/**
 * Room database implementation for the Amira Wellness Android application.
 * This abstract class defines the database schema, entities, and provides access 
 * to Data Access Objects (DAOs) for various features including user management, 
 * voice journaling, emotional tracking, tool library, and progress tracking.
 */
@Database(
    entities = [
        User::class, 
        Journal::class, 
        EmotionalState::class, 
        Tool::class, 
        ToolCategory::class, 
        Achievement::class, 
        Streak::class, 
        AppNotification::class
    ],
    version = DATABASE_VERSION,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    /**
     * Provides access to the UserDao interface
     * 
     * @return Data access object for user-related operations
     */
    abstract fun userDao(): UserDao
    
    /**
     * Provides access to the JournalDao interface
     * 
     * @return Data access object for journal-related operations
     */
    abstract fun journalDao(): JournalDao
    
    /**
     * Provides access to the EmotionalStateDao interface
     * 
     * @return Data access object for emotional state-related operations
     */
    abstract fun emotionalStateDao(): EmotionalStateDao
    
    /**
     * Provides access to the ToolDao interface
     * 
     * @return Data access object for tool-related operations
     */
    abstract fun toolDao(): ToolDao
    
    /**
     * Provides access to the ToolCategoryDao interface
     * 
     * @return Data access object for tool category-related operations
     */
    abstract fun toolCategoryDao(): ToolCategoryDao
    
    /**
     * Provides access to the AchievementDao interface
     * 
     * @return Data access object for achievement-related operations
     */
    abstract fun achievementDao(): AchievementDao
    
    /**
     * Provides access to the StreakDao interface
     * 
     * @return Data access object for streak-related operations
     */
    abstract fun streakDao(): StreakDao
    
    /**
     * Provides access to the NotificationDao interface
     * 
     * @return Data access object for notification-related operations
     */
    abstract fun notificationDao(): NotificationDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        /**
         * Gets the singleton instance of the AppDatabase
         * 
         * @param context The application context
         * @return The singleton AppDatabase instance
         */
        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    DATABASE_NAME
                )
                .addCallback(object : RoomDatabase.Callback() {
                    override fun onCreate(db: SupportSQLiteDatabase) {
                        super.onCreate(db)
                        // This callback will be invoked when the database is created for the first time
                        // We can pre-populate data here if needed (e.g., default tool categories)
                    }
                })
                .build()
                INSTANCE = instance
                instance
            }
        }

        // Migration definitions for database schema updates
        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // Placeholder for future migration from version 1 to 2
                // Will be implemented when schema changes are required
            }
        }
    }
}

/**
 * Type converters for custom data types used in the database
 */
class Converters {
    private val gson = Gson()

    /**
     * Converts a Long timestamp to a Date object
     * 
     * @param value Timestamp in milliseconds
     * @return Date object or null if input is null
     */
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    /**
     * Converts a Date object to a Long timestamp
     * 
     * @param date Date object
     * @return Timestamp or null if input is null
     */
    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }

    /**
     * Converts a List of Strings to a JSON string
     * 
     * @param list List of strings
     * @return JSON string or null if input is null
     */
    @TypeConverter
    fun stringListToJson(list: List<String>?): String? {
        return list?.let { gson.toJson(it) }
    }

    /**
     * Converts a JSON string to a List of Strings
     * 
     * @param json JSON string
     * @return List of strings or null if input is null
     */
    @TypeConverter
    fun jsonToStringList(json: String?): List<String>? {
        return json?.let {
            val type = object : TypeToken<List<String>>() {}.type
            gson.fromJson(it, type)
        }
    }

    /**
     * Converts a Map to a JSON string
     * 
     * @param map Map of string keys to any values
     * @return JSON string or null if input is null
     */
    @TypeConverter
    fun mapToJson(map: Map<String, Any>?): String? {
        return map?.let { gson.toJson(it) }
    }

    /**
     * Converts a JSON string to a Map
     * 
     * @param json JSON string
     * @return Map or null if input is null
     */
    @TypeConverter
    fun jsonToMap(json: String?): Map<String, Any>? {
        return json?.let {
            val type = object : TypeToken<Map<String, Any>>() {}.type
            gson.fromJson(it, type)
        }
    }
}