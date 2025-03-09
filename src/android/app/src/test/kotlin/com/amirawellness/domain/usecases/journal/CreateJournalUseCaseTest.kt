package com.amirawellness.domain.usecases.journal

import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.ArgumentMatchers.*
import org.mockito.MockitoAnnotations
import kotlinx.coroutines.test.runTest
import java.io.File
import java.util.UUID

import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.AudioMetadata
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.core.utils.AudioUtils

class CreateJournalUseCaseTest {

    @Mock
    private lateinit var journalRepository: JournalRepository
    
    @Mock
    private lateinit var mockAudioFile: File
    
    private lateinit var createJournalUseCase: CreateJournalUseCase
    
    private val testUserId = UUID.randomUUID().toString()
    private lateinit var preEmotionalState: EmotionalState
    private lateinit var postEmotionalState: EmotionalState
    private lateinit var invalidPreEmotionalState: EmotionalState
    private lateinit var invalidPostEmotionalState: EmotionalState
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        createJournalUseCase = CreateJournalUseCase(journalRepository)
        
        // Set up valid emotional states
        preEmotionalState = EmotionalState(
            id = UUID.randomUUID().toString(),
            emotionType = EmotionType.JOY,
            intensity = 5,
            context = EmotionContext.PRE_JOURNALING.toString(),
            notes = "Feeling happy",
            createdAt = System.currentTimeMillis(),
            relatedJournalId = null,
            relatedToolId = null
        )
        
        postEmotionalState = EmotionalState(
            id = UUID.randomUUID().toString(),
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.POST_JOURNALING.toString(),
            notes = "Feeling calmer after recording",
            createdAt = System.currentTimeMillis(),
            relatedJournalId = null,
            relatedToolId = null
        )
        
        // Set up invalid emotional states (wrong contexts)
        invalidPreEmotionalState = preEmotionalState.copy(
            context = EmotionContext.STANDALONE.toString()
        )
        
        invalidPostEmotionalState = postEmotionalState.copy(
            context = EmotionContext.STANDALONE.toString()
        )
        
