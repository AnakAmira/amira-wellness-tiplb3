package com.amirawellness.core.extensions

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.setValue // version: 1.5.0
import androidx.compose.runtime.mutableStateOf // version: 1.5.0
import androidx.compose.runtime.MutableState // version: 1.5.0
import androidx.compose.runtime.LaunchedEffect // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.draw.shadow // version: 1.5.0
import androidx.compose.ui.draw.clip // version: 1.5.0
import androidx.compose.ui.graphics.Color // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.compose.foundation.layout.padding // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxHeight // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxSize // version: 1.5.0
import androidx.compose.foundation.layout.size // version: 1.5.0
import androidx.compose.foundation.layout.height // version: 1.5.0
import androidx.compose.foundation.layout.width // version: 1.5.0
import androidx.compose.foundation.layout.aspectRatio // version: 1.5.0
import androidx.compose.foundation.clickable // version: 1.5.0
import androidx.compose.foundation.background // version: 1.5.0
import androidx.compose.foundation.border // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.material.Surface // version: 1.5.0
import androidx.compose.material.Card // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.material.ripple.rememberRipple // version: 1.5.0
import androidx.compose.ui.platform.LocalContext // version: 1.5.0
import androidx.compose.ui.platform.LocalDensity // version: 1.5.0
import androidx.compose.ui.hapticfeedback.HapticFeedbackType // version: 1.5.0
import androidx.compose.ui.hapticfeedback.LocalHapticFeedback // version: 1.5.0
import androidx.compose.ui.graphics.graphicsLayer // version: 1.5.0
import androidx.compose.foundation.interaction.MutableInteractionSource // version: 1.5.0
import androidx.compose.animation.core.Animatable // version: 1.5.0
import androidx.compose.animation.core.tween // version: 1.5.0
import androidx.compose.animation.core.InfiniteTransition // version: 1.5.0
import androidx.compose.animation.core.rememberInfiniteTransition // version: 1.5.0
import androidx.compose.animation.core.LinearEasing // version: 1.5.0
import androidx.compose.animation.core.infiniteRepeatable // version: 1.5.0
import androidx.compose.animation.core.RepeatMode // version: 1.5.0
import androidx.compose.animation.core.animateFloat // version: 1.5.0
import androidx.compose.foundation.shape.RoundedCornerShape // version: 1.5.0
import androidx.compose.ui.graphics.Brush // version: 1.5.0
import androidx.compose.ui.geometry.Offset // version: 1.5.0

import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.PrimaryDark
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.Error
import com.amirawellness.ui.theme.Success
import com.amirawellness.ui.theme.Warning
import com.amirawellness.ui.theme.Info
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.core.utils.PermissionUtils

private const val TAG = "ComposableExtensions"

/**
 * Creates a standard card modifier with consistent elevation, shape, and padding for card-like components
 *
 * @param elevation The elevation of the card in dp
 * @param cornerRadius The corner radius of the card in dp
 * @param padding The padding inside the card in dp
 * @return Modifier with standard card styling
 */
fun Modifier.cardModifier(
    elevation: Float = 4f,
    cornerRadius: Int = 8,
    padding: Int = 16
): Modifier = this
    .shadow(elevation.dp)
    .clip(RoundedCornerShape(cornerRadius.dp))
    .padding(padding.dp)

/**
 * Extends a Modifier to make a composable clickable with a ripple effect and optional haptic feedback
 *
 * @param onClick Function to execute when clicked
 * @param enabled Whether the component is enabled and clickable
 * @param hapticFeedback Whether to provide haptic feedback on click
 * @return Modifier with clickable behavior and ripple effect
 */
@Composable
fun Modifier.clickableWithRipple(
    onClick: () -> Unit,
    enabled: Boolean = true,
    hapticFeedback: Boolean = AppConstants.UI_SETTINGS.HAPTIC_FEEDBACK_ENABLED
): Modifier {
    val haptic = LocalHapticFeedback.current
    val interactionSource = remember { MutableInteractionSource() }
    
    return this.clickable(
        enabled = enabled,
        indication = rememberRipple(),
        interactionSource = interactionSource,
        onClick = {
            if (hapticFeedback) {
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
            }
            onClick()
        }
    )
}

/**
 * Conditionally applies a modifier based on a boolean condition
 *
 * @param condition The boolean condition to evaluate
 * @param modifier The modifier to apply if condition is true
 * @return The modifier if condition is true, otherwise an empty Modifier
 */
