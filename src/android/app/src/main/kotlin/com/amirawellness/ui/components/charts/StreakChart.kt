package com.amirawellness.ui.components.charts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Card
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.drawCircle
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.amirawellness.data.models.DailyActivity
import com.amirawellness.data.models.StreakInfo
import com.amirawellness.ui.components.loading.ProgressBar
import com.amirawellness.ui.theme.*
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date

/**
 * A composable function that displays a streak chart visualizing user streak information
 * with a calendar-style representation of active days and progress towards the next milestone.
 *
 * @param streakInfo Information about the user's streak
 * @param modifier Additional modifier for customizing the component
 */
@Composable
fun StreakChart(
    streakInfo: StreakInfo,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Display streak summary (current streak, longest streak)
        StreakSummary(streakInfo = streakInfo)
        
        // Display progress towards next milestone
        MilestoneProgress(streakInfo = streakInfo)
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Display calendar-style grid of activity
        CalendarGrid(activities = streakInfo.streakHistory)
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Display weekday distribution chart
        WeekdayDistributionChart(streakInfo = streakInfo)
    }
}

/**
 * A composable function that displays summary information about the user's streak.
 *
 * @param streakInfo Information about the user's streak
 * @param modifier Additional modifier for customizing the component
 */
@Composable
fun StreakSummary(
    streakInfo: StreakInfo,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 2.dp,
        shape = RoundedCornerShape(8.dp),
        backgroundColor = Surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Current streak
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = streakInfo.currentStreak.toString(),
                    style = MaterialTheme.typography.h4,
                    color = Primary
                )
                Text(
                    text = "Current Streak",
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
            }
            
            // Divider
            Box(
                modifier = Modifier
                    .height(40.dp)
                    .width(1.dp)
                    .background(Color.LightGray)
            )
            
            // Longest streak
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = streakInfo.longestStreak.toString(),
                    style = MaterialTheme.typography.h4,
                    color = Primary
                )
                Text(
                    text = "Longest Streak",
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
            }
        }
    }
}

/**
 * A composable function that displays progress towards the next streak milestone.
 *
 * @param streakInfo Information about the user's streak
 * @param modifier Additional modifier for customizing the component
 */
