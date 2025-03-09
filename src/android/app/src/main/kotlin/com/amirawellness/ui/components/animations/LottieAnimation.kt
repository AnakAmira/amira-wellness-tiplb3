package com.amirawellness.ui.components.animations

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.LottieConstants
import com.airbnb.lottie.compose.animateLottieCompositionAsState
import com.airbnb.lottie.compose.rememberLottieComposition
import com.amirawellness.core.constants.AppConstants

/**
 * Default size for animations in density-independent pixels
 */
private val DEFAULT_ANIMATION_SIZE = 120.dp

/**
 * Default animation playback speed
 */
private const val DEFAULT_ANIMATION_SPEED = 1.0f

/**
 * Default number of animation iterations (loop forever)
 */
private const val DEFAULT_ANIMATION_ITERATIONS = LottieConstants.IterateForever

/**
 * Base composable function that displays a Lottie animation from a raw resource
 *
 * @param resId The resource ID of the Lottie animation
 * @param modifier Modifier for customizing the animation container
 * @param speed Animation playback speed multiplier
 * @param iterations Number of times to play the animation (use LottieConstants.IterateForever to loop)
 * @param isPlaying Whether the animation should be playing
 * @param restartOnPlay Whether to restart the animation when isPlaying changes from false to true
 * @param onAnimationEnd Callback invoked when the animation completes (only for finite iterations)
 */
@Composable
fun LottieAnimation(
    resId: Int,
    modifier: Modifier = Modifier,
    speed: Float = DEFAULT_ANIMATION_SPEED,
    iterations: Int = DEFAULT_ANIMATION_ITERATIONS,
    isPlaying: Boolean = true,
    restartOnPlay: Boolean = true,
    onAnimationEnd: (() -> Unit)? = null
) {
    // Load the Lottie composition from the resource
    val composition by rememberLottieComposition(
        spec = LottieCompositionSpec.RawRes(resId)
    )
    
    // Track if we need to restart the animation
    var shouldRestart by remember { mutableStateOf(false) }
    
    // Update restart state when isPlaying changes
    LaunchedEffect(isPlaying) {
        if (isPlaying && restartOnPlay) {
            shouldRestart = true
        }
    }
    
    // Animation progress state
    val progress by animateLottieCompositionAsState(
        composition = composition,
        iterations = iterations,
        isPlaying = isPlaying,
        speed = speed,
        restartOnPlay = restartOnPlay
    )
    
    // Check for animation completion for finite iterations
    if (iterations != LottieConstants.IterateForever && progress >= 1f && onAnimationEnd != null) {
        LaunchedEffect(progress) {
            onAnimationEnd()
        }
    }
    
    // Handle restarting animation if needed
    if (shouldRestart) {
        LaunchedEffect(Unit) {
            shouldRestart = false
        }
    }
    
    // Display the animation
    LottieAnimation(
        composition = composition,
        progress = { progress },
        modifier = modifier
    )
}

/**
 * Composable function that displays a loading animation using Lottie
 *
 * @param modifier Modifier for customizing the animation container
 * @param size Size of the animation in dp
 * @param speed Animation playback speed multiplier
 */
@Composable
fun LoadingAnimation(
    modifier: Modifier = Modifier,
    size: Float = DEFAULT_ANIMATION_SIZE.value,
    speed: Float = DEFAULT_ANIMATION_SPEED
) {
    // R.raw.loading_animation is assumed to exist in the resources
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        LottieAnimation(
            resId = android.R.drawable.ic_popup_sync, // Placeholder - replace with actual resource ID
            modifier = Modifier
                .size(size.dp)
                .semantics { contentDescription = "Loading" },
            speed = speed,
            iterations = LottieConstants.IterateForever
        )
    }
}

/**
 * Composable function that displays a success animation using Lottie
 *
 * @param modifier Modifier for customizing the animation container
 * @param size Size of the animation in dp
 * @param speed Animation playback speed multiplier
 * @param onAnimationEnd Callback invoked when the animation completes
 */
@Composable
fun SuccessAnimation(
    modifier: Modifier = Modifier,
    size: Float = DEFAULT_ANIMATION_SIZE.value,
    speed: Float = DEFAULT_ANIMATION_SPEED,
    onAnimationEnd: () -> Unit = {}
) {
    // R.raw.success_animation is assumed to exist in the resources
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        LottieAnimation(
            resId = android.R.drawable.ic_dialog_info, // Placeholder - replace with actual resource ID
            modifier = Modifier
                .size(size.dp)
                .semantics { contentDescription = "Success" },
            speed = speed,
            iterations = 1,
            onAnimationEnd = onAnimationEnd
        )
    }
}

/**
 * Composable function that displays an error animation using Lottie
 *
 * @param modifier Modifier for customizing the animation container
 * @param size Size of the animation in dp
 * @param speed Animation playback speed multiplier
 * @param onAnimationEnd Callback invoked when the animation completes
 */
@Composable
fun ErrorAnimation(
    modifier: Modifier = Modifier,
    size: Float = DEFAULT_ANIMATION_SIZE.value,
    speed: Float = DEFAULT_ANIMATION_SPEED,
    onAnimationEnd: () -> Unit = {}
) {
    // R.raw.error_animation is assumed to exist in the resources
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        LottieAnimation(
            resId = android.R.drawable.ic_dialog_alert, // Placeholder - replace with actual resource ID
            modifier = Modifier
                .size(size.dp)
                .semantics { contentDescription = "Error" },
            speed = speed,
            iterations = 1,
            onAnimationEnd = onAnimationEnd
        )
    }
}

/**
 * Composable function that displays a custom Lottie animation from a specified resource
 *
 * @param resId The resource ID of the Lottie animation
 * @param modifier Modifier for customizing the animation container
 * @param size Size of the animation in dp
 * @param speed Animation playback speed multiplier
 * @param iterations Number of times to play the animation (use LottieConstants.IterateForever to loop)
 * @param isPlaying Whether the animation should be playing
 * @param onAnimationEnd Callback invoked when the animation completes (only for finite iterations)
 */
@Composable
fun CustomLottieAnimation(
    resId: Int,
    modifier: Modifier = Modifier,
    size: Float = DEFAULT_ANIMATION_SIZE.value,
    speed: Float = DEFAULT_ANIMATION_SPEED,
    iterations: Int = DEFAULT_ANIMATION_ITERATIONS,
    isPlaying: Boolean = true,
    onAnimationEnd: () -> Unit = {}
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        LottieAnimation(
            resId = resId,
            modifier = Modifier
                .size(size.dp)
                .semantics { contentDescription = "Custom animation" },
            speed = speed,
            iterations = iterations,
            isPlaying = isPlaying,
            onAnimationEnd = if (iterations != LottieConstants.IterateForever) onAnimationEnd else null
        )
    }
}