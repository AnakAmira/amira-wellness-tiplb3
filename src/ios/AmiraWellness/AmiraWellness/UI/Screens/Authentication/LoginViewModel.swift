import Foundation // Latest
import Combine // Latest
import SwiftUI // Latest

// Internal imports
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import BiometricAuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/BiometricAuthService.swift
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift
import AuthError // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// Enum representing the different states of the login process
enum LoginState {
    case idle
    case authenticating
    case success(User)
    case error(String)
}

/// ViewModel that manages the login screen state and authentication logic
@MainActor
class LoginViewModel: ObservableObject {
    /// Published property for the email input field
    @Published var email = ""
    
    /// Published property for the password input field
    @Published var password = ""
    
    /// Published property for the remember credentials toggle
    @Published var rememberCredentials = false
    
    /// Published property for the login state
    @Published var loginState: LoginState = .idle
    
    /// Published property for the error message
    @Published var errorMessage: String?
    
    /// Private property for the authentication service
    private let authService: AuthService
    
    /// Private property for the biometric authentication service
    private let biometricService: BiometricAuthService
    
    /// Private property for storing cancellable Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Initializes the LoginViewModel with required services
    /// - Parameters:
    ///   - authService: Optional AuthService instance for dependency injection
    ///   - biometricService: Optional BiometricAuthService instance for dependency injection
    init(authService: AuthService? = nil, biometricService: BiometricAuthService? = nil) {
        // Initialize email to empty string
        self.email = ""
        
        // Initialize password to empty string
        self.password = ""
        
        // Initialize rememberCredentials to false
        self.rememberCredentials = false
        
        // Initialize loginState to .idle
        self.loginState = .idle
        
        // Initialize errorMessage to nil
        self.errorMessage = nil
        
        // Initialize authService to provided service or AuthService.shared
        self.authService = authService ?? AuthService.shared
        
        // Initialize biometricService to provided service or BiometricAuthService.shared
        self.biometricService = biometricService ?? BiometricAuthService.shared
        
        // Initialize cancellables to empty Set<AnyCancellable>()
        self.cancellables = Set<AnyCancellable>()
        
        // Set up email and password validation publishers
        setupValidationPublishers()
        
        // Check if biometric login is available and enabled
        Logger.shared.debug("LoginViewModel initialized", category: .authentication)
    }
    
    /// Sets up email and password validation publishers
    private func setupValidationPublishers() {
        // Email validation publisher
        $email
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.errorMessage = nil // Clear error message on email change
            }
            .store(in: &cancellables)
        
