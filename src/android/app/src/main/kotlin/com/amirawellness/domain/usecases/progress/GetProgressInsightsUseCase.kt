package com.amirawellness.domain.usecases.progress

import com.amirawellness.data.models.EmotionalInsight
import com.amirawellness.data.models.PeriodType
import com.amirawellness.data.repositories.ProgressRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Use case for retrieving progress insights from the progress repository.
 * 
 * This class follows the clean architecture pattern, providing a single responsibility 
 * function to fetch emotional insights and progress data from the repository layer
 * and expose it to the presentation layer. It supports the progress tracking feature
 * by providing meaningful insights derived from emotional data and usage patterns.
 */
class GetProgressInsightsUseCase @Inject constructor(
    private val progressRepository: ProgressRepository
) {
    /**
     * Operator function that retrieves progress insights from the repository.
     * 
     * Combines dashboard data with emotional trends to provide a comprehensive
     * view of the user's progress and emotional patterns.
     *
     * @return Flow emitting progress insights data
     */
    operator fun invoke(): Flow<Map<String, Any>> {
        // Get dashboard data
        val dashboardFlow = progressRepository.getProgressDashboard()
        
        // Get emotional trends for the past week
        val trendsFlow = progressRepository.getEmotionalTrends(PeriodType.WEEK, 1)
        
        // Combine dashboard and trends data
        return dashboardFlow.combine(trendsFlow) { dashboard, trends ->
            val result = dashboard.toMutableMap()
            
            // Add emotional trends to the result
            result["emotionalTrends"] = trends
            
            // Extract insights if they are available in the trends or dashboard
            val insights = extractInsightsFromData(dashboard, trends)
            if (insights.isNotEmpty()) {
                result["insights"] = extractInsights(insights)
            }
            
            result
        }
    }
    
    /**
     * Attempts to extract insights from available data sources.
     * This combines insights from both the dashboard and trends data if available.
     *
     * @param dashboard The dashboard data map
     * @param trends The emotional trends data
     * @return List of emotional insights
     */
    private fun extractInsightsFromData(dashboard: Map<String, Any>, trends: List<Any>): List<EmotionalInsight> {
        val insightsList = mutableListOf<EmotionalInsight>()
        
        // Extract insights from dashboard if available
        (dashboard["insights"] as? List<*>)?.filterIsInstance<EmotionalInsight>()?.let {
            insightsList.addAll(it)
        }
        
        // In a real implementation, additional insights might be extracted from trends
        // based on the specific structure of the EmotionalTrend class
        
        return insightsList
    }
    
    /**
     * Extracts insights from emotional insight data.
     * 
     * Transforms EmotionalInsight objects into a format suitable for
     * presentation in the UI.
     * 
     * @param insights List of emotional insights
     * @return List of insight data maps
     */
    private fun extractInsights(insights: List<EmotionalInsight>): List<Map<String, Any>> {
        return insights.map { insight ->
            mapOf(
                "type" to insight.type,
                "description" to insight.description,
                "relatedEmotions" to insight.relatedEmotions,
                "confidence" to insight.confidence,
                "recommendedActions" to insight.recommendedActions
            )
        }
    }
}