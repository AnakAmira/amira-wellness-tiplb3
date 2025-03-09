package com.amirawellness.ui.components.buttons

import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.material.Button // version: 1.5.0
import androidx.compose.material.ButtonDefaults // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.layout.height // version: 1.5.0
import androidx.compose.foundation.layout.Box // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.compose.ui.platform.LocalContext // version: 1.5.0
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.hapticfeedback.LocalHapticFeedback
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.PrimaryDark
import com.amirawellness.ui.theme.TextOnPrimary
import com.amirawellness.ui.theme.ButtonShape
import com.amirawellness.core.extensions.clickableWithRipple
import com.amirawellness.ui.components.loading.LoadingIndicator

/**
 * A composable function that renders a primary button with the application's brand styling.
 * This button is used for primary actions and call-to-actions throughout the app.
 *
 * @param text The text to display on the button
 * @param onClick Action to perform when the button is clicked
 * @param modifier Additional modifiers to apply to the button
 * @param enabled Whether the button is enabled
 * @param isLoading Whether to show a loading indicator instead of text
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false
) {
    val context = LocalContext.current
    
    // Configure button colors using ButtonDefaults with Primary for background and TextOnPrimary for content
    val buttonColors = ButtonDefaults.buttonColors(
        backgroundColor = Primary,
        contentColor = TextOnPrimary,
        disabledBackgroundColor = Primary.copy(alpha = 0.5f),
        disabledContentColor = TextOnPrimary.copy(alpha = 0.5f)
    )
    
    Button(
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
        colors = buttonColors,
        elevation = ButtonDefaults.elevation(
            defaultElevation = 0.dp,
            pressedElevation = 4.dp,
            disabledElevation = 0.dp
        )
    ) {
        Box(
            contentAlignment = Alignment.Center
        ) {
            if (isLoading) {
                // Show loading indicator when in loading state
                LoadingIndicator(
                    color = TextOnPrimary,
                    size = 24f,
                    strokeWidth = 2f
                )
            } else {
                Text(
                    text = text,
                    style = MaterialTheme.typography.button
                )
            }
        }
    }
}