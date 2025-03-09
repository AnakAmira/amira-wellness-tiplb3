package com.amirawellness.data.models

import android.os.Parcelable // Android SDK
import androidx.room.Entity // androidx.room:room-runtime:2.6+
import androidx.room.Embedded // androidx.room:room-runtime:2.6+
import androidx.room.Index // androidx.room:room-runtime:2.6+
import androidx.room.PrimaryKey // androidx.room:room-runtime:2.6+
import androidx.room.TypeConverters // androidx.room:room-runtime:2.6+
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.constants.AppConstants.EmotionCategory
import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.data.database.converters.DateConverter
import com.amirawellness.data.database.converters.EmotionTypeConverter
import com.amirawellness.data.network.dto.EmotionalStateDto
import com.google.gson.annotations.SerializedName // com.google.gson:gson:2.9.0
import kotlinx.parcelize.Parcelize // Kotlin Android Extensions
import java.util.UUID

// Constants for emotion intensity
const val EMOTION_INTENSITY_MIN = 1
const val EMOTION_INTENSITY_MAX = 10
const val EMOTION_INTENSITY_DEFAULT = 5

/**
 * Data model class representing an emotional state in the Amira Wellness Android application.
 * 
 * This model encapsulates information about a user's emotional state including
 * the emotion type, intensity, context, and related metadata. It is used for
 * emotional check-ins, voice journaling, and emotional trend analysis.
 */