@Composable
fun MilestoneProgress(
    streakInfo: StreakInfo,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Display next milestone text
        Text(
            text = "Next milestone: ${streakInfo.nextMilestone} days",
            style = MaterialTheme.typography.subtitle1,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Progress bar showing progress towards the next milestone
        ProgressBar(
            progress = streakInfo.progressToNextMilestone,
            modifier = Modifier.fillMaxWidth(),
            height = 12f,
            backgroundColor = Surface,
            progressColor = Primary
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        // Display current progress text
        Text(
            text = "${streakInfo.currentStreak}/${streakInfo.nextMilestone} days",
            style = MaterialTheme.typography.caption,
            color = TextSecondary
        )
    }
}

/**
 * A composable function that displays a calendar-style grid of streak activity.
 *
 * @param activities List of daily activities for the streak
 * @param modifier Additional modifier for customizing the component
 */
@Composable
fun CalendarGrid(
    activities: List<DailyActivity>,
    modifier: Modifier = Modifier
) {
    // Calculate the dates to display (last 28 days - 4 weeks)
    val calendar = Calendar.getInstance()
    calendar.add(Calendar.DAY_OF_YEAR, 0) // Start from today
    
    val endDate = calendar.time
    calendar.add(Calendar.DAY_OF_YEAR, -27) // Go back 27 days to show 4 weeks
    val startDate = calendar.time
    
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        // Display card with title
        Card(
            modifier = Modifier.fillMaxWidth(),
            elevation = 2.dp,
            shape = RoundedCornerShape(8.dp),
            backgroundColor = Surface
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Activity Calendar",
                    style = MaterialTheme.typography.h6,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(12.dp))
                
                // Weekday labels row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    val weekdays = listOf("M", "T", "W", "T", "F", "S", "S")
                    weekdays.forEach { day ->
                        Text(
                            text = day,
                            style = MaterialTheme.typography.caption,
                            color = TextSecondary,
                            modifier = Modifier.width(24.dp),
                            maxLines = 1
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                // Generate the 4-week grid
                // Clone the calendar to iterate through dates
                val iteratorCalendar = Calendar.getInstance()
                iteratorCalendar.time = startDate
                
                // Create 4 weeks
                for (week in 0 until 4) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        // Create 7 days per week
                        for (day in 0 until 7) {
                            val currentDate = iteratorCalendar.time
                            
                            // Find the activity for this date
                            val activity = activities.find { dailyActivity ->
                                val activityCalendar = Calendar.getInstance()
                                activityCalendar.time = dailyActivity.date
                                
                                val currentCalendar = Calendar.getInstance()
                                currentCalendar.time = currentDate
                                
                                activityCalendar.get(Calendar.YEAR) == currentCalendar.get(Calendar.YEAR) &&
                                        activityCalendar.get(Calendar.DAY_OF_YEAR) == currentCalendar.get(Calendar.DAY_OF_YEAR)
                            }
                            
                            // Display the day indicator
                            DayIndicator(
                                activity = activity,
                                modifier = Modifier.size(24.dp)
                            )
                            
                            // Move to next day
                            iteratorCalendar.add(Calendar.DAY_OF_YEAR, 1)
                        }
                    }
                    
                    if (week < 3) {
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }
    }
}

/**
 * A composable function that displays a single day indicator in the streak calendar.
 *
 * @param activity The daily activity data for this day, or null if no activity
 * @param modifier Additional modifier for customizing the component
 */
@Composable
fun DayIndicator(
    activity: DailyActivity?,
    modifier: Modifier = Modifier
) {
    // Determine color based on activity status
    val color = if (activity != null && activity.isActive) {
        Primary
    } else {
        PrimaryLight.copy(alpha = 0.3f)
    }
    
    // Create the day indicator as a colored circle
    Box(
        modifier = modifier
            .drawBehind {
                drawCircle(
                    color = color,
                    radius = size.minDimension / 2
                )
            }
            .clickable(enabled = activity != null) {
                // Add click handling if needed (e.g., show activity details)
            }
    )
}

/**
 * A composable function that displays a bar chart of activity distribution by weekday.
 *
 * @param streakInfo Information about the user's streak
 * @param modifier Additional modifier for customizing the component
 */
@Composable
fun WeekdayDistributionChart(
    streakInfo: StreakInfo,
    modifier: Modifier = Modifier
) {
    // Get weekday distribution data
    val weekdayCounts = streakInfo.getActiveWeekdays()
    
    // Find the maximum count for scaling
    val maxCount = weekdayCounts.values.maxOrNull() ?: 1
    
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 2.dp,
        shape = RoundedCornerShape(8.dp),
        backgroundColor = Surface
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Activity by Day of Week",
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Bar chart
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.Bottom
            ) {
                // For each day of the week (1=Monday, 7=Sunday)
                for (day in 1..7) {
                    val count = weekdayCounts[day] ?: 0
                    val height = if (maxCount > 0) {
                        (count.toFloat() / maxCount) * 100
                    } else {
                        0f
                    }
                    
                    // Day column with label
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Display count above bar if non-zero
                        if (count > 0) {
                            Text(
                                text = count.toString(),
                                style = MaterialTheme.typography.caption,
                                color = TextSecondary,
                                fontSize = 10.sp
                            )
                            
                            Spacer(modifier = Modifier.height(2.dp))
                        }
                        
                        // Bar
                        Box(
                            modifier = Modifier
                                .width(24.dp)
                                .height(if (count > 0) height.dp else 4.dp)
                                .clip(RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp))
                                .background(if (count > 0) Primary else PrimaryLight.copy(alpha = 0.3f))
                        )
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        // Day label
                        val dayLabel = when (day) {
                            1 -> "M"
                            2 -> "T"
                            3 -> "W"
                            4 -> "T"
                            5 -> "F"
                            6 -> "S"
                            7 -> "S"
                            else -> ""
                        }
                        
                        Text(
                            text = dayLabel,
                            style = MaterialTheme.typography.caption,
                            color = TextSecondary
                        )
                    }
                }
            }
        }
    }
}

/**
 * Preview function for StreakChart
 */
@Preview
@Composable
fun StreakChartPreview() {
    // Create sample data for preview
    val calendar = Calendar.getInstance()
    val today = calendar.time
    
    val activities = mutableListOf<DailyActivity>()
    
    // Generate some sample activities for the last 28 days
    for (i in 0 until 28) {
        calendar.time = today
        calendar.add(Calendar.DAY_OF_YEAR, -i)
        
        // Make some days active for demonstration
        val isActive = i % 2 == 0 || i % 3 == 0
        
        activities.add(
            DailyActivity(
                date = calendar.time,
                isActive = isActive,
                activities = emptyList()
            )
        )
    }
    
    // Create sample streak info
    val sampleStreakInfo = StreakInfo(
        currentStreak = 5,
        longestStreak = 8,
        totalDaysActive = 15,
        lastActiveDate = today,
        nextMilestone = 7,
        progressToNextMilestone = 5f / 7f,
        streakHistory = activities
    )
    
    // Preview the streak chart
    AmiraWellnessTheme {
        Surface(
            color = MaterialTheme.colors.background,
            modifier = Modifier.padding(16.dp)
        ) {
            StreakChart(streakInfo = sampleStreakInfo)
        }
    }
}