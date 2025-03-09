package com.amirawellness.ui.screens.tools

import androidx.compose.foundation.layout.Arrangement // version: 1.5.0
import androidx.compose.foundation.layout.Box // version: 1.5.0
import androidx.compose.foundation.layout.Column // version: 1.5.0
import androidx.compose.foundation.layout.Row // version: 1.5.0
import androidx.compose.foundation.layout.Spacer // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxSize // version: 1.5.0
import androidx.compose.foundation.layout.fillMaxWidth // version: 1.5.0
import androidx.compose.foundation.layout.height // version: 1.5.0
import androidx.compose.foundation.layout.padding // version: 1.5.0
import androidx.compose.foundation.layout.size // version: 1.5.0
import androidx.compose.foundation.rememberScrollState // version: 1.5.0
import androidx.compose.foundation.verticalScroll // version: 1.5.0
import androidx.compose.material.Card // version: 1.5.0
import androidx.compose.material.Divider // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.material.IconButton // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Scaffold // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.material.TopAppBar // version: 1.5.0
import androidx.compose.material.icons.Icons // version: 1.5.0
import androidx.compose.material.icons.filled.ArrowBack // version: 1.5.0
import androidx.compose.material.icons.outlined.Favorite // version: 1.5.0
import androidx.compose.material.icons.outlined.FavoriteBorder // version: 1.5.0
import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.LaunchedEffect // version: 1.5.0
import androidx.compose.runtime.collectAsState // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.compose.ui.unit.sp // version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // version: 1.0.0
import androidx.navigation.navArgument // version: 2.7.0
import coil.compose.AsyncImage // version: 2.4.0
import com.amirawellness.data.models.Resource // src/android/app/src/main/kotlin/com/amirawellness/data/models/Tool.kt
import com.amirawellness.data.models.ResourceType // src/android/app/src/main/kotlin/com/amirawellness/data/models/Tool.kt
import com.amirawellness.data.models.Tool // src/android/app/src/main/kotlin/com/amirawellness/data/models/Tool.kt
import com.amirawellness.data.models.ToolContent // src/android/app/src/main/kotlin/com/amirawellness/data/models/Tool.kt
import com.amirawellness.data.models.ToolContentType // src/android/app/src/main/kotlin/com/amirawellness/data/models/Tool.kt
import com.amirawellness.data.models.ToolStep // src/android/app/src/main/kotlin/com/amirawellness/ui/components.buttons.PrimaryButton.kt
import com.amirawellness.ui.components.buttons.IconButton // src/android/app/src/main/kotlin/com/amirawellness/ui/components/buttons/IconButton.kt
import com.amirawellness.ui.components.loading.LoadingIndicator // src/android/app/src/main/kotlin/com/amirawellness/ui/components.feedback.ErrorView.kt
import com.amirawellness.ui.navigation.Screen // src/android/app/src/main/kotlin/com/amirawellness/ui/navigation/Screen.kt
import com.amirawellness.ui.screens.tools.ToolDetailViewModel // src/android/app/src/main/kotlin/com/amirawellness/ui/screens.tools.ToolDetailViewModel.kt
import com.amirawellness.ui.theme.Primary // src/android/app/src/main/kotlin/com/amirawellness/ui/theme/Color.kt
import com.amirawellness.ui.theme.Secondary // src/android/app/src/main/kotlin/com/amirawellness/ui/theme/Color.kt
import com.amirawellness.ui.theme.Surface // src/android/app/src/main/kotlin/com/amirawellness/ui/theme/Color.kt
import com.amirawellness.ui.theme.TextPrimary // src/android/app/src/main/kotlin/com/amirawellness/ui/theme/Color.kt
import com.amirawellness.ui.theme.TextSecondary // src/android/app/src/main/kotlin/com/amirawellness/ui/theme/Color.kt
import com.amirawellness.ui.components.feedback.GenericErrorView // src/android/app/src/main/kotlin/com/amirawellness/ui/components/feedback/ErrorView.kt

/**
 * Main composable function for the Tool Detail screen that displays detailed information about a tool
 * @param toolId The ID of the tool to display
 */
