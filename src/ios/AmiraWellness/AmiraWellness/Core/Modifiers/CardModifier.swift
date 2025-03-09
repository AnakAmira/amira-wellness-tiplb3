//
//  CardModifier.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI // iOS SDK

/// A ViewModifier that applies consistent card styling to any view
struct CardModifier: ViewModifier {
    /// The background color of the card
    let backgroundColor: Color?
    
    /// The corner radius of the card
    let cornerRadius: CGFloat
    
    /// The padding inside the card
    let padding: EdgeInsets
    
    /// The radius of the card's shadow
    let shadowRadius: CGFloat
    
    /// The horizontal offset of the card's shadow
    let shadowX: CGFloat
    
    /// The vertical offset of the card's shadow
    let shadowY: CGFloat
    
    /// The opacity of the card's shadow
    let shadowOpacity: CGFloat
    
    /// The color of the card's shadow
    let shadowColor: Color?
    
    /// Whether the card has a border
    let hasBorder: Bool
    
    /// The color of the card's border (if hasBorder is true)
    let borderColor: Color?
    
    /// The width of the card's border (if hasBorder is true)
    let borderWidth: CGFloat
    
    /// Initializes a new CardModifier with the specified styling parameters
    /// - Parameters:
    ///   - backgroundColor: The background color of the card (default: ColorConstants.surface)
    ///   - cornerRadius: The corner radius of the card (default: 12)
    ///   - padding: The padding inside the card (default: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
    ///   - shadowRadius: The radius of the card's shadow (default: 4)
    ///   - shadowX: The horizontal offset of the card's shadow (default: 0)
    ///   - shadowY: The vertical offset of the card's shadow (default: 2)
    ///   - shadowOpacity: The opacity of the card's shadow (default: 0.1)
    ///   - shadowColor: The color of the card's shadow (default: ColorConstants.shadow)
    ///   - hasBorder: Whether the card has a border (default: false)
    ///   - borderColor: The color of the card's border (default: nil)
    ///   - borderWidth: The width of the card's border (default: 1)
    init(
        backgroundColor: Color? = ColorConstants.surface,
        cornerRadius: CGFloat = 12,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        shadowRadius: CGFloat = 4,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 2,
        shadowOpacity: CGFloat = 0.1,
        shadowColor: Color? = ColorConstants.shadow,
        hasBorder: Bool = false,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.shadowX = shadowX
        self.shadowY = shadowY
        self.shadowOpacity = shadowOpacity
        self.shadowColor = shadowColor
        self.hasBorder = hasBorder
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    /// Applies the card styling to the provided content
    /// - Parameter content: The content to style as a card
    /// - Returns: The content with card styling applied
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor ?? ColorConstants.surface)
            .cornerRadius(cornerRadius)
            .customShadow(
                radius: shadowRadius,
                x: shadowX,
                y: shadowY,
                color: shadowColor,
                opacity: shadowOpacity
            )
            .overlay(
                Group {
                    if hasBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor ?? ColorConstants.border, lineWidth: borderWidth)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - View Extension
extension View {
    /// Applies card styling to the view with the specified parameters
    /// - Parameters:
    ///   - backgroundColor: The background color of the card (default: ColorConstants.surface)
    ///   - cornerRadius: The corner radius of the card (default: 12)
    ///   - padding: The padding inside the card (default: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
    ///   - shadowRadius: The radius of the card's shadow (default: 4)
    ///   - shadowX: The horizontal offset of the card's shadow (default: 0)
    ///   - shadowY: The vertical offset of the card's shadow (default: 2)
    ///   - shadowOpacity: The opacity of the card's shadow (default: 0.1)
    ///   - shadowColor: The color of the card's shadow (default: ColorConstants.shadow)
    ///   - hasBorder: Whether the card has a border (default: false)
    ///   - borderColor: The color of the card's border (default: nil)
    ///   - borderWidth: The width of the card's border (default: 1)
    /// - Returns: The view with card styling applied
    func cardStyle(
        backgroundColor: Color? = ColorConstants.surface,
        cornerRadius: CGFloat = 12,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        shadowRadius: CGFloat = 4,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 2,
        shadowOpacity: CGFloat = 0.1,
        shadowColor: Color? = ColorConstants.shadow,
        hasBorder: Bool = false,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1
    ) -> some View {
        self.modifier(CardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            padding: padding,
            shadowRadius: shadowRadius,
            shadowX: shadowX,
            shadowY: shadowY,
            shadowOpacity: shadowOpacity,
            shadowColor: shadowColor,
            hasBorder: hasBorder,
            borderColor: borderColor,
            borderWidth: borderWidth
        ))
    }
}