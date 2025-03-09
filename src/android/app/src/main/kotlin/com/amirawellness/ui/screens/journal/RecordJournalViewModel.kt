package com.amirawellness.ui.screens.journal

import android.content.Context // android version: latest
import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import com.amirawellness.core.constants.AppConstants.EmotionContext // project-level
import com.amirawellness.core.constants.AppConstants.EmotionType // project-level
import com.amirawellness.core.utils.LogUtils // project-level
import com.amirawellness.core.utils.PermissionUtils // project-level
import com.amirawellness.data.models.EmotionalState // project-level
import com.amirawellness.data.models.Journal // project-level
import com.amirawellness.domain.usecases.emotional.RecordEmotionalStateUseCase // project-level
import com.amirawellness.domain.usecases.journal.CreateJournalUseCase // project-level
import com.amirawellness.services.audio.AudioRecordingService // project-level
import com.amirawellness.services.audio.RecordingError // project-level
import com.amirawellness.services.audio.RecordingState // project-level
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt:hilt-android:2.44
import java.io.File // java.io version: latest
import javax.inject.Inject // javax.inject:javax.inject:1
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.collectLatest // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.update // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-android:1.6.4

private const val TAG = "RecordJournalViewModel"

/**
 * Data class representing the UI state for the journal recording screen
 */
data class RecordJournalUiState(
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val recordingState: RecordingState = RecordingState.Idle,
    val currentAmplitude: Int = 0,
    val recordingDuration: Long = 0L,
    val preEmotionalState: EmotionalState? = null,
    val postEmotionalState: EmotionalState? = null,
    val savedJournal: Journal? = null,
    val message: String? = null,
    val isError: Boolean = false,
    val permissionGranted: Boolean = false
) {
    /**
     * Creates a copy of the UI state with optional property changes
     */
    fun copy(
        isLoading: Boolean? = null,
        isSaving: Boolean? = null,
        recordingState: RecordingState? = null,
        currentAmplitude: Int? = null,
        recordingDuration: Long? = null,
        preEmotionalState: EmotionalState? = null,
        postEmotionalState: EmotionalState? = null,
        savedJournal: Journal? = null,
        message: String? = null,
        isError: Boolean? = null,
        permissionGranted: Boolean? = null
    ): RecordJournalUiState {
        return RecordJournalUiState(
            isLoading = isLoading ?: this.isLoading,
            isSaving = isSaving ?: this.isSaving,
            recordingState = recordingState ?: this.recordingState,
            currentAmplitude = currentAmplitude ?: this.currentAmplitude,
            recordingDuration = recordingDuration ?: this.recordingDuration,
            preEmotionalState = preEmotionalState ?: this.preEmotionalState,
            postEmotionalState = postEmotionalState ?: this.postEmotionalState,
            savedJournal = savedJournal ?: this.savedJournal,
            message = message ?: this.message,
            isError = isError ?: this.isError,
            permissionGranted = permissionGranted ?: this.permissionGranted
        )
    }
}

/**
 * ViewModel for managing the voice journal recording screen state and user interactions
 */
