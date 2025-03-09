//
//  Haptics.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import UIKit // iOS SDK

/// An enumeration defining the different types of haptic feedback available in the app
public enum HapticFeedbackType {
    /// Light impact feedback for subtle interactions
    case light
    /// Medium impact feedback for standard interactions
    case medium
    /// Heavy impact feedback for significant interactions
    case heavy
    /// Selection feedback for navigation and selection changes
    case selection
    /// Success notification feedback for completed actions
    case success
    /// Warning notification feedback for cautionary actions
    case warning
    /// Error notification feedback for failed actions
    case error
}

/// A singleton manager class that handles haptic feedback generation throughout the app
public class HapticManager {
    /// Shared instance of the HapticManager
    public static let shared = HapticManager()
    
    // MARK: - Private Properties
    
    /// Generator for notification-type feedback (success, warning, error)
    private let notificationGenerator: UINotificationFeedbackGenerator
    
    /// Generator for light impact feedback
    private let lightImpactGenerator: UIImpactFeedbackGenerator
    
    /// Generator for medium impact feedback
    private let mediumImpactGenerator: UIImpactFeedbackGenerator
    
    /// Generator for heavy impact feedback
    private let heavyImpactGenerator: UIImpactFeedbackGenerator
    
    /// Generator for selection feedback
    private let selectionGenerator: UISelectionFeedbackGenerator
    
    // MARK: - Initialization
    
    /// Private initializer that creates and prepares the feedback generators
    private init() {
        // Initialize all generators
        notificationGenerator = UINotificationFeedbackGenerator()
        lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
        mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
        heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        selectionGenerator = UISelectionFeedbackGenerator()
        
        // Prepare all generators to reduce latency
        prepareGenerators()
    }
    
    // MARK: - Public Methods
    
    /// Generates haptic feedback based on the specified type
    /// - Parameter type: The type of haptic feedback to generate
    public func generateFeedback(_ type: HapticFeedbackType) {
        switch type {
        case .light:
            lightImpactGenerator.impactOccurred()
        case .medium:
            mediumImpactGenerator.impactOccurred()
        case .heavy:
            heavyImpactGenerator.impactOccurred()
        case .selection:
            selectionGenerator.selectionChanged()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        }
    }
    
    /// Prepares all feedback generators to reduce latency when generating feedback
    public func prepareGenerators() {
        notificationGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
    }
}