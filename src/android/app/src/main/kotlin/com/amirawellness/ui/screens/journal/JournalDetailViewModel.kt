package com.amirawellness.ui.screens.journal

import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import dagger.hilt.android.lifecycle.HiltViewModel // com.google.dagger:hilt-android-gradle-plugin:2.44
import kotlinx.coroutines.flow.MutableStateFlow // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.StateFlow // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.asStateFlow // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.update // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.collectLatest // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.launch // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.Dispatchers // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.withContext // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import javax.inject.Inject // javax.inject:javax.inject:1
import android.net.Uri // Android SDK
import java.io.File // Android SDK
import com.amirawellness.data.models.Journal // internal
import com.amirawellness.data.models.EmotionalState // internal
import com.amirawellness.data.repositories.JournalRepository // internal
import com.amirawellness.services.audio.AudioPlaybackService // internal
import com.amirawellness.services.audio.PlaybackState // internal
import com.amirawellness.core.utils.LogUtils // internal

private const val TAG = "JournalDetailViewModel"

/**
 * Data class representing the UI state for the journal detail screen
 */
data class JournalDetailUiState(
    val isLoading: Boolean = false,
    val journal: Journal? = null,
    val emotionalShift: EmotionalShift? = null,
    val playbackState: PlaybackState = PlaybackState.Idle,
    val playbackProgress: Int = 0,
    val playbackDuration: Int = 0,
    val isDeleting: Boolean = false,
    val isExporting: Boolean = false,
    val deletionCompleted: Boolean = false,
    val exportedUri: Uri? = null,
    val message: String? = null,
    val isError: Boolean = false,
    val waveformData: FloatArray = FloatArray(0)
) {
    /**
     * Creates a copy of the state with optional property changes
     */
    fun copy(
        isLoading: Boolean? = null,
        journal: Journal? = null,
        emotionalShift: EmotionalShift? = null,
        playbackState: PlaybackState? = null,
        playbackProgress: Int? = null,
        playbackDuration: Int? = null,
        isDeleting: Boolean? = null,
        isExporting: Boolean? = null,
        deletionCompleted: Boolean? = null,
        exportedUri: Uri? = null,
        message: String? = null,
        isError: Boolean? = null,
        waveformData: FloatArray? = null
    ): JournalDetailUiState {
        return JournalDetailUiState(
            isLoading = isLoading ?: this.isLoading,
            journal = journal ?: this.journal,
            emotionalShift = emotionalShift ?: this.emotionalShift,
            playbackState = playbackState ?: this.playbackState,
            playbackProgress = playbackProgress ?: this.playbackProgress,
            playbackDuration = playbackDuration ?: this.playbackDuration,
            isDeleting = isDeleting ?: this.isDeleting,
            isExporting = isExporting ?: this.isExporting,
            deletionCompleted = deletionCompleted ?: this.deletionCompleted,
            exportedUri = exportedUri ?: this.exportedUri,
            message = message ?: this.message,
            isError = isError ?: this.isError,
            waveformData = waveformData ?: this.waveformData
        )
    }
}

/**
 * Data class representing the emotional shift between pre and post journaling states
 */
data class EmotionalShift(
    val preEmotionalState: EmotionalState,
    val postEmotionalState: EmotionalState,
    val intensityChange: Int,
    val insights: List<String>
) {
    /**
     * Checks if the emotional shift is positive (improvement)
     */
    fun isPositive(): Boolean = intensityChange > 0

    /**
     * Checks if the emotional shift is negative (decline)
     */
    fun isNegative(): Boolean = intensityChange < 0

    /**
     * Checks if there is no emotional shift
     */
    fun isNeutral(): Boolean = intensityChange == 0
}

/**
 * ViewModel for the Journal Detail screen that manages state and business logic
 */
