package com.amirawellness.data.local.dao

import androidx.test.ext.junit.runners.AndroidJUnit4 // androidx.test.ext:1.1.5
import androidx.test.platform.app.InstrumentationRegistry // androidx.test.platform:1.5.0
import org.junit.After // org.junit:4.13.2
import org.junit.Before // org.junit:4.13.2
import org.junit.Test // org.junit:4.13.2
import org.junit.runner.RunWith // org.junit:4.13.2
import org.junit.Assert.* // org.junit:4.13.2
import kotlinx.coroutines.flow.first // kotlinx.coroutines:1.7+
import kotlinx.coroutines.runBlocking // kotlinx.coroutines:1.7+
import kotlinx.coroutines.test.runTest // kotlinx.coroutines:1.7+
import com.amirawellness.data.models.EmotionalState
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.core.constants.AppConstants.EmotionContext
import com.amirawellness.data.local.AppDatabase
import java.util.UUID // standard
import java.util.Date // standard

/**
 * Instrumented test class for testing the EmotionalStateDao implementation in the Room database.
 * Tests verify that all database operations related to emotional states work correctly, including
 * CRUD operations, queries, and analysis functions for emotional trends and patterns.
 */
@RunWith(AndroidJUnit4::class)
class EmotionalStateDaoTest {
    private lateinit var db: AppDatabase
    private lateinit var emotionalStateDao: EmotionalStateDao

