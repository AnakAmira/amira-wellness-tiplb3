package com.amirawellness.data.models

import android.os.Parcelable
import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.google.gson.annotations.SerializedName
import kotlinx.parcelize.Parcelize
import java.util.UUID

/**
 * Data class representing a category for organizing emotional regulation tools.
 * This model is used in the Tool Library feature of Amira Wellness to categorize
 * various emotional wellness tools and exercises.
 */
@Parcelize
@Entity(
    tableName = "tool_categories",
    indices = [Index(
        name = "index_tool_categories_name",
        value = ["name"],
        unique = true
    )]
)
data class ToolCategory(
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
    
    @ColumnInfo(name = "icon_url")
    @SerializedName("iconUrl")
    val iconUrl: String?,
    
    @ColumnInfo(name = "tool_count", defaultValue = "0")
    @SerializedName("toolCount")
    val toolCount: Int
) : Parcelable {
    
    /**
     * Converts the ToolCategory model to a DTO for API communication.
     * 
     * @return DTO representation of this category
     */
    fun toToolCategoryDto(): ToolCategoryDto {
        return ToolCategoryDto(
            id = id,
            name = name,
            description = description,
            iconUrl = iconUrl,
            toolCount = toolCount
        )
    }
    
    companion object {
        /**
         * Creates a ToolCategory instance from a DTO.
         * 
         * @param dto The DTO to convert from
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: ToolCategoryDto): ToolCategory {
            return ToolCategory(
                id = dto.id,
                name = dto.name,
                description = dto.description,
                iconUrl = dto.iconUrl,
                toolCount = dto.toolCount
            )
        }
        
        /**
         * Creates an empty ToolCategory instance with default values.
         * Useful for initializing new categories in the UI before saving.
         * 
         * @return Empty model instance with default values
         */
        fun createEmpty(): ToolCategory {
            return ToolCategory(
                id = UUID.randomUUID().toString(),
                name = "",
                description = "",
                iconUrl = null,
                toolCount = 0
            )
        }
    }
}