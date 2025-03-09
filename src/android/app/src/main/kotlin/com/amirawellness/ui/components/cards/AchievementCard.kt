package com.amirawellness.ui.components.cards

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Lock
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import coil.compose.rememberAsyncImagePainter
import com.amirawellness.data.models.Achievement
import com.amirawellness.data.models.AchievementCategory
import com.amirawellness.ui.theme.CardShape
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Success

/**
 * A composable function that renders a card displaying an achievement with its metadata,
 * progress, and locked/unlocked status.
 *
 * @param achievement The achievement to display
 * @param onClick Callback function invoked when the card is clicked
 * @param modifier Optional Modifier for customizing the layout
 */
@Composable
fun AchievementCard(
    achievement: Achievement,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = CardShape,
        elevation = 2.dp,
        backgroundColor = Surface
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AchievementIcon(
                achievement = achievement,
                modifier = Modifier.size(48.dp)
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = achievement.title,
                    style = MaterialTheme.typography.subtitle1,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = achievement.description,
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
                
                if (!achievement.isEarned() && achievement.progress > 0) {
                    Spacer(modifier = Modifier.height(8.dp))
                    ProgressIndicator(achievement = achievement)
                }
            }
            
            Spacer(modifier = Modifier.width(8.dp))
            
            StatusIndicator(achievement = achievement)
        }
    }
}

/**
 * A composable function that renders the achievement icon or a placeholder
 * if no icon URL is provided.
 *
 * @param achievement The achievement whose icon should be displayed
 * @param modifier Optional Modifier for customizing the layout
 */
@Composable
private fun AchievementIcon(
    achievement: Achievement,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .shadow(
                elevation = 2.dp,
                shape = CardShape
            )
            .clip(CardShape),
        contentAlignment = Alignment.Center
    ) {
        if (achievement.iconUrl.isNotEmpty()) {
            AsyncImage(
                model = achievement.iconUrl,
                contentDescription = achievement.title,
                modifier = Modifier
                    .fillMaxSize()
                    .then(
                        if (!achievement.isEarned()) {
                            Modifier.alpha(0.5f)
                        } else {
                            Modifier
                        }
                    )
            )
        } else {
            // Default icon based on category
            val color = getCategoryColor(achievement.category)
            Icon(
                imageVector = Icons.Filled.EmojiEvents,
                contentDescription = achievement.title,
                tint = color,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(8.dp)
                    .then(
                        if (!achievement.isEarned()) {
                            Modifier.alpha(0.5f)
                        } else {
                            Modifier
                        }
                    )
            )
        }
    }
}

/**
 * A composable function that renders a progress indicator for achievements
 * that are in progress.
 *
 * @param achievement The achievement whose progress should be displayed
 * @param modifier Optional Modifier for customizing the layout
 */
@Composable
private fun ProgressIndicator(
    achievement: Achievement,
    modifier: Modifier = Modifier
) {
    val progress = remember { achievement.progress }
    val progressText = remember { "${achievement.getProgressPercentage()}%" }
    val color = remember { getCategoryColor(achievement.category) }
    
    Column(modifier = modifier) {
        LinearProgressIndicator(
            progress = progress.toFloat(),
            modifier = Modifier.fillMaxWidth(),
            color = color
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = progressText,
            style = MaterialTheme.typography.caption,
            color = TextSecondary
        )
    }
}

/**
 * A composable function that renders an icon indicating the achievement status
 * (locked or completed).
 *
 * @param achievement The achievement whose status should be displayed
 * @param modifier Optional Modifier for customizing the layout
 */
@Composable
private fun StatusIndicator(
    achievement: Achievement,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.size(24.dp),
        contentAlignment = Alignment.Center
    ) {
        if (achievement.isEarned()) {
            Icon(
                imageVector = Icons.Filled.EmojiEvents,
                contentDescription = "Achievement Earned",
                tint = Success
            )
        } else {
            Icon(
                imageVector = Icons.Filled.Lock,
                contentDescription = "Achievement Locked",
                tint = TextSecondary
            )
        }
    }
}

/**
 * A function that returns an appropriate color based on the achievement category.
 *
 * @param category The achievement category
 * @return Color associated with the achievement category
 */
private fun getCategoryColor(category: AchievementCategory): Color {
    return when (category) {
        AchievementCategory.STREAK -> Primary
        AchievementCategory.JOURNALING -> Secondary 
        AchievementCategory.EMOTIONAL_AWARENESS -> Primary.copy(alpha = 0.8f)
        AchievementCategory.TOOL_USAGE -> Secondary.copy(alpha = 0.8f)
        AchievementCategory.MILESTONE -> Success
    }
}