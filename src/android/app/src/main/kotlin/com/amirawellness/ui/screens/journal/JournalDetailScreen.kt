package com.amirawellness.ui.screens.journal

import android.content.Intent // android version: latest
import android.net.Uri // android version: latest
import androidx.compose.animation.core.* // androidx.compose.animation.core version: 1.5.0
import androidx.compose.foundation.background // androidx.compose.foundation version: 1.5.0
import androidx.compose.foundation.clickable // androidx.compose.foundation version: 1.5.0
import androidx.compose.foundation.layout.* // androidx.compose.foundation version: 1.5.0
import androidx.compose.foundation.shape.CircleShape // androidx.compose.foundation.shape version: 1.5.0
import androidx.compose.material.* // androidx.compose.material version: 1.5.0
import androidx.compose.material.icons.Icons // androidx.compose.material.icons version: 1.5.0
import androidx.compose.material.icons.filled.* // androidx.compose.material.icons.filled version: 1.5.0
import androidx.compose.material.icons.outlined.* // androidx.compose.material.icons.outlined version: 1.5.0
import androidx.compose.runtime.* // androidx.compose.runtime version: 1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.draw.clip // androidx.compose.ui.draw version: 1.5.0
import androidx.compose.ui.graphics.Color // androidx.compose.ui version: 1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui.text.style version: 1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui.unit version: 1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose version: 1.0.0
import androidx.navigation.NavController // androidx.navigation version: 2.7.0
import androidx.navigation.compose.rememberNavController // androidx.navigation.compose version: 2.7.0
import com.amirawellness.core.extensions.formatDuration
import com.amirawellness.core.extensions.toJournalDateString
import com.amirawellness.services.audio.AudioPlaybackService.PlaybackState
import com.amirawellness.ui.components.animations.WaveformAnimation
import com.amirawellness.ui.components.buttons.IconButton
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.components.dialogs.ConfirmationDialog
import com.amirawellness.ui.components.dialogs.DeleteConfirmationDialog
import com.amirawellness.ui.components.feedback.ErrorView
import com.amirawellness.ui.components.feedback.SuccessView
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.theme.Primary
import com.amirawellness.ui.theme.Secondary
import com.amirawellness.ui.theme.Surface
import com.amirawellness.ui.theme.TextPrimary
import com.amirawellness.ui.theme.TextSecondary
import androidx.compose.material.CircularProgressIndicator // version: 1.5.0
import androidx.compose.ui.platform.LocalContext // version: 1.5.0

private const val TAG = "JournalDetailScreen"

/**
 * Main composable function for the journal detail screen that displays a voice journal entry with playback controls and emotional data
 * @param navController NavController for screen transitions
 * @param journalId The ID of the journal to display
 */
