package com.amirawellness.ui.components.inputs

import androidx.compose.foundation.layout.*
import androidx.compose.material.Slider
import androidx.compose.material.SliderDefaults
import androidx.compose.material.Text
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.hapticfeedback.LocalHapticFeedback
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.tooling.preview.Preview

import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.PrimaryVariant
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.SemiTransparentBlack
import com.amirawellness.ui.theme.AmiraWellnessTheme
import com.amirawellness.core.extensions.roundedCorners
import com.amirawellness.core.extensions.conditionalModifier
import com.amirawellness.data.models.EMOTION_INTENSITY_MIN
import com.amirawellness.data.models.EMOTION_INTENSITY_MAX
import com.amirawellness.data.models.EMOTION_INTENSITY_DEFAULT

private const val TAG = "IntensitySlider"

/**
 * A customizable slider for selecting emotion intensity with labels and optional styling
 *
 * @param value Current intensity value
 * @param onValueChange Callback for when the value changes
 * @param modifier Modifier for the component
 * @param enabled Whether the slider is enabled
 * @param activeTrackColor Custom color for the active track
 * @param inactiveTrackColor Custom color for the inactive track
 * @param thumbColor Custom color for the thumb
 * @param showLabels Whether to show min/max labels
 * @param minLabel Text for minimum label
 * @param maxLabel Text for maximum label
 * @param showValue Whether to show the current value below the slider
 * @param hapticFeedback Whether to provide haptic feedback on value change
 */
@Composable
fun IntensitySlider(
    value: Int,
    onValueChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    activeTrackColor: Color? = null,
    inactiveTrackColor: Color? = null,
    thumbColor: Color? = null,
    showLabels: Boolean = true,
    minLabel: String = "Baja", // Low
    maxLabel: String = "Alta", // High
    showValue: Boolean = true,
    hapticFeedback: Boolean = true
) {
    // Access haptic feedback if enabled
    val haptic = if (hapticFeedback) LocalHapticFeedback.current else null
    
    // Remember the current value to detect changes
    val currentValue = remember { mutableStateOf(value) }
    
    Column(modifier = modifier) {
        // Show labels if enabled
        if (showLabels) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = minLabel,
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
                Text(
                    text = maxLabel,
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
        }
        
        // Slider component
        Slider(
            value = value.toFloat(),
            onValueChange = { newValue ->
                val newIntValue = newValue.toInt()
                // Only trigger callbacks and haptic feedback if the value actually changed
                if (newIntValue != currentValue.value) {
                    currentValue.value = newIntValue
                    onValueChange(newIntValue)
                    // Perform haptic feedback if enabled
                    haptic?.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .roundedCorners(8),
            valueRange = EMOTION_INTENSITY_MIN.toFloat()..EMOTION_INTENSITY_MAX.toFloat(),
            steps = EMOTION_INTENSITY_MAX - EMOTION_INTENSITY_MIN - 1,
            enabled = enabled,
            colors = SliderDefaults.colors(
                activeTrackColor = activeTrackColor ?: Primary,
                inactiveTrackColor = inactiveTrackColor ?: SemiTransparentBlack.copy(alpha = 0.1f),
                thumbColor = thumbColor ?: PrimaryVariant,
                disabledActiveTrackColor = activeTrackColor?.copy(alpha = 0.3f) ?: Primary.copy(alpha = 0.3f),
                disabledInactiveTrackColor = inactiveTrackColor?.copy(alpha = 0.1f) ?: SemiTransparentBlack.copy(alpha = 0.05f),
                disabledThumbColor = thumbColor?.copy(alpha = 0.3f) ?: PrimaryVariant.copy(alpha = 0.3f)
            )
        )
        
        // Show current value if enabled
        if (showValue) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = value.toString(),
                style = MaterialTheme.typography.caption,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
                color = TextPrimary
            )
        }
    }
}

/**
 * Preview function for the IntensitySlider in Android Studio
 */
@Composable
@Preview
fun IntensitySliderPreview() {
    AmiraWellnessTheme {
        androidx.compose.material.Surface(
            modifier = Modifier.padding(16.dp)
        ) {
            IntensitySlider(
                value = EMOTION_INTENSITY_DEFAULT,
                onValueChange = {}
            )
        }
    }
}