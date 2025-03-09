//
//  IconButton.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import SwiftUI // iOS SDK

/// A customizable icon button component that provides consistent styling and behavior
/// for icon-based buttons throughout the Amira Wellness app.
struct IconButton: View {
    // MARK: - Properties
    
    /// The name of the SF Symbol to use as the icon
    let systemName: String
    
    /// Optional accessibility label for the button
    let label: String?
    
    /// Whether the button is enabled
    let isEnabled: Bool
    
    /// The color of the icon
    let iconColor: Color
    
    /// The background color of the button
    let backgroundColor: Color
    
    /// The size of the button (width and height)
    let size: CGFloat
    
    /// The size of the icon
    let iconSize: CGFloat
    
    /// The corner radius of the button
    let cornerRadius: CGFloat
    
    /// Whether to show a shadow under the button
    let hasShadow: Bool
    
    /// The type of haptic feedback to generate when the button is tapped
    let feedbackType: HapticFeedbackType
    
    /// The action to perform when the button is tapped
    let action: () -> Void
    
    // MARK: - Initialization
    
    /// Creates a new icon button with the specified parameters
    /// - Parameters:
    ///   - systemName: The name of the SF Symbol to use as the icon
    ///   - label: Optional accessibility label (defaults to nil)
    ///   - isEnabled: Whether the button is enabled (defaults to true)
    ///   - iconColor: The color of the icon (defaults to primary color)
    ///   - backgroundColor: The background color of the button (defaults to background color)
    ///   - size: The size of the button (defaults to 44, the minimum touch target size)
    ///   - iconSize: The size of the icon (defaults to 20)
    ///   - cornerRadius: The corner radius of the button (defaults to size/2 for a circular button)
    ///   - hasShadow: Whether to show a shadow (defaults to false)
    ///   - feedbackType: The type of haptic feedback to generate (defaults to light)
    ///   - action: The action to perform when the button is tapped
    init(
        systemName: String,
        label: String? = nil,
        isEnabled: Bool = true,
        iconColor: Color = ColorConstants.primary,
        backgroundColor: Color = ColorConstants.background,
        size: CGFloat = 44,
        iconSize: CGFloat = 20,
        cornerRadius: CGFloat? = nil,
        hasShadow: Bool = false,
        feedbackType: HapticFeedbackType = .light,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.label = label
        self.isEnabled = isEnabled
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius ?? size / 2
        self.hasShadow = hasShadow
        self.feedbackType = feedbackType
        self.action = action
    }
    
    // MARK: - Body
    
    /// The content and behavior of the view
    var body: some View {
        Button {
            // Generate haptic feedback before executing the action
            HapticManager.shared.generateFeedback(feedbackType)
            action()
        } label: {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(iconColor)
                .padding()
                .frame(width: size, height: size)
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
                .shadow(color: Color.black.opacity(0.2), radius: hasShadow ? 4 : 0, x: 0, y: hasShadow ? 2 : 0)
                .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(label ?? systemName)
    }
}

// MARK: - Preview
#if DEBUG
struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Default icon button
            IconButton(
                systemName: "heart",
                action: {}
            )
            
            // Customized icon button
            IconButton(
                systemName: "plus",
                label: "Add item",
                iconColor: .white,
                backgroundColor: ColorConstants.primary,
                size: 60,
                iconSize: 24,
                hasShadow: true,
                action: {}
            )
            
            // Disabled icon button
            IconButton(
                systemName: "trash",
                label: "Delete item",
                isEnabled: false,
                iconColor: .white,
                backgroundColor: ColorConstants.error,
                action: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif