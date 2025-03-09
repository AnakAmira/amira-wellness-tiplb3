package com.amirawellness.ui.components.loading

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.progressBarRangeInfo

import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.PrimaryVariant
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.core.extensions.roundedCorners

// Default values for progress bars
private const val DEFAULT_PROGRESS_BAR_HEIGHT = 8f
private const val DEFAULT_PROGRESS_BAR_CORNER_RADIUS = 4f
private const val DEFAULT_ANIMATION_DURATION_MS = AppConstants.UI_SETTINGS.ANIMATION_DURATION_MS

/**
 * A composable function that displays a horizontal progress bar with customizable appearance.
 * 
 * @param progress The current progress value between 0.0 and 1.0
 * @param modifier Modifier to be applied to the progress bar
 * @param backgroundColor Background color of the progress bar track, defaults to Surface color
 * @param progressColor Color of the progress indicator, defaults to Primary color
 * @param height Height of the progress bar in dp, defaults to 8dp
 * @param showPercentage Whether to show the percentage text above the progress bar
 * @param animated Whether the progress changes should be animated
 */
@Composable
fun ProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    backgroundColor: Color? = null,
    progressColor: Color? = null,
    height: Float = DEFAULT_PROGRESS_BAR_HEIGHT,
    showPercentage: Boolean = false,
    animated: Boolean = true
) {
    // Validate progress is between 0.0 and 1.0
    val validatedProgress = progress.coerceIn(0f, 1f)
    
    // Use default colors if not provided
    val bgColor = backgroundColor ?: Surface
    val pgColor = progressColor ?: Primary
    
    // Create animated progress value if animation is enabled
    val animatedProgress = if (animated) {
        AnimatedProgressValue(targetValue = validatedProgress)
    } else {
        validatedProgress
    }
    
    // Create progress bar layout
    Box(
        modifier = modifier
            .height(height.dp)
            .fillMaxWidth()
            .semantics {
                progressBarRangeInfo = ProgressBarRangeInfo(
                    current = animatedProgress,
                    range = 0f..1f,
                    steps = 0
                )
            }
    ) {
        // Background track
        Box(
            modifier = Modifier
                .fillMaxSize()
                .roundedCorners(DEFAULT_PROGRESS_BAR_CORNER_RADIUS.toInt())
                .background(bgColor)
        )
        
        // Progress indicator
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .fillMaxWidth(animatedProgress)
                .roundedCorners(DEFAULT_PROGRESS_BAR_CORNER_RADIUS.toInt())
                .background(pgColor)
        )
        
        // Percentage text if enabled
        if (showPercentage) {
            Text(
                text = "${(animatedProgress * 100).toInt()}%",
                color = TextPrimary,
                style = MaterialTheme.typography.caption,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .align(Alignment.Center)
            )
        }
    }
}

/**
 * A composable function that displays an indeterminate horizontal progress bar
 * for situations when the progress cannot be determined.
 * 
 * @param modifier Modifier to be applied to the progress bar
 * @param backgroundColor Background color of the progress bar track, defaults to Surface color
 * @param progressColor Color of the progress indicator, defaults to Primary color
 * @param height Height of the progress bar in dp, defaults to 8dp
 */
@Composable
fun IndeterminateProgressBar(
    modifier: Modifier = Modifier,
    backgroundColor: Color? = null,
    progressColor: Color? = null,
    height: Float = DEFAULT_PROGRESS_BAR_HEIGHT
) {
    // Use default colors if not provided
    val bgColor = backgroundColor ?: Surface
    val pgColor = progressColor ?: Primary
    
    // Create progress bar layout
    Box(
        modifier = modifier
            .height(height.dp)
            .fillMaxWidth()
            .semantics {
                progressBarRangeInfo = ProgressBarRangeInfo.Indeterminate
            }
    ) {
        // Background track
        Box(
            modifier = Modifier
                .fillMaxSize()
                .roundedCorners(DEFAULT_PROGRESS_BAR_CORNER_RADIUS.toInt())
                .background(bgColor)
        )
        
        // With limited animation capabilities, we'll use a partial fill
        // to indicate an indeterminate state
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .fillMaxWidth(0.3f)
                .roundedCorners(DEFAULT_PROGRESS_BAR_CORNER_RADIUS.toInt())
                .background(pgColor)
        )
    }
}

/**
 * A composable function that displays a circular progress indicator with customizable appearance.
 * 
 * @param progress The current progress value between 0.0 and 1.0
 * @param modifier Modifier to be applied to the progress bar
 * @param backgroundColor Background color of the progress track, defaults to Surface color
 * @param progressColor Color of the progress indicator, defaults to Primary color
 * @param size Size of the circular progress indicator in dp, defaults to 48dp
 * @param strokeWidth Width of the progress track in dp, defaults to 4dp
 * @param showPercentage Whether to show the percentage text inside the circle
 * @param animated Whether the progress changes should be animated
 */
