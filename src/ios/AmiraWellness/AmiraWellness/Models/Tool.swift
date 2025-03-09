import Foundation // Version: standard library

/// Enumeration of content types supported for tools
@frozen
public enum ToolContentType: String, Codable, Equatable {
    case text
    case audio
    case video
    case interactive
    case guidedExercise
    
    /// Returns the localized display name of the content type
    public func displayName() -> String {
        switch self {
        case .text:
            return NSLocalizedString("Texto", comment: "Text content type")
        case .audio:
            return NSLocalizedString("Audio", comment: "Audio content type")
        case .video:
            return NSLocalizedString("Video", comment: "Video content type")
        case .interactive:
            return NSLocalizedString("Interactivo", comment: "Interactive content type")
        case .guidedExercise:
            return NSLocalizedString("Ejercicio guiado", comment: "Guided exercise content type")
        }
    }
}

/// Enumeration of difficulty levels for tools
@frozen
public enum ToolDifficulty: String, Codable, Equatable {
    case beginner
    case intermediate
    case advanced
    
    /// Returns the localized display name of the difficulty level
    public func displayName() -> String {
        switch self {
        case .beginner:
            return NSLocalizedString("Principiante", comment: "Beginner difficulty level")
        case .intermediate:
            return NSLocalizedString("Intermedio", comment: "Intermediate difficulty level")
        case .advanced:
            return NSLocalizedString("Avanzado", comment: "Advanced difficulty level")
        }
    }
}

/// Structure representing the content of a tool
public struct ToolContent: Codable, Equatable {
    public let title: String
    public let instructions: String
    public let mediaUrl: String?
    public let steps: [ToolStep]?
    public let additionalResources: [Resource]?
    
    /// Initializes a ToolContent instance with the provided parameters
    public init(
        title: String,
        instructions: String,
        mediaUrl: String? = nil,
        steps: [ToolStep]? = nil,
        additionalResources: [Resource]? = nil
    ) {
        self.title = title
        self.instructions = instructions
        self.mediaUrl = mediaUrl
        self.steps = steps
        self.additionalResources = additionalResources
    }
}

/// Structure representing a step in a guided tool exercise
public struct ToolStep: Codable, Equatable, Identifiable {
    public let id: Int
    public let order: Int
    public let title: String
    public let description: String
    public let durationSeconds: Int
    public let mediaUrl: String?
    
    /// Initializes a ToolStep instance with the provided parameters
    public init(
        id: Int,
        order: Int,
        title: String,
        description: String,
        durationSeconds: Int,
        mediaUrl: String? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.description = description
        self.durationSeconds = durationSeconds
        self.mediaUrl = mediaUrl
    }
    
    /// Returns a formatted string representation of the step duration
    public func formattedDuration() -> String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Enumeration of resource types for additional tool resources
@frozen
public enum ResourceType: String, Codable, Equatable {
    case article
    case audio
    case video
    case externalLink
    
    /// Returns the localized display name of the resource type
    public func displayName() -> String {
        switch self {
        case .article:
            return NSLocalizedString("Artículo", comment: "Article resource type")
        case .audio:
            return NSLocalizedString("Audio", comment: "Audio resource type")
        case .video:
            return NSLocalizedString("Video", comment: "Video resource type")
        case .externalLink:
            return NSLocalizedString("Enlace externo", comment: "External link resource type")
        }
    }
}

/// Structure representing an additional resource for a tool
public struct Resource: Codable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let url: String
    public let type: ResourceType
    
    /// Initializes a Resource instance with the provided parameters
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        url: String,
        type: ResourceType
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.type = type
    }
}

/// Structure representing an emotional regulation tool in the Amira Wellness application
public struct Tool: Codable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let description: String
    public let category: ToolCategory
    public let contentType: ToolContentType
    public let content: ToolContent
    public var isFavorite: Bool
    public var usageCount: Int
    public let targetEmotions: [EmotionType]
    public let estimatedDuration: Int // in minutes
    public let difficulty: ToolDifficulty
    public let createdAt: Date
    public var updatedAt: Date?
    
    /// Initializes a Tool instance with the provided parameters
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: ToolCategory,
        contentType: ToolContentType,
        content: ToolContent,
        isFavorite: Bool = false,
        usageCount: Int = 0,
        targetEmotions: [EmotionType],
        estimatedDuration: Int,
        difficulty: ToolDifficulty,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.contentType = contentType
        self.content = content
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.targetEmotions = targetEmotions
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Returns a formatted string representation of the estimated duration
    public func formattedDuration() -> String {
        return "\(estimatedDuration) min"
    }
    
    /// Toggles the favorite status of the tool
    public func toggleFavorite() -> Tool {
        var tool = self
        tool.isFavorite.toggle()
        tool.updatedAt = Date()
        return tool
    }
    
    /// Increments the usage count of the tool
    public func incrementUsageCount() -> Tool {
        var tool = self
        tool.usageCount += 1
        tool.updatedAt = Date()
        return tool
    }
    
    /// Determines if this tool is recommended for a specific emotion type
    public func isRecommendedFor(emotionType: EmotionType) -> Bool {
        return targetEmotions.contains(emotionType)
    }
    
    /// Determines if the tool has associated media content
    public func hasMediaContent() -> Bool {
        return content.mediaUrl != nil
    }
    
    /// Determines if the tool has step-by-step instructions
    public func hasSteps() -> Bool {
        return content.steps != nil && !(content.steps!.isEmpty)
    }
    
    /// Determines if the tool has additional resources
    public func hasAdditionalResources() -> Bool {
        return content.additionalResources != nil && !(content.additionalResources!.isEmpty)
    }
    
    /// Returns a formatted string representation of the creation date
    public func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}