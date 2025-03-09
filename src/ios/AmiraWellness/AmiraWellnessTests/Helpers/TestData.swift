import Foundation // For basic data types and date handling

// Import internal models from main application
import User
import EmotionalState
import Journal
import Tool
import ToolCategory
import Achievement
import Streak
import EmotionalTrend

/**
 * Creates a mock User object for testing.
 * 
 * - Parameters:
 *   - id: Optional UUID for the user, defaults to a new UUID
 *   - isPremium: Whether the user has a premium subscription
 * 
 * - Returns: A mock User object with test data
 */
func createTestUser(id: UUID? = nil, isPremium: Bool = false) -> User {
    let userId = id ?? UUID()
    return User(
        id: userId,
        email: "test@example.com",
        name: "Test User",
        createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
        updatedAt: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
        emailVerified: true,
        accountStatus: .active,
        subscriptionTier: isPremium ? .premium : .free,
        languagePreference: "es",
        lastLoginDate: Date().addingTimeInterval(-1 * 24 * 60 * 60), // 1 day ago
        preferences: ["notificationsEnabled": true, "dailyReminderTime": "09:00", "themeMode": "light"]
    )
}

/**
 * Creates a mock EmotionalState object for testing.
 * 
 * - Parameters:
 *   - id: Optional UUID for the emotional state, defaults to a new UUID
 *   - emotionType: The type of emotion, defaults to .calm
 *   - intensity: The intensity of the emotion (1-10), defaults to 7
 *   - context: The context of the check-in, defaults to .standalone
 * 
 * - Returns: A mock EmotionalState object with test data
 */
func createTestEmotionalState(id: UUID? = nil, emotionType: EmotionType? = nil, intensity: Int? = nil, context: CheckInContext? = nil) -> EmotionalState {
    let stateId = id ?? UUID()
    return EmotionalState(
        id: stateId,
        userId: TestData.testUserId,
        emotionType: emotionType ?? .calm,
        intensity: intensity ?? 7,
        context: context ?? .standalone,
        notes: "Test emotional state notes",
        createdAt: Date()
    )
}

/**
 * Creates a mock Journal object for testing.
 * 
 * - Parameters:
 *   - id: Optional UUID for the journal, defaults to a new UUID
 *   - withPostEmotionalState: Whether to include a post-recording emotional state
 *   - isFavorite: Whether the journal is marked as favorite
 * 
 * - Returns: A mock Journal object with test data
 */
func createTestJournal(id: UUID? = nil, withPostEmotionalState: Bool = true, isFavorite: Bool = false) -> Journal {
    let journalId = id ?? UUID()
    
    let preEmotionalState = createTestEmotionalState(
        emotionType: .anxiety, 
        intensity: 6, 
        context: .preJournaling
    )
    
    let postEmotionalState = withPostEmotionalState ? createTestEmotionalState(
        emotionType: .calm, 
        intensity: 8, 
        context: .postJournaling
    ) : nil
    
    let audioMetadata = createTestAudioMetadata()
    
    return Journal(
        id: journalId,
        userId: TestData.testUserId,
        title: "Test Journal Entry",
        createdAt: Date(),
        durationSeconds: 180, // 3 minutes
        isFavorite: isFavorite,
        isUploaded: true,
        storagePath: "journals/\(journalId.uuidString).aac",
        encryptionIv: "test-encryption-iv-base64-encoded",
        preEmotionalState: preEmotionalState,
        postEmotionalState: postEmotionalState,
        audioMetadata: audioMetadata,
        localFileUrl: URL(string: "file:///test/journals/\(journalId.uuidString).aac")
    )
}

/**
 * Creates a mock AudioMetadata object for testing.
 * 
 * - Returns: A mock AudioMetadata object with test data
 */
func createTestAudioMetadata() -> AudioMetadata {
    return AudioMetadata(
        fileFormat: "AAC",
        fileSizeBytes: 1_500_000, // ~1.5 MB
        sampleRate: 44100.0,
        bitRate: 128000,
        channels: 1,
        checksum: "test-audio-checksum-hash"
    )
}

