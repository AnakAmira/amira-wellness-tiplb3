# src/android/app/src/main/kotlin/com/amirawellness/ui/screens/emotions/EmotionalCheckinScreen.kt
```kotlin
package com.amirawellness.ui.screens.emotions

import androidx.compose.foundation.layout.* // androidx.compose.foundation.layout:1.5.0
import androidx.compose.foundation.rememberScrollState // androidx.compose.foundation:1.5.0
import androidx.compose.foundation.verticalScroll // androidx.compose.foundation:1.5.0
import androidx.compose.material.icons.Icons // androidx.compose.material.icons:1.5.0
import androidx.compose.material.icons.filled.ArrowBack // androidx.compose.material.icons:1.5.0
import androidx.compose.material3.* // androidx.compose.material3:1.1.0
import androidx.compose.runtime.* // androidx.compose.runtime:1.5.0
import androidx.compose.ui.Alignment // androidx.compose.ui:1.5.0
import androidx.compose.ui.Modifier // androidx.compose.ui:1.5.0
import androidx.compose.ui.platform.LocalContext // androidx.compose.ui.platform:1.5.0
import androidx.compose.ui.res.stringResource // androidx.compose.ui.res:1.5.0
import androidx.compose.ui.text.style.TextAlign // androidx.compose.ui.text.style:1.5.0
import androidx.compose.ui.tooling.preview.Preview // androidx.compose.ui.tooling.preview:1.5.0
import androidx.compose.ui.unit.dp // androidx.compose.ui.unit:1.5.0
import androidx.hilt.navigation.compose.hiltViewModel // androidx.hilt.navigation.compose:1.0.0
import androidx.navigation.NavController // androidx.navigation:2.7.0
import androidx.navigation.compose.rememberNavController // androidx.navigation.compose:2.7.0
import com.amirawellness.R
import com.amirawellness.core.constants.AppConstants.EmotionContext // Defined internally
import com.amirawellness.core.constants.AppConstants.EMOTION_INTENSITY_MAX // Defined internally
import com.amirawellness.core.constants.AppConstants.EMOTION_INTENSITY_MIN // Defined internally
import com.amirawellness.core.extensions.visibleIf
import com.amirawellness.ui.components.buttons.PrimaryButton // Defined internally
import com.amirawellness.ui.components.feedback.ErrorView // Defined internally
import com.amirawellness.ui.components.inputs.EmotionSelector // Defined internally
import com.amirawellness.ui.components.inputs.IntensitySlider // Defined internally
import com.amirawellness.ui.navigation.NavActions // Defined internally
import com.amirawellness.ui.screens.emotions.EmotionalCheckinViewModel // Defined internally

private const val TAG = "EmotionalCheckinScreen"

/**
 * Main composable function for the emotional check-in screen
 *
 * @param navController NavController for screen transitions
 * @param source The source context (e.g., "pre_journal", "post_journal", "standalone")
 * @param journalId Optional journal ID if the check-in is related to a journal entry
 * @param toolId Optional tool ID if the check-in is related to a tool usage
 */
@Composable
fun EmotionalCheckinScreen(
    navController: NavController,
    source: String,
    journalId: String? = null,
    toolId: String? = null
) {
    // LD1: Get the ViewModel using hiltViewModel()
    val viewModel: EmotionalCheckinViewModel = hiltViewModel()

    // LD1: Create NavActions instance with the provided NavController
    val navActions = remember { NavActions(navController) }

    // LD1: Get the current context for resource access
    val context = LocalContext.current

    // LD1: Determine the emotion context based on the source parameter
    val emotionContext = remember(source) {
        when (source) {
            "pre_journal" -> EmotionContext.PRE_JOURNALING
            "post_journal" -> EmotionContext.POST_JOURNALING
            "tool_usage" -> EmotionContext.TOOL_USAGE
            else -> EmotionContext.STANDALONE
        }
    }

    // LD1: Get the current user ID from preferences or authentication
    // TODO: Replace with actual user ID retrieval logic
    val userId = remember { "testUserId" }

    // LD1: Initialize the check-in with the user ID, context, and related IDs
    LaunchedEffect(userId, emotionContext, journalId, toolId) {
        viewModel.initializeCheckin(
            userId = userId,
            context = emotionContext,
            relatedJournalId = journalId,
            relatedToolId = toolId
        )
    }

    // LD1: Collect the UI state from the ViewModel
    val state by viewModel.uiState.collectAsState()

    // LD1: Create a Scaffold with a TopAppBar containing a back button
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.emotional_checkin)) },
                navigationIcon = {
                    IconButton(onClick = { navActions.navigateBack() }) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        // LD1: Display an error view when error is not null
        ErrorView(
            message = state.error?.message ?: "",
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .visibleIf(state.error != null)
        )

        // LD1: Display the main content when not loading and no error
        if (!state.isLoading && state.error == null) {
            EmotionalCheckinContent(
                state = state,
                onEmotionSelected = { emotionType -> viewModel.updateEmotionType(emotionType) },
                onIntensityChanged = { intensity -> viewModel.updateIntensity(intensity) },
                onNotesChanged = { notes -> viewModel.updateNotes(notes) },
                onSubmit = {
                    viewModel.submitCheckin()
                    // TODO: Handle navigation based on the result of the check-in
                    navActions.navigateToEmotionalCheckinResult()
                },
                modifier = Modifier
                    .padding(paddingValues)
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            )
        }
    }
}

/**
 * Composable function for the main content of the emotional check-in screen
 *
 * @param state The current UI state
 * @param onEmotionSelected Callback function for emotion selection
 * @param onIntensityChanged Callback function for intensity changes
 * @param onNotesChanged Callback function for notes changes
 * @param onSubmit Callback function for submitting the check-in
 * @param modifier Modifier for the content
 */
@Composable
private fun EmotionalCheckinContent(
    state: EmotionalCheckinState,
    onEmotionSelected: (EmotionType) -> Unit,
    onIntensityChanged: (Int) -> Unit,
    onNotesChanged: (String) -> Unit,
    onSubmit: () -> Unit,
    modifier: Modifier = Modifier
) {
    // LD1: Create a Column with vertical arrangement and horizontal alignment
    Column(
        modifier = modifier
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // LD1: Add a title Text based on the emotion context
        Text(
            text = stringResource(id = getContextTitle(state.context)),
            style = MaterialTheme.typography.h6,
            textAlign = TextAlign.Center
        )

        // LD1: Add a subtitle Text with instructions
        Text(
            text = stringResource(id = getContextSubtitle(state.context)),
            style = MaterialTheme.typography.body2,
            textAlign = TextAlign.Center
        )

        // LD1: Add the EmotionSelector component with the current selected emotion
        EmotionSelector(
            selectedEmotion = state.selectedEmotionType,
            onEmotionSelected = onEmotionSelected,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add a Spacer for vertical spacing
        Spacer(modifier = Modifier.height(8.dp))

        // LD1: Add a Text label for the intensity section
        Text(
            text = stringResource(id = R.string.intensity),
            style = MaterialTheme.typography.subtitle1,
            textAlign = TextAlign.Start,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add the IntensitySlider component with the current intensity value
        IntensitySlider(
            value = state.intensity,
            onValueChange = onIntensityChanged,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add a Spacer for vertical spacing
        Spacer(modifier = Modifier.height(8.dp))

        // LD1: Add a Text label for the optional notes section
        Text(
            text = stringResource(id = R.string.notes_optional),
            style = MaterialTheme.typography.subtitle1,
            textAlign = TextAlign.Start,
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add an OutlinedTextField for notes input
        OutlinedTextField(
            value = state.notes,
            onValueChange = onNotesChanged,
            label = { Text(stringResource(id = R.string.notes)) },
            modifier = Modifier.fillMaxWidth()
        )

        // LD1: Add a Spacer for vertical spacing
        Spacer(modifier = Modifier.height(16.dp))

        // LD1: Add a PrimaryButton for submitting the check-in
        PrimaryButton(
            text = stringResource(id = R.string.submit),
            onClick = onSubmit,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/**
 * Returns the appropriate title based on the emotion context
 *
 * @param context The emotion context
 * @return String resource ID for the title
 */
private fun getContextTitle(context: EmotionContext): Int {
    // LD1: Use a when expression to match the context to the appropriate string resource
    return when (context) {
        EmotionContext.PRE_JOURNALING -> R.string.emotional_checkin_pre_journaling_title
        EmotionContext.POST_JOURNALING -> R.string.emotional_checkin_post_journaling_title
        EmotionContext.TOOL_USAGE -> R.string.emotional_checkin_tool_usage_title
        EmotionContext.STANDALONE -> R.string.emotional_checkin_standalone_title
    }
}

/**
 * Returns the appropriate subtitle based on the emotion context
 *
 * @param context The emotion context
 * @return String resource ID for the subtitle
 */
private fun getContextSubtitle(context: EmotionContext): Int {
    // LD1: Use a when expression to match the context to the appropriate string resource
    return when (context) {
        EmotionContext.PRE_JOURNALING -> R.string.emotional_checkin_pre_journaling_subtitle
        EmotionContext.POST_JOURNALING -> R.string.emotional_checkin_post_journaling_subtitle
        EmotionContext.TOOL_USAGE -> R.string.emotional_checkin_tool_usage_subtitle
        EmotionContext.STANDALONE -> R.string.emotional_checkin_standalone_subtitle
    }
}

/**
 * Preview function for the emotional check-in screen
 */
@Preview
@Composable
fun EmotionalCheckinPreview() {
    // LD1: Create a preview of the EmotionalCheckinContent
    // LD1: Use a sample EmotionalCheckinState with default values
    // LD1: Provide empty callback functions
    // LD1: Apply appropriate preview parameters
    MaterialTheme {
        Surface {
            EmotionalCheckinContent(
                state = EmotionalCheckinState(),
                onEmotionSelected = {},
                onIntensityChanged = {},
                onNotesChanged = {},
                onSubmit = {},
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}