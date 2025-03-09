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
import androidx.compose.foundation.clickable
import androidx.compose.foundation.background
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.draw.clip
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Subject
import androidx.compose.material.icons.filled.Audiotrack
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.TouchApp
import androidx.compose.material.icons.filled.List
import coil.compose.AsyncImage

import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.models.ToolContentType
import com.amirawellness.ui.components.buttons.IconButton
import com.amirawellness.ui.theme.CardShape
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary

/**
 * A composable function that renders a card displaying a tool with its metadata,
 * category, duration, and actions.
 *
 * @param tool The tool to display
 * @param onClick Callback invoked when the card is clicked
 * @param onFavoriteClick Callback invoked when the favorite button is clicked
 * @param modifier Additional modifiers to apply to the card
 */
@Composable
fun ToolCard(
    tool: Tool,
    onClick: () -> Unit,
    onFavoriteClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .shadow(elevation = 2.dp),
        shape = CardShape,
        backgroundColor = Surface,
        elevation = 0.dp
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Category badge
            CategoryBadge(category = tool.category)
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Tool name
            Text(
                text = tool.name,
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            // Tool description
            Text(
                text = tool.description,
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                maxLines = 2
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Divider()
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Metadata row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Duration
                DurationIndicator(durationMinutes = tool.estimatedDuration)
                
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Content type icon
                    ContentTypeIcon(contentType = tool.contentType)
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    // Favorite button
                    IconButton(
                        icon = if (tool.isFavorite) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                        onClick = onFavoriteClick,
                        tint = if (tool.isFavorite) Primary else TextSecondary
                    )
                }
            }
        }
    }
}

/**
 * A composable function that renders a badge displaying the tool's category.
 *
 * @param category The tool category to display
 * @param modifier Additional modifiers to apply
 */
@Composable
private fun CategoryBadge(
    category: ToolCategory,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(MaterialTheme.shapes.small)
            .background(Primary.copy(alpha = 0.1f))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Start
    ) {
        // Load category icon if available
        if (category.iconUrl != null) {
            AsyncImage(
                model = category.iconUrl,
                contentDescription = null,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
        }
        
        Text(
            text = category.name,
            style = MaterialTheme.typography.caption,
            color = Primary
        )
    }
}

/**
 * A composable function that renders the estimated duration of a tool.
 *
 * @param durationMinutes The duration in minutes
 * @param modifier Additional modifiers to apply
 */
@Composable
private fun DurationIndicator(
    durationMinutes: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Filled.Schedule,
            contentDescription = null,
            tint = TextSecondary,
            modifier = Modifier.size(16.dp)
        )
        
        Spacer(modifier = Modifier.width(4.dp))
        
        Text(
            text = formatDuration(durationMinutes),
            style = MaterialTheme.typography.caption,
            color = TextSecondary
        )
    }
}

/**
 * A composable function that renders an icon representing the tool's content type.
 *
 * @param contentType The type of tool content
 * @param modifier Additional modifiers to apply
 */
@Composable
private fun ContentTypeIcon(
    contentType: ToolContentType,
    modifier: Modifier = Modifier
) {
    val icon = when (contentType) {
        ToolContentType.TEXT -> Icons.Filled.Subject
        ToolContentType.AUDIO -> Icons.Filled.Audiotrack
        ToolContentType.VIDEO -> Icons.Filled.Videocam
        ToolContentType.INTERACTIVE -> Icons.Filled.TouchApp
        ToolContentType.GUIDED_EXERCISE -> Icons.Filled.List
    }
    
    Icon(
        imageVector = icon,
        contentDescription = null,
        tint = TextSecondary,
        modifier = modifier.size(16.dp)
    )
}

/**
 * Formats the duration in minutes to a human-readable time string.
 *
 * @param durationMinutes The duration in minutes
 * @return Formatted duration string (e.g., "5 min")
 */
private fun formatDuration(durationMinutes: Int): String {
    return "$durationMinutes min"
}