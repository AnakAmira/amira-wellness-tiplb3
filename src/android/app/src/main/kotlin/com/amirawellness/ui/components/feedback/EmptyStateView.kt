package com.amirawellness.ui.components.feedback

import androidx.compose.foundation.layout.*
import androidx.compose.material.Card
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.Image
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.theme.CardShape
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary

private val DEFAULT_PADDING = 16.dp
private val DEFAULT_ILLUSTRATION_SIZE = 120.dp

/**
 * A composable function that displays an empty state view with an illustration,
 * message, and optional action button.
 *
 * @param message The main message to display
 * @param description Optional supporting text to provide more context
 * @param illustrationResId Optional resource ID for the illustration to display
 * @param actionText Optional text for the action button
 * @param onAction Optional callback for when the action button is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
fun EmptyStateView(
    message: String,
    description: String? = null,
    illustrationResId: Int? = null,
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Display illustration if provided
        illustrationResId?.let {
            Image(
                painter = painterResource(id = it),
                contentDescription = null,
                modifier = Modifier
                    .size(DEFAULT_ILLUSTRATION_SIZE)
                    .padding(bottom = DEFAULT_PADDING)
            )
        }
        
        // Main message
        Text(
            text = message,
            style = MaterialTheme.typography.h6,
            color = TextPrimary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        // Optional description
        description?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(
                    start = DEFAULT_PADDING,
                    end = DEFAULT_PADDING,
                    bottom = if (actionText != null && onAction != null) 8.dp else DEFAULT_PADDING
                )
            )
        }
        
        // Optional action button
        if (actionText != null && onAction != null) {
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
 * A composable function that displays an empty state view within a card with an illustration,
 * message, and optional action button.
 *
 * @param message The main message to display
 * @param description Optional supporting text to provide more context
 * @param illustrationResId Optional resource ID for the illustration to display
 * @param actionText Optional text for the action button
 * @param onAction Optional callback for when the action button is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
fun EmptyStateCard(
    message: String,
    description: String? = null,
    illustrationResId: Int? = null,
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = CardShape,
        elevation = 2.dp
    ) {
        EmptyStateView(
            message = message,
            description = description,
            illustrationResId = illustrationResId,
            actionText = actionText,
            onAction = onAction,
            modifier = Modifier.padding(DEFAULT_PADDING)
        )
    }
}

/**
 * A specialized empty state view for when no journal entries are available.
 *
 * @param onCreateJournal Callback for when the Create Journal button is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
fun NoJournalsEmptyState(
    onCreateJournal: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyStateView(
        message = "No journal entries yet",
        description = "Start recording your thoughts and emotions by creating your first journal",
        illustrationResId = null, // Replace with actual resource when available
        actionText = "Create Journal",
        onAction = onCreateJournal,
        modifier = modifier
    )
}

/**
 * A specialized empty state view for when no tools are available in a category.
 *
 * @param onBrowseAll Callback for when the Browse All Tools button is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
fun NoToolsEmptyState(
    onBrowseAll: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyStateView(
        message = "No tools in this category",
        description = "Browse our complete collection to find tools that work for you",
        illustrationResId = null, // Replace with actual resource when available
        actionText = "Browse All Tools",
        onAction = onBrowseAll,
        modifier = modifier
    )
}

/**
 * A specialized empty state view for when no favorite tools are available.
 *
 * @param onBrowseTools Callback for when the Browse Tools button is clicked
 * @param modifier Modifier for styling and layout
 */
@Composable
fun NoFavoritesEmptyState(
    onBrowseTools: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyStateView(
        message = "No favorites yet",
        description = "Add tools to your favorites for quick access to the ones you use most",
        illustrationResId = null, // Replace with actual resource when available
        actionText = "Browse Tools",
        onAction = onBrowseTools,
        modifier = modifier
    )
}

/**
 * A specialized empty state view for when search results are empty.
 *
 * @param modifier Modifier for styling and layout
 */
@Composable
fun SearchEmptyState(
    modifier: Modifier = Modifier
) {
    EmptyStateView(
        message = "No results found",
        description = "Try different search terms or browse through categories",
        illustrationResId = null, // Replace with actual resource when available
        modifier = modifier
    )
}