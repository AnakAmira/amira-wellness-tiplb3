//
//  ColorConstants.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // SwiftUI - iOS SDK

/// A struct containing static color constants used throughout the application
struct ColorConstants {
    // MARK: - Primary Colors (Nature-inspired blues and greens)
    
    /// Main brand color - a calming teal/blue inspired by natural elements
    static let primary = Color(red: 0.20, green: 0.60, blue: 0.70)
    
    /// Darker version of the primary color for contrast and depth
    static let primaryDark = Color(red: 0.15, green: 0.45, blue: 0.55)
    
    /// Lighter version of the primary color for subtle backgrounds and highlights
    static let primaryLight = Color(red: 0.35, green: 0.75, blue: 0.85)
    
    /// A variant of the primary color - a deeper teal for variety
    static let primaryVariant = Color(red: 0.15, green: 0.50, blue: 0.60)
    
    // MARK: - Secondary Colors (Warm accent colors)
    
    /// Main accent color - a warm amber/orange to complement the cool primary colors
    static let secondary = Color(red: 0.90, green: 0.60, blue: 0.30)
    
    /// Darker version of the secondary color for contrast and emphasis
    static let secondaryDark = Color(red: 0.75, green: 0.45, blue: 0.15)
    
    /// Lighter version of the secondary color for subtle accents and highlights
    static let secondaryLight = Color(red: 0.95, green: 0.75, blue: 0.45)
    
    /// A variant of the secondary color - a warmer tone for variety
    static let secondaryVariant = Color(red: 0.85, green: 0.50, blue: 0.25)
    
    // MARK: - Background Colors
    
    /// Main background color - clean white for a minimalist design
    static let background = Color(red: 1.00, green: 1.00, blue: 1.00)
    
    /// Dark background color for dark mode - soft dark tone that's gentle on the eyes
    static let backgroundDark = Color(red: 0.10, green: 0.12, blue: 0.15)
    
    /// Surface color for content areas - slight off-white for subtle depth
    static let surface = Color(red: 0.97, green: 0.97, blue: 0.97)
    
    /// Dark surface color for dark mode - slightly lighter than the background
    static let surfaceDark = Color(red: 0.15, green: 0.17, blue: 0.20)
    
    // MARK: - Text Colors
    
    /// Primary text color - near black for optimal readability
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)
    
    /// Secondary text color - less emphasis than primary
    static let textSecondary = Color(red: 0.30, green: 0.30, blue: 0.30)
    
    /// Tertiary text color - least emphasis, for supporting text
    static let textTertiary = Color(red: 0.50, green: 0.50, blue: 0.50)
    
    /// Text color on primary color backgrounds - ensuring readability
    static let textOnPrimary = Color.white
    
    /// Text color on secondary color backgrounds - ensuring readability
    static let textOnSecondary = Color.white
    
    // MARK: - Utility Colors
    
    /// Error color - for error messages and states
    static let error = Color(red: 0.90, green: 0.20, blue: 0.20)
    
    /// Success color - for success messages and states
    static let success = Color(red: 0.20, green: 0.75, blue: 0.40)
    
    /// Warning color - for warning messages and states
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.20)
    
    /// Info color - for informational messages and states
    static let info = Color(red: 0.20, green: 0.60, blue: 0.95)
    
    /// Divider color - light gray for separating content
    static let divider = Color(red: 0.90, green: 0.90, blue: 0.90)
    
    /// Dark divider color - for dividers in dark mode
    static let dividerDark = Color(red: 0.25, green: 0.25, blue: 0.25)
    
    /// Border color - for view borders and outlines
    static let border = Color(red: 0.85, green: 0.85, blue: 0.85)
    
    /// Dark border color - for borders in dark mode
    static let borderDark = Color(red: 0.30, green: 0.30, blue: 0.30)
    
    /// Transparent color - fully transparent for overlays and special effects
    static let transparent = Color.clear
    
    /// Semi-transparent black - for overlays and modals
    static let semiTransparentBlack = Color.black.opacity(0.5)
    
    /// Semi-transparent white - for overlays and modals in dark mode
    static let semiTransparentWhite = Color.white.opacity(0.5)
    
    /// Private initializer to prevent instantiation
    private init() {
        // This struct is only meant to be used for its static properties
    }
}

