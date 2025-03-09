package com.amirawellness.ui.screens.tools

import androidx.compose.foundation.layout.* // version: 1.5.0
import androidx.compose.foundation.rememberScrollState // version: 1.5.0
import androidx.compose.foundation.verticalScroll // version: 1.5.0
import androidx.compose.material.Card // version: 1.5.0
import androidx.compose.material.Divider // version: 1.5.0
import androidx.compose.material.MaterialTheme // version: 1.5.0
import androidx.compose.material.Scaffold // version: 1.5.0
import androidx.compose.material.Surface // version: 1.5.0
import androidx.compose.material.Text // version: 1.5.0
import androidx.compose.material.TextField // version: 1.5.0
import androidx.compose.material.TopAppBar // version: 1.5.0
import androidx.compose.material.icons.Icons // version: 1.5.0
import androidx.compose.material.icons.filled.ArrowBack // version: 1.5.0
import androidx.compose.material.Icon // version: 1.5.0
import androidx.compose.material.IconButton // version: 1.5.0
import androidx.compose.runtime.Composable // version: 1.5.0
import androidx.compose.runtime.collectAsState // version: 1.5.0
import androidx.compose.runtime.getValue // version: 1.5.0
import androidx.compose.runtime.mutableStateOf // version: 1.5.0
import androidx.compose.runtime.remember // version: 1.5.0
import androidx.compose.runtime.setValue // version: 1.5.0
import androidx.compose.ui.Alignment // version: 1.5.0
import androidx.compose.ui.Modifier // version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // version: 1.5.0
import androidx.compose.ui.unit.dp // version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // version: 1.0.0
import androidx.navigation.NavController // version: 2.7.0
import androidx.navigation.compose.rememberNavController // version: 2.7.0
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.data.models.Tool
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.components.cards.ToolCard
import com.amirawellness.ui.components.feedback.CompletedSuccessView
import com.amirawellness.ui.components.inputs.EmotionSelector
import com.amirawellness.ui.components.inputs.IntensitySlider
import com.amirawellness.ui.screens.tools.ToolCompletionViewModel
import com.amirawellness.ui.screens.tools.ToolCompletionUiState

private const val TAG = "ToolCompletionScreen"

/**
 * Main composable function for the Tool Completion screen
 *
 * @param navController NavController
 * @param toolId String
 * @param durationSeconds Int
 * @return Composable UI element
 */
@Composable
fun ToolCompletionScreen(
    navController: NavController,
    toolId: String,
    durationSeconds: Int
) {
    // Get the ViewModel using hiltViewModel()
    val viewModel: ToolCompletionViewModel = hiltViewModel()

    // Collect the UI state from the ViewModel
    val uiState by viewModel.uiState.collectAsState()

    // Load the tool data when the screen is first composed
    remember {
        viewModel.loadTool(durationSeconds)
        true
    }

    // Create a Scaffold with a TopAppBar containing a back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "Tool Completion") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { innerPadding ->
        // Create a scrollable Column for the main content
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // Display a CompletedSuccessView with congratulatory message
            CompletedSuccessView(
                message = "Congratulations!",
                description = "You have completed the tool successfully.",
                actionText = "Go to Home",
                onAction = { viewModel.navigateToHome() }
            )

            // Display recommended tools section if available
            if (uiState.recommendedTools.isNotEmpty()) {
                RecommendedToolsSection(
                    tools = uiState.recommendedTools,
                    onToolClick = { toolId -> viewModel.navigateToToolDetail(toolId) },
                    modifier = Modifier.padding(16.dp)
                )
            }

            // Display emotional check-in form if showEmotionalInputForm is true
            if (uiState.showEmotionalInputForm) {
                EmotionalInputForm(
                    viewModel = viewModel,
                    modifier = Modifier.padding(16.dp)
                )
            } else {
                // If not showing form and state not saved, show button to record emotional state
                if (!uiState.emotionalStateSaved) {
                    PrimaryButton(
                        text = "Record Emotional State",
                        onClick = { viewModel.toggleEmotionalInputForm() },
                        modifier = Modifier.padding(16.dp)
                    )
                }
            }

            // Add buttons for navigating to emotional check-in or returning home
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                PrimaryButton(
                    text = "Go to Home",
                    onClick = { viewModel.navigateToHome() }
                )
            }
        }
    }
}

/**
 * Composable function for the main content of the Tool Completion screen
 *
 * @param viewModel ToolCompletionViewModel
 * @param uiState ToolCompletionUiState
 * @param modifier Modifier
 * @return Composable UI element
 */
