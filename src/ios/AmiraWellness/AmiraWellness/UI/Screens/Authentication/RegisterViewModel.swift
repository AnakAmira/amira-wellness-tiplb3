import Foundation // Latest - Access to core Foundation types and functionality
import Combine // Latest - Reactive programming for state management
import SwiftUI // Latest - For ObservableObject conformance and property wrappers

// Internal imports
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift - Provides authentication services for user registration
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift - User model for registration data
import AuthError // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift - Error types for registration operations
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift - Logging functionality with privacy considerations
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift - Access security and app-related constants

/// Represents the different states of the registration process
enum RegisterState {
    case idle
    case registering
    case success(User)
    case error(String)
}

/// Defines available language preferences for user registration
enum LanguagePreference: String, CaseIterable, Identifiable {
    case spanish = "es"
    case english = "en"

    var id: String {
        self.rawValue
    }

    var displayName: String {
        switch self {
        case .spanish:
            return "Español"
        case .english:
            return "English"
        }
    }
}

/// ViewModel that manages the registration screen state and user creation logic
class RegisterViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var name = ""
    @Published var languagePreference: LanguagePreference = .spanish
    @Published var agreeToTerms = false
    @Published var registerState: RegisterState = .idle
    @Published var errorMessage: String?

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    /// Initializes the RegisterViewModel with required services
    /// - Parameter authService: Optional AuthService instance for dependency injection. Defaults to AuthService.shared.
    init(authService: AuthService? = nil) {
        // Initialize email to empty string
        self.email = ""
        // Initialize password to empty string
        self.password = ""
        // Initialize confirmPassword to empty string
        self.confirmPassword = ""
        // Initialize name to empty string
        self.name = ""
        // Initialize languagePreference to .spanish (default language)
        self.languagePreference = .spanish
        // Initialize agreeToTerms to false
        self.agreeToTerms = false
        // Initialize registerState to .idle
        self.registerState = .idle
        // Initialize errorMessage to nil
        self.errorMessage = nil
        // Initialize authService to provided service or AuthService.shared
        self.authService = authService ?? AuthService.shared
        // Initialize cancellables to empty Set<AnyCancellable>()
        self.cancellables = Set<AnyCancellable>()

        // Set up form validation publishers for email, password, and terms agreement
        setupFormValidation()
    }

    /// Sets up form validation publishers for email, password, and terms agreement
    private func setupFormValidation() {
        // Email validation
        $email
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !validateEmail(self.email) && !self.email.isEmpty {
                    self.errorMessage = "Invalid email format"
                } else {
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)

        // Password validation
        $password
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !validatePassword(self.password) && !self.password.isEmpty {
                    self.errorMessage = self.getPasswordRequirements()
                } else {
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }

    /// Attempts to register a new user with the provided information
    func register() {
        // Validate that the form is valid using isFormValid
        guard isFormValid else {
            // If validation fails, set errorMessage and return
            Logger.shared.debug("Registration form is invalid", category: .authentication)
            return
        }

        // Set registerState to .registering
        registerState = .registering
        // Clear any previous error message
        errorMessage = nil

        // Call authService.register with email, password, and name
        authService.register(email: email, password: password, name: name) { [weak self] result in
            guard let self = self else { return }

            // Handle the result with a switch statement
            switch result {
            case .success(let user):
                // For success, set registerState to .success with the user
                Logger.shared.debug("Registration successful for user: \(user.email)", category: .authentication)
                registerState = .success(user)
            case .failure(let error):
                // For failure, set registerState to .error with appropriate message
                let errorMessage = getErrorMessage(error: error)
                Logger.shared.error("Registration failed for user: \(email) with error: \(errorMessage)", category: .authentication)
                registerState = .error(errorMessage)
                self.errorMessage = errorMessage
            }
        }
        // Log the registration attempt with privacy considerations
        Logger.shared.logUserAction("Registration attempt with email: \(email)", file: #file, line: #line, function: #function)
    }

    /// Attempts to register a new user with the provided information using async/await
    @available(iOS 15.0, *)
    func registerAsync() async {
        // Validate that the form is valid using isFormValid
        guard isFormValid else {
            // If validation fails, set errorMessage and return
            Logger.shared.debug("Registration form is invalid", category: .authentication)
            return
        }

        // Set registerState to .registering
        registerState = .registering
        // Clear any previous error message
        errorMessage = nil

        // Use do-catch block to handle async operations
        do {
            // Try to call authService.registerAsync with email, password, and name
            let user = try await authService.registerAsync(email: email, password: password, name: name)
            // If successful, set registerState to .success with the user
            Logger.shared.debug("Registration successful for user: \(email)", category: .authentication)
            registerState = .success(user)
        } catch {
            // If an error occurs, catch it and set registerState to .error with appropriate message
            let authError = error as? AuthError ?? .unknown
            let errorMessage = getErrorMessage(error: authError)
            Logger.shared.error("Registration failed for user: \(email) with error: \(errorMessage)", category: .authentication)
            registerState = .error(errorMessage)
            self.errorMessage = errorMessage
        }
        // Log the registration attempt with privacy considerations
        Logger.shared.logUserAction("Registration attempt with email: \(email)", file: #file, line: #line, function: #function)
    }

    /// Validates the email format
    func validateEmail(email: String) -> Bool {
        // Check if email is not empty
        guard !email.isEmpty else {
            return false
        }

        // Use a regular expression to validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)

        // Return true if email matches the pattern, false otherwise
        return emailTest.evaluate(with: email)
    }

    /// Validates the password meets minimum requirements
    func validatePassword(password: String) -> Bool {
        // Check if password is not empty
        guard !password.isEmpty else {
            return false
        }

        // Call authService.validatePassword to check against security requirements
        let isValid = authService.validatePassword(password: password)

        // Return the validation result
        return isValid
    }

    /// Validates that password and confirmation password match
    func validatePasswordsMatch() -> Bool {
        // Check if both password and confirmPassword are not empty
        guard !password.isEmpty && !confirmPassword.isEmpty else {
            return false
        }

        // Compare password and confirmPassword for equality
        // Return true if they match, false otherwise
        return password == confirmPassword
    }

    /// Validates the user's name
    func validateName(name: String) -> Bool {
        // Check if name is not empty
        guard !name.isEmpty else {
            return false
        }

        // Check if name length is within acceptable range
        guard name.count >= 2 && name.count <= 50 else {
            return false
        }

        // Return true if valid, false otherwise
        return true
    }

    /// Computed property that determines if the registration form is valid
    var isFormValid: Bool {
        // Check if email is valid using validateEmail
        guard validateEmail(email: email) else {
            return false
        }

        // Check if password is valid using validatePassword
        guard validatePassword(password: password) else {
            return false
        }

        // Check if passwords match using validatePasswordsMatch
        guard validatePasswordsMatch() else {
            return false
        }

        // Check if name is valid using validateName
        guard validateName(name: name) else {
            return false
        }

        // Check if user has agreed to terms
        guard agreeToTerms else {
            return false
        }

        // Return true if all validations pass, false otherwise
        return true
    }

    /// Returns a formatted string of password requirements
    func getPasswordRequirements() -> String {
        // Create a string with minimum length requirement from AppConstants.Security.passwordMinLength
        var requirements = "Password must be at least \(AppConstants.Security.passwordMinLength) characters long."

        // If AppConstants.Security.passwordRequiresUppercase is true, add uppercase requirement
        if AppConstants.Security.passwordRequiresUppercase {
            requirements += "\nMust contain at least one uppercase letter."
        }

        // If AppConstants.Security.passwordRequiresNumber is true, add number requirement
        if AppConstants.Security.passwordRequiresNumber {
            requirements += "\nMust contain at least one number."
        }

        // If AppConstants.Security.passwordRequiresSpecialCharacter is true, add special character requirement
        if AppConstants.Security.passwordRequiresSpecialCharacter {
            requirements += "\nMust contain at least one special character."
        }

        // Return the formatted requirements string
        return requirements
    }

    /// Resets the registration state to idle
    func resetState() {
        // Set registerState to .idle
        registerState = .idle
        // Clear errorMessage
        errorMessage = nil
    }

    /// Converts AuthError to user-friendly error message
    private func getErrorMessage(error: AuthError) -> String {
        // Switch on the error type to determine the appropriate message
        switch error {
        // For registrationFailed, return 'Registration failed. Please try again'
        case .registrationFailed:
            return "Registration failed. Please try again."
        // For networkError, return 'Network error. Please check your connection'
        case .networkError:
            return "Network error. Please check your connection."
        // For other errors, return a generic error message
        default:
            return "An unexpected error occurred."
        }
    }
}