package com.amirawellness.ui.screens.tools

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import kotlinx.coroutines.Job
import javax.inject.Inject
import dagger.hilt.android.lifecycle.HiltViewModel
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolStep
import com.amirawellness.data.models.ToolContentType
import com.amirawellness.domain.usecases.tool.GetToolUseCase
import com.amirawellness.domain.usecases.tool.TrackToolUsageUseCase
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.core.utils.LogUtils.d
import com.amirawellness.core.utils.LogUtils.e

private const val TAG = "ToolInProgressViewModel"
private const val TIMER_INTERVAL_MS = 1000L // 1 second interval for timer updates

/**
 * ViewModel for the Tool In Progress screen that manages UI state and business logic during tool usage
 */
@HiltViewModel
class ToolInProgressViewModel @Inject constructor(
    private val getToolUseCase: GetToolUseCase,
    private val trackToolUsageUseCase: TrackToolUsageUseCase,
    private val navActions: NavActions
) : ViewModel() {

    private val _uiState = MutableStateFlow(Companion.defaultState())
    val uiState: StateFlow<ToolInProgressUiState> = _uiState.asStateFlow()
    
    // Timer tracking variables
    private var startTimeMs: Long = 0
    private var elapsedTimeMs: Long = 0
    private var isTimerRunning: Boolean = false
    private var timerJob: Job? = null
    
    /**
     * Loads a specific tool by ID from the repository
     */
    fun loadTool(toolId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        viewModelScope.launch {
            try {
                d(TAG, "Loading tool: $toolId")
                getToolUseCase(toolId, false).collect { tool ->
                    if (tool == null) {
                        e(TAG, "Tool not found: $toolId")
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = "Tool not found"
                        )
                    } else {
                        d(TAG, "Tool loaded successfully: ${tool.name}")
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            tool = tool,
                            currentStepIndex = 0,
                            isPlaying = true
                        )
                        
                        // Start the timer once the tool is loaded
                        startTimer()
                    }
                }
            } catch (e: Exception) {
                e(TAG, "Error loading tool: ${e.message}", e)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to load tool: ${e.message}"
                )
            }
        }
    }
    
    /**
     * Starts or resumes the timer for tracking tool usage duration
     */
    private fun startTimer() {
        if (isTimerRunning) return
        
        isTimerRunning = true
        if (startTimeMs == 0L) {
            startTimeMs = System.currentTimeMillis() - elapsedTimeMs
        }
        
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (true) {
                // Update elapsed time
                elapsedTimeMs = System.currentTimeMillis() - startTimeMs
                val formattedElapsedTime = formatTime(elapsedTimeMs)
                
                // Calculate remaining time for current step if applicable
                val currentStep = _uiState.value.getCurrentStep()
                val stepRemainingTime = if (currentStep != null) {
                    val stepDurationMs = currentStep.duration * 1000L
                    val stepElapsedTimeMs = elapsedTimeMs % stepDurationMs
                    val stepRemainingMs = stepDurationMs - stepElapsedTimeMs
                    formatTime(stepRemainingMs)
                } else {
                    "00:00"
                }
                
                // Calculate progress percentage for current step
                val progress = if (currentStep != null) {
                    val stepDurationMs = currentStep.duration * 1000L
                    val stepElapsedTimeMs = elapsedTimeMs % stepDurationMs
                    (stepElapsedTimeMs / stepDurationMs.toFloat()).coerceIn(0f, 1f)
                } else {
                    0f
                }
                
                // Update UI state with new times
                _uiState.value = _uiState.value.copy(
                    formattedElapsedTime = formattedElapsedTime,
                    formattedRemainingTime = stepRemainingTime,
                    progress = progress,
                    isPlaying = true
                )
                
                // If a step is completed, move to the next step
                if (currentStep != null && progress >= 1f) {
                    moveToNextStep()
                }
                
                delay(TIMER_INTERVAL_MS)
            }
        }
    }
    
    /**
     * Pauses the timer while keeping track of elapsed time
     */
    private fun pauseTimer() {
        if (!isTimerRunning) return
        
        d(TAG, "Pausing timer at: ${formatTime(elapsedTimeMs)}")
        isTimerRunning = false
        timerJob?.cancel()
        timerJob = null
        
        _uiState.value = _uiState.value.copy(isPlaying = false)
    }
    
    /**
     * Resumes the timer from where it was paused
     */
    private fun resumeTimer() {
        if (isTimerRunning) return
        
        d(TAG, "Resuming timer from: ${formatTime(elapsedTimeMs)}")
        // Adjust start time to account for elapsed time
        startTimeMs = System.currentTimeMillis() - elapsedTimeMs
        startTimer()
        
        _uiState.value = _uiState.value.copy(isPlaying = true)
    }
    
    /**
     * Stops the timer and finalizes the elapsed time
     */
    private fun stopTimer() {
        if (!isTimerRunning && timerJob == null) return
        
        d(TAG, "Stopping timer at: ${formatTime(elapsedTimeMs)}")
        isTimerRunning = false
        timerJob?.cancel()
        timerJob = null
        
        // Final elapsed time calculation
        val finalElapsedTime = elapsedTimeMs
        _uiState.value = _uiState.value.copy(
            formattedElapsedTime = formatTime(finalElapsedTime),
            isPlaying = false
        )
    }
    
    /**
     * Advances to the next step in a guided exercise
     */
    fun moveToNextStep() {
        val currentTool = _uiState.value.tool
        val currentStepIndex = _uiState.value.currentStepIndex
        
        if (currentTool == null || currentTool.content.steps.isNullOrEmpty()) return
        
        val nextStepIndex = currentStepIndex + 1
        if (nextStepIndex < currentTool.content.steps.size) {
            // Move to next step
            d(TAG, "Moving to next step: $nextStepIndex of ${currentTool.content.steps.size}")
            _uiState.value = _uiState.value.copy(
                currentStepIndex = nextStepIndex,
                progress = 0f
            )
        } else {
            // We've reached the end of the steps, complete the exercise
            d(TAG, "All steps completed, finishing exercise")
            completeExercise()
        }
    }
    
    /**
     * Goes back to the previous step in a guided exercise
     */
    fun moveToPreviousStep() {
        val currentTool = _uiState.value.tool
        val currentStepIndex = _uiState.value.currentStepIndex
        
        if (currentTool == null || currentTool.content.steps.isNullOrEmpty()) return
        
        val prevStepIndex = currentStepIndex - 1
        if (prevStepIndex >= 0) {
            // Move to previous step
            d(TAG, "Moving to previous step: $prevStepIndex of ${currentTool.content.steps.size}")
            _uiState.value = _uiState.value.copy(
                currentStepIndex = prevStepIndex,
                progress = 0f
            )
        }
    }
    
    /**
     * Completes the current tool exercise and records usage
     */
    fun completeExercise() {
        // Stop the timer
        stopTimer()
        
        val tool = _uiState.value.tool ?: return
        
        // Calculate total duration in seconds
        val durationSeconds = (elapsedTimeMs / 1000).toInt()
        
        d(TAG, "Completing exercise: ${tool.name}, duration: $durationSeconds seconds")
        
        // Track tool usage
        viewModelScope.launch {
            try {
                trackToolUsageUseCase(tool.id, durationSeconds)
                d(TAG, "Tool usage tracked successfully for: ${tool.id}")
                // Navigate to completion screen
                navActions.navigateToToolCompletion(tool.id)
            } catch (e: Exception) {
                e(TAG, "Error tracking tool usage: ${e.message}", e)
            }
        }
    }
    
    /**
     * Cancels the current tool exercise without recording completion
     */
    fun cancelExercise() {
        d(TAG, "Exercise cancelled by user")
        stopTimer()
        navActions.navigateBack()
    }
    
    /**
     * Toggles between playing and pausing the current tool
     */
    fun togglePlayPause() {
        if (isTimerRunning) {
            pauseTimer()
        } else {
            resumeTimer()
        }
    }
    
    /**
     * Formats milliseconds into a human-readable time string
     */
    fun formatTime(timeMs: Long): String {
        val totalSeconds = timeMs / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%02d:%02d", minutes, seconds)
    }
    
    /**
     * Called when the ViewModel is being cleared, cleans up resources
     */
    override fun onCleared() {
        super.onCleared()
        d(TAG, "ViewModel being cleared, stopping timer")
        stopTimer()
    }
    
    companion object {
        /**
         * Creates the default UI state
         */
        fun defaultState() = ToolInProgressUiState(
            isLoading = false,
            tool = null,
            currentStepIndex = 0,
            formattedElapsedTime = "00:00",
            formattedRemainingTime = "00:00",
            isPlaying = false,
            progress = 0f,
            error = null
        )
    }
}

