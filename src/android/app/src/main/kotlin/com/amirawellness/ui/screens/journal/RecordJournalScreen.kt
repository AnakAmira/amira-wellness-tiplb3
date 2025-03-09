package com.amirawellness.ui.screens.journal

import android.Manifest // android version: latest
import androidx.activity.compose.rememberLauncherForActivityResult // androidx.activity.compose:activity-compose:1.7.2
import androidx.activity.result.contract.ActivityResultContracts // androidx.activity.compose:activity-compose:1.7.2
import androidx.compose.foundation.background // androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.border // androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.* // androidx.compose.foundation:foundation:1.5.0
import androidx.compose.material.* // androidx.compose.material:material:1.5.0
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.runtime.* // androidx.compose.runtime:runtime:1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.draw.clip // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.graphics.Color // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.res.painterResource // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.tooling.preview.Preview // androidx.compose.ui:ui-tooling-preview:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui:ui-unit:1.5.0
import androidx.compose.ui.unit.sp // androidx.compose.ui:ui-unit:1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt:hilt-navigation-compose:1.0.0
import androidx.navigation.NavController // androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.compose.rememberNavController // androidx.navigation:navigation-compose:2.7.0
import com.amirawellness.R
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.extensions.formatDuration
import com.amirawellness.services.audio.RecordingState
import com.amirawellness.ui.components.animations.LiveWaveformAnimation
import com.amirawellness.ui.components.buttons.IconButton
import com.amirawellness.ui.components.buttons.PrimaryButton
import com.amirawellness.ui.components.buttons.SecondaryButton
import com.amirawellness.ui.components.feedback.ErrorView
import com.amirawellness.ui.components.feedback.SuccessView
import com.amirawellness.ui.components.inputs.EmotionSelector
import com.amirawellness.ui.components.inputs.IntensitySlider
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.screens.journal.RecordJournalViewModel
import com.amirawellness.ui.screens.journal.RecordJournalUiState
import com.amirawellness.ui.theme.* // project-level

private const val TAG = "RecordJournalScreen"

/**
 * Main composable function for the voice journal recording screen
 *
 * @param navController NavController for screen transitions
 * @param userId User ID to associate with the journal
 */
@Composable
fun RecordJournalScreen(
    navController: NavController,
    userId: String
) {
    // LD1: Get the RecordJournalViewModel using hiltViewModel()
    val viewModel: RecordJournalViewModel = hiltViewModel()

    // LD1: Set the user ID in the ViewModel
    LaunchedEffect(key1 = userId) {
        viewModel.setUserId(userId)
    }

    // LD1: Create NavActions with the provided NavController
    val navActions = remember { NavActions(navController) }

    // LD1: Collect the UI state from the ViewModel
    val uiState by viewModel.uiState.collectAsState()

    // LD1: Set up permission request launcher for audio recording
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { isGranted ->
            // LD1: Update the permission state in the ViewModel based on the result
            if (isGranted) {
                viewModel.checkPermissions()
            }
        }
    )

    // LD1: Check for recording permissions when the screen is first displayed
    LaunchedEffect(key1 = Unit) {
        viewModel.checkPermissions()
    }

    // LD1: Create a Scaffold with a TopAppBar for navigation
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.record_journal_title)) },
                navigationIcon = {
                    IconButton(
                        onClick = {
                            // LD1: Handle back button press with proper cleanup
                            viewModel.cancelRecording()
                            navActions.navigateBack()
                        },
                        icon = Icons.Filled.ArrowBack,
                        contentDescription = stringResource(id = R.string.back)
                    )
                }
            )
        }
    ) { paddingValues ->
        // LD1: Implement the screen content based on the current UI state
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
                .background(MaterialTheme.colors.surface),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // LD1: Show loading indicator when isLoading is true
            if (uiState.isLoading) {
                // TODO: Implement loading indicator
                Text(text = "Loading...")
            }

            // LD1: Show ErrorView when isError is true
            if (uiState.isError && uiState.message != null) {
                ErrorView(
                    message = uiState.message,
                    onAction = { viewModel.clearMessage() }
                )
            }

            // LD1: Show SuccessView when savedJournal is not null
            if (uiState.savedJournal != null) {
                JournalSavedContent(
                    uiState = uiState,
                    onViewJournal = {
                        // TODO: Implement navigation to journal detail
                    },
                    onBackToJournals = { navActions.navigateBack() }
                )
            } else {
                // LD1: Show appropriate UI based on recording state (PreRecording, Recording, PostRecording)
                when (uiState.recordingState) {
                    is RecordingState.Idle -> {
                        if (uiState.permissionGranted) {
                            PreRecordingContent(
                                uiState = uiState,
                                onEmotionSelected = { emotion ->
                                    viewModel.updatePreEmotionalState(emotion, 5, null)
                                },
                                onIntensityChanged = { intensity ->
                                    viewModel.updatePreEmotionalState(
                                        uiState.preEmotionalState?.emotionType ?: EmotionType.JOY,
                                        intensity,
                                        uiState.preEmotionalState?.notes
                                    )
                                },
                                onNotesChanged = { notes ->
                                    viewModel.updatePreEmotionalState(
                                        uiState.preEmotionalState?.emotionType ?: EmotionType.JOY,
                                        uiState.preEmotionalState?.intensity ?: 5,
                                        notes
                                    )
                                },
                                onStartRecording = { viewModel.startRecording() }
                            )
                        } else {
                            PermissionRequestContent {
                                permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                            }
                        }
                    }

                    is RecordingState.Preparing, is RecordingState.Recording, is RecordingState.Paused -> {
                        RecordingContent(
                            uiState = uiState,
                            onPauseRecording = { viewModel.pauseRecording() },
                            onResumeRecording = { viewModel.resumeRecording() },
                            onStopRecording = { viewModel.stopRecording() },
                            onCancelRecording = { viewModel.cancelRecording() }
                        )
                    }

                    is RecordingState.Completed -> {
                        PostRecordingContent(
                            uiState = uiState,
                            onEmotionSelected = { emotion ->
                                viewModel.updatePostEmotionalState(emotion, 5, null)
                            },
                            onIntensityChanged = { intensity ->
                                viewModel.updatePostEmotionalState(
                                    uiState.postEmotionalState?.emotionType ?: EmotionType.JOY,
                                    intensity,
                                    uiState.postEmotionalState?.notes
                                )
                            },
                            onNotesChanged = { notes ->
                                viewModel.updatePostEmotionalState(
                                    uiState.postEmotionalState?.emotionType ?: EmotionType.JOY,
                                    uiState.postEmotionalState?.intensity ?: 5,
                                    notes
                                )
                            },
                            onSaveJournal = { viewModel.saveJournal("My Journal") },
                            onCancelRecording = { viewModel.cancelRecording() }
                        )
                    }

                    is RecordingState.Error -> {
                        // TODO: Implement error handling UI
                        Text(text = "Error: ${uiState.recordingState.toString()}")
                    }
                }
            }
        }
    }
}

