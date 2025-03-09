package com.amirawellness.ui.components.charts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.LinearGradient
import androidx.compose.ui.graphics.drawscope.drawLine
import androidx.compose.ui.graphics.drawscope.drawRect
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.amirawellness.ui.theme.CardShape
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.PrimaryLight
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.SecondaryLight
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import java.time.DayOfWeek

/**
 * A data class representing the calculated values for a single bar in the activity chart.
 * This encapsulates all the necessary information to render a bar on the canvas.
 *
 * @param day The day of week this bar represents
 * @param activityCount The number of activities for this day
 * @param x The x-coordinate of the bar's left edge
 * @param width The width of the bar
 * @param height The height of the bar
 * @param isHighlighted Whether this bar represents the most active day
 */
data class BarData(
    val day: DayOfWeek,
    val activityCount: Int,
    val x: Float,
    val width: Float,
    val height: Float,
    val isHighlighted: Boolean
)

/**
 * A composable function that renders a bar chart visualizing user activity by day of week.
 * This chart helps users understand their usage patterns and engagement with the application.
 *
 * @param activityByDay Map of DayOfWeek to activity count
 * @param mostActiveDay The day with the highest activity (highlighted in the chart)
 * @param modifier Modifier for customizing the layout
 */
@Composable
fun ActivityBarChart(
    activityByDay: Map<DayOfWeek, Int>,
    mostActiveDay: DayOfWeek,
    modifier: Modifier = Modifier
) {
    Card(
        shape = CardShape,
        backgroundColor = Surface,
        elevation = 4.dp,
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Title
            Text(
                text = "Actividad semanal",
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Find max activity for scaling
            val maxActivity = remember(activityByDay) {
                activityByDay.values.maxOrNull() ?: 0
            }
            
            if (maxActivity == 0) {
                // Handle empty state
                Text(
                    text = "No hay actividad para mostrar",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary,
                    modifier = Modifier.padding(vertical = 48.dp).align(Alignment.CenterHorizontally)
                )
            } else {
                // Chart canvas
                Canvas(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                ) {
                    val canvasWidth = size.width
                    val canvasHeight = size.height
                    
                    val chartWidth = canvasWidth - 40f  // Leave space for y-axis labels
                    val chartHeight = canvasHeight - 40f  // Leave space for x-axis labels
                    
                    val chartStartX = 40f
                    val chartStartY = 10f
                    val chartEndY = chartStartY + chartHeight
                    
                    // Draw axes
                    drawLine(
                        color = TextSecondary,
                        start = androidx.compose.ui.geometry.Offset(chartStartX, chartStartY),
                        end = androidx.compose.ui.geometry.Offset(chartStartX, chartEndY),
                        strokeWidth = 1.5f
                    )
                    
                    drawLine(
                        color = TextSecondary,
                        start = androidx.compose.ui.geometry.Offset(chartStartX, chartEndY),
                        end = androidx.compose.ui.geometry.Offset(canvasWidth, chartEndY),
                        strokeWidth = 1.5f
                    )
                    
                    // Draw horizontal grid lines
                    val gridLineCount = 4
                    for (i in 0..gridLineCount) {
                        val y = chartEndY - (i * chartHeight / gridLineCount)
                        drawLine(
                            color = Color(0x22000000),
                            start = androidx.compose.ui.geometry.Offset(chartStartX, y),
                            end = androidx.compose.ui.geometry.Offset(canvasWidth, y),
                            strokeWidth = 0.5f
                        )
                        
                        // Draw y-axis labels
                        if (i > 0) { // Skip 0 as it's already at the x-axis
                            val labelValue = (maxActivity * i / gridLineCount)
                            drawContext.canvas.nativeCanvas.drawText(
                                labelValue.toString(),
                                chartStartX - 10f,
                                y - 5f,
                                android.graphics.Paint().apply {
                                    color = TextSecondary.toArgb()
                                    textSize = 10.sp.toPx()
                                    textAlign = android.graphics.Paint.Align.RIGHT
                                }
                            )
                        }
                    }
                    
                    // Calculate bar width and spacing
                    val dayCount = DayOfWeek.values().size
                    val barWidth = (chartWidth - 40f) / dayCount
                    val barSpacing = barWidth * 0.2f
                    val actualBarWidth = barWidth - barSpacing
                    
                    // Prepare bar data for all days
                    val bars = DayOfWeek.values().mapIndexed { index, day ->
                        val activityCount = activityByDay[day] ?: 0
                        val barHeight = calculateBarHeight(activityCount, maxActivity, chartHeight)
                        val barX = chartStartX + (index * barWidth) + (barSpacing / 2)
                        
                        BarData(
                            day = day,
                            activityCount = activityCount,
                            x = barX,
                            width = actualBarWidth,
                            height = barHeight,
                            isHighlighted = day == mostActiveDay
                        )
                    }
                    
                    // Draw bars and day labels
                    bars.forEach { barData ->
                        // Draw bar
                        val barStartY = chartEndY - barData.height
                        
                        val barBrush = if (barData.isHighlighted) {
                            Brush.linearGradient(
                                colors = listOf(Secondary, SecondaryLight),
                                start = androidx.compose.ui.geometry.Offset(0f, barStartY),
                                end = androidx.compose.ui.geometry.Offset(0f, chartEndY)
                            )
                        } else {
                            Brush.linearGradient(
                                colors = listOf(Primary, PrimaryLight),
                                start = androidx.compose.ui.geometry.Offset(0f, barStartY),
                                end = androidx.compose.ui.geometry.Offset(0f, chartEndY)
                            )
                        }
                        
                        drawRect(
                            brush = barBrush,
                            topLeft = androidx.compose.ui.geometry.Offset(barData.x, barStartY),
                            size = androidx.compose.ui.geometry.Size(barData.width, barData.height)
                        )
                        
                        // Draw activity count on top of the bar if space allows
                        if (barData.height > 25f && barData.activityCount > 0) {
                            drawContext.canvas.nativeCanvas.drawText(
                                barData.activityCount.toString(),
                                barData.x + barData.width / 2,
                                barStartY - 5f,
                                android.graphics.Paint().apply {
                                    color = TextPrimary.toArgb()
                                    textSize = 10.sp.toPx()
                                    textAlign = android.graphics.Paint.Align.CENTER
                                }
                            )
                        }
                        
                        // Draw day label
                        val dayLabel = getDayAbbreviation(barData.day)
                        drawContext.canvas.nativeCanvas.drawText(
                            dayLabel,
                            barData.x + barData.width / 2,
                            chartEndY + 20f,
                            android.graphics.Paint().apply {
                                color = if (barData.isHighlighted) Secondary.toArgb() else TextSecondary.toArgb()
                                textSize = 12.sp.toPx()
                                textAlign = android.graphics.Paint.Align.CENTER
                                isFakeBoldText = barData.isHighlighted
                            }
                        )
                    }
                }
            }
        }
    }
}