@Parcelize
@Entity(
    tableName = "emotional_states",
    indices = [
        Index(value = ["createdAt"], name = "index_emotional_states_created_at"),
        Index(value = ["emotionType"], name = "index_emotional_states_emotion_type"),
        Index(value = ["relatedJournalId"], name = "index_emotional_states_related_journal_id")
    ]
)
@TypeConverters(EmotionTypeConverter::class, DateConverter::class)
data class EmotionalState(
    @PrimaryKey
    @SerializedName("id")
    val id: String?,
    
    @SerializedName("emotionType")
    val emotionType: EmotionType,
    
    @SerializedName("intensity")
    val intensity: Int,
    
    @SerializedName("context")
    val context: String,
    
    @SerializedName("notes")
    val notes: String?,
    
    @SerializedName("createdAt")
    val createdAt: Long,
    
    @SerializedName("relatedJournalId")
    val relatedJournalId: String?,
    
    @SerializedName("relatedToolId")
    val relatedToolId: String?
) : Parcelable {

    /**
     * Returns the category of the emotion (POSITIVE, NEGATIVE, NEUTRAL)
     * 
     * @return Category of the emotion
     */
    fun getCategory(): EmotionCategory {
        return when (emotionType) {
            EmotionType.JOY, EmotionType.TRUST, EmotionType.ANTICIPATION, EmotionType.CALM -> EmotionCategory.POSITIVE
            EmotionType.SADNESS, EmotionType.ANGER, EmotionType.FEAR, EmotionType.DISGUST, EmotionType.ANXIETY -> EmotionCategory.NEGATIVE
            EmotionType.SURPRISE -> EmotionCategory.NEUTRAL
            else -> EmotionCategory.NEUTRAL
        }
    }
    
    /**
     * Checks if this emotional state has a positive category
     * 
     * @return True if the emotion is positive, false otherwise
     */
    fun isPositive(): Boolean = getCategory() == EmotionCategory.POSITIVE
    
    /**
     * Checks if this emotional state has a negative category
     * 
     * @return True if the emotion is negative, false otherwise
     */
    fun isNegative(): Boolean = getCategory() == EmotionCategory.NEGATIVE
    
    /**
     * Checks if this emotional state has a neutral category
     * 
     * @return True if the emotion is neutral, false otherwise
     */
    fun isNeutral(): Boolean = getCategory() == EmotionCategory.NEUTRAL
    
    /**
     * Returns the localized display name for the emotion
     * 
     * @return Localized display name
     */
    fun getDisplayName(): String {
        return when (emotionType) {
            EmotionType.JOY -> "Alegría"
            EmotionType.SADNESS -> "Tristeza"
            EmotionType.ANGER -> "Enojo"
            EmotionType.FEAR -> "Miedo"
            EmotionType.DISGUST -> "Disgusto"
            EmotionType.SURPRISE -> "Sorpresa"
            EmotionType.TRUST -> "Confianza"
            EmotionType.ANTICIPATION -> "Anticipación"
            EmotionType.ANXIETY -> "Ansiedad"
            EmotionType.CALM -> "Calma"
            else -> "Desconocida"
        }
    }
    
    /**
     * Returns the color code associated with the emotion
     * 
     * @return Hex color code
     */
    fun getColor(): String {
        return when (emotionType) {
            EmotionType.JOY -> "#FFD700" // Gold
            EmotionType.SADNESS -> "#4682B4" // Steel Blue
            EmotionType.ANGER -> "#FF4500" // Orange Red
            EmotionType.FEAR -> "#800080" // Purple
            EmotionType.DISGUST -> "#32CD32" // Lime Green
            EmotionType.SURPRISE -> "#FF69B4" // Hot Pink
            EmotionType.TRUST -> "#40E0D0" // Turquoise
            EmotionType.ANTICIPATION -> "#FFA500" // Orange
            EmotionType.ANXIETY -> "#8B0000" // Dark Red
            EmotionType.CALM -> "#87CEEB" // Sky Blue
            else -> "#808080" // Grey
        }
    }
    
    /**
     * Converts the EmotionalState model to a DTO for API communication
     * 
     * @return DTO representation of this emotional state
     */
    fun toEmotionalStateDto(): EmotionalStateDto {
        return EmotionalStateDto(
            id = id,
            emotionType = emotionType.name,
            intensity = intensity,
            context = context,
            notes = notes,
            createdAt = createdAt,
            relatedJournalId = relatedJournalId,
            relatedToolId = relatedToolId
        )
    }
    
    companion object {
        /**
         * Creates an EmotionalState instance from a DTO
         * 
         * @param dto The DTO to convert from
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: EmotionalStateDto): EmotionalState {
            return EmotionalState(
                id = dto.id,
                emotionType = try {
                    EmotionType.valueOf(dto.emotionType)
                } catch (e: IllegalArgumentException) {
                    EmotionType.JOY // Default to a positive emotion if unknown
                },
                intensity = dto.intensity.coerceIn(EMOTION_INTENSITY_MIN, EMOTION_INTENSITY_MAX),
                context = dto.context,
                notes = dto.notes,
                createdAt = dto.createdAt,
                relatedJournalId = dto.relatedJournalId,
                relatedToolId = dto.relatedToolId
            )
        }
        
        /**
         * Creates an empty EmotionalState instance with default values
         * 
         * @param emotionType The emotion type to set
         * @param context The context in which this emotional state occurs
         * @return Empty model instance with default values
         */
        fun createEmpty(emotionType: EmotionType, context: String): EmotionalState {
            return EmotionalState(
                id = UUID.randomUUID().toString(),
                emotionType = emotionType,
                intensity = EMOTION_INTENSITY_DEFAULT,
                context = context,
                notes = null,
                createdAt = System.currentTimeMillis(),
                relatedJournalId = null,
                relatedToolId = null
            )
        }
        
        /**
         * Calculates the emotional shift between two emotional states
         * 
         * @param preState The emotional state before (e.g., pre-journaling)
         * @param postState The emotional state after (e.g., post-journaling)
         * @return Intensity change value (positive for improvement, negative for decline)
         */
        fun calculateEmotionalShift(preState: EmotionalState, postState: EmotionalState): Int {
            val intensityChange = postState.intensity - preState.intensity
            
            // Apply category-based multipliers
            return when {
                // Positive to positive: direct intensity change
                preState.isPositive() && postState.isPositive() -> intensityChange
                
                // Negative to negative: reverse intensity change (less negative is better)
                preState.isNegative() && postState.isNegative() -> -intensityChange
                
                // Positive to negative: negative change
                preState.isPositive() && postState.isNegative() -> 
                    -((preState.intensity + postState.intensity) / 2)
                
                // Negative to positive: positive change
                preState.isNegative() && postState.isPositive() -> 
                    ((preState.intensity + postState.intensity) / 2)
                
                // Involving neutral: simpler calculation
                else -> intensityChange
            }
        }
    }
}