        // Set up mock audio file
        `when`(mockAudioFile.exists()).thenReturn(true)
        `when`(mockAudioFile.absolutePath).thenReturn("/path/to/audio.aac")
    }
    
    @Test
    fun testCreateJournalSuccess() = runTest {
        // Set up mock for AudioUtils.getAudioDuration to return test duration
        val testDuration = 120L * 1000 // 2 minutes in milliseconds
        AudioUtils.getAudioDuration = { file -> 
            if (file == mockAudioFile) testDuration else 0L 
        }
        
        // Set up mock for AudioUtils.getAudioMetadata to return test metadata
        val testMetadata = AudioMetadata(
            id = UUID.randomUUID().toString(),
            journalId = "",  // Will be set by CreateJournalUseCase
            fileFormat = "AAC",
            fileSizeBytes = 256000,
            sampleRate = 44100,
            bitRate = 128000,
            channels = 1,
            checksum = "test-checksum"
        )
        AudioUtils.getAudioMetadata = { file -> testMetadata }
        
        // Mock repository to return success
        val successfulJournal = Journal(
            id = UUID.randomUUID().toString(),
            userId = testUserId,
            createdAt = System.currentTimeMillis(),
            updatedAt = null,
            title = "Test Journal",
            durationSeconds = 120,
            isFavorite = false,
            isUploaded = false,
            localFilePath = "/path/to/audio.aac",
            storagePath = null,
            encryptionIv = null,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioMetadata = testMetadata
        )
        
        `when`(journalRepository.createJournal(any())).thenReturn(Result.success(successfulJournal))
        
        // Execute the use case
        val result = createJournalUseCase(
            userId = testUserId,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioFile = mockAudioFile,
            title = "Test Journal"
        )
        
        // Verify the result
        assertTrue(result.isSuccess)
        val journal = result.getOrNull()
        assertNotNull(journal)
        assertEquals(testUserId, journal?.userId)
        assertEquals("Test Journal", journal?.title)
        assertEquals(120, journal?.durationSeconds)
        assertEquals(mockAudioFile.absolutePath, journal?.localFilePath)
        assertEquals(preEmotionalState, journal?.preEmotionalState)
        assertEquals(postEmotionalState, journal?.postEmotionalState)
        assertNotNull(journal?.audioMetadata)
        
        // Verify repository was called with correct journal
        verify(journalRepository).createJournal(any())
    }
    
    @Test
    fun testCreateJournalWithoutAudioFile() = runTest {
        // Mock repository to return success
        val successfulJournal = Journal(
            id = UUID.randomUUID().toString(),
            userId = testUserId,
            createdAt = System.currentTimeMillis(),
            updatedAt = null,
            title = "Default Title",
            durationSeconds = 0,
            isFavorite = false,
            isUploaded = false,
            localFilePath = null,
            storagePath = null,
            encryptionIv = null,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioMetadata = null
        )
        
        `when`(journalRepository.createJournal(any())).thenReturn(Result.success(successfulJournal))
        
        // Execute the use case with null audio file
        val result = createJournalUseCase(
            userId = testUserId,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioFile = null
        )
        
        // Verify the result
        assertTrue(result.isSuccess)
        val journal = result.getOrNull()
        assertNotNull(journal)
        assertEquals(testUserId, journal?.userId)
        assertEquals(0, journal?.durationSeconds)
        assertNull(journal?.audioMetadata)
        assertNull(journal?.localFilePath)
        
        // Verify repository was called with correct journal
        verify(journalRepository).createJournal(any())
    }
    
    @Test
    fun testCreateJournalWithCustomTitle() = runTest {
        // Define custom title
        val customTitle = "My Custom Journal Title"
        
        // Mock repository to return success
        val successfulJournal = Journal(
            id = UUID.randomUUID().toString(),
            userId = testUserId,
            createdAt = System.currentTimeMillis(),
            updatedAt = null,
            title = customTitle,
            durationSeconds = 0,
            isFavorite = false,
            isUploaded = false,
            localFilePath = null,
            storagePath = null,
            encryptionIv = null,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioMetadata = null
        )
        
        `when`(journalRepository.createJournal(any())).thenReturn(Result.success(successfulJournal))
        
        // Execute the use case with custom title
        val result = createJournalUseCase(
            userId = testUserId,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioFile = null,
            title = customTitle
        )
        
        // Verify the result
        assertTrue(result.isSuccess)
        val journal = result.getOrNull()
        assertNotNull(journal)
        assertEquals(customTitle, journal?.title)
        
        // Verify repository was called with correct journal
        verify(journalRepository).createJournal(any())
    }
    
    @Test
    fun testCreateJournalWithInvalidEmotionalStates() = runTest {
        // Execute the use case with invalid pre-emotional state
        val resultWithInvalidPre = createJournalUseCase(
            userId = testUserId,
            preEmotionalState = invalidPreEmotionalState,
            postEmotionalState = postEmotionalState,
            audioFile = null
        )
        
        // Verify the result is failure
        assertTrue(resultWithInvalidPre.isFailure)
        val exception = resultWithInvalidPre.exceptionOrNull()
        assertNotNull(exception)
        assertTrue(exception is IllegalArgumentException)
        assertTrue(exception?.message?.contains("context") == true)
        
        // Execute the use case with invalid post-emotional state
        val resultWithInvalidPost = createJournalUseCase(
            userId = testUserId,
            preEmotionalState = preEmotionalState,
            postEmotionalState = invalidPostEmotionalState,
            audioFile = null
        )
        
        // Verify the result is failure
        assertTrue(resultWithInvalidPost.isFailure)
        val exception2 = resultWithInvalidPost.exceptionOrNull()
        assertNotNull(exception2)
        assertTrue(exception2 is IllegalArgumentException)
        assertTrue(exception2?.message?.contains("context") == true)
    }
    
    @Test
    fun testCreateJournalRepositoryError() = runTest {
        // Create a test exception
        val testException = RuntimeException("Repository error")
        
        // Set up mock for journalRepository.createJournal to return failure
        `when`(journalRepository.createJournal(any())).thenReturn(Result.failure(testException))
        
        // Execute the use case
        val result = createJournalUseCase(
            userId = testUserId,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioFile = null
        )
        
        // Verify the result is failure
        assertTrue(result.isFailure)
        assertEquals(testException, result.exceptionOrNull())
    }
    
    @Test
    fun testAudioFileProcessing() = runTest {
        // Set up mock for AudioUtils.getAudioDuration to return test duration
        val testDuration = 180L * 1000 // 3 minutes in milliseconds
        AudioUtils.getAudioDuration = { file -> 
            if (file == mockAudioFile) testDuration else 0L 
        }
        
        // Set up mock for AudioUtils.getAudioMetadata to return test metadata
        val testMetadata = AudioMetadata(
            id = UUID.randomUUID().toString(),
            journalId = "",  // Will be filled in by CreateJournalUseCase
            fileFormat = "AAC",
            fileSizeBytes = 384000,
            sampleRate = 44100,
            bitRate = 128000,
            channels = 1,
            checksum = "test-checksum"
        )
        AudioUtils.getAudioMetadata = { file -> testMetadata }
        
        // Mock repository to return success
        val successfulJournal = Journal(
            id = UUID.randomUUID().toString(),
            userId = testUserId,
            createdAt = System.currentTimeMillis(),
            updatedAt = null,
            title = "Test Journal",
            durationSeconds = 180,
            isFavorite = false,
            isUploaded = false,
            localFilePath = "/path/to/audio.aac",
            storagePath = null,
            encryptionIv = null,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioMetadata = testMetadata.copy(journalId = "filled-in-journal-id")
        )
        
        `when`(journalRepository.createJournal(any())).thenReturn(Result.success(successfulJournal))
        
        // Execute the use case
        val result = createJournalUseCase(
            userId = testUserId,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioFile = mockAudioFile
        )
        
        // Verify AudioUtils.getAudioDuration was called
        // Verify AudioUtils.getAudioMetadata was called
        // Note: Direct verification isn't possible with the current setup, 
        // but we can verify the effects in the created journal
        
        // Verify the result
        assertTrue(result.isSuccess)
        val journal = result.getOrNull()
        assertNotNull(journal)
        assertEquals(180, journal?.durationSeconds)
        assertNotNull(journal?.audioMetadata)
        
        // Verify the audioMetadata has the correct journalId
        assertEquals(journal?.id, journal?.audioMetadata?.journalId)
        
        // Verify repository was called
        verify(journalRepository).createJournal(any())
    }
}