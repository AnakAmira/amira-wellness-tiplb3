package com.amirawellness.ui.components.dialogs

import androidx.compose.runtime.Composable
import androidx.compose.ui.window.Dialog
import androidx.compose.material.AlertDialog
import androidx.compose.material.Text
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.style.TextAlign

import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.theme.Surface as SurfaceColor
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.core.extensions.clickableWithRipple

/**
 * A composable function that displays a confirmation dialog with a title, message, and two action buttons.
 * Used for confirming user actions that require explicit confirmation.
 *
 * @param title The title text for the dialog
 * @param message The message text for the dialog
 * @param confirmButtonText The text for the confirm button
 * @param cancelButtonText The text for the cancel button
 * @param onConfirm Action to perform when the user confirms
 * @param onDismiss Action to perform when the user dismisses the dialog
 * @param showDialog Boolean flag to control whether the dialog is shown
 */
@Composable
fun ConfirmationDialog(
    title: String,
    message: String,
    confirmButtonText: String,
    cancelButtonText: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    showDialog: Boolean
) {
    if (!showDialog) return
    
    Dialog(
        onDismissRequest = onDismiss
    ) {
        Surface(
            color = SurfaceColor,
            shape = MaterialTheme.shapes.medium,
            elevation = 8.dp
        ) {
            Column(
                modifier = Modifier
                    .padding(24.dp)
                    .fillMaxWidth()
            ) {
                // Title
                Text(
                    text = title,
                    style = MaterialTheme.typography.h6,
                    color = TextPrimary
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Message
                Text(
                    text = message,
                    style = MaterialTheme.typography.body1,
                    color = TextPrimary,
                    textAlign = TextAlign.center
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Confirm button
                PrimaryButton(
                    text = confirmButtonText,
                    onClick = {
                        onConfirm()
                        onDismiss()
                    }
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                // Cancel button
                SecondaryButton(
                    text = cancelButtonText,
                    onClick = onDismiss
                )
            }
        }
    }
}

/**
 * A simplified version of ConfirmationDialog with default button text.
 * Used for quick confirmations with standard styling.
 *
 * @param title The title text for the dialog
 * @param message The message text for the dialog
 * @param onConfirm Action to perform when the user confirms
 * @param onDismiss Action to perform when the user dismisses the dialog
 * @param showDialog Boolean flag to control whether the dialog is shown
 */
@Composable
fun SimpleConfirmationDialog(
    title: String,
    message: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    showDialog: Boolean
) {
    ConfirmationDialog(
        title = title,
        message = message,
        confirmButtonText = "Confirm",
        cancelButtonText = "Cancel",
        onConfirm = onConfirm,
        onDismiss = onDismiss,
        showDialog = showDialog
    )
}

/**
 * A specialized version of ConfirmationDialog for delete operations.
 * Used for confirming permanent deletion actions with appropriate styling and wording.
 *
 * @param itemType The type of item being deleted (e.g., "journal", "recording")
 * @param onConfirmDelete Action to perform when the user confirms deletion
 * @param onDismiss Action to perform when the user dismisses the dialog
 * @param showDialog Boolean flag to control whether the dialog is shown
 */
@Composable
fun DeleteConfirmationDialog(
    itemType: String,
    onConfirmDelete: () -> Unit,
    onDismiss: () -> Unit,
    showDialog: Boolean
) {
    val title = "Delete $itemType?"
    val message = "Are you sure you want to delete this $itemType? This action cannot be undone."
    
    ConfirmationDialog(
        title = title,
        message = message,
        confirmButtonText = "Delete",
        cancelButtonText = "Cancel",
        onConfirm = onConfirmDelete,
        onDismiss = onDismiss,
        showDialog = showDialog
    )
}