@Composable
private fun ToolCompletionContent(
    viewModel: ToolCompletionViewModel,
    uiState: ToolCompletionUiState,
    modifier: Modifier
) {
    // Create a Column with the provided modifier
    Column(modifier = modifier) {
        // Display a CompletedSuccessView with the completed tool name
        uiState.completedTool?.let { tool ->
            CompletedSuccessView(
                message = "Congratulations! You completed ${tool.name}!",
                description = tool.description,
                actionText = "Go to Home",
                onAction = { viewModel.navigateToHome() }
            )
        }

        // If emotional state has been saved, show a thank you message
        if (uiState.emotionalStateSaved) {
            Text(
                text = "Thank you for recording your emotional state!",
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(16.dp)
            )
        }

        // If emotional input form is shown, display EmotionalInputForm
        if (uiState.showEmotionalInputForm) {
            EmotionalInputForm(
                viewModel = viewModel,
                modifier = Modifier.padding(16.dp)
            )
        } else {
            // If not showing form and state not saved, show button to record emotional state
            if (!uiState.emotionalStateSaved) {
                PrimaryButton(
                    text = "Record Emotional State",
                    onClick = { viewModel.toggleEmotionalInputForm() },
                    modifier = Modifier.padding(16.dp)
                )
            }
        }

        // Display recommended tools section if there are recommendations
        if (uiState.recommendedTools.isNotEmpty()) {
            RecommendedToolsSection(
                tools = uiState.recommendedTools,
                onToolClick = { toolId -> viewModel.navigateToToolDetail(toolId) },
                modifier = Modifier.padding(16.dp)
            )
        }

        // Add a button to return to home screen
        SecondaryButton(
            text = "Back to Home",
            onClick = { viewModel.navigateToHome() },
            modifier = Modifier.padding(16.dp)
        )
    }
}

/**
 * Composable function for the emotional input form after tool completion
 *
 * @param viewModel ToolCompletionViewModel
 * @param modifier Modifier
 * @return Composable UI element
 */
@Composable
private fun EmotionalInputForm(
    viewModel: ToolCompletionViewModel,
    modifier: Modifier
) {
    // Create state variables for selected emotion, intensity, and notes
    var selectedEmotion by remember { mutableStateOf<EmotionType?>(null) }
    var intensity by remember { mutableStateOf(5) }
    var notes by remember { mutableStateOf("") }

    // Create a Card to contain the form
    Card(modifier = modifier) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Add a title for the emotional check-in section
            Text(
                text = "How are you feeling now?",
                style = MaterialTheme.typography.h6,
                textAlign = TextAlign.Center
            )

            // Add EmotionSelector component for selecting the emotion
            EmotionSelector(
                selectedEmotion = selectedEmotion,
                onEmotionSelected = { emotion -> selectedEmotion = emotion },
                modifier = Modifier.padding(top = 8.dp)
            )

            // Add IntensitySlider component for selecting the intensity
            IntensitySlider(
                value = intensity,
                onValueChange = { value -> intensity = value },
                modifier = Modifier.padding(top = 8.dp)
            )

            // Add TextField for optional notes
            TextField(
                value = notes,
                onValueChange = { value -> notes = value },
                label = { Text("Notes (optional)") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp)
            )

            // Add submit button that calls viewModel.recordEmotionalState
            PrimaryButton(
                text = "Submit",
                onClick = {
                    selectedEmotion?.let { emotion ->
                        viewModel.recordEmotionalState(emotion, intensity, notes)
                    }
                },
                modifier = Modifier.padding(top = 16.dp)
            )

            // Add cancel button that calls viewModel.toggleEmotionalInputForm
            SecondaryButton(
                text = "Cancel",
                onClick = { viewModel.toggleEmotionalInputForm() },
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}

/**
 * Composable function for displaying recommended tools
 *
 * @param tools List<Tool>
 * @param onToolClick Function1<String, Unit>
 * @param modifier Modifier
 * @return Composable UI element
 */
@Composable
private fun RecommendedToolsSection(
    tools: List<Tool>,
    onToolClick: (String) -> Unit,
    modifier: Modifier
) {
    // Create a Column with the provided modifier
    Column(modifier = modifier) {
        // Add a section title for recommended tools
        Text(
            text = "Recommended Tools",
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        // Add a description explaining the recommendations
        Text(
            text = "Based on your recent activity, we recommend these tools:",
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )

        // For each tool in the list, display a ToolCard
        tools.forEach { tool ->
            ToolCard(
                tool = tool,
                onClick = { onToolClick(tool.id) },
                onFavoriteClick = { /*TODO*/ },
                modifier = Modifier.padding(8.dp)
            )
        }
    }
}

/**
 * Composable function for displaying loading state
 *
 * @param modifier Modifier
 * @return Composable UI element
 */
@Composable
private fun LoadingContent(modifier: Modifier) {
    // Create a Box with the provided modifier
    Box(modifier = modifier) {
        // Center a CircularProgressIndicator in the Box
        // TODO: Implement CircularProgressIndicator
    }
}

/**
 * Composable function for displaying error state
 *
 * @param error String
 * @param modifier Modifier
 * @return Composable UI element
 */
@Composable
private fun ErrorContent(error: String, modifier: Modifier) {
    // Create a Column with the provided modifier
    Column(modifier = modifier) {
        // Display an error icon
        // TODO: Implement error icon
        // Display the error message
        Text(text = error)
        // Add a retry button
        // TODO: Implement retry button
    }
}