/**
 * Creates a mock Tool object for testing.
 * 
 * - Parameters:
 *   - id: Optional UUID for the tool, defaults to a new UUID
 *   - category: The category of the tool, defaults to .breathing
 *   - isFavorite: Whether the tool is marked as favorite
 * 
 * - Returns: A mock Tool object with test data
 */
func createTestTool(id: UUID? = nil, category: ToolCategory? = nil, isFavorite: Bool = false) -> Tool {
    let toolId = id ?? UUID()
    let toolCategory = category ?? .breathing
    let contentType: ToolContentType = toolCategory == .breathing ? .guidedExercise : 
                                     toolCategory == .meditation ? .audio :
                                     toolCategory == .journaling ? .text :
                                     toolCategory == .somatic ? .interactive : .text
    
    let toolContent = createTestToolContent(contentType: contentType)
    
    return Tool(
        id: toolId,
        name: "Test \(toolCategory.displayName()) Tool",
        description: "This is a test tool for \(toolCategory.displayName())",
        category: toolCategory,
        contentType: contentType,
        content: toolContent,
        isFavorite: isFavorite,
        usageCount: 5,
        targetEmotions: [.anxiety, .overwhelm, .frustration],
        estimatedDuration: 5, // 5 minutes
        difficulty: .beginner,
        createdAt: Date().addingTimeInterval(-60 * 24 * 60 * 60) // 60 days ago
    )
}

/**
 * Creates a mock ToolContent object for testing.
 * 
 * - Parameters:
 *   - contentType: The type of content, determines structure of content
 * 
 * - Returns: A mock ToolContent object with test data
 */
func createTestToolContent(contentType: ToolContentType? = nil) -> ToolContent {
    let type = contentType ?? .guidedExercise
    
    var steps: [ToolStep]? = nil
    var mediaUrl: String? = nil
    var resources: [Resource]? = nil
    
    switch type {
    case .guidedExercise:
        steps = [
            createTestToolStep(id: 1, order: 1),
            createTestToolStep(id: 2, order: 2),
            createTestToolStep(id: 3, order: 3)
        ]
    case .audio:
        mediaUrl = "https://example.com/audio/test-audio.mp3"
    case .video:
        mediaUrl = "https://example.com/video/test-video.mp4"
    case .text:
        // Text content doesn't need steps or media
        break
    case .interactive:
        steps = [
            createTestToolStep(id: 1, order: 1),
            createTestToolStep(id: 2, order: 2)
        ]
        mediaUrl = "https://example.com/interactive/test-content.json"
    }
    
    resources = [
        createTestResource(type: .article),
        createTestResource(type: .externalLink)
    ]
    
    return ToolContent(
        title: "Test Tool Content",
        instructions: "These are test instructions for using this tool.",
        mediaUrl: mediaUrl,
        steps: steps,
        additionalResources: resources
    )
}

/**
 * Creates a mock ToolStep object for testing.
 * 
 * - Parameters:
 *   - id: The identifier for the step
 *   - order: The order of the step in the sequence
 * 
 * - Returns: A mock ToolStep object with test data
 */
func createTestToolStep(id: Int, order: Int) -> ToolStep {
    return ToolStep(
        id: id,
        order: order,
        title: "Step \(order)",
        description: "This is test step \(order) of the tool process.",
        durationSeconds: 60, // 1 minute per step
        mediaUrl: order % 2 == 0 ? "https://example.com/steps/step\(order).mp3" : nil
    )
}

/**
 * Creates a mock Resource object for testing.
 * 
 * - Parameters:
 *   - id: Optional UUID for the resource, defaults to a new UUID
 *   - type: The type of resource, defaults to .article
 * 
 * - Returns: A mock Resource object with test data
 */
func createTestResource(id: UUID? = nil, type: ResourceType? = nil) -> Resource {
    let resourceId = id ?? UUID()
    let resourceType = type ?? .article
    
    return Resource(
        id: resourceId,
        title: "Test \(resourceType.displayName()) Resource",
        description: "This is a test resource of type \(resourceType.displayName())",
        url: "https://example.com/resources/\(resourceType.rawValue)/test-resource",
        type: resourceType
    )
}