    @Before
    fun setup() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        db = AppDatabase.getTestInstance(context)
        emotionalStateDao = db.emotionalStateDao()
    }

    @After
    fun tearDown() {
        db.close()
    }

    /**
     * Helper method to create a test emotional state
     */
    private fun createTestEmotionalState(
        userId: String,
        emotionType: EmotionType,
        intensity: Int,
        context: String,
        notes: String? = null,
        relatedJournalId: String? = null,
        relatedToolId: String? = null
    ): EmotionalState {
        return EmotionalState(
            id = UUID.randomUUID().toString(),
            emotionType = emotionType,
            intensity = intensity,
            context = context,
            notes = notes,
            createdAt = System.currentTimeMillis(),
            relatedJournalId = relatedJournalId,
            relatedToolId = relatedToolId
        )
    }

    @Test
    fun testInsertAndGetEmotionalState() = runTest {
        // Create a test emotional state
        val testState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString(),
            notes = "Feeling great today!"
        )

        // Insert the emotional state
        val insertedId = emotionalStateDao.insertEmotionalState(testState)
        assertTrue("Insertion should succeed with positive row ID", insertedId > 0)

        // Retrieve the emotional state by ID
        val retrievedState = emotionalStateDao.getEmotionalStateById(testState.id!!).first()
        
        // Assert that the retrieved state matches the inserted one
        assertNotNull("Retrieved state should not be null", retrievedState)
        assertEquals("Emotion type should match", EmotionType.JOY, retrievedState!!.emotionType)
        assertEquals("Intensity should match", 7, retrievedState.intensity)
        assertEquals("Context should match", EmotionContext.STANDALONE.toString(), retrievedState.context)
        assertEquals("Notes should match", "Feeling great today!", retrievedState.notes)
    }

    @Test
    fun testUpdateEmotionalState() = runTest {
        // Create and insert a test emotional state
        val testState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.ANXIETY,
            intensity = 8,
            context = EmotionContext.DAILY_CHECK_IN.toString(),
            notes = "Initial note"
        )
        emotionalStateDao.insertEmotionalState(testState)

        // Modify and update the emotional state
        val updatedState = testState.copy(
            intensity = 5,
            notes = "Updated note"
        )
        val updateResult = emotionalStateDao.updateEmotionalState(updatedState)
        assertEquals("Update should affect 1 row", 1, updateResult)

        // Retrieve the updated emotional state
        val retrievedState = emotionalStateDao.getEmotionalStateById(testState.id!!).first()
        
        // Assert the state was correctly updated
        assertNotNull("Retrieved state should not be null", retrievedState)
        assertEquals("Updated intensity should match", 5, retrievedState!!.intensity)
        assertEquals("Updated notes should match", "Updated note", retrievedState.notes)
        assertEquals("Emotion type should remain unchanged", EmotionType.ANXIETY, retrievedState.emotionType)
    }

    @Test
    fun testDeleteEmotionalState() = runTest {
        // Create and insert a test emotional state
        val testState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.SADNESS,
            intensity = 6,
            context = EmotionContext.POST_JOURNALING.toString()
        )
        emotionalStateDao.insertEmotionalState(testState)
        
        // Verify the state exists
        var retrievedState = emotionalStateDao.getEmotionalStateById(testState.id!!).first()
        assertNotNull("State should exist before deletion", retrievedState)
        
        // Delete the emotional state
        val deleteResult = emotionalStateDao.deleteEmotionalState(testState)
        assertEquals("Deletion should affect 1 row", 1, deleteResult)
        
        // Verify the state no longer exists
        retrievedState = emotionalStateDao.getEmotionalStateById(testState.id!!).first()
        assertNull("State should not exist after deletion", retrievedState)
    }

    @Test
    fun testGetEmotionalStatesByUserId() = runTest {
        // Create and insert multiple emotional states for different users
        val user1 = "user1"
        val user2 = "user2"
        
        val user1State1 = createTestEmotionalState(
            userId = user1,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString(),
            createdAt = System.currentTimeMillis()
        )
        
        val user1State2 = createTestEmotionalState(
            userId = user1,
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.DAILY_CHECK_IN.toString(),
            createdAt = System.currentTimeMillis() + 1000 // 1 second later
        )
        
        val user2State = createTestEmotionalState(
            userId = user2,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        )
        
        emotionalStateDao.insertEmotionalState(user1State1)
        emotionalStateDao.insertEmotionalState(user1State2)
        emotionalStateDao.insertEmotionalState(user2State)
        
        // Retrieve emotional states for user1
        val user1States = emotionalStateDao.getEmotionalStatesByUserId(user1).first()
        
        // Assert that only user1's states are returned
        assertEquals("Should return 2 states for user1", 2, user1States.size)
        assertTrue("Should contain user1's first state", user1States.any { it.id == user1State1.id })
        assertTrue("Should contain user1's second state", user1States.any { it.id == user1State2.id })
        
        // Verify ordering - newest first
        assertEquals("First state should be the newest", user1State2.id, user1States[0].id)
        assertEquals("Second state should be the oldest", user1State1.id, user1States[1].id)
    }

    @Test
    fun testGetEmotionalStatesByJournalId() = runTest {
        // Create a journal ID
        val journalId = UUID.randomUUID().toString()
        
        // Create and insert multiple emotional states with different journal IDs
        val preJournalState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.PRE_JOURNALING.toString(),
            relatedJournalId = journalId
        )
        
        val postJournalState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.POST_JOURNALING.toString(),
            relatedJournalId = journalId
        )
        
        val unrelatedState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.JOY,
            intensity = 9,
            context = EmotionContext.STANDALONE.toString(),
            relatedJournalId = UUID.randomUUID().toString()
        )
        
        emotionalStateDao.insertEmotionalState(preJournalState)
        emotionalStateDao.insertEmotionalState(postJournalState)
        emotionalStateDao.insertEmotionalState(unrelatedState)
        
        // Retrieve emotional states for the specific journal ID
        val journalStates = emotionalStateDao.getEmotionalStatesByJournalId(journalId).first()
        
        // Assert that only states with the specific journal ID are returned
        assertEquals("Should return 2 states for the journal", 2, journalStates.size)
        assertTrue("Should contain pre-journal state", journalStates.any { it.id == preJournalState.id })
        assertTrue("Should contain post-journal state", journalStates.any { it.id == postJournalState.id })
    }

    @Test
    fun testGetEmotionalStatesByToolId() = runTest {
        // Create a tool ID
        val toolId = UUID.randomUUID().toString()
        
        // Create and insert multiple emotional states with different tool IDs
        val preToolState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.TOOL_USAGE.toString(),
            relatedToolId = toolId
        )
        
        val postToolState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.TOOL_USAGE.toString(),
            relatedToolId = toolId
        )
        
        val unrelatedState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.JOY,
            intensity = 9,
            context = EmotionContext.STANDALONE.toString(),
            relatedToolId = UUID.randomUUID().toString()
        )
        
        emotionalStateDao.insertEmotionalState(preToolState)
        emotionalStateDao.insertEmotionalState(postToolState)
        emotionalStateDao.insertEmotionalState(unrelatedState)
        
        // Retrieve emotional states for the specific tool ID
        val toolStates = emotionalStateDao.getEmotionalStatesByToolId(toolId).first()
        
        // Assert that only states with the specific tool ID are returned
        assertEquals("Should return 2 states for the tool", 2, toolStates.size)
        assertTrue("Should contain pre-tool state", toolStates.any { it.id == preToolState.id })
        assertTrue("Should contain post-tool state", toolStates.any { it.id == postToolState.id })
    }

    @Test
    fun testGetEmotionalStatesByContext() = runTest {
        val userId = "user123"
        val context = EmotionContext.DAILY_CHECK_IN.toString()
        
        // Create and insert multiple emotional states with different contexts
        val dailyCheckIn1 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = context
        )
        
        val dailyCheckIn2 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = context
        )
        
        val differentContext = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        )
        
        emotionalStateDao.insertEmotionalState(dailyCheckIn1)
        emotionalStateDao.insertEmotionalState(dailyCheckIn2)
        emotionalStateDao.insertEmotionalState(differentContext)
        
        // Retrieve emotional states for the specific context
        val contextStates = emotionalStateDao.getEmotionalStatesByContext(userId, context).first()
        
        // Assert that only states with the specific context are returned
        assertEquals("Should return 2 states for the context", 2, contextStates.size)
        assertTrue("Should contain first daily check-in", contextStates.any { it.id == dailyCheckIn1.id })
        assertTrue("Should contain second daily check-in", contextStates.any { it.id == dailyCheckIn2.id })
    }

    @Test
    fun testGetEmotionalStatesByDateRange() = runTest {
        val userId = "user123"
        val now = System.currentTimeMillis()
        val oneDayMs = 24 * 60 * 60 * 1000L
        
        // Create states with different dates
        val oldState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.SADNESS,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = now - (2 * oneDayMs)) // 2 days ago
        
        val midState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = now - oneDayMs) // 1 day ago
        
        val newState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 8,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = now) // Today
        
        emotionalStateDao.insertEmotionalState(oldState)
        emotionalStateDao.insertEmotionalState(midState)
        emotionalStateDao.insertEmotionalState(newState)
        
        // Define date range: between yesterday and today
        val startDate = now - oneDayMs
        val endDate = now + oneDayMs // Include a buffer to ensure today is covered
        
        // Retrieve emotional states within the date range
        val rangeStates = emotionalStateDao.getEmotionalStatesByDateRange(userId, startDate, endDate).first()
        
        // Assert that only states within the date range are returned
        assertEquals("Should return 2 states in the date range", 2, rangeStates.size)
        assertTrue("Should contain mid state", rangeStates.any { it.id == midState.id })
        assertTrue("Should contain new state", rangeStates.any { it.id == newState.id })
    }

    @Test
    fun testGetEmotionalStatesByEmotionType() = runTest {
        val userId = "user123"
        
        // Create states with different emotion types
        val joyState1 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        )
        
        val joyState2 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 8,
            context = EmotionContext.DAILY_CHECK_IN.toString()
        )
        
        val anxietyState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        )
        
        emotionalStateDao.insertEmotionalState(joyState1)
        emotionalStateDao.insertEmotionalState(joyState2)
        emotionalStateDao.insertEmotionalState(anxietyState)
        
        // Retrieve emotional states for JOY emotion type
        val joyStates = emotionalStateDao.getEmotionalStatesByEmotionType(userId, EmotionType.JOY.toString()).first()
        
        // Assert that only JOY states are returned
        assertEquals("Should return 2 JOY states", 2, joyStates.size)
        assertTrue("Should contain first joy state", joyStates.any { it.id == joyState1.id })
        assertTrue("Should contain second joy state", joyStates.any { it.id == joyState2.id })
    }

    @Test
    fun testGetEmotionTypeFrequency() = runTest {
        val userId = "user123"
        
        // Create states with different emotion types
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 8,
            context = EmotionContext.DAILY_CHECK_IN.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.SADNESS,
            intensity = 5,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        // Get emotion type frequency
        val frequency = emotionalStateDao.getEmotionTypeFrequency(userId).first()
        
        // Verify frequency counts
        assertEquals("Should have 3 different emotion types", 3, frequency.size)
        assertEquals("JOY should have frequency of 2", 2, frequency[EmotionType.JOY.toString()])
        assertEquals("ANXIETY should have frequency of 1", 1, frequency[EmotionType.ANXIETY.toString()])
        assertEquals("SADNESS should have frequency of 1", 1, frequency[EmotionType.SADNESS.toString()])
    }

    @Test
    fun testGetAverageIntensityByEmotionType() = runTest {
        val userId = "user123"
        
        // Create states with different emotion types and intensities
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 8,
            context = EmotionContext.DAILY_CHECK_IN.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 9,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.TOOL_USAGE.toString()
        ))
        
        // Get average intensity by emotion type
        val avgIntensities = emotionalStateDao.getAverageIntensityByEmotionType(userId).first()
        
        // Verify average intensities
        assertEquals("Should have 2 different emotion types", 2, avgIntensities.size)
        assertEquals("JOY should have average intensity of 7.0", 7.0f, avgIntensities[EmotionType.JOY.toString()]!!, 0.1f)
        assertEquals("ANXIETY should have average intensity of 8.0", 8.0f, avgIntensities[EmotionType.ANXIETY.toString()]!!, 0.1f)
    }

    @Test
    fun testGetEmotionalStateCount() = runTest {
        val user1 = "user1"
        val user2 = "user2"
        
        // Create states for two different users
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = user1,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = user1,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = user1,
            emotionType = EmotionType.SADNESS,
            intensity = 5,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = user2,
            emotionType = EmotionType.JOY,
            intensity = 8,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        // Get emotional state count for user1
        val count = emotionalStateDao.getEmotionalStateCount(user1).first()
        
        // Verify count
        assertEquals("User1 should have 3 emotional states", 3, count)
    }

    @Test
    fun testGetMostFrequentEmotionType() = runTest {
        val userId = "user123"
        
        // Create states with different emotion types (JOY has highest frequency)
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 8,
            context = EmotionContext.DAILY_CHECK_IN.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 6,
            context = EmotionContext.TOOL_USAGE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 9,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.TOOL_USAGE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.SADNESS,
            intensity = 5,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        // Get most frequent emotion type
        val mostFrequent = emotionalStateDao.getMostFrequentEmotionType(userId).first()
        
        // Verify most frequent emotion type
        assertNotNull("Most frequent emotion type should not be null", mostFrequent)
        assertEquals("JOY should be the most frequent emotion type", EmotionType.JOY.toString(), mostFrequent)
    }

    @Test
    fun testGetEmotionalStatesByUserIdAndLimit() = runTest {
        val userId = "user123"
        val now = System.currentTimeMillis()
        
        // Create multiple emotional states with different creation dates
        val oldestState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.SADNESS,
            intensity = 5,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = now - 3000) // 3 seconds ago
        
        val middleState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = now - 2000) // 2 seconds ago
        
        val newestState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = now - 1000) // 1 second ago
        
        val veryNewestState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = now) // Now
        
        emotionalStateDao.insertEmotionalState(oldestState)
        emotionalStateDao.insertEmotionalState(middleState)
        emotionalStateDao.insertEmotionalState(newestState)
        emotionalStateDao.insertEmotionalState(veryNewestState)
        
        // Get most recent 2 emotional states
        val recentStates = emotionalStateDao.getEmotionalStatesByUserIdAndLimit(userId, 2).first()
        
        // Verify limit and ordering
        assertEquals("Should return only 2 states", 2, recentStates.size)
        assertEquals("First state should be the newest", veryNewestState.id, recentStates[0].id)
        assertEquals("Second state should be the second newest", newestState.id, recentStates[1].id)
    }

    @Test
    fun testGetEmotionalStateCountByDateRange() = runTest {
        val userId = "user123"
        val now = System.currentTimeMillis()
        val oneDayMs = 24 * 60 * 60 * 1000L
        
        // Create calendar instances for specific dates
        val cal = java.util.Calendar.getInstance()
        cal.timeInMillis = now
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        
        val todayStart = cal.timeInMillis
        
        cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
        val yesterdayStart = cal.timeInMillis
        
        cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
        val twoDaysAgoStart = cal.timeInMillis
        
        // Create states with different dates
        val twoDaysAgoState1 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.SADNESS,
            intensity = 5,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = twoDaysAgoStart + 3600000) // 1 hour after start
        
        val twoDaysAgoState2 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = twoDaysAgoStart + 7200000) // 2 hours after start
        
        val yesterdayState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = yesterdayStart + 3600000) // 1 hour after start
        
        val todayState1 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = todayStart + 3600000) // 1 hour after start
        
        val todayState2 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 9,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = todayStart + 7200000) // 2 hours after start
        
        emotionalStateDao.insertEmotionalState(twoDaysAgoState1)
        emotionalStateDao.insertEmotionalState(twoDaysAgoState2)
        emotionalStateDao.insertEmotionalState(yesterdayState)
        emotionalStateDao.insertEmotionalState(todayState1)
        emotionalStateDao.insertEmotionalState(todayState2)
        
        // Define date range: from 2 days ago to today
        val startDate = twoDaysAgoStart
        val endDate = todayStart + oneDayMs // Include all of today
        
        // Get emotional state counts by day
        val dayCounts = emotionalStateDao.getEmotionalStateCountByDateRange(userId, startDate, endDate).first()
        
        // Verify counts by day
        assertEquals("Should have counts for 3 days", 3, dayCounts.size)
        
        // Extract day keys (format is YYYYMMDD as Long)
        val twoDaysAgoKey = java.text.SimpleDateFormat("yyyyMMdd").format(Date(twoDaysAgoStart)).toLong()
        val yesterdayKey = java.text.SimpleDateFormat("yyyyMMdd").format(Date(yesterdayStart)).toLong()
        val todayKey = java.text.SimpleDateFormat("yyyyMMdd").format(Date(todayStart)).toLong()
        
        assertEquals("Two days ago should have 2 entries", 2, dayCounts[twoDaysAgoKey])
        assertEquals("Yesterday should have 1 entry", 1, dayCounts[yesterdayKey])
        assertEquals("Today should have 2 entries", 2, dayCounts[todayKey])
    }

    @Test
    fun testGetIntensityTrendByDateRange() = runTest {
        val userId = "user123"
        val now = System.currentTimeMillis()
        val oneDayMs = 24 * 60 * 60 * 1000L
        
        // Create calendar instances for specific dates
        val cal = java.util.Calendar.getInstance()
        cal.timeInMillis = now
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        
        val todayStart = cal.timeInMillis
        
        cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
        val yesterdayStart = cal.timeInMillis
        
        cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
        val twoDaysAgoStart = cal.timeInMillis
        
        // Create states with different dates and intensities
        val twoDaysAgoState1 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 8,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = twoDaysAgoStart + 3600000) // 1 hour after start
        
        val twoDaysAgoState2 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = twoDaysAgoStart + 7200000) // 2 hours after start
        
        val yesterdayState1 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = yesterdayStart + 3600000) // 1 hour after start
        
        val yesterdayState2 = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.SADNESS,
            intensity = 5,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = yesterdayStart + 7200000) // 2 hours after start
        
        val todayState = createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.CALM,
            intensity = 9,
            context = EmotionContext.STANDALONE.toString()
        ).copy(createdAt = todayStart + 3600000) // 1 hour after start
        
        emotionalStateDao.insertEmotionalState(twoDaysAgoState1)
        emotionalStateDao.insertEmotionalState(twoDaysAgoState2)
        emotionalStateDao.insertEmotionalState(yesterdayState1)
        emotionalStateDao.insertEmotionalState(yesterdayState2)
        emotionalStateDao.insertEmotionalState(todayState)
        
        // Define date range: from 2 days ago to today
        val startDate = twoDaysAgoStart
        val endDate = todayStart + oneDayMs // Include all of today
        
        // Get intensity trend by day
        val intensityTrend = emotionalStateDao.getIntensityTrendByDateRange(userId, startDate, endDate).first()
        
        // Verify average intensities by day
        assertEquals("Should have data for 3 days", 3, intensityTrend.size)
        
        // Extract day keys (format is YYYYMMDD as Long)
        val twoDaysAgoKey = java.text.SimpleDateFormat("yyyyMMdd").format(Date(twoDaysAgoStart)).toLong()
        val yesterdayKey = java.text.SimpleDateFormat("yyyyMMdd").format(Date(yesterdayStart)).toLong()
        val todayKey = java.text.SimpleDateFormat("yyyyMMdd").format(Date(todayStart)).toLong()
        
        assertEquals("Two days ago should have average intensity of 7.0", 7.0f, intensityTrend[twoDaysAgoKey]!!, 0.1f)
        assertEquals("Yesterday should have average intensity of 6.0", 6.0f, intensityTrend[yesterdayKey]!!, 0.1f)
        assertEquals("Today should have average intensity of 9.0", 9.0f, intensityTrend[todayKey]!!, 0.1f)
    }

    @Test
    fun testDeleteEmotionalStatesByJournalId() = runTest {
        // Create a journal ID
        val journalId = UUID.randomUUID().toString()
        
        // Create and insert multiple emotional states with the same journal ID
        val relatedState1 = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.ANXIETY,
            intensity = 7,
            context = EmotionContext.PRE_JOURNALING.toString(),
            relatedJournalId = journalId
        )
        
        val relatedState2 = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.POST_JOURNALING.toString(),
            relatedJournalId = journalId
        )
        
        val unrelatedState = createTestEmotionalState(
            userId = "user123",
            emotionType = EmotionType.JOY,
            intensity = 9,
            context = EmotionContext.STANDALONE.toString(),
            relatedJournalId = UUID.randomUUID().toString()
        )
        
        emotionalStateDao.insertEmotionalState(relatedState1)
        emotionalStateDao.insertEmotionalState(relatedState2)
        emotionalStateDao.insertEmotionalState(unrelatedState)
        
        // Verify that the journal-related states exist
        var journalStates = emotionalStateDao.getEmotionalStatesByJournalId(journalId).first()
        assertEquals("Should have 2 states for the journal before deletion", 2, journalStates.size)
        
        // Delete emotional states with the specific journal ID
        val deleteCount = emotionalStateDao.deleteEmotionalStatesByJournalId(journalId)
        assertEquals("Should delete 2 states", 2, deleteCount)
        
        // Verify that the journal-related states no longer exist
        journalStates = emotionalStateDao.getEmotionalStatesByJournalId(journalId).first()
        assertTrue("Should have no states for the journal after deletion", journalStates.isEmpty())
        
        // Verify that unrelated state still exists
        val remainingState = emotionalStateDao.getEmotionalStateById(unrelatedState.id!!).first()
        assertNotNull("Unrelated state should still exist", remainingState)
    }

    @Test
    fun testDeleteEmotionalStatesByUserId() = runTest {
        // Create and insert emotional states for different users
        val user1 = "user1"
        val user2 = "user2"
        
        val user1State1 = createTestEmotionalState(
            userId = user1,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        )
        
        val user1State2 = createTestEmotionalState(
            userId = user1,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.STANDALONE.toString()
        )
        
        val user2State = createTestEmotionalState(
            userId = user2,
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.STANDALONE.toString()
        )
        
        emotionalStateDao.insertEmotionalState(user1State1)
        emotionalStateDao.insertEmotionalState(user1State2)
        emotionalStateDao.insertEmotionalState(user2State)
        
        // Verify that user1's states exist
        var user1States = emotionalStateDao.getEmotionalStatesByUserId(user1).first()
        assertEquals("Should have 2 states for user1 before deletion", 2, user1States.size)
        
        // Delete emotional states for user1
        val deleteCount = emotionalStateDao.deleteEmotionalStatesByUserId(user1)
        assertEquals("Should delete 2 states", 2, deleteCount)
        
        // Verify that user1's states no longer exist
        user1States = emotionalStateDao.getEmotionalStatesByUserId(user1).first()
        assertTrue("Should have no states for user1 after deletion", user1States.isEmpty())
        
        // Verify that user2's state still exists
        val user2States = emotionalStateDao.getEmotionalStatesByUserId(user2).first()
        assertEquals("Should still have 1 state for user2", 1, user2States.size)
    }

    @Test
    fun testGetEmotionalStateCountByContext() = runTest {
        val userId = "user123"
        
        // Create states with different contexts
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 7,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.CALM,
            intensity = 8,
            context = EmotionContext.STANDALONE.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.ANXIETY,
            intensity = 6,
            context = EmotionContext.DAILY_CHECK_IN.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.SADNESS,
            intensity = 5,
            context = EmotionContext.PRE_JOURNALING.toString()
        ))
        
        emotionalStateDao.insertEmotionalState(createTestEmotionalState(
            userId = userId,
            emotionType = EmotionType.JOY,
            intensity = 8,
            context = EmotionContext.POST_JOURNALING.toString()
        ))
        
        // Get counts by context
        val contextCounts = emotionalStateDao.getEmotionalStateCountByContext(userId).first()
        
        // Verify counts
        assertEquals("Should have counts for 4 contexts", 4, contextCounts.size)
        assertEquals("STANDALONE should have count of 2", 2, contextCounts[EmotionContext.STANDALONE.toString()])
        assertEquals("DAILY_CHECK_IN should have count of 1", 1, contextCounts[EmotionContext.DAILY_CHECK_IN.toString()])
        assertEquals("PRE_JOURNALING should have count of 1", 1, contextCounts[EmotionContext.PRE_JOURNALING.toString()])
        assertEquals("POST_JOURNALING should have count of 1", 1, contextCounts[EmotionContext.POST_JOURNALING.toString()])
    }
}