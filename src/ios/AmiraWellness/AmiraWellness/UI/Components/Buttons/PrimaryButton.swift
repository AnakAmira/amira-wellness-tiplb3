//
//  PrimaryButton.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // iOS SDK
import ColorConstants // ../../../Core/Constants/ColorConstants.swift
import ShadowModifier // ../../../Core/Modifiers/ShadowModifier.swift
import Haptics // ../../../Core/Utilities/Haptics.swift

/// A reusable primary button component that provides consistent styling and behavior
/// for main action buttons throughout the Amira Wellness app, following the app's
/// minimalist, nature-inspired design language.
struct PrimaryButton: View {
    // MARK: - Properties
    
    /// The text displayed on the button
    let title: String
    
    /// Whether the button is enabled and interactive
    let isEnabled: Bool
    
    /// Whether the button is in a loading state
    let isLoading: Bool
    
    /// The background color of the button
    let backgroundColor: Color
    
    /// The text color of the button
    let textColor: Color
    
    /// The height of the button
    let height: CGFloat
    
    /// The corner radius of the button
    let cornerRadius: CGFloat
    
    /// Whether the button has a shadow
    let hasShadow: Bool
    
    /// The type of haptic feedback to generate when the button is tapped
    let feedbackType: HapticFeedbackType
    
    /// The action to perform when the button is tapped
    let action: () -> Void
    
    // MARK: - Initialization
    
    /// Initializes a new PrimaryButton with the specified parameters
    /// - Parameters:
    ///   - title: The text displayed on the button
    ///   - isEnabled: Whether the button is enabled and interactive (default: true)
    ///   - isLoading: Whether the button is in a loading state (default: false)
    ///   - backgroundColor: The background color of the button (default: ColorConstants.primary)
    ///   - textColor: The text color of the button (default: ColorConstants.textOnPrimary)
    ///   - height: The height of the button (default: 50)
    ///   - cornerRadius: The corner radius of the button (default: 10)
    ///   - hasShadow: Whether the button has a shadow (default: true)
    ///   - feedbackType: The type of haptic feedback to generate when the button is tapped (default: .medium)
    ///   - action: The action to perform when the button is tapped
    init(
        title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        backgroundColor: Color = ColorConstants.primary,
        textColor: Color = ColorConstants.textOnPrimary,
        height: CGFloat = 50,
        cornerRadius: CGFloat = 10,
        hasShadow: Bool = true,
        feedbackType: HapticFeedbackType = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.height = height
        self.cornerRadius = cornerRadius
        self.hasShadow = hasShadow
        self.feedbackType = feedbackType
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            // Generate haptic feedback first, then perform the action
            HapticManager.shared.generateFeedback(feedbackType)
            action()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .customShadow(opacity: hasShadow ? 0.1 : 0.0)  // Use 0 opacity to hide shadow when not needed
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
    }
}