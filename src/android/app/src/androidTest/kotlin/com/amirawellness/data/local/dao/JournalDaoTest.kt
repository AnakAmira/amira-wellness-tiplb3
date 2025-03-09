package com.amirawellness.data.local.dao

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import java.util.UUID
import java.util.Date
import java.text.SimpleDateFormat

import com.amirawellness.data.models.Journal
import com.amirawellness.data.models.AudioMetadata
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.data.local.AppDatabase

/**
 * Instrumented test class for testing the JournalDao implementation in the Room database.
 * This class verifies database operations related to voice journal entries and their associated
 * audio metadata. Tests validate CRUD operations, complex queries, and the relationships between
 * emotional states, journal entries, and audio data.
 */
@RunWith(AndroidJUnit4::class)
class JournalDaoTest {
    private lateinit var db: AppDatabase
    private lateinit var journalDao: JournalDao

    /**
     * Sets up the test environment before each test
     */
    @Before
    fun setup() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        db = AppDatabase.getTestInstance(context)
        journalDao = db.journalDao()
    }

    /**
     * Cleans up the test environment after each test
     */
    @After
    fun tearDown() {
        db.close()
    }

    /**
     * Helper method to create a test journal entry
     */
    private fun createTestJournal(
        userId: String = UUID.randomUUID().toString(),
        title: String = "Test Journal",
        durationSeconds: Int = 120,
        isFavorite: Boolean = false,
        isUploaded: Boolean = false,
        localFilePath: String? = "/test/path/audio.aac",
        storagePath: String? = null,
        encryptionIv: String? = null
    ): Journal {
        val id = UUID.randomUUID().toString()
        val createdAt = System.currentTimeMillis()
        
        val preEmotionalState = EmotionalState(
            id = UUID.randomUUID().toString(),
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.PRE_JOURNALING.toString(),
            notes = "Feeling anxious before recording",
            createdAt = createdAt,
            relatedJournalId = id,
            relatedToolId = null
        )
        
        val postEmotionalState = EmotionalState(
            id = UUID.randomUUID().toString(),
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.POST_JOURNALING.toString(),
            notes = "Feeling calmer after recording",
            createdAt = createdAt + durationSeconds * 1000L,
            relatedJournalId = id,
            relatedToolId = null
        )
        
        return Journal(
            id = id,
            userId = userId,
            createdAt = createdAt,
            updatedAt = null,
            title = title,
            durationSeconds = durationSeconds,
            isFavorite = isFavorite,
            isUploaded = isUploaded,
            localFilePath = localFilePath,
            storagePath = storagePath,
            encryptionIv = encryptionIv,
            preEmotionalState = preEmotionalState,
            postEmotionalState = postEmotionalState,
            audioMetadata = null
        )
    }

    /**
     * Helper method to create test audio metadata
     */
    private fun createTestAudioMetadata(journalId: String): AudioMetadata {
        return AudioMetadata(
            id = UUID.randomUUID().toString(),
            journalId = journalId,
            fileFormat = "AAC",
            fileSizeBytes = 1024 * 1024, // 1MB
            sampleRate = 44100,
            bitRate = 128000,
            channels = 1,
            checksum = "test-checksum-hash"
        )
    }

    /**
     * Tests inserting a journal entry and retrieving it by ID
     */
    @Test
    fun testInsertAndGetJournal() = runTest {
        // Create and insert a test journal
        val journal = createTestJournal()
        journalDao.insertJournal(journal)
        
        // Retrieve the journal by ID
        val retrievedJournal = journalDao.getJournalById(journal.id).first()
        
        // Assert that the journals are equal
        assertNotNull(retrievedJournal)
        assertEquals(journal.id, retrievedJournal?.id)
        assertEquals(journal.title, retrievedJournal?.title)
        assertEquals(journal.durationSeconds, retrievedJournal?.durationSeconds)
        assertEquals(journal.isFavorite, retrievedJournal?.isFavorite)
        assertEquals(journal.isUploaded, retrievedJournal?.isUploaded)
        assertEquals(journal.localFilePath, retrievedJournal?.localFilePath)
    }

    /**
     * Tests inserting a journal with associated audio metadata
     */
    @Test
    fun testInsertJournalWithAudioMetadata() = runTest {
        // Create and insert a test journal
        val journal = createTestJournal()
        journalDao.insertJournal(journal)
        
        // Create and insert audio metadata for the journal
        val audioMetadata = createTestAudioMetadata(journal.id)
        journalDao.insertAudioMetadata(audioMetadata)
        
        // Retrieve the journal by ID
        val retrievedJournal = journalDao.getJournalById(journal.id).first()
        
        // Assert that the journal is retrieved correctly
        assertNotNull(retrievedJournal)
        assertEquals(journal.id, retrievedJournal?.id)
        
        // Note: The audioMetadata is not automatically joined in this query
        // In a full implementation, you would have a relation or a joined query
    }

    /**
     * Tests updating a journal entry
     */
    @Test
    fun testUpdateJournal() = runTest {
        // Create and insert a test journal
        val journal = createTestJournal()
        journalDao.insertJournal(journal)
        
        // Update the journal
        val updatedJournal = journal.copy(
            title = "Updated Title",
            durationSeconds = 240,
            isFavorite = true,
            updatedAt = System.currentTimeMillis()
        )
        journalDao.updateJournal(updatedJournal)
        
        // Retrieve the updated journal
        val retrievedJournal = journalDao.getJournalById(journal.id).first()
        
        // Assert that the journal was correctly updated
        assertNotNull(retrievedJournal)
        assertEquals("Updated Title", retrievedJournal?.title)
        assertEquals(240, retrievedJournal?.durationSeconds)
        assertTrue(retrievedJournal?.isFavorite == true)
    }

    /**
     * Tests updating audio metadata
     */
    @Test
    fun testUpdateAudioMetadata() = runTest {
        // Create and insert a test journal with audio metadata
        val journal = createTestJournal()
        journalDao.insertJournal(journal)
        
        val audioMetadata = createTestAudioMetadata(journal.id)
        journalDao.insertAudioMetadata(audioMetadata)
        
        // Update the audio metadata
        val updatedAudioMetadata = audioMetadata.copy(
            fileSizeBytes = 2 * 1024 * 1024, // 2MB
            bitRate = 192000
        )
        journalDao.updateAudioMetadata(updatedAudioMetadata)
        
        // In a full implementation, we would verify by retrieving the updated metadata
    }

    /**
     * Tests deleting a journal entry and its associated audio metadata
     */
    @Test
    fun testDeleteJournal() = runTest {
        // Create and insert a test journal with audio metadata
        val journal = createTestJournal()
        journalDao.insertJournal(journal)
        
        val audioMetadata = createTestAudioMetadata(journal.id)
        journalDao.insertAudioMetadata(audioMetadata)
        
        // Delete the journal
        journalDao.deleteJournal(journal)
        
        // Try to retrieve the deleted journal
        val retrievedJournal = journalDao.getJournalById(journal.id).first()
        
        // Assert that the journal was deleted
        assertNull(retrievedJournal)
        
        // Audio metadata should be deleted via cascade delete in Room
    }

    /**
     * Tests retrieving all journal entries for a specific user
     */
    @Test
    fun testGetJournalsByUserId() = runTest {
        // Create multiple journals for different users
        val userId1 = UUID.randomUUID().toString()
        val userId2 = UUID.randomUUID().toString()
        
        val journal1User1 = createTestJournal(userId = userId1, title = "Journal 1 User 1")
        val journal2User1 = createTestJournal(userId = userId1, title = "Journal 2 User 1")
        val journal1User2 = createTestJournal(userId = userId2, title = "Journal 1 User 2")
        
        journalDao.insertJournal(journal1User1)
        journalDao.insertJournal(journal2User1)
        journalDao.insertJournal(journal1User2)
        
        // Retrieve journals for user1
        val user1Journals = journalDao.getJournalsByUserId(userId1).first()
        
        // Assert that only journals for user1 are returned
        assertEquals(2, user1Journals.size)
        assertTrue(user1Journals.all { it.userId == userId1 })
        assertTrue(user1Journals.any { it.title == "Journal 1 User 1" })
        assertTrue(user1Journals.any { it.title == "Journal 2 User 1" })
    }

    /**
     * Tests retrieving favorite journal entries for a user
     */
    @Test
    fun testGetFavoriteJournals() = runTest {
        // Create journals with different favorite statuses
        val userId = UUID.randomUUID().toString()
        
        val favoriteJournal1 = createTestJournal(userId = userId, title = "Favorite 1", isFavorite = true)
        val favoriteJournal2 = createTestJournal(userId = userId, title = "Favorite 2", isFavorite = true)
        val nonFavoriteJournal = createTestJournal(userId = userId, title = "Non-Favorite", isFavorite = false)
        
        journalDao.insertJournal(favoriteJournal1)
        journalDao.insertJournal(favoriteJournal2)
        journalDao.insertJournal(nonFavoriteJournal)
        
        // Retrieve favorite journals
        val favoriteJournals = journalDao.getFavoriteJournals(userId).first()
        
        // Assert that only favorite journals are returned
        assertEquals(2, favoriteJournals.size)
        assertTrue(favoriteJournals.all { it.isFavorite })
        assertTrue(favoriteJournals.any { it.title == "Favorite 1" })
        assertTrue(favoriteJournals.any { it.title == "Favorite 2" })
    }

    /**
     * Tests retrieving journal entries that haven't been uploaded yet
     */
    @Test
    fun testGetJournalsPendingUpload() = runTest {
        // Create journals with different upload statuses
        val userId = UUID.randomUUID().toString()
        
        val pendingJournal1 = createTestJournal(
            userId = userId,
            title = "Pending 1",
            isUploaded = false,
            localFilePath = "/path/to/local/file1.aac"
        )
        val pendingJournal2 = createTestJournal(
            userId = userId,
            title = "Pending 2",
            isUploaded = false,
            localFilePath = "/path/to/local/file2.aac"
        )
        val uploadedJournal = createTestJournal(
            userId = userId,
            title = "Uploaded",
            isUploaded = true,
            localFilePath = "/path/to/local/file3.aac",
            storagePath = "remote/path/file3.aac"
        )
        val noLocalPathJournal = createTestJournal(
            userId = userId,
            title = "No Local Path",
            isUploaded = false,
            localFilePath = null
        )
        
        journalDao.insertJournal(pendingJournal1)
        journalDao.insertJournal(pendingJournal2)
        journalDao.insertJournal(uploadedJournal)
        journalDao.insertJournal(noLocalPathJournal)
        
        // Retrieve journals pending upload
        val pendingJournals = journalDao.getJournalsPendingUpload(userId)
        
        // Assert that only journals not uploaded with a local file path are returned
        assertEquals(2, pendingJournals.size)
        assertTrue(pendingJournals.all { !it.isUploaded && it.localFilePath != null })
    }

    /**
     * Tests updating the upload status and storage path of a journal entry
     */
    @Test
    fun testUpdateUploadStatus() = runTest {
        // Create a journal with isUploaded = false
        val journal = createTestJournal(isUploaded = false)
        journalDao.insertJournal(journal)
        
        // Update the upload status
        val storagePath = "remote/path/file.aac"
        val updatedAt = System.currentTimeMillis()
        journalDao.updateUploadStatus(journal.id, true, storagePath, updatedAt)
        
        // Retrieve the updated journal
        val retrievedJournal = journalDao.getJournalById(journal.id).first()
        
        // Assert that the upload status was correctly updated
        assertNotNull(retrievedJournal)
        assertTrue(retrievedJournal?.isUploaded == true)
        assertEquals(storagePath, retrievedJournal?.storagePath)
        assertEquals(updatedAt, retrievedJournal?.updatedAt)
    }

    /**
     * Tests updating the favorite status of a journal entry
     */
    @Test
    fun testUpdateFavoriteStatus() = runTest {
        // Create a journal with isFavorite = false
        val journal = createTestJournal(isFavorite = false)
        journalDao.insertJournal(journal)
        
        // Update the favorite status
        val updatedAt = System.currentTimeMillis()
        journalDao.updateFavoriteStatus(journal.id, true, updatedAt)
        
        // Retrieve the updated journal
        val retrievedJournal = journalDao.getJournalById(journal.id).first()
        
        // Assert that the favorite status was correctly updated
        assertNotNull(retrievedJournal)
        assertTrue(retrievedJournal?.isFavorite == true)
        assertEquals(updatedAt, retrievedJournal?.updatedAt)
    }

    /**
     * Tests updating the local file path of a journal entry
     */
    @Test
    fun testUpdateLocalFilePath() = runTest {
        // Create a journal with null local file path
        val journal = createTestJournal(localFilePath = null)
        journalDao.insertJournal(journal)
        
        // Update the local file path
        val localFilePath = "/updated/path/file.aac"
        val updatedAt = System.currentTimeMillis()
        journalDao.updateLocalFilePath(journal.id, localFilePath, updatedAt)
        
        // Retrieve the updated journal
        val retrievedJournal = journalDao.getJournalById(journal.id).first()
        
        // Assert that the local file path was correctly updated
        assertNotNull(retrievedJournal)
        assertEquals(localFilePath, retrievedJournal?.localFilePath)
        assertEquals(updatedAt, retrievedJournal?.updatedAt)
    }

    /**
     * Tests counting the total number of journal entries for a user
     */
    @Test
    fun testGetJournalCount() = runTest {
        // Create multiple journals for different users
        val userId1 = UUID.randomUUID().toString()
        val userId2 = UUID.randomUUID().toString()
        
        journalDao.insertJournal(createTestJournal(userId = userId1))
        journalDao.insertJournal(createTestJournal(userId = userId1))
        journalDao.insertJournal(createTestJournal(userId = userId1))
        journalDao.insertJournal(createTestJournal(userId = userId2))
        
        // Get journal count for user1
        val journalCount = journalDao.getJournalCount(userId1).first()
        
        // Assert that the count matches the expected number
        assertEquals(3, journalCount)
    }

    /**
     * Tests calculating the total time spent journaling for a user
     */
    @Test
    fun testGetTotalJournalingTime() = runTest {
        // Create journals with different durations
        val userId = UUID.randomUUID().toString()
        
        journalDao.insertJournal(createTestJournal(userId = userId, durationSeconds = 120))
        journalDao.insertJournal(createTestJournal(userId = userId, durationSeconds = 180))
        journalDao.insertJournal(createTestJournal(userId = userId, durationSeconds = 300))
        
        // Get total journaling time
        val totalTime = journalDao.getTotalJournalingTime(userId).first()
        
        // Assert that the total time is the sum of all durations
        assertEquals(600, totalTime) // 120 + 180 + 300 = 600
    }

    /**
     * Tests retrieving journal entries within a specific date range
     */
    @Test
    fun testGetJournalsByDateRange() = runTest {
        // Create journals with different creation dates
        val userId = UUID.randomUUID().toString()
        val baseTime = System.currentTimeMillis()
        
        // Journal from 3 days ago
        val journal1 = createTestJournal(userId = userId, title = "3 days ago")
            .copy(createdAt = baseTime - 3 * 86400000L)
        
        // Journal from 2 days ago
        val journal2 = createTestJournal(userId = userId, title = "2 days ago")
            .copy(createdAt = baseTime - 2 * 86400000L)
        
        // Journal from 1 day ago
        val journal3 = createTestJournal(userId = userId, title = "1 day ago")
            .copy(createdAt = baseTime - 1 * 86400000L)
        
        // Today's journal
        val journal4 = createTestJournal(userId = userId, title = "Today")
            .copy(createdAt = baseTime)
        
        journalDao.insertJournal(journal1)
        journalDao.insertJournal(journal2)
        journalDao.insertJournal(journal3)
        journalDao.insertJournal(journal4)
        
        // Define a date range for the last 2 days
        val startDate = baseTime - 2 * 86400000L
        val endDate = baseTime + 1000L // Add a small buffer
        
        // Get journals within the date range
        val journals = journalDao.getJournalsByDateRange(userId, startDate, endDate).first()
        
        // Assert that only journals within the date range are returned
        assertEquals(3, journals.size)
        assertTrue(journals.any { it.title == "2 days ago" })
        assertTrue(journals.any { it.title == "1 day ago" })
        assertTrue(journals.any { it.title == "Today" })
        assertFalse(journals.any { it.title == "3 days ago" })
    }

    /**
     * Tests retrieving journal entries with a positive emotional shift
     */
    @Test
    fun testGetJournalsWithPositiveShift() = runTest {
        // Create journals with different emotional shifts
        val userId = UUID.randomUUID().toString()
        
        // Journal with positive shift (post intensity > pre intensity)
        val positiveShiftJournal = createTestJournal(userId = userId, title = "Positive shift")
        
        // Journal with negative shift (post intensity < pre intensity)
        val negativeShiftJournal = createTestJournal(userId = userId, title = "Negative shift").let {
            it.copy(
                preEmotionalState = it.preEmotionalState.copy(intensity = 5),
                postEmotionalState = it.postEmotionalState.copy(intensity = 3)
            )
        }
        
        // Journal with no shift (post intensity = pre intensity)
        val noShiftJournal = createTestJournal(userId = userId, title = "No shift").let {
            it.copy(
                preEmotionalState = it.preEmotionalState.copy(intensity = 5),
                postEmotionalState = it.postEmotionalState.copy(intensity = 5)
            )
        }
        
        journalDao.insertJournal(positiveShiftJournal)
        journalDao.insertJournal(negativeShiftJournal)
        journalDao.insertJournal(noShiftJournal)
        
        // Get journals with positive emotional shift
        val journalsWithPositiveShift = journalDao.getJournalsWithPositiveShift(userId).first()
        
        // Assert that only journals with positive shift are returned
        assertEquals(1, journalsWithPositiveShift.size)
        assertEquals("Positive shift", journalsWithPositiveShift[0].title)
    }

    /**
     * Tests retrieving journal entries with a specific pre-recording emotion type
     */
    @Test
    fun testGetJournalsByEmotionType() = runTest {
        // Create journals with different pre-recording emotion types
        val userId = UUID.randomUUID().toString()
        
        // Journal with ANXIETY pre-emotion
        val anxietyJournal = createTestJournal(userId = userId, title = "Anxiety journal")
        // Note: createTestJournal already creates journals with ANXIETY pre-emotion by default
        
        // Journal with SADNESS pre-emotion
        val sadnessJournal = createTestJournal(userId = userId, title = "Sadness journal").let {
            it.copy(
                preEmotionalState = it.preEmotionalState.copy(emotionType = EmotionType.SADNESS)
            )
        }
        
        // Journal with JOY pre-emotion
        val joyJournal = createTestJournal(userId = userId, title = "Joy journal").let {
            it.copy(
                preEmotionalState = it.preEmotionalState.copy(emotionType = EmotionType.JOY)
            )
        }
        
        journalDao.insertJournal(anxietyJournal)
        journalDao.insertJournal(sadnessJournal)
        journalDao.insertJournal(joyJournal)
        
        // Get journals with ANXIETY pre-emotion
        val anxietyJournals = journalDao.getJournalsByEmotionType(userId, EmotionType.ANXIETY.toString()).first()
        
        // Assert that only journals with ANXIETY pre-emotion are returned
        assertEquals(1, anxietyJournals.size)
        assertEquals("Anxiety journal", anxietyJournals[0].title)
    }

    /**
     * Tests retrieving the most recent journal entries for a user
     */
    @Test
    fun testGetRecentJournals() = runTest {
        // Create multiple journals with different creation dates
        val userId = UUID.randomUUID().toString()
        val baseTime = System.currentTimeMillis()
        
        val journal1 = createTestJournal(userId = userId, title = "Oldest")
            .copy(createdAt = baseTime - 4 * 86400000L)
        
        val journal2 = createTestJournal(userId = userId, title = "Old")
            .copy(createdAt = baseTime - 3 * 86400000L)
        
        val journal3 = createTestJournal(userId = userId, title = "Recent")
            .copy(createdAt = baseTime - 2 * 86400000L)
        
        val journal4 = createTestJournal(userId = userId, title = "Most recent")
            .copy(createdAt = baseTime - 1 * 86400000L)
        
        val journal5 = createTestJournal(userId = userId, title = "Newest")
            .copy(createdAt = baseTime)
        
        journalDao.insertJournal(journal1)
        journalDao.insertJournal(journal2)
        journalDao.insertJournal(journal3)
        journalDao.insertJournal(journal4)
        journalDao.insertJournal(journal5)
        
        // Get the 3 most recent journals
        val recentJournals = journalDao.getRecentJournals(userId, 3).first()
        
        // Assert that only the 3 most recent journals are returned in correct order
        assertEquals(3, recentJournals.size)
        assertEquals("Newest", recentJournals[0].title)
        assertEquals("Most recent", recentJournals[1].title)
        assertEquals("Recent", recentJournals[2].title)
    }
}