/**
 * A composable function that renders the activity bar chart with a legend and additional context.
 * This provides more information for interpreting the chart data.
 *
 * @param activityByDay Map of DayOfWeek to activity count
 * @param mostActiveDay The day with the highest activity
 * @param modifier Modifier for customizing the layout
 */
@Composable
fun ActivityBarChartWithLegend(
    activityByDay: Map<DayOfWeek, Int>,
    mostActiveDay: DayOfWeek,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        ActivityBarChart(
            activityByDay = activityByDay,
            mostActiveDay = mostActiveDay
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Legend and context
        Card(
            shape = CardShape,
            backgroundColor = Surface,
            elevation = 2.dp,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    text = "Insights",
                    style = MaterialTheme.typography.subtitle1,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                // Most productive day
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(vertical = 4.dp)
                ) {
                    Canvas(
                        modifier = Modifier
                            .width(16.dp)
                            .height(16.dp)
                    ) {
                        drawRect(
                            brush = Brush.linearGradient(
                                colors = listOf(Secondary, SecondaryLight)
                            ),
                            size = size
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "Día más activo: ${getDayName(mostActiveDay)}",
                        style = MaterialTheme.typography.body2,
                        color = TextPrimary
                    )
                }
                
                // Regular days
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(vertical = 4.dp)
                ) {
                    Canvas(
                        modifier = Modifier
                            .width(16.dp)
                            .height(16.dp)
                    ) {
                        drawRect(
                            brush = Brush.linearGradient(
                                colors = listOf(Primary, PrimaryLight)
                            ),
                            size = size
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "Otros días",
                        style = MaterialTheme.typography.body2,
                        color = TextPrimary
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                // Total activities
                val totalActivities = activityByDay.values.sum()
                Text(
                    text = "Total de actividades: $totalActivities",
                    style = MaterialTheme.typography.body2,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                // Average activity per day
                val avgActivitiesPerDay = if (activityByDay.isNotEmpty()) {
                    "%.1f".format(totalActivities.toFloat() / activityByDay.size)
                } else "0"
                
                Text(
                    text = "Promedio diario: $avgActivitiesPerDay actividades",
                    style = MaterialTheme.typography.body2,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Este gráfico muestra tu nivel de actividad en la aplicación a lo largo de la semana. Mantener una práctica regular contribuye a un mejor bienestar emocional.",
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
            }
        }
    }
}

/**
 * Returns the abbreviated name for a day of week in Spanish.
 *
 * @param dayOfWeek The day of week
 * @return Abbreviated day name in Spanish
 */
private fun getDayAbbreviation(dayOfWeek: DayOfWeek): String {
    return when (dayOfWeek) {
        DayOfWeek.MONDAY -> "Lun"
        DayOfWeek.TUESDAY -> "Mar"
        DayOfWeek.WEDNESDAY -> "Mié"
        DayOfWeek.THURSDAY -> "Jue"
        DayOfWeek.FRIDAY -> "Vie"
        DayOfWeek.SATURDAY -> "Sáb"
        DayOfWeek.SUNDAY -> "Dom"
    }
}

/**
 * Returns the full name for a day of week in Spanish.
 *
 * @param dayOfWeek The day of week
 * @return Full day name in Spanish
 */
private fun getDayName(dayOfWeek: DayOfWeek): String {
    return when (dayOfWeek) {
        DayOfWeek.MONDAY -> "Lunes"
        DayOfWeek.TUESDAY -> "Martes"
        DayOfWeek.WEDNESDAY -> "Miércoles"
        DayOfWeek.THURSDAY -> "Jueves"
        DayOfWeek.FRIDAY -> "Viernes"
        DayOfWeek.SATURDAY -> "Sábado"
        DayOfWeek.SUNDAY -> "Domingo"
    }
}

/**
 * Calculates the height of a bar based on activity count and maximum value.
 * Ensures that non-zero values have a minimum visible height.
 *
 * @param activityCount The number of activities for this day
 * @param maxValue The maximum activity count across all days
 * @param availableHeight The available height for the bar
 * @return Height of the bar in pixels
 */
private fun calculateBarHeight(activityCount: Int, maxValue: Int, availableHeight: Float): Float {
    if (activityCount == 0) return 0f
    if (maxValue == 0) return 0f
    
    val ratio = activityCount.toFloat() / maxValue.toFloat()
    val calculatedHeight = ratio * availableHeight
    
    // Ensure a minimum visible height for non-zero values
    return maxOf(calculatedHeight, 5f)
}