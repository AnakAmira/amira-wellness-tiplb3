package com.amirawellness.ui.components.feedback

import androidx.compose.foundation.layout.* // version: 1.5.0
import androidx.compose.material.Card // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.mutableStateOf // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import com.amirawellness.ui.theme.Error
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.animations.ErrorAnimation

/**
 * Default padding for the error view components
 */
private val DEFAULT_PADDING = 16.dp

/**
 * Default size for the error animation
 */
private val DEFAULT_ANIMATION_SIZE = 120.dp

/**
 * A composable function that displays an error state view with an animation, 
 * message, and optional action button.
 *
 * @param message The main error message to display
 * @param description Optional secondary description of the error
 * @param actionText Optional text for the action button
 * @param onAction Optional callback for when the action button is clicked
 * @param modifier Additional Modifier to apply to the component
 */
@Composable
fun ErrorView(
    message: String,
    description: String? = null,
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Display the error animation
        ErrorAnimation(
            modifier = Modifier.size(DEFAULT_ANIMATION_SIZE),
            onAnimationEnd = {}
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display the main error message
        Text(
            text = message,
            style = MaterialTheme.typography.h6,
            color = TextPrimary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = DEFAULT_PADDING)
        )

        // Display the optional description
        if (!description.isNullOrEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = description,
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = DEFAULT_PADDING)
            )
        }

        // Display the optional action button
        if (actionText != null && onAction != null) {
            Spacer(modifier = Modifier.height(24.dp))
            PrimaryButton(
                text = actionText,
                onClick = onAction,
                modifier = Modifier
                    .padding(horizontal = DEFAULT_PADDING)
                    .fillMaxWidth()
            )
        }
    }
}

/**
 * A composable function that displays an error state view within a card with 
 * an animation, message, and optional action button.
 *
 * @param message The main error message to display
 * @param description Optional secondary description of the error
 * @param actionText Optional text for the action button
 * @param onAction Optional callback for when the action button is clicked
 * @param modifier Additional Modifier to apply to the component
 */
@Composable
fun ErrorCard(
    message: String,
    description: String? = null,
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        elevation = 4.dp,
        shape = MaterialTheme.shapes.medium
    ) {
        ErrorView(
            message = message,
            description = description,
            actionText = actionText,
            onAction = onAction,
            modifier = Modifier.padding(vertical = DEFAULT_PADDING)
        )
    }
}

/**
 * A specialized error view for network connectivity issues with a 
 * predefined message and retry option.
 *
 * @param onRetry Callback function when the retry button is clicked
 * @param modifier Additional Modifier to apply to the component
 */
@Composable
fun NetworkErrorView(
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    ErrorView(
        message = "Error de conexión",
        description = "Por favor, verifica tu conexión a Internet e intenta nuevamente.",
        actionText = "Reintentar",
        onAction = onRetry,
        modifier = modifier
    )
}

/**
 * A specialized error view for general errors with a predefined message 
 * and retry option.
 *
 * @param onRetry Callback function when the retry button is clicked
 * @param modifier Additional Modifier to apply to the component
 */
@Composable
fun GenericErrorView(
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    ErrorView(
        message = "Algo salió mal",
        description = "Lo sentimos, ha ocurrido un error inesperado. Por favor, intenta nuevamente.",
        actionText = "Reintentar",
        onAction = onRetry,
        modifier = modifier
    )
}

/**
 * A specialized error view for permission-related issues with a predefined 
 * message and settings action.
 *
 * @param onOpenSettings Callback function when the settings button is clicked
 * @param modifier Additional Modifier to apply to the component
 */
@Composable
fun PermissionErrorView(
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier
) {
    ErrorView(
        message = "Permiso requerido",
        description = "Esta función requiere permisos adicionales para funcionar correctamente. Por favor, otorga los permisos necesarios en la configuración.",
        actionText = "Abrir Configuración",
        onAction = onOpenSettings,
        modifier = modifier
    )
}