@Composable
fun CircularProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    backgroundColor: Color? = null,
    progressColor: Color? = null,
    size: Float = 48f,
    strokeWidth: Float = 4f,
    showPercentage: Boolean = false,
    animated: Boolean = true
) {
    // Validate progress is between 0.0 and 1.0
    val validatedProgress = progress.coerceIn(0f, 1f)
    
    // Use default colors if not provided
    val bgColor = backgroundColor ?: Surface
    val pgColor = progressColor ?: Primary
    
    // Create animated progress value if animation is enabled
    val animatedProgress = if (animated) {
        AnimatedProgressValue(targetValue = validatedProgress)
    } else {
        validatedProgress
    }
    
    // Create a simplified circular progress indicator
    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .size(size.dp)
            .semantics {
                progressBarRangeInfo = ProgressBarRangeInfo(
                    current = animatedProgress,
                    range = 0f..1f,
                    steps = 0
                )
            }
    ) {
        // Square container with rounded corners as a placeholder for a circular indicator
        Box(
            modifier = Modifier
                .fillMaxSize()
                .roundedCorners((size / 2).toInt())
                .background(bgColor)
        )
        
        // Inner circle showing progress (using a padding trick)
        Box(
            modifier = Modifier
                .size((size * animatedProgress).dp)
                .roundedCorners((size * animatedProgress / 2).toInt())
                .background(pgColor)
        )
        
        // Percentage text if enabled
        if (showPercentage) {
            Text(
                text = "${(animatedProgress * 100).toInt()}%",
                color = TextPrimary,
                style = MaterialTheme.typography.caption,
                textAlign = TextAlign.Center
            )
        }
    }
}

/**
 * A composable function that displays a segmented progress bar for multi-step processes.
 * 
 * @param totalSteps Total number of steps in the process
 * @param currentStep Current active step (1-based index)
 * @param modifier Modifier to be applied to the progress bar
 * @param backgroundColor Background color for the progress bar, defaults to Surface color
 * @param completedColor Color for completed segments, defaults to Primary color
 * @param currentColor Color for the current segment, defaults to PrimaryVariant color
 * @param incompleteColor Color for incomplete segments, defaults to backgroundColor
 * @param height Height of the segments in dp, defaults to 8dp
 * @param spacing Spacing between segments in dp, defaults to 4dp
 */
@Composable
fun SegmentedProgressBar(
    totalSteps: Int,
    currentStep: Int,
    modifier: Modifier = Modifier,
    backgroundColor: Color? = null,
    completedColor: Color? = null,
    currentColor: Color? = null,
    incompleteColor: Color? = null,
    height: Float = DEFAULT_PROGRESS_BAR_HEIGHT,
    spacing: Float = 4f
) {
    // Validate currentStep is between 1 and totalSteps
    val validatedCurrentStep = currentStep.coerceIn(1, totalSteps)
    
    // Use default colors if not provided
    val bgColor = backgroundColor ?: Surface
    val cmpColor = completedColor ?: Primary
    val curColor = currentColor ?: PrimaryVariant
    val incColor = incompleteColor ?: bgColor
    
    // Create row to hold the segments
    Row(
        modifier = modifier
            .height(height.dp)
            .fillMaxWidth()
            .semantics {
                progressBarRangeInfo = ProgressBarRangeInfo(
                    current = validatedCurrentStep.toFloat(),
                    range = 1f..totalSteps.toFloat(),
                    steps = totalSteps
                )
            },
        horizontalArrangement = Arrangement.spacedBy(spacing.dp)
    ) {
        // Create a segment for each step
        for (step in 1..totalSteps) {
            val segmentColor = when {
                step < validatedCurrentStep -> cmpColor  // Completed
                step == validatedCurrentStep -> curColor // Current
                else -> incColor                        // Incomplete
            }
            
            // Individual segment
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .roundedCorners(DEFAULT_PROGRESS_BAR_CORNER_RADIUS.toInt())
                    .background(segmentColor)
            )
        }
    }
}

/**
 * A helper function that creates an animated float value for smooth progress transitions.
 * 
 * @param targetValue The target progress value to animate to
 * @param animationDurationMs Duration of the animation in milliseconds
 * @return Animated float value that smoothly transitions to the target value
 */
@Composable
private fun AnimatedProgressValue(
    targetValue: Float,
    animationDurationMs: Long = DEFAULT_ANIMATION_DURATION_MS
): Float {
    return animateFloatAsState(
        targetValue = targetValue,
        animationSpec = tween(
            durationMillis = animationDurationMs.toInt()
        )
    ).value
}