package com.amirawellness.ui.components.charts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.Card
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawPath
import androidx.compose.ui.graphics.drawscope.drawCircle
import androidx.compose.ui.graphics.drawscope.drawLine
import androidx.compose.ui.graphics.LinearGradient
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.data.models.EmotionalTrend
import com.amirawellness.data.models.TrendDataPoint
import com.amirawellness.data.models.TrendDirection
import com.amirawellness.ui.theme.CardShape
import com.amirawellness.ui.theme.EmotionJoy
import com.amirawellness.ui.theme.EmotionSadness
import com.amirawellness.ui.theme.EmotionAnger
import com.amirawellness.ui.theme.EmotionFear
import com.amirawellness.ui.theme.EmotionDisgust
import com.amirawellness.ui.theme.EmotionSurprise
import com.amirawellness.ui.theme.EmotionTrust
import com.amirawellness.ui.theme.EmotionAnticipation
import com.amirawellness.ui.theme.EmotionCalm
import com.amirawellness.ui.theme.EmotionAnxiety
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.TextTertiary
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * A composable function that renders a line chart visualizing emotional trend data over time.
 * 
 * @param trend The emotional trend data to visualize
 * @param modifier Modifier for styling and layout
 * @param onPointSelected Callback when a data point is selected
 */
@Composable
fun EmotionTrendChart(
    trend: EmotionalTrend,
    modifier: Modifier = Modifier,
    onPointSelected: (TrendDataPoint) -> Unit = {}
) {
    // Extract data points and ensure they're not empty
    val dataPoints = trend.dataPoints
    if (dataPoints.isEmpty()) {
        Card(
            modifier = modifier.fillMaxWidth().padding(16.dp),
            shape = CardShape,
            elevation = 4.dp
        ) {
            Text(
                text = "No hay datos suficientes para mostrar la tendencia.",
                modifier = Modifier.padding(16.dp),
                style = MaterialTheme.typography.body1,
                color = TextSecondary
            )
        }
        return
    }

    // Sort data points by date
    val sortedDataPoints = remember(trend) { dataPoints.sortedBy { it.date } }
    
    // Calculate min and max values for Y-axis scaling
    val (minValue, maxValue) = remember(trend) { trend.getIntensityRange() }
    
    // Get color based on emotion type
    val emotionColor = remember(trend) { getEmotionColor(trend.emotionType) }
    
    // Selected data point state
    val selectedPointIndex = remember { mutableStateOf<Int?>(null) }
    
    Card(
        modifier = modifier.fillMaxWidth().padding(16.dp),
        shape = CardShape,
        elevation = 4.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Tendencia de ${trend.emotionType.name} - ${trend.getFormattedPeriod()}",
                style = MaterialTheme.typography.subtitle1,
                color = TextPrimary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // The chart canvas
            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .clickable {
                        // In a future enhancement, we could implement touch detection
                        // to select the closest data point to the touch coordinates
                    }
            ) {
                val width = size.width
                val height = size.height
                val paddingTop = 20f
                val paddingBottom = 40f
                val paddingStart = 40f
                val paddingEnd = 20f
                
                val chartWidth = width - paddingStart - paddingEnd
                val chartHeight = height - paddingTop - paddingBottom
                
                // Draw axes
                drawLine(
                    color = Color.LightGray,
                    start = Offset(paddingStart, paddingTop),
                    end = Offset(paddingStart, height - paddingBottom),
                    strokeWidth = 1.5f
                )
                
                drawLine(
                    color = Color.LightGray,
                    start = Offset(paddingStart, height - paddingBottom),
                    end = Offset(width - paddingEnd, height - paddingBottom),
                    strokeWidth = 1.5f
                )
                
                // Draw horizontal grid lines
                val yStep = chartHeight / 5
                for (i in 0..5) {
                    val y = paddingTop + i * yStep
                    drawLine(
                        color = Color.LightGray.copy(alpha = 0.5f),
                        start = Offset(paddingStart, y),
                        end = Offset(width - paddingEnd, y),
                        strokeWidth = 0.5f
                    )
                }
                
                // If we have at least 2 points, we can draw a line
                if (sortedDataPoints.size >= 2) {
                    // Calculate point positions
                    val chartPoints = sortedDataPoints.mapIndexed { index, dataPoint ->
                        val x = paddingStart + (index.toFloat() * (chartWidth / (sortedDataPoints.size - 1).coerceAtLeast(1)))
                        val y = calculateYPosition(
                            dataPoint.value,
                            minValue,
                            maxValue,
                            chartHeight,
                            paddingTop,
                            paddingBottom
                        )
                        ChartPoint(dataPoint, x, y)
                    }
                    
                    // Create and draw the path for the line
                    val linePath = Path().apply {
                        chartPoints.forEachIndexed { index, point ->
                            if (index == 0) {
                                moveTo(point.x, point.y)
                            } else {
                                lineTo(point.x, point.y)
                            }
                        }
                    }
                    
                    // Draw the line
                    drawPath(
                        path = linePath,
                        color = emotionColor,
                        style = Stroke(
                            width = 3f,
                            cap = StrokeCap.Round
                        )
                    )
                    
                    // Create and draw the gradient fill
                    val fillPath = Path().apply {
                        // Start at the bottom left
                        moveTo(chartPoints.first().x, height - paddingBottom)
                        
                        // Add all points from the line
                        chartPoints.forEach { point ->
                            lineTo(point.x, point.y)
                        }
                        
                        // Close the path to the bottom right
                        lineTo(chartPoints.last().x, height - paddingBottom)
                        close()
                    }
                    
                    // Draw gradient fill
                    drawPath(
                        path = fillPath,
                        brush = LinearGradient(
                            colors = listOf(
                                emotionColor.copy(alpha = 0.3f),
                                emotionColor.copy(alpha = 0.1f),
                                emotionColor.copy(alpha = 0.0f)
                            ),
                            start = Offset(0f, paddingTop),
                            end = Offset(0f, height - paddingBottom)
                        )
                    )
                    
                    // Draw points
                    chartPoints.forEach { point ->
                        drawCircle(
                            color = emotionColor,
                            radius = 5f,
                            center = Offset(point.x, point.y)
                        )
                    }
                    
                    // Draw highlighted point if selected
                    selectedPointIndex.value?.let { index ->
                        if (index >= 0 && index < chartPoints.size) {
                            val point = chartPoints[index]
                            drawCircle(
                                color = Color.White,
                                radius = 8f,
                                center = Offset(point.x, point.y)
                            )
                            drawCircle(
                                color = emotionColor,
                                radius = 6f,
                                center = Offset(point.x, point.y)
                            )
                        }
                    }
                }
                
                // Draw X-axis labels (dates)
                val xLabelCount = 5.coerceAtMost(sortedDataPoints.size)
                if (xLabelCount > 0) {
                    val step = sortedDataPoints.size / xLabelCount.coerceAtLeast(1)
                    for (i in 0 until xLabelCount) {
                        val index = i * step
                        if (index < sortedDataPoints.size) {
                            val dataPoint = sortedDataPoints[index]
                            val x = paddingStart + (index.toFloat() * (chartWidth / (sortedDataPoints.size - 1).coerceAtLeast(1)))
                            val dateStr = formatDate(dataPoint.date, "dd/MM")
                            
                            drawContext.canvas.nativeCanvas.drawText(
                                dateStr,
                                x,
                                height - 10,
                                android.graphics.Paint().apply {
                                    color = TextSecondary.toArgb()
                                    textSize = 10.sp.toPx()
                                    textAlign = android.graphics.Paint.Align.CENTER
                                }
                            )
                        }
                    }
                }
                
                // Draw Y-axis labels (intensity values)
                for (i in 0..5) {
                    val value = minValue + ((maxValue - minValue) * i / 5)
                    val y = calculateYPosition(
                        value,
                        minValue,
                        maxValue,
                        chartHeight,
                        paddingTop,
                        paddingBottom
                    )
                    
                    drawContext.canvas.nativeCanvas.drawText(
                        "$value",
                        paddingStart - 10,
                        y + 5,
                        android.graphics.Paint().apply {
                            color = TextSecondary.toArgb()
                            textSize = 10.sp.toPx()
                            textAlign = android.graphics.Paint.Align.RIGHT
                        }
                    )
                }
            }
        }
    }
}

