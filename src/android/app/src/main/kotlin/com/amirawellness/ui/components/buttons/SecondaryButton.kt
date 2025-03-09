package com.amirawellness.ui.components.buttons

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material.ButtonDefaults
import androidx.compose.material.MaterialTheme
import androidx.compose.material.OutlinedButton
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.SecondaryDark
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.ButtonShape
import com.amirawellness.core.extensions.clickableWithRipple
import com.amirawellness.ui.components.loading.SmallLoadingIndicator

/**
 * A composable function that renders a secondary button with the application's brand styling.
 * This button is used for secondary actions and alternative options throughout the app.
 *
 * @param text The text to display on the button
 * @param onClick Function to execute when the button is clicked
 * @param modifier Additional modifiers to apply to the button
 * @param enabled Whether the button is enabled and clickable
 * @param isLoading Whether to show a loading indicator instead of text
 */
@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false
) {
    val context = LocalContext.current
    
    // Configure button colors with Surface for background and Secondary for content
    val colors = ButtonDefaults.outlinedButtonColors(
        backgroundColor = Surface,
        contentColor = Secondary,
        disabledContentColor = Secondary.copy(alpha = 0.5f)
    )
    
    // Create outlined button with Secondary color border
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .height(56.dp)
            .fillMaxWidth()
            .clickableWithRipple(
                onClick = onClick,
                enabled = enabled && !isLoading
            ),
        enabled = enabled && !isLoading,
        shape = ButtonShape,
        colors = colors,
        border = ButtonDefaults.outlinedBorder.copy(
            color = if (enabled) Secondary else Secondary.copy(alpha = 0.5f)
        )
    ) {
        // Show loading indicator or text based on isLoading state
        Box(
            contentAlignment = Alignment.Center
        ) {
            if (isLoading) {
                SmallLoadingIndicator(color = Secondary)
            } else {
                Text(
                    text = text,
                    style = MaterialTheme.typography.button
                )
            }
        }
    }
}