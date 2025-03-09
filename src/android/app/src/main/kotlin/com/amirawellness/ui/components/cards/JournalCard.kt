package com.amirawellness.ui.components.cards

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.material.Card
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.material.Icon
import androidx.compose.material.Divider
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.outlined.Sync
import java.util.Date

import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.ui.components.buttons.IconButton
import com.amirawellness.ui.theme.CardShape
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Success
import com.amirawellness.ui.theme.Error
import com.amirawellness.core.extensions.toJournalDateString
import com.amirawellness.core.extensions.getRelativeTimeSpanString

/**
 * A composable function that renders a card displaying a voice journal entry with its metadata,
 * emotional states, and actions.
 *
 * @param journal The journal entry to display
 * @param onClick Function to execute when the card is clicked
 * @param onPlayClick Function to execute when the play button is clicked
 * @param onFavoriteClick Function to execute when the favorite button is clicked
 * @param modifier Additional modifiers to apply to the card
 */
@Composable
fun JournalCard(
    journal: Journal,
    onClick: () -> Unit,
    onPlayClick: () -> Unit,
    onFavoriteClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .shadow(4.dp),
        shape = CardShape,
        elevation = 0.dp,
        backgroundColor = Surface
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Journal date and time
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                val journalDate = remember(journal.createdAt) { 
                    Date(journal.createdAt).toJournalDateString() 
                }
                val relativeTime = remember(journal.createdAt) { 
                    Date(journal.createdAt).getRelativeTimeSpanString() 
                }
                
                Text(
                    text = journalDate,
                    style = MaterialTheme.typography.subtitle1,
                    color = TextPrimary
                )
                Text(
                    text = relativeTime,
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Journal title
            Text(
                text = journal.title.ifEmpty { "Sin título" }, // "No title" in Spanish
                style = MaterialTheme.typography.h6,
                color = TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Emotional states comparison
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Pre-recording emotional state
                EmotionIndicator(
                    emotionalState = journal.preEmotionalState,
                    modifier = Modifier.weight(1f)
                )
                
                // Emotional shift arrow
                EmotionalShiftArrow(
                    journal = journal,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )
                
                // Post-recording emotional state
                EmotionIndicator(
                    emotionalState = journal.postEmotionalState,
                    modifier = Modifier.weight(1f)
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Divider()
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Metadata and actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Duration and sync status
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    DurationIndicator(
                        durationSeconds = journal.durationSeconds
                    )
                    
                    if (journal.isLocalOnly()) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(
                            imageVector = Icons.Outlined.Sync,
                            contentDescription = null,
                            tint = TextSecondary,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
                
                // Action buttons
                Row {
                    // Play button
                    IconButton(
                        icon = Icons.Filled.PlayArrow,
                        onClick = onPlayClick,
                        tint = Primary
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    // Favorite button
                    IconButton(
                        icon = if (journal.isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        onClick = onFavoriteClick,
                        tint = if (journal.isFavorite) Secondary else TextSecondary
                    )
                }
            }
        }
    }
}

/**
 * A composable function that renders an emotion indicator with name, intensity, and color.
 *
 * @param emotionalState The emotional state to display
 * @param modifier Additional modifiers to apply
 */
@Composable
private fun EmotionIndicator(
    emotionalState: EmotionalState,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        // Emotion color indicator
        val emotionColor = remember(emotionalState.emotionType) {
            try {
                Color(android.graphics.Color.parseColor(emotionalState.getColor()))
            } catch (e: Exception) {
                // Fallback color if parsing fails
                Primary
            }
        }
        
        Box(
            modifier = Modifier
                .size(24.dp)
                .clip(androidx.compose.foundation.shape.CircleShape)
                .background(emotionColor)
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        // Emotion name
        Text(
            text = emotionalState.getDisplayName(),
            style = MaterialTheme.typography.body2,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(2.dp))
        
        // Emotion intensity
        Text(
            text = "${emotionalState.intensity}/10",
            style = MaterialTheme.typography.caption,
            color = TextSecondary
        )
    }
}

/**
 * A composable function that renders an arrow indicating the direction of emotional shift.
 *
 * @param journal The journal entry to analyze for emotional shift
 * @param modifier Additional modifiers to apply
 */
@Composable
private fun EmotionalShiftArrow(
    journal: Journal,
    modifier: Modifier = Modifier
) {
    val (icon, tint) = remember(journal) {
        when {
            journal.hasPositiveShift() -> Icons.Filled.ArrowUpward to Success
            journal.hasNegativeShift() -> Icons.Filled.ArrowDownward to Error
            else -> Icons.Filled.ArrowForward to TextSecondary
        }
    }
    
    Icon(
        imageVector = icon,
        contentDescription = null,
        tint = tint,
        modifier = modifier.size(24.dp)
    )
}

/**
 * A composable function that renders the duration of a journal recording.
 *
 * @param durationSeconds The duration in seconds
 * @param modifier Additional modifiers to apply
 */
@Composable
private fun DurationIndicator(
    durationSeconds: Int,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
    ) {
        Icon(
            imageVector = Icons.Filled.AccessTime,
            contentDescription = null,
            tint = TextSecondary,
            modifier = Modifier.size(16.dp)
        )
        
        Spacer(modifier = Modifier.width(4.dp))
        
        val formattedDuration = remember(durationSeconds) { 
            formatDuration(durationSeconds) 
        }
        
        Text(
            text = formattedDuration,
            style = MaterialTheme.typography.caption,
            color = TextSecondary
        )
    }
}

/**
 * A function that formats the duration in seconds to a human-readable time string.
 *
 * @param durationSeconds The duration in seconds
 * @return Formatted duration string (e.g., "3:45")
 */
private fun formatDuration(durationSeconds: Int): String {
    val minutes = durationSeconds / 60
    val seconds = durationSeconds % 60
    return "$minutes:${seconds.toString().padStart(2, '0')}"
}