/**
 * A composable function that renders the emotion trend chart with a legend and additional context.
 * 
 * @param trend The emotional trend data to visualize
 * @param modifier Modifier for styling and layout
 * @param onPointSelected Callback when a data point is selected
 */
@Composable
fun EmotionTrendChartWithLegend(
    trend: EmotionalTrend,
    modifier: Modifier = Modifier,
    onPointSelected: (TrendDataPoint) -> Unit = {}
) {
    Column(modifier = modifier) {
        EmotionTrendChart(
            trend = trend,
            onPointSelected = onPointSelected
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = CardShape,
            elevation = 2.dp
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Tendencia: ${trend.overallTrend.getDisplayName()}",
                        style = MaterialTheme.typography.body1,
                        color = TextPrimary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    // Icon for trend direction
                    Text(
                        text = when (trend.overallTrend) {
                            TrendDirection.INCREASING -> "↗️"
                            TrendDirection.DECREASING -> "↘️"
                            TrendDirection.STABLE -> "→"
                            TrendDirection.FLUCTUATING -> "↕️"
                        },
                        style = MaterialTheme.typography.h6
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Intensidad promedio: ${trend.getFormattedAverageIntensity()}",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
                
                Text(
                    text = "Pico: ${trend.getFormattedPeakIntensity()} (${trend.getFormattedPeakDate()})",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Esta gráfica muestra cómo ha evolucionado tu emoción a lo largo del tiempo.",
                    style = MaterialTheme.typography.caption,
                    color = TextTertiary
                )
            }
        }
    }
}

