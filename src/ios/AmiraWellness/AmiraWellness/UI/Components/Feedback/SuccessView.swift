//
//  SuccessView.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // iOS SDK

/// A reusable component that displays a success state with an animation,
/// success message, and optional action button.
struct SuccessView: View {
    // MARK: - Properties
    
    /// The name of the Lottie animation file to display
    let animationName: String
    
    /// The title text to display (e.g., "Success!")
    let title: String
    
    /// The message text to display
    let message: String
    
    /// The title for the optional action button
    let buttonTitle: String?
    
    /// The spacing between elements
    let spacing: CGFloat
    
    /// The size of the animation
    let animationSize: CGFloat
    
    /// The action to perform when the button is tapped
    let buttonAction: (() -> Void)?
    
    /// Whether the animation is currently playing
    @State private var isAnimationPlaying: Bool = true
    
    // MARK: - Initialization
    
    /// Initializes a new SuccessView with the specified parameters
    /// - Parameters:
    ///   - animationName: The name of the Lottie animation file (default: "lottie_success")
    ///   - title: The title text to display (default: "¡Éxito!")
    ///   - message: The message text to display
    ///   - buttonTitle: The title for the optional action button (default: nil)
    ///   - spacing: The spacing between elements (default: 20)
    ///   - animationSize: The size of the animation (default: 150)
    ///   - buttonAction: The action to perform when the button is tapped (default: nil)
    init(
        animationName: String = "lottie_success",
        title: String = "¡Éxito!",
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
            // Animation
            LottieView(
                animationName: animationName,
                loopMode: true,
                isPlaying: $isAnimationPlaying
            )
            .frame(width: animationSize, height: animationSize)
            .accessibilityHidden(true)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.success)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .multilineTextAlignment(.center)
            
            // Optional button
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                PrimaryButton(
                    title: buttonTitle,
                    backgroundColor: ColorConstants.success,
                    action: buttonAction
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(message)")
    }
}