/**
 * Creates a mock Achievement object for testing.
 * 
 * - Parameters:
 *   - id: Optional UUID for the achievement, defaults to a new UUID
 *   - type: The type of achievement, defaults to .firstStep
 *   - isEarned: Whether the achievement has been earned
 * 
 * - Returns: A mock Achievement object with test data
 */
func createTestAchievement(id: UUID? = nil, type: AchievementType? = nil, isEarned: Bool = false) -> Achievement {
    let achievementId = id ?? UUID()
    let achievementType = type ?? .firstStep
    
    var category: AchievementCategory = .milestone
    var name = "Test Achievement"
    var description = "This is a test achievement"
    var points = 10
    
    switch achievementType {
    case .firstStep:
        category = .milestone
        name = "Primer Paso"
        description = "Completa tu primer check-in emocional"
        points = 10
    case .streak3Days:
        category = .streak
        name = "Racha de 3 días"
        description = "Mantén una racha de actividad durante 3 días consecutivos"
        points = 15
    case .streak7Days:
        category = .streak
        name = "Racha de 7 días"
        description = "Mantén una racha de actividad durante 7 días consecutivos"
        points = 25
    case .streak14Days:
        category = .streak
        name = "Racha de 14 días"
        description = "Mantén una racha de actividad durante 14 días consecutivos"
        points = 50
    case .streak30Days:
        category = .streak
        name = "Racha de 30 días"
        description = "Mantén una racha de actividad durante 30 días consecutivos"
        points = 100
    case .journals5:
        category = .journaling
        name = "5 Diarios"
        description = "Crea 5 diarios de voz"
        points = 20
    case .journals10:
        category = .journaling
        name = "10 Diarios"
        description = "Crea 10 diarios de voz"
        points = 30
    case .journals25:
        category = .journaling
        name = "25 Diarios"
        description = "Crea 25 diarios de voz"
        points = 50
    case .emotionalCheckins10:
        category = .emotionalAwareness
        name = "10 Check-ins"
        description = "Realiza 10 check-ins emocionales"
        points = 20
    case .emotionalCheckins25:
        category = .emotionalAwareness
        name = "25 Check-ins"
        description = "Realiza 25 check-ins emocionales"
        points = 40
    case .toolsExplorer:
        category = .toolUsage
        name = "Explorador de Herramientas"
        description = "Utiliza 5 herramientas diferentes"
        points = 25
    case .toolsMaster:
        category = .toolUsage
        name = "Maestro de Herramientas"
        description = "Utiliza todas las categorías de herramientas"
        points = 50
    }
    
    let earnedDate: Date? = isEarned ? Date().addingTimeInterval(-7 * 24 * 60 * 60) : nil // 7 days ago if earned
    let progress: Double = isEarned ? 1.0 : 0.3 // 30% progress if not earned
    
    let criteria: [String: Any] = ["count": 5, "action": "check-ins"]
    let metadata: [String: Any]? = achievementType == .streak3Days ? ["nextAchievement": AchievementType.streak7Days.rawValue] : nil
    
    return Achievement(
        id: achievementId,
        type: achievementType,
        category: category,
        name: name,
        description: description,
        iconUrl: "https://example.com/achievements/\(achievementType.rawValue).png",
        points: points,
        isHidden: false,
        earnedDate: earnedDate,
        progress: progress,
        criteria: criteria,
        metadata: metadata
    )
}

/**
 * Creates a mock Streak object for testing.
 * 
 * - Parameters:
 *   - id: Optional UUID for the streak, defaults to a new UUID
 *   - currentStreak: The current streak count, defaults to 5
 *   - longestStreak: The longest streak achieved, defaults to the maximum of currentStreak and 7
 * 
 * - Returns: A mock Streak object with test data
 */
