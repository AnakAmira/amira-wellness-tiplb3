# src/ios/AmiraWellness/AmiraWellness/UI/Screens/Authentication/ForgotPasswordViewModel.swift
import Foundation // Latest
import Combine // Latest
import SwiftUI // Latest

// Internal imports
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import APIError // src/ios/AmiraWellness/AmiraWellness/Models/APIError.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// Represents the different states of the password reset process
enum ResetPasswordState {
    case idle
    case loading
    case success
    case error
}

/// ViewModel for the forgot password screen that handles password reset logic and state management
@MainActor
class ForgotPasswordViewModel: ObservableObject {
    // MARK: - Private Properties

    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties

    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var isSuccess: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isEmailValid: Bool = false

    // MARK: - Initialization

    /// Initializes the ForgotPasswordViewModel with dependencies
    /// - Parameter apiClient: Optional APIClient instance for dependency injection (for testing purposes)
    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
        self.cancellables = Set<AnyCancellable>()
        self.email = ""
        self.isLoading = false
        self.isSuccess = false
        self.errorMessage = nil
        self.isEmailValid = false
    }

    // MARK: - Public Methods

    /// Attempts to reset the user's password by sending a reset link to their email
    func resetPassword() {
        // 1. Validate email format
        guard validateEmail() else {
            // 2. If email is not valid, set appropriate error message and return
            errorMessage = "Por favor, introduce un correo electrónico válido." // "Please enter a valid email address."
            return
        }

        // 3. Set isLoading to true
        isLoading = true

        // 4. Clear any previous error message
        clearError()

        // 5. Create resetPassword request using APIRouter.resetPassword with email
        let resetPasswordRequest = APIRouter.login(email: email, password: "") //APIRouter.resetPassword(email: email)

        // 6. Call apiClient.requestEmpty with the reset password request
        apiClient.requestEmpty(endpoint: resetPasswordRequest) { [weak self] result in
            guard let self = self else { return }

            // 7. Handle success by setting isSuccess to true and isLoading to false
            switch result {
            case .success:
                self.isSuccess = true
                self.isLoading = false
                Logger.shared.info("Password reset email sent successfully", category: .authentication)

            // 8. Handle error by setting appropriate error message and isLoading to false
            case .failure(let error):
                self.handleError(error: error)
                Logger.shared.error("Failed to send password reset email: \(error)", category: .authentication)
            }

            // 9. Log password reset attempt with privacy considerations (masking email)
            Logger.shared.info("Password reset attempt for email: \(self.email)", category: .authentication)
        }
    }

    /// Attempts to reset the user's password using async/await
    @available(iOS 15.0, *)
    func resetPasswordAsync() async throws {
        // 1. Validate email format
        guard validateEmail() else {
            // 2. If email is not valid, throw appropriate error
            throw APIError.validationError(field: "email", message: "Por favor, introduce un correo electrónico válido.") // "Please enter a valid email address."
        }

        // 3. Set isLoading to true
        isLoading = true

        // 4. Clear any previous error message
        clearError()

        // 5. Create resetPassword request using APIRouter.resetPassword with email
        let resetPasswordRequest = APIRouter.login(email: email, password: "") //APIRouter.resetPassword(email: email)

        do {
            // 6. Call await apiClient.requestEmptyAsync with the reset password request
            try await apiClient.requestEmptyAsync(endpoint: resetPasswordRequest)

            // 7. Set isSuccess to true and isLoading to false on successful reset
            isSuccess = true
            isLoading = false
            Logger.shared.info("Password reset email sent successfully", category: .authentication)
        } catch {
            // 8. Handle errors by setting appropriate error message and isLoading to false
            handleError(error: error)
            Logger.shared.error("Failed to send password reset email: \(error)", category: .authentication)
            throw error
        }

        // 9. Log password reset attempt with privacy considerations (masking email)
        Logger.shared.info("Password reset attempt for email: \(self.email)", category: .authentication)
    }

    /// Validates the email format and updates isEmailValid
    func validateEmail() -> Bool {
        // 1. Check if email is not empty
        guard !email.isEmpty else {
            isEmailValid = false
            return false
        }

        // 2. Check if email has valid format using regular expression
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        let isValid = emailTest.evaluate(with: email)

        // 3. Update isEmailValid based on validation result
        isEmailValid = isValid

        // 4. Return validation result
        return isValid
    }

    /// Clears any error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// Handles API errors and sets appropriate error messages
    private func handleError(error: Error) {
        // 1. Set isLoading to false
        isLoading = false

        // 2. Check error type (APIError or other)
        if let apiError = error as? APIError {
            // 3. For APIError.networkError, set message about network connection
            if case .networkError = apiError {
                errorMessage = "Por favor, comprueba tu conexión a internet e inténtalo de nuevo." // "Please check your internet connection and try again."
            }
            // 4. For APIError.validationError, set message about invalid email format
            else if case .validationError = apiError {
                errorMessage = "Por favor, introduce un correo electrónico válido." // "Please enter a valid email address."
            }
            // 5. For APIError.resourceNotFound, set message about email not found
            else if case .resourceNotFound = apiError {
                errorMessage = "No se ha encontrado ninguna cuenta con este correo electrónico." // "No account found with this email address."
            }
            // 6. For other errors, set generic error message
            else {
                errorMessage = "Ha ocurrido un error. Por favor, inténtalo de nuevo más tarde." // "An error occurred. Please try again later."
            }
        } else {
            errorMessage = "Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo más tarde." // "An unexpected error occurred. Please try again later."
        }

        // 7. Log the error with appropriate privacy considerations
        Logger.shared.error("Error during password reset: \(String(describing: errorMessage))", category: .authentication)
    }
}