/**
 * Returns the color associated with a specific emotion type.
 * 
 * @param emotionType The emotion type to get color for
 * @return Color associated with the emotion
 */
private fun getEmotionColor(emotionType: EmotionType): Color {
    return when (emotionType) {
        EmotionType.JOY -> EmotionJoy
        EmotionType.SADNESS -> EmotionSadness
        EmotionType.ANGER -> EmotionAnger
        EmotionType.FEAR -> EmotionFear
        EmotionType.DISGUST -> EmotionDisgust
        EmotionType.SURPRISE -> EmotionSurprise
        EmotionType.TRUST -> EmotionTrust
        EmotionType.ANTICIPATION -> EmotionAnticipation
        EmotionType.CALM -> EmotionCalm
        EmotionType.ANXIETY -> EmotionAnxiety
        else -> Primary
    }
}

/**
 * Formats a date for display on the chart.
 * 
 * @param date The date to format
 * @param pattern The format pattern to use
 * @return Formatted date string
 */
private fun formatDate(date: Date, pattern: String = "dd/MM"): String {
    val formatter = SimpleDateFormat(pattern, Locale("es"))
    return formatter.format(date)
}

/**
 * Calculates the Y position on the canvas for a given intensity value.
 * 
 * @param value The intensity value
 * @param minValue The minimum intensity value in the dataset
 * @param maxValue The maximum intensity value in the dataset
 * @param height The available height for drawing
 * @param paddingTop The top padding
 * @param paddingBottom The bottom padding
 * @return The Y coordinate for the value
 */
private fun calculateYPosition(
    value: Int,
    minValue: Int,
    maxValue: Int,
    height: Float,
    paddingTop: Float,
    paddingBottom: Float
): Float {
    val availableHeight = height - paddingTop - paddingBottom
    val range = (maxValue - minValue).coerceAtLeast(1)
    val ratio = (value - minValue).toFloat() / range
    
    // Invert the ratio since Y coordinates increase downward
    return paddingTop + availableHeight * (1 - ratio)
}

/**
 * Helper class to store calculated point data for rendering.
 */
private data class ChartPoint(
    val dataPoint: TrendDataPoint,
    val x: Float,
    val y: Float
)