package com.amirawellness.ui.screens.journal

import androidx.compose.ui.test.junit4.createComposeRule // androidx.compose.ui:ui-test-junit4:1.5.0
import androidx.compose.ui.test.junit4.ComposeTestRule // androidx.compose.ui:ui-test-junit4:1.5.0
import androidx.compose.ui.test.onNodeWithText // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.onNodeWithTag // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.onNodeWithContentDescription // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.assertIsDisplayed // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.assertIsEnabled // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.assertIsNotEnabled // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.performClick // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.performTextInput // androidx.compose.ui:ui-test:1.5.0
import androidx.compose.ui.test.assertTextEquals // androidx.compose.ui:ui-test:1.5.0
import androidx.test.ext.junit.runners.AndroidJUnit4 // androidx.test.ext.junit:junit:1.1.5
import org.junit.Rule // org.junit:junit:4.13.2
import org.junit.Test // org.junit:junit:4.13.2
import org.junit.Before // org.junit:junit:4.13.2
import org.junit.runner.RunWith // org.junit:junit:4.13.2
import org.mockito.Mockito // org.mockito:mockito-core:4.0.0
import org.mockito.Mock // org.mockito:mockito-core:4.0.0
import dagger.hilt.android.testing.HiltAndroidRule // dagger.hilt:hilt-android-testing:2.44
import dagger.hilt.android.testing.HiltAndroidTest // dagger.hilt:hilt-android-testing:2.44
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import android.content.Context // android version: latest
import java.util.UUID // java.util version: standard library
import com.amirawellness.ui.screens.journal.RecordJournalScreen // project-level
import com.amirawellness.ui.screens.journal.RecordJournalViewModel // project-level
import com.amirawellness.ui.screens.journal.RecordJournalUiState // project-level
import com.amirawellness.services.audio.RecordingState // project-level
import com.amirawellness.core.constants.AppConstants.EmotionType // project-level
import com.amirawellness.ui.navigation.NavActions // project-level
import com.amirawellness.data.models.Journal // project-level
import com.amirawellness.data.models.EmotionalState // project-level
import com.amirawellness.services.audio.AudioRecordingService // project-level
import com.amirawellness.domain.usecases.journal.CreateJournalUseCase // project-level
import com.amirawellness.domain.usecases.emotional.RecordEmotionalStateUseCase // project-level

/**
 * UI tests for the voice journal recording screen in the Amira Wellness Android application
 */