@HiltViewModel
class JournalDetailViewModel @Inject constructor(
    private val journalRepository: JournalRepository,
    private val audioPlaybackService: AudioPlaybackService
) : ViewModel() {

    private val _uiState = MutableStateFlow(JournalDetailUiState())
    val uiState: StateFlow<JournalDetailUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            audioPlaybackService.getPlaybackState().collectLatest { playbackState ->
                _uiState.update { it.copy(playbackState = playbackState) }
            }
        }

        viewModelScope.launch {
            audioPlaybackService.getCurrentProgress().collectLatest { progress ->
                _uiState.update { it.copy(playbackProgress = progress) }
            }
        }

        viewModelScope.launch {
            audioPlaybackService.getWaveformData().collectLatest { waveformData ->
                _uiState.update { it.copy(waveformData = waveformData) }
            }
        }
    }

    /**
     * Loads a journal entry by its ID
     */
    fun loadJournal(journalId: String) {
        _uiState.update { it.copy(isLoading = true, isError = false, message = null) }
        viewModelScope.launch {
            journalRepository.getJournal(journalId).collectLatest { journal ->
                if (journal == null) {
                    showMessage("Journal not found", true)
                    _uiState.update { it.copy(isLoading = false) }
                } else {
                    val emotionalShift = calculateEmotionalShift(journal)
                    _uiState.update {
                        it.copy(
                            journal = journal,
                            emotionalShift = emotionalShift,
                            isLoading = false
                        )
                    }
                }
            }
        }.invokeOnCompletion {
            if (it != null) {
                showMessage("Error loading journal", true)
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    /**
     * Toggles the favorite status of the current journal
     */
    fun toggleFavorite() {
        val journal = _uiState.value.journal ?: return
        viewModelScope.launch {
            journalRepository.toggleFavorite(journal)
                .onSuccess { updatedJournal ->
                    _uiState.update { it.copy(journal = updatedJournal) }
                    showMessage("Favorite status updated", false)
                }
                .onFailure {
                    showMessage("Error updating favorite status", true)
                }
        }
    }

    /**
     * Deletes the current journal entry
     */
    fun deleteJournal() {
        val journal = _uiState.value.journal ?: return
        _uiState.update { it.copy(isDeleting = true, isError = false, message = null) }
        audioPlaybackService.stopPlayback()
        viewModelScope.launch {
            journalRepository.deleteJournal(journal)
                .onSuccess {
                    _uiState.update { it.copy(isDeleting = false, deletionCompleted = true) }
                }
                .onFailure {
                    showMessage("Error deleting journal", true)
                    _uiState.update { it.copy(isDeleting = false) }
                }
        }
    }

    /**
     * Exports the current journal entry
     */
    fun exportJournal(includeMetadata: Boolean) {
        val journal = _uiState.value.journal ?: return
        _uiState.update { it.copy(isExporting = true, isError = false, message = null) }
        viewModelScope.launch {
            // TODO: Implement export functionality
            _uiState.update { it.copy(isExporting = false, exportedUri = null) }
        }
    }

    /**
     * Starts or resumes audio playback
     */
    fun playAudio() {
        val journal = _uiState.value.journal ?: return
        viewModelScope.launch {
            audioPlaybackService.playJournal(journal)
                .onFailure {
                    showMessage("Error starting playback", true)
                }
        }
    }

    /**
     * Pauses audio playback
     */
    fun pauseAudio() {
        viewModelScope.launch {
            audioPlaybackService.pausePlayback()
                .onFailure {
                    showMessage("Error pausing playback", true)
                }
        }
    }

    /**
     * Stops audio playback
     */
    fun stopAudio() {
        viewModelScope.launch {
            audioPlaybackService.stopPlayback()
                .onFailure {
                    showMessage("Error stopping playback", true)
                }
        }
    }

    /**
     * Seeks to a specific position in the audio playback
     */
    fun seekTo(positionMs: Int) {
        viewModelScope.launch {
            audioPlaybackService.seekTo(positionMs)
                .onFailure {
                    showMessage("Error seeking to position", true)
                }
        }
    }

    /**
     * Clears any displayed message
     */
    fun clearMessage() {
        _uiState.update { it.copy(message = null, isError = false) }
    }

    /**
     * Calculates the emotional shift between pre and post journaling states
     */
    private fun calculateEmotionalShift(journal: Journal): EmotionalShift {
        val intensityChange = journal.postEmotionalState.intensity - journal.preEmotionalState.intensity
        val insights = generateInsights(journal.preEmotionalState, journal.postEmotionalState, intensityChange)
        return EmotionalShift(journal.preEmotionalState, journal.postEmotionalState, intensityChange, insights)
    }

    /**
     * Generates insights based on the emotional shift
     */
    private fun generateInsights(preState: EmotionalState, postState: EmotionalState, intensityChange: Int): List<String> {
        val insights = mutableListOf<String>()

        if (intensityChange > 0) {
            insights.add("You experienced a positive emotional shift.")
        } else if (intensityChange < 0) {
            insights.add("You experienced a negative emotional shift.")
        } else {
            insights.add("There was no significant emotional shift.")
        }

        if (preState.emotionType != postState.emotionType) {
            insights.add("Your primary emotion shifted from ${preState.emotionType.name} to ${postState.emotionType.name}.")
        }

        if (intensityChange != 0) {
            insights.add("The intensity of your emotions changed by $intensityChange.")
        }

        // TODO: Add recommendations based on post emotional state

        return insights
    }

    /**
     * Shows a message in the UI
     */
    private fun showMessage(message: String, isError: Boolean) {
        _uiState.update { it.copy(message = message, isError = isError) }
    }

    /**
     * Called when the ViewModel is being cleared
     */
    override fun onCleared() {
        super.onCleared()
        audioPlaybackService.stopPlayback()
    }
}