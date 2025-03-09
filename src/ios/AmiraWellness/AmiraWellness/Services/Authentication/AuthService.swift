# src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import Foundation // Latest
import Combine // Latest

// Internal imports
import TokenManager // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/TokenManager.swift
import BiometricAuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/BiometricAuthService.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift
import APIError // src/ios/AmiraWellness/AmiraWellness/Models/APIError.swift
import APIResponse // src/ios/AmiraWellness/AmiraWellness/Models/APIResponse.swift
import KeychainManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/KeychainManager.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift
import ApiConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ApiConstants.swift

/// Errors that can occur during authentication operations
enum AuthError: Error {
    case invalidCredentials
    case accountDisabled
    case emailNotVerified
    case registrationFailed
    case networkError
    case logoutFailed
    case userNotFound
    case biometricAuthFailed
    case tokenError(TokenError)
    case unknown
}

/// Response structure for authentication operations
struct AuthResponse: Decodable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

/// Represents the authentication state of the user
enum AuthState {
    case authenticated(User)
    case unauthenticated
    case loading
}

/// A singleton service that handles authentication operations for the application
final class AuthService {
    /// Shared instance of the AuthService
    static let shared = AuthService()
    
    // MARK: - Private Properties
    
    private let tokenManager: TokenManager
    private let biometricAuthService: BiometricAuthService
    private let apiClient: APIClient
    private let keychainManager: KeychainManager
    private let userIdKey = AppConstants.Keychain.userId
    
    private var currentUser: User?
    private var authStateSubject = CurrentValueSubject<AuthState, Never>(.unauthenticated)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        self.tokenManager = TokenManager.shared
        self.biometricAuthService = BiometricAuthService.shared
        self.apiClient = APIClient.shared
        self.keychainManager = KeychainManager.shared
        self.currentUser = nil
        self.authStateSubject = CurrentValueSubject<AuthState, Never>(.unauthenticated)
        self.cancellables = Set<AnyCancellable>()
        
        restoreSession()
        