        // Password validation publisher
        $password
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.errorMessage = nil // Clear error message on password change
            }
            .store(in: &cancellables)
    }
    
    /// Attempts to authenticate the user with the provided email and password
    func login() {
        // Validate that email and password are not empty
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        // Set loginState to .authenticating
        loginState = .authenticating
        
        // Clear any previous error message
        errorMessage = nil
        
        // Call authService.login with email, password, and rememberCredentials
        authService.login(email: email, password: password, rememberCredentials: rememberCredentials) { [weak self] result in
            guard let self = self else { return }
            
            // Handle the result with a switch statement
            switch result {
            case .success(let user):
                // For success, set loginState to .success with the user
                loginState = .success(user)
                Logger.shared.logUserAction("User logged in successfully with email: \(email)")
            case .failure(let error):
                // For failure, set loginState to .error with appropriate message
                loginState = .error(getErrorMessage(error: error))
                Logger.shared.error("Login failed with error: \(error)", category: .authentication)
            }
        }
    }
    
    /// Attempts to authenticate the user with the provided email and password using async/await
    @available(iOS 15.0, *)
    func loginAsync() async {
        // Validate that email and password are not empty
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        // Set loginState to .authenticating
        loginState = .authenticating
        
        // Clear any previous error message
        errorMessage = nil
        
        do {
            // Try to call authService.loginAsync with email, password, and rememberCredentials
            let user = try await authService.loginAsync(email: email, password: password, rememberCredentials: rememberCredentials)
            
            // If successful, set loginState to .success with the user
            loginState = .success(user)
            Logger.shared.logUserAction("User logged in successfully with email: \(email)")
        } catch {
            // If an error occurs, catch it and set loginState to .error with appropriate message
            loginState = .error(getErrorMessage(error: error as? AuthError ?? .unknown))
            Logger.shared.error("Login failed with error: \(error)", category: .authentication)
        }
    }
    
    /// Attempts to authenticate the user using stored biometric credentials
    func loginWithBiometrics() {
        // Check if biometric login is available and enabled
        guard showBiometricLogin else {
            errorMessage = "Biometric login is not available"
            return
        }
        
        // Set loginState to .authenticating
        loginState = .authenticating
        
        // Clear any previous error message
        errorMessage = nil
        
        // Call authService.loginWithBiometrics()
        authService.loginWithBiometrics { [weak self] result in
            guard let self = self else { return }
            
            // Handle the result with a switch statement
            switch result {
            case .success(let user):
                // For success, set loginState to .success with the user
                loginState = .success(user)
                Logger.shared.logUserAction("User logged in successfully with biometrics")
            case .failure(let error):
                // For failure, set loginState to .error with appropriate message
                loginState = .error(getErrorMessage(error: error))
                Logger.shared.error("Biometric login failed with error: \(error)", category: .authentication)
            }
        }
    }
    
    /// Attempts to authenticate the user using stored biometric credentials with async/await
    @available(iOS 15.0, *)
    func loginWithBiometricsAsync() async {
        // Check if biometric login is available and enabled
        guard showBiometricLogin else {
            errorMessage = "Biometric login is not available"
            return
        }
        
        // Set loginState to .authenticating
        loginState = .authenticating
        
        // Clear any previous error message
        errorMessage = nil
        
        do {
            // Try to call authService.loginWithBiometricsAsync()
            let user = try await authService.loginWithBiometricsAsync()
            
            // If successful, set loginState to .success with the user
            loginState = .success(user)
            Logger.shared.logUserAction("User logged in successfully with biometrics")
        } catch {
            // If an error occurs, catch it and set loginState to .error with appropriate message
            loginState = .error(getErrorMessage(error: error as? AuthError ?? .biometricAuthFailed))
            Logger.shared.error("Biometric login failed with error: \(error)", category: .authentication)
        }
    }
    
    /// Validates the email format
    /// - Parameter email: The email to validate
    /// - Returns: True if email is valid, false otherwise
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
    /// - Parameter password: The password to validate
    /// - Returns: True if password is valid, false otherwise
    func validatePassword(password: String) -> Bool {
        // Check if password is not empty
        guard !password.isEmpty else {
            return false
        }
        
        // Call authService.validatePassword to check against security requirements
        return authService.validatePassword(password: password)
    }
    
    /// Computed property that determines if the login form is valid
    var isFormValid: Bool {
        // Check if email is valid using validateEmail
        let isEmailValid = validateEmail(email: email)
        
        // Check if password is valid using validatePassword
        let isPasswordValid = validatePassword(password: password)
        
        // Return true if both are valid, false otherwise
        return isEmailValid && isPasswordValid
    }
    
    /// Computed property that determines if biometric login option should be shown
    var showBiometricLogin: Bool {
        // Check if biometric authentication is available using authService.isBiometricLoginAvailable()
        let isBiometricAvailable = biometricService.isBiometricAuthAvailable()
        
        // Check if biometric login is enabled using authService.isBiometricLoginEnabled()
        let isBiometricEnabled = biometricService.isBiometricAuthEnabled()
        
        // Return true if both conditions are met, false otherwise
        return isBiometricAvailable && isBiometricEnabled
    }
    
    /// Resets the login state to idle
    func resetState() {
        // Set loginState to .idle
        loginState = .idle
        
        // Clear errorMessage
        errorMessage = nil
    }
    
    /// Converts AuthError to user-friendly error message
    /// - Parameter error: The AuthError to convert
    /// - Returns: Localized error message
    private func getErrorMessage(error: AuthError) -> String {
        switch error {
        case .invalidCredentials:
            return "Invalid email or password"
        case .accountDisabled:
            return "Your account has been disabled"
        case .emailNotVerified:
            return "Please verify your email address"
        case .networkError:
            return "Network error. Please try again"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        default:
            return "An unexpected error occurred"
        }
    }
}