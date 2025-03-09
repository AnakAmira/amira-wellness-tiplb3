package com.amirawellness.data.remote.dto

import android.os.Parcelable // Android SDK
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.google.gson.annotations.SerializedName // version: 2.9.0
import kotlinx.parcelize.Parcelize // Kotlin Android Extensions

/**
 * Data Transfer Object (DTO) for tools in the Amira Wellness Android application.
 * This class represents the network model for emotional regulation tools and is used for
 * serialization/deserialization when communicating with the backend API.
 */
@Parcelize
data class ToolDto(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("name")
    val name: String,
    
    @SerializedName("description")
    val description: String,
    
    @SerializedName("category")
    val category: ToolCategoryDto,
    
    @SerializedName("contentType")
    val contentType: String,
    
    @SerializedName("content")
    val content: ToolContentDto,
    
    @SerializedName("isFavorite")
    val isFavorite: Boolean,
    
    @SerializedName("usageCount")
    val usageCount: Int,
    
    @SerializedName("targetEmotions")
    val targetEmotions: List<String>, // String representations of emotion types
    
    @SerializedName("estimatedDuration")
    val estimatedDuration: Int
) : Parcelable

/**
 * Data Transfer Object for a tool category in the Amira Wellness application.
 * Used to organize tools into logical groupings for user navigation and discovery.
 */
@Parcelize
data class ToolCategoryDto(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("name")
    val name: String,
    
    @SerializedName("description")
    val description: String,
    
    @SerializedName("iconUrl")
    val iconUrl: String?,
    
    @SerializedName("toolCount")
    val toolCount: Int
) : Parcelable

/**
 * Data Transfer Object for tool content in the Amira Wellness application.
 * Contains the actual content and instructions for using the emotional regulation tool.
 */
@Parcelize
data class ToolContentDto(
    @SerializedName("title")
    val title: String,
    
    @SerializedName("instructions")
    val instructions: String,
    
    @SerializedName("mediaUrl")
    val mediaUrl: String?,
    
    @SerializedName("steps")
    val steps: List<ToolStepDto>?,
    
    @SerializedName("additionalResources")
    val additionalResources: List<ResourceDto>?
) : Parcelable

/**
 * Data Transfer Object for a step in a tool's guided exercise.
 * Represents a sequential step in a multi-step emotional regulation exercise or technique.
 */
@Parcelize
data class ToolStepDto(
    @SerializedName("order")
    val order: Int,
    
    @SerializedName("title")
    val title: String,
    
    @SerializedName("description")
    val description: String,
    
    @SerializedName("duration")
    val duration: Int, // Duration in seconds
    
    @SerializedName("mediaUrl")
    val mediaUrl: String?
) : Parcelable

/**
 * Data Transfer Object for an additional resource associated with a tool.
 * Represents supplementary materials that can enhance the tool experience,
 * such as articles, audio guides, or external links.
 */
@Parcelize
data class ResourceDto(
    @SerializedName("title")
    val title: String,
    
    @SerializedName("description")
    val description: String,
    
    @SerializedName("url")
    val url: String,
    
    @SerializedName("type")
    val type: String
) : Parcelable