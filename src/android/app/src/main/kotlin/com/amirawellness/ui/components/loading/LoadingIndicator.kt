package com.amirawellness.ui.components.loading

import androidx.compose.foundation.layout.*
import androidx.compose.material.CircularProgressIndicator
import androidx.compose.material.LinearProgressIndicator
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.animation.core.*
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.PrimaryVariant
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.components.animations.LoadingAnimation
import com.amirawellness.core.constants.AppConstants

/**
 * Default size for loading indicators
 */
private val DEFAULT_INDICATOR_SIZE = 48.dp

/**
 * Default stroke width for circular indicators
 */
private val DEFAULT_INDICATOR_STROKE_WIDTH = 4.dp

/**
 * Default animation duration for loading indicator animations
 */
private val DEFAULT_ANIMATION_DURATION = AppConstants.UI_SETTINGS.ANIMATION_DURATION_MS.toInt()

/**
 * A composable function that displays a circular loading indicator with optional text
 *
 * @param modifier Modifier for customizing the indicator container
 * @param color The color of the loading indicator, defaults to the primary theme color
 * @param size The size of the indicator in dp, defaults to [DEFAULT_INDICATOR_SIZE]
 * @param strokeWidth The width of the indicator's stroke in dp, defaults to [DEFAULT_INDICATOR_STROKE_WIDTH]
 * @param text Optional text to display below the indicator
 */
@Composable
fun LoadingIndicator(
    modifier: Modifier = Modifier,
    color: Color? = null,
    size: Float = DEFAULT_INDICATOR_SIZE.value,
    strokeWidth: Float = DEFAULT_INDICATOR_STROKE_WIDTH.value,
    text: String? = null
) {
    val indicatorColor = color ?: Primary
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        CircularProgressIndicator(
            modifier = Modifier
                .size(size.dp)
                .semantics { contentDescription = "Loading" },
            color = indicatorColor,
            strokeWidth = strokeWidth.dp
        )
        
        text?.let {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = it,
                style = MaterialTheme.typography.body2,
                textAlign = TextAlign.Center,
                color = TextPrimary
            )
        }
    }
}

/**
 * A composable function that displays a pulsating circular loading indicator
 *
 * @param modifier Modifier for customizing the indicator container
 * @param color The color of the loading indicator, defaults to the primary theme color
 * @param size The base size of the indicator in dp, defaults to [DEFAULT_INDICATOR_SIZE]
 * @param strokeWidth The width of the indicator's stroke in dp, defaults to [DEFAULT_INDICATOR_STROKE_WIDTH]
 * @param pulseDuration The duration of one pulse cycle in milliseconds
 */
@Composable
fun PulsatingLoadingIndicator(
    modifier: Modifier = Modifier,
    color: Color? = null,
    size: Float = DEFAULT_INDICATOR_SIZE.value,
    strokeWidth: Float = DEFAULT_INDICATOR_STROKE_WIDTH.value,
    pulseDuration: Int = DEFAULT_ANIMATION_DURATION
) {
    val indicatorColor = color ?: Primary
    
    // Create infinite transition for animation
    val infiniteTransition = rememberInfiniteTransition()
    
    // Size animation
    val sizeAnimation = infiniteTransition.animateFloat(
        initialValue = size * 0.8f,
        targetValue = size * 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = pulseDuration,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        )
    )
    
    // Alpha animation
    val alphaAnimation = infiniteTransition.animateFloat(
        initialValue = L0.6f,
        targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = pulseDuration,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        )
    )
    
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(
            modifier = Modifier
                .size(sizeAnimation.value.dp)
                .alpha(alphaAnimation.value)
                .semantics { contentDescription = "Loading" },
            color = indicatorColor,
            strokeWidth = strokeWidth.dp
        )
    }
}

/**
 * A composable function that displays a circular progress indicator with a specific progress value
 *
 * @param progress The progress value between 0.0 and 1.0
 * @param modifier Modifier for customizing the indicator container
 * @param color The color of the loading indicator, defaults to the primary theme color
 * @param trackColor The color of the track (background), defaults to a semi-transparent version of the indicator color
 * @param size The size of the indicator in dp, defaults to [DEFAULT_INDICATOR_SIZE]
 * @param strokeWidth The width of the indicator's stroke in dp, defaults to [DEFAULT_INDICATOR_STROKE_WIDTH]
 * @param text Optional text to display below the indicator, if null and progress is valid, it will show the percentage
 */
