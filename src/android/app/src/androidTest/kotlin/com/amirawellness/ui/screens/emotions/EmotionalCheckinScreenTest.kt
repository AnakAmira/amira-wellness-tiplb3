# src/android/app/src/androidTest/kotlin/com/amirawellness/ui/screens/emotions/EmotionalCheckinScreenTest.kt
```kotlin
package com.amirawellness.ui.screens.emotions

import androidx.compose.ui.test.junit4.createAndroidComposeRule // androidx.compose.ui.test.junit4:1.5.0
import androidx.compose.ui.test.onNodeWithText // androidx.compose.ui.test:1.5.0
import androidx.compose.ui.test.onNodeWithContentDescription // androidx.compose.ui.test:1.5.0
import androidx.compose.ui.test.performClick // androidx.compose.ui.test:1.5.0
import androidx.compose.ui.test.performTextInput // androidx.compose.ui.test:1.5.0
import androidx.compose.ui.test.assertIsDisplayed // androidx.compose.ui.test:1.5.0
import androidx.compose.ui.test.assertIsEnabled // androidx.compose.ui.test:1.5.0
import androidx.compose.ui.test.assertIsSelected // androidx.compose.ui.test:1.5.0
import androidx.test.ext.junit.runners.AndroidJUnit4 // androidx.test.ext.junit.runners:1.1.5
import org.junit.Rule // org.junit:4.13.2
import org.junit.Test // org.junit:4.13.2
import org.junit.Before // org.junit:4.13.2
import org.junit.runner.RunWith // org.junit:4.13.2
import dagger.hilt.android.testing.HiltAndroidTest // dagger.hilt.android.testing:2.44
import dagger.hilt.android.testing.HiltAndroidRule // dagger.hilt.android.testing:2.44
import com.amirawellness.core.constants.AppConstants.EmotionContext // Defined internally
import com.amirawellness.ui.screens.emotions.EmotionalCheckinScreen // Defined internally

private const val TAG = "EmotionalCheckinScreenTest"

/**
 * Test class for the EmotionalCheckinScreen composable
 */
@RunWith(AndroidJUnit4::class)
@HiltAndroidTest
class EmotionalCheckinScreenTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<ComponentActivity>()

    /**
     * Sets up the test environment before each test
     */
    @Before
    fun setup() {
        // Initialize any test dependencies
        hiltRule.inject()

        // Set up test data
        // No specific test data setup needed for this test
    }

    /**
     * Tests the emotional check-in screen in standalone mode
     */
    @Test
    fun testEmotionalCheckinScreenStandaloneMode() {
        // Launch the EmotionalCheckinScreen with STANDALONE context
        composeTestRule.setContent {
            EmotionalCheckinScreen(
                navController = rememberNavController(),
                source = EmotionContext.STANDALONE.name
            )
        }

        // Verify the title text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_standalone_title))
            .assertIsDisplayed()

        // Verify the subtitle text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_standalone_subtitle))
            .assertIsDisplayed()

        // Verify the emotion selector is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_content_description, "Alegría"))
            .assertIsDisplayed()

        // Select an emotion and verify it's selected
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotion_joy))
            .performClick()
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_selected_content_description, "Alegría"))
            .assertIsSelected()

        // Verify the intensity slider is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.intensity))
            .assertIsDisplayed()

        // Adjust the intensity slider and verify the value changes
        // TODO: Implement slider adjustment and value verification

        // Verify the notes field is displayed
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes_optional))
            .assertIsDisplayed()

        // Enter text in the notes field and verify it's updated
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes))
            .performTextInput("Test notes")
        // TODO: Verify the text input is updated

        // Verify the submit button is displayed and enabled
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.submit))
            .assertIsDisplayed()
            .assertIsEnabled()

        // Click the submit button
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.submit))
            .performClick()

        // Verify navigation to the results screen
        // TODO: Implement navigation verification
    }

    /**
     * Tests the emotional check-in screen in pre-journaling mode
     */
    @Test
    fun testEmotionalCheckinScreenPreJournalingMode() {
        // Launch the EmotionalCheckinScreen with PRE_JOURNALING context
        composeTestRule.setContent {
            EmotionalCheckinScreen(
                navController = rememberNavController(),
                source = EmotionContext.PRE_JOURNALING.name
            )
        }

        // Verify the pre-journaling title text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_pre_journaling_title))
            .assertIsDisplayed()

        // Verify the pre-journaling subtitle text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_pre_journaling_subtitle))
            .assertIsDisplayed()

        // Verify the emotion selector is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_content_description, "Alegría"))
            .assertIsDisplayed()

        // Select an emotion and verify it's selected
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotion_joy))
            .performClick()
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_selected_content_description, "Alegría"))
            .assertIsSelected()

        // Verify the intensity slider is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.intensity))
            .assertIsDisplayed()

        // Adjust the intensity slider and verify the value changes
        // TODO: Implement slider adjustment and value verification

        // Verify the notes field is displayed
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes_optional))
            .assertIsDisplayed()

        // Enter text in the notes field and verify it's updated
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes))
            .performTextInput("Test notes")
        // TODO: Verify the text input is updated

        // Verify the continue button is displayed and enabled
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.continue_button))
            .assertIsDisplayed()
            .assertIsEnabled()

        // Click the continue button
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.continue_button))
            .performClick()

        // Verify navigation to the recording screen
        // TODO: Implement navigation verification
    }

    /**
     * Tests the emotional check-in screen in post-journaling mode
     */
    @Test
    fun testEmotionalCheckinScreenPostJournalingMode() {
        // Launch the EmotionalCheckinScreen with POST_JOURNALING context and a journal ID
        composeTestRule.setContent {
            EmotionalCheckinScreen(
                navController = rememberNavController(),
                source = EmotionContext.POST_JOURNALING.name,
                journalId = "testJournalId"
            )
        }

        // Verify the post-journaling title text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_post_journaling_title))
            .assertIsDisplayed()

        // Verify the post-journaling subtitle text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_post_journaling_subtitle))
            .assertIsDisplayed()

        // Verify the emotion selector is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_content_description, "Alegría"))
            .assertIsDisplayed()

        // Select an emotion and verify it's selected
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotion_joy))
            .performClick()
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_selected_content_description, "Alegría"))
            .assertIsSelected()

        // Verify the intensity slider is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.intensity))
            .assertIsDisplayed()

        // Adjust the intensity slider and verify the value changes
        // TODO: Implement slider adjustment and value verification

        // Verify the notes field is displayed
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes_optional))
            .assertIsDisplayed()

        // Enter text in the notes field and verify it's updated
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes))
            .performTextInput("Test notes")
        // TODO: Verify the text input is updated

        // Verify the save button is displayed and enabled
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.save))
            .assertIsDisplayed()
            .assertIsEnabled()

        // Click the save button
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.save))
            .performClick()

        // Verify navigation to the journal saved confirmation screen
        // TODO: Implement navigation verification
    }

    /**
     * Tests the emotional check-in screen in tool usage mode
     */
    @Test
    fun testEmotionalCheckinScreenToolUsageMode() {
        // Launch the EmotionalCheckinScreen with TOOL_USAGE context and a tool ID
        composeTestRule.setContent {
            EmotionalCheckinScreen(
                navController = rememberNavController(),
                source = EmotionContext.TOOL_USAGE.name,
                toolId = "testToolId"
            )
        }

        // Verify the tool usage title text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_tool_usage_title))
            .assertIsDisplayed()

        // Verify the tool usage subtitle text is displayed correctly
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotional_checkin_tool_usage_subtitle))
            .assertIsDisplayed()

        // Verify the emotion selector is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_content_description, "Alegría"))
            .assertIsDisplayed()

        // Select an emotion and verify it's selected
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.emotion_joy))
            .performClick()
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.emotion_selected_content_description, "Alegría"))
            .assertIsSelected()

        // Verify the intensity slider is displayed
        composeTestRule.onNodeWithContentDescription(composeTestRule.activity.getString(R.string.intensity))
            .assertIsDisplayed()

        // Adjust the intensity slider and verify the value changes
        // TODO: Implement slider adjustment and value verification

        // Verify the notes field is displayed
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes_optional))
            .assertIsDisplayed()

        // Enter text in the notes field and verify it's updated
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.notes))
            .performTextInput("Test notes")
        // TODO: Verify the text input is updated

        // Verify the save button is displayed and enabled
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.save))
            .assertIsDisplayed()
            .assertIsEnabled()

        // Click the save button
        composeTestRule.onNodeWithText(composeTestRule.activity.getString(R.string.save))
            .performClick()

        // Verify navigation to the tool completion screen
        // TODO: Implement navigation verification
    }

    /**
     * Tests that the back button navigates correctly
     */
    @Test
    fun testBackButtonNavigation() {
        // Launch the EmotionalCheckinScreen in any context
        composeTestRule.setContent {
            EmotionalCheckinScreen(
                navController = rememberNavController(),
                source = EmotionContext.STANDALONE.name
            )
        }

        // Verify the back button is displayed
        composeTestRule.onNodeWithContentDescription("Back")
            .assertIsDisplayed()

        // Click the back button
        composeTestRule.onNodeWithContentDescription("Back")
            .performClick()

        // Verify navigation back to the previous screen
        // TODO: Implement navigation verification
    }

    /**
     * Tests that errors are displayed correctly
     */
    @Test
    fun testErrorState() {
        // Launch the EmotionalCheckinScreen with a mocked error state
        composeTestRule.setContent {
            // TODO: Mock the ViewModel to simulate an error state
            // Example:
            /*
            val viewModel = object : EmotionalCheckinViewModel() {
                override val uiState: StateFlow<EmotionalCheckinState> = MutableStateFlow(
                    EmotionalCheckinState(error = Exception("Test error message"))
                )
            }
            EmotionalCheckinScreen(
                navController = rememberNavController(),
                viewModel = viewModel
            )
            */
        }

        // Verify the error view is displayed
        // TODO: Implement error view verification

        // Verify the error message is displayed correctly
        // TODO: Implement error message verification
    }
}