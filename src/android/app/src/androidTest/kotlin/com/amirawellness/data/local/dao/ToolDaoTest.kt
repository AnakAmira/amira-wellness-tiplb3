package com.amirawellness.data.local.dao

import androidx.test.ext.junit.runners.AndroidJUnit4 // androidx.test.ext:1.1.5
import androidx.test.platform.app.InstrumentationRegistry // androidx.test.platform:1.5.0
import com.amirawellness.core.constants.AppConstants.EmotionType
import com.amirawellness.data.local.AppDatabase
import com.amirawellness.data.models.Tool
import com.amirawellness.data.models.ToolCategory
import com.amirawellness.data.models.ToolContent
import com.amirawellness.data.models.ToolContentType
import kotlinx.coroutines.flow.first // kotlinx.coroutines:1.7+
import kotlinx.coroutines.runBlocking // kotlinx.coroutines:1.7+
import org.junit.After // org.junit:4.13.2
import org.junit.Assert.* // org.junit:4.13.2
import org.junit.Before // org.junit:4.13.2
import org.junit.Test // org.junit:4.13.2
import org.junit.runner.RunWith // org.junit:4.13.2
import java.util.UUID // standard

/**
 * Test class for validating ToolDao operations in the Room database
 */
@RunWith(AndroidJUnit4::class)
class ToolDaoTest {
    private lateinit var db: AppDatabase
    private lateinit var toolDao: ToolDao

