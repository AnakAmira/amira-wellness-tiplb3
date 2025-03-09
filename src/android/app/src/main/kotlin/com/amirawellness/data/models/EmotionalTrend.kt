package com.amirawellness.data.models

import android.os.Parcelable // Android SDK
import kotlinx.parcelize.Parcelize // Kotlin Android Extensions
import com.google.gson.annotations.SerializedName // Gson 2.9.0
import java.util.Date // Java SDK
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.R

/**
 * Data model class representing emotional trend data for visualization and analysis in the Amira Wellness Android application.
 * This model captures patterns in emotional states over time, including trend direction, intensity changes, and data points for visualization.
 */

/**
 * Enumeration representing the direction of an emotional trend over time.
 */
enum class TrendDirection {
    INCREASING,
    DECREASING,
    STABLE,
    FLUCTUATING;

    /**
     * Returns the localized display name of the trend direction.
     *
     * @return Localized display name of the trend direction
     */
    fun getDisplayName(): String {
        return when (this) {
            INCREASING -> "Aumentando" // Increasing in Spanish
            DECREASING -> "Disminuyendo" // Decreasing in Spanish
            STABLE -> "Estable" // Stable in Spanish
            FLUCTUATING -> "Fluctuando" // Fluctuating in Spanish
        }
    }

    /**
     * Returns the localized description of the trend direction.
     *
     * @return Localized description of the trend direction
     */
    fun getDescription(): String {
        return when (this) {
            INCREASING -> "Esta emoción está aumentando con el tiempo"
            DECREASING -> "Esta emoción está disminuyendo con el tiempo"
            STABLE -> "Esta emoción se mantiene estable"
            FLUCTUATING -> "Esta emoción fluctúa significativamente"
        }
    }

    /**
     * Returns the resource ID for the icon associated with the trend direction.
     *
     * @return Resource ID for the trend direction icon
     */
    fun getIconResId(): Int {
        return when (this) {
            INCREASING -> R.drawable.ic_trend_increasing
            DECREASING -> R.drawable.ic_trend_decreasing
            STABLE -> R.drawable.ic_trend_stable
            FLUCTUATING -> R.drawable.ic_trend_fluctuating
        }
    }
}

/**
 * Enumeration representing the time period for trend analysis.
 */
enum class PeriodType {
    DAY,
    WEEK,
    MONTH;

    /**
     * Returns the localized display name of the period type.
     *
     * @return Localized display name of the period type
     */
    fun getDisplayName(): String {
        return when (this) {
            DAY -> "Hoy" // Today in Spanish
            WEEK -> "Esta semana" // This week in Spanish
            MONTH -> "Este mes" // This month in Spanish
        }
    }

    /**
     * Returns the default date range for the period type.
     *
     * @return Pair of start and end dates
     */
    fun getDateRange(): Pair<Date, Date> {
        val calendar = Calendar.getInstance()
        val endDate = calendar.time
        
        when (this) {
            DAY -> calendar.add(Calendar.DAY_OF_YEAR, -1)
            WEEK -> calendar.add(Calendar.WEEK_OF_YEAR, -1)
            MONTH -> calendar.add(Calendar.MONTH, -1)
        }
        
        val startDate = calendar.time
        return Pair(startDate, endDate)
    }
}

/**
 * Data class representing a single data point in an emotional trend.
 */
@Parcelize
data class TrendDataPoint(
    val date: Date,
    val value: Int,
    val context: String? = null
) : Parcelable {

    /**
     * Returns a formatted string representation of the date.
     *
     * @param formatter Optional formatter to use
     * @return Formatted date string
     */
    fun getFormattedDate(formatter: DateFormat? = null): String {
        val dateFormatter = formatter ?: SimpleDateFormat.getDateInstance(DateFormat.SHORT)
        return dateFormatter.format(date)
    }

    /**
     * Returns a formatted string representation of the value.
     *
     * @return Formatted value string (e.g., '7/10')
     */
    fun getFormattedValue(): String {
        return "$value/10"
    }
}

/**
 * Data class representing an insight derived from emotional trend analysis.
 */
@Parcelize
data class EmotionalInsight(
    val type: String,
    val description: String,
    val relatedEmotions: List<EmotionType>,
    val confidence: Double,
    val recommendedActions: List<String>
) : Parcelable {

    /**
     * Returns a formatted string representation of the confidence level.
     *
     * @return Formatted confidence string (e.g., '85%')
     */
    fun getFormattedConfidence(): String {
        return "${(confidence * 100).toInt()}%"
    }

    /**
     * Returns a comma-separated list of related emotion names.
     *
     * @return Comma-separated list of emotion names
     */
    fun getRelatedEmotionsText(): String {
        return relatedEmotions.joinToString(", ") { emotion ->
            when (emotion) {
                EmotionType.JOY -> "Alegría"
                EmotionType.SADNESS -> "Tristeza"
                EmotionType.ANGER -> "Ira"
                EmotionType.FEAR -> "Miedo"
                EmotionType.DISGUST -> "Disgusto"
                EmotionType.SURPRISE -> "Sorpresa"
                EmotionType.TRUST -> "Confianza"
                EmotionType.ANTICIPATION -> "Anticipación"
                EmotionType.ANXIETY -> "Ansiedad"
                EmotionType.CALM -> "Calma"
                else -> emotion.toString()
            }
        }
    }
}

