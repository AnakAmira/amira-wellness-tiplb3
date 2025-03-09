import XCTest
@testable import AmiraWellness

class ToolTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set up code that runs before each test
    }
    
    override func tearDown() {
        // Clean up code that runs after each test
        super.tearDown()
    }
    
    func testToolInitialization() {
        // Create a tool with valid parameters and test all properties
        let toolId = UUID()
        let content = ToolContent(
            title: "Test Tool",
            instructions: "Test instructions",
            mediaUrl: "https://example.com/test.mp3",
            steps: [
                ToolStep(id: 1, order: 1, title: "Step 1", description: "Do this first", durationSeconds: 60),
                ToolStep(id: 2, order: 2, title: "Step 2", description: "Do this next", durationSeconds: 120)
            ],
            additionalResources: [
                Resource(
                    id: UUID(),
                    title: "Test Resource",
                    description: "Test resource description",
                    url: "https://example.com/resource",
                    type: .article
                )
            ]
        )
        
        let targetEmotions: [EmotionType] = [.anxiety, .overwhelm]
        let createdAt = Date()
        
        let tool = Tool(
            id: toolId,
            name: "Breathing Exercise",
            description: "A simple breathing exercise to reduce anxiety",
            category: .breathing,
            contentType: .guidedExercise,
            content: content,
            isFavorite: true,
            usageCount: 5,
            targetEmotions: targetEmotions,
            estimatedDuration: 10,
            difficulty: .beginner,
            createdAt: createdAt,
            updatedAt: nil
        )
        
        // Assert all properties are correctly set
        XCTAssertEqual(tool.id, toolId)
        XCTAssertEqual(tool.name, "Breathing Exercise")
        XCTAssertEqual(tool.description, "A simple breathing exercise to reduce anxiety")
        XCTAssertEqual(tool.category, .breathing)
        XCTAssertEqual(tool.contentType, .guidedExercise)
        XCTAssertEqual(tool.content, content)
        XCTAssertTrue(tool.isFavorite)
        XCTAssertEqual(tool.usageCount, 5)
        XCTAssertEqual(tool.targetEmotions, targetEmotions)
        XCTAssertEqual(tool.estimatedDuration, 10)
        XCTAssertEqual(tool.difficulty, .beginner)
        XCTAssertEqual(tool.createdAt, createdAt)
        XCTAssertNil(tool.updatedAt)
    }
    
    func testToolContentTypeProperties() {
        // Test displayName() method for all content types
        XCTAssertEqual(ToolContentType.text.displayName(), "Texto")
        XCTAssertEqual(ToolContentType.audio.displayName(), "Audio")
        XCTAssertEqual(ToolContentType.video.displayName(), "Video")
        XCTAssertEqual(ToolContentType.interactive.displayName(), "Interactivo")
        XCTAssertEqual(ToolContentType.guidedExercise.displayName(), "Ejercicio guiado")
    }
    
    func testToolDifficultyProperties() {
        // Test displayName() method for all difficulty levels
        XCTAssertEqual(ToolDifficulty.beginner.displayName(), "Principiante")
        XCTAssertEqual(ToolDifficulty.intermediate.displayName(), "Intermedio")
        XCTAssertEqual(ToolDifficulty.advanced.displayName(), "Avanzado")
    }
    
    func testResourceTypeProperties() {
        // Test displayName() method for all resource types
        XCTAssertEqual(ResourceType.article.displayName(), "Artículo")
        XCTAssertEqual(ResourceType.audio.displayName(), "Audio")
        XCTAssertEqual(ResourceType.video.displayName(), "Video")
        XCTAssertEqual(ResourceType.externalLink.displayName(), "Enlace externo")
    }
    
    func testToolContentInitialization() {
        // Test initializing ToolContent with minimum required properties
        let minimalToolContent = ToolContent(
            title: "Minimal Tool Content",
            instructions: "Test instructions"
        )
        
        XCTAssertEqual(minimalToolContent.title, "Minimal Tool Content")
        XCTAssertEqual(minimalToolContent.instructions, "Test instructions")
        XCTAssertNil(minimalToolContent.mediaUrl)
        XCTAssertNil(minimalToolContent.steps)
        XCTAssertNil(minimalToolContent.additionalResources)
        
        // Test initializing ToolContent with all properties
        let steps = [
            ToolStep(id: 1, order: 1, title: "Step 1", description: "Do this first", durationSeconds: 60)
        ]
        
        let resources = [
            Resource(
                id: UUID(),
                title: "Test Resource",
                description: "Resource description",
                url: "https://example.com/resource",
                type: .article
            )
        ]
        
        let fullToolContent = ToolContent(
            title: "Full Tool Content",
            instructions: "Test instructions",
            mediaUrl: "https://example.com/test.mp3",
            steps: steps,
            additionalResources: resources
        )
        
        XCTAssertEqual(fullToolContent.title, "Full Tool Content")
        XCTAssertEqual(fullToolContent.instructions, "Test instructions")
        XCTAssertEqual(fullToolContent.mediaUrl, "https://example.com/test.mp3")
        XCTAssertEqual(fullToolContent.steps, steps)
        XCTAssertEqual(fullToolContent.additionalResources, resources)
    }
    
    func testToolStepInitialization() {
        // Test initializing ToolStep with required properties
        let toolStep = ToolStep(
            id: 1,
            order: 2,
            title: "Test Step",
            description: "Step description",
            durationSeconds: 90
        )
        
        XCTAssertEqual(toolStep.id, 1)
        XCTAssertEqual(toolStep.order, 2)
        XCTAssertEqual(toolStep.title, "Test Step")
        XCTAssertEqual(toolStep.description, "Step description")
        XCTAssertEqual(toolStep.durationSeconds, 90)
        XCTAssertNil(toolStep.mediaUrl)
        
        // Test initializing ToolStep with all properties, including mediaUrl
        let fullToolStep = ToolStep(
            id: 3,
            order: 4,
            title: "Full Test Step",
            description: "Full step description",
            durationSeconds: 120,
            mediaUrl: "https://example.com/step.mp3"
        )
        
        XCTAssertEqual(fullToolStep.id, 3)
        XCTAssertEqual(fullToolStep.order, 4)
        XCTAssertEqual(fullToolStep.title, "Full Test Step")
        XCTAssertEqual(fullToolStep.description, "Full step description")
        XCTAssertEqual(fullToolStep.durationSeconds, 120)
        XCTAssertEqual(fullToolStep.mediaUrl, "https://example.com/step.mp3")
    }
    
    func testToolStepFormattedDuration() {
        // Test the formatted duration for a ToolStep
        let step = ToolStep(
            id: 1,
            order: 1,
            title: "Test Step",
            description: "Step description",
            durationSeconds: 65 // 1 minute and 5 seconds
        )
        
        XCTAssertEqual(step.formattedDuration(), "01:05")
        
        // Test another duration
        let longStep = ToolStep(
            id: 2,
            order: 2,
            title: "Long Step",
            description: "Long step description",
            durationSeconds: 125 // 2 minutes and 5 seconds
        )
        
        XCTAssertEqual(longStep.formattedDuration(), "02:05")
        
        // Test with zero duration
        let zeroStep = ToolStep(
            id: 3,
            order: 3,
            title: "Zero Step",
            description: "Zero step description",
            durationSeconds: 0
        )
        
        XCTAssertEqual(zeroStep.formattedDuration(), "00:00")
    }
    
    func testResourceInitialization() {
        // Test initializing Resource with all properties
        let resourceId = UUID()
        let resource = Resource(
            id: resourceId,
            title: "Test Resource",
            description: "Resource description",
            url: "https://example.com/resource",
            type: .article
        )
        
        XCTAssertEqual(resource.id, resourceId)
        XCTAssertEqual(resource.title, "Test Resource")
        XCTAssertEqual(resource.description, "Resource description")
        XCTAssertEqual(resource.url, "https://example.com/resource")
        XCTAssertEqual(resource.type, .article)
    }
    
    func testToolFormattedDuration() {
        // Test the formatted duration for a Tool
        let content = ToolContent(title: "Test Content", instructions: "Test instructions")
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: content,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertEqual(tool.formattedDuration(), "5 min")
        
        // Test with a different duration
        let longTool = Tool(
            name: "Long Tool",
            description: "Long tool description",
            category: .meditation,
            contentType: .audio,
            content: content,
            targetEmotions: [.anxiety],
            estimatedDuration: 30,
            difficulty: .intermediate
        )
        
        XCTAssertEqual(longTool.formattedDuration(), "30 min")
        
        // Test with zero duration
        let zeroTool = Tool(
            name: "Zero Tool",
            description: "Zero tool description",
            category: .breathing,
            contentType: .text,
            content: content,
            targetEmotions: [.anxiety],
            estimatedDuration: 0,
            difficulty: .beginner
        )
        
        XCTAssertEqual(zeroTool.formattedDuration(), "0 min")
    }
    
    func testToolToggleFavorite() {
        // Test toggling favorite status from false to true
        let content = ToolContent(title: "Test Content", instructions: "Test instructions")
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: content,
            isFavorite: false,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        let toggledTool = tool.toggleFavorite()
        XCTAssertTrue(toggledTool.isFavorite)
        XCTAssertNotNil(toggledTool.updatedAt)
        
        // Test toggling favorite status from true to false
        let toggledAgain = toggledTool.toggleFavorite()
        XCTAssertFalse(toggledAgain.isFavorite)
        XCTAssertNotNil(toggledAgain.updatedAt)
    }
    
    func testToolIncrementUsageCount() {
        // Test incrementing usage count from 0
        let content = ToolContent(title: "Test Content", instructions: "Test instructions")
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: content,
            usageCount: 0,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        let incrementedTool = tool.incrementUsageCount()
        XCTAssertEqual(incrementedTool.usageCount, 1)
        XCTAssertNotNil(incrementedTool.updatedAt)
        
        // Test incrementing usage count from a non-zero value
        let incrementedAgain = incrementedTool.incrementUsageCount()
        XCTAssertEqual(incrementedAgain.usageCount, 2)
        XCTAssertNotNil(incrementedAgain.updatedAt)
    }
    
    func testToolIsRecommendedFor() {
        // Test a tool that is recommended for a specific emotion
        let content = ToolContent(title: "Test Content", instructions: "Test instructions")
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: content,
            targetEmotions: [.anxiety, .stress],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertTrue(tool.isRecommendedFor(emotionType: .anxiety))
        XCTAssertFalse(tool.isRecommendedFor(emotionType: .joy))
        
        // Test a tool with no target emotions
        let emptyTool = Tool(
            name: "Empty Tool",
            description: "Empty tool description",
            category: .breathing,
            contentType: .text,
            content: content,
            targetEmotions: [],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertFalse(emptyTool.isRecommendedFor(emotionType: .anxiety))
    }
    
    func testToolHasMediaContent() {
        // Test a tool with media content
        let contentWithMedia = ToolContent(
            title: "Test Content",
            instructions: "Test instructions",
            mediaUrl: "https://example.com/test.mp3"
        )
        
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .audio,
            content: contentWithMedia,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertTrue(tool.hasMediaContent())
        
        // Test a tool without media content
        let contentWithoutMedia = ToolContent(
            title: "Test Content",
            instructions: "Test instructions"
        )
        
        let toolWithoutMedia = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: contentWithoutMedia,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertFalse(toolWithoutMedia.hasMediaContent())
    }
    
    func testToolHasSteps() {
        // Test a tool with steps
        let contentWithSteps = ToolContent(
            title: "Test Content",
            instructions: "Test instructions",
            steps: [
                ToolStep(id: 1, order: 1, title: "Step 1", description: "Step 1 description", durationSeconds: 60)
            ]
        )
        
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .guidedExercise,
            content: contentWithSteps,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertTrue(tool.hasSteps())
        
        // Test a tool without steps
        let contentWithoutSteps = ToolContent(
            title: "Test Content",
            instructions: "Test instructions"
        )
        
        let toolWithoutSteps = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: contentWithoutSteps,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertFalse(toolWithoutSteps.hasSteps())
        
        // Test a tool with empty steps array
        let contentWithEmptySteps = ToolContent(
            title: "Test Content",
            instructions: "Test instructions",
            steps: []
        )
        
        let toolWithEmptySteps = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .guidedExercise,
            content: contentWithEmptySteps,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertFalse(toolWithEmptySteps.hasSteps())
    }
    
    func testToolHasAdditionalResources() {
        // Test a tool with additional resources
        let contentWithResources = ToolContent(
            title: "Test Content",
            instructions: "Test instructions",
            additionalResources: [
                Resource(
                    title: "Test Resource",
                    description: "Resource description",
                    url: "https://example.com/resource",
                    type: .article
                )
            ]
        )
        
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: contentWithResources,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertTrue(tool.hasAdditionalResources())
        
        // Test a tool without additional resources
        let contentWithoutResources = ToolContent(
            title: "Test Content",
            instructions: "Test instructions"
        )
        
        let toolWithoutResources = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: contentWithoutResources,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertFalse(toolWithoutResources.hasAdditionalResources())
        
        // Test a tool with empty resources array
        let contentWithEmptyResources = ToolContent(
            title: "Test Content",
            instructions: "Test instructions",
            additionalResources: []
        )
        
        let toolWithEmptyResources = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: contentWithEmptyResources,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertFalse(toolWithEmptyResources.hasAdditionalResources())
    }
    
    func testToolFormattedDate() {
        // Test the formatted date for a Tool
        let content = ToolContent(title: "Test Content", instructions: "Test instructions")
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        
        let tool = Tool(
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .text,
            content: content,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner,
            createdAt: date
        )
        
        // Create a date formatter with the same style as in the Tool model
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let expectedDateString = formatter.string(from: date)
        
        XCTAssertEqual(tool.formattedDate(), expectedDateString)
    }
    
    func testToolEquality() {
        // Test that tools with the same ID are considered equal
        let content1 = ToolContent(title: "Content 1", instructions: "Instructions 1")
        let content2 = ToolContent(title: "Content 2", instructions: "Instructions 2")
        
        let toolId = UUID()
        
        let tool1 = Tool(
            id: toolId,
            name: "Tool 1",
            description: "Description 1",
            category: .breathing,
            contentType: .text,
            content: content1,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        let tool2 = Tool(
            id: toolId,
            name: "Tool 2", // Different name
            description: "Description 2", // Different description
            category: .meditation, // Different category
            contentType: .audio, // Different content type
            content: content2, // Different content
            targetEmotions: [.joy], // Different target emotions
            estimatedDuration: 10, // Different duration
            difficulty: .advanced // Different difficulty
        )
        
        XCTAssertEqual(tool1, tool2, "Tools with the same ID should be considered equal")
        
        // Test that tools with different IDs are not equal
        let tool3 = Tool(
            id: UUID(), // Different ID
            name: "Tool 1",
            description: "Description 1",
            category: .breathing,
            contentType: .text,
            content: content1,
            targetEmotions: [.anxiety],
            estimatedDuration: 5,
            difficulty: .beginner
        )
        
        XCTAssertNotEqual(tool1, tool3, "Tools with different IDs should not be equal")
    }
    
    func testToolCodable() {
        // Test encoding and decoding a Tool object
        let toolId = UUID()
        let resourceId = UUID()
        
        let resource = Resource(
            id: resourceId,
            title: "Test Resource",
            description: "Resource description",
            url: "https://example.com/resource",
            type: .article
        )
        
        let step = ToolStep(
            id: 1,
            order: 1,
            title: "Test Step",
            description: "Step description",
            durationSeconds: 60,
            mediaUrl: "https://example.com/step.mp3"
        )
        
        let content = ToolContent(
            title: "Test Content",
            instructions: "Test instructions",
            mediaUrl: "https://example.com/test.mp3",
            steps: [step],
            additionalResources: [resource]
        )
        
        let createdAt = Date()
        let updatedAt = Date(timeIntervalSinceNow: 3600) // 1 hour later
        
        let tool = Tool(
            id: toolId,
            name: "Test Tool",
            description: "Tool description",
            category: .breathing,
            contentType: .guidedExercise,
            content: content,
            isFavorite: true,
            usageCount: 5,
            targetEmotions: [.anxiety, .overwhelm],
            estimatedDuration: 10,
            difficulty: .beginner,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Encode the tool
        let encoder = JSONEncoder()
        
        do {
            let encodedData = try encoder.encode(tool)
            
            // Decode the tool
            let decoder = JSONDecoder()
            let decodedTool = try decoder.decode(Tool.self, from: encodedData)
            
            // Verify all properties were correctly encoded and decoded
            XCTAssertEqual(decodedTool.id, toolId)
            XCTAssertEqual(decodedTool.name, "Test Tool")
            XCTAssertEqual(decodedTool.description, "Tool description")
            XCTAssertEqual(decodedTool.category, .breathing)
            XCTAssertEqual(decodedTool.contentType, .guidedExercise)
            XCTAssertEqual(decodedTool.isFavorite, true)
            XCTAssertEqual(decodedTool.usageCount, 5)
            XCTAssertEqual(decodedTool.targetEmotions, [.anxiety, .overwhelm])
            XCTAssertEqual(decodedTool.estimatedDuration, 10)
            XCTAssertEqual(decodedTool.difficulty, .beginner)
            
            // Compare dates - Note: This might fail due to precision loss in JSON encoding/decoding
            // Use a reasonable epsilon for date comparison (e.g., 1 second)
            XCTAssertEqual(decodedTool.createdAt.timeIntervalSince1970, createdAt.timeIntervalSince1970, accuracy: 1)
            XCTAssertEqual(decodedTool.updatedAt?.timeIntervalSince1970, updatedAt.timeIntervalSince1970, accuracy: 1)
            
            // Verify content was correctly encoded and decoded
            XCTAssertEqual(decodedTool.content.title, "Test Content")
            XCTAssertEqual(decodedTool.content.instructions, "Test instructions")
            XCTAssertEqual(decodedTool.content.mediaUrl, "https://example.com/test.mp3")
            
            // Verify steps were correctly encoded and decoded
            XCTAssertEqual(decodedTool.content.steps?.count, 1)
            XCTAssertEqual(decodedTool.content.steps?[0].id, 1)
            XCTAssertEqual(decodedTool.content.steps?[0].order, 1)
            XCTAssertEqual(decodedTool.content.steps?[0].title, "Test Step")
            XCTAssertEqual(decodedTool.content.steps?[0].description, "Step description")
            XCTAssertEqual(decodedTool.content.steps?[0].durationSeconds, 60)
            XCTAssertEqual(decodedTool.content.steps?[0].mediaUrl, "https://example.com/step.mp3")
            
            // Verify resources were correctly encoded and decoded
            XCTAssertEqual(decodedTool.content.additionalResources?.count, 1)
            XCTAssertEqual(decodedTool.content.additionalResources?[0].id, resourceId)
            XCTAssertEqual(decodedTool.content.additionalResources?[0].title, "Test Resource")
            XCTAssertEqual(decodedTool.content.additionalResources?[0].description, "Resource description")
            XCTAssertEqual(decodedTool.content.additionalResources?[0].url, "https://example.com/resource")
            XCTAssertEqual(decodedTool.content.additionalResources?[0].type, .article)
            
        } catch {
            XCTFail("Failed to encode or decode Tool: \(error)")
        }
    }
    
    func testMockToolCreation() {
        // Test the TestData.mockTool helper function
        let mockTool = TestData.mockTool()
        
        // Verify that the mock tool has valid properties
        XCTAssertEqual(mockTool.id, TestData.testToolId)
        XCTAssertFalse(mockTool.isFavorite) // Default is false
        XCTAssertEqual(mockTool.usageCount, 5)
        XCTAssertEqual(mockTool.category, .breathing) // Default category
        XCTAssertEqual(mockTool.contentType, .guidedExercise)
        XCTAssertEqual(mockTool.difficulty, .beginner)
        XCTAssertNotNil(mockTool.content)
        XCTAssertNotEmpty(mockTool.targetEmotions)
        
        // Test creating a mock tool with custom parameters
        let customMockTool = TestData.mockTool(category: .meditation, isFavorite: true)
        
        XCTAssertEqual(customMockTool.id, TestData.testToolId)
        XCTAssertTrue(customMockTool.isFavorite)
        XCTAssertEqual(customMockTool.category, .meditation)
        XCTAssertEqual(customMockTool.contentType, .audio) // contentType changes based on category
    }
}