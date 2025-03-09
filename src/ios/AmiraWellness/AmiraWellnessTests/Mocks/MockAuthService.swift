import Foundation // Latest
import Combine // Latest

// Internal imports
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift

/// A mock implementation of the AuthService for unit testing
class MockAuthService: AuthService {
    
    static let shared = MockAuthService()
    
    private var authStateSubject = CurrentValueSubject<AuthState, Never>(.unauthenticated)
    private var currentUser: User?
    
    var loginResult: Result<User, AuthError> = .failure(.unknown)
    var loginAsyncResult: Result<User, AuthError> = .failure(.unknown)
    var loginWithBiometricsResult: Result<User, AuthError> = .failure(.unknown)
    var loginWithBiometricsAsyncResult: Result<User, AuthError> = .failure(.unknown)
    var registerResult: Result<User, AuthError> = .failure(.unknown)
    var registerAsyncResult: Result<User, AuthError> = .failure(.unknown)
    var logoutResult: Result<Void, AuthError> = .failure(.unknown)
    var logoutAsyncResult: Result<Void, AuthError> = .failure(.unknown)
    var getUserProfileResult: Result<User, AuthError> = .failure(.unknown)
    var getUserProfileAsyncResult: Result<User, AuthError> = .failure(.unknown)
    var enableBiometricLoginResult: Result<Void, AuthError> = .failure(.unknown)
    var enableBiometricLoginAsyncResult: Result<Void, AuthError> = .failure(.unknown)
    var isBiometricLoginAvailableResult: Bool = false
    var isBiometricLoginEnabledResult: Bool = false
    var validatePasswordResult: Bool = false
    
    var loginCalled: Bool = false
    var loginAsyncCalled: Bool = false
    var loginWithBiometricsCalled: Bool = false
    var loginWithBiometricsAsyncCalled: Bool = false
    var registerCalled: Bool = false
    var registerAsyncCalled: Bool = false
    var logoutCalled: Bool = false
    var logoutAsyncCalled: Bool = false
    var getUserProfileCalled: Bool = false
    var getUserProfileAsyncCalled: Bool = false
    var enableBiometricLoginCalled: Bool = false
    var enableBiometricLoginAsyncCalled: Bool = false
    var validatePasswordCalled: Bool = false
    
    var lastLoginEmail: String?
    var lastLoginPassword: String?
    var lastRegisterEmail: String?
    var lastRegisterPassword: String?
    var lastRegisterName: String?
    
    private override init() {
        super.init()
        reset()
    }
    
    /// Resets the mock to its initial state
    func reset() {
        authStateSubject = CurrentValueSubject<AuthState, Never>(.unauthenticated)
        currentUser = nil
        loginResult = .failure(.unknown)
        loginAsyncResult = .failure(.unknown)
        loginWithBiometricsResult = .failure(.unknown)
        loginWithBiometricsAsyncResult = .failure(.unknown)
        registerResult = .failure(.unknown)
        registerAsyncResult = .failure(.unknown)
        logoutResult = .failure(.unknown)
        logoutAsyncResult = .failure(.unknown)
        getUserProfileResult = .failure(.unknown)
        getUserProfileAsyncResult = .failure(.unknown)
        enableBiometricLoginResult = .failure(.unknown)
        enableBiometricLoginAsyncResult = .failure(.unknown)
        isBiometricLoginAvailableResult = false
        isBiometricLoginEnabledResult = false
        validatePasswordResult = false
        loginCalled = false
        loginAsyncCalled = false
        loginWithBiometricsCalled = false
        loginWithBiometricsAsyncCalled = false
        registerCalled = false
        registerAsyncCalled = false
        logoutCalled = false
        logoutAsyncCalled = false
        getUserProfileCalled = false
        getUserProfileAsyncCalled = false
        enableBiometricLoginCalled = false
        enableBiometricLoginAsyncCalled = false
        validatePasswordCalled = false
        lastLoginEmail = nil
        lastLoginPassword = nil
        lastRegisterEmail = nil
        lastRegisterPassword = nil
        lastRegisterName = nil
    }
    