@Composable
fun JournalDetailScreen(
    navController: NavController,
    journalId: String
) {
    // Get JournalDetailViewModel using hiltViewModel()
    val viewModel: JournalDetailViewModel = hiltViewModel()

    // Create NavActions with the provided navController
    val navActions = remember { NavActions(navController) }

    // Collect uiState from viewModel as State
    val uiState by viewModel.uiState.collectAsState()

    // Create mutable state for showDeleteDialog
    val showDeleteDialog = remember { mutableStateOf(false) }

    // Create mutable state for showExportDialog
    val showExportDialog = remember { mutableStateOf(false) }

    // Create mutable state for includeMetadata for export
    val includeMetadata = remember { mutableStateOf(false) }

    // Set up LaunchedEffect to load journal data when the screen is first displayed
    LaunchedEffect(key1 = journalId) {
        viewModel.loadJournal(journalId)
    }

    // Create a Scaffold with a TopAppBar and content
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Journal Detail",
                        color = TextPrimary
                    )
                },
                navigationIcon = {
                    IconButton(
                        onClick = { navActions.navigateBack() },
                        icon = Icons.Filled.ArrowBack,
                        tint = TextPrimary
                    )
                },
                actions = {
                    // Action buttons for favorite, export, and delete
                    IconButton(
                        onClick = { viewModel.toggleFavorite() },
                        icon = if (uiState.journal?.isFavorite == true) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                        tint = Primary
                    )
                    IconButton(
                        onClick = { showExportDialog.value = true },
                        icon = Icons.Outlined.Share,
                        tint = Primary
                    )
                    IconButton(
                        onClick = { showDeleteDialog.value = true },
                        icon = Icons.Outlined.Delete,
                        tint = Primary
                    )
                },
                backgroundColor = Surface
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Handle loading state by showing CircularProgressIndicator
            if (uiState.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center),
                    color = Primary
                )
            }

            // Handle error state by showing ErrorView
            if (uiState.isError) {
                ErrorView(
                    message = uiState.message ?: "An error occurred",
                    modifier = Modifier.align(Alignment.Center)
                )
            }

            // Handle deletion completed state by navigating back to journal list
            if (uiState.deletionCompleted) {
                LaunchedEffect(key1 = uiState.deletionCompleted) {
                    navActions.navigateToJournalList()
                }
            }

            // Display journal content when loaded
            uiState.journal?.let { journal ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                ) {
                    // Show journal title and date
                    JournalHeader(
                        uiState = uiState,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )

                    // Display emotional shift visualization with pre and post states
                    uiState.emotionalShift?.let { emotionalShift ->
                        EmotionalShiftSection(
                            emotionalShift = emotionalShift,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                    }

                    // Show audio player with waveform visualization
                    AudioPlayerSection(
                        uiState = uiState,
                        onPlayPause = {
                            if (uiState.playbackState is PlaybackState.Playing) {
                                viewModel.pauseAudio()
                            } else {
                                viewModel.playAudio()
                            }
                        },
                        onSeek = { position ->
                            viewModel.seekTo(position)
                        },
                        modifier = Modifier.padding(bottom = 16.dp)
                    )

                    // Display insights from emotional shift
                    uiState.emotionalShift?.let { emotionalShift ->
                        InsightsSection(
                            emotionalShift = emotionalShift,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                    }
                }
            }

            // Show DeleteConfirmationDialog when showDeleteDialog is true
            if (showDeleteDialog.value) {
                DeleteConfirmationDialog(
                    itemType = "journal",
                    onConfirmDelete = { viewModel.deleteJournal() },
                    onDismiss = { showDeleteDialog.value = false },
                    showDialog = showDeleteDialog.value
                )
            }

            // Show ConfirmationDialog for export options when showExportDialog is true
            if (showExportDialog.value) {
                ConfirmationDialog(
                    title = "Export Options",
                    message = "Include metadata in the exported file?",
                    confirmButtonText = "Export with Metadata",
                    cancelButtonText = "Export without Metadata",
                    onConfirm = {
                        includeMetadata.value = true
                        viewModel.exportJournal(includeMetadata.value)
                        showExportDialog.value = false
                    },
                    onDismiss = {
                        includeMetadata.value = false
                        viewModel.exportJournal(includeMetadata.value)
                        showExportDialog.value = false
                    },
                    showDialog = showExportDialog.value
                )
            }

            // Handle exported URI by showing share intent
            uiState.exportedUri?.let { uri ->
                val context = LocalContext.current
                LaunchedEffect(key1 = uri) {
                    val shareIntent = Intent().apply {
                        action = Intent.ACTION_SEND
                        putExtra(Intent.EXTRA_STREAM, uri)
                        type = "audio/*"
                        flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                    }
                    context.startActivity(Intent.createChooser(shareIntent, "Share Journal"))
                    viewModel.clearMessage()
                }
            }

            // Display Snackbar for messages and errors
            uiState.message?.let { message ->
                LaunchedEffect(key1 = message) {
                    // TODO: Show snackbar
                    viewModel.clearMessage()
                }
            }
        }
    }
}

