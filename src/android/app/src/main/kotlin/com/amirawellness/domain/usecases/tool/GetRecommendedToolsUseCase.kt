package com.amirawellness.domain.usecases.tool

import com.amirawellness.data.repositories.ToolRepository
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.core.utils.LogUtils.d as logDebug
import com.amirawellness.core.utils.LogUtils.e as logError
import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private const val TAG = "GetRecommendedToolsUseCase"

/**
 * Use case for retrieving tool recommendations based on emotional state.
 * 
 * This class encapsulates the business logic for fetching personalized tool recommendations
 * that match a user's current emotional state and intensity level, following the clean architecture
 * pattern to separate business logic from data access and presentation layers.
 */
class GetRecommendedToolsUseCase @Inject constructor(
    private val toolRepository: ToolRepository
) {
    
    /**
     * Executes the use case to retrieve tool recommendations based on emotional state.
     *
     * @param emotionalState The user's current emotional state
     * @return Result containing a list of recommended tools or an error
     */
    suspend operator fun invoke(emotionalState: EmotionalState): Result<List<Tool>> {
        logDebug(TAG, "Getting tool recommendations for emotion: ${emotionalState.emotionType}, intensity: ${emotionalState.intensity}")
        
        return try {
            val emotionType = emotionalState.emotionType.name
            val intensity = emotionalState.intensity
            
            val recommendations = withContext(Dispatchers.IO) {
                toolRepository.getRecommendedTools(emotionType, intensity)
            }
            
            val filteredRecommendations = filterRecommendationsByIntensity(recommendations, intensity)
            
            Result.success(filteredRecommendations)
        } catch (e: Exception) {
            logError(TAG, "Error getting recommended tools", e)
            Result.failure(e)
        }
    }
    
    /**
     * Overloaded operator function to retrieve tool recommendations with explicit emotion type and intensity.
     *
     * @param emotionType The type of emotion (e.g., "ANXIETY", "JOY")
     * @param intensity The intensity level of the emotion (1-10)
     * @return Result containing a list of recommended tools or an error
     */
    suspend operator fun invoke(emotionType: String, intensity: Int): Result<List<Tool>> {
        logDebug(TAG, "Getting tool recommendations for emotion type: $emotionType, intensity: $intensity")
        
        return try {
            val recommendations = withContext(Dispatchers.IO) {
                toolRepository.getRecommendedTools(emotionType, intensity)
            }
            
            val filteredRecommendations = filterRecommendationsByIntensity(recommendations, intensity)
            
            Result.success(filteredRecommendations)
        } catch (e: Exception) {
            logError(TAG, "Error getting recommended tools", e)
            Result.failure(e)
        }
    }
    
    /**
     * Filters and sorts recommendations based on emotional intensity.
     * 
     * Different intensity levels warrant different types of tools:
     * - High intensity (7-10): Focus on calming and grounding tools
     * - Medium intensity (4-6): Balanced mix of tools
     * - Low intensity (1-3): Focus on maintenance and enhancement tools
     *
     * @param tools The list of tools to filter
     * @param intensity The emotional intensity level
     * @return Filtered and sorted list of tools optimized for the intensity level
     */
    private fun filterRecommendationsByIntensity(tools: List<Tool>, intensity: Int): List<Tool> {
        return when {
            // High intensity (7-10): Prioritize calming and grounding tools
            intensity >= 7 -> {
                tools.sortedByDescending { tool ->
                    // For high intensity, prioritize shorter, calming exercises
                    val isShortDuration = tool.estimatedDuration <= 5
                    
                    // Breathing exercises are particularly effective for high intensity
                    val hasBreathingContent = tool.name.contains("breath", ignoreCase = true) ||
                                             tool.description.contains("breath", ignoreCase = true)
                                             
                    val hasGroundingContent = tool.name.contains("ground", ignoreCase = true) ||
                                            tool.description.contains("ground", ignoreCase = true)
                    
                    // Calculate relevance score
                    (if (isShortDuration) 2 else 0) +
                    (if (hasBreathingContent) 3 else 0) +
                    (if (hasGroundingContent) 2 else 0)
                }
            }
            
            // Medium intensity (4-6): Balanced approach
            intensity in 4..6 -> {
                tools.sortedByDescending { tool ->
                    // For medium intensity, provide a balanced mix
                    val isMediumDuration = tool.estimatedDuration in 5..10
                    
                    // Reflective and mindfulness practices are good for medium intensity
                    val hasMindfulnessContent = tool.name.contains("mindful", ignoreCase = true) ||
                                              tool.description.contains("mindful", ignoreCase = true)
                                              
                    val hasRegulationContent = tool.name.contains("regulat", ignoreCase = true) ||
                                             tool.description.contains("regulat", ignoreCase = true)
                    
                    // Calculate relevance score
                    (if (isMediumDuration) 2 else 0) +
                    (if (hasMindfulnessContent) 2 else 0) +
                    (if (hasRegulationContent) 2 else 0)
                }
            }
            
            // Low intensity (1-3): Focus on maintenance and enhancement
            else -> {
                tools.sortedByDescending { tool ->
                    // For low intensity, can include longer, more reflective practices
                    val isLongerDuration = tool.estimatedDuration > 5
                    
                    // Gratitude and journaling are good for low intensity states
                    val hasGratitudeContent = tool.name.contains("gratitude", ignoreCase = true) ||
                                            tool.description.contains("gratitude", ignoreCase = true)
                                            
                    val hasJournalingContent = tool.name.contains("journal", ignoreCase = true) ||
                                             tool.description.contains("journal", ignoreCase = true)
                                             
                    val hasReflectiveContent = tool.name.contains("reflect", ignoreCase = true) ||
                                             tool.description.contains("reflect", ignoreCase = true)
                    
                    // Calculate relevance score
                    (if (isLongerDuration) 1 else 0) +
                    (if (hasGratitudeContent) 2 else 0) +
                    (if (hasJournalingContent) 2 else 0) +
                    (if (hasReflectiveContent) 2 else 0)
                }
            }
        }
    }
}