func createTestStreak(id: UUID? = nil, currentStreak: Int? = nil, longestStreak: Int? = nil) -> Streak {
    let streakId = id ?? UUID()
    let current = currentStreak ?? 5
    let longest = longestStreak ?? max(current, 7)
    
    // Generate activity dates for the streak
    var activityDates: [Date] = []
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    for i in (0..<current).reversed() {
        if let date = calendar.date(byAdding: .day, value: -i, to: today) {
            activityDates.append(date)
        }
    }
    
    return Streak(
        id: streakId,
        userId: TestData.testUserId,
        currentStreak: current,
        longestStreak: longest,
        lastActivityDate: activityDates.last,
        activityDates: activityDates,
        totalDaysActive: longest + 5, // Some extra days beyond longest streak
        hasGracePeriodUsed: false
    )
}

/**
 * Creates a mock EmotionalTrend object for testing.
 * 
 * - Parameters:
 *   - emotionType: The type of emotion for the trend, defaults to .calm
 *   - direction: The direction of the trend, defaults to .stable
 *   - dataPointCount: The number of data points to generate
 * 
 * - Returns: A mock EmotionalTrend object with test data
 */
func createTestEmotionalTrend(emotionType: EmotionType? = nil, direction: TrendDirection? = nil, dataPointCount: Int = 7) -> EmotionalTrend {
    let emotion = emotionType ?? .calm
    let trendDirection = direction ?? .stable
    
    // Generate data points based on trend direction
    var dataPoints: [TrendDataPoint] = []
    var baseValue = 5
    var totalValue = 0
    var maxValue = 0
    var peakDate = Date()
    
    for i in 0..<dataPointCount {
        let date = createTestDate(daysOffset: -i)
        var value = baseValue
        
        switch trendDirection {
        case .increasing:
            // Value increases over time (older dates have lower values)
            value = max(1, min(10, baseValue - i / 2))
        case .decreasing:
            // Value decreases over time (older dates have higher values)
            value = max(1, min(10, baseValue + i / 2))
        case .fluctuating:
            // Values fluctuate randomly
            value = max(1, min(10, baseValue + Int.random(in: -3...3)))
        case .stable:
            // Values remain relatively stable
            value = max(1, min(10, baseValue + Int.random(in: -1...1)))
        }
        
        let dataPoint = createTestTrendDataPoint(date: date, value: value)
        dataPoints.append(dataPoint)
        
        totalValue += value
        if value > maxValue {
            maxValue = value
            peakDate = date
        }
    }
    
    // Calculate average intensity
    let averageIntensity = Double(totalValue) / Double(dataPointCount)
    
    return EmotionalTrend(
        emotionType: emotion,
        dataPoints: dataPoints,
        overallTrend: trendDirection,
        averageIntensity: averageIntensity,
        peakIntensity: Double(maxValue),
        peakDate: peakDate,
        occurrenceCount: dataPointCount
    )
}

/**
 * Creates a mock TrendDataPoint object for testing.
 * 
 * - Parameters:
 *   - date: The date of the data point
 *   - value: The intensity value (1-10), defaults to a random value
 * 
 * - Returns: A mock TrendDataPoint object with test data
 */
func createTestTrendDataPoint(date: Date, value: Int? = nil) -> TrendDataPoint {
    let pointValue = value ?? Int.random(in: 1...10)
    
    return TrendDataPoint(
        date: date,
        value: pointValue,
        context: "Test data point context"
    )
}

/**
 * Creates a mock EmotionalInsight object for testing.
 * 
 * - Parameters:
 *   - type: The type of insight, defaults to .pattern
 *   - relatedEmotion: A related emotion, defaults to .anxiety
 * 
 * - Returns: A mock EmotionalInsight object with test data
 */
