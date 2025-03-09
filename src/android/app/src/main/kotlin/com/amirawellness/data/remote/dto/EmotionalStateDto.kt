package com.amirawellness.data.remote.dto

import com.google.gson.annotations.SerializedName // v2.9.0
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Data Transfer Object for emotional state data used in API communication.
 * This class handles serialization and deserialization of emotional state data
 * for API communication between the mobile app and backend services.
 *
 * Valid emotion types include: JOY, SADNESS, ANGER, FEAR, DISGUST, SURPRISE, TRUST, 
 * ANTICIPATION, ANXIETY, CALM
 * 
 * Valid contexts include: PRE_JOURNALING, POST_JOURNALING, STANDALONE, TOOL_USAGE, 
 * DAILY_CHECK_IN
 */
data class EmotionalStateDto(
    @SerializedName("id")
    val id: String? = null,
    
    @SerializedName("emotion_type")
    val emotionType: String,
    
    @SerializedName("intensity")
    val intensity: Int,
    
    @SerializedName("context")
    val context: String,
    
    @SerializedName("notes")
    val notes: String? = null,
    
    @SerializedName("created_at")
    val createdAt: String,
    
    @SerializedName("related_journal_id")
    val relatedJournalId: String? = null,
    
    @SerializedName("related_tool_id")
    val relatedToolId: String? = null
) {
    /**
     * Converts this DTO to a domain model.
     * 
     * Note: This method assumes the existence of an EmotionalState domain model and 
     * EmotionType enum in the domain layer of the application.
     *
     * @return Domain model representation of this DTO
     */
    fun toDomain(): EmotionalState {
        // Parse the id string to UUID if not null, otherwise generate a new UUID
        val uuid = id?.let { UUID.fromString(it) } ?: UUID.randomUUID()
        
        // Convert the emotionType string to the corresponding EmotionType enum value
        val emotion = EmotionType.valueOf(emotionType)
        
        // Parse the createdAt date string to a timestamp
        val timestamp = Instant.parse(createdAt)
        
        // Create and return a new EmotionalState object with the converted values
        return EmotionalState(
            id = uuid,
            emotionType = emotion,
            intensity = intensity,
            context = context,
            notes = notes,
            createdAt = timestamp,
            relatedJournalId = relatedJournalId?.let { UUID.fromString(it) },
            relatedToolId = relatedToolId?.let { UUID.fromString(it) }
        )
    }

    companion object {
        /**
         * Creates a DTO from a domain model.
         * 
         * Note: This method assumes the existence of an EmotionalState domain model
         * in the domain layer of the application.
         *
         * @param emotionalState The domain model to convert
         * @return DTO representation of the domain model
         */
        fun fromDomain(emotionalState: EmotionalState): EmotionalStateDto {
            // Convert UUID to string
            val idString = emotionalState.id.toString()
            
            // Convert the EmotionType enum to its string representation
            val emotionTypeString = emotionalState.emotionType.name
            
            // Format the createdAt timestamp to ISO string format
            val createdAtString = DateTimeFormatter.ISO_INSTANT.format(emotionalState.createdAt)
            
            // Create and return a new EmotionalStateDto with the converted values
            return EmotionalStateDto(
                id = idString,
                emotionType = emotionTypeString,
                intensity = emotionalState.intensity,
                context = emotionalState.context,
                notes = emotionalState.notes,
                createdAt = createdAtString,
                relatedJournalId = emotionalState.relatedJournalId?.toString(),
                relatedToolId = emotionalState.relatedToolId?.toString()
            )
        }
    }
}