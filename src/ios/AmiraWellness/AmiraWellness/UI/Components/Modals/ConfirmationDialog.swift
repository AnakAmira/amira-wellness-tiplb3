//
//  ConfirmationDialog.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI

/// A customizable modal dialog that presents a message with confirm and cancel options
struct ConfirmationDialog: View {
    // MARK: - Properties
    
    /// The title of the dialog
    let title: String
    
    /// The message to display in the dialog
    let message: String
    
    /// The text for the confirm button
    let confirmButtonTitle: String
    
    /// The text for the cancel button (optional)
    let cancelButtonTitle: String?
    
    /// The maximum width of the dialog
    let maxWidth: CGFloat
    
    /// Binding to control the visibility of the dialog
    @Binding private var isShowing: Bool
    
    /// Action to perform when the confirm button is tapped
    let onConfirm: (() -> Void)?
    
    /// Action to perform when the cancel button is tapped
    let onCancel: (() -> Void)?
    
    /// The type of haptic feedback to generate for the confirm button
    let confirmFeedbackType: HapticFeedbackType
    
    /// The type of haptic feedback to generate for the cancel button
    let cancelFeedbackType: HapticFeedbackType
    
    // MARK: - Initialization
    
    /// Initializes a new ConfirmationDialog with the specified parameters
    /// - Parameters:
    ///   - title: The title of the dialog
    ///   - message: The message to display in the dialog
    ///   - confirmButtonTitle: The text for the confirm button
    ///   - cancelButtonTitle: The text for the cancel button (optional)
    ///   - isShowing: Binding to control the visibility of the dialog
    ///   - maxWidth: The maximum width of the dialog
    ///   - confirmFeedbackType: The type of haptic feedback for the confirm button
    ///   - cancelFeedbackType: The type of haptic feedback for the cancel button
    ///   - onConfirm: Action to perform when the confirm button is tapped
    ///   - onCancel: Action to perform when the cancel button is tapped
    init(
        title: String = "Confirmar",
        message: String,
        confirmButtonTitle: String = "Confirmar",
        cancelButtonTitle: String? = "Cancelar",
        isShowing: Binding<Bool>,
        maxWidth: CGFloat = 300,
        confirmFeedbackType: HapticFeedbackType = .medium,
        cancelFeedbackType: HapticFeedbackType = .light,
        onConfirm: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self._isShowing = isShowing
        self.maxWidth = maxWidth
        self.confirmFeedbackType = confirmFeedbackType
        self.cancelFeedbackType = cancelFeedbackType
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            if isShowing {
                ColorConstants.semiTransparentBlack
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 0.2), value: isShowing)
            }
            
            // Dialog content
            if isShowing {
                VStack(spacing: 16) {
                    // Title
                    Text(title)
                        .font(.headline)
                        .foregroundColor(ColorConstants.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Message
                    Text(message)
                        .font(.body)
                        .foregroundColor(ColorConstants.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 16)
                    
                    // Buttons
                    VStack(spacing: 12) {
                        // Confirm button
                        PrimaryButton(
                            title: confirmButtonTitle,
                            feedbackType: confirmFeedbackType,
                            action: handleConfirm
                        )
                        
                        // Cancel button (if provided)
                        if let cancelButtonTitle = cancelButtonTitle {
                            SecondaryButton(
                                title: cancelButtonTitle,
                                feedbackType: cancelFeedbackType,
                                action: handleCancel
                            )
                        }
                    }
                }
                .cardStyle(
                    backgroundColor: ColorConstants.surface,
                    cornerRadius: 16,
                    padding: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24),
                    shadowRadius: 6,
                    shadowY: 4,
                    shadowOpacity: 0.15
                )
                .frame(maxWidth: maxWidth)
                .padding(.horizontal, 40)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
                .zIndex(1)
                .accessibility(label: Text(title))
                .accessibility(hint: Text(message))
            }
        }
    }
    
    // MARK: - Actions
    
    /// Handles the confirm button action
    private func handleConfirm() {
        HapticManager.shared.generateFeedback(confirmFeedbackType)
        isShowing = false
        onConfirm?()
    }
    
    /// Handles the cancel button action
    private func handleCancel() {
        HapticManager.shared.generateFeedback(cancelFeedbackType)
        isShowing = false
        onCancel?()
    }
}