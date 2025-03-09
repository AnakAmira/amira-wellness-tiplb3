package com.amirawellness.data.remote.dto

import kotlinx.serialization.Serializable // kotlinx.serialization 1.5+
import kotlinx.serialization.SerialName // kotlinx.serialization 1.5+

/**
 * Data Transfer Object representing an achievement from the API.
 * This class is responsible for serializing and deserializing achievement data
 * when communicating with the backend API.
 */
@Serializable
data class AchievementDto(
    /**
     * Unique identifier for the achievement
     */
    val id: String,
    
    /**
     * Type of achievement (e.g., "streak", "journaling", "milestone")
     */
    val type: String,
    
    /**
     * Category the achievement belongs to (e.g., "STREAK", "JOURNALING", "EMOTIONAL_AWARENESS")
     */
    val category: String,
    
    /**
     * Display title of the achievement
     */
    val title: String,
    
    /**
     * Detailed description of the achievement and how to earn it
     */
    val description: String,
    
    /**
     * URL to the achievement's icon image
     */
    @SerialName("icon_url")
    val iconUrl: String,
    
    /**
     * Point value assigned to this achievement
     */
    val points: Int,
    
    /**
     * Indicates if this achievement should be hidden from the user until earned
     */
    @SerialName("is_hidden")
    val isHidden: Boolean,
    
    /**
     * ISO-8601 formatted timestamp when the achievement was earned (null if not earned)
     */
    @SerialName("earned_at")
    val earnedAt: String? = null,
    
    /**
     * Progress towards earning the achievement (0.0 to 1.0)
     */
    val progress: Double,
    
    /**
     * Additional metadata about the achievement (key-value pairs)
     */
    val metadata: Map<String, String>? = null
)

/**
 * Data Transfer Object representing a list of achievements from the API.
 * This class provides a container for achievement lists when retrieved from the backend.
 * 
 * Used for endpoints that return multiple achievements at once, such as:
 * - GET /achievements (get all user achievements)
 * - GET /achievements/unlocked (get unlocked achievements)
 * - GET /achievements/upcoming (get achievements nearing completion)
 */
@Serializable
data class AchievementListDto(
    /**
     * List of achievement objects
     */
    val achievements: List<AchievementDto>
)