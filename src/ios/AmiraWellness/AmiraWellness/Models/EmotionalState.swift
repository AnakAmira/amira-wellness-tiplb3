import Foundation // standard library
import APIError // For error handling during JSON parsing

/// Enumeration of emotion types supported in the application
@frozen
enum EmotionType: String, Codable, CaseIterable {
    case joy
    case sadness
    case anger
    case fear
    case disgust
    case surprise
    case trust
    case anticipation
    case gratitude
    case contentment
    case anxiety
    case frustration
    case overwhelm
    case calm
    case hope
    case loneliness
    
    /// Returns the localized display name of the emotion type
    func displayName() -> String {
        switch self {
        case .joy:
            return NSLocalizedString("Alegría", comment: "Joy emotion")
        case .sadness:
            return NSLocalizedString("Tristeza", comment: "Sadness emotion")
        case .anger:
            return NSLocalizedString("Ira", comment: "Anger emotion")
        case .fear:
            return NSLocalizedString("Miedo", comment: "Fear emotion")
        case .disgust:
            return NSLocalizedString("Asco", comment: "Disgust emotion")
        case .surprise:
            return NSLocalizedString("Sorpresa", comment: "Surprise emotion")
        case .trust:
            return NSLocalizedString("Confianza", comment: "Trust emotion")
        case .anticipation:
            return NSLocalizedString("Anticipación", comment: "Anticipation emotion")
        case .gratitude:
            return NSLocalizedString("Gratitud", comment: "Gratitude emotion")
        case .contentment:
            return NSLocalizedString("Satisfacción", comment: "Contentment emotion")
        case .anxiety:
            return NSLocalizedString("Ansiedad", comment: "Anxiety emotion")
        case .frustration:
            return NSLocalizedString("Frustración", comment: "Frustration emotion")
        case .overwhelm:
            return NSLocalizedString("Agobio", comment: "Overwhelm emotion")
        case .calm:
            return NSLocalizedString("Calma", comment: "Calm emotion")
        case .hope:
            return NSLocalizedString("Esperanza", comment: "Hope emotion")
        case .loneliness:
            return NSLocalizedString("Soledad", comment: "Loneliness emotion")
        }
    }
    
    /// Returns the localized description of the emotion type
    func description() -> String {
        switch self {
        case .joy:
            return NSLocalizedString("Una sensación de felicidad y placer", comment: "Joy description")
        case .sadness:
            return NSLocalizedString("Una sensación de tristeza o infelicidad", comment: "Sadness description")
        case .anger:
            return NSLocalizedString("Una sensación fuerte de desagrado o hostilidad", comment: "Anger description")
        case .fear:
            return NSLocalizedString("Una sensación de amenaza o peligro", comment: "Fear description")
        case .disgust:
            return NSLocalizedString("Una sensación de repulsión o rechazo", comment: "Disgust description")
        case .surprise:
            return NSLocalizedString("Una reacción a algo inesperado", comment: "Surprise description")
        case .trust:
            return NSLocalizedString("Una sensación de seguridad y confianza", comment: "Trust description")
        case .anticipation:
            return NSLocalizedString("Una sensación de espera positiva", comment: "Anticipation description")
        case .gratitude:
            return NSLocalizedString("Un sentimiento de aprecio y agradecimiento", comment: "Gratitude description")
        case .contentment:
            return NSLocalizedString("Una sensación de satisfacción y tranquilidad", comment: "Contentment description")
        case .anxiety:
            return NSLocalizedString("Una sensación de preocupación o nerviosismo", comment: "Anxiety description")
        case .frustration:
            return NSLocalizedString("Una sensación de decepción o descontento", comment: "Frustration description")
        case .overwhelm:
            return NSLocalizedString("Una sensación de ser sobrepasado o abrumado", comment: "Overwhelm description")
        case .calm:
            return NSLocalizedString("Una sensación de tranquilidad y paz", comment: "Calm description")
        case .hope:
            return NSLocalizedString("Una sensación de optimismo sobre el futuro", comment: "Hope description")
        case .loneliness:
            return NSLocalizedString("Una sensación de soledad o aislamiento", comment: "Loneliness description")
        }
    }
    
