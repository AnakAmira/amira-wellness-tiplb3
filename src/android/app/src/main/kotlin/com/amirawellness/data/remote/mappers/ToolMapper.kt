package com.amirawellness.data.remote.mappers

import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.models.ToolContent
import com.amirawellness.data.models.ToolContentType
import com.amirawellness.data.models.ToolStep
import com.amirawellness.data.models.Resource
import com.amirawellness.data.models.ResourceType
import com.amirawellness.data.remote.dto.ToolDto
import com.amirawellness.data.remote.dto.ToolContentDto
import com.amirawellness.data.remote.dto.ToolStepDto
import com.amirawellness.data.remote.dto.ResourceDto
import com.amirawellness.core.constants.AppConstants.EmotionType

/**
 * Extension function to convert a ToolDto to a Tool domain model
 * 
 * @return Domain model converted from this DTO
 */
fun ToolDto.toTool(): Tool {
    return Tool(
        id = id,
        name = name,
        description = description,
        category = ToolCategory.fromDto(category),
        contentType = ToolContentType.valueOf(contentType),
        content = content.toToolContent(),
        isFavorite = isFavorite,
        usageCount = usageCount,
        targetEmotions = targetEmotions.map { EmotionType.valueOf(it) },
        estimatedDuration = estimatedDuration
    )
}

/**
 * Extension function to convert a Tool domain model to a ToolDto
 * 
 * @return DTO converted from this domain model
 */
fun Tool.toToolDto(): ToolDto {
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

/**
 * Extension function to convert a ToolContentDto to a ToolContent domain model
 * 
 * @return Domain model converted from this DTO
 */
fun ToolContentDto.toToolContent(): ToolContent {
    return ToolContent(
        title = title,
        instructions = instructions,
        mediaUrl = mediaUrl,
        steps = steps?.map { it.toToolStep() },
        additionalResources = additionalResources?.map { it.toResource() }
    )
}

/**
 * Extension function to convert a ToolContent domain model to a ToolContentDto
 * 
 * @return DTO converted from this domain model
 */
fun ToolContent.toToolContentDto(): ToolContentDto {
    return ToolContentDto(
        title = title,
        instructions = instructions,
        mediaUrl = mediaUrl,
        steps = steps?.map { it.toToolStepDto() },
        additionalResources = additionalResources?.map { it.toResourceDto() }
    )
}

/**
 * Extension function to convert a ToolStepDto to a ToolStep domain model
 * 
 * @return Domain model converted from this DTO
 */
fun ToolStepDto.toToolStep(): ToolStep {
    return ToolStep(
        order = order,
        title = title,
        description = description,
        duration = duration,
        mediaUrl = mediaUrl
    )
}

/**
 * Extension function to convert a ToolStep domain model to a ToolStepDto
 * 
 * @return DTO converted from this domain model
 */
fun ToolStep.toToolStepDto(): ToolStepDto {
    return ToolStepDto(
        order = order,
        title = title,
        description = description,
        duration = duration,
        mediaUrl = mediaUrl
    )
}

/**
 * Extension function to convert a ResourceDto to a Resource domain model
 * 
 * @return Domain model converted from this DTO
 */
fun ResourceDto.toResource(): Resource {
    return Resource(
        title = title,
        description = description,
        url = url,
        type = ResourceType.valueOf(type)
    )
}

/**
 * Extension function to convert a Resource domain model to a ResourceDto
 * 
 * @return DTO converted from this domain model
 */
fun Resource.toResourceDto(): ResourceDto {
    return ResourceDto(
        title = title,
        description = description,
        url = url,
        type = type.toString()
    )
}

/**
 * Object containing utility methods for mapping between Tool domain models and DTOs
 */
object ToolMapper {
    
    /**
     * Maps a ToolDto to a Tool domain model
     * 
     * @param dto DTO to be converted to domain model
     * @return Domain model converted from the DTO
     */
    fun mapToDomain(dto: ToolDto): Tool {
        return dto.toTool()
    }
    
    /**
     * Maps a Tool domain model to a ToolDto
     * 
     * @param model Domain model to be converted to DTO
     * @return DTO converted from the domain model
     */
    fun mapToDto(model: Tool): ToolDto {
        return model.toToolDto()
    }
    
    /**
     * Maps a list of ToolDtos to a list of Tool domain models
     * 
     * @param dtos List of DTOs to be converted to domain models
     * @return List of domain models converted from the DTOs
     */
    fun mapListToDomain(dtos: List<ToolDto>): List<Tool> {
        return dtos.map { mapToDomain(it) }
    }
    
    /**
     * Maps a list of Tool domain models to a list of ToolDtos
     * 
     * @param models List of domain models to be converted to DTOs
     * @return List of DTOs converted from the domain models
     */
    fun mapListToDto(models: List<Tool>): List<ToolDto> {
        return models.map { mapToDto(it) }
    }
    
    /**
     * Maps a ToolContentDto to a ToolContent domain model
     * 
     * @param dto Content DTO to be converted to domain model
     * @return Domain model converted from the DTO
     */
    fun mapContentToDomain(dto: ToolContentDto): ToolContent {
        return dto.toToolContent()
    }
    
    /**
     * Maps a ToolContent domain model to a ToolContentDto
     * 
     * @param model Content domain model to be converted to DTO
     * @return DTO converted from the domain model
     */
    fun mapContentToDto(model: ToolContent): ToolContentDto {
        return model.toToolContentDto()
    }
}