func createTestEmotionalInsight(type: InsightType? = nil, relatedEmotion: EmotionType? = nil) -> EmotionalInsight {
    let insightType = type ?? .pattern
    let emotion = relatedEmotion ?? .anxiety
    let emotions = [emotion, .calm]
    
    var description = "Test insight description"
    var actions = ["Test recommended action 1", "Test recommended action 2"]
    
    switch insightType {
    case .pattern:
        description = "Hemos notado que \(emotion.displayName()) tiende a aparecer más en las mañanas."
        actions = ["Intenta comenzar el día con unos minutos de respiración consciente", "Refleja sobre lo que podría estar causando este patrón"]
    case .trigger:
        description = "Situaciones relacionadas al trabajo parecen desencadenar \(emotion.displayName())."
        actions = ["Practica técnicas de respiración antes de situaciones laborales estresantes", "Considera establecer límites más claros en el trabajo"]
    case .improvement:
        description = "Tu nivel de \(emotion.displayName()) ha disminuido un 30% en el último mes."
        actions = ["Continúa con las prácticas que has estado utilizando", "Celebra este progreso como un logro importante"]
    case .correlation:
        description = "Cuando practicas ejercicios de respiración, tu nivel de \(emotion.displayName()) tiende a disminuir."
        actions = ["Incorpora ejercicios de respiración a tu rutina diaria", "Experimenta con diferentes técnicas de respiración"]
    case .recommendation:
        description = "Basado en tus patrones, recomendamos herramientas de respiración para gestionar \(emotion.displayName())."
        actions = ["Prueba la técnica de respiración 4-7-8", "Establece recordatorios para practicar respiración consciente"]
    }
    
    return EmotionalInsight(
        type: insightType,
        description: description,
        relatedEmotions: emotions,
        confidence: 0.85,
        recommendedActions: actions
    )
}

/**
 * Creates a test date with specified offset from current date.
 * 
 * - Parameter daysOffset: Number of days to offset from today (negative is past, positive is future)
 * 
 * - Returns: A date with the specified offset from current date
 */
func createTestDate(daysOffset: Int) -> Date {
    let calendar = Calendar.current
    return calendar.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date()
}

/**
 * Static utility class that provides mock data for unit tests.
 */
class TestData {
    // Static UUIDs for consistent test objects
    static let testUserId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let testJournalId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let testEmotionalStateId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let testToolId = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let testAchievementId = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let testStreakId = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    
    /// Private initializer to prevent instantiation of utility class
    private init() { }
    
    // MARK: - Mock Objects
    
    /**
     * Returns a mock User object with standard test values.
     * 
     * - Parameter isPremium: Whether the user has a premium subscription
     * - Returns: A mock User object
     */
    static func mockUser(isPremium: Bool = false) -> User {
        return createTestUser(id: testUserId, isPremium: isPremium)
    }
    
    /**
     * Returns a mock EmotionalState object with standard test values.
     * 
     * - Parameters:
     *   - emotionType: The type of emotion, defaults to .calm
     *   - intensity: The intensity of the emotion (1-10), defaults to 7
     *   - context: The context of the check-in, defaults to .standalone
     * 
     * - Returns: A mock EmotionalState object
     */
    static func mockEmotionalState(emotionType: EmotionType? = nil, intensity: Int? = nil, context: CheckInContext? = nil) -> EmotionalState {
        return createTestEmotionalState(id: testEmotionalStateId, emotionType: emotionType, intensity: intensity, context: context)
    }
    
    /**
     * Returns a mock Journal object with standard test values.
     * 
     * - Parameters:
     *   - withPostEmotionalState: Whether to include a post-recording emotional state
     *   - isFavorite: Whether the journal is marked as favorite
     * 
     * - Returns: A mock Journal object
     */
    static func mockJournal(withPostEmotionalState: Bool = true, isFavorite: Bool = false) -> Journal {
        return createTestJournal(id: testJournalId, withPostEmotionalState: withPostEmotionalState, isFavorite: isFavorite)
    }
    
    /**
     * Returns a mock Tool object with standard test values.
     * 
     * - Parameters:
     *   - category: The category of the tool, defaults to .breathing
     *   - isFavorite: Whether the tool is marked as favorite
     * 
     * - Returns: A mock Tool object
     */
    static func mockTool(category: ToolCategory? = nil, isFavorite: Bool = false) -> Tool {
        return createTestTool(id: testToolId, category: category, isFavorite: isFavorite)
    }
    
