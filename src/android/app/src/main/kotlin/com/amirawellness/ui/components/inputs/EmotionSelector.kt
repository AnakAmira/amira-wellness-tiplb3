package com.amirawellness.ui.components.inputs

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.foundation.background
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.foundation.shape.RoundedCornerShape
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.ui.theme.*
import com.amirawellness.R

/**
 * A composable function that displays a grid of emotions for selection during emotional check-ins.
 *
 * @param selectedEmotion The currently selected emotion, or null if no emotion is selected.
 * @param onEmotionSelected Callback function invoked when an emotion is selected.
 * @param modifier Modifier to be applied to the grid container.
 */
@Composable
fun EmotionSelector(
    selectedEmotion: EmotionType? = null,
    onEmotionSelected: (EmotionType) -> Unit,
    modifier: Modifier = Modifier
) {
    val emotions = listOf(
        EmotionType.JOY,
        EmotionType.SADNESS,
        EmotionType.ANGER,
        EmotionType.FEAR,
        EmotionType.DISGUST,
        EmotionType.SURPRISE,
        EmotionType.TRUST,
        EmotionType.ANTICIPATION,
        EmotionType.CALM,
        EmotionType.ANXIETY
    )
    
    // Create a grid layout using Column and Rows
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Split emotions into rows of 3
        val rows = emotions.chunked(3)
        
        rows.forEach { rowEmotions ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                rowEmotions.forEach { emotion ->
                    EmotionItem(
                        emotion = emotion,
                        isSelected = emotion == selectedEmotion,
                        onEmotionSelected = onEmotionSelected,
                        modifier = Modifier.weight(1f)
                    )
                }
                
                // Fill empty slots in the last row if needed
                repeat(3 - rowEmotions.size) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

/**
 * A composable function that displays a single emotion option with icon and label.
 *
 * @param emotion The emotion to display.
 * @param isSelected Whether this emotion is currently selected.
 * @param onEmotionSelected Callback function invoked when this emotion is selected.
 * @param modifier Modifier to be applied to the emotion item.
 */
@Composable
private fun EmotionItem(
    emotion: EmotionType,
    isSelected: Boolean,
    onEmotionSelected: (EmotionType) -> Unit,
    modifier: Modifier = Modifier
) {
    val emotionName = stringResource(id = getEmotionName(emotion))
    val contentDescription = if (isSelected) {
        stringResource(
            id = R.string.emotion_selected_content_description,
            emotionName
        )
    } else {
        stringResource(
            id = R.string.emotion_content_description,
            emotionName
        )
    }

    Card(
        modifier = modifier
            .aspectRatio(1f)
            .semantics { this.contentDescription = contentDescription }
            .clickable { onEmotionSelected(emotion) }
            .then(
                if (isSelected) {
                    Modifier.border(2.dp, getEmotionColor(emotion), CardShape)
                } else {
                    Modifier
                }
            ),
        shape = CardShape,
        elevation = CardDefaults.cardElevation(
            defaultElevation = if (isSelected) 4.dp else 1.dp
        ),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceEvenly
        ) {
            EmotionIcon(
                emotion = emotion,
                modifier = Modifier.size(48.dp)
            )
            
            Text(
                text = emotionName,
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.bodyMedium,
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

/**
 * A composable function that displays an icon representing an emotion.
 *
 * @param emotion The emotion to represent.
 * @param modifier Modifier to be applied to the icon container.
 */
@Composable
private fun EmotionIcon(
    emotion: EmotionType,
    modifier: Modifier = Modifier
) {
    val circleShape = RoundedCornerShape(percent = 50)
    
    Box(
        modifier = modifier
            .clip(circleShape)
            .background(getEmotionColor(emotion).copy(alpha = 0.2f))
            .padding(8.dp),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            painter = painterResource(id = getEmotionIconRes(emotion)),
            contentDescription = null, // Content description handled at parent level
            tint = getEmotionColor(emotion),
            modifier = Modifier.size(32.dp)
        )
    }
}

/**
 * Returns the appropriate color for a given emotion type.
 *
 * @param emotion The emotion type.
 * @return The color corresponding to the emotion type.
 */
fun getEmotionColor(emotion: EmotionType): Color {
    return when (emotion) {
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
    }
}

/**
 * Returns the appropriate icon resource ID for a given emotion type.
 *
 * @param emotion The emotion type.
 * @return The resource ID for the emotion icon.
 */
private fun getEmotionIconRes(emotion: EmotionType): Int {
    return when (emotion) {
        EmotionType.JOY -> R.drawable.ic_emotion_joy
        EmotionType.SADNESS -> R.drawable.ic_emotion_sadness
        EmotionType.ANGER -> R.drawable.ic_emotion_anger
        EmotionType.FEAR -> R.drawable.ic_emotion_fear
        EmotionType.DISGUST -> R.drawable.ic_emotion_disgust
        EmotionType.SURPRISE -> R.drawable.ic_emotion_surprise
        EmotionType.TRUST -> R.drawable.ic_emotion_trust
        EmotionType.ANTICIPATION -> R.drawable.ic_emotion_anticipation
        EmotionType.CALM -> R.drawable.ic_emotion_calm
        EmotionType.ANXIETY -> R.drawable.ic_emotion_anxiety
    }
}

/**
 * Returns the localized name for a given emotion type.
 *
 * @param emotion The emotion type.
 * @return The string resource ID for the emotion name.
 */
private fun getEmotionName(emotion: EmotionType): Int {
    return when (emotion) {
        EmotionType.JOY -> R.string.emotion_joy
        EmotionType.SADNESS -> R.string.emotion_sadness
        EmotionType.ANGER -> R.string.emotion_anger
        EmotionType.FEAR -> R.string.emotion_fear
        EmotionType.DISGUST -> R.string.emotion_disgust
        EmotionType.SURPRISE -> R.string.emotion_surprise
        EmotionType.TRUST -> R.string.emotion_trust
        EmotionType.ANTICIPATION -> R.string.emotion_anticipation
        EmotionType.CALM -> R.string.emotion_calm
        EmotionType.ANXIETY -> R.string.emotion_anxiety
    }
}

/**
 * A preview function for the EmotionSelector composable.
 */
@Preview
@Composable
private fun EmotionSelectorPreview() {
    MaterialTheme {
        EmotionSelector(
            selectedEmotion = null,
            onEmotionSelected = {}
        )
    }
}

/**
 * A preview function for the EmotionSelector composable with a selected emotion.
 */
@Preview
@Composable
private fun EmotionSelectorWithSelectionPreview() {
    MaterialTheme {
        EmotionSelector(
            selectedEmotion = EmotionType.JOY,
            onEmotionSelected = {}
        )
    }
}