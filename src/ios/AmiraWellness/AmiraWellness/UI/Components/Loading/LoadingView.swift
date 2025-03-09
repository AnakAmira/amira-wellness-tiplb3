//
//  LoadingView.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // SwiftUI - iOS SDK
import ColorConstants // ../../../Core/Constants/ColorConstants
import LottieView // ../../Animation/LottieView
import ProgressBar // ./ProgressBar

/// A customizable loading view that displays an animation and optional message
/// with a nature-inspired design consistent with the app's aesthetic.
struct LoadingView: View {
    // MARK: - Properties
    
    /// Optional message to display below the loading animation
    var message: String?
    
    /// Controls whether the loading view is visible
    var isLoading: Bool
    
    /// Optional progress value for determinate loading (nil for indeterminate)
    var progress: Double?
    
    /// The total value for progress calculation (denominator)
    var total: Double
    
    /// The name of the Lottie animation file to display
    var animationName: String
    
    /// The tint color for the loading animation
    var tintColor: Color
    
    /// Whether to show a progress bar for determinate loading
    var showProgressBar: Bool
    
    /// Whether to display as a fullscreen overlay or contained view
    var fullscreen: Bool
    
    // MARK: - Initialization
    
    /// Creates a new loading view with customizable appearance
    /// - Parameters:
    ///   - message: Optional text to display below the animation
    ///   - isLoading: Controls visibility of the loading view
    ///   - progress: Optional progress value (nil for indeterminate loading)
    ///   - total: The maximum value for progress calculation
    ///   - animationName: The name of the Lottie animation file
    ///   - tintColor: The tint color for the loading animation
    ///   - showProgressBar: Whether to show a progress bar for determinate loading
    ///   - fullscreen: Whether to display as a fullscreen overlay
    init(
        message: String? = nil,
        isLoading: Bool = true,
        progress: Double? = nil,
        total: Double = 1.0,
        animationName: String = "lottie_loading",
        tintColor: Color? = nil,
        showProgressBar: Bool = false,
        fullscreen: Bool = false
    ) {
        self.message = message
        self.isLoading = isLoading
        self.progress = progress
        self.total = total
        self.animationName = animationName
        self.tintColor = tintColor ?? ColorConstants.primary
        self.showProgressBar = showProgressBar
        self.fullscreen = fullscreen
    }
    
    // MARK: - Body
    
    var body: some View {
        if isLoading {
            Group {
                if fullscreen {
                    // Fullscreen overlay with semi-transparent background
                    ZStack {
                        ColorConstants.background.opacity(0.8)
                        loadingContent
                            .padding(40)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ColorConstants.background)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                            )
                            .padding(20)
                    }
                    .edgesIgnoringSafeArea(.all)
                } else {
                    // Contained loading view
                    loadingContent
                        .padding()
                }
            }
            .accessibilityElement(children: message == nil)
            .accessibilityLabel(message ?? "Loading")
            .accessibilityTraits(.updatesFrequently)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
        }
    }
    
    /// The core loading content (animation, message, progress)
    private var loadingContent: some View {
        VStack(spacing: 20) {
            // Lottie animation
            LottieView(
                animationName: animationName,
                loopMode: true,
                tintColor: tintColor,
                contentMode: .fit
            )
            .frame(width: 80, height: 80)
            .accessibility(label: Text("Loading"))
            
            // Optional message text
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorConstants.textPrimary)
            }
            
            // Progress bar for determinate loading
            if isDeterminate() {
                ProgressBar(
                    value: progress ?? 0,
                    total: total,
                    height: 8,
                    backgroundColor: ColorConstants.surface,
                    foregroundColor: tintColor,
                    cornerRadius: 4,
                    showPercentage: true,
                    animated: true
                )
                .frame(width: 200)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines if the loading view should show determinate progress
    /// - Returns: Whether determinate progress should be shown
    private func isDeterminate() -> Bool {
        return showProgressBar && progress != nil
    }
}