/**
 * Composable function for the pre-recording emotional check-in UI
 */
@Composable
private fun PreRecordingContent(
    uiState: RecordJournalUiState,
    onEmotionSelected: (EmotionType) -> Unit,
    onIntensityChanged: (Int) -> Unit,
    onNotesChanged: (String) -> Unit,
    onStartRecording: () -> Unit
) {
    // LD1: Create a Column layout for the content
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // LD1: Add a title text for the pre-recording check-in
        Text(
            text = stringResource(id = R.string.pre_recording_checkin_title),
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        // LD1: Add a description text explaining the purpose of the check-in
        Text(
            text = stringResource(id = R.string.pre_recording_checkin_description),
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )

        // LD1: Add EmotionSelector component for selecting the emotion
        EmotionSelector(
            selectedEmotion = uiState.preEmotionalState?.emotionType,
            onEmotionSelected = onEmotionSelected,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add IntensitySlider component for selecting the emotion intensity
        IntensitySlider(
            value = uiState.preEmotionalState?.intensity ?: 5,
            onValueChange = onIntensityChanged,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add TextField for optional notes
        OutlinedTextField(
            value = uiState.preEmotionalState?.notes ?: "",
            onValueChange = onNotesChanged,
            label = { Text(stringResource(id = R.string.notes_optional)) },
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add PrimaryButton to start recording when ready
        PrimaryButton(
            text = stringResource(id = R.string.start_recording),
            onClick = onStartRecording,
            enabled = uiState.preEmotionalState != null // LD1: Disable the start button if no emotion is selected
        )
    }
}

/**
 * Composable function for the recording in progress UI
 */
@Composable
private fun RecordingContent(
    uiState: RecordJournalUiState,
    onPauseRecording: () -> Unit,
    onResumeRecording: () -> Unit,
    onStopRecording: () -> Unit,
    onCancelRecording: () -> Unit
) {
    // LD1: Create a Column layout for the content
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // LD1: Add a title text for the recording screen
        Text(
            text = stringResource(id = R.string.recording_title),
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        // LD1: Add LiveWaveformAnimation to visualize the audio recording
        LiveWaveformAnimation(
            currentAmplitude = uiState.currentAmplitude,
            modifier = Modifier
                .fillMaxWidth()
                .height(120.dp)
        )

        // LD1: Display the current recording duration formatted as MM:SS
        Text(
            text = formatDuration(uiState.recordingDuration),
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center
        )

        // LD1: Add recording control buttons in a Row layout
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            // LD1: Show pause/resume button based on current recording state
            if (uiState.recordingState is RecordingState.Recording) {
                PrimaryButton(
                    text = stringResource(id = R.string.pause),
                    onClick = onPauseRecording
                )
            } else if (uiState.recordingState is RecordingState.Paused) {
                PrimaryButton(
                    text = stringResource(id = R.string.resume),
                    onClick = onResumeRecording
                )
            }

            // LD1: Add stop button to finish recording
            SecondaryButton(
                text = stringResource(id = R.string.stop),
                onClick = onStopRecording
            )

            // LD1: Add cancel button to discard recording
            SecondaryButton(
                text = stringResource(id = R.string.cancel),
                onClick = onCancelRecording
            )
        }

        // LD1: Add tips section with helpful recording suggestions
        Text(
            text = stringResource(id = R.string.recording_tips),
            style = MaterialTheme.typography.caption,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Composable function for the post-recording emotional check-in UI
 */
@Composable
private fun PostRecordingContent(
    uiState: RecordJournalUiState,
    onEmotionSelected: (EmotionType) -> Unit,
    onIntensityChanged: (Int) -> Unit,
    onNotesChanged: (String) -> Unit,
    onSaveJournal: () -> Unit,
    onCancelRecording: () -> Unit
) {
    // LD1: Create a Column layout for the content
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // LD1: Add a title text for the post-recording check-in
        Text(
            text = stringResource(id = R.string.post_recording_checkin_title),
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        // LD1: Add a description text explaining the purpose of the check-in
        Text(
            text = stringResource(id = R.string.post_recording_checkin_description),
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )

        // LD1: Add EmotionSelector component for selecting the emotion
        EmotionSelector(
            selectedEmotion = uiState.postEmotionalState?.emotionType,
            onEmotionSelected = onEmotionSelected,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add IntensitySlider component for selecting the emotion intensity
        IntensitySlider(
            value = uiState.postEmotionalState?.intensity ?: 5,
            onValueChange = onIntensityChanged,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add TextField for optional notes
        OutlinedTextField(
            value = uiState.postEmotionalState?.notes ?: "",
            onValueChange = onNotesChanged,
            label = { Text(stringResource(id = R.string.notes_optional)) },
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add PrimaryButton to save the journal
        PrimaryButton(
            text = stringResource(id = R.string.save),
            onClick = onSaveJournal,
            enabled = uiState.postEmotionalState != null, // LD1: Disable the save button if no emotion is selected
            isLoading = uiState.isSaving // LD1: Show loading indicator when saving is in progress
        )

        // LD1: Add SecondaryButton to cancel and discard the recording
        SecondaryButton(
            text = stringResource(id = R.string.cancel),
            onClick = onCancelRecording
        )
    }
}

/**
 * Composable function for the journal saved success UI
 */
@Composable
private fun JournalSavedContent(
    uiState: RecordJournalUiState,
    onViewJournal: () -> Unit,
    onBackToJournals: () -> Unit
) {
    // LD1: Create a Column layout for the content
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // LD1: Add SuccessView component to show success animation
        SuccessView(message = "Journal saved successfully")

        // LD1: Add a title text confirming the journal was saved
        Text(
            text = stringResource(id = R.string.journal_saved_title),
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        // LD1: Display emotional shift information (before and after emotions)
        Text(
            text = "Emotional shift: ${uiState.preEmotionalState?.emotionType} -> ${uiState.postEmotionalState?.emotionType}",
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )

        // LD1: Add PrimaryButton to view the saved journal details
        PrimaryButton(
            text = stringResource(id = R.string.view_journal),
            onClick = onViewJournal
        )

        // LD1: Add SecondaryButton to return to the journal list
        SecondaryButton(
            text = stringResource(id = R.string.back_to_journals),
            onClick = onBackToJournals
        )
    }
}

/**
 * Composable function for the permission request UI
 */
@Composable
private fun PermissionRequestContent(
    onRequestPermission: () -> Unit
) {
    // LD1: Create a Column layout for the content
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // TODO: Add an icon representing microphone/recording
        // LD1: Add an icon representing microphone/recording
        Icon(
            painter = painterResource(id = R.drawable.ic_mic),
            contentDescription = "Microphone",
            modifier = Modifier.size(48.dp)
        )

        // LD1: Add a title text explaining the need for microphone permission
        Text(
            text = stringResource(id = R.string.permission_required_title),
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        // LD1: Add a description text with more details about permission usage
        Text(
            text = stringResource(id = R.string.permission_required_description),
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )

        // LD1: Add PrimaryButton to request the permission
        PrimaryButton(
            text = stringResource(id = R.string.request_permission),
            onClick = onRequestPermission
        )
    }
}

/**
 * Preview function for the RecordJournalScreen
 */
@Composable
@Preview
fun RecordJournalScreenPreview() {
    // LD1: Create a preview of the RecordJournalScreen with mock data
    // LD1: Use a dummy NavController
    val navController = rememberNavController()
    // LD1: Use a sample user ID
    val userId = "sample_user_id"
    RecordJournalScreen(navController = navController, userId = userId)
}