fun Modifier.conditionalModifier(condition: Boolean, modifier: Modifier): Modifier =
    if (condition) this.then(modifier) else this

/**
 * Makes a composable visible or gone based on a condition
 *
 * @param visible Whether the component should be visible
 * @return Modifier that controls visibility
 */
fun Modifier.visibleIf(visible: Boolean): Modifier =
    if (visible) this else this.size(0.dp)

/**
 * Applies a fade-in animation effect to a composable
 *
 * @param durationMillis Duration of the animation in milliseconds
 * @return Modifier with fade-in animation
 */
@Composable
fun Modifier.fadeInEffect(
    durationMillis: Int = AppConstants.UI_SETTINGS.ANIMATION_DURATION_MS.toInt()
): Modifier {
    val alpha = remember { Animatable(initialValue = 0f) }
    
    LaunchedEffect(key1 = Unit) {
        alpha.animateTo(
            targetValue = 1f,
            animationSpec = tween(durationMillis = durationMillis)
        )
    }
    
    return this.graphicsLayer(alpha = alpha.value)
}

/**
 * Applies a slide-in animation effect to a composable
 *
 * @param durationMillis Duration of the animation in milliseconds
 * @param direction Direction of the slide ("up", "down", "left", "right")
 * @return Modifier with slide-in animation
 */
@Composable
fun Modifier.slideInEffect(
    durationMillis: Int = AppConstants.UI_SETTINGS.ANIMATION_DURATION_MS.toInt(),
    direction: String = "up"
): Modifier {
    val alpha = remember { Animatable(initialValue = 0f) }
    val offsetX = remember { Animatable(initialValue = when(direction) {
        "left" -> -100f
        "right" -> 100f
        else -> 0f
    }) }
    val offsetY = remember { Animatable(initialValue = when(direction) {
        "up" -> 100f
        "down" -> -100f
        else -> 0f
    }) }
    
    LaunchedEffect(key1 = Unit) {
        alpha.animateTo(
            targetValue = 1f,
            animationSpec = tween(durationMillis = durationMillis)
        )
        offsetX.animateTo(
            targetValue = 0f,
            animationSpec = tween(durationMillis = durationMillis)
        )
        offsetY.animateTo(
            targetValue = 0f,
            animationSpec = tween(durationMillis = durationMillis)
        )
    }
    
    return this.graphicsLayer(
        alpha = alpha.value,
        translationX = offsetX.value,
        translationY = offsetY.value
    )
}

/**
 * Applies a shimmer loading effect to a composable for loading states
 *
 * @return Modifier with shimmer effect
 */
@Composable
fun Modifier.shimmerEffect(): Modifier {
    val transition = rememberInfiniteTransition()
    val translateAnim = transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 1200,
                easing = LinearEasing
            ),
            repeatMode = RepeatMode.Restart
        )
    )
    
    val shimmerColors = listOf(
        Color.LightGray.copy(alpha = 0.6f),
        Color.LightGray.copy(alpha = 0.2f),
        Color.LightGray.copy(alpha = 0.6f),
    )
    
    val brush = Brush.linearGradient(
        colors = shimmerColors,
        start = Offset.Zero,
        end = Offset(x = translateAnim.value, y = translateAnim.value)
    )
    
    return this.background(brush)
}

/**
 * Applies an error border to a composable for indicating validation errors
 *
 * @param isError Whether to show the error border
 * @param width Border width in dp
 * @return Modifier with error border if isError is true
 */
fun Modifier.errorBorder(isError: Boolean, width: Int = 1): Modifier =
    if (isError) this.border(width.dp, Error, RoundedCornerShape(8.dp))
    else this

/**
 * Applies a success border to a composable for indicating successful validation
 *
 * @param isSuccess Whether to show the success border
 * @param width Border width in dp
 * @return Modifier with success border if isSuccess is true
 */
fun Modifier.successBorder(isSuccess: Boolean, width: Int = 1): Modifier =
    if (isSuccess) this.border(width.dp, Success, RoundedCornerShape(8.dp))
    else this

/**
 * Makes a composable clickable without the ripple effect
 *
 * @param onClick Function to execute when clicked
 * @return Modifier with clickable behavior but no ripple
 */
fun Modifier.noRippleClickable(onClick: () -> Unit): Modifier = this.clickable(
    indication = null,
    interactionSource = remember { MutableInteractionSource() }
) {
    onClick()
}

