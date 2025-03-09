//
//  ProgressBar.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // SwiftUI - iOS SDK
import ColorConstants // ../../../Core/Constants/ColorConstants

/// A customizable progress bar component that visualizes determinate progress
/// with a nature-inspired aesthetic consistent with the app's design language.
struct ProgressBar: View {
    // MARK: - Properties
    
    /// The current progress value
    private var value: Double
    
    /// The maximum value (denominator for progress calculation)
    private var total: Double
    
    /// The height of the progress bar
    private var height: CGFloat
    
    /// The background color of the progress bar
    private var backgroundColor: Color
    
    /// The foreground color of the progress bar (the filled portion)
    private var foregroundColor: Color
    
    /// The corner radius of the progress bar
    private var cornerRadius: CGFloat
    
    /// Flag to determine if percentage text should be shown
    private var showPercentage: Bool
    
    /// Flag to determine if progress changes should be animated
    private var animated: Bool
    
    // MARK: - Initialization
    
    /// Creates a new progress bar with customizable appearance
    /// - Parameters:
    ///   - value: The current progress value (default: 0.0)
    ///   - total: The maximum value (default: 1.0)
    ///   - height: The height of the progress bar (default: 8.0)
    ///   - backgroundColor: The background color (default: ColorConstants.surface)
    ///   - foregroundColor: The foreground color (default: ColorConstants.primary)
    ///   - cornerRadius: The corner radius (default: 4.0)
    ///   - showPercentage: Whether to show percentage text (default: false)
    ///   - animated: Whether to animate progress changes (default: true)
    init(
        value: Double = 0.0,
        total: Double = 1.0, 
        height: CGFloat = 8.0,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        cornerRadius: CGFloat = 4.0,
        showPercentage: Bool = false,
        animated: Bool = true
    ) {
        self.value = value
        self.total = total
        self.height = height
        self.backgroundColor = backgroundColor ?? ColorConstants.surface
        self.foregroundColor = foregroundColor ?? ColorConstants.primary
        self.cornerRadius = cornerRadius
        self.showPercentage = showPercentage
        self.animated = animated
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: showPercentage ? 4 : 0) {
            // Show percentage text above the progress bar if enabled
            if showPercentage {
                Text(formattedPercentage())
                    .font(.caption)
                    .foregroundColor(ColorConstants.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 2)
                    .accessibility(hidden: true) // Screen readers will use the progress view's label
            }
            
            // Use GeometryReader to get the available width for the progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background capsule
                    Capsule()
                        .fill(backgroundColor)
                        .frame(width: geometry.size.width, height: height)
                    
                    // Foreground capsule (progress)
                    Capsule()
                        .fill(foregroundColor)
                        .frame(width: geometry.size.width * CGFloat(progressPercentage()), height: height)
                        .if(animated) { view in
                            view.animation(.easeInOut(duration: 0.3), value: progressPercentage())
                        }
                }
                .cornerRadius(cornerRadius)
            }
            .frame(height: height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progress")
            .accessibilityValue("\(Int(progressPercentage() * 100))%")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the progress percentage between 0 and 1
    /// - Returns: The progress percentage as a value between 0 and 1
    private func progressPercentage() -> Double {
        let percentage = total > 0 ? value / total : 0
        return min(max(percentage, 0), 1) // Clamp between 0 and 1
    }
    
    /// Formats the progress percentage as a string with a % symbol
    /// - Returns: The formatted percentage string
    private func formattedPercentage() -> String {
        return "\(Int(progressPercentage() * 100))%"
    }
}

// MARK: - View Modifier Extension

extension View {
    /// Conditional modifier that applies the given transform if the condition is true
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - transform: The transform to apply if the condition is true
    /// - Returns: The modified view
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressBar(value: 0.3, showPercentage: true)
                .frame(height: 40)
                .previewDisplayName("Default with percentage")
            
            ProgressBar(value: 0.7, total: 1.0, height: 12, cornerRadius: 6)
                .frame(height: 40)
                .previewDisplayName("Taller bar")
            
            ProgressBar(
                value: 0.5,
                height: 16,
                backgroundColor: Color.gray.opacity(0.3),
                foregroundColor: ColorConstants.secondary,
                cornerRadius: 8,
                showPercentage: true
            )
            .frame(height: 50)
            .previewDisplayName("Custom colors")
            
            // Show different progress values
            VStack(spacing: 10) {
                ProgressBar(value: 0.25, showPercentage: true)
                ProgressBar(value: 0.5, showPercentage: true)
                ProgressBar(value: 0.75, showPercentage: true)
                ProgressBar(value: 1.0, showPercentage: true)
            }
            .padding()
            .background(ColorConstants.surface)
            .cornerRadius(12)
            .previewDisplayName("Various progress values")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}