//
//  Color+Extensions.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // iOS SDK
import UIKit // iOS SDK

/// Extension on SwiftUI Color type to add utility functions for the Amira Wellness app
extension Color {
    
    /// Initializes a Color from a hex string
    /// - Parameters:
    ///   - hex: The hex string representation of the color (e.g., "#FF5500" or "FF5500")
    ///   - opacity: The opacity value for the color (0.0 - 1.0)
    init(hex: String, opacity: Double = 1.0) {
        // Remove any '#' prefix from the hex string
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        // Validate the hex string length (should be 6 or 8 characters)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: Double
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = (
                Double((int & 0xF00) >> 8) / 15.0,
                Double((int & 0x0F0) >> 4) / 15.0,
                Double(int & 0x00F) / 15.0
            )
        case 6: // RGB (24-bit)
            (r, g, b) = (
                Double((int & 0xFF0000) >> 16) / 255.0,
                Double((int & 0x00FF00) >> 8) / 255.0,
                Double(int & 0x0000FF) / 255.0
            )
        case 8: // RGBA (32-bit)
            (r, g, b) = (
                Double((int & 0xFF000000) >> 24) / 255.0,
                Double((int & 0x00FF0000) >> 16) / 255.0,
                Double((int & 0x0000FF00) >> 8) / 255.0
            )
        default:
            (r, g, b) = (1, 1, 1)
        }
        
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
    
    /// Converts a SwiftUI Color to a UIKit UIColor
    /// - Returns: A UIColor representation of the Color
    func toUIColor() -> UIColor {
        // Use UIColor from method to convert SwiftUI Color to UIColor
        return UIColor(self)
    }
    
    /// Creates a new Color with modified opacity
    /// - Parameter opacity: The opacity value (0.0 - 1.0)
    /// - Returns: A new Color with the specified opacity
    func withOpacity(_ opacity: Double) -> Color {
        // Apply the opacity modifier to the color
        return self.opacity(opacity)
    }
    
    /// Creates a lighter version of the color
    /// - Parameter percentage: How much lighter to make the color (0.0 - 1.0)
    /// - Returns: A lighter version of the color
    func lighter(by percentage: Double = 0.2) -> Color {
        // Convert to UIColor
        let uiColor = toUIColor()
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        // Get the HSBA components
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            // Increase brightness by the specified percentage
            let newBrightness = min(b + CGFloat(percentage), 1.0)
            // Create a new UIColor with modified brightness
            return Color(UIColor(hue: h, saturation: s, brightness: newBrightness, alpha: a))
        }
        
        // Fallback if HSBA conversion fails
        return self.opacity(1.0)
    }
    
    /// Creates a darker version of the color
    /// - Parameter percentage: How much darker to make the color (0.0 - 1.0)
    /// - Returns: A darker version of the color
    func darker(by percentage: Double = 0.2) -> Color {
        // Convert to UIColor
        let uiColor = toUIColor()
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        // Get the HSBA components
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            // Decrease brightness by the specified percentage
            let newBrightness = max(b - CGFloat(percentage), 0.0)
            // Create a new UIColor with modified brightness
            return Color(UIColor(hue: h, saturation: s, brightness: newBrightness, alpha: a))
        }
        
        // Fallback if HSBA conversion fails
        return self.opacity(1.0)
    }
    
    /// Determines whether white or black text would be more readable on this color
    /// - Returns: Either white or black color for optimal text contrast
    func contrastingTextColor() -> Color {
        // Convert to UIColor
        let uiColor = toUIColor()
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Calculate luminance using the formula (0.299*R + 0.587*G + 0.114*B)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        
        // Return white if luminance is less than 0.5, black otherwise
        return luminance < 0.5 ? .white : .black
    }
    
    /// Returns the color associated with a given emotion type
    /// - Parameter emotionType: The emotion type to get a color for
    /// - Returns: The color associated with the specified emotion
    static func forEmotionType(emotionType: EmotionType) -> Color {
        // Use EmotionColors.forEmotionType to get the color for the specified emotion type
        return EmotionColors.forEmotionType(emotionType: emotionType)
    }
    
    /// Interpolates between two colors based on a progress value
    /// - Parameters:
    ///   - to: The target color to interpolate towards
    ///   - progress: The progress value (0.0 = self, 1.0 = to)
    /// - Returns: A color interpolated between self and 'to' based on progress
    func interpolate(to: Color, progress: Double) -> Color {
        // Convert both colors to UIColor
        let fromUIColor = self.toUIColor()
        let toUIColor = to.toUIColor()
        
        // Get the RGB components of both colors
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        // Interpolate each component based on the progress value
        let r = fromR + (toR - fromR) * CGFloat(progress)
        let g = fromG + (toG - fromG) * CGFloat(progress)
        let b = fromB + (toB - fromB) * CGFloat(progress)
        let a = fromA + (toA - fromA) * CGFloat(progress)
        
        // Create a new UIColor with the interpolated components
        let interpolatedUIColor = UIColor(red: r, green: g, blue: b, alpha: a)
        
        // Convert back to SwiftUI Color and return
        return Color(interpolatedUIColor)
    }
    
    /// Creates a gradient from colors representing different emotions
    /// - Parameters:
    ///   - startEmotion: The starting emotion type
    ///   - endEmotion: The ending emotion type
    /// - Returns: A gradient between the colors of the specified emotions
    static func emotionGradient(startEmotion: EmotionType, endEmotion: EmotionType) -> LinearGradient {
        // Get the color for startEmotion using forEmotionType
        let startColor = forEmotionType(emotionType: startEmotion)
        
        // Get the color for endEmotion using forEmotionType
        let endColor = forEmotionType(emotionType: endEmotion)
        
        // Create and return a LinearGradient between these two colors
        return LinearGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}