    /// Returns the color associated with the emotion type
    func color() -> Color {
        switch self {
        case .joy:
            return Color(hexString: "#FFD700") // Yellow
        case .sadness:
            return Color(hexString: "#1E90FF") // Blue
        case .anger:
            return Color(hexString: "#FF0000") // Red
        case .fear:
            return Color(hexString: "#800080") // Purple
        case .disgust:
            return Color(hexString: "#008000") // Green
        case .surprise:
            return Color(hexString: "#FFA500") // Orange
        case .trust:
            return Color(hexString: "#006400") // Dark Green
        case .anticipation:
            return Color(hexString: "#FF69B4") // Pink
        case .gratitude:
            return Color(hexString: "#DDA0DD") // Plum
        case .contentment:
            return Color(hexString: "#87CEEB") // Sky Blue
        case .anxiety:
            return Color(hexString: "#CD5C5C") // Indian Red
        case .frustration:
            return Color(hexString: "#B22222") // Firebrick
        case .overwhelm:
            return Color(hexString: "#9932CC") // Dark Orchid
        case .calm:
            return Color(hexString: "#ADD8E6") // Light Blue
        case .hope:
            return Color(hexString: "#F0E68C") // Khaki
        case .loneliness:
            return Color(hexString: "#708090") // Slate Gray
        }
    }
    
    /// Returns the category of the emotion type
    func category() -> EmotionCategory {
        switch self {
        case .joy, .trust, .anticipation, .gratitude, .contentment, .calm, .hope:
            return .positive
        case .sadness, .anger, .fear, .disgust, .anxiety, .frustration, .overwhelm, .loneliness:
            return .negative
        case .surprise:
            return .neutral
        }
    }
}

/// Enumeration of emotion categories for grouping and analysis
@frozen
enum EmotionCategory: String, Codable {
    case positive
    case negative
    case neutral
    
    /// Returns the localized display name of the emotion category
    func displayName() -> String {
        switch self {
        case .positive:
            return NSLocalizedString("Positiva", comment: "Positive emotion category")
        case .negative:
            return NSLocalizedString("Negativa", comment: "Negative emotion category")
        case .neutral:
            return NSLocalizedString("Neutral", comment: "Neutral emotion category")
        }
    }
}

/// Enumeration of contexts in which emotional check-ins occur
@frozen
enum CheckInContext: String, Codable {
    case preJournaling
    case postJournaling
    case standalone
    case toolUsage
    case dailyCheckIn
    
    /// Returns the localized display name of the check-in context
    func displayName() -> String {
        switch self {
        case .preJournaling:
            return NSLocalizedString("Antes de grabar", comment: "Pre-journaling context")
        case .postJournaling:
            return NSLocalizedString("Después de grabar", comment: "Post-journaling context")
        case .standalone:
            return NSLocalizedString("Check-in independiente", comment: "Standalone check-in context")
        case .toolUsage:
            return NSLocalizedString("Uso de herramienta", comment: "Tool usage context")
        case .dailyCheckIn:
            return NSLocalizedString("Check-in diario", comment: "Daily check-in context")
        }
    }
}

/// A simple color representation using hex strings
struct Color: Codable, Equatable {
    let hexString: String
    
    init(hexString: String) {
        self.hexString = hexString
    }
}

/// Structure representing an emotional state in the Amira Wellness application
struct EmotionalState: Codable, Equatable {
    var id: UUID?
    var userId: UUID?
    var emotionType: EmotionType
    var intensity: Int
    var context: CheckInContext
    var notes: String?
    var relatedJournalId: UUID?
    var relatedToolId: UUID?
    var createdAt: Date
    var updatedAt: Date?
    
    /// Initializes an EmotionalState with the provided parameters
    init(
        id: UUID? = nil,
        userId: UUID? = nil,
        emotionType: EmotionType,
        intensity: Int,
        context: CheckInContext,
        notes: String? = nil,
        relatedJournalId: UUID? = nil,
        relatedToolId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.emotionType = emotionType
        self.intensity = intensity
        self.context = context
        self.notes = notes
        self.relatedJournalId = relatedJournalId
        self.relatedToolId = relatedToolId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Validates that the emotional state has valid values
    func isValid() -> Bool {
        return intensity >= 1 && intensity <= 10
    }
    
    /// Compares this emotional state with another to determine changes
    func compareWith(_ other: EmotionalState) -> (emotionChanged: Bool, intensityDifference: Int) {
        let emotionChanged = emotionType != other.emotionType
        let intensityDifference = other.intensity - intensity
        return (emotionChanged, intensityDifference)
    }
    
    /// Returns a formatted string representation of the creation date
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// Returns a formatted string representation of the intensity
    func formattedIntensity() -> String {
        return "\(intensity)/10"
    }
    
    /// Returns a summary of the emotional state
    func summary() -> String {
        return "\(emotionType.displayName()) - \(formattedIntensity())"
    }
}