@Composable
fun ToolDetailScreen(toolId: String) {
    // Get the ToolDetailViewModel using hiltViewModel()
    val viewModel: ToolDetailViewModel = hiltViewModel()

    // Collect the UI state from the ViewModel
    val uiState by viewModel.uiState.collectAsState()

    // Use LaunchedEffect to load the tool when the screen is first composed
    LaunchedEffect(key1 = toolId) {
        viewModel.loadTool(toolId)
    }

    // Create a Scaffold with a TopAppBar containing back button and favorite button
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "Detalles de la herramienta") },
                navigationIcon = {
                    IconButton(onClick = { viewModel.navigateBack() },
                        icon = Icons.Filled.ArrowBack,
                        contentDescription = "Back")
                },
                actions = {
                    if (uiState.tool != null) {
                        IconButton(
                            onClick = { viewModel.toggleFavorite() },
                            icon = if (uiState.tool.isFavorite) Icons.Outlined.Favorite else Icons.Outlined.FavoriteBorder,
                            contentDescription = "Favorite"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        // Handle different UI states (loading, error, content)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (uiState.isLoading) {
                // If loading, show LoadingIndicator
                LoadingIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (uiState.error != null) {
                // If error, show GenericErrorView with retry option
                GenericErrorView(onRetry = { viewModel.retry() },
                    modifier = Modifier.align(Alignment.Center))
            } else if (uiState.tool != null) {
                // If content loaded successfully, show ToolDetailContent
                ToolDetailContent(
                    tool = uiState.tool,
                    onStartTool = { viewModel.startTool() },
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}

/**
 * Composable function that displays the content of a tool detail screen
 * @param tool The tool to display
 * @param onStartTool Callback function to start the tool
 * @param modifier Modifier for styling
 */
@Composable
private fun ToolDetailContent(
    tool: Tool,
    onStartTool: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Create a Column with vertical scroll capability
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Display tool header with name and category
        ToolHeader(tool = tool)

        // Display tool description
        Text(
            text = tool.description,
            style = MaterialTheme.typography.body1,
            color = TextPrimary,
            textAlign = TextAlign.Justify
        )

        // Display tool metadata (duration, content type, target emotions)
        ToolMetadata(tool = tool)

        // Display tool content with instructions
        ToolInstructions(content = tool.content)

        // If tool has steps, display step list
        if (tool.content.steps != null) {
            ToolStepsList(steps = tool.content.steps)
        }

        // If tool has additional resources, display resource list
        if (tool.content.additionalResources != null) {
            ResourcesList(resources = tool.content.additionalResources)
        }

        // Add a start button at the bottom to begin using the tool
        PrimaryButton(
            text = "Comenzar",
            onClick = onStartTool,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/**
 * Composable function that displays the header section of a tool detail screen
 * @param tool The tool to display
 * @param modifier Modifier for styling
 */
@Composable
private fun ToolHeader(tool: Tool, modifier: Modifier = Modifier) {
    // Create a Card with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Display tool name with large typography
            Text(
                text = tool.name,
                style = MaterialTheme.typography.h5,
                color = TextPrimary,
                textAlign = TextAlign.Center
            )

            // Display tool category badge
            Text(
                text = tool.category.name,
                style = MaterialTheme.typography.caption,
                color = Secondary,
                textAlign = TextAlign.Center
            )

            // Display tool description with medium typography
            Text(
                text = tool.description,
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                textAlign = TextAlign.Justify
            )
        }
    }
}

/**
 * Composable function that displays metadata about a tool
 * @param tool The tool to display
 * @param modifier Modifier for styling
 */
@Composable
private fun ToolMetadata(tool: Tool, modifier: Modifier = Modifier) {
    // Create a Card with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Display duration information with clock icon
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack, // Replace with clock icon
                    contentDescription = "Duration",
                    tint = TextSecondary
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = formatDuration(tool.estimatedDuration),
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }

            // Display content type with appropriate icon
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack, // Replace with content type icon
                    contentDescription = "Content Type",
                    tint = TextSecondary
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = tool.contentType.toString(),
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }

            // Display target emotions with emotion icons
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack, // Replace with emotion icon
                    contentDescription = "Target Emotions",
                    tint = TextSecondary
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = tool.targetEmotions.joinToString(", "),
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
        }
    }
}

