import SwiftUI // Latest - Framework for building the user interface
import Combine // Latest - Reactive programming for handling state changes

// Internal imports
import ForgotPasswordViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Authentication/ForgotPasswordViewModel.swift - Provides the business logic and state management for the forgot password screen
import CustomTextField // src/ios/AmiraWellness/AmiraWellness/UI/Components/Inputs/CustomTextField.swift - Provides a styled text field for email input
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift - Provides a styled primary button for the reset password action
import SecondaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/SecondaryButton.swift - Provides a styled secondary button for the back to login action
import SuccessView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/SuccessView.swift - Displays success feedback when password reset email is sent
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift - Provides consistent colors for the UI elements

/// A view that allows users to request a password reset by entering their email address
struct ForgotPasswordView: View {
    // MARK: - Properties

    /// ViewModel for managing the forgot password logic and state
    @StateObject private var viewModel: ForgotPasswordViewModel

    /// Environment variable for presentation mode to dismiss the view
    @Environment(\.presentationMode) var presentationMode

    /// Closure to navigate to the login screen
    var onNavigateToLogin: (() -> Void)?

    /// Closure to navigate back
    var onGoBack: (() -> Void)?

    // MARK: - Initialization

    /// Initializes the ForgotPasswordView with dependencies
    /// - Parameters:
    ///   - viewModel: Optional ForgotPasswordViewModel instance for dependency injection (for testing purposes)
    ///   - onNavigateToLogin: Optional closure to navigate to the login screen
    ///   - onGoBack: Optional closure to navigate back
    init(viewModel: ForgotPasswordViewModel? = nil, onNavigateToLogin: (() -> Void)? = nil, onGoBack: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? ForgotPasswordViewModel())
        self.onNavigateToLogin = onNavigateToLogin
        self.onGoBack = onGoBack
    }

    // MARK: - Body

    /// Builds the forgot password view with form and success state
    /// - Returns: The composed view
    var body: some View {
        ZStack {
            // Show success view if password reset email was sent successfully
            if viewModel.isSuccess {
                successView()
            } else {
                // Show password reset form
                formView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the view takes up the entire screen
        .background(ColorConstants.background) // Apply background color
        .edgesIgnoringSafeArea(.all) // Ignore safe area to extend background to edges
    }

    // MARK: - Subviews

    /// Builds the password reset form view
    /// - Returns: The form view
    @ViewBuilder
    private func formView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                onGoBack?()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(ColorConstants.textPrimary)
            }
            .padding(.bottom, 10)

            // Title and description
            Text("¿Olvidaste tu contraseña?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Ingresa tu correo electrónico y te enviaremos un enlace para restablecerla.")
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Email input field
            CustomTextField(
                title: "Correo electrónico",
                text: $viewModel.email,
                placeholder: "tu_correo@ejemplo.com",
                errorMessage: viewModel.errorMessage,
                keyboardType: .emailAddress,
                autocapitalizationType: .none,
                autocorrectionType: .no
            )

            // Submit button
            PrimaryButton(
                title: "Restablecer contraseña",
                isEnabled: viewModel.isEmailValid && !viewModel.isLoading,
                isLoading: viewModel.isLoading
            ) {
                viewModel.resetPassword()
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
    }

    /// Builds the success view shown after password reset request is sent
    /// - Returns: The success view
    @ViewBuilder
    private func successView() -> some View {
        SuccessView(
            title: "¡Correo electrónico enviado!",
            message: "Revisa tu correo electrónico y sigue las instrucciones para restablecer tu contraseña.",
            buttonTitle: "Volver a iniciar sesión"
        ) {
            onNavigateToLogin?()
        }
    }
}