//
//  ShadowModifier.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI // iOS SDK
import ColorConstants // ../Constants/ColorConstants.swift

/// A view modifier that applies a consistent shadow styling throughout the app
struct ShadowModifier: ViewModifier {
    /// The radius of the shadow
    let radius: CGFloat
    
    /// The horizontal offset of the shadow
    let x: CGFloat
    
    /// The vertical offset of the shadow
    let y: CGFloat
    
    /// The color of the shadow
    let color: Color?
    
    /// The opacity of the shadow
    let opacity: CGFloat
    
    /// Initializes a new ShadowModifier with the specified shadow parameters
    /// - Parameters:
    ///   - radius: The radius of the shadow blur (default: 4)
    ///   - x: The horizontal offset of the shadow (default: 0)
    ///   - y: The vertical offset of the shadow (default: 2)
    ///   - color: The color of the shadow (default: ColorConstants.shadow)
    ///   - opacity: The opacity of the shadow (default: 0.1)
    init(
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2,
        color: Color? = ColorConstants.shadow,
        opacity: CGFloat = 0.1
    ) {
        self.radius = radius
        self.x = x
        self.y = y
        self.color = color
        self.opacity = opacity
    }
    
    /// Applies the shadow styling to the provided content
    /// - Parameter content: The content to which the shadow will be applied
    /// - Returns: The content with shadow applied
    func body(content: Content) -> some View {
        content
            .shadow(
                color: (color ?? Color.black).opacity(opacity),
                radius: radius,
                x: x,
                y: y
            )
    }
}

// MARK: - View Extension
extension View {
    /// Applies a custom shadow to the view with specified parameters
    /// - Parameters:
    ///   - radius: The radius of the shadow blur (default: 4)
    ///   - x: The horizontal offset of the shadow (default: 0)
    ///   - y: The vertical offset of the shadow (default: 2)
    ///   - color: The color of the shadow (default: ColorConstants.shadow)
    ///   - opacity: The opacity of the shadow (default: 0.1)
    /// - Returns: The view with the shadow applied
    func customShadow(
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2,
        color: Color? = ColorConstants.shadow,
        opacity: CGFloat = 0.1
    ) -> some View {
        self.modifier(ShadowModifier(
            radius: radius,
            x: x,
            y: y,
            color: color,
            opacity: opacity
        ))
    }
}