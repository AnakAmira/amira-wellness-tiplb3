import Foundation // Version: standard library
import SwiftUI // Version: standard library

/// Enumeration representing the categories of emotional regulation tools in the Amira Wellness application.
/// This provides categorization, localization, and visual representation for the tool library.
@frozen
public enum ToolCategory: String, Codable, CaseIterable, Equatable, Hashable {
    case breathing
    case meditation
    case journaling
    case somatic
    case gratitude
    
    /// Returns the localized display name of the tool category.
    public func displayName() -> String {
        switch self {
        case .breathing:
            return NSLocalizedString("Respiración", comment: "Breathing tool category name")
        case .meditation:
            return NSLocalizedString("Meditación", comment: "Meditation tool category name")
        case .journaling:
            return NSLocalizedString("Prompts de journaling", comment: "Journaling tool category name")
        case .somatic:
            return NSLocalizedString("Ejercicios somáticos", comment: "Somatic exercises tool category name")
        case .gratitude:
            return NSLocalizedString("Gratitud", comment: "Gratitude tool category name")
        }
    }
    
    /// Returns the localized description of the tool category.
    public func description() -> String {
        switch self {
        case .breathing:
            return NSLocalizedString("Técnicas de respiración para regular emociones y reducir la ansiedad", comment: "Breathing tool category description")
        case .meditation:
            return NSLocalizedString("Meditaciones guiadas para calmar la mente y aumentar la conciencia", comment: "Meditation tool category description")
        case .journaling:
            return NSLocalizedString("Preguntas y temas para reflexionar a través de la escritura", comment: "Journaling tool category description")
        case .somatic:
            return NSLocalizedString("Ejercicios físicos para liberar tensión y conectar con las sensaciones corporales", comment: "Somatic tool category description")
        case .gratitude:
            return NSLocalizedString("Prácticas para cultivar gratitud y perspectiva positiva", comment: "Gratitude tool category description")
        }
    }
    
    /// Returns the system icon name associated with the tool category.
    /// Uses SF Symbols available in iOS 14+
    public func iconName() -> String {
        switch self {
        case .breathing:
            return "wind"
        case .meditation:
            return "sparkles"
        case .journaling:
            return "note.text"
        case .somatic:
            return "figure.walk"
        case .gratitude:
            return "heart"
        }
    }
    
    /// Returns the color associated with the tool category.
    /// Uses nature-inspired colors that align with the app's design principles
    public func color() -> Color {
        switch self {
        case .breathing:
            return Color(red: 0.35, green: 0.56, blue: 0.84) // Calm blue
        case .meditation:
            return Color(red: 0.54, green: 0.36, blue: 0.66) // Serene purple
        case .journaling:
            return Color(red: 0.32, green: 0.59, blue: 0.47) // Forest green
        case .somatic:
            return Color(red: 0.85, green: 0.55, blue: 0.35) // Warm orange
        case .gratitude:
            return Color(red: 0.82, green: 0.38, blue: 0.48) // Rose pink
        }
    }
}