@RunWith(AndroidJUnit4::class)
@HiltAndroidTest
class RecordJournalScreenTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @get:Rule
    val composeTestRule: ComposeTestRule = createComposeRule()

    @Mock
    lateinit var mockNavActions: NavActions

    @Mock
    lateinit var mockAudioRecordingService: AudioRecordingService

    @Mock
    lateinit var mockCreateJournalUseCase: CreateJournalUseCase

    @Mock
    lateinit var mockRecordEmotionalStateUseCase: RecordEmotionalStateUseCase

    lateinit var viewModel: RecordJournalViewModel

    val testUserId = "test-user-id"
    val testJournalId = UUID.randomUUID().toString()

    @Before
    fun setUp() {
        hiltRule.inject()

        Mockito.`when`(mockNavActions.navigateBack()).then {}
        Mockito.`when`(mockNavActions.navigateToJournalList()).then {}
        Mockito.`when`(mockNavActions.navigateToJournalDetail(testJournalId)).then {}

        viewModel = RecordJournalViewModel(
            context = Mockito.mock(Context::class.java),
            audioRecordingService = mockAudioRecordingService,
            createJournalUseCase = mockCreateJournalUseCase,
            recordEmotionalStateUseCase = mockRecordEmotionalStateUseCase
        )

        composeTestRule.setContent {
            RecordJournalScreen(
                navController = Mockito.mock(androidx.navigation.NavController::class.java),
                userId = testUserId
            )
        }

        viewModel.setUserId(testUserId)
    }

    @Test
    fun testRecordJournalScreenInitialState() {
        val uiState = RecordJournalUiState(permissionGranted = true)
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Diario de voz").assertIsDisplayed()
        composeTestRule.onNodeWithText("¿Cómo te sientes antes de grabar?").assertIsDisplayed()
        composeTestRule.onNodeWithTag("emotion_selector").assertIsDisplayed()
        composeTestRule.onNodeWithTag("intensity_slider").assertIsDisplayed()
        composeTestRule.onNodeWithText("Notas (opcional):").assertIsDisplayed()
        composeTestRule.onNodeWithText("Comenzar").assertIsNotEnabled()
    }

    @Test
    fun testPermissionRequest() {
        val uiState = RecordJournalUiState(permissionGranted = false)
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Permiso requerido").assertIsDisplayed()
        composeTestRule.onNodeWithText("Esta función requiere permisos adicionales para funcionar correctamente.").assertIsDisplayed()
        composeTestRule.onNodeWithText("Solicitar permiso").assertIsDisplayed()

        composeTestRule.onNodeWithText("Solicitar permiso").performClick()
        Mockito.verify(mockAudioRecordingService, Mockito.times(0)).getRecordingState()
    }

    @Test
    fun testPreRecordingEmotionSelection() {
        val uiState = RecordJournalUiState(permissionGranted = true)
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithTag("emotion_selector").performClick()
        Mockito.verify(mockRecordEmotionalStateUseCase, Mockito.times(0)).invoke(
            Mockito.anyString(),
            Mockito.any(EmotionType::class.java),
            Mockito.anyInt(),
            Mockito.anyString(),
            Mockito.anyString(),
            Mockito.anyString(),
            Mockito.anyString()
        )

        val updatedUiState = uiState.copy(preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"))
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("Comenzar").assertIsEnabled()
    }

    @Test
    fun testPreRecordingIntensitySelection() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithTag("intensity_slider").performTextInput("7")
        Mockito.verify(mockRecordEmotionalStateUseCase, Mockito.times(0)).invoke(
            Mockito.anyString(),
            Mockito.any(EmotionType::class.java),
            Mockito.anyInt(),
            Mockito.anyString(),
            Mockito.anyString(),
            Mockito.anyString(),
            Mockito.anyString()
        )
    }

    @Test
    fun testStartRecording() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Comenzar").performClick()
        Mockito.verify(mockAudioRecordingService, Mockito.times(1)).startRecording(Mockito.anyString())

        val updatedUiState = uiState.copy(recordingState = RecordingState.Recording(Mockito.mock(java.io.File::class.java), 1234))
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("Pausar").assertIsDisplayed()
        composeTestRule.onNodeWithText("Detener").assertIsDisplayed()
    }

    @Test
    fun testPauseAndResumeRecording() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"), recordingState = RecordingState.Recording(Mockito.mock(java.io.File::class.java), 1234))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Pausar").performClick()
        Mockito.verify(mockAudioRecordingService, Mockito.times(1)).pauseRecording()

        val updatedUiState = uiState.copy(recordingState = RecordingState.Paused(Mockito.mock(java.io.File::class.java), 1234, 1234, 1234))
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("Reanudar").assertIsDisplayed()
        composeTestRule.onNodeWithText("Reanudar").performClick()
        Mockito.verify(mockAudioRecordingService, Mockito.times(1)).resumeRecording()
    }

    @Test
    fun testStopRecording() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"), recordingState = RecordingState.Recording(Mockito.mock(java.io.File::class.java), 1234))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Detener").performClick()
        Mockito.verify(mockAudioRecordingService, Mockito.times(1)).stopRecording()

        val updatedUiState = uiState.copy(recordingState = RecordingState.Completed(Mockito.mock(java.io.File::class.java), 1234, 1234, 1234))
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("¿Cómo te sientes después de grabar?").assertIsDisplayed()
        composeTestRule.onNodeWithTag("emotion_selector").assertIsDisplayed()
        composeTestRule.onNodeWithTag("intensity_slider").assertIsDisplayed()
        composeTestRule.onNodeWithText("Guardar").assertIsNotEnabled()
    }

    @Test
    fun testCancelRecording() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"), recordingState = RecordingState.Recording(Mockito.mock(java.io.File::class.java), 1234))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Cancelar").performClick()
        Mockito.verify(mockAudioRecordingService, Mockito.times(1)).cancelRecording()

        val updatedUiState = uiState.copy(recordingState = RecordingState.Idle)
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("¿Cómo te sientes antes de grabar?").assertIsDisplayed()
    }

    @Test
    fun testPostRecordingEmotionSelection() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"), recordingState = RecordingState.Completed(Mockito.mock(java.io.File::class.java), 1234, 1234, 1234))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithTag("emotion_selector").performClick()
        Mockito.verify(mockRecordEmotionalStateUseCase, Mockito.times(0)).invoke(
            Mockito.anyString(),
            Mockito.any(EmotionType::class.java),
            Mockito.anyInt(),
            Mockito.anyString(),
            Mockito.anyString(),
            Mockito.anyString(),
            Mockito.anyString()
        )

        val updatedUiState = uiState.copy(postEmotionalState = EmotionalState("test", EmotionType.CALM, 5, "test", "test", 1234, "test", "test"))
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("Guardar").assertIsEnabled()
    }

    @Test
    fun testSaveJournal() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"), recordingState = RecordingState.Completed(Mockito.mock(java.io.File::class.java), 1234, 1234, 1234), postEmotionalState = EmotionalState("test", EmotionType.CALM, 5, "test", "test", 1234, "test", "test"))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Guardar").performClick()
        Mockito.verify(mockCreateJournalUseCase, Mockito.times(1)).invoke(
            Mockito.anyString(),
            Mockito.any(EmotionalState::class.java),
            Mockito.any(EmotionalState::class.java),
            Mockito.any(java.io.File::class.java),
            Mockito.anyString()
        )

        val updatedUiState = uiState.copy(savedJournal = Journal("test", "test", 1234, 1234, "test", 1234, false, false, "test", "test", "test", Mockito.mock(EmotionalState::class.java), Mockito.mock(EmotionalState::class.java), null))
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("¡Grabación guardada!").assertIsDisplayed()
        composeTestRule.onNodeWithText("Ver todas mis grabaciones").assertIsDisplayed()
    }

    @Test
    fun testNavigateToJournalDetail() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"), recordingState = RecordingState.Completed(Mockito.mock(java.io.File::class.java), 1234, 1234, 1234), postEmotionalState = EmotionalState("test", EmotionType.CALM, 5, "test", "test", 1234, "test", "test"), savedJournal = Journal(testJournalId, "test", 1234, 1234, "test", 1234, false, false, "test", "test", "test", Mockito.mock(EmotionalState::class.java), Mockito.mock(EmotionalState::class.java), null))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Ver todas mis grabaciones").performClick()
        Mockito.verify(mockNavActions, Mockito.times(0)).navigateToJournalDetail(testJournalId)
    }

    @Test
    fun testNavigateToJournalList() {
        val uiState = RecordJournalUiState(permissionGranted = true, preEmotionalState = EmotionalState("test", EmotionType.JOY, 5, "test", "test", 1234, "test", "test"), recordingState = RecordingState.Completed(Mockito.mock(java.io.File::class.java), 1234, 1234, 1234), postEmotionalState = EmotionalState("test", EmotionType.CALM, 5, "test", "test", 1234, "test", "test"), savedJournal = Journal(testJournalId, "test", 1234, 1234, "test", 1234, false, false, "test", "test", "test", Mockito.mock(EmotionalState::class.java), Mockito.mock(EmotionalState::class.java), null))
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Volver al inicio").performClick()
        Mockito.verify(mockNavActions, Mockito.times(1)).navigateToJournalList()
    }

    @Test
    fun testErrorState() {
        val uiState = RecordJournalUiState(isError = true, message = "Test error message")
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithText("Test error message").assertIsDisplayed()
        composeTestRule.onNodeWithText("Reintentar").performClick()
        Mockito.verify(viewModel, Mockito.times(1)).clearMessage()

        val updatedUiState = uiState.copy(isError = false, message = null)
        uiStateFlow.value = updatedUiState

        composeTestRule.onNodeWithText("Test error message").assertDoesNotExist()
    }

    @Test
    fun testBackNavigation() {
        val uiState = RecordJournalUiState(permissionGranted = true)
        val uiStateFlow = MutableStateFlow(uiState)
        Mockito.`when`(mockAudioRecordingService.getRecordingState()).thenReturn(uiStateFlow)

        composeTestRule.onNodeWithContentDescription("Atrás").performClick()
        Mockito.verify(mockNavActions, Mockito.times(1)).navigateBack()
        Mockito.verify(viewModel, Mockito.times(1)).resetState()
    }
}