package com.amirawellness.ui.components.cards

import androidx.compose.runtime.Composable // androidx.compose.runtime:1.5.0
import androidx.compose.runtime.remember // androidx.compose.runtime:1.5.0
import androidx.compose.material.Card // androidx.compose.material:1.5.0
import androidx.compose.material.MaterialTheme // androidx.compose.material:1.5.0
import androidx.compose.material.Text // androidx.compose.material:1.5.0
import androidx.compose.foundation.layout.Row // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.Column // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.Box // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.Spacer // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.padding // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.size // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.width // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.height // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.layout.Arrangement // androidx.compose.foundation.layout:1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui.Alignment:1.5.0
import androidx.compose.foundation.clickable // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.background // androidx.compose.foundation:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui.unit:1.5.0
import androidx.compose.ui.draw.shadow // androidx.compose.ui.draw:1.5.0
import androidx.compose.ui.draw.clip // androidx.compose.ui.draw:1.5.0
import androidx.compose.ui.graphics.Color // androidx.compose.ui.graphics:1.5.0
import androidx.compose.ui.tooling.preview.Preview // androidx.compose.ui.tooling.preview:1.5.0

import com.amirawellness.data.models.EmotionalState
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.ui.theme.CardShape
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import androidx.compose.foundation.shape.CircleShape // androidx.compose.foundation:1.5.0

/**
 * A card component for displaying emotional state information.
 * 
 * This composable renders a card with an emotion indicator, name, and intensity level.
 * It follows the minimalist, nature-inspired design language of the application,
 * supporting the emotional check-in and progress tracking features.
 * 
 * @param emotionalState The emotional state to display
 * @param onClick Callback for when the card is clicked
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
fun EmotionCard(
    emotionalState: EmotionalState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val emotionColor = remember { 
        try {
            Color(android.graphics.Color.parseColor(emotionalState.getColor()))
        } catch (e: IllegalArgumentException) {
            Color.Gray // Fallback color if parsing fails
        }
    }
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .shadow(elevation = 2.dp, shape = CardShape)
            .clip(CardShape),
        backgroundColor = Surface,
        shape = CardShape
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            EmotionIndicator(color = emotionColor)
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column {
                Text(
                    text = emotionalState.getDisplayName(),
                    style = MaterialTheme.typography.subtitle1,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = "${emotionalState.intensity}/10",
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
        }
    }
}

/**
 * A colored circular indicator representing an emotion.
 * 
 * @param color The color representing the emotion
 * @param modifier Optional modifier for customizing the layout
 */
@Composable
private fun EmotionIndicator(color: Color, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(color)
    )
}

/**
 * Preview for EmotionCard composable to verify appearance during development.
 */
@Preview(showBackground = true)
@Composable
private fun EmotionCardPreview() {
    val sampleEmotionalState = EmotionalState.createEmpty(
        emotionType = EmotionType.JOY,
        context = "STANDALONE"
    ).copy(intensity = 7)
    
    EmotionCard(
        emotionalState = sampleEmotionalState,
        onClick = { /* Preview only */ }
    )
}