/// A struct containing static color constants for different emotions
struct EmotionColors {
    // MARK: - Basic Emotion Colors
    
    /// Joy - bright yellow representing happiness and positivity
    static let joy = Color(red: 1.00, green: 0.85, blue: 0.25)
    
    /// Sadness - blue representing melancholy and reflection
    static let sadness = Color(red: 0.30, green: 0.45, blue: 0.75)
    
    /// Anger - red representing intensity and frustration
    static let anger = Color(red: 0.90, green: 0.20, blue: 0.20)
    
    /// Fear - purple representing uncertainty and tension
    static let fear = Color(red: 0.60, green: 0.30, blue: 0.70)
    
    /// Disgust - green with a hint of brown representing aversion
    static let disgust = Color(red: 0.40, green: 0.60, blue: 0.25)
    
    /// Surprise - bright pink representing unexpectedness
    static let surprise = Color(red: 0.95, green: 0.40, blue: 0.70)
    
    /// Trust - sky blue representing reliability and openness
    static let trust = Color(red: 0.35, green: 0.70, blue: 0.90)
    
    /// Anticipation - orange representing expectation and excitement
    static let anticipation = Color(red: 0.95, green: 0.55, blue: 0.20)
    
    // MARK: - Nuanced Emotion Colors
    
    /// Anxiety - tense purple representing worry and unease
    static let anxiety = Color(red: 0.70, green: 0.40, blue: 0.80)
    
    /// Calm - soft blue representing peace and tranquility
    static let calm = Color(red: 0.40, green: 0.70, blue: 0.85)
    
    /// Contentment - warm peach representing satisfaction
    static let contentment = Color(red: 0.95, green: 0.75, blue: 0.65)
    
    /// Gratitude - magenta representing appreciation and warmth
    static let gratitude = Color(red: 0.85, green: 0.40, blue: 0.65)
    
    /// Hope - light green representing optimism and potential
    static let hope = Color(red: 0.50, green: 0.85, blue: 0.60)
    
    /// Frustration - burnt orange representing blockage and irritation
    static let frustration = Color(red: 0.80, green: 0.40, blue: 0.15)
    
    /// Overwhelm - deep purple representing pressure and excess
    static let overwhelm = Color(red: 0.50, green: 0.20, blue: 0.60)
    
    /// Loneliness - soft gray with a hint of blue representing isolation
    static let loneliness = Color(red: 0.60, green: 0.65, blue: 0.70)
    
    /// Returns the color associated with a given emotion type
    ///
    /// - Parameter emotionType: The emotion type to get a color for
    /// - Returns: The color associated with the specified emotion
    static func forEmotionType(emotionType: EmotionType) -> Color {
        switch emotionType {
        case .JOY:
            return joy
        case .SADNESS:
            return sadness
        case .ANGER:
            return anger
        case .FEAR:
            return fear
        case .DISGUST:
            return disgust
        case .SURPRISE:
            return surprise
        case .TRUST:
            return trust
        case .ANTICIPATION:
            return anticipation
        case .GRATITUDE:
            return gratitude
        case .CONTENTMENT:
            return contentment
        case .ANXIETY:
            return anxiety
        case .FRUSTRATION:
            return frustration
        case .OVERWHELM:
            return overwhelm
        case .CALM:
            return calm
        case .HOPE:
            return hope
        case .LONELINESS:
            return loneliness
        default:
            // Return a neutral color for any unhandled emotion types
            return Color(red: 0.50, green: 0.50, blue: 0.50)
        }
    }
    
    /// Private initializer to prevent instantiation
    private init() {
        // This struct is only meant to be used for its static properties
    }
}