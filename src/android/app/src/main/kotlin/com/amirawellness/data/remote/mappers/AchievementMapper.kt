package com.amirawellness.data.remote.mappers

import com.amirawellness.data.models.Achievement
import com.amirawellness.data.models.AchievementType
import com.amirawellness.data.models.AchievementCategory
import com.amirawellness.data.remote.dto.AchievementDto
import com.amirawellness.data.remote.dto.AchievementListDto
import java.util.Date
import java.util.UUID
import java.text.SimpleDateFormat

// Format for date strings in API communication following ISO-8601 standard
private const val DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

/**
 * Mapper class responsible for converting between Achievement domain models and 
 * AchievementDto data transfer objects in the Amira Wellness Android application.
 * This class follows the clean architecture approach by providing a clear separation
 * between domain and data layers.
 */
class AchievementMapper {

    /**
     * Converts an AchievementDto to an Achievement domain model
     *
     * @param dto The AchievementDto to convert
     * @return Achievement domain model converted from the DTO
     */
    fun toAchievement(dto: AchievementDto): Achievement {
        return Achievement(
            id = UUID.fromString(dto.id),
            type = AchievementType.valueOf(dto.type),
            category = AchievementCategory.valueOf(dto.category),
            title = dto.title,
            description = dto.description,
            iconUrl = dto.iconUrl,
            points = dto.points,
            isHidden = dto.isHidden,
            earnedAt = parseDate(dto.earnedAt),
            progress = dto.progress,
            metadata = dto.metadata?.mapValues { it.value as Any }
        )
    }

    /**
     * Converts an Achievement domain model to an AchievementDto
     *
     * @param model The Achievement domain model to convert
     * @return DTO converted from the domain model
     */
    fun toAchievementDto(model: Achievement): AchievementDto {
        return AchievementDto(
            id = model.id.toString(),
            type = model.type.toString(),
            category = model.category.toString(),
            title = model.title,
            description = model.description,
            iconUrl = model.iconUrl,
            points = model.points,
            isHidden = model.isHidden,
            earnedAt = formatDate(model.earnedAt),
            progress = model.progress,
            metadata = model.metadata?.mapValues { it.value.toString() }
        )
    }

    /**
     * Converts a list of AchievementDto objects to a list of Achievement domain models
     *
     * @param dtos The list of AchievementDto objects to convert
     * @return List of domain models converted from the DTOs
     */
    fun toAchievementList(dtos: List<AchievementDto>): List<Achievement> {
        return dtos.map { toAchievement(it) }
    }

    /**
     * Converts a list of Achievement domain models to a list of AchievementDto objects
     *
     * @param models The list of Achievement domain models to convert
     * @return List of DTOs converted from the domain models
     */
    fun toAchievementDtoList(models: List<Achievement>): List<AchievementDto> {
        return models.map { toAchievementDto(it) }
    }

    /**
     * Parses a date string to a Date object
     *
     * @param dateString The date string to parse
     * @return Parsed Date object or null if the input is null
     */
    private fun parseDate(dateString: String?): Date? {
        if (dateString == null) return null
        
        return try {
            SimpleDateFormat(DATE_FORMAT).parse(dateString)
        } catch (e: Exception) {
            null // Return null if parsing fails
        }
    }

    /**
     * Formats a Date object to a string
     *
     * @param date The Date object to format
     * @return Formatted date string or null if the input is null
     */
    private fun formatDate(date: Date?): String? {
        if (date == null) return null
        
        return try {
            SimpleDateFormat(DATE_FORMAT).format(date)
        } catch (e: Exception) {
            null // Return null if formatting fails
        }
    }
}