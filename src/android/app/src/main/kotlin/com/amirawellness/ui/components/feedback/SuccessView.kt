package com.amirawellness.ui.components.feedback

import androidx.compose.foundation.layout.*
import androidx.compose.material.Card
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Success
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.animations.SuccessAnimation
import com.amirawellness.ui.theme.CardShape

private val DEFAULT_PADDING = 16.dp
private val DEFAULT_ANIMATION_SIZE = 120.dp

/**
 * A composable function that displays a success state view with an animation, message, and optional action button
 *
 * @param message The success message to display
 * @param description Optional description text to provide additional context
 * @param actionText Text for the action button, if null no button will be shown
 * @param onAction Action to perform when the button is clicked, if null no button will be shown
 * @param modifier Additional modifiers to apply to the component
 */
@Composable
fun SuccessView(
    message: String,
    description: String? = null,
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        // Display success animation
        SuccessAnimation(
            modifier = Modifier.size(DEFAULT_ANIMATION_SIZE)
        )
        
        Spacer(modifier = Modifier.height(DEFAULT_PADDING))
        
        // Display success message
        Text(
            text = message,
            style = MaterialTheme.typography.h6,
            color = TextPrimary,
            textAlign = TextAlign.Center
        )
        
        // Display description if provided
        if (description != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = description,
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                textAlign = TextAlign.Center
            )
        }
        
        // Display action button if text and handler are provided
        if (actionText != null && onAction != null) {
            Spacer(modifier = Modifier.height(24.dp))
            PrimaryButton(
                text = actionText,
                onClick = onAction
            )
        }
    }
}

/**
 * A composable function that displays a success state view within a card with an animation, message, and optional action button
 *
 * @param message The success message to display
 * @param description Optional description text to provide additional context
 * @param actionText Text for the action button, if null no button will be shown
 * @param onAction Action to perform when the button is clicked, if null no button will be shown
 * @param modifier Additional modifiers to apply to the component
 */
@Composable
fun SuccessCard(
    message: String,
    description: String? = null,
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = CardShape,
        elevation = 4.dp
    ) {
        SuccessView(
            message = message,
            description = description,
            actionText = actionText,
            onAction = onAction,
            modifier = Modifier.padding(DEFAULT_PADDING)
        )
    }
}

/**
 * A specialized success view for when content has been successfully saved
 *
 * @param actionText Text for the action button, if null no button will be shown
 * @param onAction Action to perform when the button is clicked, if null no button will be shown
 * @param modifier Additional modifiers to apply to the component
 */
@Composable
fun SavedSuccessView(
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    SuccessView(
        message = "Saved successfully",
        description = "Your content has been safely stored",
        actionText = actionText,
        onAction = onAction,
        modifier = modifier
    )
}

/**
 * A specialized success view for when an activity has been successfully completed
 *
 * @param actionText Text for the action button, if null no button will be shown
 * @param onAction Action to perform when the button is clicked, if null no button will be shown
 * @param modifier Additional modifiers to apply to the component
 */
@Composable
fun CompletedSuccessView(
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    SuccessView(
        message = "Completed successfully",
        description = "Great job! You've completed this activity",
        actionText = actionText,
        onAction = onAction,
        modifier = modifier
    )
}

/**
 * A specialized success view for when content has been successfully uploaded
 *
 * @param actionText Text for the action button, if null no button will be shown
 * @param onAction Action to perform when the button is clicked, if null no button will be shown
 * @param modifier Additional modifiers to apply to the component
 */
@Composable
fun UploadedSuccessView(
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    SuccessView(
        message = "Uploaded successfully",
        description = "Your content has been securely stored",
        actionText = actionText,
        onAction = onAction,
        modifier = modifier
    )
}