/**
 * Composable function that displays the journal header with title and date
 * @param uiState JournalDetailUiState containing journal data
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun JournalHeader(
    uiState: JournalDetailUiState,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
    ) {
        Text(
            text = uiState.journal?.title ?: "Untitled Journal",
            style = MaterialTheme.typography.h5,
            color = TextPrimary
        )
        Text(
            text = uiState.journal?.createdAt?.toJournalDateString() ?: "Unknown Date",
            style = MaterialTheme.typography.body2,
            color = TextSecondary
        )
    }
}

/**
 * Composable function that displays the emotional shift between pre and post journaling states
 * @param emotionalShift EmotionalShift data class containing emotional states
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun EmotionalShiftSection(
    emotionalShift: EmotionalShift,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Emotional Shift",
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                EmotionIndicator(
                    emotionalState = emotionalShift.preEmotionalState,
                    modifier = Modifier.weight(1f)
                )
                Icon(
                    imageVector = Icons.Filled.ArrowForward,
                    contentDescription = "Emotional Shift",
                    tint = Primary,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )
                EmotionIndicator(
                    emotionalState = emotionalShift.postEmotionalState,
                    modifier = Modifier.weight(1f)
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Intensity Change: ${emotionalShift.intensityChange}",
                style = MaterialTheme.typography.body2,
                color = when {
                    emotionalShift.isPositive() -> Primary
                    emotionalShift.isNegative() -> Secondary
                    else -> TextSecondary
                }
            )
        }
    }
}

/**
 * Composable function that displays an emotion indicator with name, intensity, and color
 * @param emotionalState EmotionalState data class containing emotion data
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun EmotionIndicator(
    emotionalState: EmotionalState,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        val emotionColor = Color.Black // TODO: Get emotion color using emotionalState.getColor()
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(emotionColor)
        )
        Text(
            text = "Emotion Name", // TODO: Get emotion name using emotionalState.getDisplayName()
            style = MaterialTheme.typography.body2,
            color = TextPrimary
        )
        Text(
            text = "7/10", // TODO: Display emotion intensity (e.g., '7/10')
            style = MaterialTheme.typography.caption,
            color = TextSecondary
        )
    }
}

/**
 * Composable function that displays the audio player with waveform visualization and playback controls
 * @param uiState JournalDetailUiState containing playback state and progress
 * @param onPlayPause Function to toggle play/pause
 * @param onSeek Function to seek to a specific position
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun AudioPlayerSection(
    uiState: JournalDetailUiState,
    onPlayPause: () -> Unit,
    onSeek: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Audio Recording",
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            WaveformAnimation(
                amplitudes = uiState.waveformData.toList(),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(64.dp)
            )
            Slider(
                value = uiState.playbackProgress.toFloat(),
                onValueChange = { value -> onSeek(value.toInt()) },
                valueRange = 0f..uiState.playbackDuration.toFloat(),
                modifier = Modifier.fillMaxWidth()
            )
            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = formatPlaybackTime(uiState.playbackProgress),
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
                Text(
                    text = formatPlaybackTime(uiState.playbackDuration),
                    style = MaterialTheme.typography.caption,
                    color = TextSecondary
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.fillMaxWidth()
            ) {
                IconButton(
                    onClick = onPlayPause,
                    icon = when (uiState.playbackState) {
                        is PlaybackState.Playing -> Icons.Filled.Pause
                        else -> Icons.Filled.PlayArrow
                    },
                    tint = Primary
                )
            }
        }
    }
}

/**
 * Composable function that displays insights derived from the emotional shift
 * @param emotionalShift EmotionalShift data class containing insights
 * @param modifier Modifier for styling and layout
 */
@Composable
private fun InsightsSection(
    emotionalShift: EmotionalShift,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = MaterialTheme.shapes.medium,
        elevation = 4.dp
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Insights",
                style = MaterialTheme.typography.h6,
                color = TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            emotionalShift.insights.forEach { insight ->
                Text(
                    text = insight,
                    style = MaterialTheme.typography.body2,
                    color = TextSecondary
                )
            }
        }
    }
}

/**
 * Function that formats milliseconds into a readable time string (MM:SS)
 * @param timeMs Time in milliseconds
 * @return Formatted time string
 */
private fun formatPlaybackTime(timeMs: Int): String {
    val totalSeconds = timeMs / 1000
    val minutes = totalSeconds / 60
    val remainingSeconds = totalSeconds % 60
    return String.format("%02d:%02d", minutes, remainingSeconds)
}