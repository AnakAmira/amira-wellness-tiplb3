package com.amirawellness.ui.components.dialogs

import androidx.compose.foundation.layout.*
import androidx.compose.material.AlertDialog
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.animations.ErrorAnimation
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Error

/**
 * Default animation size used across error dialogs
 */
private val DEFAULT_ANIMATION_SIZE = 120.dp

/**
 * Default padding used for spacing elements in dialogs
 */
private val DEFAULT_PADDING = 16.dp

/**
 * A composable function that displays an error dialog with an animation, title, message, and action button.
 * This dialog follows the minimalist, nature-inspired design of the Amira Wellness application.
 *
 * @param title The title text to display at the top of the dialog
 * @param message The message text to display in the dialog body
 * @param buttonText The text to display on the action button
 * @param onDismiss The callback to invoke when the dialog is dismissed
 * @param showDialog Boolean flag to control dialog visibility
 */
@Composable
fun ErrorDialog(
    title: String,
    message: String,
    buttonText: String,
    onDismiss: () -> Unit,
    showDialog: Boolean
) {
    if (!showDialog) return
    
    AlertDialog(
        onDismissRequest = onDismiss,
        backgroundColor = Surface,
        shape = MaterialTheme.shapes.medium,
        title = null,
        text = null,
        buttons = {},
        content = {
            Column(
                modifier = Modifier
                    .padding(DEFAULT_PADDING),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(DEFAULT_PADDING)
            ) {
                // Error animation for visual feedback
                ErrorAnimation(
                    modifier = Modifier.size(DEFAULT_ANIMATION_SIZE),
                    onAnimationEnd = {}
                )
                
                // Title text
                Text(
                    text = title,
                    style = MaterialTheme.typography.h6,
                    color = TextPrimary,
                    textAlign = TextAlign.Center
                )
                
                // Message text
                Text(
                    text = message,
                    style = MaterialTheme.typography.body1,
                    color = TextSecondary,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(DEFAULT_PADDING / 2))
                
                // Action button
                PrimaryButton(
                    text = buttonText,
                    onClick = onDismiss
                )
            }
        }
    )
}

/**
 * A specialized error dialog for network connectivity issues with a predefined title and message.
 * This provides a consistent experience for handling network errors throughout the application.
 *
 * @param onDismiss The callback to invoke when the dialog is dismissed
 * @param showDialog Boolean flag to control dialog visibility
 */
@Composable
fun NetworkErrorDialog(
    onDismiss: () -> Unit,
    showDialog: Boolean
) {
    ErrorDialog(
        title = "Connection Error",
        message = "Please check your internet connection and try again.",
        buttonText = "Retry",
        onDismiss = onDismiss,
        showDialog = showDialog
    )
}

/**
 * A generic error dialog for unexpected errors with a predefined title and message.
 * This provides a fallback for handling unexpected errors throughout the application.
 *
 * @param onDismiss The callback to invoke when the dialog is dismissed
 * @param showDialog Boolean flag to control dialog visibility
 */
@Composable
fun GenericErrorDialog(
    onDismiss: () -> Unit,
    showDialog: Boolean
) {
    ErrorDialog(
        title = "Error",
        message = "An unexpected error occurred. Please try again later.",
        buttonText = "OK",
        onDismiss = onDismiss,
        showDialog = showDialog
    )
}

/**
 * A customizable error dialog that allows specifying a custom title, message, and button text.
 * This provides flexibility for specific error scenarios while maintaining consistent styling.
 *
 * @param title The title text to display at the top of the dialog
 * @param message The message text to display in the dialog body
 * @param buttonText The text to display on the action button
 * @param onDismiss The callback to invoke when the dialog is dismissed
 * @param showDialog Boolean flag to control dialog visibility
 */
@Composable
fun CustomErrorDialog(
    title: String,
    message: String,
    buttonText: String,
    onDismiss: () -> Unit,
    showDialog: Boolean
) {
    ErrorDialog(
        title = title,
        message = message,
        buttonText = buttonText,
        onDismiss = onDismiss,
        showDialog = showDialog
    )
}