package com.amirawellness.ui.components.animations

import androidx.compose.animation.core.* // androidx.compose.animation.core version: 1.4.3
import androidx.compose.foundation.Canvas // androidx.compose.foundation version: 1.4.3
import androidx.compose.foundation.layout.* // androidx.compose.foundation version: 1.4.3
import androidx.compose.runtime.* // androidx.compose.runtime version: 1.4.3
import androidx.compose.ui.Modifier // androidx.compose.ui version: 1.4.3
import androidx.compose.ui.geometry.Offset // androidx.compose.ui version: 1.4.3
import androidx.compose.ui.geometry.Size // androidx.compose.ui version: 1.4.3
import androidx.compose.ui.graphics.* // androidx.compose.ui version: 1.4.3
import androidx.compose.ui.unit.dp // androidx.compose.ui version: 1.4.3
import kotlin.math.* // kotlin.math version: 1.8.0
import com.amirawellness.core.constants.AppConstants

// Default values for waveform visualization
private val DEFAULT_WAVEFORM_HEIGHT = 120.dp
private val DEFAULT_WAVEFORM_BAR_WIDTH = 4.dp
private val DEFAULT_WAVEFORM_BAR_SPACING = 2.dp
private const val DEFAULT_WAVEFORM_BARS = 60
private const val MAX_AMPLITUDE = 32767  // Maximum amplitude for 16-bit PCM audio

/**
 * Displays a static waveform visualization based on a list of amplitude values.
 *
 * @param amplitudes List of amplitude values between 0.0 and 1.0
 * @param modifier Modifier for styling and layout
 * @param color Color of the waveform bars
 * @param barCount Number of bars to display in the waveform
 */
@Composable
fun WaveformAnimation(
    amplitudes: List<Float>,
    modifier: Modifier = Modifier,
    color: Color = Color.Blue,
    barCount: Int = DEFAULT_WAVEFORM_BARS
) {
    Canvas(
        modifier = modifier
            .height(DEFAULT_WAVEFORM_HEIGHT)
            .fillMaxWidth()
    ) {
        if (amplitudes.isEmpty()) return@Canvas

        val effectiveBarCount = min(barCount, amplitudes.size)
        val barWidth = DEFAULT_WAVEFORM_BAR_WIDTH.toPx()
        val spacing = DEFAULT_WAVEFORM_BAR_SPACING.toPx()
        val totalBarWidth = effectiveBarCount * (barWidth + spacing)
        val startX = (size.width - totalBarWidth) / 2

        for (i in 0 until effectiveBarCount) {
            val amplitude = amplitudes[i % amplitudes.size]
            val barHeight = amplitude * size.height * 0.8f // 80% of canvas height max
            val x = startX + i * (barWidth + spacing)
            val y = (size.height - barHeight) / 2

            drawRect(
                color = color,
                topLeft = Offset(x, y),
                size = Size(barWidth, barHeight)
            )
        }
    }
}

/**
 * Displays a real-time animated waveform visualization based on current audio amplitude.
 * This visualization responds to audio input and provides visual feedback during recording.
 *
 * @param currentAmplitude Current audio amplitude value (raw)
 * @param modifier Modifier for styling and layout
 * @param color Color of the waveform bars
 * @param barCount Number of bars to display in the waveform
 */
@Composable
fun LiveWaveformAnimation(
    currentAmplitude: Int,
    modifier: Modifier = Modifier,
    color: Color = Color.Blue,
    barCount: Int = DEFAULT_WAVEFORM_BARS
) {
    // Keep track of the last N amplitude values
    val amplitudeList = remember { mutableStateListOf<Float>() }
    
    // Normalize the current amplitude and add it to the list
    LaunchedEffect(currentAmplitude) {
        val normalizedAmplitude = normalizeAmplitude(currentAmplitude)
        if (amplitudeList.size >= barCount) {
            amplitudeList.removeAt(0)
        }
        amplitudeList.add(normalizedAmplitude)
    }
    
    // Fill with placeholder values if we don't have enough data yet
    if (amplitudeList.size < barCount) {
        val initialValues = generateRandomWaveform(barCount - amplitudeList.size)
        LaunchedEffect(Unit) {
            amplitudeList.addAll(initialValues)
        }
    }
    
    // Create animated values for each bar
    val animatedValues = amplitudeList.mapIndexed { index, amplitude ->
        val animatedValue = remember { Animatable(0f) }
        LaunchedEffect(key1 = amplitude) {
            animatedValue.animateTo(
                targetValue = amplitude,
                animationSpec = tween(
                    durationMillis = 300,
                    easing = FastOutSlowInEasing
                )
            )
        }
        animatedValue.value
    }

    // Time-based animation for wave-like effect
    val infiniteTransition = rememberInfiniteTransition()
    val phase = infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 2 * PI.toFloat(),
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        )
    )
    
    Canvas(
        modifier = modifier
            .height(DEFAULT_WAVEFORM_HEIGHT)
            .fillMaxWidth()
    ) {
        val barWidth = DEFAULT_WAVEFORM_BAR_WIDTH.toPx()
        val spacing = DEFAULT_WAVEFORM_BAR_SPACING.toPx()
        val totalBarWidth = animatedValues.size * (barWidth + spacing)
        val startX = (size.width - totalBarWidth) / 2
        
        for (i in animatedValues.indices) {
            val amplitude = animatedValues[i]
            
            // Add a subtle wave-like motion for more natural appearance
            val waveOffset = sin((phase.value + i * 0.2f).toDouble()).toFloat() * 5f
            val adjustedAmplitude = (amplitude * 0.8f) + (waveOffset / size.height)
            
            val barHeight = adjustedAmplitude * size.height * 0.8f
            val x = startX + i * (barWidth + spacing)
            val y = (size.height - barHeight) / 2
            
            // Create a gradient effect
            val brush = Brush.verticalGradient(
                colors = listOf(
                    color.copy(alpha = 0.7f),
                    color
                )
            )
            
            drawRect(
                brush = brush,
                topLeft = Offset(x, y),
                size = Size(barWidth, barHeight)
            )
        }
    }
}

/**
 * Normalizes an amplitude value to a range of 0.0 to 1.0 with some minimal
 * value to ensure visibility of low amplitudes.
 *
 * @param amplitude Raw amplitude value
 * @return Normalized amplitude value between 0.0 and 1.0
 */
private fun normalizeAmplitude(amplitude: Int): Float {
    // Ensure positive value
    val absAmplitude = abs(amplitude)
    
    // Normalize to range 0.0 - 1.0
    val normalized = absAmplitude.toFloat() / MAX_AMPLITUDE
    
    // Apply minimum threshold for visibility
    val minThreshold = 0.05f
    
    // Apply non-linear scaling for better visual appearance
    val scaled = sqrt(max(normalized, minThreshold))
    
    // Ensure the value is between 0.0 and 1.0
    return scaled.coerceIn(0f, 1f)
}

/**
 * Generates a random waveform pattern for preview or placeholder purposes.
 *
 * @param barCount Number of bars to generate
 * @return List of random amplitude values between 0.1 and 1.0
 */
private fun generateRandomWaveform(barCount: Int): List<Float> {
    val result = mutableListOf<Float>()
    val smoothingFactor = 0.3f
    var lastValue = 0.5f
    
    for (i in 0 until barCount) {
        val randomValue = 0.1f + Math.random().toFloat() * 0.9f
        // Apply smoothing to make transitions between bars more natural
        val smoothedValue = lastValue + (randomValue - lastValue) * smoothingFactor
        result.add(smoothedValue)
        lastValue = smoothedValue
    }
    
    return result
}