/**
 * Makes a composable clickable with debounce to prevent rapid multiple clicks
 *
 * @param debounceTime Time in milliseconds to debounce clicks
 * @param onClick Function to execute when clicked
 * @return Modifier with debounced click behavior
 */
@Composable
fun Modifier.debounceClickable(
    debounceTime: Long = AppConstants.UI_SETTINGS.DEBOUNCE_DELAY_MS,
    onClick: () -> Unit
): Modifier {
    var lastClickTime by remember { mutableStateOf(0L) }
    
    return this.clickable {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastClickTime > debounceTime) {
            lastClickTime = currentTime
            onClick()
        }
    }
}

/**
 * Applies a background color to a composable based on a condition
 *
 * @param condition The boolean condition to evaluate
 * @param activeColor Color to use when condition is true
 * @param inactiveColor Color to use when condition is false
 * @return Modifier with conditional background color
 */
fun Modifier.conditionalBackground(
    condition: Boolean,
    activeColor: Color,
    inactiveColor: Color
): Modifier = this.background(if (condition) activeColor else inactiveColor)

/**
 * Applies rounded corners to a composable with a specified radius
 *
 * @param radius Corner radius in dp
 * @return Modifier with rounded corners
 */
fun Modifier.roundedCorners(radius: Int = 8): Modifier = this
    .clip(RoundedCornerShape(radius.dp))

/**
 * Forces a composable to maintain a specific aspect ratio
 *
 * @param ratio Width to height ratio
 * @return Modifier that maintains the specified aspect ratio
 */
fun Modifier.aspectRatio(ratio: Float): Modifier = this
    .aspectRatio(ratio)

/**
 * A composable function that displays an error message with standard styling
 *
 * @param text The error message to display
 * @param modifier Additional modifiers to apply
 */
@Composable
fun ErrorText(text: String, modifier: Modifier = Modifier) {
    if (text.isNotEmpty()) {
        Text(
            text = text,
            color = Error,
            style = MaterialTheme.typography.caption,
            modifier = modifier
        )
    }
}

/**
 * A composable function that displays a success message with standard styling
 *
 * @param text The success message to display
 * @param modifier Additional modifiers to apply
 */
@Composable
fun SuccessText(text: String, modifier: Modifier = Modifier) {
    if (text.isNotEmpty()) {
        Text(
            text = text,
            color = Success,
            style = MaterialTheme.typography.caption,
            modifier = modifier
        )
    }
}

/**
 * A composable function that displays an informational message with standard styling
 *
 * @param text The info message to display
 * @param modifier Additional modifiers to apply
 */
@Composable
fun InfoText(text: String, modifier: Modifier = Modifier) {
    if (text.isNotEmpty()) {
        Text(
            text = text,
            color = Info,
            style = MaterialTheme.typography.caption,
            modifier = modifier
        )
    }
}

/**
 * A composable function that displays a warning message with standard styling
 *
 * @param text The warning message to display
 * @param modifier Additional modifiers to apply
 */
@Composable
fun WarningText(text: String, modifier: Modifier = Modifier) {
    if (text.isNotEmpty()) {
        Text(
            text = text,
            color = Warning,
            style = MaterialTheme.typography.caption,
            modifier = modifier
        )
    }
}

/**
 * A composable function that wraps content in a standardized card with consistent styling
 *
 * @param modifier Additional modifiers to apply to the card
 * @param elevation Card elevation in dp
 * @param onClick Optional click handler for the card
 * @param enabled Whether the card is enabled for interaction
 * @param content Content to display inside the card
 */
@Composable
fun StandardCard(
    modifier: Modifier = Modifier,
    elevation: Float = 4f,
    onClick: (() -> Unit)? = null,
    enabled: Boolean = true,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier.let {
            if (onClick != null) {
                it.clickableWithRipple(onClick = onClick, enabled = enabled)
            } else {
                it
            }
        },
        elevation = elevation.dp,
        shape = MaterialTheme.shapes.medium,
        content = content
    )
}

/**
 * A convenience function that combines remember and mutableStateOf
 *
 * @param initialValue Initial value for the state
 * @return A remembered mutable state with the initial value
 */
@Composable
fun <T> rememberMutableStateOf(initialValue: T): MutableState<T> =
    remember { mutableStateOf(initialValue) }