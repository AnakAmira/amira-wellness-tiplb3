package com.amirawellness.data.models

import android.os.Parcelable
import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey
import com.google.gson.annotations.SerializedName
import kotlinx.parcelize.Parcelize
import java.util.UUID

/**
 * Data class representing metadata for an audio recording associated with a journal entry.
 * Contains technical information about the audio file such as format, size, and quality parameters.
 */
@Parcelize
@Entity(
    tableName = "audio_metadata",
    foreignKeys = [
        ForeignKey(
            entity = Journal::class,
            parentColumns = ["id"],
            childColumns = ["journalId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["journalId"], name = "index_audio_metadata_journal_id", unique = true)
    ]
)
data class AudioMetadata(
    @PrimaryKey
    @SerializedName("id")
    val id: String,

    @ColumnInfo(name = "journalId")
    @SerializedName("journalId")
    val journalId: String,

    @ColumnInfo(name = "fileFormat")
    @SerializedName("fileFormat")
    val fileFormat: String,

    @ColumnInfo(name = "fileSizeBytes")
    @SerializedName("fileSizeBytes")
    val fileSizeBytes: Int,

    @ColumnInfo(name = "sampleRate")
    @SerializedName("sampleRate")
    val sampleRate: Int,

    @ColumnInfo(name = "bitRate")
    @SerializedName("bitRate")
    val bitRate: Int,

    @ColumnInfo(name = "channels")
    @SerializedName("channels")
    val channels: Int,

    @ColumnInfo(name = "checksum")
    @SerializedName("checksum")
    val checksum: String
) : Parcelable {
    
    /**
     * Converts the AudioMetadata model to a DTO for API communication
     * 
     * @return DTO representation of this audio metadata
     */
    fun toAudioMetadataDto(): AudioMetadataDto {
        return AudioMetadataDto(
            id = id,
            journalId = journalId,
            fileFormat = fileFormat,
            fileSizeBytes = fileSizeBytes,
            sampleRate = sampleRate,
            bitRate = bitRate,
            channels = channels,
            checksum = checksum
        )
    }
    
    /**
     * Creates a copy of the audio metadata with optional property changes
     */
    fun copy(
        id: String? = null,
        journalId: String? = null,
        fileFormat: String? = null,
        fileSizeBytes: Int? = null,
        sampleRate: Int? = null,
        bitRate: Int? = null,
        channels: Int? = null,
        checksum: String? = null
    ): AudioMetadata {
        return AudioMetadata(
            id = id ?: this.id,
            journalId = journalId ?: this.journalId,
            fileFormat = fileFormat ?: this.fileFormat,
            fileSizeBytes = fileSizeBytes ?: this.fileSizeBytes,
            sampleRate = sampleRate ?: this.sampleRate,
            bitRate = bitRate ?: this.bitRate,
            channels = channels ?: this.channels,
            checksum = checksum ?: this.checksum
        )
    }
}

/**
 * Data class representing a voice journal entry with audio metadata and emotional states.
 * This is the core model for the voice journaling feature, containing all information about
 * a user's journal entry including pre/post emotional states and synchronization status.
 */
@Parcelize
@Entity(
    tableName = "journals",
    foreignKeys = [
        ForeignKey(
            entity = User::class,
            parentColumns = ["id"],
            childColumns = ["userId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["userId"], name = "index_journals_user_id"),
        Index(value = ["createdAt"], name = "index_journals_created_at"),
        Index(value = ["isFavorite"], name = "index_journals_is_favorite"),
        Index(value = ["isUploaded"], name = "index_journals_is_uploaded")
    ]
)
data class Journal(
    @PrimaryKey
    @SerializedName("id")
    val id: String,
    
    @ColumnInfo(name = "userId")
    @SerializedName("userId")
    val userId: String,
    
    @ColumnInfo(name = "createdAt")
    @SerializedName("createdAt")
    val createdAt: Long,
    
    @ColumnInfo(name = "updatedAt")
    @SerializedName("updatedAt")
    val updatedAt: Long?,
    
    @ColumnInfo(name = "title")
    @SerializedName("title")
    val title: String,
    
    @ColumnInfo(name = "durationSeconds")
    @SerializedName("durationSeconds")
    val durationSeconds: Int,
    
    @ColumnInfo(name = "isFavorite")
    @SerializedName("isFavorite")
    val isFavorite: Boolean,
    
    @ColumnInfo(name = "isUploaded")
    @SerializedName("isUploaded")
    val isUploaded: Boolean,
    
    @ColumnInfo(name = "localFilePath")
    @SerializedName("localFilePath")
    val localFilePath: String?,
    
    @ColumnInfo(name = "storagePath")
    @SerializedName("storagePath")
    val storagePath: String?,
    
    @ColumnInfo(name = "encryptionIv")
    @SerializedName("encryptionIv")
    val encryptionIv: String?,
    
    @Embedded(prefix = "pre_")
    @SerializedName("preEmotionalState")
    val preEmotionalState: EmotionalState,
    
    @Embedded(prefix = "post_")
    @SerializedName("postEmotionalState")
    val postEmotionalState: EmotionalState,
    
    @Ignore
    @SerializedName("audioMetadata")
    val audioMetadata: AudioMetadata?
) : Parcelable {
    
    /**
     * Calculates the emotional shift between pre and post recording states
     * 
     * @return Intensity change value (positive for improvement, negative for decline)
     */
    fun getEmotionalShift(): Int {
        return EmotionalState.calculateEmotionalShift(preEmotionalState, postEmotionalState)
    }
    
    /**
     * Checks if the emotional shift is positive (improvement)
     * 
     * @return True if the emotional shift is positive, false otherwise
     */
    fun hasPositiveShift(): Boolean {
        return getEmotionalShift() > 0
    }
    
    /**
     * Checks if the emotional shift is negative (decline)
     * 
     * @return True if the emotional shift is negative, false otherwise
     */
    fun hasNegativeShift(): Boolean {
        return getEmotionalShift() < 0
    }
    
    /**
     * Checks if there is no emotional shift
     * 
     * @return True if there is no emotional shift, false otherwise
     */
    fun hasNoShift(): Boolean {
        return getEmotionalShift() == 0
    }
    
    /**
     * Checks if the journal exists only locally and hasn't been uploaded
     * 
     * @return True if the journal is local only, false otherwise
     */
    fun isLocalOnly(): Boolean {
        return !isUploaded && localFilePath != null
    }
    
    /**
     * Checks if the journal has an associated audio recording
     * 
     * @return True if the journal has an audio recording, false otherwise
     */
    fun hasAudioRecording(): Boolean {
        return localFilePath != null || storagePath != null
    }
    
    /**
     * Converts the Journal model to a DTO for API communication
     * 
     * @return DTO representation of this journal
     */
    fun toJournalDto(): JournalDto {
        return JournalDto(
            id = id,
            userId = userId,
            createdAt = createdAt,
            updatedAt = updatedAt,
            title = title,
            durationSeconds = durationSeconds,
            isFavorite = isFavorite,
            isUploaded = isUploaded,
            localFilePath = localFilePath,
            storagePath = storagePath,
            encryptionIv = encryptionIv,
            preEmotionalState = preEmotionalState.toEmotionalStateDto(),
            postEmotionalState = postEmotionalState.toEmotionalStateDto(),
            audioMetadata = audioMetadata?.toAudioMetadataDto()
        )
    }
    
    /**
     * Creates a copy of the journal with optional property changes
     */
    fun copy(
        id: String? = null,
        userId: String? = null,
        createdAt: Long? = null,
        updatedAt: Long? = null,
        title: String? = null,
        durationSeconds: Int? = null,
        isFavorite: Boolean? = null,
        isUploaded: Boolean? = null,
        localFilePath: String? = null,
        storagePath: String? = null,
        encryptionIv: String? = null,
        preEmotionalState: EmotionalState? = null,
        postEmotionalState: EmotionalState? = null,
        audioMetadata: AudioMetadata? = null
    ): Journal {
        return Journal(
            id = id ?: this.id,
            userId = userId ?: this.userId,
            createdAt = createdAt ?: this.createdAt,
            updatedAt = updatedAt ?: this.updatedAt,
            title = title ?: this.title,
            durationSeconds = durationSeconds ?: this.durationSeconds,
            isFavorite = isFavorite ?: this.isFavorite,
            isUploaded = isUploaded ?: this.isUploaded,
            localFilePath = localFilePath ?: this.localFilePath,
            storagePath = storagePath ?: this.storagePath,
            encryptionIv = encryptionIv ?: this.encryptionIv,
            preEmotionalState = preEmotionalState ?: this.preEmotionalState,
            postEmotionalState = postEmotionalState ?: this.postEmotionalState,
            audioMetadata = audioMetadata ?: this.audioMetadata
        )
    }
    
    /**
     * Creates a copy of the journal with updated upload status and storage path
     * 
     * @param isUploaded New upload status
     * @param storagePath New storage path (optional)
     * @return A new Journal instance with updated upload status
     */
    fun withUpdatedUploadStatus(isUploaded: Boolean, storagePath: String? = null): Journal {
        return copy(
            isUploaded = isUploaded,
            storagePath = storagePath ?: this.storagePath,
            updatedAt = System.currentTimeMillis()
        )
    }
    
    /**
     * Creates a copy of the journal with updated favorite status
     * 
     * @param isFavorite New favorite status
     * @return A new Journal instance with updated favorite status
     */
    fun withUpdatedFavoriteStatus(isFavorite: Boolean): Journal {
        return copy(
            isFavorite = isFavorite,
            updatedAt = System.currentTimeMillis()
        )
    }
    
    companion object {
        /**
         * Creates a Journal instance from a DTO
         * 
         * @param dto The DTO to convert from
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: JournalDto): Journal {
            val preEmotionalState = EmotionalState.fromDto(dto.preEmotionalState)
            val postEmotionalState = EmotionalState.fromDto(dto.postEmotionalState)
            val audioMetadata = dto.audioMetadata?.let { AudioMetadataDto ->
                AudioMetadata(
                    id = AudioMetadataDto.id,
                    journalId = AudioMetadataDto.journalId,
                    fileFormat = AudioMetadataDto.fileFormat,
                    fileSizeBytes = AudioMetadataDto.fileSizeBytes,
                    sampleRate = AudioMetadataDto.sampleRate,
                    bitRate = AudioMetadataDto.bitRate,
                    channels = AudioMetadataDto.channels,
                    checksum = AudioMetadataDto.checksum
                )
            }
            
            return Journal(
                id = dto.id,
                userId = dto.userId,
                createdAt = dto.createdAt,
                updatedAt = dto.updatedAt,
                title = dto.title,
                durationSeconds = dto.durationSeconds,
                isFavorite = dto.isFavorite,
                isUploaded = dto.isUploaded,
                localFilePath = dto.localFilePath,
                storagePath = dto.storagePath,
                encryptionIv = dto.encryptionIv,
                preEmotionalState = preEmotionalState,
                postEmotionalState = postEmotionalState,
                audioMetadata = audioMetadata
            )
        }
        
        /**
         * Creates an empty Journal instance with default values
         * 
         * @param userId ID of the user creating the journal
         * @param preEmotionalState Initial emotional state before recording
         * @return Empty model instance with default values
         */
        fun createEmpty(userId: String, preEmotionalState: EmotionalState): Journal {
            val journalId = UUID.randomUUID().toString()
            val currentTime = System.currentTimeMillis()
            
            // Create an empty post emotional state with the same emotion type as pre state
            val postEmotionalState = preEmotionalState.copy(
                id = UUID.randomUUID().toString(),
                relatedJournalId = journalId
            )
            
            return Journal(
                id = journalId,
                userId = userId,
                createdAt = currentTime,
                updatedAt = null,
                title = "",
                durationSeconds = 0,
                isFavorite = false,
                isUploaded = false,
                localFilePath = null,
                storagePath = null,
                encryptionIv = null,
                preEmotionalState = preEmotionalState.copy(
                    relatedJournalId = journalId
                ),
                postEmotionalState = postEmotionalState,
                audioMetadata = null
            )
        }
    }
}