    /// Sets the current authentication state
    /// - Parameter state: The new authentication state
    func setAuthState(state: AuthState) {
        authStateSubject.send(state)
        if case .authenticated(let user) = state {
            currentUser = user
        }
    }
    
    /// Returns a publisher that emits the current authentication state
    /// - Returns: Publisher for auth state changes
    override func authStatePublisher() -> AnyPublisher<AuthState, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    /// Returns the current authentication state
    /// - Returns: Current authentication state
    override func currentAuthState() -> AuthState {
        return authStateSubject.value
    }
    
    /// Checks if the user is currently authenticated
    /// - Returns: True if authenticated, false otherwise
    override func isAuthenticated() -> Bool {
        if case .authenticated(_) = currentAuthState() {
            return true
        } else {
            return false
        }
    }
    
    /// Gets the currently authenticated user
    /// - Returns: Current user or nil if not authenticated
    override func getCurrentUser() -> User? {
        return currentUser
    }
    
    /// Mock implementation of login method
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - rememberCredentials: Whether to store credentials for biometric login
    ///   - completion: Completion handler with result containing user or error
    override func login(email: String, password: String, rememberCredentials: Bool, completion: @escaping (Result<User, AuthError>) -> Void) {
        loginCalled = true
        lastLoginEmail = email
        lastLoginPassword = password
        authStateSubject.send(.loading)
        completion(loginResult)
        if case .success(let user) = loginResult {
            authStateSubject.send(.authenticated(user))
            currentUser = user
        }
    }
    