/**
 * Composable function that displays the instructions for using a tool
 * @param content The content of the tool
 * @param modifier Modifier for styling
 */
@Composable
private fun ToolInstructions(content: ToolContent, modifier: Modifier = Modifier) {
    // Create a Card with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Display content title with medium typography
            Text(
                text = content.title,
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )

            // Display instructions with regular typography
            Text(
                text = content.instructions,
                style = MaterialTheme.typography.body2,
                color = TextSecondary,
                textAlign = TextAlign.Justify
            )

            // If mediaUrl is not null, display media preview
            if (content.mediaUrl != null) {
                AsyncImage(
                    model = content.mediaUrl,
                    contentDescription = "Media Preview",
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

/**
 * Composable function that displays a list of steps for a guided tool exercise
 * @param steps The list of steps to display
 * @param modifier Modifier for styling
 */
@Composable
private fun ToolStepsList(steps: List<ToolStep>, modifier: Modifier = Modifier) {
    // Create a Card with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Display "Steps" header with medium typography
            Text(
                text = "Pasos",
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )

            // For each step in the list, display StepItem
            steps.forEach { step ->
                StepItem(step = step)
                Divider()
            }
        }
    }
}

/**
 * Composable function that displays a single step in a guided tool exercise
 * @param step The step to display
 * @param modifier Modifier for styling
 */
@Composable
private fun StepItem(step: ToolStep, modifier: Modifier = Modifier) {
    // Create a Row with appropriate styling
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Display step order number in a circle
        Text(
            text = step.order.toString(),
            style = MaterialTheme.typography.body1,
            color = Primary,
            modifier = Modifier.padding(end = 8.dp)
        )

        Column {
            // Display step title with medium typography
            Text(
                text = step.title,
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )

            // Display step description with regular typography
            Text(
                text = step.description,
                style = MaterialTheme.typography.body2,
                color = TextSecondary
            )
        }

        // Display step duration with clock icon
        Icon(
            imageVector = Icons.Filled.ArrowBack, // Replace with clock icon
            contentDescription = "Duration",
            tint = TextSecondary
        )
        Text(
            text = "${step.duration} seconds",
            style = MaterialTheme.typography.caption,
            color = TextSecondary
        )
    }
}

/**
 * Composable function that displays a list of additional resources for a tool
 * @param resources The list of resources to display
 * @param modifier Modifier for styling
 */
@Composable
private fun ResourcesList(resources: List<Resource>, modifier: Modifier = Modifier) {
    // Create a Card with appropriate styling
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = 4.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Display "Additional Resources" header with medium typography
            Text(
                text = "Recursos adicionales",
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )

            // For each resource in the list, display ResourceItem
            resources.forEach { resource ->
                ResourceItem(resource = resource)
                Divider()
            }
        }
    }
}

/**
 * Composable function that displays a single additional resource for a tool
 * @param resource The resource to display
 * @param modifier Modifier for styling
 */
@Composable
private fun ResourceItem(resource: Resource, modifier: Modifier = Modifier) {
    // Create a Row with appropriate styling
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Display resource type icon based on resource.type
        Icon(
            imageVector = Icons.Filled.ArrowBack, // Replace with resource type icon
            contentDescription = "Resource Type",
            tint = Secondary
        )

        Column {
            // Display resource title with medium typography
            Text(
                text = resource.title,
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )

            // Display resource description with regular typography
            Text(
                text = resource.description,
                style = MaterialTheme.typography.body2,
                color = TextSecondary
            )
        }

        // Add a clickable link icon to open the resource URL
        IconButton(onClick = { /*TODO: Open URL*/ },
            icon = Icons.Filled.ArrowBack, // Replace with link icon
            contentDescription = "Open Link")
    }
}

/**
 * Helper function to format duration in minutes to a human-readable string
 * @param durationMinutes The duration in minutes
 * @return Formatted duration string (e.g., "5 min")
 */
private fun formatDuration(durationMinutes: Int): String {
    // Format the duration as a string with "min" suffix
    return "${durationMinutes} min"
}