    /**
     * Returns a mock Achievement object with standard test values.
     * 
     * - Parameters:
     *   - type: The type of achievement, defaults to .firstStep
     *   - isEarned: Whether the achievement has been earned
     * 
     * - Returns: A mock Achievement object
     */
    static func mockAchievement(type: AchievementType? = nil, isEarned: Bool = false) -> Achievement {
        return createTestAchievement(id: testAchievementId, type: type, isEarned: isEarned)
    }
    
    /**
     * Returns a mock Streak object with standard test values.
     * 
     * - Parameters:
     *   - currentStreak: The current streak count, defaults to 5
     *   - longestStreak: The longest streak achieved, defaults to the maximum of currentStreak and 7
     * 
     * - Returns: A mock Streak object
     */
    static func mockStreak(currentStreak: Int? = nil, longestStreak: Int? = nil) -> Streak {
        return createTestStreak(id: testStreakId, currentStreak: currentStreak, longestStreak: longestStreak)
    }
    
    /**
     * Returns a mock EmotionalTrend object with standard test values.
     * 
     * - Parameters:
     *   - emotionType: The type of emotion for the trend, defaults to .calm
     *   - direction: The direction of the trend, defaults to .stable
     *   - dataPointCount: The number of data points to generate
     * 
     * - Returns: A mock EmotionalTrend object
     */
    static func mockEmotionalTrend(emotionType: EmotionType? = nil, direction: TrendDirection? = nil, dataPointCount: Int = 7) -> EmotionalTrend {
        return createTestEmotionalTrend(emotionType: emotionType, direction: direction, dataPointCount: dataPointCount)
    }
    
    // MARK: - Mock Arrays
    
    /**
     * Returns an array of mock Tool objects with different categories.
     * 
     * - Parameter count: The number of tools to generate
     * - Returns: An array of mock Tool objects
     */
    static func mockToolArray(count: Int = 5) -> [Tool] {
        var tools: [Tool] = []
        let categories = ToolCategory.allCases
        
        for i in 0..<count {
            let category = categories[i % categories.count]
            let tool = createTestTool(category: category, isFavorite: i % 3 == 0)
            tools.append(tool)
        }
        
        return tools
    }
    
    /**
     * Returns an array of mock Journal objects.
     * 
     * - Parameter count: The number of journals to generate
     * - Returns: An array of mock Journal objects
     */
    static func mockJournalArray(count: Int = 5) -> [Journal] {
        var journals: [Journal] = []
        
        for i in 0..<count {
            let journal = createTestJournal(
                withPostEmotionalState: true, 
                isFavorite: i % 3 == 0
            )
            journals.append(journal)
        }
        
        return journals
    }
    
    /**
     * Returns an array of mock Achievement objects.
     * 
     * - Parameters:
     *   - count: The number of achievements to generate
     *   - earnedCount: The number of achievements that should be marked as earned
     * 
     * - Returns: An array of mock Achievement objects
     */
    static func mockAchievementArray(count: Int = 6, earnedCount: Int = 3) -> [Achievement] {
        var achievements: [Achievement] = []
        let types: [AchievementType] = [
            .firstStep, .streak3Days, .streak7Days, 
            .journals5, .emotionalCheckins10, .toolsExplorer
        ]
        
        for i in 0..<count {
            let type = types[i % types.count]
            let isEarned = i < earnedCount
            let achievement = createTestAchievement(type: type, isEarned: isEarned)
            achievements.append(achievement)
        }
        
        return achievements
    }
    
    /**
     * Returns an array of mock EmotionalTrend objects for different emotions.
     * 
     * - Parameter count: The number of emotional trends to generate
     * - Returns: An array of mock EmotionalTrend objects
     */
    static func mockEmotionalTrendArray(count: Int = 4) -> [EmotionalTrend] {
        var trends: [EmotionalTrend] = []
        let emotions: [EmotionType] = [.calm, .anxiety, .joy, .frustration]
        let directions: [TrendDirection] = [.increasing, .decreasing, .stable, .fluctuating]
        
        for i in 0..<count {
            let emotion = emotions[i % emotions.count]
            let direction = directions[i % directions.count]
            let trend = createTestEmotionalTrend(emotionType: emotion, direction: direction)
            trends.append(trend)
        }
        
        return trends
    }
}