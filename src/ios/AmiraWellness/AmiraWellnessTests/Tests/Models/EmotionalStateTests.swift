import XCTest
import EmotionalState
import TestData

class EmotionalStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Set up any resources needed for tests
    }

    override func tearDown() {
        // Clean up any resources used in tests
        super.tearDown()
    }

    func testEmotionalStateInitialization() {
        // Create a UUID for testing
        let stateId = UUID()
        let userId = UUID()
        
        // Create an EmotionalState with valid parameters
        let emotionalState = EmotionalState(
            id: stateId,
            userId: userId,
            emotionType: .joy,
            intensity: 7,
            context: .standalone,
            notes: "Test notes",
            relatedJournalId: nil,
            relatedToolId: nil,
            createdAt: Date(),
            updatedAt: nil
        )
        
        // Assert that all properties are correctly set
        XCTAssertEqual(emotionalState.id, stateId)
        XCTAssertEqual(emotionalState.userId, userId)
        XCTAssertEqual(emotionalState.emotionType, .joy)
        XCTAssertEqual(emotionalState.intensity, 7)
        XCTAssertEqual(emotionalState.context, .standalone)
        XCTAssertEqual(emotionalState.notes, "Test notes")
        XCTAssertNil(emotionalState.relatedJournalId)
        XCTAssertNil(emotionalState.relatedToolId)
        XCTAssertNil(emotionalState.updatedAt)
    }
    
    func testEmotionalStateValidation() {
        // Create a valid EmotionalState with intensity in valid range
        let validState = EmotionalState(
            emotionType: .joy,
            intensity: 7,
            context: .standalone
        )
        XCTAssertTrue(validState.isValid())
        
        // Create an invalid EmotionalState with intensity below valid range
        let invalidStateLow = EmotionalState(
            emotionType: .joy,
            intensity: 0,
            context: .standalone
        )
        XCTAssertFalse(invalidStateLow.isValid())
        
        // Create an invalid EmotionalState with intensity above valid range
        let invalidStateHigh = EmotionalState(
            emotionType: .joy,
            intensity: 11,
            context: .standalone
        )
        XCTAssertFalse(invalidStateHigh.isValid())
    }
    
    func testEmotionalStateComparison() {
        // Create a first EmotionalState with joy emotion and intensity 5
        let state1 = EmotionalState(
            emotionType: .joy,
            intensity: 5,
            context: .standalone
        )
        
        // Create a second EmotionalState with same emotion but higher intensity
        let state2 = EmotionalState(
            emotionType: .joy,
            intensity: 8,
            context: .standalone
        )
        
        // Compare the states and verify intensity difference is correct
        let comparison1 = state1.compareWith(state2)
        XCTAssertFalse(comparison1.emotionChanged)
        XCTAssertEqual(comparison1.intensityDifference, 3)
        
        // Create a third EmotionalState with different emotion
        let state3 = EmotionalState(
            emotionType: .anger,
            intensity: 6,
            context: .standalone
        )
        
        // Compare first and third states to verify emotion change is detected
        let comparison2 = state1.compareWith(state3)
        XCTAssertTrue(comparison2.emotionChanged)
        XCTAssertEqual(comparison2.intensityDifference, 1)
        
        // Test various combinations of emotion changes and intensity differences
        let comparison3 = state2.compareWith(state1)
        XCTAssertFalse(comparison3.emotionChanged)
        XCTAssertEqual(comparison3.intensityDifference, -3)
    }
    
    func testEmotionTypeProperties() {
        // Test displayName() method for various emotion types
        XCTAssertEqual(EmotionType.joy.displayName(), "Alegría")
        XCTAssertEqual(EmotionType.anger.displayName(), "Ira")
        XCTAssertEqual(EmotionType.anxiety.displayName(), "Ansiedad")
        
        // Test description() method for various emotion types
        XCTAssertTrue(EmotionType.joy.description().contains("felicidad"))
        XCTAssertTrue(EmotionType.sadness.description().contains("tristeza"))
        XCTAssertTrue(EmotionType.fear.description().contains("amenaza"))
        
        // Test color() method for various emotion types
        XCTAssertEqual(EmotionType.joy.color().hexString, "#FFD700")
        XCTAssertEqual(EmotionType.anger.color().hexString, "#FF0000")
        XCTAssertEqual(EmotionType.calm.color().hexString, "#ADD8E6")
        
        // Test category() method for various emotion types
        XCTAssertEqual(EmotionType.joy.category(), .positive)
        XCTAssertEqual(EmotionType.anger.category(), .negative)
        XCTAssertEqual(EmotionType.surprise.category(), .neutral)
        
        // Verify that all emotion types have a valid category
        for emotionType in EmotionType.allCases {
            XCTAssertNotNil(emotionType.category())
        }
    }
    
    func testEmotionCategoryProperties() {
        // Test displayName() method for all emotion categories
        XCTAssertEqual(EmotionCategory.positive.displayName(), "Positiva")
        XCTAssertEqual(EmotionCategory.negative.displayName(), "Negativa")
        XCTAssertEqual(EmotionCategory.neutral.displayName(), "Neutral")
        
        // Verify that positive emotions are categorized correctly
        XCTAssertEqual(EmotionType.joy.category(), .positive)
        XCTAssertEqual(EmotionType.trust.category(), .positive)
        XCTAssertEqual(EmotionType.hope.category(), .positive)
        
        // Verify that negative emotions are categorized correctly
        XCTAssertEqual(EmotionType.sadness.category(), .negative)
        XCTAssertEqual(EmotionType.anger.category(), .negative)
        XCTAssertEqual(EmotionType.fear.category(), .negative)
        
        // Verify that neutral emotions are categorized correctly
        XCTAssertEqual(EmotionType.surprise.category(), .neutral)
    }
    
    func testCheckInContextProperties() {
        // Test displayName() method for all check-in contexts
        XCTAssertEqual(CheckInContext.preJournaling.displayName(), "Antes de grabar")
        XCTAssertEqual(CheckInContext.postJournaling.displayName(), "Después de grabar")
        XCTAssertEqual(CheckInContext.standalone.displayName(), "Check-in independiente")
        XCTAssertEqual(CheckInContext.toolUsage.displayName(), "Uso de herramienta")
        XCTAssertEqual(CheckInContext.dailyCheckIn.displayName(), "Check-in diario")
        
        // Verify that each context has a unique display name
        let contexts: [CheckInContext] = [
            .preJournaling,
            .postJournaling,
            .standalone,
            .toolUsage,
            .dailyCheckIn
        ]
        
        let displayNames = contexts.map { $0.displayName() }
        XCTAssertEqual(displayNames.count, Set(displayNames).count, "All context display names should be unique")
    }
    
    func testFormattedDate() {
        // Create an EmotionalState with a known date
        let dateComponents = DateComponents(year: 2023, month: 5, day: 15, hour: 10, minute: 30)
        let calendar = Calendar.current
        let testDate = calendar.date(from: dateComponents)!
        
        let emotionalState = EmotionalState(
            emotionType: .joy,
            intensity: 7,
            context: .standalone,
            createdAt: testDate
        )
        
        // Call formattedDate() method
        let formattedDate = emotionalState.formattedDate()
        
        // Verify that the returned string is correctly formatted
        XCTAssertTrue(formattedDate.contains("2023") || formattedDate.contains("23"), "Formatted date should include the year")
        XCTAssertTrue(formattedDate.contains("5") || formattedDate.contains("May") || formattedDate.contains("mayo"), "Formatted date should include the month")
        XCTAssertTrue(formattedDate.contains("15"), "Formatted date should include the day")
        XCTAssertTrue(formattedDate.contains("10:30") || formattedDate.contains("10.30"), "Formatted date should include the time")
    }
    
    func testFormattedIntensity() {
        // Create an EmotionalState with intensity 7
        let emotionalState = EmotionalState(
            emotionType: .joy,
            intensity: 7,
            context: .standalone
        )
        
        // Call formattedIntensity() method
        let formattedIntensity = emotionalState.formattedIntensity()
        
        // Verify that the returned string is '7/10'
        XCTAssertEqual(formattedIntensity, "7/10")
        
        // Test with different intensity values
        let emotionalState2 = EmotionalState(
            emotionType: .joy,
            intensity: 10,
            context: .standalone
        )
        XCTAssertEqual(emotionalState2.formattedIntensity(), "10/10")
        
        let emotionalState3 = EmotionalState(
            emotionType: .joy,
            intensity: 1,
            context: .standalone
        )
        XCTAssertEqual(emotionalState3.formattedIntensity(), "1/10")
    }
    
    func testSummary() {
        // Create an EmotionalState with known emotion type and intensity
        let emotionalState = EmotionalState(
            emotionType: .joy,
            intensity: 7,
            context: .standalone
        )
        
        // Call summary() method
        let summary = emotionalState.summary()
        
        // Verify that the returned string contains both the emotion name and formatted intensity
        XCTAssertTrue(summary.contains("Alegría"))
        XCTAssertTrue(summary.contains("7/10"))
        XCTAssertEqual(summary, "Alegría - 7/10")
    }
    
    func testMockEmotionalState() {
        // Create a mock EmotionalState using TestData.mockEmotionalState()
        let mockState = TestData.mockEmotionalState()
        
        // Verify that the mock object has valid properties
        XCTAssertNotNil(mockState.id)
        XCTAssertEqual(mockState.emotionType, .calm) // Default emotion type in TestData
        XCTAssertEqual(mockState.intensity, 7) // Default intensity in TestData
        XCTAssertEqual(mockState.context, .standalone) // Default context in TestData
        
        // Create a mock with custom emotion type and intensity
        let mockState2 = TestData.mockEmotionalState(emotionType: .joy, intensity: 8, context: .dailyCheckIn)
        
        // Verify that the custom properties are correctly set
        XCTAssertEqual(mockState2.emotionType, .joy)
        XCTAssertEqual(mockState2.intensity, 8)
        XCTAssertEqual(mockState2.context, .dailyCheckIn)
        
        // Test createTestEmotionalState function
        let customState = createTestEmotionalState(
            emotionType: .anxiety,
            intensity: 6,
            context: .preJournaling
        )
        
        // Verify custom created state
        XCTAssertEqual(customState.emotionType, .anxiety)
        XCTAssertEqual(customState.intensity, 6)
        XCTAssertEqual(customState.context, .preJournaling)
    }
}