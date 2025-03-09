package com.amirawellness.ui.screens.tools

import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout version: 1.5.0
import androidx.compose.material.* // androidx.compose.material version: 1.5.0
import androidx.compose.runtime.* // androidx.compose.runtime version: 1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.graphics.vector.ImageVector // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui.res version: 1.5.0
import androidx.compose.ui.res.vectorResource // androidx.compose.ui.res version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui.text.style version: 1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui.unit version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose version: 1.0.0
import androidx.navigation.compose.NavBackStackEntry // androidx.navigation.compose version: 2.7.0
import androidx.navigation.compose.rememberNavController // androidx.navigation.compose version: 2.7.0
import coil.compose.AsyncImage // coil.compose version: 2.4.0
import com.amirawellness.R
import com.amirawellness.data.models.Tool // Import Tool data class
import com.amirawellness.data.models.ToolContentType // Import ToolContentType enum
import com.amirawellness.data.models.ToolStep // Import ToolStep data class
import com.amirawellness.ui.components.animations.WaveformAnimation // Import WaveformAnimation composable
import com.amirawellness.ui.components.buttons.FilledIconButton // Import FilledIconButton composable
import com.amirawellness.ui.components.buttons.PrimaryIconButton // Import PrimaryIconButton composable
import com.amirawellness.ui.components.buttons.SecondaryIconButton // Import SecondaryIconButton composable
import com.amirawellness.ui.components.feedback.ErrorView // Import ErrorView composable
import com.amirawellness.ui.components.loading.DeterminateLoadingIndicator // Import DeterminateLoadingIndicator composable
import com.amirawellness.ui.components.loading.LoadingIndicator // Import LoadingIndicator composable
import com.amirawellness.ui.navigation.Screen // Import Screen sealed class
import com.amirawellness.ui.screens.tools.ToolInProgressViewModel // Import ToolInProgressViewModel class
import com.amirawellness.ui.screens.tools.ToolInProgressUiState // Import ToolInProgressUiState data class
import com.amirawellness.ui.theme.Primary // Import Primary color
import com.amirawellness.ui.theme.Secondary // Import Secondary color

/**
 * Composable function that displays the tool in progress screen
 *
 * @param navBackStackEntry navBackStackEntry
 */