/**
 * Data class representing the UI state for the Tool In Progress screen
 */
data class ToolInProgressUiState(
    val isLoading: Boolean,
    val tool: Tool?,
    val currentStepIndex: Int,
    val formattedElapsedTime: String,
    val formattedRemainingTime: String,
    val isPlaying: Boolean,
    val progress: Float,
    val error: String?
) {
    /**
     * Gets the current step from the tool based on currentStepIndex
     */
    fun getCurrentStep(): ToolStep? {
        if (tool == null || tool.content.steps.isNullOrEmpty()) return null
        if (currentStepIndex < 0 || currentStepIndex >= tool.content.steps.size) return null
        return tool.content.steps[currentStepIndex]
    }
    
    /**
     * Gets the total number of steps in the current tool
     */
    fun getTotalSteps(): Int {
        return tool?.content?.steps?.size ?: 0
    }
    
    /**
     * Checks if the current step is the last step in the tool
     */
    fun isLastStep(): Boolean {
        if (tool == null || tool.content.steps.isNullOrEmpty()) return true
        return currentStepIndex == tool.content.steps.size - 1
    }
    
    /**
     * Checks if the current step is the first step in the tool
     */
    fun isFirstStep(): Boolean {
        return currentStepIndex == 0
    }
    
    /**
     * Creates a copy of the state with specified properties changed
     */
    fun copy(
        isLoading: Boolean = this.isLoading,
        tool: Tool? = this.tool,
        currentStepIndex: Int = this.currentStepIndex,
        formattedElapsedTime: String = this.formattedElapsedTime,
        formattedRemainingTime: String = this.formattedRemainingTime,
        isPlaying: Boolean = this.isPlaying,
        progress: Float = this.progress,
        error: String? = this.error
    ) = ToolInProgressUiState(
        isLoading = isLoading,
        tool = tool,
        currentStepIndex = currentStepIndex,
        formattedElapsedTime = formattedElapsedTime,
        formattedRemainingTime = formattedRemainingTime,
        isPlaying = isPlaying,
        progress = progress,
        error = error
    )
}