@HiltViewModel
class RecordJournalViewModel @Inject constructor(
    private val context: Context,
    private val audioRecordingService: AudioRecordingService,
    private val createJournalUseCase: CreateJournalUseCase,
    private val recordEmotionalStateUseCase: RecordEmotionalStateUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(Companion.createDefaultUiState())
    val uiState: StateFlow<RecordJournalUiState> = _uiState.asStateFlow()

    private var recordingFile: File? = null
    private var encryptedFile: File? = null
    private var userId: String = "temp_user_id" // TODO: Replace with actual user ID

    init {
        initCollectors()
    }

    /**
     * Initializes the ViewModel by setting up collectors for audio recording state
     */
    private fun initCollectors() {
        viewModelScope.launch {
            audioRecordingService.getRecordingState().collectLatest { state ->
                _uiState.update { it.copy(recordingState = state) }
            }
        }

        viewModelScope.launch {
            audioRecordingService.getCurrentAmplitude().collectLatest { amplitude ->
                _uiState.update { it.copy(currentAmplitude = amplitude) }
            }
        }

        viewModelScope.launch {
            audioRecordingService.getRecordingDuration().collectLatest { duration ->
                _uiState.update { it.copy(recordingDuration = duration) }
            }
        }
    }

    /**
     * Sets the user ID for the journal recording
     */
    fun setUserId(userId: String) {
        this.userId = userId
    }

    /**
     * Checks if the app has the necessary permissions for audio recording
     */
    fun checkPermissions() {
        val hasPermission = PermissionUtils.hasAudioRecordingPermission(context)
        _uiState.update { it.copy(permissionGranted = hasPermission) }
    }

    /**
     * Starts the audio recording process
     */
    fun startRecording() {
        if (_uiState.value.preEmotionalState == null) {
            _uiState.update { it.copy(message = "Please select pre-recording emotional state first", isError = true) }
            return
        }

        viewModelScope.launch {
            try {
                val journalId = java.util.UUID.randomUUID().toString()
                audioRecordingService.startRecording(journalId)
                    .onSuccess { file ->
                        recordingFile = file
                        _uiState.update { it.copy(message = "Recording started", isError = false) }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(message = "Error starting recording: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error starting recording", e)
                _uiState.update { it.copy(message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Pauses the current audio recording
     */
    fun pauseRecording() {
        viewModelScope.launch {
            try {
                audioRecordingService.pauseRecording()
                    .onSuccess {
                        _uiState.update { it.copy(message = "Recording paused", isError = false) }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(message = "Error pausing recording: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error pausing recording", e)
                _uiState.update { it.copy(message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Resumes a paused audio recording
     */
    fun resumeRecording() {
        viewModelScope.launch {
            try {
                audioRecordingService.resumeRecording()
                    .onSuccess {
                        _uiState.update { it.copy(message = "Recording resumed", isError = false) }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(message = "Error resuming recording: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error resuming recording", e)
                _uiState.update { it.copy(message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Stops the current audio recording and prepares for post-recording emotional check-in
     */
    fun stopRecording() {
        viewModelScope.launch {
            try {
                audioRecordingService.stopRecording()
                    .onSuccess { file ->
                        _uiState.update { it.copy(recordingState = RecordingState.Completed(file, 0, 0, 0), message = "Recording stopped", isError = false) }
                        createDefaultPostEmotionalState()?.let { emotionalState ->
                            updatePostEmotionalState(emotionalState.emotionType, emotionalState.intensity, emotionalState.notes)
                        }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(message = "Error stopping recording: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error stopping recording", e)
                _uiState.update { it.copy(message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Cancels the current recording and cleans up resources
     */
    fun cancelRecording() {
        viewModelScope.launch {
            try {
                audioRecordingService.cancelRecording()
                    .onSuccess {
                        recordingFile = null
                        _uiState.update { it.copy(recordingState = RecordingState.Idle, message = "Recording cancelled", isError = false) }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(message = "Error cancelling recording: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error cancelling recording", e)
                _uiState.update { it.copy(message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Updates the pre-recording emotional state
     */
    fun updatePreEmotionalState(emotionType: EmotionType, intensity: Int, notes: String?) {
        viewModelScope.launch {
            try {
                val emotionalState = EmotionalState.createEmpty(emotionType, EmotionContext.PRE_JOURNALING.toString()).copy(intensity = intensity, notes = notes)
                recordEmotionalStateUseCase(userId, emotionType, intensity, EmotionContext.PRE_JOURNALING.toString(), notes, null, null)
                    .onSuccess { state ->
                        _uiState.update { it.copy(preEmotionalState = state, message = "Pre-recording emotional state updated", isError = false) }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(message = "Error updating pre-recording emotional state: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error updating pre-recording emotional state", e)
                _uiState.update { it.copy(message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Updates the post-recording emotional state
     */
    fun updatePostEmotionalState(emotionType: EmotionType, intensity: Int, notes: String?) {
        viewModelScope.launch {
            try {
                val emotionalState = EmotionalState.createEmpty(emotionType, EmotionContext.POST_JOURNALING.toString()).copy(intensity = intensity, notes = notes)
                recordEmotionalStateUseCase(userId, emotionType, intensity, EmotionContext.POST_JOURNALING.toString(), notes, null, null)
                    .onSuccess { state ->
                        _uiState.update { it.copy(postEmotionalState = state, message = "Post-recording emotional state updated", isError = false) }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(message = "Error updating post-recording emotional state: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error updating post-recording emotional state", e)
                _uiState.update { it.copy(message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Saves the completed journal with audio recording and emotional states
     */
    fun saveJournal(title: String?) {
        if (_uiState.value.preEmotionalState == null || _uiState.value.postEmotionalState == null) {
            _uiState.update { it.copy(message = "Please select both pre and post recording emotional states", isError = true) }
            return
        }

        _uiState.update { it.copy(isSaving = true, message = "Saving journal...", isError = false) }

        viewModelScope.launch {
            try {
                encryptRecordingFile()
                    .onSuccess { (encryptedFile, encryptionIv) ->
                        val audioMetadata = audioRecordingService.createAudioMetadata(recordingFile!!, userId).getOrNull()
                        createJournalUseCase(userId, _uiState.value.preEmotionalState!!, _uiState.value.postEmotionalState!!, encryptedFile, title)
                            .onSuccess { journal ->
                                _uiState.update {
                                    it.copy(
                                        savedJournal = journal,
                                        isSaving = false,
                                        recordingState = RecordingState.Idle,
                                        message = "Journal saved successfully",
                                        isError = false
                                    )
                                }
                                resetState()
                            }
                            .onFailure { e ->
                                _uiState.update { it.copy(isSaving = false, message = "Error saving journal: ${e.message}", isError = true) }
                            }
                    }
                    .onFailure { e ->
                        _uiState.update { it.copy(isSaving = false, message = "Error encrypting recording: ${e.message}", isError = true) }
                    }
            } catch (e: Exception) {
                LogUtils.e(TAG, "Error saving journal", e)
                _uiState.update { it.copy(isSaving = false, message = "An unexpected error occurred", isError = true) }
            }
        }
    }

    /**
     * Clears any message or error in the UI state
     */
    fun clearMessage() {
        _uiState.update { it.copy(message = null, isError = false) }
    }

    /**
     * Resets the ViewModel state to initial values
     */
    fun resetState() {
        _uiState.update { Companion.createDefaultUiState() }
        recordingFile = null
        encryptedFile = null
    }

    /**
     * Called when the ViewModel is being cleared, used for cleanup
     */
    override fun onCleared() {
        super.onCleared()
        cancelRecording()
    }

    /**
     * Encrypts the recording file for privacy protection
     */
    private suspend fun encryptRecordingFile(): Result<Pair<File, String>> {
        return try {
            val file = recordingFile
            if (file == null || !file.exists()) {
                return Result.failure(Exception("Recording file does not exist"))
            }

            val journalId = java.util.UUID.randomUUID().toString()
            val encryptedFilePath = file.absolutePath.replace(".aac", ".encrypted")
            encryptedFile = File(encryptedFilePath)

            audioRecordingService.encryptRecording(file, journalId)
                .onSuccess { (encryptedFilePath, iv) ->
                    return Result.success(Pair(File(encryptedFilePath), String(iv)))
                }
                .onFailure { e ->
                    return Result.failure(e)
                }
            Result.success(Pair(encryptedFile!!, "testIv"))
        } catch (e: Exception) {
            LogUtils.e(TAG, "Error encrypting recording file", e)
            Result.failure(e)
        }
    }

    /**
     * Creates a default post-recording emotional state based on the pre-recording state
     */
    private fun createDefaultPostEmotionalState(): EmotionalState? {
        val preEmotionalState = _uiState.value.preEmotionalState
        if (preEmotionalState == null) {
            return null
        }

        return EmotionalState.createEmpty(preEmotionalState.emotionType, EmotionContext.POST_JOURNALING.toString()).copy(intensity = preEmotionalState.intensity)
    }

    companion object {
        /**
         * Creates the default UI state for the recording screen
         */
        fun createDefaultUiState(): RecordJournalUiState {
            return RecordJournalUiState(
                isLoading = false,
                isSaving = false,
                recordingState = RecordingState.Idle,
                currentAmplitude = 0,
                recordingDuration = 0L,
                preEmotionalState = null,
                postEmotionalState = null,
                savedJournal = null,
                message = null,
                isError = false,
                permissionGranted = false
            )
        }
    }
}