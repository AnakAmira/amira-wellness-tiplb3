//
//  View+Extensions.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI
import Combine

// MARK: - View Extensions

extension View {
    // MARK: - Styling
    
    /// Applies the standard card styling to a view
    /// - Parameters:
    ///   - backgroundColor: The background color of the card
    ///   - cornerRadius: The corner radius of the card
    ///   - shadowRadius: The shadow radius
    ///   - shadowOpacity: The shadow opacity
    ///   - shadowOffsetY: The vertical shadow offset
    ///   - shadowColor: The shadow color
    ///   - padding: The padding inside the card
    /// - Returns: The view with card styling applied
    func cardStyle(
        backgroundColor: Color? = ColorConstants.surface,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 4,
        shadowOpacity: CGFloat = 0.1,
        shadowOffsetY: CGFloat = 2,
        shadowColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    ) -> some View {
        self.modifier(CardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            padding: padding,
            shadowRadius: shadowRadius,
            shadowX: 0,
            shadowY: shadowOffsetY,
            shadowOpacity: shadowOpacity,
            shadowColor: shadowColor
        ))
    }
    
    /// Applies a custom shadow to a view
    /// - Parameters:
    ///   - radius: The shadow radius
    ///   - x: The horizontal shadow offset
    ///   - y: The vertical shadow offset
    ///   - opacity: The shadow opacity
    ///   - color: The shadow color
    /// - Returns: The view with custom shadow applied
    func customShadow(
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2,
        opacity: CGFloat = 0.1,
        color: Color? = nil
    ) -> some View {
        self.modifier(ShadowModifier(
            radius: radius,
            x: x,
            y: y,
            color: color,
            opacity: opacity
        ))
    }
    
    /// Applies the standard text field styling to a TextField view
    /// - Parameters:
    ///   - font: The font for the text field
    ///   - textColor: The text color
    ///   - placeholderColor: The placeholder text color
    ///   - backgroundColor: The background color
    ///   - borderColor: The border color
    ///   - borderWidth: The border width
    ///   - cornerRadius: The corner radius
    ///   - padding: The padding inside the text field
    ///   - showBorder: Whether to show a border around the text field
    /// - Returns: The TextField with standard styling applied
    func standardTextFieldStyle(
        font: Font = .body,
        textColor: Color? = ColorConstants.textPrimary,
        placeholderColor: Color? = ColorConstants.textTertiary,
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
    
    /// Applies a corner radius to specific corners of a view
    /// - Parameters:
    ///   - radius: The corner radius
    ///   - corners: The corners to apply the radius to
    /// - Returns: The view with corner radius applied to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
    
    // MARK: - Interaction
    
    /// Dismisses the keyboard when called
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Adds a tap gesture with haptic feedback to a view
    /// - Parameters:
    ///   - feedbackType: The type of haptic feedback to generate
    ///   - action: The action to perform when tapped
    /// - Returns: The view with tap gesture and haptic feedback
    func onTapWithHaptic(feedbackType: HapticFeedbackType = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.generateFeedback(feedbackType)
            action()
        }
    }
    
    // MARK: - Conditional Modifiers
    
    /// Overlays a placeholder view when a condition is true
    /// - Parameters:
    ///   - shouldShow: Whether to show the placeholder
    ///   - placeholder: The placeholder view to show
    /// - Returns: The original view or the placeholder based on the condition
    func placeholder(
        when shouldShow: Bool,
        placeholder: AnyView
    ) -> some View {
        ZStack {
            self.opacity(shouldShow ? 0 : 1)
            if shouldShow {
                placeholder
            }
        }
    }
    
    /// Applies a modifier only when a condition is true
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - modifier: The modifier to apply when the condition is true
    /// - Returns: The view with the modifier applied conditionally
    @ViewBuilder func conditionalModifier<Content: View>(
        _ condition: Bool,
        _ modifier: (Self) -> Content
    ) -> some View {
        if condition {
            modifier(self)
        } else {
            self
        }
    }
    
    // MARK: - Layout Helpers
    
    /// Embeds a view in a ScrollView with specified axes
    /// - Parameters:
    ///   - axes: The scroll axes
    ///   - showsIndicators: Whether to show scroll indicators
    /// - Returns: The view embedded in a ScrollView
    func embedInScrollView(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true
    ) -> some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            self
        }
    }
    
    // MARK: - Utilities
    
    /// Debounces a binding value to prevent rapid updates
    /// - Parameters:
    ///   - binding: The binding to debounce
    ///   - debounceDuration: The debounce duration in seconds
    /// - Returns: The view with debounced binding
    func debounce<T: Equatable>(
        _ binding: Binding<T>,
        debounceDuration: TimeInterval = 0.5
    ) -> some View {
        let publisher = binding.wrappedValue.publisher
            .debounce(for: .seconds(debounceDuration), scheduler: RunLoop.main)
        
        return self.onReceive(publisher) { value in
            if binding.wrappedValue != value {
                binding.wrappedValue = value
            }
        }
    }
    
    /// Applies an adaptive background color based on color scheme
    /// - Parameters:
    ///   - lightModeColor: The color to use in light mode
    ///   - darkModeColor: The color to use in dark mode
    /// - Returns: The view with adaptive background color
    func adaptiveBackground(
        lightModeColor: Color,
        darkModeColor: Color
    ) -> some View {
        self.background(Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(darkModeColor) : UIColor(lightModeColor)
        }))
    }
    
    /// Applies a rounded border to a view
    /// - Parameters:
    ///   - color: The border color
    ///   - width: The border width
    ///   - cornerRadius: The corner radius
    /// - Returns: The view with a rounded border
    func roundedBorder(
        color: Color,
        width: CGFloat = 1,
        cornerRadius: CGFloat = 8
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// Centers a view in the screen
    /// - Returns: The view centered in the screen
    func centerInScreen() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                self
                Spacer()
            }
            Spacer()
        }
    }
    
    /// Reads the size of a view and provides it via a binding
    /// - Parameter size: The binding to update with the view's size
    /// - Returns: The view with size reading capability
    func readSize(onChange size: Binding<CGSize>) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { newSize in
            size.wrappedValue = newSize
        }
    }
}

// MARK: - Helper Structs

/// A shape that applies a corner radius to specific corners
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

/// A preference key for reading view sizes
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}