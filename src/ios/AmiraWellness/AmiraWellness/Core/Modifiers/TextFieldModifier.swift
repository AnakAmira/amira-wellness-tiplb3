//
//  TextFieldModifier.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // iOS SDK
import ColorConstants // ../Constants/ColorConstants.swift

/// A ViewModifier that applies consistent text field styling to any TextField view
struct TextFieldModifier: ViewModifier {
    // MARK: - Properties
    
    /// The font to be used for the text field
    let font: Font
    
    /// The color of the text in the text field
    let textColor: Color?
    
    /// The color of the placeholder text
    let placeholderColor: Color?
    
    /// The background color of the text field
    let backgroundColor: Color?
    
    /// The color of the text field border
    let borderColor: Color?
    
    /// The width of the text field border
    let borderWidth: CGFloat
    
    /// The corner radius of the text field
    let cornerRadius: CGFloat
    
    /// The padding inside the text field
    let padding: EdgeInsets
    
    /// Whether to show a border around the text field
    let showBorder: Bool
    
    // MARK: - Initializer
    
    /// Initializes a new TextFieldModifier with the specified styling parameters
    /// - Parameters:
    ///   - font: The font to be used (default: .body)
    ///   - textColor: The color of the text (default: ColorConstants.textPrimary)
    ///   - placeholderColor: The color of the placeholder text (default: ColorConstants.textPrimary.opacity(0.6))
    ///   - backgroundColor: The background color (default: ColorConstants.background)
    ///   - borderColor: The border color (default: ColorConstants.border)
    ///   - borderWidth: The width of the border (default: 1)
    ///   - cornerRadius: The corner radius (default: 8)
    ///   - padding: The padding inside the text field (default: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
    ///   - showBorder: Whether to show a border (default: true)
    init(
        font: Font = .body,
        textColor: Color? = ColorConstants.textPrimary,
        placeholderColor: Color? = ColorConstants.textPrimary.opacity(0.6),
        backgroundColor: Color? = ColorConstants.background,
        borderColor: Color? = ColorConstants.border,
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 8,
        padding: EdgeInsets = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
        showBorder: Bool = true
    ) {
        self.font = font
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.showBorder = showBorder
    }
    
    // MARK: - ViewModifier Implementation
    
    /// Applies the text field styling to the provided content
    /// - Parameter content: The content to be modified
    /// - Returns: The modified content with text field styling applied
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .padding(padding)
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor ?? Color.clear, lineWidth: borderWidth)
                    }
                }
            )
            // Add accessibility improvements
            .accessibilityElement(children: .combine)
    }
}

// MARK: - View Extension

extension View {
    /// Applies custom text field styling to a view
    /// - Parameters:
    ///   - font: The font to be used
    ///   - textColor: The color of the text
    ///   - placeholderColor: The color of the placeholder text
    ///   - backgroundColor: The background color
    ///   - borderColor: The border color
    ///   - borderWidth: The width of the border
    ///   - cornerRadius: The corner radius
    ///   - padding: The padding inside the text field
    ///   - showBorder: Whether to show a border
    /// - Returns: The view with text field styling applied
    func textFieldStyle(
        font: Font = .body,
        textColor: Color? = ColorConstants.textPrimary,
        placeholderColor: Color? = ColorConstants.textPrimary.opacity(0.6),
        backgroundColor: Color? = ColorConstants.background,
        borderColor: Color? = ColorConstants.border,
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 8,
        padding: EdgeInsets = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
        showBorder: Bool = true
    ) -> some View {
        self.modifier(TextFieldModifier(
            font: font,
            textColor: textColor,
            placeholderColor: placeholderColor,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            padding: padding,
            showBorder: showBorder
        ))
    }
}