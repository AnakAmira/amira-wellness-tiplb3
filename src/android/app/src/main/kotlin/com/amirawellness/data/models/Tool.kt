package com.amirawellness.data.models

import android.os.Parcelable // android version: latest
import androidx.room.ColumnInfo // androidx.room:2.6+
import androidx.room.Entity // androidx.room:2.6+
import androidx.room.PrimaryKey // androidx.room:2.6+
import androidx.room.TypeConverters // androidx.room:2.6+
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.google.gson.annotations.SerializedName // com.google.gson:gson:2.9.0
import kotlinx.parcelize.Parcelize // Kotlin Android Extensions
import java.util.UUID

// Tool duration constraints in minutes
const val TOOL_DURATION_MIN = 1
const val TOOL_DURATION_MAX = 60
const val TOOL_DURATION_DEFAULT = 5

/**
 * Enumeration of different types of tool content.
 */
enum class ToolContentType {
    TEXT,
    AUDIO,
    VIDEO,
    INTERACTIVE,
    GUIDED_EXERCISE
}

/**
 * Data class representing an emotional regulation tool in the Amira Wellness application.
 * This model encapsulates information about tools including their content, category,
 * target emotions, and usage metrics.
 */
@Parcelize
@Entity(
    tableName = "tools",
    indices = [
        androidx.room.Index(name = "index_tools_category", value = ["category"]),
        androidx.room.Index(name = "index_tools_is_favorite", value = ["isFavorite"]),
        androidx.room.Index(name = "index_tools_content_type", value = ["contentType"])
    ]
)
@TypeConverters(
    ToolContentTypeConverter::class,
    EmotionTypeListConverter::class,
    ToolContentConverter::class,
    ToolCategoryConverter::class
)
data class Tool(
    @PrimaryKey
    @ColumnInfo(name = "id")
    @SerializedName("id")
    val id: String,
    
    @ColumnInfo(name = "name")
    @SerializedName("name")
    val name: String,
    
    @ColumnInfo(name = "description")
    @SerializedName("description")
    val description: String,
    
    @ColumnInfo(name = "category")
    @SerializedName("category")
    val category: ToolCategory,
    
    @ColumnInfo(name = "contentType")
    @SerializedName("contentType")
    val contentType: ToolContentType,
    
    @ColumnInfo(name = "content")
    @SerializedName("content")
    val content: ToolContent,
    
    @ColumnInfo(name = "isFavorite", defaultValue = "0")
    @SerializedName("isFavorite")
    val isFavorite: Boolean,
    
    @ColumnInfo(name = "usageCount", defaultValue = "0")
    @SerializedName("usageCount")
    val usageCount: Int,
    
    @ColumnInfo(name = "targetEmotions")
    @SerializedName("targetEmotions")
    val targetEmotions: List<EmotionType>,
    
    @ColumnInfo(name = "estimatedDuration", defaultValue = "$TOOL_DURATION_DEFAULT")
    @SerializedName("estimatedDuration")
    val estimatedDuration: Int
) : Parcelable {
    
    /**
     * Checks if this tool is targeted for a specific emotion.
     *
     * @param emotionType The emotion type to check against
     * @return True if the tool targets the emotion, false otherwise
     */
    fun isTargetedForEmotion(emotionType: EmotionType): Boolean {
        return emotionType in targetEmotions
    }
    
    /**
     * Toggles the favorite status of this tool.
     *
     * @return Updated tool with toggled favorite status
     */
    fun toggleFavorite(): Tool {
        return copy(isFavorite = !isFavorite)
    }
    
    /**
     * Increments the usage count of this tool.
     *
     * @return Updated tool with incremented usage count
     */
    fun incrementUsageCount(): Tool {
        return copy(usageCount = usageCount + 1)
    }
    
    /**
     * Converts the Tool model to a DTO for API communication.
     *
     * @return DTO representation of this tool
     */
    fun toToolDto(): ToolDto {
        return ToolDto(
            id = id,
            name = name,
            description = description,
            category = category.toToolCategoryDto(),
            contentType = contentType.toString(),
            content = content.toToolContentDto(),
            isFavorite = isFavorite,
            usageCount = usageCount,
            targetEmotions = targetEmotions.map { it.toString() },
            estimatedDuration = estimatedDuration
        )
    }
    
    companion object {
        /**
         * Creates a Tool instance from a DTO.
         *
         * @param dto The DTO to convert from
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: ToolDto): Tool {
            return Tool(
                id = dto.id,
                name = dto.name,
                description = dto.description,
                category = ToolCategory.fromDto(dto.category),
                contentType = ToolContentType.valueOf(dto.contentType),
                content = ToolContent.fromDto(dto.content),
                isFavorite = dto.isFavorite,
                usageCount = dto.usageCount,
                targetEmotions = dto.targetEmotions.map { EmotionType.valueOf(it) },
                estimatedDuration = dto.estimatedDuration
            )
        }
        
        /**
         * Creates an empty Tool instance with default values.
         * Useful for initializing new tools in the UI before saving.
         *
         * @return Empty model instance with default values
         */
        fun createEmpty(): Tool {
            return Tool(
                id = UUID.randomUUID().toString(),
                name = "",
                description = "",
                category = ToolCategory.createEmpty(),
                contentType = ToolContentType.TEXT,
                content = ToolContent(
                    title = "",
                    instructions = "",
                    mediaUrl = null,
                    steps = null,
                    additionalResources = null
                ),
                isFavorite = false,
                usageCount = 0,
                targetEmotions = emptyList(),
                estimatedDuration = TOOL_DURATION_DEFAULT
            )
        }
    }
}

/**
 * Data class representing the content of a tool.
 * Contains all the information needed to present and use the tool.
 */
@Parcelize
data class ToolContent(
    @SerializedName("title")
    val title: String,
    
    @SerializedName("instructions")
    val instructions: String,
    
    @SerializedName("mediaUrl")
    val mediaUrl: String?,
    
    @SerializedName("steps")
    val steps: List<ToolStep>?,
    
    @SerializedName("additionalResources")
    val additionalResources: List<Resource>?
) : Parcelable {
    
    /**
     * Converts the ToolContent model to a DTO for API communication.
     *
     * @return DTO representation of this content
     */
    fun toToolContentDto(): ToolContentDto {
        return ToolContentDto(
            title = title,
            instructions = instructions,
            mediaUrl = mediaUrl,
            steps = steps?.map { it.toToolStepDto() },
            additionalResources = additionalResources?.map { it.toResourceDto() }
        )
    }
    
    companion object {
        /**
         * Creates a ToolContent instance from a DTO.
         *
         * @param dto The DTO to convert from
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: ToolContentDto): ToolContent {
            return ToolContent(
                title = dto.title,
                instructions = dto.instructions,
                mediaUrl = dto.mediaUrl,
                steps = dto.steps?.map { ToolStep.fromDto(it) },
                additionalResources = dto.additionalResources?.map { Resource.fromDto(it) }
            )
        }
    }
}

/**
 * Data class representing a step in a tool's guided exercise.
 * Contains information about a single step in a multi-step tool.
 */
@Parcelize
data class ToolStep(
    @SerializedName("order")
    val order: Int,
    
    @SerializedName("title")
    val title: String,
    
    @SerializedName("description")
    val description: String,
    
    @SerializedName("duration")
    val duration: Int,
    
    @SerializedName("mediaUrl")
    val mediaUrl: String?
) : Parcelable {
    
    /**
     * Converts the ToolStep model to a DTO for API communication.
     *
     * @return DTO representation of this step
     */
    fun toToolStepDto(): ToolStepDto {
        return ToolStepDto(
            order = order,
            title = title,
            description = description,
            duration = duration,
            mediaUrl = mediaUrl
        )
    }
    
    companion object {
        /**
         * Creates a ToolStep instance from a DTO.
         *
         * @param dto The DTO to convert from
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: ToolStepDto): ToolStep {
            return ToolStep(
                order = dto.order,
                title = dto.title,
                description = dto.description,
                duration = dto.duration,
                mediaUrl = dto.mediaUrl
            )
        }
    }
}

/**
 * Enumeration of different types of additional resources.
 */
enum class ResourceType {
    ARTICLE,
    AUDIO,
    VIDEO,
    EXTERNAL_LINK
}

/**
 * Data class representing an additional resource for a tool.
 * Provides supplementary content for tools.
 */
@Parcelize
data class Resource(
    @SerializedName("title")
    val title: String,
    
    @SerializedName("description")
    val description: String,
    
    @SerializedName("url")
    val url: String,
    
    @SerializedName("type")
    val type: ResourceType
) : Parcelable {
    
    /**
     * Converts the Resource model to a DTO for API communication.
     *
     * @return DTO representation of this resource
     */
    fun toResourceDto(): ResourceDto {
        return ResourceDto(
            title = title,
            description = description,
            url = url,
            type = type.toString()
        )
    }
    
    companion object {
        /**
         * Creates a Resource instance from a DTO.
         *
         * @param dto The DTO to convert from
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: ResourceDto): Resource {
            return Resource(
                title = dto.title,
                description = dto.description,
                url = dto.url,
                type = ResourceType.valueOf(dto.type)
            )
        }
    }
}