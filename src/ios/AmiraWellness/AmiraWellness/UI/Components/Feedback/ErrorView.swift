//
//  ErrorView.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // iOS SDK
import PrimaryButton // ../Buttons/PrimaryButton
import LottieView // ../Animation/LottieView
import ColorConstants // ../../../Core/Constants/ColorConstants

/// A customizable view that displays an error state with animation, message, and optional retry button
struct ErrorView: View {
    // MARK: - Properties
    
    /// The name of the Lottie animation to display
    let animationName: String
    
    /// The error title
    let title: String
    
    /// The error message
    let message: String
    
    /// The title for the retry button (nil to hide button)
    let buttonTitle: String?
    
    /// The spacing between elements
    let spacing: CGFloat
    
    /// The size of the animation
    let animationSize: CGFloat
    
    /// The action to perform when retry button is tapped
    let retryAction: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes a new ErrorView with the specified parameters
    /// - Parameters:
    ///   - animationName: The name of the Lottie animation to display (default: "lottie_error")
    ///   - title: The error title (default: "Error")
    ///   - message: The error message
    ///   - buttonTitle: The title for the retry button (default: "Reintentar", nil to hide button)
    ///   - spacing: The spacing between elements (default: 20)
    ///   - animationSize: The size of the animation (default: 150)
    ///   - retryAction: The action to perform when retry button is tapped (nil to hide button)
    init(
        animationName: String = "lottie_error",
        title: String = "Error",
        message: String,
        buttonTitle: String? = "Reintentar",
        spacing: CGFloat = 20,
        animationSize: CGFloat = 150,
        retryAction: (() -> Void)? = nil
    ) {
        self.animationName = animationName
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.spacing = spacing
        self.animationSize = animationSize
        self.retryAction = retryAction
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: spacing) {
            // Animation
            LottieView(
                animationName: animationName,
                loopMode: true,
                speed: 1.0,
                tintColor: ColorConstants.error
            )
            .frame(width: animationSize, height: animationSize)
            .accessibilityHidden(true)
            
            // Error title
            Text(title)
                .font(.headline)
                .foregroundColor(ColorConstants.error)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            // Error message
            Text(message)
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .multilineTextAlignment(.center)
            
            // Retry button (if provided)
            if let buttonTitle = buttonTitle, let retryAction = retryAction {
                PrimaryButton(
                    title: buttonTitle,
                    backgroundColor: ColorConstants.error,
                    textColor: ColorConstants.textOnPrimary,
                    action: retryAction
                )
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(message)")
    }
}