//
//  SecondaryButton.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI // iOS SDK

/// A reusable secondary button component that provides consistent styling and behavior
/// for alternative action buttons throughout the Amira Wellness app, following the app's
/// minimalist, nature-inspired design language.
struct SecondaryButton: View {
    // MARK: - Properties
    
    /// The title text to display on the button
    let title: String
    
    /// Whether the button is enabled and can be interacted with
    let isEnabled: Bool
    
    /// Whether the button is in a loading state
    let isLoading: Bool
    
    /// The background color of the button
    let backgroundColor: Color
    
    /// The text color of the button
    let textColor: Color
    
    /// The border color of the button
    let borderColor: Color
    
    /// The height of the button
    let height: CGFloat
    
    /// The corner radius of the button
    let cornerRadius: CGFloat
    
    /// The width of the button's border
    let borderWidth: CGFloat
    
    /// Whether the button has a shadow
    let hasShadow: Bool
    
    /// The type of haptic feedback to generate when the button is pressed
    let feedbackType: HapticFeedbackType
    
    /// The action to perform when the button is tapped
    let action: () -> Void
    
    // MARK: - Initialization
    
    /// Initializes a new SecondaryButton with the specified parameters
    /// - Parameters:
    ///   - title: The title text to display on the button
    ///   - isEnabled: Whether the button is enabled (default: true)
    ///   - isLoading: Whether the button is in a loading state (default: false)
    ///   - backgroundColor: The background color of the button (default: Color.white)
    ///   - textColor: The text color of the button (default: ColorConstants.secondary)
    ///   - borderColor: The border color of the button (default: ColorConstants.secondary)
    ///   - height: The height of the button (default: 50)
    ///   - cornerRadius: The corner radius of the button (default: 10)
    ///   - borderWidth: The width of the button's border (default: 1)
    ///   - hasShadow: Whether the button has a shadow (default: true)
    ///   - feedbackType: The type of haptic feedback to generate (default: .light)
    ///   - action: The action to perform when the button is tapped
    init(
        title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        backgroundColor: Color = Color.white,
        textColor: Color = ColorConstants.secondary,
        borderColor: Color = ColorConstants.secondary,
        height: CGFloat = 50,
        cornerRadius: CGFloat = 10,
        borderWidth: CGFloat = 1,
        hasShadow: Bool = true,
        feedbackType: HapticFeedbackType = .light,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderColor = borderColor
        self.height = height
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.hasShadow = hasShadow
        self.feedbackType = feedbackType
        self.action = action
    }
    
    // MARK: - Body
    
    /// Builds the button view with the specified styling
    var body: some View {
        Button {
            // Generate haptic feedback when button is pressed
            HapticManager.shared.generateFeedback(feedbackType)
            
            // Execute the provided action
            action()
        } label: {
            ZStack {
                if isLoading {
                    // Show loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    // Show button title
                    Text(title)
                        .font(.headline)
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .customShadow(
                radius: hasShadow ? 4 : 0,
                opacity: hasShadow ? 0.1 : 0
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
    }
}