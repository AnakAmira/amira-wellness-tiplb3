package com.amirawellness.data.remote.mappers

import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.remote.dto.EmotionalStateDto
import com.amirawellness.core.constants.AppConstants.EmotionType
import java.text.SimpleDateFormat
import java.util.Date
import javax.inject.Inject

/**
 * Mapper class responsible for converting between EmotionalState domain models and
 * EmotionalStateDto data transfer objects in the Amira Wellness Android application.
 * 
 * This class provides bidirectional mapping functionality to facilitate communication
 * between the application and the backend API.
 */
class EmotionalStateMapper @Inject constructor() {
    
    // ISO 8601 date format for handling API date strings
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").apply {
        timeZone = java.util.TimeZone.getTimeZone("UTC")
    }
    
    /**
     * Converts an EmotionalState domain model to an EmotionalStateDto
     *
     * @param domain The domain model to convert
     * @return DTO representation of the domain model
     */
    fun toDto(domain: EmotionalState): EmotionalStateDto {
        return EmotionalStateDto(
            id = domain.id,
            emotionType = mapEmotionTypeToString(domain.emotionType),
            intensity = domain.intensity,
            context = domain.context,
            notes = domain.notes,
            createdAt = dateFormat.format(Date(domain.createdAt)),
            relatedJournalId = domain.relatedJournalId,
            relatedToolId = domain.relatedToolId
        )
    }
    
    /**
     * Converts an EmotionalStateDto to an EmotionalState domain model
     *
     * @param dto The DTO to convert
     * @return Domain model representation of the DTO
     */
    fun toDomain(dto: EmotionalStateDto): EmotionalState {
        return EmotionalState(
            id = dto.id,
            emotionType = mapStringToEmotionType(dto.emotionType),
            intensity = dto.intensity,
            context = dto.context,
            notes = dto.notes,
            createdAt = dateFormat.parse(dto.createdAt)?.time ?: System.currentTimeMillis(),
            relatedJournalId = dto.relatedJournalId,
            relatedToolId = dto.relatedToolId
        )
    }
    
    /**
     * Converts a list of EmotionalStateDto objects to a list of EmotionalState domain models
     *
     * @param dtoList The list of DTOs to convert
     * @return List of domain model representations
     */
    fun toDomainList(dtoList: List<EmotionalStateDto>): List<EmotionalState> {
        return dtoList.map { toDomain(it) }
    }
    
    /**
     * Converts a list of EmotionalState domain models to a list of EmotionalStateDto objects
     *
     * @param domainList The list of domain models to convert
     * @return List of DTO representations
     */
    fun toDtoList(domainList: List<EmotionalState>): List<EmotionalStateDto> {
        return domainList.map { toDto(it) }
    }
    
    /**
     * Maps an EmotionType enum value to its string representation
     *
     * @param emotionType The enum value to map
     * @return String representation of the emotion type
     */
    fun mapEmotionTypeToString(emotionType: EmotionType): String {
        return emotionType.name
    }
    
    /**
     * Maps a string to the corresponding EmotionType enum value
     *
     * @param emotionTypeString The string to map
     * @return Corresponding EmotionType enum value
     */
    fun mapStringToEmotionType(emotionTypeString: String): EmotionType {
        return try {
            EmotionType.valueOf(emotionTypeString)
        } catch (e: IllegalArgumentException) {
            // Default to CALM as a fallback if the string doesn't match any enum value
            EmotionType.CALM
        }
    }
}