@Composable
fun DeterminateLoadingIndicator(
    progress: Float,
    modifier: Modifier = Modifier,
    color: Color? = null,
    trackColor: Color? = null,
    size: Float = DEFAULT_INDICATOR_SIZE.value,
    strokeWidth: Float = DEFAULT_INDICATOR_STROKE_WIDTH.value,
    text: String? = null
) {
    // Validate progress to ensure it's between 0.0 and 1.0
    val validProgress = progress.coerceIn(0f, 1f)
    val indicatorColor = color ?: Primary
    val indicatorTrackColor = trackColor ?: indicatorColor.copy(alpha = 0.2f)
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        CircularProgressIndicator(
            progress = validProgress,
            modifier = Modifier
                .size(size.dp)
                .semantics { 
                    contentDescription = "Loading ${(validProgress * 100).toInt()}%" 
                },
            color = indicatorColor,
            strokeWidth = strokeWidth.dp,
            backgroundColor = indicatorTrackColor
        )
        
        if (text != null || progress in 0f..1f) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = text ?: "${(validProgress * 100).toInt()}%",
                style = MaterialTheme.typography.body2,
                textAlign = TextAlign.Center,
                color = TextPrimary
            )
        }
    }
}

/**
 * A composable function that displays a linear loading indicator
 *
 * @param modifier Modifier for customizing the indicator container
 * @param color The color of the loading indicator, defaults to the primary theme color
 * @param trackColor The color of the track (background), defaults to a semi-transparent version of the indicator color
 * @param progress Optional progress value between 0.0 and 1.0, if null an indeterminate indicator is shown
 * @param text Optional text to display below the indicator
 */
@Composable
fun LinearLoadingIndicator(
    modifier: Modifier = Modifier,
    color: Color? = null,
    trackColor: Color? = null,
    progress: Float? = null,
    text: String? = null
) {
    val indicatorColor = color ?: Primary
    val indicatorTrackColor = trackColor ?: indicatorColor.copy(alpha = 0.2f)
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        if (progress == null) {
            // Indeterminate linear indicator
            LinearProgressIndicator(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .semantics { contentDescription = "Loading" },
                color = indicatorColor,
                backgroundColor = indicatorTrackColor
            )
        } else {
            // Determinate linear indicator with progress
            val validProgress = progress.coerceIn(0f, 1f)
            LinearProgressIndicator(
                progress = validProgress,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .semantics { 
                        contentDescription = "Loading ${(validProgress * 100).toInt()}%" 
                    },
                color = indicatorColor,
                backgroundColor = indicatorTrackColor
            )
        }
        
        text?.let {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = it,
                style = MaterialTheme.typography.body2,
                textAlign = TextAlign.Center,
                color = TextPrimary
            )
        }
    }
}

/**
 * A composable function that displays a Lottie animation as a loading indicator
 *
 * @param modifier Modifier for customizing the animation container
 * @param text Optional text to display below the animation
 */
@Composable
fun LottieLoadingIndicator(
    modifier: Modifier = Modifier,
    text: String? = null
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        LoadingAnimation(
            modifier = Modifier.semantics { contentDescription = "Loading" }
        )
        
        text?.let {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = it,
                style = MaterialTheme.typography.body2,
                textAlign = TextAlign.Center,
                color = TextPrimary
            )
        }
    }
}

/**
 * A composable function that displays a full-screen loading overlay
 *
 * @param isLoading Boolean to control the visibility of the loading overlay
 * @param text Optional text to display with the loading indicator
 * @param useLottie Whether to use the Lottie animation or the standard circular indicator
 * @param backgroundColor Background color for the loading overlay, defaults to semi-transparent surface color
 * @param content The content to display beneath the loading overlay
 */
@Composable
fun FullScreenLoading(
    isLoading: Boolean,
    text: String? = null,
    useLottie: Boolean = false,
    backgroundColor: Color? = null,
    content: @Composable () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        // Main content
        content()
        
        // Loading overlay
        if (isLoading) {
            Surface(
                color = backgroundColor ?: MaterialTheme.colors.surface.copy(alpha = 0.8f),
                modifier = Modifier.fillMaxSize()
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    if (useLottie) {
                        LottieLoadingIndicator(text = text)
                    } else {
                        LoadingIndicator(text = text)
                    }
                }
            }
        }
    }
}