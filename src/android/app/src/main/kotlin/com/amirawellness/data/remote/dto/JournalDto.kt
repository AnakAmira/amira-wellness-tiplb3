package com.amirawellness.data.remote.dto

import com.google.gson.annotations.SerializedName // v2.9.0
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Data Transfer Object for audio metadata associated with a journal entry.
 * Contains technical details about the audio recording.
 */
data class AudioMetadataDto(
    @SerializedName("id")
    val id: String? = null,
    
    @SerializedName("journal_id")
    val journalId: String? = null,
    
    @SerializedName("file_format")
    val fileFormat: String,
    
    @SerializedName("file_size_bytes")
    val fileSizeBytes: Int,
    
    @SerializedName("sample_rate")
    val sampleRate: Int,
    
    @SerializedName("bit_rate")
    val bitRate: Int,
    
    @SerializedName("channels")
    val channels: Int,
    
    @SerializedName("checksum")
    val checksum: String
) {
    /**
     * Converts this AudioMetadataDto to an AudioMetadata domain model.
     *
     * @return Domain model representation of this DTO
     */
    fun toDomain(): AudioMetadata {
        // Parse the id string to UUID if not null, otherwise generate a new UUID
        val uuid = id?.let { UUID.fromString(it) } ?: UUID.randomUUID()
        
        // Parse the journalId string to UUID if not null
        val journalUuid = journalId?.let { UUID.fromString(it) }
        
        // Create and return a new AudioMetadata object with the converted values
        return AudioMetadata(
            id = uuid,
            journalId = journalUuid,
            fileFormat = fileFormat,
            fileSizeBytes = fileSizeBytes,
            sampleRate = sampleRate,
            bitRate = bitRate,
            channels = channels,
            checksum = checksum
        )
    }
}

/**
 * Data Transfer Object for journal entries used in API communication.
 * This class is responsible for serializing and deserializing journal data
 * for API communication between the mobile app and backend services.
 * 
 * It includes properties for journal metadata, emotional states before and
 * after recording, and audio recording details, supporting the voice journaling feature
 * with emotional check-ins as defined in the requirements.
 */
data class JournalDto(
    @SerializedName("id")
    val id: String? = null,
    
    @SerializedName("user_id")
    val userId: String,
    
    @SerializedName("created_at")
    val createdAt: String,
    
    @SerializedName("updated_at")
    val updatedAt: String? = null,
    
    @SerializedName("title")
    val title: String,
    
    @SerializedName("duration_seconds")
    val durationSeconds: Int,
    
    @SerializedName("is_favorite")
    val isFavorite: Boolean,
    
    @SerializedName("is_uploaded")
    val isUploaded: Boolean,
    
    @SerializedName("storage_path")
    val storagePath: String? = null,
    
    @SerializedName("encryption_iv")
    val encryptionIv: String? = null,
    
    @SerializedName("pre_emotional_state")
    val preEmotionalState: EmotionalStateDto,
    
    @SerializedName("post_emotional_state")
    val postEmotionalState: EmotionalStateDto,
    
    @SerializedName("audio_metadata")
    val audioMetadata: AudioMetadataDto? = null
) {
    /**
     * Converts this JournalDto to a Journal domain model.
     *
     * @return Domain model representation of this DTO
     */
    fun toDomain(): Journal {
        // Parse the id string to UUID if not null, otherwise generate a new UUID
        val uuid = id?.let { UUID.fromString(it) } ?: UUID.randomUUID()
        
        // Parse the userId string to UUID
        val userUuid = UUID.fromString(userId)
        
        // Parse the createdAt and updatedAt date strings to timestamps
        val createdTimestamp = Instant.parse(createdAt)
        val updatedTimestamp = updatedAt?.let { Instant.parse(it) }
        
        // Convert the pre and post emotional states to domain models
        val preEmotionalStateDomain = preEmotionalState.toDomain()
        val postEmotionalStateDomain = postEmotionalState.toDomain()
        
        // Convert the audio metadata to domain model if present
        val audioMetadataDomain = audioMetadata?.toDomain()
        
        // Create and return a new Journal object with the converted values
        return Journal(
            id = uuid,
            userId = userUuid,
            createdAt = createdTimestamp,
            updatedAt = updatedTimestamp,
            title = title,
            durationSeconds = durationSeconds,
            isFavorite = isFavorite,
            isUploaded = isUploaded,
            storagePath = storagePath,
            encryptionIv = encryptionIv,
            preEmotionalState = preEmotionalStateDomain,
            postEmotionalState = postEmotionalStateDomain,
            audioMetadata = audioMetadataDomain
        )
    }
    
    companion object {
        /**
         * Creates a JournalDto from a Journal domain model.
         *
         * @param journal The domain model to convert
         * @return DTO representation of the domain model
         */
        fun fromDomain(journal: Journal): JournalDto {
            // Convert UUID to string
            val idString = journal.id.toString()
            val userIdString = journal.userId.toString()
            
            // Format the createdAt and updatedAt timestamps to ISO string format
            val createdAtString = DateTimeFormatter.ISO_INSTANT.format(journal.createdAt)
            val updatedAtString = journal.updatedAt?.let { DateTimeFormatter.ISO_INSTANT.format(it) }
            
            // Convert the pre and post emotional states to DTOs
            val preEmotionalStateDto = EmotionalStateDto.Companion.fromDomain(journal.preEmotionalState)
            val postEmotionalStateDto = EmotionalStateDto.Companion.fromDomain(journal.postEmotionalState)
            
            // Convert the audio metadata to DTO if present
            val audioMetadataDto = journal.audioMetadata?.let { 
                AudioMetadataDto(
                    id = it.id.toString(),
                    journalId = journal.id.toString(),
                    fileFormat = it.fileFormat,
                    fileSizeBytes = it.fileSizeBytes,
                    sampleRate = it.sampleRate,
                    bitRate = it.bitRate,
                    channels = it.channels,
                    checksum = it.checksum
                )
            }
            
            // Create and return a new JournalDto with the converted values
            return JournalDto(
                id = idString,
                userId = userIdString,
                createdAt = createdAtString,
                updatedAt = updatedAtString,
                title = journal.title,
                durationSeconds = journal.durationSeconds,
                isFavorite = journal.isFavorite,
                isUploaded = journal.isUploaded,
                storagePath = journal.storagePath,
                encryptionIv = journal.encryptionIv,
                preEmotionalState = preEmotionalStateDto,
                postEmotionalState = postEmotionalStateDto,
                audioMetadata = audioMetadataDto
            )
        }
    }
}