        Logger.shared.debug("AuthService initialized", category: .authentication)
    }
    
    // MARK: - Public Methods
    
    /// Returns a publisher that emits the current authentication state
    /// - Returns: Publisher for auth state changes
    func authStatePublisher() -> AnyPublisher<AuthState, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    /// Returns the current authentication state
    /// - Returns: Current authentication state
    func currentAuthState() -> AuthState {
        return authStateSubject.value
    }
    
    /// Checks if the user is currently authenticated
    /// - Returns: True if authenticated, false otherwise
    func isAuthenticated() -> Bool {
        if case .authenticated(_) = currentAuthState() {
            return true
        } else {
            return false
        }
    }
    
    /// Gets the currently authenticated user
    /// - Returns: Current user or nil if not authenticated
    func getCurrentUser() -> User? {
        if case .authenticated(let user) = currentAuthState() {
            return user
        } else {
            return nil
        }
    }
    
    /// Authenticates a user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - rememberCredentials: Whether to store credentials for biometric login
    ///   - completion: Completion handler with result containing user or error
    func login(email: String, password: String, rememberCredentials: Bool, completion: @escaping (Result<User, AuthError>) -> Void) {
        authStateSubject.send(.loading)
        
        let loginRequest = APIRouter.login(email: email, password: password)
        
        apiClient.request(endpoint: loginRequest) { [weak self] (result: Result<AuthResponse, APIError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let authResponse):
                let saveTokensResult = self.tokenManager.saveTokens(accessToken: authResponse.accessToken, refreshToken: authResponse.refreshToken)
                
                switch saveTokensResult {
                case .success:
                    // Save userId to keychain
                    let _ = self.keychainManager.saveString(string: authResponse.user.id.uuidString, key: self.userIdKey)
                    
                    if rememberCredentials {
                        self.biometricAuthService.storeCredentialsWithBiometrics(email: email, password: password) { _ in }
                    }
                    
                    self.currentUser = authResponse.user
                    self.authStateSubject.send(.authenticated(authResponse.user))
                    completion(.success(authResponse.user))
                    Logger.shared.info("User logged in successfully", category: .authentication)
                case .failure(let error):
                    self.authStateSubject.send(.unauthenticated)
                    completion(.failure(.tokenError(error)))
                    Logger.shared.error("Failed to save tokens: \(error)", category: .authentication)
                }
                
            case .failure(let error):
                self.authStateSubject.send(.unauthenticated)
                let authError = self.handleAuthError(error: error)
                completion(.failure(authError))
                Logger.shared.error("Login failed: \(authError)", category: .authentication)
            }
        }
    }
    
    /// Authenticates a user with email and password using async/await
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - rememberCredentials: Whether to store credentials for biometric login
    /// - Returns: Authenticated user or throws an error
    @available(iOS 15.0, *)
    func loginAsync(email: String, password: String, rememberCredentials: Bool) async throws -> User {
        authStateSubject.send(.loading)
        
        let loginRequest = APIRouter.login(email: email, password: password)
        
        do {
            let authResponse: AuthResponse = try await apiClient.requestAsync(endpoint: loginRequest)
            
            let saveTokensResult = self.tokenManager.saveTokens(accessToken: authResponse.accessToken, refreshToken: authResponse.refreshToken)
            
            switch saveTokensResult {
            case .success:
                // Save userId to keychain
                let _ = self.keychainManager.saveString(string: authResponse.user.id.uuidString, key: self.userIdKey)
                
                if rememberCredentials {
                    try await self.biometricAuthService.storeCredentialsWithBiometricsAsync(email: email, password: password)
                }
                
                self.currentUser = authResponse.user
                self.authStateSubject.send(.authenticated(authResponse.user))
                Logger.shared.info("User logged in successfully", category: .authentication)
                return authResponse.user
            case .failure(let error):
                self.authStateSubject.send(.unauthenticated)
                throw AuthError.tokenError(error)
            }
        } catch {
            self.authStateSubject.send(.unauthenticated)
            let authError = (error as? APIError).map(self.handleAuthError) ?? .unknown
            Logger.shared.error("Login failed: \(authError)", category: .authentication)
            throw authError
        }
    }
    
    /// Authenticates a user using stored biometric credentials
    /// - Parameter completion: Completion handler with result containing user or error
    func loginWithBiometrics(completion: @escaping (Result<User, AuthError>) -> Void) {
        guard biometricAuthService.isBiometricAuthEnabled() else {
            completion(.failure(.biometricAuthFailed))
            return
        }
        
        authStateSubject.send(.loading)
        
        biometricAuthService.retrieveCredentialsWithBiometrics { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let credentials):
                self.login(email: credentials.email, password: credentials.password, rememberCredentials: true, completion: completion)
            case .failure(let error):
                self.authStateSubject.send(.unauthenticated)
                completion(.failure(.biometricAuthFailed))
                Logger.shared.error("Biometric login failed: \(error)", category: .authentication)
            }
        }
    }
    
    /// Authenticates a user using stored biometric credentials with async/await
    /// - Returns: Authenticated user or throws an error
    @available(iOS 15.0, *)
    func loginWithBiometricsAsync() async throws -> User {
        guard biometricAuthService.isBiometricAuthEnabled() else {
            throw AuthError.biometricAuthFailed
        }
        
        authStateSubject.send(.loading)
        
        do {
            let credentials = try await biometricAuthService.retrieveCredentialsWithBiometricsAsync()
            return try await loginAsync(email: credentials.email, password: credentials.password, rememberCredentials: true)
        } catch {
            self.authStateSubject.send(.unauthenticated)
            Logger.shared.error("Biometric login failed: \(error)", category: .authentication)
            throw AuthError.biometricAuthFailed
        }
    }
    
    /// Registers a new user with email, password, and name
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - name: User's full name
    ///   - completion: Completion handler with result containing user or error
    func register(email: String, password: String, name: String, completion: @escaping (Result<User, AuthError>) -> Void) {
        authStateSubject.send(.loading)
        
        let registerRequest = APIRouter.register(email: email, password: password, name: name)
        
        apiClient.request(endpoint: registerRequest) { [weak self] (result: Result<AuthResponse, APIError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let authResponse):
                let saveTokensResult = self.tokenManager.saveTokens(accessToken: authResponse.accessToken, refreshToken: authResponse.refreshToken)
                
                switch saveTokensResult {
                case .success:
                    // Save userId to keychain
                    let _ = self.keychainManager.saveString(string: authResponse.user.id.uuidString, key: self.userIdKey)
                    
                    self.currentUser = authResponse.user
                    self.authStateSubject.send(.authenticated(authResponse.user))
                    completion(.success(authResponse.user))
                    Logger.shared.info("User registered successfully", category: .authentication)
                case .failure(let error):
                    self.authStateSubject.send(.unauthenticated)
                    completion(.failure(.tokenError(error)))
                    Logger.shared.error("Failed to save tokens: \(error)", category: .authentication)
                }
                
            case .failure(let error):
                self.authStateSubject.send(.unauthenticated)
                let authError = self.handleAuthError(error: error)
                completion(.failure(authError))
                Logger.shared.error("Registration failed: \(authError)", category: .authentication)
            }
        }
    }
    
    /// Registers a new user with email, password, and name using async/await
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - name: User's full name
    /// - Returns: Registered user or throws an error
    @available(iOS 15.0, *)
    func registerAsync(email: String, password: String, name: String) async throws -> User {
        authStateSubject.send(.loading)
        
        let registerRequest = APIRouter.register(email: email, password: password, name: name)
        
        do {
            let authResponse: AuthResponse = try await apiClient.requestAsync(endpoint: registerRequest)
            
            let saveTokensResult = self.tokenManager.saveTokens(accessToken: authResponse.accessToken, refreshToken: authResponse.refreshToken)
            
            switch saveTokensResult {
            case .success:
                // Save userId to keychain
                let _ = self.keychainManager.saveString(string: authResponse.user.id.uuidString, key: self.userIdKey)
                
                self.currentUser = authResponse.user
                self.authStateSubject.send(.authenticated(authResponse.user))
                Logger.shared.info("User registered successfully", category: .authentication)
                return authResponse.user
            case .failure(let error):
                self.authStateSubject.send(.unauthenticated)
                throw AuthError.tokenError(error)
            }
        } catch {
            self.authStateSubject.send(.unauthenticated)
            let authError = (error as? APIError).map(self.handleAuthError) ?? .unknown
            Logger.shared.error("Registration failed: \(authError)", category: .authentication)
            throw authError
        }
    }
    
    /// Logs out the current user and clears authentication data
    /// - Parameter completion: Completion handler with result indicating success or error
    func logout(completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard isAuthenticated() else {
            completion(.success(()))
            return
        }
        
        let logoutRequest = APIRouter.logout
        
        apiClient.requestEmpty(endpoint: logoutRequest) { [weak self] (result: Result<Void, APIError>) in
            guard let self = self else { return }
            
            // Clear local authentication data regardless of API result
            let clearTokensResult = self.tokenManager.clearTokens()
            
            switch clearTokensResult {
            case .success:
                let _ = self.keychainManager.delete(key: self.userIdKey)
                self.currentUser = nil
                self.authStateSubject.send(.unauthenticated)
                completion(.success(()))
                Logger.shared.info("User logged out successfully", category: .authentication)
            case .failure(let error):
                Logger.shared.error("Failed to clear tokens: \(error)", category: .authentication)
                completion(.failure(.tokenError(error)))
            }
        }
    }
    
    /// Logs out the current user and clears authentication data using async/await
    @available(iOS 15.0, *)
    func logoutAsync() async throws {
        guard isAuthenticated() else {
            return
        }
        
        let logoutRequest = APIRouter.logout
        
        do {
            try await apiClient.requestEmptyAsync(endpoint: logoutRequest)
            
            let clearTokensResult = self.tokenManager.clearTokens()
            
            switch clearTokensResult {
            case .success:
                let _ = self.keychainManager.delete(key: self.userIdKey)
                self.currentUser = nil
                self.authStateSubject.send(.unauthenticated)
                Logger.shared.info("User logged out successfully", category: .authentication)
            case .failure(let error):
                throw AuthError.tokenError(error)
            }
        } catch {
            throw AuthError.logoutFailed
        }
    }
    
    /// Attempts to restore a previous authentication session
    func restoreSession() {
        guard tokenManager.hasValidTokens() else {
            authStateSubject.send(.unauthenticated)
            return
        }
        
        authStateSubject.send(.loading)
        
        getUserProfile { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                self.authStateSubject.send(.authenticated(user))
                Logger.shared.info("Session restored successfully", category: .authentication)
            case .failure:
                let _ = self.tokenManager.clearTokens()
                self.authStateSubject.send(.unauthenticated)
                Logger.shared.info("Session restore failed, clearing tokens", category: .authentication)
            }
        }
    }
    
    /// Attempts to restore a previous authentication session using async/await
    @available(iOS 15.0, *)
    func restoreSessionAsync() async throws -> User? {
        guard tokenManager.hasValidTokens() else {
            authStateSubject.send(.unauthenticated)
            return nil
        }
        
        authStateSubject.send(.loading)
        
        do {
            let user = try await getUserProfileAsync()
            authStateSubject.send(.authenticated(user))
            Logger.shared.info("Session restored successfully", category: .authentication)
            return user
        } catch {
            let _ = self.tokenManager.clearTokens()
            authStateSubject.send(.unauthenticated)
            Logger.shared.info("Session restore failed, clearing tokens", category: .authentication)
            return nil
        }
    }
    
    /// Fetches the current user's profile from the API
    /// - Parameter completion: Completion handler with result containing user or error
    func getUserProfile(completion: @escaping (Result<User, AuthError>) -> Void) {
        let profileRequest = APIRouter.getUserProfile
        
        apiClient.request(endpoint: profileRequest) { [weak self] (result: Result<User, APIError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                self.currentUser = user
                completion(.success(user))
                Logger.shared.info("User profile fetched successfully", category: .authentication)
            case .failure(let error):
                let authError = self.handleAuthError(error: error)
                completion(.failure(authError))
                Logger.shared.error("Failed to fetch user profile: \(authError)", category: .authentication)
            }
        }
    }
    
    /// Fetches the current user's profile from the API using async/await
    @available(iOS 15.0, *)
    func getUserProfileAsync() async throws -> User {
        let profileRequest = APIRouter.getUserProfile
        
        do {
            let user: User = try await apiClient.requestAsync(endpoint: profileRequest)
            self.currentUser = user
            Logger.shared.info("User profile fetched successfully", category: .authentication)
            return user
        } catch {
            let authError = (error as? APIError).map(self.handleAuthError) ?? .unknown
            Logger.shared.error("Failed to fetch user profile: \(authError)", category: .authentication)
            throw authError
        }
    }
    
    /// Enables or disables biometric login for the current user
    /// - Parameters:
    ///   - enable: Whether to enable or disable biometric login
    ///   - email: User's email address (required when enabling)
    ///   - password: User's password (required when enabling)
    ///   - completion: Completion handler with result indicating success or error
    func enableBiometricLogin(enable: Bool, email: String? = nil, password: String? = nil, completion: @escaping (Result<Void, AuthError>) -> Void) {
        if enable && (email == nil || password == nil) {
            completion(.failure(.invalidCredentials))
            return
        }
        
        if enable {
            biometricAuthService.storeCredentialsWithBiometrics(email: email!, password: password!) { result in
                switch result {
                case .success:
                    completion(.success(()))
                    Logger.shared.info("Biometric login enabled successfully", category: .authentication)
                case .failure(let error):
                    completion(.failure(.biometricAuthFailed))
                    Logger.shared.error("Failed to enable biometric login: \(error)", category: .authentication)
                }
            }
        } else {
            biometricAuthService.clearStoredCredentials() { result in
                switch result {
                case .success:
                    completion(.success(()))
                    Logger.shared.info("Biometric login disabled successfully", category: .authentication)
                case .failure(let error):
                    completion(.failure(.biometricAuthFailed))
                    Logger.shared.error("Failed to disable biometric login: \(error)", category: .authentication)
                }
            }
        }
    }
    
    /// Enables or disables biometric login for the current user using async/await
    /// - Parameters:
    ///   - enable: Whether to enable or disable biometric login
    ///   - email: User's email address (required when enabling)
    ///   - password: User's password (required when enabling)
    @available(iOS 15.0, *)
    func enableBiometricLoginAsync(enable: Bool, email: String? = nil, password: String? = nil) async throws {
        if enable && (email == nil || password == nil) {
            throw AuthError.invalidCredentials
        }
        
        if enable {
            do {
                try await biometricAuthService.storeCredentialsWithBiometricsAsync(email: email!, password: password!)
                Logger.shared.info("Biometric login enabled successfully", category: .authentication)
            } catch {
                Logger.shared.error("Failed to enable biometric login: \(error)", category: .authentication)
                throw AuthError.biometricAuthFailed
            }
        } else {
            do {
                try await biometricAuthService.clearStoredCredentialsAsync()
                Logger.shared.info("Biometric login disabled successfully", category: .authentication)
            } catch {
                Logger.shared.error("Failed to disable biometric login: \(error)", category: .authentication)
                throw AuthError.biometricAuthFailed
            }
        }
    }
    
    /// Checks if biometric login is available on the device
    /// - Returns: True if biometric login is available
    func isBiometricLoginAvailable() -> Bool {
        return biometricAuthService.isBiometricAuthAvailable()
    }
    
    /// Checks if biometric login is enabled for the current user
    /// - Returns: True if biometric login is enabled
    func isBiometricLoginEnabled() -> Bool {
        return biometricAuthService.isBiometricAuthEnabled()
    }
    
    /// Validates a password against security requirements
    /// - Parameter password: The password to validate
    /// - Returns: True if password meets requirements
    func validatePassword(password: String) -> Bool {
        guard password.count >= AppConstants.Security.passwordMinLength else {
            return false
        }
        
        return true // Add more validation rules as needed
    }
    
    // MARK: - Private Methods
    
    /// Converts API errors to appropriate AuthError types
    /// - Parameter error: The APIError to convert
    /// - Returns: Appropriate AuthError based on the API error
    private func handleAuthError(error: APIError) -> AuthError {
        switch error {
        case .authenticationError(let code, _):
            if code == ApiConstants.ErrorCodes.invalidCredentials {
                return .invalidCredentials
            } else {
                return .authenticationError(code: code, message: "Authentication failed")
            }
        case .networkError:
            return .networkError
        case .resourceNotFound:
            return .userNotFound
        default:
            return .unknown
        }
    }
}