@Composable
fun ToolInProgressScreen(navBackStackEntry: NavBackStackEntry?) {
    // Extract the toolId parameter from the navigation back stack entry
    val toolId = navBackStackEntry?.arguments?.getString(Screen.ToolInProgress.TOOL_ID_KEY)

    // Get the ToolInProgressViewModel using hiltViewModel()
    val viewModel: ToolInProgressViewModel = hiltViewModel()

    // Collect the UI state from the ViewModel using collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    // Remember the NavController
    val navController = rememberNavController()

    // Call LaunchedEffect to load the tool when the screen is first composed
    LaunchedEffect(key1 = toolId) {
        if (toolId != null) {
            viewModel.loadTool(toolId)
        }
    }

    // Set up the screen scaffold with a top app bar
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = uiState.tool?.name ?: stringResource(id = R.string.tool_in_progress)) },
                navigationIcon = {
                    PrimaryIconButton(
                        icon = ImageVector.vectorResource(id = R.drawable.ic_arrow_back),
                        onClick = { viewModel.cancelExercise() }
                    )
                }
            )
        },
        bottomBar = {
            ControlButtons(
                uiState = uiState,
                onPrevious = { viewModel.moveToPreviousStep() },
                onNext = { viewModel.moveToNextStep() },
                onPlayPause = { viewModel.togglePlayPause() },
                onComplete = { viewModel.completeExercise() },
                onCancel = { viewModel.cancelExercise() }
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            // Display loading indicator when isLoading is true
            if (uiState.isLoading) {
                LoadingIndicator(modifier = Modifier.align(Alignment.Center))
            }
            // Display error view when error is not null
            if (uiState.error != null) {
                ErrorView(
                    message = uiState.error,
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            // Display the tool content when tool is not null
            uiState.tool?.let { tool ->
                when (tool.contentType) {
                    ToolContentType.GUIDED_EXERCISE -> {
                        GuidedExerciseContent(
                            uiState = uiState,
                            onPrevious = { viewModel.moveToPreviousStep() },
                            onNext = { viewModel.moveToNextStep() },
                            onPlayPause = { viewModel.togglePlayPause() }
                        )
                    }
                    ToolContentType.AUDIO -> {
                        AudioContent(
                            uiState = uiState,
                            onPlayPause = { viewModel.togglePlayPause() }
                        )
                    }
                    ToolContentType.VIDEO -> {
                        VideoContent(
                            uiState = uiState,
                            onPlayPause = { viewModel.togglePlayPause() }
                        )
                    }
                    ToolContentType.TEXT -> {
                        TextContent(uiState = uiState)
                    }
                    else -> {
                        Text(text = "Unsupported content type")
                    }
                }
            }
        }
    }
}

/**
 * Composable function that displays guided exercise content
 *
 * @param uiState uiState
 * @param onPrevious onPrevious
 * @param onNext onNext
 * @param onPlayPause onPlayPause
 */
@Composable
private fun GuidedExerciseContent(
    uiState: ToolInProgressUiState,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onPlayPause: () -> Unit
) {
    // Get the current step from uiState.getCurrentStep()
    val currentStep = uiState.getCurrentStep()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Display step number indicator (e.g., 'Step 2 of 5')
        Text(
            text = stringResource(id = R.string.step_number, uiState.currentStepIndex + 1, uiState.getTotalSteps()),
            style = MaterialTheme.typography.caption,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Display step title in a large font
        Text(
            text = currentStep?.title ?: "",
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display step description
        Text(
            text = currentStep?.description ?: "",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display media content if mediaUrl is not null
        currentStep?.mediaUrl?.let { mediaUrl ->
            AsyncImage(
                model = mediaUrl,
                contentDescription = null,
                modifier = Modifier.height(200.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Display progress indicator showing step completion
        DeterminateLoadingIndicator(
            progress = uiState.progress,
            text = uiState.formattedRemainingTime
        )
    }
}

/**
 * Composable function that displays audio content
 *
 * @param uiState uiState
 * @param onPlayPause onPlayPause
 */
@Composable
private fun AudioContent(
    uiState: ToolInProgressUiState,
    onPlayPause: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Display tool title in a large font
        Text(
            text = uiState.tool?.name ?: "",
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display tool instructions
        Text(
            text = uiState.tool?.content?.instructions ?: "",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Add waveform visualization for audio
        WaveformAnimation(
            amplitudes = listOf(0.2f, 0.4f, 0.6f, 0.8f, 0.6f, 0.4f, 0.2f), // Replace with actual audio data
            modifier = Modifier.height(80.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display elapsed time and total duration
        Text(
            text = "${uiState.formattedElapsedTime} / ${uiState.formattedRemainingTime}",
            style = MaterialTheme.typography.caption,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Display progress indicator for audio completion
        DeterminateLoadingIndicator(
            progress = uiState.progress
        )
    }
}

/**
 * Composable function that displays video content
 *
 * @param uiState uiState
 * @param onPlayPause onPlayPause
 */
@Composable
private fun VideoContent(
    uiState: ToolInProgressUiState,
    onPlayPause: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Display tool title in a large font
        Text(
            text = uiState.tool?.name ?: "",
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display video player with controls
        Text(text = "Video Player Placeholder") // Replace with actual video player

        Spacer(modifier = Modifier.height(16.dp))

        // Display elapsed time and total duration
        Text(
            text = "${uiState.formattedElapsedTime} / ${uiState.formattedRemainingTime}",
            style = MaterialTheme.typography.caption,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Display progress indicator for video completion
        DeterminateLoadingIndicator(
            progress = uiState.progress
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display tool instructions below the video
        Text(
            text = uiState.tool?.content?.instructions ?: "",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Composable function that displays text content
 *
 * @param uiState uiState
 */
@Composable
private fun TextContent(uiState: ToolInProgressUiState) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Display tool title in a large font
        Text(
            text = uiState.tool?.name ?: "",
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display tool instructions in a scrollable text area
        Text(
            text = uiState.tool?.content?.instructions ?: "",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Display elapsed time for tracking usage
        Text(
            text = stringResource(id = R.string.elapsed_time, uiState.formattedElapsedTime),
            style = MaterialTheme.typography.caption,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Composable function that displays control buttons for the tool
 *
 * @param uiState uiState
 * @param onPrevious onPrevious
 * @param onNext onNext
 * @param onPlayPause onPlayPause
 * @param onComplete onComplete
 * @param onCancel onCancel
 */
@Composable
private fun ControlButtons(
    uiState: ToolInProgressUiState,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onPlayPause: () -> Unit,
    onComplete: () -> Unit,
    onCancel: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceAround,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Add previous button, disabled if on first step
        SecondaryIconButton(
            icon = ImageVector.vectorResource(id = R.drawable.ic_skip_previous),
            onClick = onPrevious,
            enabled = !uiState.isFirstStep()
        )

        // Add play/pause toggle button that changes icon based on isPlaying state
        FilledIconButton(
            icon = ImageVector.vectorResource(
                id = if (uiState.isPlaying) R.drawable.ic_pause else R.drawable.ic_play_arrow
            ),
            onClick = onPlayPause
        )

        // Add next button, showing complete icon if on last step
        PrimaryIconButton(
            icon = ImageVector.vectorResource(
                id = if (uiState.isLastStep()) R.drawable.ic_check else R.drawable.ic_skip_next
            ),
            onClick = onNext
        )

        // Add cancel button to exit the tool
        SecondaryIconButton(
            icon = ImageVector.vectorResource(id = R.drawable.ic_cancel),
            onClick = onCancel
        )
    }
}