    /// Mock implementation of loginAsync method
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - rememberCredentials: Whether to store credentials for biometric login
    /// - Returns: Authenticated user or throws an error
    @available(iOS 15.0, *)
    override func loginAsync(email: String, password: String, rememberCredentials: Bool) async throws -> User {
        loginAsyncCalled = true
        lastLoginEmail = email
        lastLoginPassword = password
        authStateSubject.send(.loading)
        switch loginAsyncResult {
        case .success(let user):
            authStateSubject.send(.authenticated(user))
            currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }
    
    /// Mock implementation of loginWithBiometrics method
    /// - Parameter completion: Completion handler with result containing user or error
    override func loginWithBiometrics(completion: @escaping (Result<User, AuthError>) -> Void) {
        loginWithBiometricsCalled = true
        authStateSubject.send(.loading)
        completion(loginWithBiometricsResult)
        if case .success(let user) = loginWithBiometricsResult {
            authStateSubject.send(.authenticated(user))
            currentUser = user
        }
    }
    
    /// Mock implementation of loginWithBiometricsAsync method
    /// - Returns: Authenticated user or throws an error
    @available(iOS 15.0, *)
    override func loginWithBiometricsAsync() async throws -> User {
        loginWithBiometricsAsyncCalled = true
        authStateSubject.send(.loading)
        switch loginWithBiometricsAsyncResult {
        case .success(let user):
            authStateSubject.send(.authenticated(user))
            currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }
    
    /// Mock implementation of register method
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - name: User's full name
    ///   - completion: Completion handler with result containing user or error
    override func register(email: String, password: String, name: String, completion: @escaping (Result<User, AuthError>) -> Void) {
        registerCalled = true
        lastRegisterEmail = email
        lastRegisterPassword = password
        lastRegisterName = name
        authStateSubject.send(.loading)
        completion(registerResult)
        if case .success(let user) = registerResult {
            authStateSubject.send(.authenticated(user))
            currentUser = user
        }
    }
    
    /// Mock implementation of registerAsync method
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - name: User's full name
    /// - Returns: Registered user or throws an error
    @available(iOS 15.0, *)
    override func registerAsync(email: String, password: String, name: String) async throws -> User {
        registerAsyncCalled = true
        lastRegisterEmail = email
        lastRegisterPassword = password
        lastRegisterName = name
        authStateSubject.send(.loading)
        switch registerAsyncResult {
        case .success(let user):
            authStateSubject.send(.authenticated(user))
            currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }
    
    /// Mock implementation of logout method
    /// - Parameter completion: Completion handler with result indicating success or error
    override func logout(completion: @escaping (Result<Void, AuthError>) -> Void) {
        logoutCalled = true
        completion(logoutResult)
        if case .success = logoutResult {
            authStateSubject.send(.unauthenticated)
            currentUser = nil
        }
    }
    
    /// Mock implementation of logoutAsync method
    @available(iOS 15.0, *)
    override func logoutAsync() async throws {
        logoutAsyncCalled = true
        switch logoutAsyncResult {
        case .success:
            authStateSubject.send(.unauthenticated)
            currentUser = nil
        case .failure(let error):
            throw error
        }
    }
    
    /// Mock implementation of restoreSession method
    override func restoreSession() {
        if currentUser != nil {
            authStateSubject.send(.authenticated(currentUser!))
        } else {
            authStateSubject.send(.unauthenticated)
        }
    }

    /// Mock implementation of restoreSessionAsync method
    @available(iOS 15.0, *)
    override func restoreSessionAsync() async throws -> User? {
        if currentUser != nil {
            authStateSubject.send(.authenticated(currentUser!))
            return currentUser
        } else {
            authStateSubject.send(.unauthenticated)
            return nil
        }
    }
    
    /// Mock implementation of getUserProfile method
    /// - Parameter completion: Completion handler with result containing user or error
    override func getUserProfile(completion: @escaping (Result<User, AuthError>) -> Void) {
        getUserProfileCalled = true
        completion(getUserProfileResult)
        if case .success(let user) = getUserProfileResult {
            currentUser = user
        }
    }
    
    /// Mock implementation of getUserProfileAsync method
    @available(iOS 15.0, *)
    override func getUserProfileAsync() async throws -> User {
        getUserProfileAsyncCalled = true
        switch getUserProfileAsyncResult {
        case .success(let user):
            currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }
    
    /// Mock implementation of enableBiometricLogin method
    /// - Parameters:
    ///   - enable: Whether to enable or disable biometric login
    ///   - email: User's email address (required when enabling)
    ///   - password: User's password (required when enabling)
    ///   - completion: Completion handler with result indicating success or error
    override func enableBiometricLogin(enable: Bool, email: String? = nil, password: String? = nil, completion: @escaping (Result<Void, AuthError>) -> Void) {
        enableBiometricLoginCalled = true
        completion(enableBiometricLoginResult)
    }
    
    /// Mock implementation of enableBiometricLoginAsync method
    @available(iOS 15.0, *)
    override func enableBiometricLoginAsync(enable: Bool, email: String? = nil, password: String? = nil) async throws {
        enableBiometricLoginAsyncCalled = true
        switch enableBiometricLoginAsyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    /// Mock implementation of isBiometricLoginAvailable method
    /// - Returns: True if biometric login is available
    override func isBiometricLoginAvailable() -> Bool {
        return isBiometricLoginAvailableResult
    }
    
    /// Mock implementation of isBiometricLoginEnabled method
    /// - Returns: True if biometric login is enabled
    override func isBiometricLoginEnabled() -> Bool {
        return isBiometricLoginEnabledResult
    }
    
    /// Mock implementation of validatePassword method
    /// - Parameter password: The password to validate
    /// - Returns: True if password meets requirements
    override func validatePassword(password: String) -> Bool {
        validatePasswordCalled = true
        return validatePasswordResult
    }
    
    /// Creates a mock user for testing
    /// - Parameters:
    ///   - id: User ID (optional)
    ///   - email: User email
    ///   - name: User name (optional)
    ///   - accountStatus: Account status
    /// - Returns: A mock user instance
    func createMockUser(id: UUID? = UUID(), email: String, name: String? = "Test User", accountStatus: AccountStatus = .active) -> User {
        return User(
            id: id ?? UUID(),
            email: email,
            name: name,
            createdAt: Date(),
            accountStatus: accountStatus,
            subscriptionTier: .free,
            languagePreference: "en"
        )
    }
}