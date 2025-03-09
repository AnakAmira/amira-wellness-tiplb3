package com.amirawellness.ui.components.buttons

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.graphics.vector.ImageVector // version: 1.5.0
import androidx.compose.ui.graphics.Color // version: 1.5.0
import androidx.compose.ui.graphics.ColorFilter // version: 1.5.0
import androidx.compose.ui.graphics.tint // version: 1.5.0
import androidx.compose.foundation.layout.Box // version: 1.5.0
import androidx.compose.foundation.layout.size // version: 1.5.0
import androidx.compose.foundation.layout.padding // version: 1.5.0
import androidx.compose.foundation.background // version: 1.5.0
import androidx.compose.ui.draw.clip // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.compose.ui.platform.LocalContext // version: 1.5.0

import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.PrimaryDark
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextOnPrimary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.ButtonShape
import com.amirawellness.core.extensions.clickableWithRipple

/**
 * A composable function that renders an icon button with the application's brand styling.
 * This button is used for compact actions throughout the app.
 *
 * @param icon The icon to display in the button
 * @param onClick The action to perform when the button is clicked
 * @param modifier Additional modifiers to apply to the button
 * @param tint The tint color to apply to the icon (defaults to TextPrimary)
 * @param backgroundColor The background color for the button (defaults to transparent)
 * @param enabled Whether the button is enabled and can be clicked
 * @param size The size of the button in dp (defaults to 48dp)
 * @param contentPadding The padding around the icon in dp (defaults to 12dp)
 */
@Composable
fun IconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    tint: Color = TextPrimary,
    backgroundColor: Color = Color.Transparent,
    enabled: Boolean = true,
    size: Int = 48,
    contentPadding: Int = 12
) {
    // Context for haptic feedback and accessibility services
    val context = LocalContext.current
    
    // Calculate the final tint based on parameters and enabled state
    val finalTint = if (enabled) tint else tint.copy(alpha = 0.5f)
    
    Box(
        modifier = Modifier
            .size(size.dp)
            .run {
                if (backgroundColor != Color.Transparent) {
                    clip(ButtonShape)
                        .background(backgroundColor)
                } else {
                    this
                }
            }
            .then(modifier)
            .clickableWithRipple(
                onClick = onClick,
                enabled = enabled
            )
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null, // Content description should be provided by parent component
            tint = finalTint,
            modifier = Modifier.padding(contentPadding.dp)
        )
    }
}

/**
 * A composable function that renders an icon button with primary color styling.
 * This is a convenience wrapper around IconButton for primary actions.
 *
 * @param icon The icon to display in the button
 * @param onClick The action to perform when the button is clicked
 * @param modifier Additional modifiers to apply to the button
 * @param enabled Whether the button is enabled and can be clicked
 * @param size The size of the button in dp (defaults to 48dp)
 * @param contentPadding The padding around the icon in dp (defaults to 12dp)
 */
@Composable
fun PrimaryIconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    size: Int = 48,
    contentPadding: Int = 12
) {
    IconButton(
        icon = icon,
        onClick = onClick,
        modifier = modifier,
        tint = Primary,
        backgroundColor = Color.Transparent,
        enabled = enabled,
        size = size,
        contentPadding = contentPadding
    )
}

/**
 * A composable function that renders an icon button with secondary color styling.
 * This is a convenience wrapper around IconButton for secondary actions.
 *
 * @param icon The icon to display in the button
 * @param onClick The action to perform when the button is clicked
 * @param modifier Additional modifiers to apply to the button
 * @param enabled Whether the button is enabled and can be clicked
 * @param size The size of the button in dp (defaults to 48dp)
 * @param contentPadding The padding around the icon in dp (defaults to 12dp)
 */
@Composable
fun SecondaryIconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    size: Int = 48,
    contentPadding: Int = 12
) {
    IconButton(
        icon = icon,
        onClick = onClick,
        modifier = modifier,
        tint = Secondary,
        backgroundColor = Color.Transparent,
        enabled = enabled,
        size = size,
        contentPadding = contentPadding
    )
}

/**
 * A composable function that renders an icon button with a filled background.
 * This variant provides more visual emphasis for important actions.
 *
 * @param icon The icon to display in the button
 * @param onClick The action to perform when the button is clicked
 * @param modifier Additional modifiers to apply to the button
 * @param tint The tint color to apply to the icon (defaults to TextOnPrimary)
 * @param backgroundColor The background color for the button (defaults to Primary)
 * @param enabled Whether the button is enabled and can be clicked
 * @param size The size of the button in dp (defaults to 48dp)
 * @param contentPadding The padding around the icon in dp (defaults to 12dp)
 */
@Composable
fun FilledIconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    tint: Color = TextOnPrimary,
    backgroundColor: Color = Primary,
    enabled: Boolean = true,
    size: Int = 48,
    contentPadding: Int = 12
) {
    IconButton(
        icon = icon,
        onClick = onClick,
        modifier = modifier,
        tint = tint,
        backgroundColor = backgroundColor,
        enabled = enabled,
        size = size,
        contentPadding = contentPadding
    )
}