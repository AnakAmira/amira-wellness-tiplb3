//
//  EmptyStateView.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI

/// A reusable component that displays an empty state with an animation, message, and optional action button.
/// Used throughout the app to provide feedback when no content is available or when a user needs to take an action.
struct EmptyStateView: View {
    // MARK: - Properties
    
    /// The name of the Lottie animation file to display
    let animationName: String
    
    /// The title text displayed above the message
    let title: String
    
    /// The message text describing the empty state
    let message: String
    
    /// Optional text for the action button (nil if no button should be displayed)
    let buttonTitle: String?
    
    /// The spacing between elements in the view
    let spacing: CGFloat
    
    /// The size of the animation view
    let animationSize: CGFloat
    
    /// The action to perform when the button is tapped (nil if no action)
    let buttonAction: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes a new EmptyStateView with the specified parameters
    /// - Parameters:
    ///   - animationName: The name of the Lottie animation file (default: "lottie_empty")
    ///   - title: The title text displayed above the message (default: "No hay contenido")
    ///   - message: The message text describing the empty state
    ///   - buttonTitle: Optional text for the action button (nil if no button should be displayed)
    ///   - spacing: The spacing between elements in the view (default: 20)
    ///   - animationSize: The size of the animation view (default: 150)
    ///   - buttonAction: The action to perform when the button is tapped (nil if no action)
    init(
        animationName: String = "lottie_empty",
        title: String = "No hay contenido",
        message: String,
        buttonTitle: String? = nil,
        spacing: CGFloat = 20,
        animationSize: CGFloat = 150,
        buttonAction: (() -> Void)? = nil
    ) {
        self.animationName = animationName
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.spacing = spacing
        self.animationSize = animationSize
        self.buttonAction = buttonAction
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: spacing) {
            // Lottie animation
            LottieView(animationName: animationName)
                .frame(width: animationSize, height: animationSize)
                .accessibilityHidden(true) // Hide animation from accessibility as it's decorative
            
            // Title text
            Text(title)
                .font(.headline)
                .foregroundColor(ColorConstants.info)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            // Message text
            Text(message)
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .multilineTextAlignment(.center)
            
            // Optional action button
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                PrimaryButton(
                    title: buttonTitle,
                    action: buttonAction
                )
                .padding(.top, spacing / 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Empty state: \(title). \(message)")
    }
}