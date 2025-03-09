package com.amirawellness.ui.screens.settings

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.User
import com.amirawellness.data.repositories.EmotionalStateRepository
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.data.repositories.UserRepository
import com.amirawellness.domain.usecases.journal.ExportFormat
import com.amirawellness.domain.usecases.journal.ExportJournalUseCase
import com.amirawellness.services.encryption.EncryptionManager
import com.google.gson.Gson // com.google.code.gson:gson:2.10.1
import dagger.hilt.android.lifecycle.HiltViewModel // com.google.dagger:hilt-android-compiler:2.44
import kotlinx.coroutines.Dispatchers // org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.4
import kotlinx.coroutines.flow.MutableStateFlow // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.StateFlow // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.asStateFlow // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.flow.update // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.launch // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.withContext // org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4
import java.io.File
import java.io.FileOutputStream
import javax.inject.Inject // javax.inject:javax.inject:1

private const val TAG = "DataExportViewModel"
private const val MIN_PASSWORD_LENGTH = 8

/**
 * Data class representing the UI state for data export operations
 */
data class DataExportUiState(
    val isLoading: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val exportedFileUri: Uri? = null
)

/**
 * ViewModel for managing data export operations with password-based encryption
 */
@HiltViewModel
class DataExportViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val journalRepository: JournalRepository,
    private val emotionalStateRepository: EmotionalStateRepository,
    private val exportJournalUseCase: ExportJournalUseCase,
    context: Context
) : ViewModel() {

    private val encryptionManager = EncryptionManager.getInstance(context)
    private val gson = Gson()
    private val _uiState = MutableStateFlow(DataExportUiState())
    val uiState: StateFlow<DataExportUiState> = _uiState.asStateFlow()

    /**
     * Exports all user data with password-based encryption
     */
    fun exportUserData(password: String) {
        _uiState.update { it.copy(isLoading = true, error = null, isSuccess = false, exportedFileUri = null) }
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val user = userRepository.getCurrentUser().first()
                    if (user == null) {
                        _uiState.update { it.copy(isLoading = false, error = "User not found") }
                        return@withContext
                    }

                    val journals = journalRepository.getJournalsByUser(user.id.toString()).first()
                    val emotionalStates = emotionalStateRepository.getEmotionalStatesByUserId(user.id.toString()).first()

                    val exportData = ExportData(user, journals, emotionalStates)
                    val jsonString = gson.toJson(exportData)

                    val exportDirectory = createExportDirectory()
                    val exportFile = File(exportDirectory, getExportFileName("all_data"))

                    val encryptResult = encryptionManager.encryptWithPassword(jsonString.toByteArray(), password)
                    encryptResult.fold(
                        onSuccess = { encryptedData ->
                            FileOutputStream(exportFile).use { fileOutputStream ->
                                fileOutputStream.write(encryptedData.encryptedData.encryptedBytes)
                            }
                            _uiState.update { it.copy(isLoading = false, isSuccess = true, exportedFileUri = Uri.fromFile(exportFile)) }
                        },
                        onFailure = { exception ->
                            LogUtils.e(TAG, "Encryption failed", exception)
                            _uiState.update { it.copy(isLoading = false, error = "Encryption failed: ${exception.message}") }
                        }
                    )
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Export failed", e)
                    _uiState.update { it.copy(isLoading = false, error = "Export failed: ${e.message}") }
                }
            }
        }
    }

    /**
     * Exports only journal data with password-based encryption
     */
    fun exportJournalsOnly(password: String) {
        _uiState.update { it.copy(isLoading = true, error = null, isSuccess = false, exportedFileUri = null) }
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val user = userRepository.getCurrentUser().first()
                    if (user == null) {
                        _uiState.update { it.copy(isLoading = false, error = "User not found") }
                        return@withContext
                    }

                    val journals = journalRepository.getJournalsByUser(user.id.toString()).first()

                    val journalExportData = JournalExportData(journals)
                    val jsonString = gson.toJson(journalExportData)

                    val exportDirectory = createExportDirectory()
                    val exportFile = File(exportDirectory, getExportFileName("journals_only"))

                    val encryptResult = encryptionManager.encryptWithPassword(jsonString.toByteArray(), password)
                    encryptResult.fold(
                        onSuccess = { encryptedData ->
                            FileOutputStream(exportFile).use { fileOutputStream ->
                                fileOutputStream.write(encryptedData.encryptedData.encryptedBytes)
                            }

                            // Export audio files for each journal
                            journals.forEach { journal ->
                                if (journal.localFilePath != null && journal.encryptionIv != null) {
                                    val audioExportFile = File(exportDirectory, "${journal.id}.eaac")
                                    exportJournalUseCase(journal, audioExportFile, ExportFormat.ENCRYPTED)
                                }
                            }

                            _uiState.update { it.copy(isLoading = false, isSuccess = true, exportedFileUri = Uri.fromFile(exportFile)) }
                        },
                        onFailure = { exception ->
                            LogUtils.e(TAG, "Encryption failed", exception)
                            _uiState.update { it.copy(isLoading = false, error = "Encryption failed: ${exception.message}") }
                        }
                    )
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Export failed", e)
                    _uiState.update { it.copy(isLoading = false, error = "Export failed: ${e.message}") }
                }
            }
        }
    }

    /**
     * Exports only emotional data with password-based encryption
     */
    fun exportEmotionalDataOnly(password: String) {
        _uiState.update { it.copy(isLoading = true, error = null, isSuccess = false, exportedFileUri = null) }
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val user = userRepository.getCurrentUser().first()
                    if (user == null) {
                        _uiState.update { it.copy(isLoading = false, error = "User not found") }
                        return@withContext
                    }

                    val emotionalStates = emotionalStateRepository.getEmotionalStatesByUserId(user.id.toString()).first()

                    val emotionalExportData = EmotionalExportData(emotionalStates)
                    val jsonString = gson.toJson(emotionalExportData)

                    val exportDirectory = createExportDirectory()
                    val exportFile = File(exportDirectory, getExportFileName("emotional_data_only"))

                    val encryptResult = encryptionManager.encryptWithPassword(jsonString.toByteArray(), password)
                    encryptResult.fold(
                        onSuccess = { encryptedData ->
                            FileOutputStream(exportFile).use { fileOutputStream ->
                                fileOutputStream.write(encryptedData.encryptedData.encryptedBytes)
                            }
                            _uiState.update { it.copy(isLoading = false, isSuccess = true, exportedFileUri = Uri.fromFile(exportFile)) }
                        },
                        onFailure = { exception ->
                            LogUtils.e(TAG, "Encryption failed", exception)
                            _uiState.update { it.copy(isLoading = false, error = "Encryption failed: ${exception.message}") }
                        }
                    )
                } catch (e: Exception) {
                    LogUtils.e(TAG, "Export failed", e)
                    _uiState.update { it.copy(isLoading = false, error = "Export failed: ${e.message}") }
                }
            }
        }
    }

    /**
     * Validates that the password meets security requirements
     */
    fun validatePassword(password: String): Boolean {
        if (password.isBlank()) {
            _uiState.update { it.copy(error = "Password cannot be blank") }
            return false
        }
        if (password.length < MIN_PASSWORD_LENGTH) {
            _uiState.update { it.copy(error = "Password must be at least $MIN_PASSWORD_LENGTH characters long") }
            return false
        }
        if (!password.matches(".*\\d.*".toRegex())) {
            _uiState.update { it.copy(error = "Password must contain at least one digit") }
            return false
        }
        if (!password.matches(".*[a-zA-Z].*".toRegex())) {
            _uiState.update { it.copy(error = "Password must contain at least one letter") }
            return false
        }
        return true
    }

    /**
     * Resets the UI state to initial state
     */
    fun resetState() {
        _uiState.update { DataExportUiState() }
    }

    /**
     * Creates the directory for exported files if it doesn't exist
     */
    private fun createExportDirectory(): File {
        val directory = File(context.getExternalFilesDir(null), "exports")
        if (!directory.exists()) {
            directory.mkdirs()
        }
        return directory
    }

    /**
     * Generates a filename for the exported data with timestamp
     */
    private fun getExportFileName(prefix: String): String {
        val timestamp = System.currentTimeMillis()
        return "${prefix}_${timestamp}.amira"
    }

    /**
     * Data class representing all user data for export
     */
    private data class ExportData(
        val user: User,
        val journals: List<Journal>,
        val emotionalStates: List<EmotionalState>,
        val exportTimestamp: Long = System.currentTimeMillis(),
        val version: String = "1.0"
    )

    /**
     * Data class representing journal data for export
     */
    private data class JournalExportData(
        val journals: List<Journal>,
        val exportTimestamp: Long = System.currentTimeMillis(),
        val version: String = "1.0"
    )

    /**
     * Data class representing emotional data for export
     */
    private data class EmotionalExportData(
        val emotionalStates: List<EmotionalState>,
        val exportTimestamp: Long = System.currentTimeMillis(),
        val version: String = "1.0"
    )
}