/**
 * Data class representing a data point DTO for API communication.
 */
data class DataPointDto(
    @SerializedName("date") val date: Date,
    @SerializedName("value") val value: Int,
    @SerializedName("context") val context: String?
)

/**
 * Data class representing an emotional trend DTO for API communication.
 */
data class EmotionalTrendDto(
    @SerializedName("emotion_type") val emotionType: String,
    @SerializedName("data_points") val dataPoints: List<DataPointDto>,
    @SerializedName("overall_trend") val overallTrend: String,
    @SerializedName("average_intensity") val averageIntensity: Double,
    @SerializedName("peak_intensity") val peakIntensity: Double,
    @SerializedName("peak_date") val peakDate: Date,
    @SerializedName("occurrence_count") val occurrenceCount: Int
)

/**
 * Data class representing an emotional trend over time.
 */
@Parcelize
data class EmotionalTrend(
    val emotionType: EmotionType,
    val dataPoints: List<TrendDataPoint>,
    val overallTrend: TrendDirection,
    val averageIntensity: Double,
    val peakIntensity: Double,
    val peakDate: Date,
    val occurrenceCount: Int
) : Parcelable {

    /**
     * Returns a localized description of the emotional trend.
     *
     * @return Localized description of the trend
     */
    fun getTrendDescription(): String {
        val emotion = when (emotionType) {
            EmotionType.JOY -> "alegría"
            EmotionType.SADNESS -> "tristeza"
            EmotionType.ANGER -> "ira"
            EmotionType.FEAR -> "miedo"
            EmotionType.DISGUST -> "disgusto"
            EmotionType.SURPRISE -> "sorpresa"
            EmotionType.TRUST -> "confianza"
            EmotionType.ANTICIPATION -> "anticipación"
            EmotionType.ANXIETY -> "ansiedad"
            EmotionType.CALM -> "calma"
            else -> emotionType.toString().toLowerCase()
        }
        
        return "Tu nivel de $emotion ${overallTrend.getDescription().toLowerCase()} con una intensidad promedio de ${getFormattedAverageIntensity()}."
    }

    /**
     * Returns a formatted string representation of the average intensity.
     *
     * @return Formatted average intensity string (e.g., '7.2/10')
     */
    fun getFormattedAverageIntensity(): String {
        return String.format("%.1f/10", averageIntensity)
    }

    /**
     * Returns a formatted string representation of the peak intensity.
     *
     * @return Formatted peak intensity string (e.g., '9/10')
     */
    fun getFormattedPeakIntensity(): String {
        return String.format("%.1f/10", peakIntensity)
    }

    /**
     * Returns a formatted string representation of the peak date.
     *
     * @return Formatted peak date string
     */
    fun getFormattedPeakDate(): String {
        val dateFormat = SimpleDateFormat.getDateInstance(DateFormat.MEDIUM)
        return dateFormat.format(peakDate)
    }

    /**
     * Returns the date range covered by the trend data points.
     *
     * @return Pair with start and end dates
     */
    fun getDateRange(): Pair<Date, Date> {
        if (dataPoints.isEmpty()) {
            return Pair(Date(), Date())
        }
        
        val sortedPoints = dataPoints.sortedBy { it.date }
        return Pair(sortedPoints.first().date, sortedPoints.last().date)
    }

    /**
     * Returns the range of intensity values in the trend data points.
     *
     * @return Pair with minimum and maximum intensity values
     */
    fun getIntensityRange(): Pair<Int, Int> {
        if (dataPoints.isEmpty()) {
            return Pair(0, 10)
        }
        
        val minValue = dataPoints.minOf { it.value }
        val maxValue = dataPoints.maxOf { it.value }
        return Pair(minValue, maxValue)
    }

    /**
     * Returns a formatted string representation of the trend period.
     *
     * @return Formatted period string (e.g., 'Last 7 days')
     */
    fun getFormattedPeriod(): String {
        val (startDate, endDate) = getDateRange()
        val diffMillis = endDate.time - startDate.time
        val diffDays = diffMillis / (1000 * 60 * 60 * 24)
        
        return when {
            diffDays < 1 -> "Hoy"
            diffDays < 7 -> "Últimos ${diffDays.toInt()} días"
            diffDays < 30 -> "Últimas ${(diffDays / 7).toInt()} semanas"
            else -> "Últimos ${(diffDays / 30).toInt()} meses"
        }
    }

    /**
     * Converts the EmotionalTrend model to a DTO for API communication.
     *
     * @return DTO representation of this emotional trend
     */
    fun toEmotionalTrendDto(): EmotionalTrendDto {
        return EmotionalTrendDto(
            emotionType = emotionType.toString(),
            dataPoints = dataPoints.map { DataPointDto(it.date, it.value, it.context) },
            overallTrend = overallTrend.toString(),
            averageIntensity = averageIntensity,
            peakIntensity = peakIntensity,
            peakDate = peakDate,
            occurrenceCount = occurrenceCount
        )
    }

    companion object {
        /**
         * Creates an EmotionalTrend instance from a DTO.
         *
         * @param dto DTO representation of the emotional trend
         * @return Model instance created from the DTO
         */
        fun fromDto(dto: EmotionalTrendDto): EmotionalTrend {
            val emotionType = try {
                EmotionType.valueOf(dto.emotionType)
            } catch (e: IllegalArgumentException) {
                // Default to CALM if the emotion type is not recognized
                EmotionType.CALM
            }
            
            val dataPoints = dto.dataPoints.map { 
                TrendDataPoint(it.date, it.value, it.context) 
            }
            
            val overallTrend = try {
                TrendDirection.valueOf(dto.overallTrend)
            } catch (e: IllegalArgumentException) {
                // Default to STABLE if the trend direction is not recognized
                TrendDirection.STABLE
            }
            
            return EmotionalTrend(
                emotionType = emotionType,
                dataPoints = dataPoints,
                overallTrend = overallTrend,
                averageIntensity = dto.averageIntensity,
                peakIntensity = dto.peakIntensity,
                peakDate = dto.peakDate,
                occurrenceCount = dto.occurrenceCount
            )
        }

        /**
         * Calculates the trend direction based on a series of data points.
         *
         * @param dataPoints List of data points to analyze
         * @return Calculated trend direction
         */
        fun calculateTrendDirection(dataPoints: List<TrendDataPoint>): TrendDirection {
            if (dataPoints.size < 2) {
                return TrendDirection.STABLE
            }
            
            // Sort data points by date
            val sortedPoints = dataPoints.sortedBy { it.date }
            
            // Linear regression to find slope
            val n = sortedPoints.size
            val xValues = sortedPoints.mapIndexed { index, _ -> index.toDouble() }
            val yValues = sortedPoints.map { it.value.toDouble() }
            
            val sumX = xValues.sum()
            val sumY = yValues.sum()
            val sumXY = xValues.zip(yValues).sumOf { it.first * it.second }
            val sumXX = xValues.sumOf { it * it }
            
            val slope = if (n * sumXX - sumX * sumX != 0.0) {
                (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
            } else {
                0.0
            }
            
            // Calculate variance to determine stability
            val mean = yValues.average()
            val variance = yValues.sumOf { (it - mean) * (it - mean) } / n
            
            // Determine trend direction
            return when {
                variance < 1.0 -> TrendDirection.STABLE
                slope > 0.2 -> TrendDirection.INCREASING
                slope < -0.2 -> TrendDirection.DECREASING
                else -> TrendDirection.FLUCTUATING
            }
        }
    }
}

/**
 * Data class representing a request for emotional trend analysis.
 */
data class EmotionalTrendRequest(
    val periodType: PeriodType,
    val startDate: Date,
    val endDate: Date,
    val emotionTypes: List<EmotionType>? = null
) {

    /**
     * Validates that the request has valid parameters.
     *
     * @return True if the request is valid, false otherwise
     */
    fun isValid(): Boolean {
        // Check if startDate is before endDate
        if (startDate.after(endDate)) {
            return false
        }
        
        // Check if date range is within reasonable limits (e.g., not more than 1 year)
        val diffMillis = endDate.time - startDate.time
        val diffDays = diffMillis / (1000 * 60 * 60 * 24)
        if (diffDays > 365) {
            return false
        }
        
        return true
    }

    /**
     * Converts the request to a map of parameters for API requests.
     *
     * @return Map of parameters
     */
    fun toMap(): Map<String, Any> {
        val params = mutableMapOf<String, Any>()
        
        params["periodType"] = periodType.name
        params["startDate"] = formatDate(startDate)
        params["endDate"] = formatDate(endDate)
        
        emotionTypes?.let {
            params["emotionTypes"] = it.joinToString(",") { emotion -> emotion.name }
        }
        
        return params
    }
    
    private fun formatDate(date: Date): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return formatter.format(date)
    }
}

/**
 * Data class representing a response from emotional trend analysis.
 */
data class EmotionalTrendResponse(
    val trends: List<EmotionalTrend>,
    val insights: List<EmotionalInsight>
)