    /**
     * Sets up the test environment before each test
     */
    @Before
    fun setup() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        // Create in-memory test database instance
        db = AppDatabase.getTestInstance(context)
        toolDao = db.toolDao()
    }

    /**
     * Cleans up the test environment after each test
     */
    @After
    fun tearDown() {
        db.close()
    }

    /**
     * Helper method to create a test tool category
     */
    private fun createTestToolCategory(name: String, description: String): ToolCategory {
        return ToolCategory(
            id = UUID.randomUUID().toString(),
            name = name,
            description = description,
            iconUrl = null,
            toolCount = 0
        )
    }

    /**
     * Helper method to create a test tool
     */
    private fun createTestTool(
        name: String,
        description: String,
        category: ToolCategory,
        contentType: ToolContentType = ToolContentType.TEXT,
        isFavorite: Boolean = false,
        usageCount: Int = 0,
        targetEmotions: List<EmotionType> = listOf(EmotionType.JOY),
        estimatedDuration: Int = 5
    ): Tool {
        return Tool(
            id = UUID.randomUUID().toString(),
            name = name,
            description = description,
            category = category,
            contentType = contentType,
            content = ToolContent(
                title = "Test Title for $name",
                instructions = "Instructions for $name",
                mediaUrl = null,
                steps = null,
                additionalResources = null
            ),
            isFavorite = isFavorite,
            usageCount = usageCount,
            targetEmotions = targetEmotions,
            estimatedDuration = estimatedDuration
        )
    }

    /**
     * Tests inserting a tool and retrieving it by ID
     */
    @Test
    fun testInsertAndGetTool() = runBlocking {
        val category = createTestToolCategory("Category 1", "Test category 1")
        val tool = createTestTool("Test Tool", "Tool for testing", category)
        
        // Insert the tool into the database
        val insertId = toolDao.insertTool(tool)
        assertTrue(insertId > 0)
        
        // Retrieve the tool by ID
        val retrievedTool = toolDao.getToolById(tool.id).first()
        assertNotNull(retrievedTool)
        assertEquals(tool.id, retrievedTool?.id)
        assertEquals(tool.name, retrievedTool?.name)
        assertEquals(tool.description, retrievedTool?.description)
    }

    /**
     * Tests inserting multiple tools at once
     */
    @Test
    fun testInsertMultipleTools() = runBlocking {
        val category = createTestToolCategory("Category 1", "Test category 1")
        val tools = listOf(
            createTestTool("Tool 1", "First tool", category),
            createTestTool("Tool 2", "Second tool", category),
            createTestTool("Tool 3", "Third tool", category)
        )
        
        // Insert the tools into the database
        val insertIds = toolDao.insertTools(tools)
        assertEquals(tools.size, insertIds.size)
        
        // Retrieve all tools
        val allTools = toolDao.getAllTools().first()
        assertEquals(tools.size, allTools.size)
        
        // Verify each tool was inserted correctly
        tools.forEach { tool ->
            val found = allTools.any { it.id == tool.id }
            assertTrue(found)
        }
    }

    /**
     * Tests updating an existing tool
     */
    @Test
    fun testUpdateTool() = runBlocking {
        val category = createTestToolCategory("Category 1", "Test category 1")
        val tool = createTestTool("Original Name", "Original description", category)
        
        // Create and insert a test tool
        toolDao.insertTool(tool)
        
        // Modify the tool properties
        val updatedTool = tool.copy(
            name = "Updated Name",
            description = "Updated description",
            estimatedDuration = 10
        )
        val updateCount = toolDao.updateTool(updatedTool)
        assertEquals(1, updateCount)
        
        // Retrieve the updated tool
        val retrievedTool = toolDao.getToolById(tool.id).first()
        assertNotNull(retrievedTool)
        assertEquals(updatedTool.name, retrievedTool?.name)
        assertEquals(updatedTool.description, retrievedTool?.description)
        assertEquals(updatedTool.estimatedDuration, retrievedTool?.estimatedDuration)
    }

    /**
     * Tests deleting a tool
     */
    @Test
    fun testDeleteTool() = runBlocking {
        val category = createTestToolCategory("Category 1", "Test category 1")
        val tool = createTestTool("Test Tool", "Tool for testing", category)
        
        // Create and insert a test tool
        toolDao.insertTool(tool)
        
        // Delete the tool from the database
        val deleteCount = toolDao.deleteTool(tool)
        assertEquals(1, deleteCount)
        
        // Try to retrieve the deleted tool
        val retrievedTool = toolDao.getToolById(tool.id).first()
        assertNull(retrievedTool)
    }

    /**
     * Tests retrieving all tools
     */
    @Test
    fun testGetAllTools() = runBlocking {
        val category = createTestToolCategory("Category 1", "Test category 1")
        val tools = listOf(
            createTestTool("B Tool", "B description", category),
            createTestTool("A Tool", "A description", category),
            createTestTool("C Tool", "C description", category)
        )
        
        // Create and insert multiple test tools
        tools.forEach { toolDao.insertTool(it) }
        
        // Retrieve all tools
        val allTools = toolDao.getAllTools().first()
        
        // Verify the correct number of tools is returned
        assertEquals(tools.size, allTools.size)
        
        // Verify that the tools are ordered by name in ascending order
        assertEquals("A Tool", allTools[0].name)
        assertEquals("B Tool", allTools[1].name)
        assertEquals("C Tool", allTools[2].name)
    }

    /**
     * Tests retrieving tools by category
     */
    @Test
    fun testGetToolsByCategory() = runBlocking {
        val category1 = createTestToolCategory("Category 1", "First category")
        val category2 = createTestToolCategory("Category 2", "Second category")
        
        val toolsCategory1 = listOf(
            createTestTool("Tool A1", "Tool A1 desc", category1),
            createTestTool("Tool A2", "Tool A2 desc", category1)
        )
        
        val toolsCategory2 = listOf(
            createTestTool("Tool B1", "Tool B1 desc", category2),
            createTestTool("Tool B2", "Tool B2 desc", category2),
            createTestTool("Tool B3", "Tool B3 desc", category2)
        )
        
        // Create and insert tools with different categories
        toolsCategory1.forEach { toolDao.insertTool(it) }
        toolsCategory2.forEach { toolDao.insertTool(it) }
        
        // Retrieve tools for a specific category
        val retrievedTools = toolDao.getToolsByCategory(category2.id).first()
        
        // Verify the correct number of tools is returned
        assertEquals(toolsCategory2.size, retrievedTools.size)
        
        // Verify all tools belong to the specified category
        retrievedTools.forEach { tool ->
            assertEquals(category2.id, tool.category.id)
        }
        
        // Verify that the tools are ordered by name in ascending order
        assertEquals("Tool B1", retrievedTools[0].name)
        assertEquals("Tool B2", retrievedTools[1].name)
        assertEquals("Tool B3", retrievedTools[2].name)
    }

    /**
     * Tests retrieving favorite tools
     */
    @Test
    fun testGetFavoriteTools() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        
        val favoriteTools = listOf(
            createTestTool("Favorite 1", "Favorite 1 desc", category, isFavorite = true),
            createTestTool("Favorite 2", "Favorite 2 desc", category, isFavorite = true)
        )
        
        val nonFavoriteTools = listOf(
            createTestTool("Tool 1", "Tool 1 desc", category, isFavorite = false),
            createTestTool("Tool 2", "Tool 2 desc", category, isFavorite = false)
        )
        
        // Create and insert tools with different favorite statuses
        favoriteTools.forEach { toolDao.insertTool(it) }
        nonFavoriteTools.forEach { toolDao.insertTool(it) }
        
        // Retrieve favorite tools
        val retrievedFavorites = toolDao.getFavoriteTools().first()
        
        // Verify the correct number of tools is returned
        assertEquals(favoriteTools.size, retrievedFavorites.size)
        
        // Verify all tools are favorites
        retrievedFavorites.forEach { tool ->
            assertTrue(tool.isFavorite)
        }
        
        // Verify that the tools are ordered by name in ascending order
        assertEquals("Favorite 1", retrievedFavorites[0].name)
        assertEquals("Favorite 2", retrievedFavorites[1].name)
    }

    /**
     * Tests retrieving tools by target emotion type
     */
    @Test
    fun testGetToolsByEmotionType() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        
        val joyTools = listOf(
            createTestTool("Joy Tool 1", "Joy 1 desc", category, targetEmotions = listOf(EmotionType.JOY)),
            createTestTool("Joy Tool 2", "Joy 2 desc", category, targetEmotions = listOf(EmotionType.JOY))
        )
        
        val anxietyTools = listOf(
            createTestTool("Anxiety Tool", "Anxiety desc", category, targetEmotions = listOf(EmotionType.ANXIETY)),
            createTestTool("Mixed Tool", "Mixed desc", category, targetEmotions = listOf(EmotionType.ANXIETY, EmotionType.JOY))
        )
        
        // Create and insert tools targeting different emotions
        joyTools.forEach { toolDao.insertTool(it) }
        anxietyTools.forEach { toolDao.insertTool(it) }
        
        // Retrieve tools for a specific emotion type
        val retrievedJoyTools = toolDao.getToolsByEmotionType(EmotionType.JOY.name).first()
        
        // Verify the correct number of tools is returned (including the mixed one)
        assertEquals(3, retrievedJoyTools.size)
        
        // Verify all tools target the JOY emotion
        retrievedJoyTools.forEach { tool ->
            assertTrue(tool.targetEmotions.contains(EmotionType.JOY))
        }
        
        // Verify that the tools are ordered by name in ascending order
        assertEquals("Joy Tool 1", retrievedJoyTools[0].name)
        assertEquals("Joy Tool 2", retrievedJoyTools[1].name)
        assertEquals("Mixed Tool", retrievedJoyTools[2].name)
    }

    /**
     * Tests updating the favorite status of a tool
     */
    @Test
    fun testUpdateFavoriteStatus() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        val tool = createTestTool("Test Tool", "Tool desc", category, isFavorite = false)
        
        // Create and insert a test tool with isFavorite=false
        toolDao.insertTool(tool)
        
        // Update the favorite status to true
        val updateCount = toolDao.updateFavoriteStatus(tool.id, true)
        assertEquals(1, updateCount)
        
        // Retrieve the updated tool
        val retrievedTool = toolDao.getToolById(tool.id).first()
        assertNotNull(retrievedTool)
        assertTrue(retrievedTool?.isFavorite == true)
    }

    /**
     * Tests incrementing the usage count of a tool
     */
    @Test
    fun testIncrementUsageCount() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        val tool = createTestTool("Test Tool", "Tool desc", category, usageCount = 0)
        
        // Create and insert a test tool with usageCount=0
        toolDao.insertTool(tool)
        
        // Increment the usage count
        val updateCount = toolDao.incrementUsageCount(tool.id)
        assertEquals(1, updateCount)
        
        // Retrieve the updated tool
        val retrievedTool = toolDao.getToolById(tool.id).first()
        assertNotNull(retrievedTool)
        assertEquals(1, retrievedTool?.usageCount)
    }

    /**
     * Tests searching for tools by name or description
     */
    @Test
    fun testSearchTools() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        
        val tools = listOf(
            createTestTool("Breathing Exercise", "Calming breath work", category),
            createTestTool("Meditation Guide", "Guided meditation", category),
            createTestTool("Journaling Prompt", "Writing exercise", category)
        )
        
        // Create and insert tools with different names and descriptions
        tools.forEach { toolDao.insertTool(it) }
        
        // Search for tools with a specific query string
        val searchResults = toolDao.searchTools("breath").first()
        
        // Verify search results
        assertEquals(1, searchResults.size)
        assertEquals("Breathing Exercise", searchResults[0].name)
        
        // Verify that the search is case-insensitive
        val exerciseResults = toolDao.searchTools("exercise").first()
        assertEquals(2, exerciseResults.size)
        assertTrue(exerciseResults.any { it.name == "Breathing Exercise" })
        assertTrue(exerciseResults.any { it.name == "Journaling Prompt" })
    }

    /**
     * Tests retrieving tools with duration less than or equal to specified minutes
     */
    @Test
    fun testGetToolsByDuration() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        
        val tools = listOf(
            createTestTool("Quick Tool", "5 minute tool", category, estimatedDuration = 5),
            createTestTool("Medium Tool", "10 minute tool", category, estimatedDuration = 10),
            createTestTool("Long Tool", "20 minute tool", category, estimatedDuration = 20)
        )
        
        // Create and insert tools with different durations
        tools.forEach { toolDao.insertTool(it) }
        
        // Retrieve tools with duration less than or equal to a specific value
        val shortTools = toolDao.getToolsByDuration(10).first()
        
        // Verify results
        assertEquals(2, shortTools.size)
        assertTrue(shortTools.any { it.name == "Quick Tool" })
        assertTrue(shortTools.any { it.name == "Medium Tool" })
        
        // Verify that the tools are ordered by duration in ascending order
        assertEquals("Quick Tool", shortTools[0].name)
        assertEquals("Medium Tool", shortTools[1].name)
    }

    /**
     * Tests counting the total number of tools in the database
     */
    @Test
    fun testGetToolCount() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        
        // Initially there should be no tools
        val initialCount = toolDao.getToolCount().first()
        assertEquals(0, initialCount)
        
        // Create and insert multiple tools
        val tools = listOf(
            createTestTool("Tool 1", "First tool", category),
            createTestTool("Tool 2", "Second tool", category),
            createTestTool("Tool 3", "Third tool", category)
        )
        tools.forEach { toolDao.insertTool(it) }
        
        // Get the tool count
        val updatedCount = toolDao.getToolCount().first()
        assertEquals(3, updatedCount)
    }

    /**
     * Tests counting the number of tools in a specific category
     */
    @Test
    fun testGetToolCountByCategory() = runBlocking {
        val category1 = createTestToolCategory("Category 1", "First category")
        val category2 = createTestToolCategory("Category 2", "Second category")
        
        // Create and insert tools with different categories
        val toolsCategory1 = listOf(
            createTestTool("Tool A1", "Tool A1 desc", category1),
            createTestTool("Tool A2", "Tool A2 desc", category1)
        )
        toolsCategory1.forEach { toolDao.insertTool(it) }
        
        val toolsCategory2 = listOf(
            createTestTool("Tool B1", "Tool B1 desc", category2),
            createTestTool("Tool B2", "Tool B2 desc", category2),
            createTestTool("Tool B3", "Tool B3 desc", category2)
        )
        toolsCategory2.forEach { toolDao.insertTool(it) }
        
        // Get the tool count for a specific category
        val category1Count = toolDao.getToolCountByCategory(category1.id).first()
        assertEquals(2, category1Count)
        
        val category2Count = toolDao.getToolCountByCategory(category2.id).first()
        assertEquals(3, category2Count)
    }

    /**
     * Tests retrieving the most frequently used tools
     */
    @Test
    fun testGetMostUsedTools() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        
        val tools = listOf(
            createTestTool("Rarely Used", "Tool desc", category, usageCount = 2),
            createTestTool("Sometimes Used", "Tool desc", category, usageCount = 5),
            createTestTool("Frequently Used", "Tool desc", category, usageCount = 10),
            createTestTool("Most Used", "Tool desc", category, usageCount = 15)
        )
        
        // Create and insert tools with different usage counts
        tools.forEach { toolDao.insertTool(it) }
        
        // Retrieve the most used tools with a limit
        val mostUsed = toolDao.getMostUsedTools(2).first()
        
        // Verify the tools are returned in descending order of usage count
        assertEquals(2, mostUsed.size)
        assertEquals("Most Used", mostUsed[0].name)
        assertEquals("Frequently Used", mostUsed[1].name)
    }

    /**
     * Tests deleting all tools from the database
     */
    @Test
    fun testDeleteAllTools() = runBlocking {
        val category = createTestToolCategory("Category", "Test category")
        
        // Create and insert multiple tools
        val tools = listOf(
            createTestTool("Tool 1", "First tool", category),
            createTestTool("Tool 2", "Second tool", category),
            createTestTool("Tool 3", "Third tool", category)
        )
        tools.forEach { toolDao.insertTool(it) }
        
        // Verify tools were inserted
        val initialCount = toolDao.getToolCount().first()
        assertEquals(3, initialCount)
        
        // Delete all tools from the database
        val deleteCount = toolDao.deleteAllTools()
        assertEquals(3, deleteCount)
        
        // Verify no tools remain in the database
        val allTools = toolDao.getAllTools().first()
        assertTrue(allTools.isEmpty())
    }
}