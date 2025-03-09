package com.amirawellness.data.remote.mappers

import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.AudioMetadata
import com.amirawellness.data.remote.dto.JournalDto
import com.amirawellness.data.remote.dto.AudioMetadataDto
import com.amirawellness.data.remote.mappers.EmotionalStateMapper
import java.text.SimpleDateFormat // JDK
import java.util.Date // JDK
import java.util.UUID // JDK
import javax.inject.Inject // 1.0

/**
 * Mapper class responsible for converting between Journal domain models and
 * JournalDto data transfer objects in the Amira Wellness Android application.
 * 
 * This class provides bidirectional mapping functionality to facilitate communication
 * between the application and the backend API for voice journal entries.
 */
class JournalMapper @Inject constructor(
    private val emotionalStateMapper: EmotionalStateMapper
) {
    // ISO 8601 date format for handling API date strings
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").apply {
        timeZone = java.util.TimeZone.getTimeZone("UTC")
    }
    
    /**
     * Converts a Journal domain model to a JournalDto
     *
     * @param domain The domain model to convert
     * @return DTO representation of the domain model
     */
    fun toDto(domain: Journal): JournalDto {
        return JournalDto(
            id = domain.id,
            userId = domain.userId,
            createdAt = formatDate(domain.createdAt),
            updatedAt = domain.updatedAt?.let { formatDate(it) },
            title = domain.title,
            durationSeconds = domain.durationSeconds,
            isFavorite = domain.isFavorite,
            isUploaded = domain.isUploaded,
            storagePath = domain.storagePath,
            encryptionIv = domain.encryptionIv,
            preEmotionalState = emotionalStateMapper.toDto(domain.preEmotionalState),
            postEmotionalState = emotionalStateMapper.toDto(domain.postEmotionalState),
            audioMetadata = domain.audioMetadata?.let { audioMetadataToDto(it) }
        )
    }
    
    /**
     * Converts a JournalDto to a Journal domain model
     *
     * @param dto The DTO to convert
     * @return Domain model representation of the DTO
     */
    fun toDomain(dto: JournalDto): Journal {
        return Journal(
            id = dto.id ?: UUID.randomUUID().toString(),
            userId = dto.userId,
            createdAt = parseDate(dto.createdAt),
            updatedAt = dto.updatedAt?.let { parseDate(it) },
            title = dto.title,
            durationSeconds = dto.durationSeconds,
            isFavorite = dto.isFavorite,
            isUploaded = dto.isUploaded,
            localFilePath = null, // This is a client-side property not coming from the DTO
            storagePath = dto.storagePath,
            encryptionIv = dto.encryptionIv,
            preEmotionalState = emotionalStateMapper.toDomain(dto.preEmotionalState),
            postEmotionalState = emotionalStateMapper.toDomain(dto.postEmotionalState),
            audioMetadata = dto.audioMetadata?.let { audioMetadataToDomain(it) }
        )
    }
    
    /**
     * Converts a list of JournalDto objects to a list of Journal domain models
     *
     * @param dtoList The list of DTOs to convert
     * @return List of domain model representations
     */
    fun toDomainList(dtoList: List<JournalDto>): List<Journal> {
        return dtoList.map { toDomain(it) }
    }
    
    /**
     * Converts a list of Journal domain models to a list of JournalDto objects
     *
     * @param domainList The list of domain models to convert
     * @return List of DTO representations
     */
    fun toDtoList(domainList: List<Journal>): List<JournalDto> {
        return domainList.map { toDto(it) }
    }
    
    /**
     * Converts an AudioMetadata domain model to an AudioMetadataDto
     *
     * @param domain The domain model to convert
     * @return DTO representation of the audio metadata
     */
    fun audioMetadataToDto(domain: AudioMetadata): AudioMetadataDto {
        return AudioMetadataDto(
            id = domain.id,
            journalId = domain.journalId,
            fileFormat = domain.fileFormat,
            fileSizeBytes = domain.fileSizeBytes,
            sampleRate = domain.sampleRate,
            bitRate = domain.bitRate,
            channels = domain.channels,
            checksum = domain.checksum
        )
    }
    
    /**
     * Converts an AudioMetadataDto to an AudioMetadata domain model
     *
     * @param dto The DTO to convert
     * @return Domain model representation of the DTO
     */
    fun audioMetadataToDomain(dto: AudioMetadataDto): AudioMetadata {
        return AudioMetadata(
            id = dto.id ?: UUID.randomUUID().toString(),
            journalId = dto.journalId,
            fileFormat = dto.fileFormat,
            fileSizeBytes = dto.fileSizeBytes,
            sampleRate = dto.sampleRate,
            bitRate = dto.bitRate,
            channels = dto.channels,
            checksum = dto.checksum
        )
    }
    
    /**
     * Formats a timestamp to ISO 8601 date string
     *
     * @param timestamp The timestamp to format
     * @return Formatted date string
     */
    private fun formatDate(timestamp: Long): String {
        val date = Date(timestamp)
        return dateFormat.format(date)
    }
    
    /**
     * Parses an ISO 8601 date string to a timestamp
     *
     * @param dateString The date string to parse
     * @return Timestamp in milliseconds
     */
    private fun parseDate(dateString: String): Long {
        return try {
            dateFormat.parse(dateString)?.time ?: System.currentTimeMillis()
        } catch (e: Exception) {
            // If parsing fails, return current time as fallback
            System.currentTimeMillis()
        }
    }
}